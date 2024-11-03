# Load environment variables from .env if it exists
ifneq (,$(wildcard ./.env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

# Redshift connection details
REDSHIFT_HOST ?= $(REDSHIFT_HOST)
REDSHIFT_PORT ?= $(REDSHIFT_PORT)
REDSHIFT_USER ?= $(REDSHIFT_USER)
REDSHIFT_DB ?= $(REDSHIFT_DB)
REDSHIFT_SQL_FILE ?= $(REDSHIFT_SQL_FILE)
REDSHIFT_ROLE_ARN ?= $(REDSHIFT_ROLE_ARN)

# Airflow setup commands
AWS_CREDENTIALS_URI=aws://$(AWS_ACCESS_KEY):$(shell echo $(AWS_SECRET_ACCESS_KEY) | python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.stdin.read().strip()))")@
REDSHIFT_URI=redshift://$(REDSHIFT_USER):$(REDSHIFT_PASSWORD)@$(REDSHIFT_HOST):$(REDSHIFT_PORT)/$(REDSHIFT_DB)
S3_BUCKET_NAME ?= $(S3_BUCKET)
S3_PREFIX ?= data-pipelines


.PHONY: setup-aws-credentials setup-redshift setup-s3 docker-up docker-down docker-restart check-docker run-sql

# Default target
all: setup

# Ensure .env variables or prompt if not set
setup-env:
	@test -n "$(AWS_ACCESS_KEY)"
	@test -n "$(AWS_SECRET_ACCESS_KEY)"
	@test -n "$(REDSHIFT_USER)"
	@test -n "$(REDSHIFT_PASSWORD)"
	@test -n "$(S3_BUCKET)"
	@test -n "$(REDSHIFT_ROLE_ARN)"
	@test -n "$(REDSHIFT_HOST)"
	@test -n "$(REDSHIFT_PORT)"
	@test -n "$(REDSHIFT_DB)"
	@test -n "$(REDSHIFT_SQL_FILE)"

# Check if Docker Compose is running
check-docker:
	@docker compose ps | grep airflow-webserver > /dev/null || (echo "Docker Compose is not running. Starting now..."; docker compose up -d)

# Create AWS Airflow Connection
setup-aws-credentials: check-docker setup-env
	@echo "Checking if Airflow AWS connection exists..."
	@if ! docker compose exec airflow-webserver airflow connections get aws_credentials > /dev/null 2>&1; then \
		echo "Creating Airflow AWS connection..."; \
		docker compose exec airflow-webserver airflow connections add aws_credentials \
			--conn-type aws \
			--conn-login "$(AWS_ACCESS_KEY)" \
			--conn-password "$(AWS_SECRET_ACCESS_KEY)"; \
	else \
		echo "Airflow AWS connection already exists. Skipping creation."; \
	fi

# Create Redshift Airflow Connection
setup-redshift: check-docker setup-env
	@echo "Checking if Airflow Redshift connection exists..."
	@if ! docker compose exec airflow-webserver airflow connections get redshift > /dev/null 2>&1; then \
		echo "Creating Airflow Redshift connection..."; \
		docker compose exec airflow-webserver airflow connections add redshift --conn-uri '$(REDSHIFT_URI)'; \
	else \
		echo "Airflow Redshift connection already exists. Skipping creation."; \
	fi

# Set Airflow S3 variables
setup-s3: check-docker setup-env
	@echo "Setting up Airflow S3 variables..."
	@docker compose exec airflow-webserver airflow variables set s3_bucket $(S3_BUCKET_NAME)
	@docker compose exec airflow-webserver airflow variables set role_arn $(REDSHIFT_ROLE_ARN)

# Full setup
setup: docker-up setup-aws-credentials setup-redshift setup-s3 run-sql
	@echo "Airflow connections and variables have been set up."

# Cleanup: remove Airflow connections and variables
clean: check-docker
	@echo "Cleaning up Airflow connections and variables..."
	@docker compose exec airflow-webserver airflow connections delete aws_credentials || true
	@docker compose exec airflow-webserver airflow connections delete redshift || true
	@docker compose exec airflow-webserver airflow variables delete s3_bucket || true
	@docker compose exec airflow-webserver airflow variables delete role_arn || true
	@echo "Cleanup complete."

# Docker Compose commands
docker-up:
	@echo "Starting Airflow containers..."
	@docker compose up -d --build

docker-down:
	@echo "Stopping Airflow containers..."
	@docker compose down

docker-restart: docker-down docker-up
	@echo "Restarting Airflow containers..."

run-sql: setup-env
	@echo "Running SQL file on Redshift..."
	@PGPASSWORD=$(REDSHIFT_PASSWORD) psql -h $(REDSHIFT_HOST) -p $(REDSHIFT_PORT) -U $(REDSHIFT_USER) -d $(REDSHIFT_DB) -f $(REDSHIFT_SQL_FILE)

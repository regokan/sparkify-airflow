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

# EKS connection details
EKS_CLUSTER_NAME ?= $(EKS_CLUSTER_NAME)
RELEASE_NAME ?= $(RELEASE_NAME)
DOCKER_IMAGE ?= $(DOCKER_IMAGE)
DOCKER_IMAGE_TAG ?= $(DOCKER_IMAGE_TAG)

.PHONY: setup deploy-airflow setup-eks

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

# Connect to the EKS cluster using AWS CLI
connect-eks:
	@echo "Connecting to EKS cluster $(EKS_CLUSTER_NAME)..."
	aws eks update-kubeconfig --name $(EKS_CLUSTER_NAME) --region us-east-1 --alias airflow-cluster

# Create the namespace for Airflow if it doesn’t exist
create-namespace: connect-eks
	@kubectl get namespace $(NAMESPACE) || kubectl create namespace $(NAMESPACE)

# Create AWS Airflow Connection in Production
setup-aws-credentials-eks: connect-eks
	@echo "Setting up AWS connection in Airflow on EKS..."
	@if ! kubectl exec -it deployment/airflow-webserver -n $(NAMESPACE) -- \
		airflow connections get aws_credentials > /dev/null 2>&1; then \
		echo "Creating AWS connection..."; \
		kubectl exec -it deployment/airflow-webserver -n $(NAMESPACE) -- \
		airflow connections add aws_credentials \
			--conn-type aws \
			--conn-login "$(AWS_ACCESS_KEY)" \
			--conn-password "$(AWS_SECRET_ACCESS_KEY)"; \
	else \
		echo "AWS connection already exists. Skipping creation."; \
	fi

# Create Redshift Airflow Connection in Production
setup-redshift-eks: connect-eks
	@echo "Setting up Redshift connection in Airflow on EKS..."
	@if ! kubectl exec -it deployment/airflow-webserver -n $(NAMESPACE) -- \
		airflow connections get redshift > /dev/null 2>&1; then \
		echo "Creating Redshift connection..."; \
		kubectl exec -it deployment/airflow-webserver -n $(NAMESPACE) -- \
		airflow connections add redshift --conn-uri '$(REDSHIFT_URI)'; \
	else \
		echo "Redshift connection already exists. Skipping creation."; \
	fi

setup-eks: connect-eks setup-aws-credentials-eks setup-redshift-eks

configure-ebs-csi-driver: connect-eks
	helm repo update
	helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
	--namespace kube-system \
	--set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-ebs-csi-driver \
	--set controller.serviceAccount.create=true \
	--set controller.replicaCount=2 \
	--set enableVolumeScheduling=true \
	--set enableVolumeResizing=true \
	--set enableVolumeSnapshot=true


# Deploy Airflow to EKS using Helm chart
deploy-airflow: connect-eks create-namespace
	helm repo add apache-airflow https://airflow.apache.org || true
	@echo "Checking for existing airflow-webserver-secret-key..."
	@if kubectl get secret airflow-webserver-secret-key --namespace $(NAMESPACE) > /dev/null 2>&1; then \
		echo "Existing secret found, updating metadata..."; \
		kubectl label secret airflow-webserver-secret-key \
			app.kubernetes.io/managed-by=Helm \
			--namespace $(NAMESPACE) --overwrite; \
		kubectl annotate secret airflow-webserver-secret-key \
			meta.helm.sh/release-name=${RELEASE_NAME} \
			meta.helm.sh/release-namespace=$(NAMESPACE) \
			--namespace $(NAMESPACE) --overwrite; \
	else \
		echo "No existing secret found, proceeding with Helm install..."; \
	fi
	@echo "Deploying Airflow with Helm..."
	@helm upgrade --install airflow apache-airflow/airflow \
		--namespace ${NAMESPACE} \
		--timeout 15m

upgrade-airflow: connect-eks
	@docker build --pull --tag ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}.
	@docker push ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}
	@helm upgrade --install airflow apache-airflow/airflow \
		--namespace ${NAMESPACE} \
		--timeout 15m


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
setup: docker-up setup-aws-credentials setup-redshift setup-s3
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

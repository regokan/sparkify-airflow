# Sparkify ETL Pipeline with Apache Airflow

Sparkify, a music streaming company, has decided to automate and monitor their ETL (Extract, Transform, Load) pipelines for better data management and analysis in their data warehouse on Amazon Redshift. This project uses **Apache Airflow** to orchestrate and manage data pipelines that dynamically load JSON data from **Amazon S3** into **Amazon Redshift** and perform data quality checks to ensure integrity. The pipelines are modular, reusable, and support backfilling, making them highly flexible and reliable.

## Project Structure

The project is structured as follows:

```plaintext
.
├── LICENSE
├── Makefile
├── README.md
├── assets
│   └── dag.png                # Image of the final DAG structure in Airflow
├── create_tables.sql          # SQL script to set up initial tables in Redshift
├── dags
│   └── sparkify_etl.py        # Main DAG definition for the ETL process
├── docker-compose.yaml        # Docker configuration for running Airflow locally
├── infra                      # Terraform files for infrastructure setup (S3, Redshift)
│   └── ...                    # IAM, Redshift, S3, networking configurations
├── plugins                    # Custom Airflow plugins and operators
│   └── ...                    # Operators: data_quality, load_dimension, load_fact, stage_redshift
├── poetry.lock                # Poetry dependency lock file
├── poetry.toml                # Poetry project file
└── pyproject.toml             # Project metadata
```

## Project Components

### Airflow DAG: `sparkify_etl`

The main Airflow DAG, `sparkify_etl`, is configured to run hourly and orchestrates the entire ETL process. It includes tasks for staging data from S3 to Redshift, loading fact and dimension tables, and running data quality checks.

![Final DAG](assets/dag.png)

#### Key Configurations in `sparkify_etl`

- **Scheduling**: Runs every hour to process new data.
- **Dependencies**: The DAG begins with a `start_execution` task, followed by staging, loading dimensions, loading fact tables, and ends with data quality checks.
- **Retry Logic**: Uses `retries` and `retry_delay` to handle transient issues.

### Custom Airflow Operators

1. **`StageToRedshiftOperator`**:

   - This operator stages JSON data from S3 to Redshift by running a dynamic `COPY` command. It uses parameters such as `s3_bucket`, `s3_key`, `role_arn`, and `json_path` to define the S3 location and format.
   - **Logging** is implemented to monitor each step of the staging process, from command construction to execution.
   - Uses Airflow’s `PostgresHook` to connect to Redshift.

2. **`LoadDimensionOperator`**:

   - Responsible for loading data into dimension tables (`users`, `songs`, `artists`, and `time`).
   - Supports a **truncate-insert pattern** (using a `truncate_insert` flag) to allow flexibility between full reloads and incremental appends.
   - Leverages SQL queries stored in the `SqlQueries` helper class to dynamically insert data.

3. **`LoadFactOperator`**:

   - Loads data into the `songplays` fact table, which captures each user’s song play activity.
   - Configured as an **append-only** operation, ideal for large tables that need historical data retention.

4. **`DataQualityOperator`**:
   - Runs a series of **data quality checks** after data is loaded into Redshift.
   - Accepts a list of test cases, each containing a SQL query and an expected result. If the result does not match expectations, the operator raises an error, and Airflow retries as per the DAG’s configuration.
   - The operator ensures that critical data columns contain no `NULL` values or unexpected records.

### Fact and Dimension Tables

1. **Fact Table (`songplays`)**:

   - Stores records of each user’s song play activity, with fields like `playid`, `start_time`, `userid`, `level`, `songid`, and `artistid`.
   - Used to analyze user behavior and song popularity.

2. **Dimension Tables**:
   - **`users`**: User profile information (e.g., `userid`, `first_name`, `last_name`, `gender`, `level`).
   - **`songs`**: Details about each song (e.g., `songid`, `title`, `artistid`, `year`, `duration`).
   - **`artists`**: Artist information (e.g., `artistid`, `name`, `location`, `latitude`, `longitude`).
   - **`time`**: Timestamps broken down by various time units (e.g., `start_time`, `hour`, `day`, `week`, `month`, `year`, `weekday`).

### Infrastructure Setup (`infra` directory)

The project’s infrastructure is provisioned using **Terraform**. The `infra` directory includes the configurations required to set up the following resources:

1. **Amazon S3**:

   - Used as the storage location for the source JSON data files (`log-data` and `song-data`).

2. **Amazon Redshift Serverless**:

   - Redshift serves as the primary data warehouse where all staging, fact, and dimension tables reside.
   - A **serverless setup** is used for scalability and cost-effectiveness.

3. **IAM Roles**:
   - Configured in Terraform to allow Redshift access to S3 for data loading.
   - Roles are managed under the `iam` module, with permissions for staging data and loading it into Redshift.

### Makefile

The `Makefile` provides streamlined commands for setting up and managing the environment. It includes targets for initializing AWS credentials, configuring Redshift, and managing Docker containers for Airflow.

#### Key Commands

- **Environment Setup**:

  - `setup-env`: Ensures required environment variables are set or loaded from `.env`.
  - `setup-aws-credentials`: Sets up the AWS credentials in Airflow.
  - `setup-redshift`: Configures the Redshift connection in Airflow.
  - `setup-s3`: Sets Airflow variables for S3 bucket and IAM role.

- **Docker Management**:

  - `docker-up`: Starts Airflow containers using Docker Compose.
  - `docker-down`: Stops Airflow containers.
  - `docker-restart`: Restarts Airflow containers.

- **Redshift SQL Execution**:
  - `run-sql`: Runs a specified SQL file on Redshift to initialize tables or manage data directly.

To set up the environment using the Makefile, run:

```bash
make setup
```

To clean up connections and variables in Airflow, use:

```bash
make clean
```

### How to Run the Project

1. **Setup Environment**:

   - Make sure you have Docker and Terraform installed.
   - Configure necessary AWS credentials and permissions.

2. **Provision Infrastructure**:

   - Navigate to the `infra` directory and run:
     ```bash
     terraform init
     terraform apply
     ```

3. **Start Airflow**:

   - Use Docker Compose to start Airflow locally:
     ```bash
     docker-compose up
     ```

4. **Run the DAG**:

   - Access the Airflow UI at `http://localhost:8080`, enable the `sparkify_etl` DAG, and trigger it manually or wait for the scheduled interval.

5. **Monitor the DAG**:
   - Check task logs and statuses in Airflow to ensure smooth execution. All tasks, including data quality checks, should pass without errors.

### Project Dependencies

- **Apache Airflow** (with Postgres and S3 hooks)
- **Amazon Redshift** (Serverless)
- **Amazon S3**
- **Terraform** (for infrastructure provisioning)
- **Poetry** (for Python dependency management)

### License

This project is licensed under the [Creative Commons License](LICENSE).

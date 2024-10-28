from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults
from airflow.exceptions import AirflowException


class StageToRedshiftOperator(BaseOperator):
    ui_color = "#358140"
    template_fields = ("s3_bucket", "s3_key", "role_arn")

    @apply_defaults
    def __init__(
        self,
        redshift_conn_id="",
        aws_credentials_id="",
        role_arn="",
        table="",
        s3_bucket="",
        s3_key="",
        json_path="auto",
        *args,
        **kwargs,
    ):
        """
        Constructor for the StageToRedshiftOperator
        Args:
            - redshift_conn_id: The connection ID for the Redshift cluster
            - aws_credentials_id: The connection ID for the AWS credentials
            - role_arn: The ARN of the IAM role to use for the COPY operation
            - table: The name of the table to stage the data into
            - s3_bucket: The name of the S3 bucket containing the data
            - s3_key: The key (directory) in the S3 bucket containing the data
            - json_path: The path to the JSON file containing the data
        """
        super().__init__(*args, **kwargs)
        self.redshift_conn_id = redshift_conn_id
        self.aws_credentials_id = aws_credentials_id
        self.role_arn = role_arn
        self.table = table
        self.s3_bucket = s3_bucket
        self.s3_key = s3_key
        self.json_path = json_path

    def execute(self, context):
        self.log.info("Starting to stage data from S3 to Redshift")

        # Prepare connection details for PostgresHook specific to Redshift
        extra_dejson = {
            "iam": True,
            "redshift": True,
            "aws_conn_id": self.aws_credentials_id,
            "cluster-identifier": self.redshift_conn_id,
        }

        # Initialize PostgresHook for Redshift with required IAM parameters
        redshift = PostgresHook(
            postgres_conn_id=self.redshift_conn_id, extra_dejson=extra_dejson
        )

        # Construct the SQL COPY command with the specified IAM role and JSON path
        copy_sql = f"""
            COPY {self.table}
            FROM 's3://{self.s3_bucket}/{self.s3_key}'
            IAM_ROLE '{self.role_arn}'
            FORMAT AS JSON '{self.json_path}'
        """

        # Execute the COPY command
        try:
            redshift.run(copy_sql)
            self.log.info(
                f"Successfully staged data from S3 to Redshift table {self.table}"
            )
        except Exception as e:
            raise AirflowException(f"Error staging data: {str(e)}")

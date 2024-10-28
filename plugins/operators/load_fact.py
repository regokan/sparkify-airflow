from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults
from airflow.exceptions import AirflowException
from helpers.sql_queries import SqlQueries


class LoadFactOperator(BaseOperator):

    ui_color = "#F98866"

    @apply_defaults
    def __init__(
        self,
        redshift_conn_id="redshift",
        aws_credentials_id="aws_credentials",
        *args,
        **kwargs,
    ):
        """
        Constructor for the LoadFactOperator
        Args:
            - redshift_conn_id: The connection ID for the Redshift cluster
            - aws_credentials_id: The connection ID for the AWS credentials
        """
        super().__init__(*args, **kwargs)
        self.redshift_conn_id = redshift_conn_id
        self.aws_credentials_id = aws_credentials_id

    def execute(self, context):
        self.log.info("Starting to load data into the songplays fact table")

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

        # Execute the SQL query to load data into the songplays fact table
        try:
            self.log.info("Executing fact table load SQL")
            redshift.run(SqlQueries.songplay_table_insert)

            self.log.info("Successfully loaded data into the songplays fact table")
        except Exception as e:
            self.log.error(
                f"Error loading data into the songplays fact table: {str(e)}"
            )
            raise AirflowException(
                f"Error loading data into the songplays fact table: {str(e)}"
            ) from e

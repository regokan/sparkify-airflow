from typing import Sequence
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults
from airflow.exceptions import AirflowException
from helpers.sql_queries import SqlQueries


class LoadFactOperator(BaseOperator):

    ui_color = "#F98866"
    template_fields: Sequence[str] = (
        "redshift_conn_id",
        "aws_credentials_id",
        "table_name",
        "columns",
    )

    @apply_defaults
    def __init__(
        self,
        redshift_conn_id: str,
        aws_credentials_id: str,
        table_name: str,
        columns: list,
        *args,
        **kwargs,
    ):
        """
        Constructor for the LoadFactOperator
        Args:
            - redshift_conn_id: The connection ID for the Redshift cluster
            - aws_credentials_id: The connection ID for the AWS credentials
            - table_name: The target table to insert data into
            - columns: A list of columns to match the table schema
        """
        super().__init__(*args, **kwargs)
        self.redshift_conn_id = redshift_conn_id
        self.aws_credentials_id = aws_credentials_id
        self.table_name = table_name
        self.columns = columns

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

        insert_query = f"""
            INSERT INTO {self.table_name} ({",".join(self.columns)})
            {SqlQueries.songplay_table_insert}
        """

        # Execute the SQL query to load data into the songplays fact table
        try:
            self.log.info("Executing fact table load SQL")
            redshift.run(insert_query)

            self.log.info("Successfully loaded data into the songplays fact table")
        except Exception as e:
            self.log.error(
                f"Error loading data into the songplays fact table: {str(e)}"
            )
            raise AirflowException(
                f"Error loading data into the songplays fact table: {str(e)}"
            ) from e

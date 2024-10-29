from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults


class LoadDimensionOperator(BaseOperator):
    ui_color = "#80BD9E"

    @apply_defaults
    def __init__(
        self,
        redshift_conn_id="",
        table="",
        sql_query="",
        truncate_insert=True,
        *args,
        **kwargs,
    ):
        """
        Initializes the LoadDimensionOperator Constructor.

        :param redshift_conn_id: Redshift connection ID in Airflow
        :param table: Dimension table name to load data into
        :param sql_query: SQL query to fetch data for loading into dimension
        :param truncate_insert: If True, perform a truncate-insert; if False, only append
        """
        super(LoadDimensionOperator, self).__init__(*args, **kwargs)
        self.redshift_conn_id = redshift_conn_id
        self.table = table
        self.sql_query = sql_query
        self.truncate_insert = truncate_insert

    def execute(self, context):
        self.log.info(f"Loading dimension table {self.table}")

        redshift = PostgresHook(postgres_conn_id=self.redshift_conn_id)

        # Truncate table if required
        if self.truncate_insert:
            self.log.info(f"Truncating Redshift table {self.table}")
            truncate_sql = f"TRUNCATE TABLE {self.table};"
            redshift.run(truncate_sql)

        # Insert data into dimension table
        insert_sql = f"INSERT INTO {self.table} {self.sql_query};"
        self.log.info(f"Executing query: {insert_sql}")
        redshift.run(insert_sql)
        self.log.info(f"Successfully loaded data into {self.table} table")

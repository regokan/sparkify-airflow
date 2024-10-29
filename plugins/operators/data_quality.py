from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults


class DataQualityOperator(BaseOperator):

    ui_color = "#89DA59"

    @apply_defaults
    def __init__(self, redshift_conn_id="", test_cases=None, *args, **kwargs):
        """
        Initialize the DataQualityOperator Constructor.

        :param redshift_conn_id: The connection ID for Redshift
        :param test_cases: A list of dictionaries containing SQL test queries and their expected results.
                           Example format:
                           test_cases = [
                               {"test_sql": "SELECT COUNT(*) FROM users WHERE userid IS NULL", "expected_result": 0},
                               {"test_sql": "SELECT COUNT(*) FROM songs WHERE songid IS NULL", "expected_result": 0},
                               ...
                           ]
        """
        super(DataQualityOperator, self).__init__(*args, **kwargs)
        self.redshift_conn_id = redshift_conn_id
        self.test_cases = test_cases or []

    def execute(self, context):
        self.log.info("Starting data quality checks")

        # Set up connection to Redshift
        redshift = PostgresHook(postgres_conn_id=self.redshift_conn_id)

        # Iterate over each test case
        for idx, test_case in enumerate(self.test_cases):
            test_sql = test_case.get("test_sql")
            expected_result = test_case.get("expected_result")

            self.log.info(f"Executing test case {idx+1}: {test_sql}")
            records = redshift.get_records(test_sql)

            # Check if the result matches the expected result
            if len(records) < 1 or len(records[0]) < 1:
                raise ValueError(
                    f"Data quality check {idx+1} failed. No results returned for query: {test_sql}"
                )

            actual_result = records[0][0]
            if actual_result != expected_result:
                raise ValueError(
                    f"Data quality check {idx+1} failed. Query: {test_sql} returned {actual_result} but expected {expected_result}."
                )

            self.log.info(
                f"Data quality check {idx+1} passed with result {actual_result}"
            )

        self.log.info("All data quality checks passed successfully")

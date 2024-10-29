from datetime import datetime, timedelta
import pendulum
import os
from airflow.decorators import dag
from airflow.operators.dummy import DummyOperator
from operators import (
    StageToRedshiftOperator,
    LoadFactOperator,
    LoadDimensionOperator,
    DataQualityOperator,
)
from helpers.sql_queries import SqlQueries

default_args = {
    "owner": "regokan",
    "depends_on_past": False,
    "start_date": pendulum.now(),
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "catchup": False,
}


@dag(
    default_args=default_args,
    description="Load and transform data in Redshift with Airflow",
    schedule_interval="0 * * * *",
    max_active_runs=1,
)
def sparkify_etl():
    start_operator = DummyOperator(task_id="Begin_execution")
    stage_events_to_redshift = StageToRedshiftOperator(
        task_id="Stage_events",
        redshift_conn_id="redshift",
        aws_credentials_id="aws_credentials",
        role_arn="{{ var.value.role_arn }}",
        table="staging_events",
        s3_bucket="{{ var.value.s3_bucket }}",
        s3_key="log-data",
        json_path="s3://{{ var.value.s3_bucket }}/log_json_path.json",
    )

    stage_songs_to_redshift = StageToRedshiftOperator(
        task_id="Stage_songs",
        redshift_conn_id="redshift",
        aws_credentials_id="aws_credentials",
        role_arn="{{ var.value.role_arn }}",
        table="staging_songs",
        s3_bucket="{{ var.value.s3_bucket }}",
        s3_key="song-data",
        json_path="auto",
    )

    load_songplays_table = LoadFactOperator(
        task_id="Load_songplays_fact_table",
        redshift_conn_id="redshift",
        aws_credentials_id="aws_credentials",
        table_name="songplays",
        columns=[
            "playid",
            "start_time",
            "userid",
            "level",
            "songid",
            "artistid",
            "sessionid",
            "location",
            "user_agent",
        ],
    )

    load_user_dimension_table = LoadDimensionOperator(
        task_id="Load_user_dim_table",
        redshift_conn_id="redshift",
        table="users",
        sql_query=SqlQueries.user_table_insert,
        truncate_insert=True,
    )

    load_song_dimension_table = LoadDimensionOperator(
        task_id="Load_song_dim_table",
        redshift_conn_id="redshift",
        table="songs",
        sql_query=SqlQueries.song_table_insert,
        truncate_insert=True,
    )

    load_artist_dimension_table = LoadDimensionOperator(
        task_id="Load_artist_dim_table",
        redshift_conn_id="redshift",
        table="artists",
        sql_query=SqlQueries.artist_table_insert,
        truncate_insert=True,
    )

    load_time_dimension_table = LoadDimensionOperator(
        task_id="Load_time_dim_table",
        redshift_conn_id="redshift",
        table="time",
        sql_query=SqlQueries.time_table_insert,
        truncate_insert=True,
    )

    run_quality_checks = DataQualityOperator(
        task_id="Run_data_quality_checks",
        redshift_conn_id="redshift",
        test_cases=[
            {
                "test_sql": "SELECT COUNT(*) FROM users WHERE userid IS NULL",
                "expected_result": 0,
            },
            {
                "test_sql": "SELECT COUNT(*) FROM songs WHERE songid IS NULL",
                "expected_result": 0,
            },
            {
                "test_sql": "SELECT COUNT(*) FROM artists WHERE artistid IS NULL",
                "expected_result": 0,
            },
            {
                "test_sql": "SELECT COUNT(*) FROM time WHERE start_time IS NULL",
                "expected_result": 0,
            },
            {
                "test_sql": "SELECT COUNT(*) FROM songplays WHERE playid IS NULL",
                "expected_result": 0,
            },
        ],
    )

    end_operator = DummyOperator(task_id="End_execution")

    (
        start_operator
        >> [stage_events_to_redshift, stage_songs_to_redshift]
        >> load_songplays_table
        >> [
            load_user_dimension_table,
            load_song_dimension_table,
            load_artist_dimension_table,
            load_time_dimension_table,
        ]
        >> run_quality_checks
        >> end_operator
    )


sparkify_etl_dag = sparkify_etl()

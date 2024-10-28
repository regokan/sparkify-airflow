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

default_args = {
    "owner": "regokan",
    "start_date": pendulum.now(),
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
}


@dag(
    default_args=default_args,
    description="Load and transform data in Redshift with Airflow",
    schedule_interval="0 * * * *",
    max_active_runs=1,
)
def final_project():
    """
    start_operator = DummyOperator(task_id="Begin_execution")
    stage_events_to_redshift = StageToRedshiftOperator(
        task_id="Stage_events",
        redshift_conn_id="redshift",
        aws_credentials_id="aws_credentials",
        role_arn="{{ var.value.role_arn }}",
        table="staging_events",
        s3_bucket="{{ var.value.s3_bucket }}",
        s3_key="log-data",
        json_path="auto",
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

    """

    load_songplays_table = LoadFactOperator(
        task_id="Load_songplays_fact_table",
        # redshift_conn_id="redshift",
        # aws_credentials_id="aws_credentials",
    )

    """
    load_user_dimension_table = LoadDimensionOperator(
        task_id="Load_user_dim_table",
    )

    load_song_dimension_table = LoadDimensionOperator(
        task_id="Load_song_dim_table",
    )

    load_artist_dimension_table = LoadDimensionOperator(
        task_id="Load_artist_dim_table",
    )

    load_time_dimension_table = LoadDimensionOperator(
        task_id="Load_time_dim_table",
    )

    run_quality_checks = DataQualityOperator(
        task_id="Run_data_quality_checks",
    )

    end_operator = DummyOperator(task_id="End_execution")
    """


final_project_dag = final_project()

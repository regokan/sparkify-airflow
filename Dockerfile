FROM apache/airflow:2.0.2

USER root

COPY --chown=airflow:root ./dags/ \${AIRFLOW_HOME}/dags/
COPY --chown=airflow:root ./plugins/ \${AIRFLOW_HOME}/plugins/

USER airflow

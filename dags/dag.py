from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.dummy import DummyOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data_engineering_team',
    'depends_on_past': True,
    'start_date': datetime(2026, 9, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'pulsetrack_daily_etl_pipeline',
    default_args=default_args,
    description='Daily ETL pipeline for Medallion Architecture',
    schedule_interval='@daily',
    catchup=False,
) as dag:

    start_pipeline = DummyOperator(task_id='start_pipeline')

    # BRONZE LAYER: Ingest raw data
    ingest_bronze = PostgresOperator(
        task_id='ingest_to_bronze',
        postgres_conn_id='warehouse_conn',
        sql='sql/01_load_bronze.sql'
    )

    # SILVER LAYER: Clean and conform
    clean_silver_dimensions = PostgresOperator(
        task_id='clean_silver_dimensions',
        postgres_conn_id='warehouse_conn',
        sql='sql/02_clean_silver_dims.sql'
    )
    
    clean_silver_facts = PostgresOperator(
        task_id='clean_silver_facts',
        postgres_conn_id='warehouse_conn',
        sql='sql/03_clean_silver_facts.sql'
    )

    # GOLD LAYER: Dimensional Modeling (Star Schema)
    load_gold_dimensions = PostgresOperator(
        task_id='load_gold_dimensions',
        postgres_conn_id='warehouse_conn',
        sql='sql/04_load_gold_dims.sql'
    )

    load_gold_facts = PostgresOperator(
        task_id='load_gold_facts',
        postgres_conn_id='warehouse_conn',
        sql='sql/05_load_gold_facts.sql'
    )

    # DATA MARTS: Aggregation for BI
    refresh_campaign_mart = PostgresOperator(
        task_id='refresh_campaign_mart',
        postgres_conn_id='warehouse_conn',
        sql='sql/06_refresh_marts.sql'
    )

    end_pipeline = DummyOperator(task_id='end_pipeline')

    # Define DAG Dependencies (Execution Order)
    start_pipeline >> ingest_bronze 
    ingest_bronze >> [clean_silver_dimensions, clean_silver_facts]
    
    clean_silver_dimensions >> load_gold_dimensions
    clean_silver_facts >> load_gold_facts
    
    [load_gold_dimensions, load_gold_facts] >> refresh_campaign_mart >> end_pipeline
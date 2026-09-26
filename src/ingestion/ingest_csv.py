import os
import sys
import glob
import datetime
import pandas as pd
from sqlalchemy import create_engine, text

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))
from config import DB_URI, DATA_DIR, CHUNK_SIZE

engine = create_engine(DB_URI)

# Create schema if it doesn't exist
with engine.connect() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS bronze;"))
    conn.commit()

# Locate the data folder in the project root
BASE_DIR = DATA_DIR
csv_files = glob.glob(os.path.join(BASE_DIR, '*.csv'))

print(f"[*] Found {len(csv_files)} CSV files in {BASE_DIR}")

for file_path in csv_files:
    file_name = os.path.basename(file_path)
    table_name = 'bronze_' + file_name.replace('.csv', '')
    
    print(f"[>] Ingesting {file_name} -> bronze.{table_name}...")
    
    # Memory-efficient loading in 50,000 chunks
    total_rows = 0
    for chunk in pd.read_csv(file_path, dtype=str, chunksize=CHUNK_SIZE):
        chunk['ingested_at'] = datetime.datetime.utcnow()
        chunk['source_file'] = file_name
        chunk.to_sql(table_name, engine, schema='bronze', if_exists='append', index=False)
        total_rows += len(chunk)
        
    print(f"[✓] Completed {file_name} ({total_rows} rows inserted)")

print("\n[ALL CSV INGESTION COMPLETED SUCCESSFULLY]")
import os
import sys
import glob
import datetime
import pandas as pd
from sqlalchemy import create_engine

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))
from config import DB_URI, MONGO_DIR

engine = create_engine(DB_URI)

# Locate the mongo folder in the project root
BASE_DIR = MONGO_DIR
jsonl_files = glob.glob(os.path.join(BASE_DIR, '*.jsonl'))

print(f"[*] Found {len(jsonl_files)} JSONL files in {BASE_DIR}")

for file_path in jsonl_files:
    file_name = os.path.basename(file_path)
    table_name = 'bronze_' + file_name.replace('.jsonl', '')
    
    print(f"[>] Ingesting {file_name} -> bronze.{table_name}...")
    
    # Read JSON file line by line as text
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    # Store each complete JSON document in a single column (raw_document)
    df = pd.DataFrame({'raw_document': lines})
    
    # Add metadata
    df['ingested_at'] = datetime.datetime.utcnow()
    df['source_file'] = file_name
    
    # Push to database
    df.to_sql(table_name, engine, schema='bronze', if_exists='append', index=False)
    
    print(f"[✓] Completed {file_name} ({len(df)} rows inserted)")

print("\n[ALL JSON INGESTION COMPLETED SUCCESSFULLY]")
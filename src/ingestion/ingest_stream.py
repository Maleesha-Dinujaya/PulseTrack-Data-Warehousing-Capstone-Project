import os
import sys
import datetime
import pandas as pd
from sqlalchemy import create_engine

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))
from config import DB_URI, STREAM_LOG_FILE, CHUNK_SIZE

engine = create_engine(DB_URI)

# Locate the stream folder in the project root
log_file = STREAM_LOG_FILE

print(f"[*] Locating stream file: {log_file}")

# Load in chunks of 50,000 rows to avoid memory issues
chunk_size = CHUNK_SIZE
records = []
total_inserted = 0
table_name = 'bronze_stream_conversions'

print(f"[>] Ingesting stream log -> bronze.{table_name}...")

# Read the text file line by line
with open(log_file, 'r', encoding='utf-8') as f:
    for line in f:
        records.append({'raw_log_line': line.strip()})
        
        # Insert into database when 50,000 rows are accumulated
        if len(records) >= chunk_size:
            df = pd.DataFrame(records)
            df['ingested_at'] = datetime.datetime.utcnow()
            df['source_file'] = 'pulsetrack_conversions.log'
            df.to_sql(table_name, engine, schema='bronze', if_exists='append', index=False)
            total_inserted += len(df)
            records = [] # Clear list for the next chunk

    # Insert the remaining rows (last chunk)
    if records:
        df = pd.DataFrame(records)
        df['ingested_at'] = datetime.datetime.utcnow()
        df['source_file'] = 'pulsetrack_conversions.log'
        df.to_sql(table_name, engine, schema='bronze', if_exists='append', index=False)
        total_inserted += len(df)

print(f"[✓] Completed stream ingestion ({total_inserted} rows inserted)")
print("\n[ALL STREAM INGESTION COMPLETED SUCCESSFULLY]")
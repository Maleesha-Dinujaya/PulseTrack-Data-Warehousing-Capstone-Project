-- 1. Create the Audit Schema
CREATE SCHEMA IF NOT EXISTS audit;

-- 2. Create the log table
CREATE TABLE IF NOT EXISTS audit.pipeline_runs (
    run_id SERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100) NOT NULL,
    batch_id VARCHAR(50),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20),
    source_record_count INT DEFAULT 0,
    inserted_count INT DEFAULT 0,
    updated_count INT DEFAULT 0,
    rejected_count INT DEFAULT 0,
    error_message TEXT
);

-- 3. (For testing) Insert a dummy record and check it
INSERT INTO audit.pipeline_runs (pipeline_name, status, source_record_count, inserted_count)
VALUES ('Initial_Test_Run', 'SUCCESS', 1000, 1000);
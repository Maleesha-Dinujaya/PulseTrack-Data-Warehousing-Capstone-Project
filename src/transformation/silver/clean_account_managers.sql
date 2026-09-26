DROP TABLE IF EXISTS silver.silver_account_managers_clean;

CREATE TABLE silver.silver_account_managers_clean AS 
SELECT 
    TRIM(am_id) AS am_id,
    TRIM(am_name) AS am_name,
    NULLIF(TRIM(team), '') AS team,
    NULLIF(TRIM(region), '') AS region,
    
    -- hire_date standardization
    CASE 
        WHEN hire_date IS NULL OR TRIM(hire_date::TEXT) = '' THEN NULL
        WHEN TRIM(hire_date::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(hire_date::TEXT)::NUMERIC)
        WHEN TRIM(hire_date::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(hire_date::TEXT), 'MM/DD/YYYY')
        WHEN TRIM(hire_date::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(hire_date::TEXT), 'DD-MM-YYYY')
        WHEN TRIM(hire_date::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(hire_date::TEXT)::TIMESTAMP
        ELSE TRIM(hire_date::TEXT)::TIMESTAMP 
    END AS hire_date,

    -- created_at standardization
    CASE 
        WHEN created_at IS NULL OR TRIM(created_at::TEXT) = '' THEN NULL
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(created_at::TEXT)::NUMERIC)
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(created_at::TEXT), 'MM/DD/YYYY')
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(created_at::TEXT), 'DD-MM-YYYY')
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(created_at::TEXT)::TIMESTAMP
        ELSE TRIM(created_at::TEXT)::TIMESTAMP 
    END AS created_at,

    -- updated_at standardization
    CASE 
        WHEN updated_at IS NULL OR TRIM(updated_at::TEXT) = '' THEN NULL
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(updated_at::TEXT)::NUMERIC)
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'MM/DD/YYYY')
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'DD-MM-YYYY')
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(updated_at::TEXT)::TIMESTAMP
        ELSE TRIM(updated_at::TEXT)::TIMESTAMP 
    END AS updated_at,

    ingested_at,
    source_file
FROM bronze.bronze_account_managers_raw;
DROP TABLE IF EXISTS silver.silver_advertisers_clean;

CREATE TABLE silver.silver_advertisers_clean AS 
SELECT 
    advertiser_id,
    advertiser_name,
    vertical,
    account_manager_id,
    status,
    
    -- signup_date standardization
    CASE 
        WHEN signup_date IS NULL OR TRIM(signup_date) = '' THEN NULL
        WHEN signup_date ~ '^[0-9]{10}$' THEN to_timestamp(signup_date::NUMERIC)::DATE
        WHEN signup_date ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_date(signup_date, 'MM/DD/YYYY')
        WHEN signup_date ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_date(signup_date, 'DD-MM-YYYY')
        WHEN signup_date ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_date(signup_date, 'Mon DD, YYYY')
        ELSE signup_date::DATE 
    END AS signup_date,

    billing_country,

    -- created_at standardization
    CASE 
        WHEN created_at IS NULL OR TRIM(created_at) = '' THEN NULL
        WHEN created_at ~ '^[0-9]{10}$' THEN to_timestamp(created_at::NUMERIC)::DATE
        WHEN created_at ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_date(created_at, 'MM/DD/YYYY')
        WHEN created_at ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_date(created_at, 'DD-MM-YYYY')
        WHEN created_at ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_date(created_at, 'Mon DD, YYYY')
        ELSE created_at::DATE 
    END AS created_at,

    -- updated_at standardization
    CASE 
        WHEN updated_at IS NULL OR TRIM(updated_at) = '' THEN NULL
        WHEN updated_at ~ '^[0-9]{10}$' THEN to_timestamp(updated_at::NUMERIC)::DATE
        WHEN updated_at ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_date(updated_at, 'MM/DD/YYYY')
        WHEN updated_at ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_date(updated_at, 'DD-MM-YYYY')
        WHEN updated_at ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_date(updated_at, 'Mon DD, YYYY')
        ELSE updated_at::DATE 
    END AS updated_at,

    ingested_at,
    source_file
FROM bronze.bronze_advertisers_raw;
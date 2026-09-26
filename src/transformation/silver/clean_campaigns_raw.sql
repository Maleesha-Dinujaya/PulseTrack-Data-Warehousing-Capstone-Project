DROP TABLE IF EXISTS silver.silver_campaigns_clean;

CREATE TABLE silver.silver_campaigns_clean AS 
SELECT 
    TRIM(campaign_id) AS campaign_id,
    TRIM(campaign_name) AS campaign_name,
    TRIM(offer_id) AS offer_id,
    TRIM(advertiser_id) AS advertiser_id,
    
    -- Normalize Price Type to a single uppercase format (e.g., CPM, FIXED, CPC)
    UPPER(TRIM(price_type)) AS price_type,

    -- start_date
    CASE 
        WHEN start_date IS NULL OR TRIM(start_date) = '' THEN NULL
        WHEN TRIM(start_date) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(start_date)::NUMERIC)
        WHEN TRIM(start_date) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(start_date), 'MM/DD/YYYY')
        WHEN TRIM(start_date) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(start_date), 'DD-MM-YYYY')
        WHEN TRIM(start_date) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(start_date), 'Mon DD, YYYY')
        ELSE TRIM(start_date)::TIMESTAMP 
    END AS start_date,

    -- end_date
    CASE 
        WHEN end_date IS NULL OR TRIM(end_date) = '' THEN NULL
        WHEN TRIM(end_date) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(end_date)::NUMERIC)
        WHEN TRIM(end_date) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(end_date), 'MM/DD/YYYY')
        WHEN TRIM(end_date) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(end_date), 'DD-MM-YYYY')
        WHEN TRIM(end_date) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(end_date), 'Mon DD, YYYY')
        ELSE TRIM(end_date)::TIMESTAMP 
    END AS end_date,

    -- created_at
    CASE 
        WHEN created_at IS NULL OR TRIM(created_at) = '' THEN NULL
        WHEN TRIM(created_at) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(created_at)::NUMERIC)
        WHEN TRIM(created_at) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(created_at), 'MM/DD/YYYY')
        WHEN TRIM(created_at) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(created_at), 'DD-MM-YYYY')
        WHEN TRIM(created_at) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(created_at), 'Mon DD, YYYY')
        ELSE TRIM(created_at)::TIMESTAMP 
    END AS created_at,

    -- updated_at
    CASE 
        WHEN updated_at IS NULL OR TRIM(updated_at) = '' THEN NULL
        WHEN TRIM(updated_at) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(updated_at)::NUMERIC)
        WHEN TRIM(updated_at) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(updated_at), 'MM/DD/YYYY')
        WHEN TRIM(updated_at) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(updated_at), 'DD-MM-YYYY')
        WHEN TRIM(updated_at) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(updated_at), 'Mon DD, YYYY')
        ELSE TRIM(updated_at)::TIMESTAMP 
    END AS updated_at,

    ingested_at,
    source_file
FROM bronze.bronze_campaigns_raw;
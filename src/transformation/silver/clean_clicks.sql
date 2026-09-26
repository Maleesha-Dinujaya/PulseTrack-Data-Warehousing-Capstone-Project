DROP TABLE IF EXISTS silver.silver_conversion_touchpoints_clean;

CREATE TABLE silver.silver_conversion_touchpoints_clean AS 
SELECT 
    TRIM(touchpoint_id) AS touchpoint_id,
    TRIM(conversion_id) AS conversion_id,
    TRIM(click_id) AS click_id,
    
    -- touch_position lowercase standardization (first, mid, last)
    LOWER(TRIM(touch_position)) AS touch_position,

    -- weight to numeric/decimal
    CASE 
        WHEN weight IS NULL OR TRIM(weight) = '' THEN NULL 
        ELSE TRIM(weight)::NUMERIC(5,4)
    END AS weight,

    -- created_at standardization
    CASE 
        WHEN created_at IS NULL OR TRIM(created_at) = '' THEN NULL
        WHEN TRIM(created_at) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(created_at)::NUMERIC)
        WHEN TRIM(created_at) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(created_at)::TIMESTAMP
        WHEN TRIM(created_at) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(created_at), 'Mon DD, YYYY')
        WHEN TRIM(created_at) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(created_at), 'MM/DD/YYYY')
        WHEN TRIM(created_at) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(created_at), 'DD-MM-YYYY')
        ELSE TRIM(created_at)::TIMESTAMP 
    END AS created_at,

    -- updated_at standardization
    CASE 
        WHEN updated_at IS NULL OR TRIM(updated_at) = '' THEN NULL
        WHEN TRIM(updated_at) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(updated_at)::NUMERIC)
        WHEN TRIM(updated_at) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(updated_at)::TIMESTAMP
        WHEN TRIM(updated_at) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(updated_at), 'Mon DD, YYYY')
        WHEN TRIM(updated_at) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(updated_at), 'MM/DD/YYYY')
        WHEN TRIM(updated_at) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(updated_at), 'DD-MM-YYYY')
        ELSE TRIM(updated_at)::TIMESTAMP 
    END AS updated_at,

    ingested_at,
    source_file
FROM bronze.bronze_conversion_touchpoints_raw;
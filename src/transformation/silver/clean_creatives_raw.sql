DROP TABLE IF EXISTS silver.silver_creatives_clean;

CREATE TABLE silver.silver_creatives_clean AS 
SELECT 
    TRIM(creative_id) AS creative_id,
    TRIM(campaign_id) AS campaign_id,
    TRIM(creative_name) AS creative_name,
    
    -- Lowercase the Format and Size
    LOWER(TRIM(format)) AS format,
    LOWER(TRIM(size)) AS size,
    
    NULLIF(TRIM(landing_url), '') AS landing_url,

    -- created_at standardization
    CASE 
        WHEN created_at IS NULL OR TRIM(created_at::TEXT) = '' THEN NULL
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(created_at::TEXT)::NUMERIC)
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(created_at::TEXT)::TIMESTAMP
        WHEN TRIM(created_at::TEXT) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(created_at::TEXT), 'Mon DD, YYYY')
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(created_at::TEXT), 'MM/DD/YYYY')
        WHEN TRIM(created_at::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(created_at::TEXT), 'DD-MM-YYYY')
        ELSE TRIM(created_at::TEXT)::TIMESTAMP 
    END AS created_at,

    -- updated_at standardization
    CASE 
        WHEN updated_at IS NULL OR TRIM(updated_at::TEXT) = '' THEN NULL
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(updated_at::TEXT)::NUMERIC)
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(updated_at::TEXT)::TIMESTAMP
        WHEN TRIM(updated_at::TEXT) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'Mon DD, YYYY')
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'MM/DD/YYYY')
        WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'DD-MM-YYYY')
        ELSE TRIM(updated_at::TEXT)::TIMESTAMP 
    END AS updated_at,

    ingested_at,
    source_file
FROM bronze.bronze_creatives_raw;
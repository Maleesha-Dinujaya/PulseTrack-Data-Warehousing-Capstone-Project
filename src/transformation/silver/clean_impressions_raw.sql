DROP TABLE IF EXISTS silver.silver_impressions_clean;

CREATE TABLE silver.silver_impressions_clean AS 
SELECT 
    TRIM(impression_id) AS impression_id,
    TRIM(campaign_id) AS campaign_id,
    TRIM(creative_id) AS creative_id,

    -- If the Partner ID contains '_', take only the first part
    CASE 
        WHEN partner_id IS NULL OR TRIM(partner_id) = '' THEN NULL
        WHEN TRIM(partner_id) LIKE '%_%' THEN SPLIT_PART(TRIM(partner_id), '_', 1)
        ELSE TRIM(partner_id)
    END AS partner_id,

    -- Sub-partner tracking code (e.g., 598319)
    CASE 
        WHEN TRIM(partner_id) LIKE '%_%' THEN SPLIT_PART(TRIM(partner_id), '_', 2)
        ELSE NULL 
    END AS sub_partner_id,

    -- Impression Time standardization
    CASE 
        WHEN impression_time IS NULL OR TRIM(impression_time::TEXT) = '' THEN NULL
        WHEN TRIM(impression_time::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(impression_time::TEXT)::NUMERIC)
        WHEN TRIM(impression_time::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(impression_time::TEXT)::TIMESTAMP
        WHEN TRIM(impression_time::TEXT) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(impression_time::TEXT), 'Mon DD, YYYY')
        WHEN TRIM(impression_time::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(impression_time::TEXT), 'MM/DD/YYYY')
        WHEN TRIM(impression_time::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(impression_time::TEXT), 'DD-MM-YYYY')
        ELSE TRIM(impression_time::TEXT)::TIMESTAMP 
    END AS impression_time,

    -- Placement raw
    LOWER(TRIM(placement_raw)) AS placement,

    -- Country ISO-2 (UK -> GB, United States -> US)
    CASE 
        WHEN country IS NULL OR TRIM(country) = '' THEN NULL
        WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('US', 'USA', 'UNITED STATES') THEN 'US'
        WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('CA', 'CAN', 'CANADA') THEN 'CA'
        WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('AU', 'AUS', 'AUSTRALIA') THEN 'AU'
        WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('GB', 'GBR', 'UK', 'UNITED KINGDOM') THEN 'GB'
        ELSE UPPER(REPLACE(TRIM(country), '.', ''))
    END AS country,

    -- Device type
    CASE 
        WHEN LOWER(TRIM(device)) IN ('mob', 'mobile', 'iphone', 'android', 'ios') THEN 'mobile'
        WHEN LOWER(TRIM(device)) IN ('desk', 'desktop', 'macintosh', 'windows') THEN 'desktop'
        WHEN LOWER(TRIM(device)) IN ('tab', 'tablet', 'ipad') THEN 'tablet'
        ELSE LOWER(TRIM(device))
    END AS device,

    -- Bot Score (Numeric Cast)
    CASE 
        WHEN bot_score IS NULL OR TRIM(bot_score::TEXT) = '' THEN NULL
        ELSE TRIM(bot_score::TEXT)::DECIMAL(5,4)
    END AS bot_score,

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
FROM bronze.bronze_impressions_raw;
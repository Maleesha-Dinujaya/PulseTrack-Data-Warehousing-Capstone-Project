DROP TABLE IF EXISTS silver.silver_offers_clean;

CREATE TABLE silver.silver_offers_clean AS 
SELECT 
    TRIM(offer_id) AS offer_id,
    TRIM(offer_name) AS offer_name,
    TRIM(advertiser_id) AS advertiser_id,
    TRIM(vertical) AS vertical,

    -- Remove values like USD and $ from default_payout and convert to Numeric
    CASE 
        WHEN default_payout IS NULL OR TRIM(default_payout::TEXT) = '' THEN NULL 
        WHEN REGEXP_REPLACE(default_payout::TEXT, '[^0-9.]', '', 'g') = '' THEN NULL
        ELSE REGEXP_REPLACE(default_payout::TEXT, '[^0-9.]', '', 'g')::DECIMAL(10,2) 
    END AS default_payout,

    -- Uppercase the payout_type (e.g., cpa -> CPA)
    UPPER(TRIM(payout_type)) AS payout_type,

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
FROM bronze.bronze_offers_raw;
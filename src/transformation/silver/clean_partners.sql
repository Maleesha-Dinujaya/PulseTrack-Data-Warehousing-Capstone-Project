DROP TABLE IF EXISTS silver.silver_partners_clean;

CREATE TABLE silver.silver_partners_clean AS 
SELECT 
    TRIM(partner_id) AS partner_id,
    TRIM(partner_name) AS partner_name,
    LOWER(TRIM(channel)) AS channel,
    NULLIF(TRIM(media_buyer), '') AS media_buyer,
    
    -- join_date standardization (Unix, Dates, etc.)
    CASE 
        WHEN join_date IS NULL OR TRIM(join_date::TEXT) = '' THEN NULL
        WHEN TRIM(join_date::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(join_date::TEXT)::NUMERIC)
        WHEN TRIM(join_date::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(join_date::TEXT)::TIMESTAMP
        WHEN TRIM(join_date::TEXT) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(join_date::TEXT), 'Mon DD, YYYY')
        WHEN TRIM(join_date::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(join_date::TEXT), 'MM/DD/YYYY')
        WHEN TRIM(join_date::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(join_date::TEXT), 'DD-MM-YYYY')
        ELSE TRIM(join_date::TEXT)::TIMESTAMP 
    END AS join_date,

    TRIM(payment_terms) AS payment_terms,

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
FROM bronze.bronze_partners_raw;
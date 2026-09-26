DROP TABLE IF EXISTS silver.silver_conversions_clean;

CREATE TABLE silver.silver_conversions_clean AS 
WITH ranked_conversions AS (
    SELECT 
        TRIM(conversion_id) AS conversion_id,
        NULLIF(TRIM(click_id), '') AS click_id,
        TRIM(campaign_id) AS campaign_id,

        -- If the Partner ID contains '_', take only the first part
        CASE 
            WHEN partner_id IS NULL OR TRIM(partner_id) = '' THEN NULL
            WHEN TRIM(partner_id) LIKE '%_%' THEN SPLIT_PART(TRIM(partner_id), '_', 1)
            ELSE TRIM(partner_id)
        END AS partner_id,
        
        NULLIF(TRIM(sub_id), '') AS sub_id,

        -- Revenue clean 
        CASE 
            WHEN revenue IS NULL OR TRIM(revenue::TEXT) = '' THEN NULL 
            WHEN REGEXP_REPLACE(revenue::TEXT, '[^0-9.]', '', 'g') = '' THEN NULL
            ELSE REGEXP_REPLACE(revenue::TEXT, '[^0-9.]', '', 'g')::DECIMAL(10,2) 
        END AS revenue,

        -- Payout clean
        CASE 
            WHEN payout IS NULL OR TRIM(payout::TEXT) = '' THEN NULL 
            WHEN REGEXP_REPLACE(payout::TEXT, '[^0-9.]', '', 'g') = '' THEN NULL
            ELSE REGEXP_REPLACE(payout::TEXT, '[^0-9.]', '', 'g')::DECIMAL(10,2) 
        END AS payout,

        -- Currency code standard ($, USD, US$ -> USD)
        CASE 
            WHEN currency IS NULL OR TRIM(currency) = '' THEN 'USD'
            WHEN UPPER(TRIM(currency)) IN ('$', 'USD', 'US$') THEN 'USD'
            ELSE UPPER(TRIM(currency))
        END AS currency,

        -- Standardized Status
        CASE 
            WHEN LOWER(TRIM(status)) IN ('app', 'approved', 'approve', '1') THEN 'approved'
            WHEN LOWER(TRIM(status)) IN ('pend', 'pending', '0') THEN 'pending'
            WHEN LOWER(TRIM(status)) IN ('rev', 'reversed', 'reject', 'rejected', 'returned', '-1') THEN 'reversed'
            WHEN LOWER(TRIM(status)) IN ('declined', 'decline') THEN 'declined'
            ELSE LOWER(TRIM(status))
        END AS status,

        -- Country ISO-2
        CASE 
            WHEN country IS NULL OR TRIM(country) = '' THEN NULL
            WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('US', 'USA', 'UNITED STATES') THEN 'US'
            WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('CA', 'CAN', 'CANADA') THEN 'CA'
            WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('AU', 'AUS', 'AUSTRALIA') THEN 'AU'
            WHEN UPPER(REPLACE(TRIM(country), '.', '')) IN ('GB', 'GBR', 'UK', 'UNITED KINGDOM') THEN 'GB'
            ELSE UPPER(REPLACE(TRIM(country), '.', ''))
        END AS country,

        -- Device
        CASE 
            WHEN LOWER(TRIM(device)) IN ('mob', 'mobile', 'iphone', 'android', 'ios') THEN 'mobile'
            WHEN LOWER(TRIM(device)) IN ('desk', 'desktop', 'macintosh', 'windows') THEN 'desktop'
            WHEN LOWER(TRIM(device)) IN ('tab', 'tablet', 'ipad') THEN 'tablet'
            ELSE LOWER(TRIM(device))
        END AS device,

        -- is_test flag
        CASE 
            WHEN is_test IS NULL OR TRIM(is_test::TEXT) = '' THEN FALSE
            WHEN LOWER(TRIM(is_test::TEXT)) IN ('1', 'true', 't', 'y', 'yes') THEN TRUE
            ELSE FALSE 
        END AS is_test,

        -- conversion_time standardization
        CASE 
            WHEN conversion_time IS NULL OR TRIM(conversion_time::TEXT) = '' THEN NULL
            WHEN TRIM(conversion_time::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(conversion_time::TEXT)::NUMERIC)
            WHEN TRIM(conversion_time::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(conversion_time::TEXT)::TIMESTAMP
            WHEN TRIM(conversion_time::TEXT) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(conversion_time::TEXT), 'Mon DD, YYYY')
            WHEN TRIM(conversion_time::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(conversion_time::TEXT), 'MM/DD/YYYY')
            WHEN TRIM(conversion_time::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(conversion_time::TEXT), 'DD-MM-YYYY')
            ELSE TRIM(conversion_time::TEXT)::TIMESTAMP 
        END AS conversion_time,

        -- updated_at standardization
        CASE 
            WHEN updated_at IS NULL OR TRIM(updated_at::TEXT) = '' THEN NULL
            WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(updated_at::TEXT)::NUMERIC)
            WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(updated_at::TIMESTAMP::TEXT)::TIMESTAMP
            WHEN TRIM(updated_at::TEXT) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'Mon DD, YYYY')
            WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'MM/DD/YYYY')
            WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'DD-MM-YYYY')
            ELSE TRIM(updated_at::TEXT)::TIMESTAMP 
        END AS updated_at,

        ingested_at,
        source_file,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(conversion_id) 
            ORDER BY 
                CASE 
                    WHEN updated_at IS NULL OR TRIM(updated_at::TEXT) = '' THEN NULL
                    WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{10}$' THEN to_timestamp(TRIM(updated_at::TEXT)::NUMERIC)
                    WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T]' THEN TRIM(updated_at::TIMESTAMP::TEXT)::TIMESTAMP
                    WHEN TRIM(updated_at::TEXT) ~ '^[A-Za-z]{3} [0-9]{1,2}, \d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'Mon DD, YYYY')
                    WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}/[0-9]{1,2}/\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'MM/DD/YYYY')
                    WHEN TRIM(updated_at::TEXT) ~ '^[0-9]{1,2}-[0-9]{1,2}-\d{4}' THEN to_timestamp(TRIM(updated_at::TEXT), 'DD-MM-YYYY')
                    ELSE TRIM(updated_at::TEXT)::TIMESTAMP 
                END DESC NULLS LAST
        ) AS rn
    FROM bronze.bronze_conversions_raw
)
SELECT 
    conversion_id,
    click_id,
    campaign_id,
    partner_id,
    sub_id,
    revenue,
    payout,
    currency,
    status,
    country,
    device,
    is_test,
    conversion_time,
    updated_at,
    ingested_at,
    source_file
FROM ranked_conversions
WHERE rn = 1;
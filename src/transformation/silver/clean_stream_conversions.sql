DROP TABLE IF EXISTS silver.silver_stream_conversions_clean;

CREATE TABLE silver.silver_stream_conversions_clean AS 
WITH parsed_logs AS (
    SELECT 
        -- Extract JSON block between { and } and normalize quotes
        CAST(
            REPLACE(
                (REGEXP_MATCHES(raw_log_line, '(\{.*\})'))[1], 
                '""', 
                '"'
            ) AS JSONB
        ) AS payload,
        ingested_at,
        source_file
    FROM bronze.bronze_stream_conversions
    WHERE raw_log_line ~ '\{.*\}'
)
SELECT 
    TRIM(payload ->> 'event_id') AS event_id,
    LOWER(TRIM(payload ->> 'event_type')) AS event_type,
    TRIM(payload ->> 'conversion_id') AS conversion_id,
    TRIM(payload ->> 'campaign_id') AS campaign_id,

    CASE 
        WHEN (payload ->> 'partner_id') IS NULL OR TRIM(payload ->> 'partner_id') = '' THEN NULL
        WHEN TRIM(payload ->> 'partner_id') LIKE '%_%' THEN SPLIT_PART(TRIM(payload ->> 'partner_id'), '_', 1)
        ELSE TRIM(payload ->> 'partner_id')
    END AS partner_id,

    CASE 
        WHEN TRIM(payload ->> 'partner_id') LIKE '%_%' THEN SPLIT_PART(TRIM(payload ->> 'partner_id'), '_', 2)
        ELSE NULL 
    END AS sub_partner_id,

    NULLIF(TRIM(payload ->> 'click_id'), '') AS click_id,

    CASE 
        WHEN (payload ->> 'revenue') IS NULL OR TRIM(payload ->> 'revenue') = '' THEN NULL 
        WHEN REGEXP_REPLACE(payload ->> 'revenue', '[^0-9.\-]', '', 'g') = '' THEN NULL
        ELSE REGEXP_REPLACE(payload ->> 'revenue', '[^0-9.\-]', '', 'g')::DECIMAL(10,2) 
    END AS revenue,

    CASE 
        WHEN (payload ->> 'payout') IS NULL OR TRIM(payload ->> 'payout') = '' THEN NULL 
        WHEN REGEXP_REPLACE(payload ->> 'payout', '[^0-9.\-]', '', 'g') = '' THEN NULL
        ELSE REGEXP_REPLACE(payload ->> 'payout', '[^0-9.\-]', '', 'g')::DECIMAL(10,2) 
    END AS payout,

    CASE 
        WHEN (payload ->> 'currency') IS NULL OR TRIM(payload ->> 'currency') = '' THEN 'USD'
        WHEN UPPER(TRIM(payload ->> 'currency')) IN ('$', 'USD', 'US$') THEN 'USD'
        ELSE UPPER(TRIM(payload ->> 'currency'))
    END AS currency,

    CASE 
        WHEN LOWER(TRIM(payload ->> 'status')) IN ('app', 'approved', 'approve', '1') THEN 'approved'
        WHEN LOWER(TRIM(payload ->> 'status')) IN ('pend', 'pending', '0') THEN 'pending'
        WHEN LOWER(TRIM(payload ->> 'status')) IN ('rev', 'reversed', 'reject', 'rejected', 'returned', '-1', 'chargeback') THEN 'reversed'
        WHEN LOWER(TRIM(payload ->> 'status')) IN ('declined', 'decline') THEN 'declined'
        ELSE LOWER(TRIM(payload ->> 'status'))
    END AS status,

    CASE 
        WHEN (payload ->> 'is_test') IS NULL OR TRIM(payload ->> 'is_test') = '' THEN FALSE
        WHEN LOWER(TRIM(payload ->> 'is_test')) IN ('1', 'true', 't', 'y', 'yes') THEN TRUE
        ELSE FALSE 
    END AS is_test,

    CASE 
        WHEN (payload ->> 'occurred_at') IS NULL OR TRIM(payload ->> 'occurred_at') = '' THEN NULL
        ELSE (payload ->> 'occurred_at')::TIMESTAMP 
    END AS occurred_at,

    ingested_at,
    source_file
FROM parsed_logs;
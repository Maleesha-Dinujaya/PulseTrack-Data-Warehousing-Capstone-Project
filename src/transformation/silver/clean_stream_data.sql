DROP TABLE IF EXISTS silver.stream_conversions_clean;

CREATE TABLE silver.stream_conversions_clean AS
WITH extracted_json AS (
    SELECT 
        -- Cut the portion from the first '{' sign to the end and convert it to JSONB
        SUBSTRING(raw_log_line FROM '\{.*\}')::jsonb AS payload,
        ingested_at
    FROM bronze.bronze_stream_conversions
)
SELECT 
    payload ->> 'event_id' AS event_id,
    payload ->> 'event_type' AS event_type,
    payload ->> 'conversion_id' AS conversion_id,
    payload ->> 'campaign_id' AS campaign_id,
    payload ->> 'partner_id' AS partner_id,
    payload ->> 'click_id' AS click_id,
    -- The values in the JSON are already in target (Numeric) form, so they can be cast to DECIMAL directly
    (payload ->> 'revenue')::DECIMAL(10,2) AS revenue,
    (payload ->> 'payout')::DECIMAL(10,2) AS payout,
    payload ->> 'currency' AS currency,
    payload ->> 'status' AS status,
    -- 'is_test' is a Boolean (True/False), so convert it to BOOLEAN
    (payload ->> 'is_test')::BOOLEAN AS is_test,
    -- Convert the date and time to TIMESTAMP
    (payload ->> 'occurred_at')::TIMESTAMP AS occurred_at,
    ingested_at
FROM extracted_json;
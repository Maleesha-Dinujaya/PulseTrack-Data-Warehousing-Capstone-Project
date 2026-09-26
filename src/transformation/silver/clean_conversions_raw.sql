-- Create a Clean Table by removing Duplicates from the Conversions data
DROP TABLE IF EXISTS silver.conversions_clean;

CREATE TABLE silver.conversions_clean AS
WITH ranked_conversions AS (
    SELECT 
        *,
        -- Using the 'updated_at' column to bring the latest record to the top
        ROW_NUMBER() OVER(PARTITION BY conversion_id ORDER BY updated_at DESC) as rn
    FROM bronze.bronze_conversions_raw
)
SELECT 
    conversion_id,
    click_id,
    campaign_id,
    partner_id,
    -- Convert empty values (Empty strings) to NULL, remove 'USD' and '$', and cast to Decimal
    CAST(NULLIF(TRIM(REPLACE(REPLACE(revenue, '$', ''), 'USD', '')), '') AS DECIMAL(10,2)) AS revenue,
    CAST(NULLIF(TRIM(REPLACE(REPLACE(payout, '$', ''), 'USD', '')), '') AS DECIMAL(10,2)) AS payout,
    status,
    country,
    device,
    conversion_time,
    updated_at,
    ingested_at
FROM ranked_conversions
WHERE rn = 1;
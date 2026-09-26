DROP TABLE IF EXISTS silver.revenue_adjustments_clean;

CREATE TABLE silver.revenue_adjustments_clean AS
SELECT 
    adjustment_id,
    conversion_id,
    -- Remove '$' and 'USD' and convert to a number
    CAST(REPLACE(REPLACE(REPLACE(amount, '$', ''), 'USD', ''), ' ', '') AS DECIMAL(10,2)) AS adjustment_amount,
    "timestamp",
    ingested_at
FROM bronze.bronze_revenue_adjustments_raw;
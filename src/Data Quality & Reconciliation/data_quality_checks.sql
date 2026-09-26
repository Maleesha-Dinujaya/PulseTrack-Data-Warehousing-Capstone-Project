-- =====================================================================
-- Question 6: Data Quality, Reconciliation & Audit Checks
-- =====================================================================

-- 1. RECONCILIATION (Row count comparison)
-- Check whether the number of records in Silver equals the number in Gold.
SELECT 
    'Conversions' AS entity,
    (SELECT COUNT(*) FROM silver.silver_conversions_clean) AS silver_row_count,
    (SELECT COUNT(*) FROM gold.fact_conversions) AS gold_row_count,
    (SELECT COUNT(*) FROM silver.silver_conversions_clean) - (SELECT COUNT(*) FROM gold.fact_conversions) AS dropped_rows
UNION ALL
SELECT 
    'Clicks' AS entity,
    (SELECT COUNT(*) FROM silver.silver_clicks_clean) AS silver_row_count,
    (SELECT COUNT(*) FROM gold.fact_clicks) AS gold_row_count,
    (SELECT COUNT(*) FROM silver.silver_clicks_clean) - (SELECT COUNT(*) FROM gold.fact_clicks) AS dropped_rows;


-- 2. DATA QUALITY: Referential Integrity (Checking relationship validity)
-- Check how many Fact table records have a missing Campaign (UNKNOWN / -1).
SELECT 
    'fact_conversions' AS table_name,
    'Missing Campaign (SK = -1)' AS issue_type,
    COUNT(*) AS issue_count
FROM gold.fact_conversions
WHERE campaign_sk = -1
UNION ALL
SELECT 
    'fact_clicks' AS table_name,
    'Missing Partner (SK = -1)' AS issue_type,
    COUNT(*) AS issue_count
FROM gold.fact_clicks
WHERE partner_sk = -1;


-- 3. DATA QUALITY: Null Checks (Checking for empty values)
-- Check whether Primary Keys contain empty values (NULLs).
-- (The expected result here is 0)
SELECT 
    'fact_conversions' AS table_name,
    'Null Conversion IDs' AS issue_type,
    COUNT(*) AS issue_count
FROM gold.fact_conversions
WHERE conversion_id IS NULL;


-- 4. BUSINESS RULE VALIDATION (Business rule verification)
-- Check whether there are Conversions where Payout (cost) is greater than Revenue (income).
SELECT 
    conversion_id,
    revenue,
    payout,
    (revenue - payout) AS profit
FROM gold.fact_conversions
WHERE payout > revenue;


-- 5. AUDIT LOG CHECK (Checking the log book)
-- Query that reads the details of the Audit Table we created earlier.
SELECT 
    run_id, 
    pipeline_name, 
    start_time, 
    end_time, 
    status, 
    source_record_count, 
    inserted_count
FROM audit.pipeline_runs
ORDER BY start_time DESC
LIMIT 10;
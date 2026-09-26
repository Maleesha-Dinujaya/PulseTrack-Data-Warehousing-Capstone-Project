DROP TABLE IF EXISTS gold.fact_revenue_adjustments CASCADE;

CREATE TABLE gold.fact_revenue_adjustments (
    adjustment_id VARCHAR(50) PRIMARY KEY,
    date_sk INT NOT NULL,
    conversion_id VARCHAR(50) NOT NULL,
    
    -- Metrics (amount differences)
    delta_amount DECIMAL(10,2),
    
    -- Attributes
    reason VARCHAR(100),
    adjusted_at TIMESTAMP
);

INSERT INTO gold.fact_revenue_adjustments (
    adjustment_id,
    date_sk,
    conversion_id,
    delta_amount,
    reason,
    adjusted_at
)
SELECT 
    a.adjustment_id,
    
    -- Building the Date SK
    COALESCE(to_char(a.adjusted_at::DATE, 'YYYYMMDD')::INT, -1) AS date_sk,
    
    a.conversion_id,
    a.delta_amount::DECIMAL(10,2),
    a.reason,
    a.adjusted_at::TIMESTAMP
    
FROM silver.silver_revenue_adjustments_clean a
WHERE a.adjustment_id IS NOT NULL;
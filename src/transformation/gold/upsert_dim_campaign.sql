-- No DROP TABLE here. The table is already created and kept.

INSERT INTO gold.dim_campaign (
    campaign_id, 
    campaign_name, 
    price_type, 
    start_date, 
    end_date, 
    created_at, 
    updated_at
)
SELECT DISTINCT
    campaign_id,
    campaign_name,
    price_type,
    start_date::TIMESTAMP,
    end_date::TIMESTAMP,
    created_at::TIMESTAMP,
    updated_at::TIMESTAMP
FROM silver.silver_campaigns_clean
WHERE campaign_id IS NOT NULL

-- This is the magic of Question 5! (Idempotency)
-- If this Campaign ID already exists, update it with the new details.
ON CONFLICT (campaign_id) 
DO UPDATE SET 
    campaign_name = EXCLUDED.campaign_name,
    price_type = EXCLUDED.price_type,
    end_date = EXCLUDED.end_date,
    updated_at = EXCLUDED.updated_at;
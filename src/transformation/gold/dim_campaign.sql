DROP TABLE IF EXISTS gold.dim_campaign CASCADE;

CREATE TABLE gold.dim_campaign (
    campaign_sk SERIAL PRIMARY KEY,
    campaign_id VARCHAR(50) UNIQUE NOT NULL,
    campaign_name VARCHAR(255),
    price_type VARCHAR(50),
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

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
WHERE campaign_id IS NOT NULL;

-- Default Unknown row for unmatched facts
INSERT INTO gold.dim_campaign (campaign_sk, campaign_id, campaign_name, price_type)
VALUES (-1, 'UNKNOWN', 'Unknown Campaign', 'Unknown')
ON CONFLICT (campaign_sk) DO NOTHING;
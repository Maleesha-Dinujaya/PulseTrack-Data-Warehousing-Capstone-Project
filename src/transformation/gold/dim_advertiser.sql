DROP TABLE IF EXISTS gold.dim_advertiser CASCADE;

CREATE TABLE gold.dim_advertiser (
    advertiser_sk SERIAL PRIMARY KEY,
    advertiser_id VARCHAR(50) UNIQUE NOT NULL,
    advertiser_name VARCHAR(255),
    vertical VARCHAR(100),
    status VARCHAR(50),
    signup_date TIMESTAMP,
    billing_country VARCHAR(10),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

INSERT INTO gold.dim_advertiser (
    advertiser_id,
    advertiser_name,
    vertical,
    status,
    signup_date,
    billing_country,
    created_at,
    updated_at
)
SELECT DISTINCT
    advertiser_id,
    advertiser_name,
    vertical,
    status,
    signup_date::TIMESTAMP,
    billing_country,
    created_at::TIMESTAMP,
    updated_at::TIMESTAMP
FROM silver.silver_advertisers_clean
WHERE advertiser_id IS NOT NULL;

-- Default Unknown row for unmatched facts
INSERT INTO gold.dim_advertiser (advertiser_sk, advertiser_id, advertiser_name, status)
VALUES (-1, 'UNKNOWN', 'Unknown Advertiser', 'Unknown')
ON CONFLICT (advertiser_sk) DO NOTHING;
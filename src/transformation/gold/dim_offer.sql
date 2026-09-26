DROP TABLE IF EXISTS gold.dim_offer CASCADE;

CREATE TABLE gold.dim_offer (
    offer_sk SERIAL PRIMARY KEY,
    offer_id VARCHAR(50) UNIQUE NOT NULL,
    offer_name VARCHAR(255),
    vertical VARCHAR(100),
    default_payout DECIMAL(10,2),
    payout_type VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

INSERT INTO gold.dim_offer (
    offer_id,
    offer_name,
    vertical,
    default_payout,
    payout_type,
    created_at,
    updated_at
)
SELECT DISTINCT
    offer_id,
    offer_name,
    vertical,
    default_payout,
    payout_type,
    created_at::TIMESTAMP,
    updated_at::TIMESTAMP
FROM silver.silver_offers_clean
WHERE offer_id IS NOT NULL;

-- Default Unknown row for unmatched facts
INSERT INTO gold.dim_offer (offer_sk, offer_id, offer_name, vertical)
VALUES (-1, 'UNKNOWN', 'Unknown Offer', 'Unknown')
ON CONFLICT (offer_sk) DO NOTHING;
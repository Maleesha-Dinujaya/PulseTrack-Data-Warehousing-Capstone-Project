DROP TABLE IF EXISTS gold.dim_partner CASCADE;

CREATE TABLE gold.dim_partner (
    partner_sk SERIAL PRIMARY KEY,
    partner_id VARCHAR(50) UNIQUE NOT NULL,
    partner_name VARCHAR(255),
    channel VARCHAR(100),
    media_buyer VARCHAR(255),
    join_date TIMESTAMP,
    payment_terms VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

INSERT INTO gold.dim_partner (
    partner_id,
    partner_name,
    channel,
    media_buyer,
    join_date,
    payment_terms,
    created_at,
    updated_at
)
SELECT DISTINCT
    partner_id,
    partner_name,
    channel,
    media_buyer,
    join_date::TIMESTAMP,
    payment_terms,
    created_at::TIMESTAMP,
    updated_at::TIMESTAMP
FROM silver.silver_partners_clean
WHERE partner_id IS NOT NULL;

-- Default Unknown row for unmatched facts
INSERT INTO gold.dim_partner (partner_sk, partner_id, partner_name, channel)
VALUES (-1, 'UNKNOWN', 'Unknown Partner', 'Unknown')
ON CONFLICT (partner_sk) DO NOTHING;
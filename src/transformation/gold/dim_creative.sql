DROP TABLE IF EXISTS gold.dim_creative CASCADE;

CREATE TABLE gold.dim_creative (
    creative_sk SERIAL PRIMARY KEY,
    creative_id VARCHAR(50) UNIQUE NOT NULL,
    creative_name VARCHAR(255),
    format VARCHAR(100),
    size VARCHAR(50),
    landing_url TEXT,
    created_at TIMESTAMP
);

INSERT INTO gold.dim_creative (creative_id, creative_name, format, size, landing_url, created_at)
SELECT DISTINCT
    creative_id,
    creative_name,
    format,
    size,
    landing_url,
    created_at
FROM silver.silver_creatives_clean
WHERE creative_id IS NOT NULL;

-- Default Unknown row for unmatched facts
INSERT INTO gold.dim_creative (creative_sk, creative_id, creative_name, format, size)
VALUES (-1, 'UNKNOWN', 'Unknown Creative', 'Unknown', 'Unknown')
ON CONFLICT (creative_sk) DO NOTHING;
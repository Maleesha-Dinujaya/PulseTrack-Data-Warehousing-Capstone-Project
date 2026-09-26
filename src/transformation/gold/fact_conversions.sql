DROP TABLE IF EXISTS gold.fact_clicks CASCADE;

CREATE TABLE gold.fact_clicks (
    click_id VARCHAR(50) PRIMARY KEY,
    date_sk INT NOT NULL,
    impression_id VARCHAR(50),
    campaign_sk INT NOT NULL,
    creative_sk INT NOT NULL,
    partner_sk INT NOT NULL,
    
    click_time TIMESTAMP,
    ip VARCHAR(50),
    user_agent TEXT,
    country VARCHAR(10),
    device VARCHAR(50),
    is_unique BOOLEAN,
    referrer_raw TEXT
);

INSERT INTO gold.fact_clicks (
    click_id,
    date_sk,
    impression_id,
    campaign_sk,
    creative_sk,
    partner_sk,
    click_time,
    ip,
    user_agent,
    country,
    device,
    is_unique,
    referrer_raw
)
SELECT 
    c.click_id,
    COALESCE(to_char(c.click_time::DATE, 'YYYYMMDD')::INT, -1) AS date_sk,
    c.impression_id,
    
    COALESCE(cmp.campaign_sk, -1) AS campaign_sk,
    COALESCE(crt.creative_sk, -1) AS creative_sk,
    COALESCE(p.partner_sk, -1) AS partner_sk,
    
    c.click_time::TIMESTAMP,
    c.ip,
    c.user_agent,
    c.country,
    c.device,
    c.is_unique::BOOLEAN,
    c.referrer_raw
    
FROM silver.silver_clicks_clean c

LEFT JOIN gold.dim_campaign cmp ON cmp.campaign_id = c.campaign_id
LEFT JOIN gold.dim_creative crt ON crt.creative_id = c.creative_id
-- Extracting the main partner_id from formats like '11845_198503'
LEFT JOIN gold.dim_partner p ON p.partner_id = SPLIT_PART(c.partner_id, '_', 1)

WHERE c.click_id IS NOT NULL;
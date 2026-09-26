DROP TABLE IF EXISTS gold.fact_impressions CASCADE;

CREATE TABLE gold.fact_impressions (
    impression_id VARCHAR(50) PRIMARY KEY,
    
    -- Surrogate Keys
    date_sk INT NOT NULL,
    campaign_sk INT NOT NULL,
    creative_sk INT NOT NULL,
    partner_sk INT NOT NULL,
    
    -- Attributes & Metrics
    sub_partner_id VARCHAR(50),
    impression_time TIMESTAMP,
    placement VARCHAR(50),
    country VARCHAR(10),
    device VARCHAR(50),
    bot_score DECIMAL(5,4)
);

INSERT INTO gold.fact_impressions (
    impression_id,
    date_sk,
    campaign_sk,
    creative_sk,
    partner_sk,
    sub_partner_id,
    impression_time,
    placement,
    country,
    device,
    bot_score
)
SELECT 
    i.impression_id,
    
    -- Deriving the Date SK (extract the date from the Timestamp and convert it to a Format like 20260206)
    COALESCE(to_char(i.impression_time::DATE, 'YYYYMMDD')::INT, -1) AS date_sk,
    
    COALESCE(cmp.campaign_sk, -1) AS campaign_sk,
    COALESCE(crt.creative_sk, -1) AS creative_sk,
    COALESCE(p.partner_sk, -1) AS partner_sk,
    
    i.sub_partner_id,
    i.impression_time::TIMESTAMP,
    i.placement,
    i.country,
    i.device,
    i.bot_score::DECIMAL(5,4)
    
FROM silver.silver_impressions_clean i

-- Joining with the Dimension Tables
LEFT JOIN gold.dim_campaign cmp ON cmp.campaign_id = i.campaign_id
LEFT JOIN gold.dim_creative crt ON crt.creative_id = i.creative_id
LEFT JOIN gold.dim_partner p ON p.partner_id = i.partner_id
WHERE i.impression_id IS NOT NULL;
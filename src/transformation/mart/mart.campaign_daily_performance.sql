-- 1. Create a new schema to hold the Data Mart (no problem if it already exists)
CREATE SCHEMA IF NOT EXISTS mart;

-- 2. Drop it if it already exists 
DROP TABLE IF EXISTS mart.campaign_daily_performance;

-- 3. Build the Data Mart Table
CREATE TABLE mart.campaign_daily_performance AS
WITH agg_impressions AS (
    SELECT date_sk, campaign_sk, COUNT(impression_id) AS total_impressions
    FROM gold.fact_impressions
    GROUP BY date_sk, campaign_sk
),
agg_clicks AS (
    SELECT date_sk, campaign_sk, COUNT(click_id) AS total_clicks
    FROM gold.fact_clicks
    GROUP BY date_sk, campaign_sk
),
agg_conversions AS (
    SELECT date_sk, campaign_sk, 
           COUNT(conversion_id) AS total_conversions,
           SUM(revenue) AS total_revenue,
           SUM(payout) AS total_payout
    FROM gold.fact_conversions
    GROUP BY date_sk, campaign_sk
)
SELECT 
    -- Dimensions (description)
    COALESCE(i.date_sk, cl.date_sk, cv.date_sk) AS date_sk,
    COALESCE(i.campaign_sk, cl.campaign_sk, cv.campaign_sk) AS campaign_sk,
    c.campaign_name,
    
    -- Base Measures (primary measurements)
    COALESCE(i.total_impressions, 0) AS impressions,
    COALESCE(cl.total_clicks, 0) AS clicks,
    COALESCE(cv.total_conversions, 0) AS conversions,
    COALESCE(cv.total_revenue, 0.00) AS revenue,
    COALESCE(cv.total_payout, 0.00) AS payout,
    
    -- Calculated Metrics / KPIs (computed measurements)
    
    -- 1. Click-Through Rate (CTR) = (Clicks / Impressions) * 100
    CASE WHEN COALESCE(i.total_impressions, 0) > 0 
         THEN ROUND((COALESCE(cl.total_clicks, 0)::DECIMAL / i.total_impressions) * 100, 2) 
         ELSE 0.00 END AS ctr_percentage,
         
    -- 2. Conversion Rate = (Conversions / Clicks) * 100
    CASE WHEN COALESCE(cl.total_clicks, 0) > 0 
         THEN ROUND((COALESCE(cv.total_conversions, 0)::DECIMAL / cl.total_clicks) * 100, 2) 
         ELSE 0.00 END AS conversion_rate_percentage,
         
    -- 3. Revenue Per Click (RPC) = Revenue / Clicks
    CASE WHEN COALESCE(cl.total_clicks, 0) > 0 
         THEN ROUND(COALESCE(cv.total_revenue, 0.00) / cl.total_clicks, 2) 
         ELSE 0.00 END AS revenue_per_click,

    -- 4. Profit (gain) = Revenue - Payout
    (COALESCE(cv.total_revenue, 0.00) - COALESCE(cv.total_payout, 0.00)) AS profit

FROM agg_impressions i
FULL OUTER JOIN agg_clicks cl ON i.date_sk = cl.date_sk AND i.campaign_sk = cl.campaign_sk
FULL OUTER JOIN agg_conversions cv ON COALESCE(i.date_sk, cl.date_sk) = cv.date_sk AND COALESCE(i.campaign_sk, cl.campaign_sk) = cv.campaign_sk

-- Here we JOIN only with dim_campaign (to avoid doubling the Advertiser rows)
LEFT JOIN gold.dim_campaign c ON COALESCE(i.campaign_sk, cl.campaign_sk, cv.campaign_sk) = c.campaign_sk;
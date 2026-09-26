WITH CreativePerformance AS (
    -- Step 1: Calculate Impressions, Clicks and CTR for each Creative
    SELECT 
        c.campaign_name,
        cr.creative_name,
        COUNT(DISTINCT i.impression_id) AS creative_impressions,
        COUNT(DISTINCT cl.click_id) AS creative_clicks,
        ROUND((COUNT(DISTINCT cl.click_id)::DECIMAL / NULLIF(COUNT(DISTINCT i.impression_id), 0)) * 100, 2) AS creative_ctr
    FROM gold.fact_impressions i
    LEFT JOIN gold.fact_clicks cl ON i.impression_id = cl.impression_id
    JOIN gold.dim_campaign c ON i.campaign_sk = c.campaign_sk
    JOIN gold.dim_creative cr ON i.creative_sk = cr.creative_sk
    GROUP BY c.campaign_name, cr.creative_name
    HAVING COUNT(DISTINCT i.impression_id) >= 100 -- Minimum sample threshold to avoid random results
),
CampaignBenchmarks AS (
    -- Step 2: Find the average CTR of a Campaign using a Window Function
    SELECT 
        campaign_name,
        creative_name,
        creative_impressions,
        creative_clicks,
        creative_ctr,
        ROUND(AVG(creative_ctr) OVER(PARTITION BY campaign_name), 2) AS campaign_avg_ctr
    FROM CreativePerformance
)
-- Step 3: Filter Creatives that are below the Campaign average
SELECT 
    campaign_name,
    creative_name,
    creative_ctr,
    campaign_avg_ctr,
    (campaign_avg_ctr - creative_ctr) AS underperformance_gap
FROM CampaignBenchmarks
WHERE creative_ctr < campaign_avg_ctr
ORDER BY underperformance_gap DESC
LIMIT 10;
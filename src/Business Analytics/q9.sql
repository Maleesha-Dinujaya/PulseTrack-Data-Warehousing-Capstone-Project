WITH MonthlyCampaignMetrics AS (
    SELECT 
        c.campaign_name,
        d.year,
        d.month,
        SUM(m.impressions) AS total_impressions,
        SUM(m.conversions) AS total_conversions
    FROM mart.campaign_daily_performance m
    JOIN gold.dim_campaign c ON m.campaign_sk = c.campaign_sk
    JOIN gold.dim_date d ON m.date_sk = d.date_sk
    GROUP BY c.campaign_name, d.year, d.month
),
MetricTrends AS (
    SELECT 
        campaign_name,
        year,
        month,
        total_impressions,
        total_conversions,
        LAG(total_impressions) OVER (PARTITION BY campaign_name ORDER BY year, month) AS prev_impressions,
        LAG(total_conversions) OVER (PARTITION BY campaign_name ORDER BY year, month) AS prev_conversions
    FROM MonthlyCampaignMetrics
)
SELECT 
    campaign_name,
    year,
    month,
    prev_impressions,
    total_impressions,
    (total_impressions - prev_impressions) AS impression_increase,
    prev_conversions,
    total_conversions,
    (total_conversions - prev_conversions) AS conversion_decline
FROM MetricTrends
WHERE total_impressions > prev_impressions 
  AND total_conversions < prev_conversions
ORDER BY impression_increase DESC, conversion_decline ASC;
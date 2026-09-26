SELECT 
    campaign_name,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(conversions) AS total_conversions,
    -- Overall CTR at campaign level: (Clicks / Impressions) * 100
    ROUND((SUM(clicks)::DECIMAL / NULLIF(SUM(impressions), 0)) * 100, 2) AS overall_ctr_percentage,
    -- Overall Conversion Rate at campaign level: (Conversions / Clicks) * 100
    ROUND((SUM(conversions)::DECIMAL / NULLIF(SUM(clicks), 0)) * 100, 2) AS overall_conv_rate_percentage
FROM mart.campaign_daily_performance
GROUP BY campaign_name
HAVING SUM(impressions) >= 500 -- Minimum impressions threshold for a reliable sample
ORDER BY overall_ctr_percentage DESC, overall_conv_rate_percentage ASC
LIMIT 5;
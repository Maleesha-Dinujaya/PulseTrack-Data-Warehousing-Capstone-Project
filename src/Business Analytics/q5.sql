WITH TotalRevenue AS (
    SELECT SUM(revenue) AS grand_total_revenue 
    FROM mart.campaign_daily_performance
)
SELECT 
    c.campaign_name,
    SUM(c.revenue) AS campaign_revenue,
    t.grand_total_revenue,
    ROUND((SUM(c.revenue) / NULLIF(t.grand_total_revenue, 0)) * 100, 2) AS contribution_percentage
FROM mart.campaign_daily_performance c
CROSS JOIN TotalRevenue t
GROUP BY c.campaign_name, t.grand_total_revenue
ORDER BY contribution_percentage DESC
LIMIT 10;
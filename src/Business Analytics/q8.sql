WITH TotalRevenue AS (
    SELECT SUM(revenue) AS grand_total_revenue 
    FROM gold.fact_conversions
)
SELECT 
    p.partner_name,
    SUM(f.revenue) AS partner_revenue,
    t.grand_total_revenue,
    ROUND((SUM(f.revenue) / NULLIF(t.grand_total_revenue, 0)) * 100, 2) AS partner_revenue_percentage
FROM gold.fact_conversions f
JOIN gold.dim_partner p ON f.partner_sk = p.partner_sk
CROSS JOIN TotalRevenue t
GROUP BY p.partner_name, t.grand_total_revenue
ORDER BY partner_revenue_percentage DESC;
SELECT 
    d.partner_name,
    SUM(f.revenue) AS total_revenue       -- 1. Summed here
FROM gold.dim_partner d
JOIN gold.fact_conversions f ON d.partner_sk = f.partner_sk
GROUP BY d.partner_name                   -- 2. Grouped by partner name
ORDER BY total_revenue DESC               -- 3. Sorted so the highest comes first
LIMIT 10;
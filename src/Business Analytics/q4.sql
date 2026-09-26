WITH MonthlyRevenue AS (
    -- Step 1: Aggregate revenue month over month
    SELECT 
        d.month,
        SUM(f.revenue) AS current_revenue
    FROM gold.fact_conversions f
    JOIN gold.dim_date d ON f.date_sk = d.date_sk
    GROUP BY d.month
)
SELECT 
    month,
    current_revenue,
    -- Step 2: Pull in the previous month's revenue
    LAG(current_revenue) OVER (ORDER BY month) AS previous_month_revenue,
    
    -- Step 3: Difference and percentage (MoM Growth %)
    ROUND(
        ((current_revenue - LAG(current_revenue) OVER (ORDER BY month)) / 
        NULLIF(LAG(current_revenue) OVER (ORDER BY month), 0)) * 100, 
        2
    ) AS mom_change_percentage
FROM MonthlyRevenue
ORDER BY month ASC;
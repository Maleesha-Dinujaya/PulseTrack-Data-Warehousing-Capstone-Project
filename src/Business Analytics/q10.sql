WITH GrossRevenue AS (
    SELECT COALESCE(SUM(revenue), 0.00) AS total_gross_revenue 
    FROM gold.fact_conversions
),
AdjustmentsSummary AS (
    SELECT 
        COALESCE(SUM(delta_amount), 0.00) AS total_adjustment_impact,
        COUNT(adjustment_id) AS total_adjustment_events
    FROM gold.fact_revenue_adjustments
)
SELECT 
    g.total_gross_revenue,
    a.total_adjustment_impact,
    (g.total_gross_revenue + a.total_adjustment_impact) AS net_revenue,
    a.total_adjustment_events,
    ROUND((ABS(a.total_adjustment_impact) / NULLIF(g.total_gross_revenue, 0)) * 100, 2) AS revenue_erosion_percentage
FROM GrossRevenue g
CROSS JOIN AdjustmentsSummary a;
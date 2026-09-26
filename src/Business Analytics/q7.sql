WITH UnnestedHistory AS (
    -- Step 1: Unnest Manager transitions and their validity periods from the JSON array
    SELECT 
        s.advertiser_id,
        s.advertiser_name,
        elem->>'am_id' AS am_id,
        elem->>'am_name' AS am_name,
        (elem->>'from')::TIMESTAMP AS valid_from,
        COALESCE((elem->>'to')::TIMESTAMP, '9999-12-31'::TIMESTAMP) AS valid_to
    FROM silver.silver_advertiser_accounts_clean s,
         jsonb_array_elements(s.account_manager_history) AS elem
    WHERE jsonb_array_length(s.account_manager_history) > 1
),
ManagerPerformance AS (
    -- Step 2: Aggregate Revenue and Conversions by matching conversion_time to the relevant Manager's period
    SELECT 
        h.advertiser_id,
        h.advertiser_name,
        h.am_name,
        h.valid_from,
        h.valid_to,
        COALESCE(SUM(f.revenue), 0.00) AS total_revenue,
        COUNT(f.conversion_id) AS total_conversions
    FROM UnnestedHistory h
    JOIN gold.dim_advertiser a ON h.advertiser_id = a.advertiser_id
    LEFT JOIN gold.fact_conversions f 
        ON a.advertiser_sk = f.advertiser_sk 
        AND f.conversion_time >= h.valid_from 
        AND f.conversion_time < h.valid_to
    GROUP BY 
        h.advertiser_id, 
        h.advertiser_name, 
        h.am_name, 
        h.valid_from, 
        h.valid_to
),
ManagerTransitions AS (
    -- Step 3: Get the previous Manager's values using LAG
    SELECT 
        advertiser_name,
        am_name AS current_manager,
        total_revenue AS revenue_after,
        total_conversions AS conversions_after,
        LAG(am_name) OVER (PARTITION BY advertiser_id ORDER BY valid_from) AS previous_manager,
        LAG(total_revenue) OVER (PARTITION BY advertiser_id ORDER BY valid_from) AS revenue_before,
        LAG(total_conversions) OVER (PARTITION BY advertiser_id ORDER BY valid_from) AS conversions_before
    FROM ManagerPerformance
)
-- Step 4: Calculate the Before vs After difference
SELECT 
    advertiser_name,
    previous_manager,
    current_manager,
    revenue_before,
    revenue_after,
    (revenue_after - revenue_before) AS revenue_difference,
    ROUND(
        ((revenue_after - revenue_before) / NULLIF(revenue_before, 0)) * 100, 
        2
    ) AS revenue_growth_percentage
FROM ManagerTransitions
WHERE previous_manager IS NOT NULL
ORDER BY revenue_difference DESC;
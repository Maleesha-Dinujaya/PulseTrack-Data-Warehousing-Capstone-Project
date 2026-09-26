WITH RankedAdvertisers AS (
    SELECT 
        d.quarter,
        a.advertiser_name,
        SUM(f.revenue) AS total_revenue,
        RANK() OVER (
            PARTITION BY d.quarter 
            ORDER BY SUM(f.revenue) DESC
        ) AS rank
    FROM gold.fact_conversions f
    JOIN gold.dim_advertiser a ON f.advertiser_sk = a.advertiser_sk
    JOIN gold.dim_date d ON f.date_sk = d.date_sk
    GROUP BY d.quarter, a.advertiser_name
)
SELECT 
    quarter, 
    advertiser_name, 
    total_revenue
FROM RankedAdvertisers
WHERE rank = 1
ORDER BY quarter ASC;
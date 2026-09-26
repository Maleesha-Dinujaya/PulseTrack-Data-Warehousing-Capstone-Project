DROP TABLE IF EXISTS gold.bridge_conversion_touchpoints CASCADE;

CREATE TABLE gold.bridge_conversion_touchpoints (
    conversion_id VARCHAR(50) NOT NULL,
    click_id VARCHAR(50) NOT NULL,
    weight DECIMAL(5,4) NOT NULL,
    
    PRIMARY KEY (conversion_id, click_id)
);

INSERT INTO gold.bridge_conversion_touchpoints (
    conversion_id, 
    click_id, 
    weight
)
SELECT 
    conversion_id,
    click_id,
    1.0000 AS weight
FROM silver.silver_conversions_clean
WHERE conversion_id IS NOT NULL 
  AND click_id IS NOT NULL;
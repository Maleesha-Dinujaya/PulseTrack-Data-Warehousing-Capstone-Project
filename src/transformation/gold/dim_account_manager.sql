DROP TABLE IF EXISTS gold.dim_account_managers CASCADE;

-- Create the Dimension Table
CREATE TABLE gold.dim_account_managers (
    account_manager_key SERIAL PRIMARY KEY, -- Our new Surrogate Key
    am_id VARCHAR(50) UNIQUE NOT NULL,      -- Original (Natural) Key
    am_name VARCHAR(255),
    team VARCHAR(100),
    region VARCHAR(100),
    hire_date TIMESTAMP
);

-- Take the data from Silver and Insert it into Gold
INSERT INTO gold.dim_account_managers (am_id, am_name, team, region, hire_date)
SELECT 
    am_id,
    am_name,
    team,
    region,
    hire_date
FROM silver.silver_account_managers_clean
WHERE am_id IS NOT NULL;

-- Insert a Default / Unknown row (for records in the Fact table that have no match)
INSERT INTO gold.dim_account_managers (account_manager_key, am_id, am_name, team, region) 
VALUES (-1, 'UNKNOWN', 'Unknown Account Manager', 'Unknown', 'Unknown')
ON CONFLICT (account_manager_key) DO NOTHING;
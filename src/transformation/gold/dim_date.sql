DROP TABLE IF EXISTS gold.dim_date CASCADE;

CREATE TABLE gold.dim_date (
    date_sk INT PRIMARY KEY,              -- e.g., 20250110
    full_date DATE NOT NULL,              -- e.g., 2025-01-10
    year INT NOT NULL,                    -- 2025
    quarter INT NOT NULL,                 -- 1 to 4
    month INT NOT NULL,                   -- 1 to 12
    month_name VARCHAR(20) NOT NULL,      -- January, February...
    day INT NOT NULL,                     -- 1 to 31
    day_of_week INT NOT NULL,             -- 1 (Sunday/Monday) to 7
    day_name VARCHAR(20) NOT NULL,        -- Monday, Tuesday...
    is_weekend BOOLEAN NOT NULL           -- TRUE / FALSE
);

-- Auto-generate and Insert dates from 2024 to 2027
INSERT INTO gold.dim_date
SELECT 
    to_char(datum, 'YYYYMMDD')::INT AS date_sk,
    datum AS full_date,
    EXTRACT(YEAR FROM datum)::INT AS year,
    EXTRACT(QUARTER FROM datum)::INT AS quarter,
    EXTRACT(MONTH FROM datum)::INT AS month,
    to_char(datum, 'TMMonth') AS month_name,
    EXTRACT(DAY FROM datum)::INT AS day,
    EXTRACT(DOW FROM datum)::INT + 1 AS day_of_week,
    to_char(datum, 'TMDay') AS day_name,
    CASE 
        WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE 
        ELSE FALSE 
    END AS is_weekend
FROM generate_series(
    '2024-01-01'::DATE, 
    '2027-12-31'::DATE, 
    '1 day'::INTERVAL
) AS datum;

-- Default Unknown row (for a missing date or incorrect Fact records)
INSERT INTO gold.dim_date (date_sk, full_date, year, quarter, month, month_name, day, day_of_week, day_name, is_weekend)
VALUES (-1, '1900-01-01', 1900, 0, 0, 'Unknown', 0, 0, 'Unknown', FALSE)
ON CONFLICT (date_sk) DO NOTHING;
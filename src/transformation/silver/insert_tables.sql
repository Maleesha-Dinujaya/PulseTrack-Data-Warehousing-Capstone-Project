-- Copy the remaining clean data into the Silver Layer

DROP TABLE IF EXISTS silver.clicks_clean;
CREATE TABLE silver.clicks_clean AS 
SELECT * FROM bronze.bronze_clicks_raw;

DROP TABLE IF EXISTS silver.impressions_clean;
CREATE TABLE silver.impressions_clean AS 
SELECT * FROM bronze.bronze_impressions_raw;

DROP TABLE IF EXISTS silver.campaigns_clean;
CREATE TABLE silver.campaigns_clean AS 
SELECT * FROM bronze.bronze_campaigns_raw;

DROP TABLE IF EXISTS silver.creatives_clean;
CREATE TABLE silver.creatives_clean AS 
SELECT * FROM bronze.bronze_creatives_raw;

DROP TABLE IF EXISTS silver.offers_clean;
CREATE TABLE silver.offers_clean AS 
SELECT * FROM bronze.bronze_offers_raw;

DROP TABLE IF EXISTS silver.account_managers_clean;
CREATE TABLE silver.account_managers_clean AS 
SELECT * FROM bronze.bronze_account_managers_raw;

DROP TABLE IF EXISTS silver.conversion_touchpoints_clean;
CREATE TABLE silver.conversion_touchpoints_clean AS 
SELECT * FROM bronze.bronze_conversion_touchpoints_raw;

DROP TABLE IF EXISTS silver.advertisers_clean;
CREATE TABLE silver.advertisers_clean AS 
SELECT * FROM bronze.bronze_advertisers_raw;

DROP TABLE IF EXISTS silver.partners_clean;
CREATE TABLE silver.partners_clean AS 
SELECT * FROM bronze.bronze_partners_raw;
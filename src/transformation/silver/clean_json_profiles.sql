-- 1. Partner Profiles Clean
DROP TABLE IF EXISTS silver.partner_profiles_clean;

CREATE TABLE silver.partner_profiles_clean AS
SELECT 
    raw_document::jsonb ->> 'partner_id' AS partner_id,
    raw_document::jsonb ->> 'name' AS partner_name,
    raw_document::jsonb -> 'contact' ->> 'email' AS contact_email,
    raw_document::jsonb -> 'payment' ->> 'terms' AS payment_terms,
    raw_document::jsonb -> 'tags' AS tags,
    raw_document::jsonb -> 'channels' AS channels,
    ingested_at
FROM bronze.bronze_partner_profiles;

-- 2. Advertiser Accounts Clean
DROP TABLE IF EXISTS silver.advertiser_accounts_clean;

CREATE TABLE silver.advertiser_accounts_clean AS
SELECT 
    raw_document::jsonb ->> 'advertiser_id' AS advertiser_id,
    raw_document::jsonb ->> 'legal_name' AS advertiser_name,
    raw_document::jsonb ->> 'vertical' AS vertical,
    raw_document::jsonb ->> 'status' AS status,
    raw_document::jsonb -> 'billing' ->> 'country' AS billing_country,
    raw_document::jsonb -> 'billing' ->> 'currency' AS billing_currency,
    raw_document::jsonb -> 'account_manager_history' AS account_manager_history,
    ingested_at
FROM bronze.bronze_advertiser_accounts;
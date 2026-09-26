# PulseTrack — Data Warehousing Capstone Project

An end-to-end **Data Warehouse** built on top of PulseTrack, a fictional ad-tech / affiliate-marketing
platform. The project ingests three deliberately messy sources, cleans and conforms them through a
**Medallion Architecture** (Bronze → Silver → Gold), models the result as a **Kimball star schema**,
and serves a BI-ready **data mart** plus 10 analytical queries and a suite of data-quality checks.

Everything runs on **PostgreSQL**. Orchestration is wired up with **Apache Airflow**.

---

## Table of Contents

- [What Problem Does This Solve?](#what-problem-does-this-solve)
- [The Data Sources](#the-data-sources)
- [Data Quality Problems Tackled](#data-quality-problems-tackled)
- [Architecture — Medallion](#architecture--medallion)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Running the Pipeline](#running-the-pipeline)
- [The Data Model](#the-data-model)
- [Business Questions](#business-questions)
- [Data Quality & Reconciliation](#data-quality--reconciliation)
- [Orchestration with Airflow](#orchestration-with-airflow)
- [BI / DAX Measures](#bi--dax-measures)
- [Dataset](#dataset)
- [License](#license)
- [Author](#author)

---

## What Problem Does This Solve?

Marketing teams need to answer questions like *"which campaign is actually profitable?"*,
*"did impressions grow while conversions fell?"* and *"did handing an account to a new account
manager change revenue?"*

Answering those against the raw exports is painful: there are no keys, no types, and no
constraints — the data is a raw dump. This project turns that dump into a **modelled, typed,
reconciled and auditable warehouse** that a BI tool (Power BI, Tableau, Looker) can query directly.

---

## The Data Sources

The dataset ships as **three independent sources generated from the same ground truth**, which
means they can be (and are) reconciled against each other.

| # | Source | Format | Location | What it holds |
|---|--------|--------|----------|---------------|
| 1 | **Relational export** | 11 CSVs | `data/` | The full unnormalised, untyped business data — reference tables + funnel events |
| 2 | **MongoDB "PartnerHub/CRM"** | JSON Lines | `mongo/` | Nested reference data: partner profiles, advertiser account-manager **history** |
| 3 | **Kafka-style stream** | Log, 1 record/line | `stream/` | A live conversion event stream with retries, duplicates and schema evolution |

**Volume:** ~774,000 relational rows (300k impressions, 150k clicks, 126k conversions, 183k
touchpoints, 12k adjustments) plus ~1.1M stream events.

### Cross-source relationships

```
pulsetrack.conversions | partition=<0-3> | offset=<n> | ts=<epoch ms> | key=<conversion_id> | <JSON>
```

- `partner_id` prefix ↔ `partner_profiles.partner_id`
- `advertiser_id` ↔ `advertiser_accounts.advertiser_id`
- `conversion_id` ↔ stream key

Replaying the stream (deduplicated by `event_id`, latest status per conversion) reproduces the
batch state: `conversions_raw` deduplicated by `MAX(updated_at)` + `revenue_adjustments_raw`.

---

## Data Quality Problems Tackled

The dataset is dirty **on purpose**. The problems, and how the Silver layer handles them:

| Problem | Example in the raw data | Silver-layer solution |
|---------|------------------------|-----------------------|
| **Everything is TEXT** | `"$ 214.52"`, `"USD 980.00"`, `"N/A"` | Typed casts + `NULLIF` on empty strings |
| **Mixed date formats** | `1735689600`, `01/10/2025`, `2025-01-10`, `Jan 10, 2025` | A `CASE` ladder matching each format via regex |
| **Money as text** | `$`, `USD`, `US$`, blanks, negatives | `REGEXP_REPLACE(..., '[^0-9.\-]', '')` → `DECIMAL(10,2)` |
| **Compound keys** | `11845_198503` (partner + sub-partner) | `SPLIT_PART(partner_id, '_', 1)` / `(…, 2)` |
| **Duplicate rows** | Same `conversion_id`, evolving `status` | `ROW_NUMBER() OVER (PARTITION BY conversion_id ORDER BY updated_at DESC)` |
| **Dirty enumerations** | `status`: ~10 spellings for approved/pending/reversed | `CASE` → `approved` / `pending` / `reversed` / `declined` |
| **Country variants** | `US`, `USA`, `United States`, `UK` | Mapped to ISO-2 (`US`, `GB`, `CA`, `AU`) |
| **Device variants** | `mob`, `iPhone`, `android`, `ios` | Mapped to `mobile` / `desktop` / `tablet` |
| **Mixed booleans** | `1`, `0`, `true`, `Y`, `N`, blank | Cast to real `BOOLEAN` (`is_test` rows filtered out) |
| **Casing noise** | `cpa` / `CPA`, `Banner` / `banner` | `UPPER()` / `LOWER()` |
| **Orphaned FKs** | Campaign → non-existent advertiser | `LEFT JOIN` + `COALESCE(..., -1)` → `UNKNOWN` member |
| **Junk columns** | `placement_raw`, `bot_score`, `legacy_flag`, `internal_note` | Ignored / not carried forward |
| **PII** | `ip`, `user_agent` | Not propagated into the conformed model |
| **Stream artefacts** | ~2.5% duplicate deliveries, ~0.1% truncated lines, `schema_version` 1.0 → 2.0 | Defensive parsing, quarantined bad lines, `event_id` dedup |

---

## Architecture — Medallion

```
  3 SOURCES                    BRONZE              SILVER               GOLD              MART
 ┌──────────────┐          ┌───────────┐       ┌──────────────┐    ┌──────────────┐   ┌────────────┐
 │ data/*.csv   │─────────▶│  raw,     │──────▶│ typed,       │───▶│ star schema, │──▶│ campaign_  │
 │ (11 tables)  │          │  as-is,   │       │ conformed,   │    │ surrogate    │   │ daily_     │
 ├──────────────┤          │  no types │       │ deduped,     │    │ keys,        │   │ performanc │
 │ mongo/*.jsonl│─────────▶│  + lineage│       │ standardised │    │ conformed    │   │ e          │
 ├──────────────┤          └───────────┘       └──────────────┘    └──────────────┘   └────────────┘
 │ stream/*.log │                                                                │
 └──────────────┘                                                          ┌────────────┐
                                                                          │  audit.    │
                                                                          │ pipeline_  │
                                                                          │ runs       │
                                                                          └────────────┘
```

| Layer | Schema | Purpose |
|-------|--------|---------|
| **Bronze** | `bronze` | Raw, untyped, append-only landing zone. Adds `ingested_at` + `source_file` lineage columns. |
| **Silver** | `silver` | Cleaned & conformed. Real data types, standardised codes, duplicates removed, junk dropped. |
| **Gold** | `gold` | Kimball star schema. Surrogate keys, conformed dimensions, fact tables, plus a bridge table for multi-touch attribution. |
| **Mart** | `mart` | Pre-aggregated, BI-ready daily campaign performance with derived KPIs. |
| **Audit** | `audit` | `pipeline_runs` log table — every run's status, timings and row counts. |

### Ordering constraints

- Bronze must run before Silver; Silver before Gold.
- Gold **dimensions** must be loaded before Gold **facts** (facts `LEFT JOIN` the dimensions to
  resolve surrogate keys).
- The Mart aggregates Gold and must be last.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Database | PostgreSQL 14+ |
| Ingestion | Python 3.10+, pandas, SQLAlchemy |
| Transformation | SQL (PostgreSQL) — CTEs, window functions, `JSONB`, regex, `SPLIT_PART`, `generate_series` |
| Orchestration | Apache Airflow 2.8+ (`PostgresOperator`) |
| BI | Power BI (DAX measures provided) |
| Source datasets | CSV · JSON Lines · Kafka-style log |

---

## Repository Structure

```
.
├── config.py                       # Central config — reads PULSETRACK_DB_URI from the env
├── requirements.txt                # Python dependencies
├── .env.example                    # Template for your local connection string
│
├── data/                           # 11 raw CSV exports  (git-ignored, 94 MB)
├── mongo/                          # JSON Lines reference data (git-ignored)
├── stream/                         # Kafka-style log (git-ignored) + README_topic.md
│
├── ddl/
│   └── pulsetrack_source_schema.sql  # RAW schema: 11 untyped tables, no keys, no constraints
│
├── dags/
│   └── dag.py                      # Airflow DAG — daily ETL, 6 tasks
│
├── src/
│   ├── ingestion/                  # ── BRONZE ──────────────────────────────
│   │   ├── ingest_csv.py           # data/*.csv     -> bronze.bronze_*
│   │   ├── ingest_json.py          # mongo/*.jsonl  -> bronze.bronze_*
│   │   └── ingest_stream.py        # stream/*.log   -> bronze.bronze_stream_conversions
│   │
│   ├── transformation/
│   │   ├── silver/                 # ── SILVER ── clean, type, conform, dedupe
│   │   │   ├── clean_account_managers.sql
│   │   │   ├── clean_advertisers_clean.sql
│   │   │   ├── clean_partners.sql
│   │   │   ├── clean_offers_raw.sql
│   │   │   ├── clean_campaigns_raw.sql
│   │   │   ├── clean_creatives_raw.sql
│   │   │   ├── clean_impressions_raw.sql
│   │   │   ├── clean_clicks.sql
│   │   │   ├── clean_conversion_touchpoints.sql
│   │   │   ├── clean_conversions.sql
│   │   │   ├── clean_conversions_raw.sql
│   │   │   ├── clean_revenue_adjustments.sql
│   │   │   ├── clean_json_profiles.sql          # JSONB unnesting
│   │   │   ├── clean_stream_conversions.sql     # stream + schema evolution
│   │   │   ├── clean_stream_data.sql
│   │   │   └── insert_tables.sql                # pass-through copies
│   │   │
│   │   ├── gold/                   # ── GOLD ── star schema
│   │   │   ├── dim_date.sql                     # generated 2024-01-01 .. 2027-12-31
│   │   │   ├── dim_partner.sql
│   │   │   ├── dim_advertiser.sql
│   │   │   ├── dim_account_manager.sql
│   │   │   ├── dim_offer.sql
│   │   │   ├── dim_campaign.sql
│   │   │   ├── dim_creative.sql
│   │   │   ├── fact_impressions.sql
│   │   │   ├── fact_click.sql
│   │   │   ├── fact_conversions.sql
│   │   │   ├── fact_revenue_adjustments.sql
│   │   │   ├── bridge_conversion_touchpoints.sql # multi-touch attribution (M:N)
│   │   │   └── upsert_dim_campaign.sql           # idempotent ON CONFLICT upsert
│   │   │
│   │   ├── mart/
│   │   │   ├── mart.campaign_daily_performance.sql
│   │   │   └── dax_measures.txt
│   │   │
│   │   └── audit/
│   │       └── audit.pipeline_runs.sql
│   │
│   ├── Business Analytics/        # 10 analytical queries (see below)
│   │   ├── q1.sql   ..   q10.sql
│   │
│   └── Data Quality & Reconciliation/
│       └── data_quality_checks.sql
│
└── tests/
```

---

## Prerequisites

- **Python** 3.10 or newer
- **PostgreSQL** 14 or newer, running locally
- **Apache Airflow** 2.8+ (optional — only to run the DAG)
- ~200 MB of free disk for the database and the raw dataset

---

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/Maleesha-Dinujaya/PulseTrack-Data-Warehousing-Capstone-Project.git
cd PulseTrack-Data-Warehousing-Capstone-Project

python -m venv .venv
# Windows:      .venv\Scripts\activate
# macOS/Linux:  source .venv/bin/activate

pip install -r requirements.txt
```

### 2. Configure the database connection

The connection string is **never hardcoded**. It is read from the `PULSETRACK_DB_URI`
environment variable, with a safe local default.

```bash
# Windows PowerShell
$env:PULSETRACK_DB_URI = "postgresql://postgres:your_password@localhost:5432/pulsetrack_raw"

# macOS / Linux
export PULSETRACK_DB_URI="postgresql://postgres:your_password@localhost:5432/pulsetrack_raw"
```

You can also copy `.env.example` to `.env` and export it from there. `.env` is git-ignored.

### 3. Create the database

```bash
createdb pulsetrack_raw
```

### 4. Load the RAW source schema

The raw tables are deliberately untyped (`TEXT` everywhere) with **no** primary keys, foreign keys
or constraints — exactly as a platform export would arrive.

```bash
psql -d pulsetrack_raw -f ddl/pulsetrack_source_schema.sql
```

### 5. Add the dataset

The raw data files (154 MB) are **not** committed to this repository. Download the capstone
dataset and place the files as follows:

```
data/     <- 11 CSV files      (account_managers_raw.csv ... revenue_adjustments_raw.csv)
mongo/    <- 2 JSONL files     (partner_profiles.jsonl, advertiser_accounts.jsonl)
stream/   <- pulsetrack_conversions.log
```

> See [Dataset](#dataset) for the exact file list.

---

## Running the Pipeline

Run the stages **in order** — the layers are strictly dependent.

### Stage 0 — Bronze (ingest the three sources)

```bash
python src/ingestion/ingest_csv.py      # data/*.csv    -> bronze.bronze_*        (~774k rows)
python src/ingestion/ingest_json.py     # mongo/*.jsonl -> bronze.bronze_*        (nested docs)
python src/ingestion/ingest_stream.py   # stream/*.log  -> bronze.bronze_stream_conversions
```

The JSON and stream loaders keep each document as a single raw column
(`raw_document` / `raw_log_line`) — parsing happens in Silver.

### Stage 1 — Silver (clean & conform)

```bash
psql -d pulsetrack_raw -f src/transformation/silver/clean_account_managers.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_advertisers_clean.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_partners.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_offers_raw.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_campaigns_raw.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_creatives_raw.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_impressions_raw.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_clicks.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_conversion_touchpoints.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_conversions.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_revenue_adjustments.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_json_profiles.sql
psql -d pulsetrack_raw -f src/transformation/silver/clean_stream_conversions.sql
```

### Stage 2 — Gold (star schema)

Dimensions first, then facts — the facts resolve surrogate keys by joining the dimensions.

```bash
# Dimensions
psql -d pulsetrack_raw -f src/transformation/gold/dim_date.sql
psql -d pulsetrack_raw -f src/transformation/gold/dim_partner.sql
psql -d pulsetrack_raw -f src/transformation/gold/dim_advertiser.sql
psql -d pulsetrack_raw -f src/transformation/gold/dim_account_manager.sql
psql -d pulsetrack_raw -f src/transformation/gold/dim_offer.sql
psql -d pulsetrack_raw -f src/transformation/gold/dim_campaign.sql
psql -d pulsetrack_raw -f src/transformation/gold/dim_creative.sql

# Facts
psql -d pulsetrack_raw -f src/transformation/gold/fact_impressions.sql
psql -d pulsetrack_raw -f src/transformation/gold/fact_click.sql
psql -d pulsetrack_raw -f src/transformation/gold/fact_conversions.sql
psql -d pulsetrack_raw -f src/transformation/gold/fact_revenue_adjustments.sql

# Bridge (multi-touch attribution)
psql -d pulsetrack_raw -f src/transformation/gold/bridge_conversion_touchpoints.sql

# Idempotent dimension refresh (no DROP — safe to re-run)
psql -d pulsetrack_raw -f src/transformation/gold/upsert_dim_campaign.sql
```

### Stage 3 — Mart & Audit

```bash
psql -d pulsetrack_raw -f src/transformation/mart/mart.campaign_daily_performance.sql
psql -d pulsetrack_raw -f src/transformation/audit/audit.pipeline_runs.sql
```

### Stage 4 — Analytics & Quality checks

```bash
psql -d pulsetrack_raw -f "src/Business Analytics/q1.sql"
psql -d pulsetrack_raw -f "src/Data Quality & Reconciliation/data_quality_checks.sql"
```

---

## The Data Model

### Star schema

```
                        ┌──────────────┐
                        │  dim_date    │  2024-01-01 → 2027-12-31
                        │  (date_sk)   │  year · quarter · month · day · weekend
                        └──────┬───────┘
                               │
   ┌──────────────┐      ┌──────┴───────┐      ┌──────────────┐
   │ dim_partner  │─────▶│              │◀─────│ dim_advertiser│
   │ (partner_sk) │      │              │      │ (advertiser_sk)
   └──────────────┘      │   FACT       │      └──────────────┘
                         │   TABLES     │
   ┌──────────────┐      │              │      ┌──────────────┐
   │ dim_campaign │─────▶│              │◀─────│ dim_creative │
   │ (campaign_sk)│      │              │      │ (creative_sk)│
   └──────────────┘      └──────┬───────┘      └──────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
 ┌──────┴───────┐      ┌────────┴────────┐     ┌────────┴───────┐
 │fact_impressions│   │  fact_clicks    │     │fact_conversions│
 └──────────────┘      └─────────────────┘     └────────────────┘
                                                        │
                                             ┌──────────┴──────────┐
                                             │fact_revenue_        │
                                             │  adjustments        │
                                             └─────────────────────┘
```

Plus:

- **`dim_account_manager`** — internal account managers (team, region, hire date)
- **`dim_offer`** — offers/products promoted, with default payout
- **`bridge_conversion_touchpoints`** — many-to-many bridge modelling multi-touch attribution
  between conversions and clicks

### Design decisions

- **Surrogate keys** on every dimension (`*_sk`), with the natural/business key kept as a
  `UNIQUE` natural key for traceability.
- **An `UNKNOWN` / `-1` member** is inserted into every dimension. Facts that fail to match a
  dimension are mapped to it via `COALESCE(..., -1)`, so no fact row is ever lost and
  referential integrity always holds.
- **`dim_date` is pre-generated** for a fixed window with `generate_series` — no runtime
  date logic scattered through the queries.
- **`date_sk` is an `INT`** in `YYYYMMDD` form (e.g. `20260206`) — compact, sortable, and
  trivially derivable from any timestamp.
- **Idempotent loads** — `upsert_dim_campaign.sql` uses `ON CONFLICT ... DO UPDATE` instead of
  `DROP` + `INSERT`, so re-running it updates in place and never destroys history.
- **Lineage everywhere** — every Bronze and Silver table carries `ingested_at` and `source_file`.

---

## Business Questions

Ten analytical queries live in `src/Business Analytics/`. They are written to run against the
**Gold** and **Mart** layers only — the whole point of modelling the data.

| # | File | Question | Key SQL technique |
|---|------|----------|-------------------|
| 1 | `q1.sql` | Top advertiser by revenue, per quarter | `RANK() OVER (PARTITION BY ...)` |
| 2 | `q2.sql` | Top 5 campaigns by overall CTR and conversion rate | Conditional aggregation, `HAVING` filter |
| 3 | `q3.sql` | Top 10 partners by total revenue | Join + `GROUP BY` + `ORDER BY` |
| 4 | `q4.sql` | Month-over-month revenue growth % | CTE + `LAG()` window function |
| 5 | `q5.sql` | Each campaign's revenue contribution to the grand total | `CROSS JOIN` total, percentage-of-total |
| 6 | `q6.sql` | Creatives performing **below** their campaign's average CTR | Nested CTE + `AVG() OVER (PARTITION BY ...)` |
| 7 | `q7.sql` | Revenue impact **before vs after** an account-manager change | `jsonb_array_elements` unnesting + validity-window join + `LAG()` |
| 8 | `q8.sql` | Each partner's share of total platform revenue | `CROSS JOIN` total, percentage-of-total |
| 9 | `q9.sql` | Campaigns where impressions rose **but** conversions fell | `LAG()` on two measures, compound filter |
| 10 | `q10.sql` | Net revenue after late-arriving adjustments, and revenue erosion % | Two `CROSS JOIN`ed aggregates |

**Highlights**

- **Q7** is the SCD2 question. The MongoDB `advertiser_accounts` documents carry an
  `account_manager_history` JSON array with `from` / `to` timestamps. The query unnests it with
  `jsonb_array_elements`, joins each validity window to `fact_conversions` on `conversion_time`,
  then uses `LAG()` to compare the revenue booked under the *previous* manager against the
  *current* one.

- **Q9** combines the mart with `LAG()` on two different measures, then filters for the specific
  pathology of rising impressions alongside falling conversions.

---

## Data Quality & Reconciliation

`src/Data Quality & Reconciliation/data_quality_checks.sql` runs five independent checks:

1. **Reconciliation** — do the Silver row counts match the Gold row counts? Reports
   `dropped_rows` per entity.
2. **Referential integrity** — how many fact rows carry a missing dimension
   (`SK = -1`, i.e. `UNKNOWN`)?
3. **Null checks** — do any primary keys contain `NULL`s? (Expected result: `0`.)
4. **Business rule validation** — flag any conversion where `payout > revenue`
   (a loss-making conversion that still needs review).
5. **Audit log** — the last 10 runs from `audit.pipeline_runs`, with status and row counts.

Run it with:

```bash
psql -d pulsetrack_raw -f "src/Data Quality & Reconciliation/data_quality_checks.sql"
```

---

## Orchestration with Airflow

`dags/dag.py` defines a daily DAG, `pulsetrack_daily_etl_pipeline`, with six tasks:

```
start_pipeline
      │
      ▼
ingest_to_bronze
      │
      ├──▶ clean_silver_dimensions ──▶ load_gold_dimensions ──┐
      │                                                      ├──▶ refresh_campaign_mart ──▶ end_pipeline
      └──▶ clean_silver_facts ────────▶ load_gold_facts ──────┘
```

**Configuration**

- `schedule_interval='@daily'`, `catchup=False`
- `retries=2`, `retry_delay=5 minutes`
- `depends_on_past=True`
- Airflow connection ID: **`warehouse_conn`**

Create the connection once:

```bash
airflow connections add warehouse_conn \
  --conn-type postgres \
  --conn-host localhost \
  --conn-port 5432 \
  --conn-schema pulsetrack_raw \
  --conn-login postgres \
  --conn-password <your password>
```

Then copy `dags/dag.py` into your `AIRFLOW_HOME/dags/` folder.

---

## BI / DAX Measures

`src/transformation/mart/dax_measures.txt` contains ready-to-use Power BI DAX measures built on
`mart.campaign_daily_performance`:

| Measure | Definition |
|---------|-----------|
| Total Impressions / Clicks / Conversions | `SUM()` of the mart measure |
| Total Revenue / Payout | `SUM()` of the mart measure |
| **Total Profit** | `Total Revenue − Total Payout` |
| **CTR %** | `DIVIDE([Total Clicks], [Total Impressions], 0)` |
| **Conversion Rate %** | `DIVIDE([Total Conversions], [Total Clicks], 0)` |
| **Revenue Per Click** | `DIVIDE([Total Revenue], [Total Clicks], 0)` |
| **Revenue Per Conversion** | `DIVIDE([Total Revenue], [Total Conversions], 0)` |
| **MoM Revenue Growth** | `CALCULATE(..., PREVIOUSMONTH('DimDate'[Date]))` |
| **Rank by Revenue** | `RANKX(ALL('dim_campaign'[campaign_name]), [Total Revenue], , DESC, Dense)` |

The mart already carries the same KPIs as physical columns (`ctr_percentage`,
`conversion_rate_percentage`, `revenue_per_click`, `profit`) so they can be used directly in SQL
too.

---

## Dataset

The raw data is **not** committed (154 MB). Download the capstone dataset and lay it out as:

**`data/`** — 11 CSV files (~774,000 rows total)

| File | Rows | Notes |
|------|------|-------|
| `account_managers_raw.csv` | 25 | SCD2 subject |
| `advertisers_raw.csv` | 60 | Casing variants |
| `campaigns_raw.csv` | 400 | Orphaned `advertiser_id` |
| `clicks_raw.csv` | 150,000 | ~15% have no impression |
| `conversions_raw.csv` | 126,380 | Duplicates, money-as-text |
| `conversion_touchpoints_raw.csv` | 183,529 | Multi-touch bridge |
| `creatives_raw.csv` | 1,200 | |
| `impressions_raw.csv` | 300,000 | Highest volume |
| `offers_raw.csv` | 150 | |
| `partners_raw.csv` | 600 | ~13% null names |
| `revenue_adjustments_raw.csv` | 12,000 | Late-arriving deltas |

**`mongo/`** — `partner_profiles.jsonl`, `advertiser_accounts.jsonl`

**`stream/`** — `pulsetrack_conversions.log` (see `stream/README_topic.md` for the event
format, delivery semantics and schema-evolution notes)

---

## License

Released for educational and portfolio purposes.

---

## Author

**Maleesha Dinujaya**

[![GitHub](https://img.shields.io/badge/GitHub-Maleesha--Dinujaya-181717?style=for-the-badge&logo=github)](https://github.com/Maleesha-Dinujaya)

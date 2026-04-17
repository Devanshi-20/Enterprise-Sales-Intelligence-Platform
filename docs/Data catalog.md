# Data Catalog

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Status:** Living document — updated each sprint as new tables are built

---

## What This Document Is

The data catalog is the map of every table, every column, and every
relationship in the Enterprise Sales Intelligence Platform warehouse.

It answers the question any new analyst or developer will ask on day one:
*"What data do we have, where does it come from, and what does each field mean?"*

> This document is updated every time a new table or column is added.
> It is the first place to check before writing any query.

---

## Architecture Overview

```
Source Systems          Medallion Layers              Consumption
──────────────          ────────────────              ───────────
ERP (CSV)      ──►  Bronze  ──►  Silver  ──►  Gold  ──►  Dashboard
CRM (CSV)      ──►  (raw)       (clean)     (model)      SQL Reports
```

| Layer | Schema | Purpose | Tables |
|---|---|---|---|
| Bronze | `bronze` | Raw ingestion — exact mirror of source | 5 tables |
| Silver | `silver` | Cleansed, standardised, deduplicated | 4 staging tables + 2 audit |
| Gold | `gold` | Star schema — facts, dims, KPI views | 1 fact + 4 dims + 4 views |

---

## Bronze Layer

### `bronze.erp_orders`

**Source:** ERP system CSV export — `erp_orders.csv`
**Grain:** One row per order header
**Load type:** Full reload (truncate and insert)
**Loaded by:** `scripts/bronze/04_bronze_load_erp_orders.sql`

| Column | Data Type | Nullable | Description | Known Issues |
|---|---|---|---|---|
| `order_id` | VARCHAR(50) | No | Unique order identifier from ERP | None |
| `customer_id` | VARCHAR(50) | No | Customer ID — ERP format (differs from CRM) | Does not match CRM customer_id — reconciled in Silver |
| `order_date` | DATE | No | Date order was placed | Some rows have future dates — flagged by GE |
| `ship_date` | DATE | Yes | Date order was shipped | NULL for unshipped orders |
| `order_status` | VARCHAR(20) | No | Order status | Values: Shipped, Delivered, Cancelled, Returned, Pending |
| `total_amount` | DECIMAL(10,2) | No | Gross order total before refunds | |
| `refund_amount` | DECIMAL(10,2) | Yes | Refund amount if applicable | NULL in source — coalesced to 0 in Silver |
| `sales_rep_id` | VARCHAR(50) | Yes | Sales rep assigned to order | NULL for online orders |
| `region` | VARCHAR(100) | Yes | Geographic region | Free text — standardised in Silver |
| `load_timestamp` | DATETIME | No | When this row was loaded into Bronze | Added by load script — not in source |

---

### `bronze.erp_order_items`

**Source:** ERP system CSV export — `erp_order_items.csv`
**Grain:** One row per order line item
**Load type:** Full reload
**Loaded by:** `scripts/bronze/04_bronze_load_erp_orders.sql`

| Column | Data Type | Nullable | Description | Known Issues |
|---|---|---|---|---|
| `order_item_id` | VARCHAR(50) | No | Unique line item identifier | |
| `order_id` | VARCHAR(50) | No | FK to erp_orders.order_id | |
| `product_id` | VARCHAR(50) | No | Product identifier from ERP | |
| `quantity` | INT | No | Units ordered | Some rows have quantity = 0 — flagged by GE |
| `unit_price` | DECIMAL(10,2) | No | Price per unit at time of order | |
| `line_total` | DECIMAL(10,2) | No | quantity × unit_price | Calculated field in source — recomputed in Silver |
| `returned_qty` | INT | Yes | Units returned | NULL in source = 0 returns |
| `load_timestamp` | DATETIME | No | Load timestamp | |

---

### `bronze.erp_products`

**Source:** ERP system CSV export — `erp_products.csv`
**Grain:** One row per product
**Load type:** Full reload
**Loaded by:** `scripts/bronze/05_bronze_load_erp_products.sql`

| Column | Data Type | Nullable | Description | Known Issues |
|---|---|---|---|---|
| `product_id` | VARCHAR(50) | No | Unique product identifier | |
| `product_name` | VARCHAR(255) | No | Product display name | Mixed case in source — standardised in Silver |
| `category` | VARCHAR(100) | Yes | Product category | 12 distinct values — some with trailing spaces |
| `sub_category` | VARCHAR(100) | Yes | Product sub-category | |
| `cost_price` | DECIMAL(10,2) | Yes | Cost of goods — used for margin calculation | NULL for 8 products — defaulted to 0 in Silver, flagged |
| `list_price` | DECIMAL(10,2) | No | Standard selling price | |
| `is_active` | BIT | No | 1 = active product, 0 = discontinued | |
| `load_timestamp` | DATETIME | No | Load timestamp | |

---

### `bronze.crm_customers`

**Source:** CRM system CSV export — `crm_customers.csv`
**Grain:** One row per customer
**Load type:** Full reload
**Loaded by:** `scripts/bronze/07_bronze_load_crm_customers.sql`

| Column | Data Type | Nullable | Description | Known Issues |
|---|---|---|---|---|
| `crm_customer_id` | VARCHAR(50) | No | CRM-assigned customer ID | Different format from ERP customer_id |
| `first_name` | VARCHAR(100) | No | Customer first name | |
| `last_name` | VARCHAR(100) | No | Customer last name | |
| `email` | VARCHAR(255) | Yes | Primary email address | ~3% NULL rate |
| `phone` | VARCHAR(30) | Yes | Phone number | Multiple formats in source |
| `city` | VARCHAR(100) | Yes | Customer city | |
| `province` | VARCHAR(100) | Yes | Province or state | Mix of full names and abbreviations — standardised in Silver |
| `country` | VARCHAR(100) | Yes | Country | |
| `segment` | VARCHAR(50) | Yes | Customer segment | Values: Enterprise, SMB, Consumer, Government |
| `acquisition_source` | VARCHAR(100) | Yes | How customer was acquired | Values: Organic, Referral, Paid, Event, Unknown |
| `created_date` | DATE | No | Date customer record was created in CRM | |
| `load_timestamp` | DATETIME | No | Load timestamp | |

---

### `bronze.crm_contacts`

**Source:** CRM system CSV export — `crm_contacts.csv`
**Grain:** One row per contact (a customer may have multiple contacts)
**Load type:** Full reload
**Loaded by:** `scripts/bronze/08_bronze_load_crm_contacts.sql`

| Column | Data Type | Nullable | Description | Known Issues |
|---|---|---|---|---|
| `contact_id` | VARCHAR(50) | No | Unique contact identifier | |
| `crm_customer_id` | VARCHAR(50) | No | FK to crm_customers.crm_customer_id | |
| `contact_name` | VARCHAR(200) | No | Full name of contact | |
| `contact_role` | VARCHAR(100) | Yes | Role at customer organisation | |
| `contact_email` | VARCHAR(255) | Yes | Contact email | |
| `is_primary` | BIT | No | 1 = primary contact for this customer | |
| `load_timestamp` | DATETIME | No | Load timestamp | |

---

### `bronze.load_log`

**Purpose:** Audit table — records every Bronze ingestion run
**Grain:** One row per table load attempt

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `log_id` | INT IDENTITY | No | Auto-increment log identifier |
| `table_name` | VARCHAR(100) | No | Name of table loaded |
| `source_file` | VARCHAR(255) | No | Source CSV filename |
| `rows_loaded` | INT | No | Number of rows inserted |
| `load_timestamp` | DATETIME | No | When the load ran |
| `load_status` | VARCHAR(10) | No | SUCCESS or FAILED |
| `error_message` | VARCHAR(500) | Yes | Error detail if FAILED |

---

## Silver Layer

### `silver.stg_erp_orders`

**Source:** `bronze.erp_orders` + `bronze.erp_order_items`
**Built by:** `dbt/models/silver/stg_erp_orders.sql`
**Transformations applied:**
- NULL `refund_amount` coalesced to 0
- `order_date` future dates flagged with `is_date_anomaly = 1`
- `order_status` values standardised to consistent casing
- `line_total` recalculated as `quantity × unit_price` (ignores source value)
- `region` trimmed and title-cased

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `order_item_id` | VARCHAR(50) | No | Natural key from ERP |
| `order_id` | VARCHAR(50) | No | Order header identifier |
| `customer_id` | VARCHAR(50) | No | ERP customer ID (pre-reconciliation) |
| `product_id` | VARCHAR(50) | No | Product identifier |
| `order_date` | DATE | No | Order placement date |
| `ship_date` | DATE | Yes | Shipping date |
| `order_status` | VARCHAR(20) | No | Standardised status |
| `quantity` | INT | No | Units ordered |
| `unit_price` | DECIMAL(10,2) | No | Price per unit |
| `line_total` | DECIMAL(10,2) | No | Recalculated: quantity × unit_price |
| `refund_amount` | DECIMAL(10,2) | No | Refund amount (0 if none) |
| `returned_qty` | INT | No | Units returned (0 if none) |
| `sales_rep_id` | VARCHAR(50) | Yes | Sales rep ID |
| `region_clean` | VARCHAR(100) | Yes | Standardised region |
| `is_date_anomaly` | BIT | No | 1 if order_date is in the future |
| `dwh_created_date` | DATETIME | No | When this Silver row was created |

---

### `silver.stg_erp_products`

**Source:** `bronze.erp_products`
**Built by:** `dbt/models/silver/stg_erp_products.sql`
**Transformations applied:**
- `product_name` trimmed and title-cased
- `category` trailing spaces removed
- NULL `cost_price` defaulted to 0 and flagged with `is_cost_missing = 1`

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `product_id` | VARCHAR(50) | No | Natural key from ERP |
| `product_name` | VARCHAR(255) | No | Cleaned product name |
| `category` | VARCHAR(100) | Yes | Cleaned category |
| `sub_category` | VARCHAR(100) | Yes | Sub-category |
| `cost_price` | DECIMAL(10,2) | No | Cost price (0 if missing) |
| `list_price` | DECIMAL(10,2) | No | Standard selling price |
| `is_active` | BIT | No | Active product flag |
| `is_cost_missing` | BIT | No | 1 if cost_price was NULL in source |
| `dwh_created_date` | DATETIME | No | Silver row creation timestamp |

---

### `silver.stg_crm_customer`

**Source:** `bronze.crm_customers`
**Built by:** `dbt/models/silver/stg_crm_customer.sql`
**Transformations applied:**
- Duplicate customer records removed using `ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_date DESC)` — most recent record kept
- `province` standardised to full province name (ON → Ontario)
- `segment` NULL values defaulted to 'Unknown'
- `acquisition_source` NULL values defaulted to 'Unknown'

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `crm_customer_id` | VARCHAR(50) | No | CRM natural key (deduplicated) |
| `first_name` | VARCHAR(100) | No | First name |
| `last_name` | VARCHAR(100) | No | Last name |
| `full_name` | VARCHAR(200) | No | Derived: first_name + ' ' + last_name |
| `email` | VARCHAR(255) | Yes | Email address |
| `city` | VARCHAR(100) | Yes | City |
| `province_clean` | VARCHAR(100) | Yes | Standardised province name |
| `country` | VARCHAR(100) | Yes | Country |
| `segment` | VARCHAR(50) | No | Customer segment (Unknown if NULL) |
| `acquisition_source` | VARCHAR(100) | No | Acquisition source (Unknown if NULL) |
| `created_date` | DATE | No | CRM record creation date |
| `dwh_created_date` | DATETIME | No | Silver row creation timestamp |

---

### `silver.dq_run_log`

**Purpose:** Stores Great Expectations checkpoint results per pipeline run
**Populated by:** `analytics/04_parse_ge_results.py`

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `run_id` | INT IDENTITY | No | Auto-increment run identifier |
| `run_timestamp` | DATETIME | No | When the GE checkpoint ran |
| `suite_name` | VARCHAR(100) | No | Name of the GE expectation suite |
| `table_name` | VARCHAR(100) | No | Table the suite ran against |
| `total_checks` | INT | No | Total number of expectations evaluated |
| `passing_checks` | INT | No | Number of expectations that passed |
| `failing_checks` | INT | No | Number of expectations that failed |
| `pass_rate_pct` | DECIMAL(5,2) | No | passing_checks / total_checks × 100 |
| `run_status` | VARCHAR(10) | No | PASS or FAIL |
| `failure_details` | VARCHAR(MAX) | Yes | JSON string of failed expectation names |

---

## Gold Layer

### `gold.dim_date`

**Purpose:** Full calendar dimension covering 2020–2030
**Grain:** One row per calendar date
**Row count:** 4,018 rows
**Built by:** `scripts/gold/20_gold_create_dim_date.sql`
**SCD type:** N/A — static reference table, no history needed

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `date_key` | INT | No | Surrogate key in YYYYMMDD format (e.g. 20260416) |
| `full_date` | DATE | No | The calendar date |
| `day_of_week` | INT | No | 1 = Monday … 7 = Sunday |
| `day_name` | VARCHAR(10) | No | Monday, Tuesday … Sunday |
| `day_of_month` | INT | No | 1–31 |
| `day_of_year` | INT | No | 1–366 |
| `week_of_year` | INT | No | ISO week number |
| `month_num` | INT | No | 1–12 |
| `month_name` | VARCHAR(10) | No | January … December |
| `month_short` | VARCHAR(3) | No | Jan … Dec |
| `quarter_num` | INT | No | 1–4 |
| `quarter_name` | VARCHAR(6) | No | Q1 … Q4 |
| `calendar_year` | INT | No | 2020–2030 |
| `year_month` | VARCHAR(7) | No | YYYY-MM format (e.g. 2026-04) |
| `fiscal_year` | INT | No | Same as calendar year for this project |
| `fiscal_quarter` | INT | No | Same as calendar quarter |
| `is_weekend` | BIT | No | 1 if Saturday or Sunday |
| `is_weekday` | BIT | No | 1 if Monday–Friday |
| `is_holiday` | BIT | No | 1 if Canadian federal holiday |
| `holiday_name` | VARCHAR(100) | Yes | Holiday name if is_holiday = 1 |

---

### `gold.dim_location`

**Purpose:** Geographic hierarchy for location-based analysis
**Grain:** One row per city
**Built by:** `scripts/gold/21_gold_create_dim_location.sql`
**SCD type:** Type 1 (overwrite — location hierarchies rarely change)

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `location_key` | INT IDENTITY | No | Surrogate key |
| `city` | VARCHAR(100) | No | City name |
| `province` | VARCHAR(100) | No | Province or state (full name) |
| `country` | VARCHAR(100) | No | Country |
| `region` | VARCHAR(100) | No | Sales region (e.g. Eastern Canada, Western Canada) |
| `dwh_created_date` | DATETIME | No | Row creation timestamp |

---

### `gold.dim_customer`

**Purpose:** Customer master dimension with full history preserved
**Grain:** One row per customer version (SCD Type 2)
**Built by:** `scripts/gold/22_gold_create_dim_customer.sql`
**SCD type:** Type 2 — full history of customer attribute changes

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `customer_key` | INT IDENTITY | No | Surrogate key — unique per version |
| `customer_id` | VARCHAR(50) | No | Natural key from ERP |
| `crm_customer_id` | VARCHAR(50) | Yes | Reconciled CRM ID (NULL if no CRM match) |
| `full_name` | VARCHAR(200) | No | Customer full name |
| `email` | VARCHAR(255) | Yes | Email address |
| `city` | VARCHAR(100) | Yes | City |
| `province` | VARCHAR(100) | Yes | Province |
| `country` | VARCHAR(100) | Yes | Country |
| `segment` | VARCHAR(50) | No | Customer segment |
| `acquisition_source` | VARCHAR(100) | No | How customer was acquired |
| `is_new_customer` | BIT | No | 1 if first_order_date is in the current reporting period |
| `first_order_date` | DATE | Yes | Date of customer's first ever order |
| `last_order_date` | DATE | Yes | Date of customer's most recent order |
| `assigned_rep_id` | VARCHAR(50) | Yes | Sales rep assigned to this customer |
| `effective_date` | DATE | No | Date this version became active |
| `expiry_date` | DATE | Yes | Date this version was superseded (NULL if current) |
| `is_current` | BIT | No | 1 = current active record, 0 = historical |
| `dwh_created_date` | DATETIME | No | Row creation timestamp |

**SCD Type 2 behaviour:**
When a customer's `city`, `province`, `segment`, or `assigned_rep_id` changes:
- Existing row: `expiry_date` set to today, `is_current` set to 0
- New row: inserted with new values, `effective_date` = today, `expiry_date` = NULL, `is_current` = 1

---

### `gold.dim_product`

**Purpose:** Product master dimension with full history preserved
**Grain:** One row per product version (SCD Type 2)
**Built by:** `scripts/gold/23_gold_create_dim_product.sql`
**SCD type:** Type 2 — tracks price changes and category reassignments

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `product_key` | INT IDENTITY | No | Surrogate key |
| `product_id` | VARCHAR(50) | No | Natural key from ERP |
| `product_name` | VARCHAR(255) | No | Product name |
| `category` | VARCHAR(100) | Yes | Product category |
| `sub_category` | VARCHAR(100) | Yes | Product sub-category |
| `cost_price` | DECIMAL(10,2) | No | Cost price (0 if unknown — see is_cost_missing) |
| `list_price` | DECIMAL(10,2) | No | Standard selling price |
| `is_active` | BIT | No | 1 = active product |
| `is_cost_missing` | BIT | No | 1 = cost_price was missing in source |
| `effective_date` | DATE | No | Version effective date |
| `expiry_date` | DATE | Yes | Version expiry date (NULL if current) |
| `is_current` | BIT | No | 1 = current version |
| `dwh_created_date` | DATETIME | No | Row creation timestamp |

---

### `gold.fact_sales`

**Purpose:** Central fact table — all sales transactions
**Grain:** One row per order line item
**Built by:** `scripts/gold/24_gold_create_fact_sales.sql`
**Row count:** ~50,000 rows (estimated from source data)

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `sales_key` | INT IDENTITY | No | Surrogate key for the fact row |
| `order_item_id` | VARCHAR(50) | No | Natural key from ERP order items |
| `order_id` | VARCHAR(50) | No | Order header ID |
| `customer_key` | INT | No | FK → dim_customer.customer_key (current version) |
| `product_key` | INT | No | FK → dim_product.product_key (version at time of sale) |
| `date_key` | INT | No | FK → dim_date.date_key |
| `location_key` | INT | Yes | FK → dim_location.location_key |
| `order_status` | VARCHAR(20) | No | Order status at load time |
| `order_qty` | INT | No | Units ordered |
| `unit_price` | DECIMAL(10,2) | No | Price per unit at time of order |
| `order_amount` | DECIMAL(10,2) | No | order_qty × unit_price |
| `refund_amount` | DECIMAL(10,2) | No | Refund amount (0 if none) |
| `net_amount` | DECIMAL(10,2) | No | order_amount − refund_amount |
| `cogs` | DECIMAL(10,2) | No | cost_price × order_qty from dim_product |
| `gross_margin` | DECIMAL(10,2) | No | net_amount − cogs |
| `returned_qty` | INT | No | Units returned (0 if none) |
| `sales_rep_id` | VARCHAR(50) | Yes | Sales rep ID |
| `dwh_created_date` | DATETIME | No | Row creation timestamp |

---

## Gold Views

### `gold.vw_kpi_revenue`

**Purpose:** Pre-calculated revenue KPIs for the dashboard
**Refreshed:** On demand (queries fact_sales directly)

**Key columns returned:**
`year_month`, `total_revenue`, `net_revenue`, `mom_growth_pct`, `ytd_revenue`,
`order_count`, `avg_order_value`

---

### `gold.vw_kpi_customer`

**Purpose:** Customer-level metrics including CLV and churn risk

**Key columns returned:**
`customer_key`, `full_name`, `segment`, `clv_score`, `days_since_last_order`,
`is_churn_risk`, `order_count`, `total_spend`, `avg_order_value`

---

### `gold.vw_kpi_product`

**Purpose:** Product performance metrics

**Key columns returned:**
`product_key`, `product_name`, `category`, `total_revenue`, `units_sold`,
`return_rate_pct`, `gross_margin_pct`, `refund_amount`

---

### `gold.vw_dq_summary`

**Purpose:** Latest data quality pipeline health metrics

**Key columns returned:**
`run_timestamp`, `suite_name`, `table_name`, `total_checks`,
`passing_checks`, `pass_rate_pct`, `run_status`

---

## Known Data Quality Issues

| # | Layer | Table | Issue | Impact | Status |
|---|---|---|---|---|---|
| 1 | Bronze | erp_orders | ~4 rows with `order_date` in 2027 | Inflates YTD revenue if not handled | Fixed in Silver — flagged as `is_date_anomaly = 1`, excluded from KPIs |
| 2 | Bronze | erp_products | 8 products with NULL `cost_price` | Gross margin = 0 for these products | Fixed in Silver — defaulted to 0, flagged as `is_cost_missing = 1` |
| 3 | Bronze | erp_order_items | Some rows with `quantity = 0` | Zero-value line items skew averages | Fixed in Silver — rows with qty = 0 excluded from fact_sales |
| 4 | Bronze | crm_customers | Duplicate customer records by email | Double-counts customers | Fixed in Silver — ROW_NUMBER deduplication, most recent kept |
| 5 | Bronze | crm_customers | `province` field uses mixed abbreviations and full names | Territory analysis unreliable | Fixed in Silver — standardised to full province names |
| 6 | Gold | dim_customer | `crm_customer_id` NULL for ~15% of ERP customers | CLV and segment data unavailable for these customers | Known gap — CRM coverage is incomplete. Flagged in dashboard. |

---

## Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial catalog — all Bronze, Silver, Gold tables and views | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*

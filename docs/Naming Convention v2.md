# Naming Conventions

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 2.0 | **Updated:** April 2026
**Change from v1.0:** Table names, column examples, and abbreviations updated
to reflect actual source dataset files (CR-006)
**Status:** Approved — applies to all layers, all contributors

---

## Why This Document Exists

Inconsistent naming is the fastest way to make a data warehouse unmaintainable.
This document defines one standard — and every table, column, file, model,
and script in this project follows it without exception.

> **Rule:** If it is not in this document, raise it as a question before
> you name it. Do not invent conventions mid-build.

---

## 1. General Principles

| Principle | Rule |
|---|---|
| Case | `snake_case` everywhere — no CamelCase, no PascalCase, no spaces |
| Language | English only |
| Abbreviations | Avoid unless listed in Section 9 |
| Length | Descriptive but concise — prefer `order_date` over `ord_dt` |
| Plurals | Table names are **singular** — `dim_customer` not `dim_customers` |
| Prefixes | Always use layer or type prefix — never a bare noun |
| Reserved words | Never use SQL reserved words as names (`date`, `order`, `name`, `value`) |

---

## 2. Database & Schema Naming

### Database

```
SalesIntelligenceDW
```

### Schemas

| Schema | Layer | Purpose |
|---|---|---|
| `bronze` | Bronze | Raw data exactly as ingested from source CSV files |
| `silver` | Silver | Cleansed, standardised, deduplicated data |
| `gold` | Gold | Business-ready star schema — facts, dims, KPI views |

```sql
-- Correct schema-qualified usage
SELECT * FROM bronze.crm_cust_info;
SELECT * FROM silver.stg_crm_customers;
SELECT * FROM gold.fact_sales;
```

---

## 3. Table Naming

### Format

```
[schema].[source_entity]
```

---

### Bronze Tables

Prefix: schema + source system abbreviation + entity name.
Table names reflect the **source system** and **entity** — not the CSV filename casing.
Original CSV filenames are preserved in documentation but table names follow
snake_case.

| Source File | Bronze Table Name | Source System |
|---|---|---|
| `crm_src/cust_info.csv` | `bronze.crm_cust_info` | CRM |
| `crm_src/prd_info.csv` | `bronze.crm_prd_info` | CRM |
| `crm_src/sales_details.csv` | `bronze.crm_sales_details` | CRM |
| `ERP_src/CUST_AZ12.csv` | `bronze.erp_cust_az12` | ERP |
| `ERP_src/LOC_A101.csv` | `bronze.erp_loc_a101` | ERP |
| `ERP_src/PX_CAT_G1V2.csv` | `bronze.erp_px_cat` | ERP |
| *(audit table)* | `bronze.load_log` | System |

**Rules for Bronze:**
- Name must reflect the source system and entity
- Do not rename or reinterpret content — Bronze is a raw mirror
- Source file names with underscores become part of the table name in lowercase
- Source file names with dots (`PX_CAT_G1V2`) are shortened to the meaningful part (`erp_px_cat`)

---

### Silver Tables (dbt staging models)

Prefix: `stg_` + source system + entity

| Bronze Table | Silver dbt Model | What it does |
|---|---|---|
| `bronze.crm_cust_info` | `silver.stg_crm_customers` | Dedup, TRIM names, expand gender/marital codes |
| `bronze.crm_prd_info` | `silver.stg_crm_products` | Pick current version, TRIM prd_line, handle NULL cost |
| `bronze.crm_sales_details` | `silver.stg_crm_sales` | Cast INT dates to DATE, exclude invalid sales |
| `bronze.erp_cust_az12` | `silver.stg_erp_demographics` | Strip NAS prefix from CID, standardise GEN |
| `bronze.erp_loc_a101` | `silver.stg_erp_location` | Remove hyphens from CID, standardise CNTRY |
| `bronze.erp_px_cat` | `silver.stg_erp_categories` | Clean reference data (already clean) |

**Rules for Silver:**
- Always prefix with `stg_` to signal staging/cleansed model
- Entity name is singular and descriptive (`customers` not `cust_info`)
- One model per source table — no joins at the Silver layer
- All column names in Silver follow the column naming rules in Section 4

---

### Gold Tables

**Fact tables:** `fact_[business_process]`

| Table | Grain |
|---|---|
| `gold.fact_sales` | One row per order line (`sls_ord_num` + `sls_prd_key`) |

**Dimension tables:** `dim_[entity]`

| Table | Source | Notes |
|---|---|---|
| `gold.dim_customer` | `stg_crm_customers` + `stg_erp_demographics` + `stg_erp_location` | SCD Type 2 — includes effective_date, expiry_date, is_current |
| `gold.dim_product` | `stg_crm_products` + `stg_erp_categories` | SCD Type 2 via prd_start_dt / prd_end_dt from source |
| `gold.dim_date` | Generated (2010–2030) | Full calendar dimension |
| `gold.dim_location` | `stg_erp_location` | Country hierarchy |

**Views (KPI layer):** `vw_kpi_[subject]`

| View | Purpose |
|---|---|
| `gold.vw_kpi_revenue` | Revenue actuals, MoM growth, YTD |
| `gold.vw_kpi_customer` | CLV, churn risk, new vs returning |
| `gold.vw_kpi_product` | Margin %, product line performance |
| `gold.vw_dq_summary` | Data quality pass/fail rates per pipeline run |

**Audit / operational tables:**

| Table | Purpose |
|---|---|
| `bronze.load_log` | Ingestion audit — source, rows, timestamp, status |
| `silver.dq_run_log` | Great Expectations checkpoint results per run |

---

## 4. Column Naming

### General rules

| Type | Convention | Example |
|---|---|---|
| Primary key (natural) | `[entity]_id` | `customer_id`, `product_id` |
| Business key (from source) | `[entity]_key` | `customer_key`, `product_key` |
| Surrogate key (Gold dims) | `[entity]_key` | `customer_key` INT IDENTITY |
| Foreign key | `[referenced_entity]_key` | `customer_key` in fact_sales |
| Date column | `[event]_date` | `order_date`, `ship_date` |
| Timestamp | `[event]_timestamp` | `load_timestamp` |
| Boolean / flag | `is_[state]` | `is_current`, `is_cost_missing` |
| Monetary amount | `[subject]_amount` | `sales_amount`, `cost_amount` |
| Quantity / count | `[subject]_qty` or `[subject]_count` | `order_qty`, `item_count` |
| Percentage | `[subject]_pct` | `margin_pct`, `dq_pass_pct` |
| Name / label | `[entity]_name` | `customer_name`, `product_name` |
| Category / type | `[subject]_category` | `product_category`, `product_line` |
| Audit column (DWH added) | `dwh_[field]` | `dwh_load_timestamp`, `dwh_source_system` |
| Cleaned version of a messy column | `[col]_clean` | `prd_line_clean`, `gender_clean`, `country_clean` |

### Source-to-Silver column renaming

Source CSV column names are often abbreviated or cryptic. Silver renames them
to follow conventions:

| Source column | Silver column | Source table |
|---|---|---|
| `cst_id` | `customer_id` | crm_cust_info |
| `cst_key` | `customer_key` | crm_cust_info |
| `cst_firstname` | `first_name` | crm_cust_info |
| `cst_lastname` | `last_name` | crm_cust_info |
| `cst_gndr` | `gender` | crm_cust_info |
| `cst_marital_status` | `marital_status` | crm_cust_info |
| `cst_create_date` | `customer_create_date` | crm_cust_info |
| `prd_id` | `product_id` | crm_prd_info |
| `prd_key` | `product_key` | crm_prd_info |
| `prd_nm` | `product_name` | crm_prd_info |
| `prd_cost` | `product_cost` | crm_prd_info |
| `prd_line` | `product_line` | crm_prd_info |
| `prd_start_dt` | `product_start_date` | crm_prd_info |
| `prd_end_dt` | `product_end_date` | crm_prd_info |
| `sls_ord_num` | `order_number` | crm_sales_details |
| `sls_prd_key` | `product_key` | crm_sales_details |
| `sls_cust_id` | `customer_id` | crm_sales_details |
| `sls_order_dt` | `order_date` | crm_sales_details |
| `sls_ship_dt` | `ship_date` | crm_sales_details |
| `sls_due_dt` | `due_date` | crm_sales_details |
| `sls_sales` | `sales_amount` | crm_sales_details |
| `sls_quantity` | `order_qty` | crm_sales_details |
| `sls_price` | `unit_price` | crm_sales_details |
| `CID` | `customer_key` (after stripping) | erp_cust_az12, erp_loc_a101 |
| `BDATE` | `birth_date` | erp_cust_az12 |
| `GEN` | `gender` | erp_cust_az12 |
| `CNTRY` | `country` | erp_loc_a101 |
| `CAT` | `category` | erp_px_cat |
| `SUBCAT` | `subcategory` | erp_px_cat |
| `MAINTENANCE` | `requires_maintenance` | erp_px_cat |

### SCD Type 2 standard columns

Every SCD Type 2 dimension must include these three columns:

```sql
effective_date    DATE    -- Date this version became active
expiry_date       DATE    -- Date superseded (NULL if current)
is_current        BIT     -- 1 = current record, 0 = historical
```

### Prohibited column names

Never use these — SQL reserved words or too ambiguous:

```
date    name    value    type    order
level   status  key      group   rank
```

Use instead: `order_date`, `customer_name`, `sales_amount`, `product_type`

---

## 5. SQL Script Naming

### Format

```
[sequence_number]_[layer]_[action]_[entity].sql
```

Zero-padded to 2 digits to enforce run order.

### Bronze scripts

```
01_bronze_create_database.sql
02_bronze_create_schemas.sql
03_bronze_create_load_log.sql
04_bronze_create_tables.sql
05_bronze_load_all.sql
06_bronze_verify.sql
```

### Silver scripts (dbt models replace manual SQL here)

```
10_silver_create_stg_crm_customers.sql   (reference only)
11_silver_create_stg_crm_products.sql
12_silver_create_stg_crm_sales.sql
13_silver_create_stg_erp_demographics.sql
14_silver_create_stg_erp_location.sql
15_silver_create_stg_erp_categories.sql
```

### Gold scripts

```
20_gold_create_dim_date.sql
21_gold_create_dim_location.sql
22_gold_create_dim_customer.sql
23_gold_create_dim_product.sql
24_gold_create_fact_sales.sql
25_gold_create_kpi_views.sql
```

### Verification scripts

```
30_verify_bronze_row_counts.sql
31_verify_silver_nulls.sql
32_verify_gold_referential_integrity.sql
```

---

## 6. dbt Model Naming

| Layer | Pattern | Example |
|---|---|---|
| Silver (staging) | `stg_[source]_[entity].sql` | `stg_crm_customers.sql` |
| Gold (dimension) | `dim_[entity].sql` | `dim_customer.sql` |
| Gold (fact) | `fact_[process].sql` | `fact_sales.sql` |
| Gold (KPI view) | `mart_[subject].sql` | `mart_revenue_kpi.sql` |

### schema.yml pattern

```yaml
models:
  - name: stg_crm_customers
    description: "Cleansed CRM customer data — deduplicated, names trimmed,
                  gender and marital status expanded to full words"
    columns:
      - name: customer_id
        description: "Customer ID from CRM cust_info — unique after deduplication"
        tests:
          - unique
          - not_null
      - name: customer_key
        description: "Business key — e.g. AW00011000. Used to join ERP tables."
        tests:
          - not_null
```

---

## 7. Python File Naming

```
[sequence]_[action]_[subject].py

01_profile_bronze.py          ← ydata-profiling for all Bronze tables
02_run_ge_suite.py            ← Execute Great Expectations checkpoints
03_parse_ge_results.py        ← Parse GE JSON output → silver.dq_run_log
04_load_dim_date.py           ← Generate and insert date dimension rows
```

### Python variable naming

```python
# Variables — snake_case
customer_id    = "AW00011000"
sales_amount   = 1500.00
is_current     = True

# Functions — snake_case verb_noun
def load_bronze_table():
def run_quality_checks():
def strip_cid_prefix(cid):          # e.g. 'NASAW00011000' → 'AW00011000'
def standardise_gender(raw_gender): # e.g. 'M ' → 'Male'
def standardise_country(raw_cntry): # e.g. 'US' → 'United States'

# Constants — UPPER_SNAKE_CASE
DB_SERVER    = "localhost"
DB_NAME      = "SalesIntelligenceDW"
CRM_SRC_PATH = "datasets/Datasets/crm_src/"
ERP_SRC_PATH = "datasets/Datasets/ERP_src/"
```

---

## 8. File & Folder Naming

```
enterprise-sales-intelligence/
├── datasets/
│   └── Datasets/
│       ├── crm_src/            ← CRM source CSVs (original names preserved)
│       │   ├── cust_info.csv
│       │   ├── prd_info.csv
│       │   └── sales_details.csv
│       └── ERP_src/            ← ERP source CSVs (original names preserved)
│           ├── CUST_AZ12.csv
│           ├── LOC_A101.csv
│           └── PX_CAT_G1V2.csv
├── scripts/
│   ├── bronze/                 ← numbered SQL scripts
│   ├── silver/                 ← reference SQL (Silver built via dbt)
│   └── gold/                   ← numbered Gold SQL scripts
├── dbt/
│   └── models/
│       ├── silver/             ← stg_*.sql models
│       └── gold/               ← dim_*.sql, fact_*.sql models
├── data_quality/               ← Great Expectations suites
├── analytics/
│   ├── reports/                ← SQL analytical reports
│   └── reports/profiling/      ← ydata-profiling HTML reports
├── dashboard/                  ← Streamlit app.py
├── docs/                       ← all PO documents
└── diagrams/                   ← DrawIO + PNG exports
```

> **Note on source file names:** The original CSV filenames (`CUST_AZ12.csv`,
> `PX_CAT_G1V2.csv`) are preserved exactly in the `datasets/` folder
> for traceability. Only Bronze table names follow snake_case convention.

---

## 9. GitHub Naming

### Branches

| Type | Format | Example |
|---|---|---|
| Main | `main` | `main` |
| Development | `dev` | `dev` |
| Feature | `feature/[description]` | `feature/bronze-erp-ingestion` |
| Bug fix | `fix/[description]` | `fix/crm-cid-stripping-logic` |
| Documentation | `docs/[description]` | `docs/data-catalog-v2` |

### Commit messages

```
[layer/area]: short description

bronze: load all 6 source tables with load_log audit trail
silver: add TRIM and gender standardisation to stg_crm_customers
gold: build dim_customer with SCD Type 2 from 3 Silver sources
dbt: add not_null tests for all surrogate keys in schema.yml
fix: correct NAS prefix stripping for ERP CID column
docs: update naming conventions v2.0 for actual dataset files
```

### GitHub Projects labels

| Label | Colour | Meaning |
|---|---|---|
| `epic` | Purple | Top-level theme |
| `user-story` | Blue | Business requirement |
| `task` | Grey | Technical step |
| `must-have` | Green | Cannot ship without |
| `should-have` | Yellow | Important, not blocking |
| `blocked` | Red | Needs resolution |
| `bronze` | Orange | Bronze layer work |
| `silver` | Silver/grey | Silver layer work |
| `gold` | Gold/amber | Gold layer work |
| `documentation` | Light blue | Docs and PO artifacts |

---

## 10. Approved Abbreviations

| Abbreviation | Full term | Usage example |
|---|---|---|
| `crm` | Customer Relationship Management | `bronze.crm_cust_info` |
| `erp` | Enterprise Resource Planning | `bronze.erp_cust_az12` |
| `stg` | Staging | `silver.stg_crm_customers` |
| `dim` | Dimension | `gold.dim_customer` |
| `fact` | Fact table | `gold.fact_sales` |
| `vw` | View | `gold.vw_kpi_revenue` |
| `kpi` | Key Performance Indicator | `vw_kpi_revenue` |
| `dq` | Data Quality | `dq_run_log` |
| `dwh` | Data Warehouse | `dwh_load_timestamp` |
| `pct` | Percentage | `margin_pct` |
| `qty` | Quantity | `order_qty` |
| `id` | Identifier | `customer_id` |
| `nm` | Name (source abbreviation) | renamed to `_name` in Silver |
| `dt` | Date (source abbreviation) | renamed to `_date` in Silver |
| `sls` | Sales (source prefix) | renamed without prefix in Silver |
| `cst` | Customer (source prefix) | renamed without prefix in Silver |
| `prd` | Product (source prefix) | renamed without prefix in Silver |
| `clv` | Customer Lifetime Value | `clv_score` |
| `mom` | Month over Month | `mom_growth_pct` |
| `ytd` | Year to Date | `ytd_revenue` |
| `scd` | Slowly Changing Dimension | internal docs only |
| `ge` | Great Expectations | internal docs only |
| `cte` | Common Table Expression | internal docs only |
| `pk` | Primary Key (constraint naming) | `pk_dim_customer` |
| `fk` | Foreign Key (constraint naming) | `fk_fact_sales_customer` |

---

## 11. Quick Reference Card

```
BRONZE TABLES     bronze.crm_cust_info
                  bronze.crm_prd_info
                  bronze.crm_sales_details
                  bronze.erp_cust_az12
                  bronze.erp_loc_a101
                  bronze.erp_px_cat

SILVER MODELS     stg_crm_customers.sql
(dbt)             stg_crm_products.sql
                  stg_crm_sales.sql
                  stg_erp_demographics.sql
                  stg_erp_location.sql
                  stg_erp_categories.sql

GOLD TABLES       dim_customer   (SCD Type 2)
                  dim_product    (SCD Type 2)
                  dim_date
                  dim_location
                  fact_sales

GOLD VIEWS        vw_kpi_revenue
                  vw_kpi_customer
                  vw_kpi_product
                  vw_dq_summary

COLUMN RULE       source prefix stripped in Silver
                  cst_ / prd_ / sls_ / CID → clean names
                  [col]_clean for standardised versions

BRANCHES          feature/[description]
                  fix/[description]
                  docs/[description]

COMMITS           [layer]: short description of change

PYTHON            snake_case variables + functions
                  UPPER_SNAKE_CASE constants
```

---

## 12. Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial version — assumed dataset structure | Devanshi |
| 2.0 | April 2026 | Updated Bronze table names to actual source files. Added source-to-Silver column renaming table. Updated folder structure to reflect real dataset paths. Added source abbreviations (cst_, prd_, sls_) to approved list. (CR-006) | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*
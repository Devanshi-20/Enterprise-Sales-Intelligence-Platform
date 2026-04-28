# Naming Conventions

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Status:** Approved — applies to all layers, all contributors

---

## Why This Document Exists

Inconsistent naming is the fastest way to make a data warehouse unmaintainable.
When `CustomerID`, `customer_id`, `cust_id`, and `CustID` all appear in the same project,
every new query becomes a guessing game. This document defines one standard —
and every table, column, file, model, and script in this project follows it.

> **Rule:** If it is not in this document, raise it as a question before you name it.
> Do not invent conventions mid-build.

---

## 1. General Principles

| Principle | Rule |
|---|---|
| Case | `snake_case` everywhere — no CamelCase, no PascalCase, no spaces |
| Language | English only |
| Abbreviations | Avoid unless listed in the approved abbreviations table (Section 9) |
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

One database. Three schemas inside it — one per Medallion layer.

### Schemas

| Schema | Layer | Purpose |
|---|---|---|
| `bronze` | Bronze | Raw data exactly as ingested from source systems |
| `silver` | Silver | Cleansed, standardised, deduplicated data |
| `gold` | Gold | Business-ready star schema — facts, dims, KPI views |

```sql
-- Correct usage
SELECT * FROM bronze.erp_orders;
SELECT * FROM silver.stg_crm_customer;
SELECT * FROM gold.fact_sales;
```

---

## 3. Table Naming

### Format

```
[schema].[layer_source_entity]
```

### Bronze tables

Prefix: `bronze` schema + source system abbreviation + entity name

| Pattern | Example |
|---|---|
| `bronze.[source]_[entity]` | `bronze.crm_cust_info` |
| | `bronze.crm_prd_info` |
| | `bronze.crm_sales_details` |
| | `bronze.erp_cust_az12` |
| | `bronze.erp_loca101` |
| | `bronze.erp_px_catg1v2` |

Rules for Bronze:
- Name must reflect the source system and entity exactly
- Do not rename or reinterpret — Bronze is a mirror of the source
- Never abbreviate the entity name in Bronze

### Silver tables (dbt staging models)

Prefix: `stg_` + source system + entity name

| Pattern | Example |
|---|---|
| `silver.stg_[source]_[entity]` | `silver.stg_crm_cust_info` |
| | `silver.stg_crm_sales` |
| | `silver.stg_erp_demographics` |

Rules for Silver:
- Always prefix with `stg_` to signal this is a staging/cleansed model
- Entity name is singular
- One model per source table — no joins at the Silver layer

### Gold tables

**Fact tables:** `fact_[business_process]`

| Table | Grain |
|---|---|
| `gold.fact_sales` | One row per order line item |

**Dimension tables:** `dim_[entity]`

| Table | Notes |
|---|---|
| `gold.dim_customer` | SCD Type 2 — includes effective_date, expiry_date, is_current |
| `gold.dim_product` | SCD Type 2 — includes category hierarchy |
| `gold.dim_date` | Full calendar dimension 2020–2030 |
| `gold.dim_location` | Region → Country → City hierarchy |

**Views (KPI layer):** `vw_kpi_[subject]`

| View | Purpose |
|---|---|
| `gold.vw_kpi_revenue` | Revenue actuals, MoM growth, YTD vs target |
| `gold.vw_kpi_customer` | CLV, churn risk score, acquisition cost |
| `gold.vw_kpi_product` | Margin %, return rate, sell-through rate |
| `gold.vw_dq_summary` | Data quality pass/fail rates per pipeline run |

### Audit / operational tables

| Table | Purpose |
|---|---|
| `bronze.load_log` | Ingestion audit — source, rows, timestamp, status |
| `silver.dq_run_log` | Great Expectations checkpoint results per run |

---

## 4. Column Naming

### General rules

| Type | Convention | Example |
|---|---|---|
| Primary key (natural) | `[entity]_id` | `customer_id`, `order_id` |
| Surrogate key (Gold dims) | `[entity]_key` | `customer_key`, `product_key` |
| Foreign key | `[referenced_entity]_key` | `customer_key` in fact_sales |
| Date column | `[event]_date` | `order_date`, `ship_date` |
| Timestamp column | `[event]_timestamp` | `created_timestamp`, `load_timestamp` |
| Boolean / flag | `is_[state]` | `is_current`, `is_deleted`, `is_weekend` |
| Monetary amount | `[subject]_amount` | `order_amount`, `refund_amount` |
| Quantity / count | `[subject]_qty` or `[subject]_count` | `order_qty`, `item_count` |
| Percentage | `[subject]_pct` | `margin_pct`, `return_pct` |
| Name / label | `[entity]_name` | `customer_name`, `product_name` |
| Category / type | `[subject]_category` or `[subject]_type` | `product_category`, `customer_type` |
| Calculated / derived | `[subject]_[calc]` | `gross_margin_pct`, `days_since_order` |
| Audit column (DWH) | `dwh_[field]` | `dwh_created_date`, `dwh_source_system` |

### SCD Type 2 standard columns

Every SCD Type 2 dimension must include these three columns with exactly these names:

```sql
effective_date    DATE         -- Date this version became active
expiry_date       DATE         -- Date this version was superseded (NULL if current)
is_current        BIT          -- 1 = current record, 0 = historical
```

### Prohibited column names

Never use these — they are SQL reserved words or ambiguous:

```
date        name        value       type        order
level       status      key         group       rank
```

Instead use: `order_date`, `customer_name`, `order_amount`, `customer_type`, `order_status`

---

## 5. SQL Script Naming

### Format

```
[sequence_number]_[layer]_[action]_[entity].sql
```

Scripts are numbered to enforce run order. Zero-padded to 2 digits.

### Bronze scripts

```
01_bronze_create_database.sql
02_bronze_create_schemas.sql
03_bronze_create_erp_tables.sql
04_bronze_load_erp_orders.sql
05_bronze_load_erp_products.sql
06_bronze_create_crm_tables.sql
07_bronze_load_crm_customers.sql
08_bronze_load_crm_contacts.sql
09_bronze_create_load_log.sql
```

### Silver scripts (manual — before dbt)

```
10_silver_create_stg_erp_orders.sql
11_silver_create_stg_erp_products.sql
12_silver_create_stg_crm_customer.sql
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

### Quality check scripts

```
30_quality_check_bronze_row_counts.sql
31_quality_check_silver_nulls.sql
32_quality_check_gold_referential_integrity.sql
```

---

## 6. dbt Model Naming

### File names

dbt model files follow the same convention as SQL scripts but without sequence numbers —
dbt handles run order through `ref()` dependencies.

| Layer | Pattern | Example |
|---|---|---|
| Silver (staging) | `stg_[source]_[entity].sql` | `stg_erp_orders.sql` |
| Gold (dimension) | `dim_[entity].sql` | `dim_customer.sql` |
| Gold (fact) | `fact_[process].sql` | `fact_sales.sql` |
| Gold (mart/KPI) | `mart_[subject].sql` | `mart_revenue_kpi.sql` |

### schema.yml naming

Every dbt model must have a corresponding entry in `schema.yml`:

```yaml
models:
  - name: stg_erp_orders           # matches SQL file name exactly
    description: "Cleansed and standardised ERP order data from Bronze layer"
    columns:
      - name: order_id              # matches column name in SQL exactly
        description: "Unique identifier for each order from ERP source"
        tests:
          - unique
          - not_null
      - name: customer_id
        description: "Customer identifier — links to CRM via reconciliation in Silver"
        tests:
          - not_null
```

### dbt source naming

```yaml
sources:
  - name: bronze                    # schema name
    database: SalesIntelligenceDW
    tables:
      - name: erp_orders            # table name without schema prefix
      - name: crm_customers
```

---

## 7. Python File Naming

### Format

```
[sequence_number]_[action]_[subject].py
```

| File | Purpose |
|---|---|
| `01_profile_bronze_erp.py` | ydata-profiling report for ERP Bronze tables |
| `02_profile_bronze_crm.py` | ydata-profiling report for CRM Bronze tables |
| `03_run_ge_suite_silver.py` | Execute Great Expectations checkpoint on Silver |
| `04_parse_ge_results.py` | Parse GE JSON output → dq_run_log SQL table |
| `05_load_dim_date.py` | Bulk generate and insert date dimension rows |

### Python variable and function naming

```python
# Variables — snake_case
customer_id       = "C001"
order_total       = 1500.00
is_current_record = True

# Functions — snake_case verb_noun
def load_bronze_table():
def run_quality_checks():
def parse_ge_checkpoint_results():
def calculate_clv():

# Constants — UPPER_SNAKE_CASE
DB_SERVER         = "localhost"
DB_NAME           = "SalesIntelligenceDW"
BRONZE_SCHEMA     = "bronze"
SILVER_SCHEMA     = "silver"
GOLD_SCHEMA       = "gold"

# Classes — PascalCase (if used)
class DataQualityRunner:
class BronzeIngestionPipeline:
```

---

## 8. File & Folder Naming

### Folders

All lowercase, hyphen-separated for multi-word names:

```
datasets/
scripts/
  bronze/
  silver/
  gold/
  quality_checks/
dbt/
  models/
    bronze/
    silver/
    gold/
data_quality/
analytics/
  reports/
dashboard/
docs/
diagrams/
.github/
  workflows/
```

### Documentation files

```
BRD.md
naming_conventions.md               ← this file
kpi_definitions.md
data_catalog.md
definition_of_done.md
stakeholder_communication_plan.md
risk_register.md
change_log.md
project_closure.md
```

### Diagram files

```
architecture.drawio
architecture.png                    ← exported for README
data_flow.drawio
star_schema.drawio
star_schema.png                     ← exported for README
```

### Sprint documents

```
docs/sprint_reviews/
  sprint_1_review.md
  sprint_2_review.md
  sprint_3_review.md
docs/sprint_retrospectives.md
```

### Persona documents

```
docs/personas/
  Persona_01_Sarah_Chen.docx
  Persona_02_Marcus_Obi.docx
  Persona_03_Priya_Sharma.docx
```

---

## 9. GitHub Naming

### Repository

```
enterprise-sales-intelligence
```

### Branch names

| Branch type | Format | Example |
|---|---|---|
| Main branch | `main` | `main` |
| Development | `dev` | `dev` |
| Feature branch | `feature/[short-description]` | `feature/bronze-erp-ingestion` |
| Bug fix | `fix/[short-description]` | `fix/null-customer-id-silver` |
| Documentation | `docs/[short-description]` | `docs/data-catalog` |
| Release | `release/v[version]` | `release/v1.0` |

### Commit message format

```
[layer/area]: short description of what changed

Optional longer explanation if needed.
```

Examples:

```
bronze: add load_log audit table with row count and status columns

silver: fix null customer_id deduplication logic in stg_crm_customer

gold: add SCD Type 2 columns to dim_customer (effective_date, expiry_date, is_current)

dbt: add not_null and unique tests for all fact_sales foreign keys

docs: update naming conventions with Python file standards

fix: correct order_date cast failing on NULL values in stg_erp_orders

ci: add GitHub Actions workflow for dbt test on PR to main
```

### GitHub Projects — label naming

| Label | Colour | Meaning |
|---|---|---|
| `epic` | Purple | Top-level theme |
| `user-story` | Blue | Business requirement |
| `task` | Grey | Technical implementation step |
| `must-have` | Green | Cannot ship without this |
| `should-have` | Yellow | Important but not blocking |
| `could-have` | Light grey | Nice to have |
| `blocked` | Red | Cannot progress — needs resolution |
| `bronze` | Orange | Bronze layer work |
| `silver` | Silver/grey | Silver layer work |
| `gold` | Gold/amber | Gold layer work |
| `dashboard` | Teal | Dashboard and reporting work |
| `documentation` | Light blue | Docs, BRD, personas, conventions |

---

## 10. Approved Abbreviations

Only these abbreviations are allowed. Any other shortening must be spelled out in full.

| Abbreviation | Full term | Usage example |
|---|---|---|
| `erp` | Enterprise Resource Planning | `bronze.erp_orders` |
| `crm` | Customer Relationship Management | `bronze.crm_customers` |
| `stg` | Staging | `silver.stg_erp_orders` |
| `dim` | Dimension | `gold.dim_customer` |
| `fact` | Fact | `gold.fact_sales` |
| `vw` | View | `gold.vw_kpi_revenue` |
| `kpi` | Key Performance Indicator | `vw_kpi_revenue` |
| `dq` | Data Quality | `dq_run_log` |
| `dwh` | Data Warehouse | `dwh_created_date` |
| `pct` | Percentage | `margin_pct` |
| `qty` | Quantity | `order_qty` |
| `id` | Identifier | `customer_id` |
| `dt` | Date (avoid — use `_date` instead) | Use `order_date` not `order_dt` |
| `usp` | User Stored Procedure | `usp_bronze_load_erp` |
| `pk` | Primary Key (constraint naming only) | `pk_dim_customer` |
| `fk` | Foreign Key (constraint naming only) | `fk_fact_sales_customer` |
| `clv` | Customer Lifetime Value | `clv_score` |
| `mom` | Month over Month | `mom_growth_pct` |
| `ytd` | Year to Date | `ytd_revenue` |
| `scd` | Slowly Changing Dimension | internal docs only |
| `ge` | Great Expectations | internal docs only |
| `cte` | Common Table Expression | internal docs only |

---

## 11. Quick Reference Card

Copy this into a sticky note or pin it in your editor.

```
TABLES          bronze.[source]_[entity]
                silver.stg_[source]_[entity]
                gold.dim_[entity]
                gold.fact_[process]
                gold.vw_kpi_[subject]

COLUMNS         [entity]_id         primary key
                [entity]_key        surrogate key (Gold)
                [event]_date        date field
                is_[state]          boolean
                [subject]_amount    money
                [subject]_pct       percentage
                dwh_[field]         audit column

SQL SCRIPTS     01_bronze_[action]_[entity].sql
                10_silver_[action]_[entity].sql
                20_gold_[action]_[entity].sql

dbt MODELS      stg_[source]_[entity].sql
                dim_[entity].sql
                fact_[process].sql

BRANCHES        feature/[short-description]
                fix/[short-description]
                docs/[short-description]

COMMITS         [layer]: short description of what changed

PYTHON          snake_case variables and functions
                UPPER_SNAKE_CASE constants
                PascalCase classes
```

---

## 12. Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial version — covers all layers, scripts, dbt, Python, GitHub | Devanshi |
| 1.1 | April 2026 | Modified version — Replace details with actual datasets | Devanshi |

---

*This document is part of the Enterprise Sales Intelligence Platform project.*
*GitHub: github.com/Devanshi-20/enterprise-sales-intelligence*

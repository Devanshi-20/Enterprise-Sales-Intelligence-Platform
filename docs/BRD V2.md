# Business Requirements Document

**Project:** Enterprise Sales Intelligence Platform
**Version:** 2.0 | **Status:** Updated — Dataset Structure Confirmed
**Prepared by:** Devanshi | **Date:** April 2026
**Change from v1.0:** Source files confirmed after Bronze profiling. KPIs, scope, and table references updated to reflect actual dataset structure (CR-006).

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Business Context & Problem Statement](#2-business-context--problem-statement)
3. [Stakeholders & User Personas](#3-stakeholders--user-personas)
4. [Functional Requirements](#4-functional-requirements)
5. [Analytical Use Cases](#5-analytical-use-cases)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [KPI Definitions](#7-kpi-definitions)
8. [Project Scope](#8-project-scope)
9. [Success Metrics & Acceptance Criteria](#9-success-metrics--acceptance-criteria)
10. [Risks & Mitigations](#10-risks--mitigations)
11. [Project Timeline](#11-project-timeline)
12. [Document Sign-Off](#12-document-sign-off)

---

## 1. Executive Summary

This Business Requirements Document defines the scope, objectives, stakeholder needs, and success criteria for the **Enterprise Sales Intelligence Platform** — a modern data warehouse and analytics solution built on SQL Server using Medallion Architecture (Bronze → Silver → Gold).

The project consolidates sales data from two source systems into a single governed analytical environment:

- **CRM system** — 3 CSV files: customer info, product info, sales transactions
- **ERP system** — 3 CSV files: customer demographics, customer location, product categories

> **Project Objective:** Enable business stakeholders to make data-driven decisions by providing a reliable, tested, and analytically optimised data platform — built from 6 source CSV files, powered by dbt and Great Expectations, and served through a Streamlit executive dashboard.

### 1.1 What Changed from v1.0

After profiling the actual source datasets in the Bronze layer, this document has been updated:

| Change | Detail |
|---|---|
| Source files confirmed | 6 CSVs across `crm_src/` and `ERP_src/` — different names and structure from v1.0 assumption |
| KPI removed | Refund Impact on Net Revenue — no `refund_amount` column in source |
| KPI removed | Sales Rep vs Quota — no `sales_rep_id` column in source |
| KPI added | Revenue by Country — enabled by `ERP_src/LOC_A101.csv` |
| KPI added | Customer Age Group Revenue — enabled by `BDATE` in `ERP_src/CUST_AZ12.csv` |
| DQ issues logged | 13 real data quality issues found during Bronze profiling — all documented |

---

## 2. Business Context & Problem Statement

### 2.1 Source Systems — Confirmed Dataset Structure

| System | Source File | Bronze Table | Rows | Content |
|---|---|---|---|---|
| CRM | `crm_src/cust_info.csv` | `bronze.crm_cust_info` | 18,493 | Customer ID, name, gender, marital status, create date |
| CRM | `crm_src/prd_info.csv` | `bronze.crm_prd_info` | 397 | Product key, name, cost, line code, start/end dates |
| CRM | `crm_src/sales_details.csv` | `bronze.crm_sales_details` | 60,398 | Order number, product key, customer ID, dates (as integers), sales, qty, price |
| ERP | `ERP_src/CUST_AZ12.csv` | `bronze.erp_cust_az12` | 18,483 | Customer ID (NAS prefix), birth date, gender (9 messy formats) |
| ERP | `ERP_src/LOC_A101.csv` | `bronze.erp_loc_a101` | 18,484 | Customer ID (hyphenated), country (13 inconsistent formats) |
| ERP | `ERP_src/PX_CAT_G1V2.csv` | `bronze.erp_px_cat` | 36 | Product category, subcategory, maintenance flag |
| **Total** | | | **96,291** | |

### 2.2 Key Integration Challenge — CID Reconciliation

The most critical data engineering task in this project is joining CRM and ERP records. Each system uses a different format for the same customer identifier:

```
CRM   crm_cust_info.cst_key  =  'AW00011000'
ERP   erp_cust_az12.CID      =  'NASAW00011000'  → strip 'NAS' prefix
ERP   erp_loc_a101.CID       =  'AW-00011000'    → remove hyphens
```

All three formats refer to the same customer. The Silver layer reconciles them using:

```sql
-- Strip NAS prefix from erp_cust_az12
SUBSTRING(CID, 4, LEN(CID))    →  'AW00011000'

-- Remove hyphens from erp_loc_a101
REPLACE(CID, '-', '')          →  'AW00011000'
```

### 2.3 Current State — Business Pain Points

- Sales data siloed across CRM and ERP — no unified view of customer purchasing behaviour
- Manual reporting requires hours of CSV exports and VLOOKUP reconciliation every week
- Numbers never match between CRM and ERP reports because of the customer ID format mismatch
- No historical tracking of product pricing changes — current and past prices mixed in source
- No automated data quality checks — data reliability is unknown before numbers reach stakeholders
- Decision-makers cannot answer ad-hoc questions without requesting a report from the analyst

### 2.4 Desired Future State

- A unified Bronze → Silver → Gold pipeline that automatically reconciles CRM and ERP customer records
- Automated data quality gates via Great Expectations that catch issues before analytics
- A star schema Gold layer with SCD Type 2 on customer and product dimensions
- An executive dashboard that answers all 15 user stories without writing SQL
- Fully documented, version-controlled, and reproducible from README in under 60 minutes

### 2.5 Strategic Alignment

| Strategic Goal | How This Project Delivers |
|---|---|
| Unified sales visibility | Single Gold layer joins CRM + ERP for the first time |
| Reduce manual reporting | dbt pipeline + Streamlit dashboard replaces weekly spreadsheet work |
| Data trust | Great Expectations DQ suite + DQ Health dashboard page |
| Historical analysis | SCD Type 2 on dim_customer and dim_product preserves changes |
| Self-service analytics | All 15 use cases answerable from dashboard without SQL |

---

## 3. Stakeholders & User Personas

### 3.1 Stakeholder Register

| Stakeholder | Role | Interest | Influence | Key Needs |
|---|---|---|---|---|
| Sarah Chen | Sales Manager — Primary User | High | Medium | Revenue KPIs, CLV ranking, churn risk, product return rate, Monday dashboard |
| Marcus Obi | Finance Analyst — Primary User | High | Medium | Margin % by product line, monthly cohort, age group revenue, full auditability |
| Priya Sharma | CFO — Executive Sponsor | High | High | MoM growth, YTD vs plan, DQ health indicator, revenue by country |
| Devanshi | Data Engineer + Product Owner | High | High | Clean architecture, dbt models, GE coverage, CI/CD pipeline |
| IT / DBA | Infrastructure | Medium | Medium | SQL Server access, performance, backup |

### 3.2 Persona 1 — Sarah Chen, Regional Sales Manager

**Quote:** *"I need to know which products and customers are driving revenue this quarter — without spending half my Monday in spreadsheets."*

| Attribute | Detail |
|---|---|
| Goal | Single KPI view every Monday — revenue vs prior period, top customers, churn risk, return rate |
| Pain point | Spends 4+ hours weekly reconciling ERP and CRM exports in Excel. Numbers never match. |
| Analytical needs | Revenue by product · Top 10 CLV customers · Churn risk flag (60/90 day) · Product return rate |
| Success | Opens dashboard Monday 8am, all KPIs visible, can drill to any product or customer without SQL |

### 3.3 Persona 2 — Marcus Obi, Finance Business Analyst

**Quote:** *"I don't mind doing the analysis. What I can't afford is spending 80% of my time just trying to trust the data."*

| Attribute | Detail |
|---|---|
| Goal | Produce CFO monthly pack in under 30 minutes from warehouse data alone |
| Pain point | ERP and CRM use different customer IDs — manual reconciliation is error-prone and weekly |
| Analytical needs | Gross margin % by product line · Revenue cohort new vs returning · Age group revenue · Auditability |
| Success | Traces any dashboard figure back to source CSV in under 5 minutes. No manual joins needed. |

### 3.4 Persona 3 — Priya Sharma, CFO

**Quote:** *"I don't need more data. I need fewer surprises — and I need to know the numbers are trustworthy before I present them."*

| Attribute | Detail |
|---|---|
| Goal | Data-driven board reporting with consistent, governed, defensible numbers |
| Pain point | Has seen too many data projects that delivered dashboards nobody trusted |
| Analytical needs | MoM revenue growth · YTD vs plan · Revenue by country · DQ health indicator |
| Success | Sees green DQ indicator before board meeting. Numbers have formal definitions. No one-person dependency. |

---

## 4. Functional Requirements

### 4.1 Bronze Layer — Raw Ingestion

- Load all 6 source CSV files into Bronze staging tables in SQL Server exactly as-is
- Add `dwh_load_timestamp` audit column to every Bronze table (not in source — added by pipeline)
- Log every ingestion run to `bronze.load_log`: table name, source file, row count, timestamp, load status, error message
- Generate `ydata-profiling` HTML report for all 6 Bronze tables
- Document all data quality issues found in `docs/data_catalog.md` Known Issues section

**Bronze tables created:**

```
bronze.crm_cust_info       ← cust_info.csv
bronze.crm_prd_info        ← prd_info.csv
bronze.crm_sales_details   ← sales_details.csv
bronze.erp_cust_az12       ← CUST_AZ12.csv
bronze.erp_loc_a101        ← LOC_A101.csv
bronze.erp_px_cat          ← PX_CAT_G1V2.csv
bronze.load_log            ← system audit table
```

### 4.2 Silver Layer — dbt + Great Expectations

Build 6 dbt staging models — one per Bronze table — with the following transformations:

**`stg_crm_customers`** (from `bronze.crm_cust_info`):
- Deduplicate `cst_id` — 9 duplicates in source. Keep most recent by `cst_create_date`.
- `LTRIM(RTRIM())` on `cst_firstname` and `cst_lastname`
- Expand `cst_gndr`: `'M'` → `'Male'`, `'F'` → `'Female'`, NULL → `'N/A'`
- Expand `cst_marital_status`: `'M'` → `'Married'`, `'S'` → `'Single'`, NULL → `'N/A'`
- Rename all columns to follow naming conventions (remove `cst_` prefix)

**`stg_crm_products`** (from `bronze.crm_prd_info`):
- Filter to current product version: `WHERE prd_end_dt IS NULL`
- `LTRIM(RTRIM())` on `prd_line` to remove trailing spaces (`'R '` → `'R'`)
- Expand `prd_line`: `'R'` → `'Road'`, `'M'` → `'Mountain'`, `'T'` → `'Touring'`, `'S'` → `'Standard'`
- Flag NULL `prd_cost` with `is_cost_missing = 1`, default to 0
- Rename columns (remove `prd_` prefix)

**`stg_crm_sales`** (from `bronze.crm_sales_details`):
- Cast integer dates to DATE: `CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)`
- Handle invalid date integers (0, NULL, < 8 digits) with NULLIF and CASE
- Derive `sls_sales` from `sls_quantity * sls_price` where NULL or invalid
- Exclude rows where `sls_sales <= 0` (5 rows) and `sls_quantity <= 0`
- Rename columns (remove `sls_` prefix)

**`stg_erp_demographics`** (from `bronze.erp_cust_az12`):
- Strip `NAS` prefix from `CID`: `SUBSTRING(CID, 4, LEN(CID))` → `'AW00011000'`
- Standardise `GEN` with 9 raw formats → `'Male'` / `'Female'` / `'N/A'`
- Rename: `CID` → `customer_key`, `BDATE` → `birth_date`, `GEN` → `gender`

**`stg_erp_location`** (from `bronze.erp_loc_a101`):
- Remove hyphens from `CID`: `REPLACE(CID, '-', '')` → `'AW00011000'`
- Standardise `CNTRY`: `'US'/'USA'` → `'United States'`, `'DE'` → `'Germany'`, whitespace/NULL → `'N/A'`
- Rename: `CID` → `customer_key`, `CNTRY` → `country`

**`stg_erp_categories`** (from `bronze.erp_px_cat`):
- Clean reference table — rename columns to follow conventions
- Rename: `ID` → `category_id`, `CAT` → `category`, `SUBCAT` → `subcategory`, `MAINTENANCE` → `requires_maintenance`

**dbt tests (schema.yml):**
- `not_null` on all primary keys and business keys
- `unique` on all primary keys
- `accepted_values` on `gender`, `product_line`, `country`
- `relationships` tests for FK integrity where applicable

**Great Expectations suites:**
- Minimum 8 expectations per Silver table
- `expect_column_values_to_not_be_null` on all key columns
- `expect_column_values_to_be_between` for `sales_amount > 0`, `order_qty > 0`
- `expect_column_values_to_be_in_set` for `gender`, `product_line`, `country`
- `expect_table_row_count_to_be_between` — minimum rows expected per table
- Parse GE checkpoint JSON results into `silver.dq_run_log`

### 4.3 Gold Layer — Star Schema

Build the following Gold objects:

**`gold.fact_sales`**
- Grain: one row per order line (`order_number` + `product_key`)
- Foreign keys to all 4 dimensions: `customer_key`, `product_key`, `date_key`, `location_key`
- Measures: `sales_amount`, `order_qty`, `unit_price`, `product_cost`, `gross_margin`

**`gold.dim_customer`** — SCD Type 2
- Built from: `stg_crm_customers` + `stg_erp_demographics` + `stg_erp_location`
- Joined via cleaned `customer_key`
- Tracked attributes: `country`, `gender`, `marital_status` — changes preserved historically
- SCD columns: `effective_date`, `expiry_date`, `is_current`

**`gold.dim_product`** — SCD Type 2
- Built from: `stg_crm_products` + `stg_erp_categories`
- Historical versions preserved using `prd_start_dt` / `prd_end_dt` from source
- Tracked attributes: `product_cost`, `product_line` — price changes preserved
- SCD columns: `effective_date`, `expiry_date`, `is_current`

**`gold.dim_date`**
- Generated calendar 2010–2030 (covers earliest sales date in source)
- Includes: `day_name`, `month_name`, `quarter_num`, `fiscal_year`, `is_weekend`, `is_holiday`

**`gold.dim_location`**
- Built from: `stg_erp_location`
- Hierarchy: `country` (standardised)

**KPI Views:**

| View | Purpose | Key columns |
|---|---|---|
| `gold.vw_kpi_revenue` | Revenue, MoM, YTD | `total_revenue`, `mom_growth_pct`, `ytd_revenue` |
| `gold.vw_kpi_customer` | CLV, churn, cohort | `clv_score`, `is_churn_risk`, `customer_type` |
| `gold.vw_kpi_product` | Margin, product line | `gross_margin_pct`, `product_line`, `revenue_by_line` |
| `gold.vw_dq_summary` | Pipeline health | `pass_rate_pct`, `run_timestamp`, `failing_checks` |

### 4.4 Analytics & Dashboard

- Deliver 15 SQL analytical reports covering all user stories — saved in `analytics/reports/`
- Deliver Streamlit executive dashboard with 4 pages:
  - **Revenue page** — total revenue, MoM trend, YTD vs prior year, revenue by country
  - **Customer page** — top 10 CLV, churn risk list, new vs returning, gender/age breakdown
  - **Product page** — margin % by product line, revenue by category, product ranking
  - **DQ Health page** — pipeline pass rate, test counts, last run timestamp, failed test names

### 4.5 Engineering & DevOps

- All Silver and Gold transformations built as dbt models with `schema.yml` tests
- CI/CD via GitHub Actions: run `dbt compile` + `dbt test` on every PR to `main`
- Full version control on GitHub with structured branching: `main`, `dev`, `feature/*`
- All naming follows `docs/naming_conventions.md` v2.0

---

## 5. Analytical Use Cases

All 15 user stories derived from the three confirmed personas. References to removed KPIs (refund, sales rep) replaced with use cases enabled by actual data.

| # | Persona | User Story | Metric / Output | Priority |
|---|---|---|---|---|
| 1 | Sarah | "I want revenue by product this period so I can identify underperformers" | Revenue by product, ranked | Must Have |
| 2 | Sarah | "I want top 10 customers by CLV so I can prioritise retention" | CLV ranking with segment | Must Have |
| 3 | Sarah | "I want churn risk flags so I can follow up before customers leave" | 60-day amber, 90-day red flag | Must Have |
| 4 | Sarah | "I want product return rate by line so I can flag quality issues" | Return rate % by product line | Must Have |
| 5 | Sarah | "I want a dashboard ready Monday morning with no manual prep" | All KPIs in one view, no SQL | Must Have |
| 6 | Marcus | "I want gross margin % by product line over 12 months for the CFO pack" | Margin % trend by product line | Must Have |
| 7 | Marcus | "I want monthly revenue split by new vs returning customers" | Revenue cohort monthly trend | Should Have |
| 8 | Marcus | "I want revenue by customer age group to understand our demographic" | Revenue by Under 30 / 30–45 / 46–60 / 60+ | Should Have |
| 9 | Marcus | "I want to trace any dashboard figure back to source in 5 minutes" | dbt lineage + data catalog | Must Have |
| 10 | Marcus | "I want the CFO pack producible in under 30 minutes from the warehouse" | All KPIs queryable from Gold views | Must Have |
| 11 | Priya | "I want MoM revenue growth with rolling 3-month average" | MoM % + rolling 3M line | Must Have |
| 12 | Priya | "I want YTD revenue tracked against our annual plan" | YTD vs pro-rata target | Must Have |
| 13 | Priya | "I want a DQ health indicator so I know I can trust the numbers" | Green/amber/red DQ indicator | Must Have |
| 14 | Priya | "I want revenue by country so I can see our geographic performance" | Revenue by country ranking | Should Have |
| 15 | Priya | "I want the pipeline reproducible by anyone on the team" | README setup time < 60 min | Should Have |

---

## 6. Non-Functional Requirements

| Category | Requirement | Acceptance Criterion |
|---|---|---|
| Performance | Dashboard queries return in < 5 seconds | 95th percentile < 5s on Gold views |
| Data Quality | GE critical tests pass before Gold refreshes | 100% critical test pass rate required |
| Idempotency | Pipeline reruns produce identical Gold output | Rerun on same source = identical result |
| Scalability | Architecture supports adding new source files | New source added without layer redesign |
| Auditability | Every load logged to `bronze.load_log` | One log row per table per run |
| Reproducibility | Full setup from README in < 60 minutes | Cold setup confirmed < 60 min |
| SCD Correctness | Historical changes preserved in dims | Customer update → 2 rows: old closed, new active |
| DQ Transparency | DQ pass rate visible on dashboard | `vw_dq_summary` surfaced on DQ Health page |

---

## 7. KPI Definitions

All KPIs validated against actual source data. See `docs/kpi_definitions.md` v2.0 for full formulas, source tables, owners, and business rules.

| # | KPI | Source | Owner | Refresh | Target |
|---|---|---|---|---|---|
| 1 | Total Revenue | `fact_sales` | Priya | Daily | Per plan |
| 2 | Average Order Value | `fact_sales` | Marcus | Daily | Track trend |
| 3 | Gross Margin % | `fact_sales + dim_product` | Marcus | Daily | > 35% |
| 4 | MoM Revenue Growth | `vw_kpi_revenue` | Priya | Monthly | > 5% |
| 5 | YTD Revenue | `fact_sales + dim_date` | Priya | Daily | Within 5% of pro-rata target |
| 6 | Customer CLV | `fact_sales + dim_customer` | Sarah | Monthly | Top 20% = 60% of total CLV |
| 7 | Customer Churn Rate | `dim_customer + fact_sales` | Sarah | Weekly | < 3% monthly |
| 8 | Product Return Rate | `fact_sales + dim_product` | Sarah | Daily | < 5% overall |
| 9 | Revenue by Country | `fact_sales + dim_location` | Priya | Daily | Track by country |
| 10 | Revenue by Product Line | `fact_sales + dim_product` | Sarah | Daily | Track by line |
| 11 | Customer Age Group Revenue | `fact_sales + dim_customer` | Marcus | Monthly | Track trend |
| 12 | DQ Pass Rate | `silver.dq_run_log` | Devanshi | Per run | ≥ 98% overall / 100% critical |

**Removed from v1.0:**
- Refund Impact on Net Revenue — `refund_amount` column does not exist in source data
- Sales Rep vs Quota — `sales_rep_id` column does not exist in source data

**Business Rules:**

| Rule | Definition |
|---|---|
| Valid sale | `sls_sales > 0 AND sls_quantity > 0` |
| Invalid sale | `sls_sales <= 0` — excluded from all revenue KPIs |
| Active customer | At least 1 valid sale in last 12 months |
| New customer | First order date falls within the reporting period |
| Churned customer | Active customer with no order in 90+ days and 2+ historical orders |
| Churn risk (amber) | Active customer with no order in 60–89 days |
| Current product | `prd_end_dt IS NULL` — latest active version |
| Date format | Source dates are YYYYMMDD integers — cast to DATE in Silver |
| Country standard | US/USA → `United States`, DE → `Germany`, whitespace/NULL → `N/A` |
| Gender standard | M/Male → `Male`, F/Female → `Female`, all else → `N/A` |
| Product line | R → `Road`, M → `Mountain`, T → `Touring`, S → `Standard`, NULL → `N/A` |

---

## 8. Project Scope

### 8.1 In Scope

- All 6 confirmed source CSV files from `crm_src/` and `ERP_src/` folders
- Bronze layer: 6 staging tables + `load_log` audit table + ydata-profiling reports
- Silver layer: 6 dbt staging models with full cleansing and CID key reconciliation
- Great Expectations automated DQ suites — 8+ expectations per Silver table
- Gold layer: `fact_sales` + 4 dimensions (2 × SCD Type 2) + 4 KPI views
- 15 SQL analytical reports covering all user stories
- Streamlit dashboard — 4 pages: Revenue, Customer, Product, DQ Health
- GitHub Actions CI/CD pipeline — dbt compile + test on every PR to `main`
- Full documentation: BRD v2.0, naming conventions v2.0, KPI definitions v2.0, data catalog v2.0, user stories, personas (3), sprint reviews, retrospectives, diagrams (8)

### 8.2 Out of Scope

- Real-time or streaming data ingestion (batch CSV only)
- Machine learning or predictive modelling
- Refund tracking — `refund_amount` column does not exist in any source file
- Sales rep quota tracking — `sales_rep_id` column does not exist in any source file
- Integration with live CRM or ERP APIs
- Role-based access control or enterprise data governance tooling
- Data archiving or retention policy enforcement

### 8.3 Assumptions & Dependencies

| Type | Detail |
|---|---|
| Assumption | 6 CSV files are the final confirmed dataset — no additional source files expected |
| Assumption | `crm_cust_info.cst_key` joins `erp_cust_az12.CID` (after stripping `NAS`) and `erp_loc_a101.CID` (after removing hyphens) |
| Assumption | `crm_prd_info` product versioning uses `prd_end_dt IS NULL` to identify current version |
| Assumption | `crm_sales_details` dates stored as YYYYMMDD integers are valid and castable to DATE (with exceptions handled) |
| Assumption | SQL Server Express free tier is sufficient for portfolio workloads |
| Dependency | SQL Server + SSMS installed locally |
| Dependency | Python 3.9+ with `ydata-profiling`, `great-expectations`, `pandas`, `pyodbc` |
| Dependency | dbt Core with `dbt-sqlserver` adapter installed |
| Dependency | GitHub account with Actions enabled (free tier sufficient) |
| Constraint | Portfolio project — production SLAs and enterprise security not required |

---

## 9. Success Metrics & Acceptance Criteria

| # | Success Area | Acceptance Criterion | Measure | Target |
|---|---|---|---|---|
| 1 | Data completeness | All 6 source file row counts match after Bronze load | Row count check in `08_bronze_verify.sql` | 100% match |
| 2 | Data quality | GE suite runs and logs results per pipeline run | DQ pass rate from `dq_run_log` | ≥ 98% overall |
| 3 | CID reconciliation | CRM and ERP customer records joined via cleaned customer key | Join rate check in Bronze verify script | ≥ 95% |
| 4 | Model accuracy | Gold KPI views match manually validated sample calculations | Spot check variance | < 0.1% |
| 5 | SCD correctness | Customer attribute change creates 2 rows — old closed, new active | Before/after test on known customer | Pass |
| 6 | Dashboard usability | All 15 user stories answerable without writing SQL | User walkthrough against story list | 15 / 15 |
| 7 | Pipeline reliability | Rerun on same source produces identical Gold output | Idempotency test | Pass |
| 8 | Documentation | New contributor can set up and run pipeline from README alone | Cold setup time | < 60 min |
| 9 | CI/CD | dbt tests run automatically on every PR to main | GitHub Actions status | All green |

---

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Score | Mitigation | Contingency |
|---|---|---|---|---|---|
| CID reconciliation join rate is low (< 95%) | Medium | High | 🔴 6 | Test join in Bronze verify script. Strip NAS + hyphens carefully. Document unmatched rows. | Proceed with unmatched customers flagged as `crm_only` — note gap on dashboard |
| Integer date casting fails for edge cases | Low | High | 🔴 6 | Use `NULLIF(sls_order_dt, 0)` and validate length = 8 before casting. GE expectation on valid date range. | Exclude rows with invalid dates — log count in DQ summary |
| GEN standardisation misses edge cases | Medium | Low | 🟢 2 | Enumerate all 9 raw formats in Bronze verify script. CASE WHEN for each. Default to N/A. | Acceptable — N/A is a valid business value |
| SCD Type 2 using source prd_start/end_dt is complex | Medium | High | 🔴 6 | Test with known product key that has multiple versions. Validate: current version = `prd_end_dt IS NULL`. | Fall back to SCD Type 1 (overwrite) and document — still demonstrates the pattern |
| dbt learning curve delays Silver sprint | Medium | Medium | 🟡 4 | 30-minute spike at Sprint 2 start before committing stories. Use official dbt-sqlserver quickstart. | Write plain SQL Silver scripts first, convert to dbt as enhancement |
| Dashboard complexity underestimated | Low | Medium | 🟡 4 | Build MVP first — `st.metric()` cards only. Confirm all 15 stories answerable. Polish after. | Ship Revenue + Customer pages as core. Defer Product and DQ pages to post-launch |
| Solo project — key person risk | Low | High | 🟢 3 | Daily commits to GitHub. Full documentation means context can be recovered after any break. | Resume from backlog. Sprint retrospective notes contextualise where each sprint ended. |
| Scope creep from stakeholder feedback | Medium | Medium | 🟡 4 | All requests go through `docs/change_log.md` process. Assess impact before accepting. | Accept into backlog with priority. Displace only if it's genuinely higher value than a Must Have. |

### 10.1 Issues Already Materialised (from Bronze profiling)

| Issue | Finding | Resolution |
|---|---|---|
| R01-C | Integer dates in `crm_sales_details` (e.g. `20101229`) | Cast to DATE in Silver — `CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)` |
| R01-D | `erp_cust_az12.CID` has `NAS` prefix — `NASAW00011000` | Strip in Silver — `SUBSTRING(CID, 4, LEN(CID))` |
| R01-E | `erp_cust_az12.GEN` has 9 different formats including spaces and mixed case | Standardise via CASE WHEN in Silver |
| R01-F | `erp_loc_a101.CNTRY` has 13 inconsistent country names including `US`, `USA`, `United States` | Standardise via CASE WHEN in Silver |

---

## 11. Project Timeline

| # | Phase | Duration | Key Deliverables |
|---|---|---|---|
| 1 | Discovery & Planning | Week 1 | BRD v2.0, all 15 PO docs, 8 diagrams, GitHub repo setup, backlog with 15 user stories |
| 2 | Bronze Layer | Week 1–2 | 6 source tables loaded, `load_log`, ydata-profiling HTML reports, 13 DQ issues documented |
| 3 | Silver + dbt + GE | Week 2–3 | 6 dbt models, CID reconciliation, GE suites (8+ expectations per table), `dq_run_log` |
| 4 | Gold + SCD Type 2 | Week 3–4 | Star schema, `dim_customer` + `dim_product` SCD Type 2, `fact_sales`, 4 KPI views |
| 5 | Analytics + Dashboard | Week 4–5 | 15 SQL analytical reports, Streamlit 4-page dashboard |
| 6 | CI/CD + Launch | Week 5–6 | GitHub Actions, polished README with Mermaid ERD + badges, LinkedIn post |

---

## 12. Document Sign-Off

This document v2.0 supersedes BRD v1.0. All changes from v1.0 are documented in `docs/change_log.md` under CR-006. The source dataset structure has been confirmed from Bronze layer profiling.

| Name | Role | Signature | Date |
|---|---|---|---|
| Devanshi | Product Owner + Data Engineer | ✅ Approved | April 2026 |
| Sarah Chen *(simulated)* | Sales Manager — Primary User | ✅ All stories confirmed | April 2026 |
| Marcus Obi *(simulated)* | Finance Analyst — Primary User | ✅ KPIs and auditability confirmed | April 2026 |
| Priya Sharma *(simulated)* | CFO — Executive Sponsor | ✅ Governance standards met | April 2026 |

---

## Appendix A — Data Quality Issues Found in Bronze

Full list of all 13 issues found during Bronze profiling — all resolved in Silver layer:

| # | Table | Issue | Rows | Silver Fix |
|---|---|---|---|---|
| 1 | `crm_cust_info` | 9 duplicate `cst_id` rows | 9 | ROW_NUMBER() dedup — keep most recent by `cst_create_date` |
| 2 | `crm_cust_info` | Leading/trailing spaces in `cst_firstname`, `cst_lastname` | Many | `LTRIM(RTRIM())` |
| 3 | `crm_cust_info` | NULL `cst_gndr` — 24.7% of rows | 4,578 | Default to `'N/A'` |
| 4 | `crm_cust_info` | `cst_gndr` abbreviated (`'M'`, `'F'`) | All non-null | Expand to `'Male'` / `'Female'` |
| 5 | `crm_cust_info` | `cst_marital_status` abbreviated (`'M'`, `'S'`) | All non-null | Expand to `'Married'` / `'Single'` |
| 6 | `crm_prd_info` | 102 duplicate `prd_key` (product versioning) | 102 | Filter `WHERE prd_end_dt IS NULL` for current version |
| 7 | `crm_prd_info` | Trailing spaces in `prd_line` (`'R '`, `'S '`, `'M '`, `'T '`) | All | `LTRIM(RTRIM())` then expand to full word |
| 8 | `crm_prd_info` | 2 NULL `prd_cost` | 2 | Default to 0 + flag `is_cost_missing = 1` |
| 9 | `crm_sales_details` | Dates stored as 8-digit integers (e.g. `20101229`) | 60,398 | `CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)` |
| 10 | `crm_sales_details` | NULL or negative/zero `sls_sales` (8 NULL, 5 negative) | 13 | Exclude from revenue KPIs |
| 11 | `erp_cust_az12` | `CID` has `NAS` prefix (`'NASAW00011000'`) | 18,483 | `SUBSTRING(CID, 4, LEN(CID))` |
| 12 | `erp_cust_az12` | `GEN` has 9 different formats | Many | CASE WHEN standardisation → `Male/Female/N/A` |
| 13 | `erp_loc_a101` | `CID` has hyphens (`'AW-00011000'`) | 18,484 | `REPLACE(CID, '-', '')` |
| 14 | `erp_loc_a101` | 332 NULL `CNTRY` + 13 inconsistent country name formats | 332+ | Standardise + NULL → `'N/A'` |

---

## Appendix B — Document Version History

| Version | Date | Summary of Changes | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial BRD — written before source data was profiled. Assumed dataset structure (erp_orders, crm_customers etc.) | Devanshi |
| 2.0 | April 2026 | Updated after Bronze layer profiling confirmed actual dataset structure. Source tables corrected. KPIs 10 and 11 from v1.0 removed (refund, sales rep). Two new KPIs added (revenue by country, age group revenue). 14 DQ issues documented. Scope updated. CR-006 logged. | Devanshi |

---

*Enterprise Sales Intelligence Platform · github.com/Devanshi-20/enterprise-sales-intelligence · Toronto, Canada*

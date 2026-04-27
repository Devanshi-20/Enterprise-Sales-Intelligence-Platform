# Data Catalog — Bronze Layer (Updated v2.0)

**Updated:** April 2026 — reflects actual source dataset structure after profiling  
**Change from v1.0:** All 6 Bronze tables rewritten to match real CSV files

---

## Source System Mapping

```
CRM source (crm_src/)               ERP source (ERP_src/)
├── cust_info.csv      →  bronze.crm_cust_info
├── prd_info.csv       →  bronze.crm_prd_info          ├── CUST_AZ12.csv   →  bronze.erp_cust_az12
└── sales_details.csv  →  bronze.crm_sales_details      ├── LOC_A101.csv    →  bronze.erp_loc_a101
                                                         └── PX_CAT_G1V2.csv →  bronze.erp_px_cat
```

---

## bronze.crm_cust_info

**Source file:** `crm_src/cust_info.csv`
**Grain:** One row per customer record
**Row count:** 18,493
**Load type:** Full reload (TRUNCATE + BULK INSERT)

| Column | Data Type | Nullable | Description | Issues Found |
|---|---|---|---|---|
| `cst_id` | INT | Yes | Customer ID — numeric | 9 duplicates found — deduplicate in Silver |
| `cst_key` | VARCHAR(50) | No | Business key e.g. `AW00011000` | Used to join ERP tables after stripping prefixes |
| `cst_firstname` | VARCHAR(100) | Yes | First name | Leading/trailing spaces — TRIM in Silver. 8 NULLs. |
| `cst_lastname` | VARCHAR(100) | Yes | Last name | Leading/trailing spaces — TRIM in Silver. 7 NULLs. |
| `cst_marital_status` | VARCHAR(5) | Yes | `M` = Married, `S` = Single | 7 NULLs. Expand to full word in Silver. |
| `cst_gndr` | VARCHAR(5) | Yes | `M` = Male, `F` = Female | 4,578 NULLs (24.7%). Expand to full word in Silver. |
| `cst_create_date` | DATE | Yes | Date customer was created in CRM | 4 NULLs |
| `dwh_load_timestamp` | DATETIME | No | Added by load script — not in source | |

**Data quality issues logged:**
- 9 duplicate `cst_id` rows — keep most recent by `cst_create_date` in Silver
- 4,578 NULL gender (24.7%) — default to `'N/A'` in Silver
- Leading/trailing spaces on names — `LTRIM(RTRIM())` in Silver

---

## bronze.crm_prd_info

**Source file:** `crm_src/prd_info.csv`
**Grain:** One row per product version (product may have multiple rows over time)
**Row count:** 397
**Load type:** Full reload

| Column | Data Type | Nullable | Description | Issues Found |
|---|---|---|---|---|
| `prd_id` | INT | No | Product ID | |
| `prd_key` | VARCHAR(50) | No | Product key e.g. `CO-RF-FR-R92B-58` | 102 duplicate keys — same product, multiple versions. Handle as SCD in Silver. |
| `prd_nm` | VARCHAR(255) | No | Product name | |
| `prd_cost` | DECIMAL(10,2) | Yes | Cost price | 2 NULLs — default to 0 and flag `is_cost_missing = 1` in Silver |
| `prd_line` | VARCHAR(10) | Yes | Product line code | Trailing spaces: `'R '`, `'S '`, `'M '`, `'T '`. 17 NULLs. TRIM in Silver. R=Road, S=Standard/Accessories, M=Mountain, T=Touring |
| `prd_start_dt` | DATE | No | When this product version became active | Used with `prd_end_dt` to determine current version |
| `prd_end_dt` | DATE | Yes | When this version ended | 197 NULLs = currently active version |
| `dwh_load_timestamp` | DATETIME | No | Added by load script | |

**Data quality issues logged:**
- 102 duplicate `prd_key` — this is by design (product versioning over time). Silver will pick the current version using `prd_end_dt IS NULL`. This creates the SCD-like pattern for `dim_product`.
- Trailing spaces in `prd_line` — use `LTRIM(RTRIM(prd_line))` in Silver

---

## bronze.crm_sales_details

**Source file:** `crm_src/sales_details.csv`
**Grain:** One row per order line
**Row count:** 60,398
**Load type:** Full reload

| Column | Data Type | Nullable | Description | Issues Found |
|---|---|---|---|---|
| `sls_ord_num` | VARCHAR(20) | No | Order number e.g. `SO43697` | |
| `sls_prd_key` | VARCHAR(50) | No | Product key — links to `crm_prd_info.prd_key` | |
| `sls_cust_id` | INT | No | Customer ID — links to `crm_cust_info.cst_id` | |
| `sls_order_dt` | INT | No | Order date stored as **integer YYYYMMDD** e.g. `20101229` | Must CAST to DATE in Silver: `CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)` |
| `sls_ship_dt` | INT | No | Ship date as integer YYYYMMDD | Same casting required |
| `sls_due_dt` | INT | No | Due date as integer YYYYMMDD | Same casting required |
| `sls_sales` | DECIMAL(10,2) | Yes | Total sales amount | 8 NULLs, 5 zero/negative values — exclude from KPIs |
| `sls_quantity` | INT | No | Quantity ordered | |
| `sls_price` | DECIMAL(10,2) | Yes | Unit price | 7 NULLs |
| `dwh_load_timestamp` | DATETIME | No | Added by load script | |

**Data quality issues logged:**
- Dates stored as 8-digit integers — requires explicit casting in Silver
- 8 NULL `sls_sales`, 5 negative/zero values — flag and exclude from revenue calculations
- Derive `sls_sales` from `sls_quantity * sls_price` where NULL

---

## bronze.erp_cust_az12

**Source file:** `ERP_src/CUST_AZ12.csv`
**Grain:** One row per customer demographic record
**Row count:** 18,483
**Load type:** Full reload

| Column | Data Type | Nullable | Description | Issues Found |
|---|---|---|---|---|
| `CID` | VARCHAR(50) | No | Customer ID with `NAS` prefix e.g. `NASAW00011000` | Strip `NAS` prefix in Silver: `SUBSTRING(CID, 4, LEN(CID))` → gives `AW00011000` to join CRM |
| `BDATE` | DATE | No | Customer birth date | Used to calculate age group |
| `GEN` | VARCHAR(20) | Yes | Gender — 9 different formats in source | 1,472 NULLs + messy values. Standardise in Silver: `Male/M/M (space)/F space` → `'Male'` etc. |
| `dwh_load_timestamp` | DATETIME | No | Added by load script | |

**GEN value standardisation (Silver):**

| Raw value | Standardised |
|---|---|
| `Male`, `M`, `M ` | `Male` |
| `Female`, `F`, `F ` | `Female` |
| NULL, `  `, ` ` | `N/A` |

---

## bronze.erp_loc_a101

**Source file:** `ERP_src/LOC_A101.csv`
**Grain:** One row per customer location
**Row count:** 18,484
**Load type:** Full reload

| Column | Data Type | Nullable | Description | Issues Found |
|---|---|---|---|---|
| `CID` | VARCHAR(50) | No | Customer ID with hyphens e.g. `AW-00011000` | Strip hyphens in Silver: `REPLACE(CID, '-', '')` → `AW00011000` to join CRM |
| `CNTRY` | VARCHAR(100) | Yes | Country name — 13 different formats | 332 NULLs + whitespace + inconsistent names |
| `dwh_load_timestamp` | DATETIME | No | Added by load script | |

**CNTRY standardisation (Silver):**

| Raw value(s) | Standardised |
|---|---|
| `US`, `USA`, `United States` | `United States` |
| `DE`, `Germany` | `Germany` |
| `  `, ` `, `   `, NULL | `N/A` |
| `Australia`, `United Kingdom`, `France`, `Canada` | Keep as-is |

---

## bronze.erp_px_cat

**Source file:** `ERP_src/PX_CAT_G1V2.csv`
**Grain:** One row per product subcategory
**Row count:** 36
**Load type:** Full reload
**Quality:** ✅ Clean — no issues found

| Column | Data Type | Nullable | Description |
|---|---|---|---|
| `ID` | VARCHAR(20) | No | Category code e.g. `AC_BR`, `BI_MB` |
| `CAT` | VARCHAR(100) | No | Category name: `Accessories`, `Bikes`, `Clothing`, `Components` |
| `SUBCAT` | VARCHAR(100) | No | Subcategory e.g. `Bike Racks`, `Mountain Bikes` |
| `MAINTENANCE` | VARCHAR(5) | No | Whether product requires maintenance: `Yes` / `No` |
| `dwh_load_timestamp` | DATETIME | No | Added by load script |

---

## Key Join Logic (Bronze → Silver)

This is how the 6 tables connect. Silver uses these joins to build unified customer and product records.

```
crm_cust_info.cst_key         = SUBSTRING(erp_cust_az12.CID, 4, LEN(CID))
  'AW00011000'                = strip 'NAS' from 'NASAW00011000'

crm_cust_info.cst_key         = REPLACE(erp_loc_a101.CID, '-', '')
  'AW00011000'                = strip '-' from 'AW-00011000'

crm_sales_details.sls_prd_key = crm_prd_info.prd_key
  (direct match)

crm_prd_info.prd_key prefix   → erp_px_cat.ID
  'CO-RF-FR-R92B-58'         → prefix 'CO_RF' → category 'Components / Road Frames'
```

---

## Known Data Quality Issues

| # | Table | Issue | Rows Affected | Silver Fix |
|---|---|---|---|---|
| 1 | crm_cust_info | 9 duplicate `cst_id` rows | 9 | ROW_NUMBER() dedup — keep most recent |
| 2 | crm_cust_info | Leading/trailing spaces in names | Many | LTRIM(RTRIM()) |
| 3 | crm_cust_info | NULL `cst_gndr` (24.7%) | 4,578 | Default to `N/A` |
| 4 | crm_prd_info | 102 duplicate `prd_key` (versioned) | 102 | Filter WHERE prd_end_dt IS NULL for current |
| 5 | crm_prd_info | Trailing spaces in `prd_line` | All | LTRIM(RTRIM()) |
| 6 | crm_prd_info | 2 NULL `prd_cost` | 2 | Default to 0, flag `is_cost_missing = 1` |
| 7 | crm_sales_details | Dates as integers (YYYYMMDD) | 60,398 | CAST to DATE in Silver |
| 8 | crm_sales_details | NULL or negative `sls_sales` | 13 | Exclude from revenue KPIs |
| 9 | erp_cust_az12 | `CID` has `NAS` prefix | 18,483 | SUBSTRING(CID, 4, LEN(CID)) |
| 10 | erp_cust_az12 | `GEN` has 9 different formats | Many | CASE WHEN standardisation |
| 11 | erp_loc_a101 | `CID` has hyphens | 18,484 | REPLACE(CID, '-', '') |
| 12 | erp_loc_a101 | 332 NULL `CNTRY` | 332 | Default to `N/A` |
| 13 | erp_loc_a101 | Inconsistent country names | Many | CASE WHEN standardisation |

---

*Data Catalog v2.0 · Enterprise Sales Intelligence Platform · github.com/Devanshi-20*

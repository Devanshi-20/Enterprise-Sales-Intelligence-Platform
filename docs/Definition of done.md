# Definition of Done

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Status:** Approved — applies to all deliverables across all 6 phases

---

## Why This Document Exists

"Done" means different things to different people until someone writes it down.

This document defines exactly what must be true before any deliverable —
a table, a model, a test suite, a dashboard page, or a document —
can be moved to the **Done** column on the GitHub Projects board.

> **Rule:** If a checklist item is not ticked, the story is not done.
> "It mostly works" is not done. "I'll fix it later" is not done.

---

## Definition of Done by Deliverable Type

---

### 1. A Bronze Staging Table is Done When

- [ ] Table created in the correct schema (`bronze.[source]_[entity]`)
- [ ] All source columns present — column names match naming conventions doc
- [ ] Correct data types assigned (VARCHAR, INT, DECIMAL, DATE — no generic NVARCHAR(MAX) unless required)
- [ ] Row count after load matches source CSV file exactly
- [ ] Load logged in `bronze.load_log` with: source file name, row count, load timestamp, status (`SUCCESS` / `FAILED`)
- [ ] Script numbered and saved in `scripts/bronze/` following naming conventions
- [ ] Script runs clean with no errors from a fresh state (drop + recreate tested)
- [ ] Committed to GitHub with a meaningful commit message

**Not required for Bronze:**
- Data quality checks (that is Silver's job)
- Column transformations (Bronze is a raw mirror)

---

### 2. A Python Profiling Report is Done When

- [ ] `ydata-profiling` report generated for the table
- [ ] Report saved as HTML in `analytics/reports/profiling/`
- [ ] Key findings documented in a comment block at the top of the Python script:
  - Total row count
  - Null rate for each column
  - Any columns with > 5% nulls flagged
  - Any duplicate primary key values found
  - Any unexpected data type issues noted
- [ ] Findings fed back into the Silver layer plan — known issues logged

---

### 3. A Silver dbt Model is Done When

- [ ] Model file saved in `dbt/models/silver/` with correct `stg_` prefix
- [ ] Model runs without errors: `dbt run --select model_name`
- [ ] All columns renamed to match naming conventions
- [ ] Data types explicitly cast — no implicit conversions
- [ ] NULL handling applied — every column has a deliberate decision (keep NULL / replace / flag)
- [ ] Duplicate records removed using documented deduplication logic (ROW_NUMBER strategy)
- [ ] Description written for the model in `schema.yml`
- [ ] Description written for every column in `schema.yml`
- [ ] dbt tests written in `schema.yml`:
  - [ ] `not_null` on all primary keys and foreign keys
  - [ ] `unique` on all primary keys
  - [ ] `accepted_values` where applicable (e.g. order_status)
  - [ ] `relationships` test for foreign key integrity where applicable
- [ ] `dbt test --select model_name` runs with zero failures
- [ ] Row count before and after transformation logged in commit notes
- [ ] Committed to GitHub

---

### 4. A Great Expectations Suite is Done When

- [ ] GE datasource connected to the Silver table in SQL Server
- [ ] Expectation suite created and named `suite_[table_name]`
- [ ] Minimum expectations written:
  - [ ] `expect_column_values_to_not_be_null` on all PK and FK columns
  - [ ] `expect_column_values_to_be_unique` on primary key
  - [ ] `expect_column_values_to_be_between` on all numeric columns (price, quantity, amount)
  - [ ] `expect_column_values_to_be_in_set` on all status / category columns
  - [ ] `expect_table_row_count_to_be_between` — minimum expected rows
- [ ] Checkpoint created and runs successfully: `great_expectations checkpoint run checkpoint_name`
- [ ] GE results parsed and written to `silver.dq_run_log` table
- [ ] DQ pass rate visible in `vw_dq_summary` Gold view
- [ ] Suite saved in `data_quality/` folder and committed to GitHub

---

### 5. A Gold Dimension Table is Done When

- [ ] Table created in `gold` schema with correct `dim_` prefix
- [ ] Surrogate key column present (`[entity]_key`) — integer, identity/auto-increment
- [ ] Natural key from source system preserved as a separate column (`[entity]_id`)
- [ ] All descriptive attributes included from the Silver layer
- [ ] **If SCD Type 2:** `effective_date`, `expiry_date`, `is_current` columns present
- [ ] **If SCD Type 2:** Update logic tested — change a source record, rerun load, confirm 2 rows exist (old closed, new active)
- [ ] Row count validated against Silver source after load
- [ ] Foreign key constraints documented (even if not enforced in SQL Server Express)
- [ ] Dimension added to star schema DrawIO diagram
- [ ] Script saved in `scripts/gold/` and committed to GitHub

---

### 6. The Fact Table is Done When

- [ ] Table created in `gold` schema with `fact_` prefix
- [ ] Grain documented in a comment at the top of the script: `-- Grain: one row per order line item`
- [ ] All foreign keys present and pointing to correct dimension tables:
  - [ ] `customer_key` → `dim_customer`
  - [ ] `product_key` → `dim_product`
  - [ ] `date_key` → `dim_date`
  - [ ] `location_key` → `dim_location`
- [ ] All additive measures present: `order_qty`, `unit_price`, `order_amount`, `refund_amount`, `cogs`
- [ ] Referential integrity tested: every FK value in fact_sales exists in the corresponding dim table
- [ ] Row count matches Silver source after load
- [ ] Star schema diagram updated
- [ ] Script committed to GitHub

---

### 7. A KPI View is Done When

- [ ] View created in `gold` schema with `vw_kpi_` prefix
- [ ] Formula matches the definition in `kpi_definitions.md` exactly
- [ ] `NULLIF` used wherever division occurs (no division-by-zero errors)
- [ ] Output validated against a manually calculated sample — variance < 0.1%
- [ ] View is queryable from the dashboard without additional joins
- [ ] KPI definition doc updated with SQL reference if formula changed during build
- [ ] View committed to GitHub

---

### 8. A SQL Analytical Report is Done When

- [ ] Script saved in `analytics/reports/` with correct numbering and name
- [ ] Query answers the exact use case from the BRD (cross-referenced)
- [ ] Output columns named clearly — no unnamed calculated columns
- [ ] Query runs in under 5 seconds on the local SQL Server instance
- [ ] Results validated against at least one other source (spot check)
- [ ] Query handles NULLs gracefully — no unexpected NULL rows in output
- [ ] Script committed to GitHub

---

### 9. A Dashboard Page is Done When

- [ ] Page renders without errors in Streamlit / Power BI
- [ ] All KPIs on the page pull from Gold KPI views — no raw table queries in the dashboard
- [ ] Every KPI on the page has a label and a unit (e.g. "Total Revenue (CAD)")
- [ ] Date filter works correctly — changing the period updates all visuals
- [ ] The BRD use case for this page is fully answerable without writing SQL
- [ ] Page tested against the persona it serves:
  - Revenue page — Sarah and Priya can answer their BRD questions
  - Customer page — Sarah can identify CLV and churn risk
  - Product page — Sarah and Marcus can see margin and return rate
  - DQ page — Data quality pass rate and pipeline health visible
- [ ] Page title and navigation label match dashboard design
- [ ] Committed to GitHub

---

### 10. A Documentation File is Done When

- [ ] Saved in `/docs` with correct filename per naming conventions
- [ ] Follows the template structure for its document type
- [ ] All placeholder text replaced with real content
- [ ] Reviewed against the BRD to confirm alignment
- [ ] Spell-checked
- [ ] Committed to GitHub with commit message: `docs: add [filename]`

---

### 11. A GitHub Actions Workflow is Done When

- [ ] Workflow file saved in `.github/workflows/`
- [ ] Triggers on pull request to `main` branch
- [ ] Runs `dbt test` against all models
- [ ] Workflow status badge added to README
- [ ] PR to `main` is blocked if any dbt test fails
- [ ] Tested end-to-end: create a PR, verify workflow runs, verify it blocks on failure

---

## Sprint-Level Definition of Done

A sprint is only done when ALL of the following are true:

- [ ] Every committed story has met its individual DoD checklist
- [ ] All code changes are committed and pushed to GitHub
- [ ] GitHub Projects board updated — all shipped stories moved to Done
- [ ] Carried-forward stories documented with reason in sprint retrospective
- [ ] Sprint retrospective notes written and committed to `docs/sprint_retrospectives.md`
- [ ] README updated if any new major feature was shipped
- [ ] No known critical bugs or broken states left unresolved

---

## What is NOT in Scope for Done

These items are not required before marking a story done — they are tracked separately:

| Item | Where it is tracked |
|---|---|
| Performance optimisation of queries | Separate backlog story |
| Dashboard aesthetic polish | Separate backlog story |
| Data catalog entry for new tables | Separate `data_catalog.md` update task |
| Stakeholder demo / sign-off | Sprint review meeting note |

---

## Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial DoD covering all 11 deliverable types | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*

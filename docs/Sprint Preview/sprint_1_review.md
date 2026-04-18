# Sprint 1 Review

**Project:** Enterprise Sales Intelligence Platform
**Sprint:** 1 of 3
**Dates:** March 10 – March 21, 2026
**Facilitator:** Devanshi (Product Owner)
**Attendees (simulated):** Sarah Chen (Sales Manager), Marcus Obi (Finance Analyst)

---

## Sprint Goal

> Set up the project foundation and get raw data into SQL Server so
> the team has something to work with.

**Goal met:** ✅ Yes — foundation complete, Bronze ingestion 88% done

---

## What Was Committed vs What Shipped

| # | Story | Points | Committed | Shipped | Notes |
|---|---|---|---|---|---|
| 1 | GitHub repo + folder structure + README | 2 | ✅ | ✅ | Clean structure, README matches architecture |
| 2 | SQL Server database + 3 schemas | 2 | ✅ | ✅ | bronze, silver, gold schemas verified in SSMS |
| 3 | Naming conventions document | 1 | ✅ | ✅ | Covers tables, columns, files, stored procs |
| 4 | Architecture DrawIO diagram | 2 | ✅ | ✅ | Exported PNG embedded in README |
| 5 | BRD v1.0 — all 12 sections | 5 | ✅ | ✅ | Stakeholders, personas, KPIs, risk register |
| 6 | Load ERP CSVs into Bronze | 3 | ✅ | ✅ | 3 tables: erp_orders, erp_order_items, erp_products |
| 7 | Load CRM CSVs into Bronze | 3 | ✅ | ✅ | 2 tables: crm_customers, crm_contacts |
| 8 | Build load_log audit table | 2 | ✅ | ✅ | Logs source, row count, timestamp, status |
| 9 | Python data profiling report | 3 | ✅ | ⏩ | pandas-profiling deprecated — carrying to Sprint 2 |
| 10 | GitHub Projects backlog setup | 1 | ✅ | ✅ | 5 epics, 14 stories, MoSCoW priorities |

**Sprint velocity:** 21 / 24 points shipped — **87.5%**

---

## Demo Highlights

### Bronze Layer — Live in SQL Server

All 5 Bronze staging tables populated and queryable:

```sql
-- Verified row counts after load
SELECT 'erp_orders'      AS tbl, COUNT(*) AS rows FROM bronze.erp_orders
UNION ALL
SELECT 'erp_order_items',        COUNT(*) FROM bronze.erp_order_items
UNION ALL
SELECT 'erp_products',           COUNT(*) FROM bronze.erp_products
UNION ALL
SELECT 'crm_customers',          COUNT(*) FROM bronze.crm_customers
UNION ALL
SELECT 'crm_contacts',           COUNT(*) FROM bronze.crm_contacts;
```

Load log showing successful ingestion:

```sql
SELECT * FROM bronze.load_log ORDER BY load_timestamp DESC;
```

### BRD v1.0

All 12 sections complete. Highlighted in demo:
- 3 user personas (Sarah, Marcus, Priya) with acceptance criteria
- 12 KPI definitions with formulas and owners
- Risk register with 8 active risks
- Sign-off table ready for stakeholder approval

### GitHub Projects Board

Live backlog visible at: `github.com/Devanshi-20/enterprise-sales-intelligence/projects`
5 epics, 14 user stories, all prioritised with MoSCoW labels.

---

## Stakeholder Feedback

### Sarah Chen (Sales Manager)

> "The BRD personas look right — that is exactly my Monday morning problem.
> When can I see something in the dashboard?"

**Response:** Dashboard is Sprint 3. Sprint 2 cleans the data, Sprint 3 builds the views and the dashboard. You'll get a preview screenshot at the end of Sprint 2.

**Action logged:** No change to backlog needed.

---

### Marcus Obi (Finance Analyst)

> "I notice refund_amount is in erp_orders but not planned as a separate
> column in fact_sales. I need that broken out for Net Revenue calculations."

**Response:** Valid gap — this was not explicit in the original BRD fact table design.

**Action logged:** Change Request CR-001 raised — add refund_amount to fact_sales.
Added to Sprint 2 backlog as a sub-task under the Silver stg_erp_orders story.

---

## Carry-Forward Items

| Story | Reason | Sprint 2 plan |
|---|---|---|
| Python data profiling report (3 pts) | pandas-profiling deprecated — install failed. ydata-profiling is the replacement. | Add spike task for ydata-profiling install. Run profiling on all 5 Bronze tables. |

---

## Acceptance Criteria Sign-Off

| Story | Acceptance criteria met | Signed off by |
|---|---|---|
| GitHub repo + structure | All folders present, README readable | Devanshi ✅ |
| SQL Server schemas | bronze, silver, gold schemas exist | Devanshi ✅ |
| Naming conventions | All sections complete | Devanshi ✅ |
| Architecture diagram | PNG in README, DrawIO in /diagrams | Devanshi ✅ |
| BRD v1.0 | All 12 sections, personas, KPIs | Devanshi ✅ |
| ERP Bronze load | Row counts match CSV files | Devanshi ✅ |
| CRM Bronze load | Row counts match CSV files | Devanshi ✅ |
| load_log | Rows logged per table with status | Devanshi ✅ |
| GitHub Projects backlog | All epics and stories visible with priorities | Devanshi ✅ |

---

## Next Sprint Preview

**Sprint 2 goal:** Transform raw Bronze data into a clean, tested Silver layer
using dbt models, with automated Great Expectations checks.

**Key Sprint 2 stories:**
- Python profiling report (carried forward)
- dbt-sqlserver install + project init
- Silver dbt models: stg_erp_orders, stg_erp_products, stg_crm_customer
- Great Expectations suites for all Silver tables
- dq_run_log metrics table

---

*Sprint 1 Review · Enterprise Sales Intelligence Platform · March 21, 2026*

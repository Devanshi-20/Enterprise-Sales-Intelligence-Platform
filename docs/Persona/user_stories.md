# User Stories

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Total stories:** 17 across 3 personas and 5 epics

---

## How to Read This Document

Every user story follows the standard format:

> "As a **[persona]**, I want **[feature/capability]**, so that **[business outcome]**."

Each story includes:
- **Epic** — which business theme it belongs to
- **Priority** — MoSCoW (Must / Should / Could)
- **Story points** — effort estimate
- **Acceptance criteria** — the exact checklist that defines "done"

---

## Story Map by Persona

| Persona | Stories | Must Have | Should Have |
|---|---|---|---|
| Sarah Chen — Sales Manager | US-01 to US-06 | 4 | 2 |
| Marcus Obi — Finance Analyst | US-07 to US-12 | 4 | 2 |
| Priya Sharma — CFO | US-13 to US-17 | 4 | 1 |
| **Total** | **17** | **12** | **5** |

---

## Epic Index

| Epic | Description | Stories |
|---|---|---|
| Epic 1 — Data Infrastructure | Build the warehouse layers | (Technical — no user-facing stories) |
| Epic 2 — Sales Analytics | Sarah's KPIs and dashboard | US-01 to US-06 |
| Epic 3 — Finance Analytics | Marcus's reports and auditability | US-07 to US-12 |
| Epic 4 — Dashboard & Reporting | The front-end product | US-06, US-12 |
| Epic 5 — Governance & Exec Reporting | Priya's trust and control layer | US-13 to US-17 |
| Epic DQ — Data Quality | Pipeline health and reliability | US-09, US-15 |

---

## Sarah Chen — Regional Sales Manager

---

### US-01 — Monthly revenue vs target by product

**Persona:** Sarah Chen (Sales Manager)
**Epic:** Epic 2 — Sales Analytics
**Priority:** Must have
**Story points:** 3

> "As a Sales Manager, I want to see monthly revenue versus target by product,
> so that I can identify which product lines are underperforming before quarter end."

**Acceptance criteria:**
- [ ] Revenue grouped by product and month visible on the Revenue dashboard page
- [ ] Variance column shows difference between actual and target (CAD)
- [ ] MoM % change column included alongside actuals
- [ ] Date range filter changes all figures correctly
- [ ] Numbers match manually verified sample calculation (variance < 0.1%)

**SQL view:** `gold.vw_kpi_revenue`
**Source tables:** `gold.fact_sales`, `gold.dim_product`, `gold.dim_date`

---

### US-02 — Top 10 customers by lifetime value

**Persona:** Sarah Chen (Sales Manager)
**Epic:** Epic 2 — Sales Analytics
**Priority:** Must have
**Story points:** 3

> "As a Sales Manager, I want to see my top 10 customers ranked by lifetime value,
> so that I can prioritise retention efforts on the accounts that matter most."

**Acceptance criteria:**
- [ ] CLV calculated as avg order value × purchase frequency × customer lifespan
- [ ] Top 10 ranked and visible on Customer dashboard page without writing SQL
- [ ] Customer segment label shown alongside CLV score
- [ ] Customers with 2+ orders only — one-time buyers excluded from CLV ranking
- [ ] Filterable by customer segment

**SQL view:** `gold.vw_kpi_customer`
**Source tables:** `gold.fact_sales`, `gold.dim_customer`

---

### US-03 — Customer churn risk flag

**Persona:** Sarah Chen (Sales Manager)
**Epic:** Epic 2 — Sales Analytics
**Priority:** Must have
**Story points:** 2

> "As a Sales Manager, I want a churn risk flag on customers who have not ordered
> in 60+ days, so that I can proactively follow up before they leave."

**Acceptance criteria:**
- [ ] Amber flag: 60–89 days since last order
- [ ] Red flag: 90+ days since last order
- [ ] Only customers with 2+ historical orders flagged — new customers excluded
- [ ] Days since last order column visible alongside the churn flag
- [ ] Sortable by days since last order descending

**Business rule:** Customer churn = active customer with no order in 60+ days
**SQL view:** `gold.vw_kpi_customer`
**Source tables:** `gold.dim_customer`, `gold.fact_sales`

---

### US-04 — Sales rep performance vs quota

**Persona:** Sarah Chen (Sales Manager)
**Epic:** Epic 2 — Sales Analytics
**Priority:** Should have
**Story points:** 2

> "As a Sales Manager, I want to see each rep's YTD revenue versus their quota,
> so that I can coach underperforming reps before the quarter closes."

**Acceptance criteria:**
- [ ] Rep-level YTD revenue visible, grouped by sales_rep_id from fact_sales
- [ ] % to quota calculated and displayed per rep
- [ ] Alert colour applied if rep below 70% with fewer than 30 days left in quarter
- [ ] Filterable by time period and region

**SQL view:** `gold.vw_kpi_revenue`
**Source tables:** `gold.fact_sales`, `gold.dim_customer`

---

### US-05 — Product return rate by product line

**Persona:** Sarah Chen (Sales Manager)
**Epic:** Epic 2 — Sales Analytics
**Priority:** Must have
**Story points:** 2

> "As a Sales Manager, I want to see product return rate by product line,
> so that I can flag quality or fulfilment issues to the operations team."

**Acceptance criteria:**
- [ ] Return rate = returned_qty / order_qty × 100 per product
- [ ] Displayed by product and product category
- [ ] Alert shown if any product exceeds 15% return rate
- [ ] Filterable by product category and date range

**SQL view:** `gold.vw_kpi_product`
**Source tables:** `gold.fact_sales`, `gold.dim_product`

---

### US-06 — Dashboard ready every Monday with no manual work

**Persona:** Sarah Chen (Sales Manager)
**Epic:** Epic 4 — Dashboard
**Priority:** Must have
**Story points:** 5

> "As a Sales Manager, I want a dashboard that is ready every Monday morning
> with refreshed data, so that I can start my week with accurate KPIs without
> any manual work."

**Acceptance criteria:**
- [ ] All 8 BRD analytical use cases answerable without writing SQL
- [ ] Dashboard loads in under 5 seconds on local machine
- [ ] Revenue, Customer, Product, and DQ Health pages all present
- [ ] Date filter on every page works correctly
- [ ] No manual data export or spreadsheet step required

**Linked to:** US-01, US-02, US-03, US-04, US-05
**Deliverable:** `dashboard/app.py` (Streamlit 4-page dashboard)

---

## Marcus Obi — Finance Business Analyst

---

### US-07 — Gross margin % by product category

**Persona:** Marcus Obi (Finance Analyst)
**Epic:** Epic 3 — Finance Analytics
**Priority:** Must have
**Story points:** 3

> "As a Finance Analyst, I want gross margin percentage by product category
> over 12 months, so that I can report profitability trends to the CFO in the
> monthly pack."

**Acceptance criteria:**
- [ ] Margin % = (Net Revenue − COGS) / Net Revenue × 100
- [ ] Grouped by product category and calendar month
- [ ] 12-month rolling view visible on Product dashboard page
- [ ] Alert if any category drops below 20% margin threshold
- [ ] Formula matches kpi_definitions.md exactly

**SQL view:** `gold.vw_kpi_product`
**Source tables:** `gold.fact_sales`, `gold.dim_product`, `gold.dim_date`

---

### US-08 — Refund and return impact on net revenue

**Persona:** Marcus Obi (Finance Analyst)
**Epic:** Epic 3 — Finance Analytics
**Priority:** Must have
**Story points:** 3

> "As a Finance Analyst, I want to see how refunds and returns impact net revenue
> by product line, so that I can accurately account for them in the monthly
> CFO report."

**Acceptance criteria:**
- [ ] Net revenue = gross revenue − SUM(refund_amount) per product line
- [ ] Refund % of gross revenue displayed as a separate column
- [ ] Filterable by month and product category
- [ ] Alert if refund % of gross exceeds 3% in any single month
- [ ] Change Request CR-001 implemented — refund_amount separate column in fact_sales

**SQL view:** `gold.vw_kpi_product`
**Source tables:** `gold.fact_sales`, `gold.dim_product`, `gold.dim_date`

---

### US-09 — Trace any figure back to source in under 5 minutes

**Persona:** Marcus Obi (Finance Analyst)
**Epic:** Epic DQ — Data Quality
**Priority:** Must have
**Story points:** 2

> "As a Finance Analyst, I want to trace any dashboard figure back to its source
> data in under 5 minutes, so that I can defend every number to the CFO without
> hesitation."

**Acceptance criteria:**
- [ ] dbt lineage graph shows Bronze → Silver → Gold path for each KPI
- [ ] kpi_definitions.md maps each metric to its exact source table and formula
- [ ] data_catalog.md documents every column in fact_sales and all dim tables
- [ ] load_log table shows when data was last refreshed with row counts

**Deliverables:** `docs/kpi_definitions.md`, `docs/data_catalog.md`, dbt lineage screenshot

---

### US-10 — Monthly revenue cohort — new vs returning

**Persona:** Marcus Obi (Finance Analyst)
**Epic:** Epic 3 — Finance Analytics
**Priority:** Should have
**Story points:** 3

> "As a Finance Analyst, I want monthly revenue cohort analysis showing new vs
> returning customer revenue, so that I can report acquisition and retention
> performance separately."

**Acceptance criteria:**
- [ ] New customer defined as: first_order_date falls in the reporting month
- [ ] Revenue split by new vs returning shown month by month
- [ ] Trend line shows whether retention revenue is growing over time
- [ ] Definition matches kpi_definitions.md new customer business rule

**SQL view:** `gold.vw_kpi_customer`
**Source tables:** `gold.fact_sales`, `gold.dim_customer`, `gold.dim_date`

---

### US-11 — Customer acquisition cost by segment

**Persona:** Marcus Obi (Finance Analyst)
**Epic:** Epic 3 — Finance Analytics
**Priority:** Should have
**Story points:** 2

> "As a Finance Analyst, I want customer acquisition cost trend by segment,
> so that I can identify which segments are becoming more or less efficient
> to acquire."

**Acceptance criteria:**
- [ ] CAC proxy = total sales cost / new customers acquired per period
- [ ] Grouped by customer segment: Enterprise, SMB, Consumer, Government
- [ ] CAC:CLV ratio displayed alongside CAC for each segment
- [ ] Target: CAC:CLV ratio > 1:3 highlighted as healthy

**SQL view:** `gold.vw_kpi_customer`
**Source tables:** `gold.dim_customer`, `gold.fact_sales`

---

### US-12 — Produce CFO monthly pack in under 30 minutes

**Persona:** Marcus Obi (Finance Analyst)
**Epic:** Epic 4 — Dashboard
**Priority:** Must have
**Story points:** 5

> "As a Finance Analyst, I want the monthly CFO pack figures to be producible
> in under 30 minutes using warehouse data alone, so that I eliminate the
> manual spreadsheet process entirely."

**Acceptance criteria:**
- [ ] All KPIs in monthly pack queryable from Gold views without manual joins
- [ ] Historical data preserved via SCD Type 2 — any prior month re-queryable
- [ ] ERP and CRM data reconciled automatically — no manual VLOOKUP needed
- [ ] Numbers traceable to source in under 5 minutes (links to US-09)

**Linked to:** US-07, US-08, US-09, US-10
**Deliverable:** Gold KPI views + Streamlit dashboard

---

## Priya Sharma — CFO

---

### US-13 — Single agreed KPI definitions

**Persona:** Priya Sharma (CFO)
**Epic:** Epic 5 — Governance
**Priority:** Must have
**Story points:** 2

> "As a CFO, I want all KPIs to have a single, agreed-upon definition that is
> documented and accessible, so that there are no conflicting figures in board
> meetings."

**Acceptance criteria:**
- [ ] kpi_definitions.md published with formula, source table, and owner for all 12 KPIs
- [ ] Business rules table defines revenue, COGS, churn, and new customer consistently
- [ ] Dashboard KPI labels match kpi_definitions.md exactly — zero discrepancy
- [ ] Change log documents any definition change with a date and reason

**Deliverable:** `docs/kpi_definitions.md`

---

### US-14 — MoM revenue growth with rolling 3-month average

**Persona:** Priya Sharma (CFO)
**Epic:** Epic 5 — Governance
**Priority:** Must have
**Story points:** 3

> "As a CFO, I want month-over-month revenue growth with a rolling 3-month average,
> so that I can distinguish genuine momentum from one-month anomalies."

**Acceptance criteria:**
- [ ] MoM % = (this month − last month) / last month × 100
- [ ] Rolling 3-month average shown as a separate line on the Revenue page
- [ ] Alert triggered if two consecutive months show negative MoM growth
- [ ] Excludes the current (incomplete) month from trend calculations

**SQL view:** `gold.vw_kpi_revenue`
**Source tables:** `gold.fact_sales`, `gold.dim_date`

---

### US-15 — Data quality health indicator on dashboard

**Persona:** Priya Sharma (CFO)
**Epic:** Epic DQ — Data Quality
**Priority:** Must have
**Story points:** 2

> "As a CFO, I want a data quality health indicator on the dashboard,
> so that I know whether to trust the numbers before presenting them to the board."

**Acceptance criteria:**
- [ ] DQ Health page shows pass rate % from the most recent pipeline run
- [ ] Last pipeline run timestamp visible — data freshness always clear
- [ ] Green indicator if pass rate ≥ 98%
- [ ] Amber indicator if pass rate 90–97%
- [ ] Red indicator if pass rate < 90%
- [ ] Failed test names visible in detail view

**SQL view:** `gold.vw_dq_summary`
**Source tables:** `silver.dq_run_log`

---

### US-16 — YTD revenue vs annual plan

**Persona:** Priya Sharma (CFO)
**Epic:** Epic 5 — Governance
**Priority:** Must have
**Story points:** 2

> "As a CFO, I want YTD revenue tracked against the annual plan,
> so that I can assess whether the business is on track to hit its annual target
> at any point in the year."

**Acceptance criteria:**
- [ ] YTD cumulative revenue from Jan 1 to today visible on Revenue page
- [ ] Pro-rata target line shows expected progress at this point in the year
- [ ] Variance vs target shown in both CAD and percentage
- [ ] Alert if YTD is more than 5% below the pro-rata target

**SQL view:** `gold.vw_kpi_revenue`
**Source tables:** `gold.fact_sales`, `gold.dim_date`

---

### US-17 — Pipeline reproducible by any team member

**Persona:** Priya Sharma (CFO)
**Epic:** Epic 5 — Governance
**Priority:** Should have
**Story points:** 2

> "As a CFO, I want the data pipeline to be reproducible by anyone on the team,
> so that the business is not dependent on one person to produce accurate reporting."

**Acceptance criteria:**
- [ ] README setup guide allows a new person to reproduce the full pipeline in under 60 minutes
- [ ] GitHub Actions CI/CD runs dbt tests automatically on every PR to main
- [ ] All transformation logic in version-controlled SQL and dbt — nothing in spreadsheets
- [ ] naming_conventions.md, definition_of_done.md, and data_catalog.md all published

**Deliverables:** README, `.github/workflows/dbt_test.yml`, all `/docs` documentation

---

## Full Backlog Summary

| ID | Story title | Persona | Priority | Points | Epic | Status |
|---|---|---|---|---|---|---|
| US-01 | Monthly revenue vs target by product | Sarah | Must | 3 | 2 | To do |
| US-02 | Top 10 customers by CLV | Sarah | Must | 3 | 2 | To do |
| US-03 | Customer churn risk flag | Sarah | Must | 2 | 2 | To do |
| US-04 | Sales rep vs quota | Sarah | Should | 2 | 2 | To do |
| US-05 | Product return rate | Sarah | Must | 2 | 2 | To do |
| US-06 | Dashboard ready every Monday | Sarah | Must | 5 | 4 | To do |
| US-07 | Gross margin % by category | Marcus | Must | 3 | 3 | To do |
| US-08 | Refund impact on net revenue | Marcus | Must | 3 | 3 | To do |
| US-09 | Trace figures to source in 5 min | Marcus | Must | 2 | DQ | To do |
| US-10 | Revenue cohort new vs returning | Marcus | Should | 3 | 3 | To do |
| US-11 | CAC by customer segment | Marcus | Should | 2 | 3 | To do |
| US-12 | CFO pack in under 30 minutes | Marcus | Must | 5 | 4 | To do |
| US-13 | Single agreed KPI definitions | Priya | Must | 2 | 5 | Done ✅ |
| US-14 | MoM growth + rolling average | Priya | Must | 3 | 5 | To do |
| US-15 | DQ health indicator | Priya | Must | 2 | DQ | To do |
| US-16 | YTD vs annual plan | Priya | Must | 2 | 5 | To do |
| US-17 | Pipeline reproducible by anyone | Priya | Should | 2 | 5 | To do |
| | **Total** | | | **46 pts** | | |

---

## Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial 17 stories across all 3 personas | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*

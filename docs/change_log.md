# Change Log

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Status:** Living document — updated every time a requirement changes

---

## Purpose

Every requirement change, scope addition, or definition update that occurs
after the BRD was approved is recorded here. Nothing changes silently.

This document answers: *"Why does the project look different from the original BRD?"*

> **Rule:** No change to scope, KPI definitions, table structure, or
> acceptance criteria is valid until it appears in this log with a decision.
> "I'll just add it quickly" is not a process — it is scope creep.

---

## Change Request Process

1. **Identify** — someone requests a change during a sprint review,
   dashboard preview, or data model review
2. **Log** — create a new entry in this document immediately
3. **Assess** — estimate impact on current sprint, existing models, and timeline
4. **Decide** — Accept / Defer to later sprint / Reject with reason
5. **Act** — if accepted, add to backlog with priority and update BRD if needed
6. **Close** — update the Status field when the change is implemented

---

## Change Request Template

```
### CR-[number] — [Short title]

| Field | Detail |
|---|---|
| **Requested by** | [Name / Role] |
| **Date raised** | [Date] |
| **Sprint raised in** | [Sprint number] |
| **Description** | [What is being requested and why] |
| **Impact assessment** | [Effect on scope, existing models, timeline, story points] |
| **Decision** | Accepted / Deferred to Sprint N / Rejected |
| **Reason** | [Why this decision was made] |
| **Action** | [What was added to backlog, what was updated] |
| **Status** | Open / Implemented / Rejected |
| **Implemented in** | [Sprint number or date] |
```

---

## Change Requests

---

### CR-001 — Add refund_amount column to fact_sales

| Field | Detail |
|---|---|
| **Requested by** | Marcus Obi (Finance Analyst) |
| **Date raised** | March 28, 2026 |
| **Sprint raised in** | Sprint 2 |
| **Description** | During the Sprint 2 data model review, Marcus flagged that the original fact_sales design did not include a `refund_amount` column as a separate additive measure. Without it, Net Revenue and Refund Impact KPIs cannot be calculated accurately at the order-line level. |
| **Impact assessment** | Medium. Requires updating `stg_erp_orders` Silver model to carry refund_amount through, updating fact_sales DDL, and adding a new GE expectation (`expect_column_values_to_be_between` for refund_amount >= 0). Estimated 0.5 story points. Does not affect dim tables. |
| **Decision** | Accepted |
| **Reason** | refund_amount is essential for two Must Have KPIs (Net Revenue, Refund Impact). The omission was a gap in the original BRD fact table design, not a new scope addition. |
| **Action** | Added to Sprint 2 backlog as Task under Story 3 (stg_erp_orders). KPI definitions doc updated to reference refund_amount explicitly. |
| **Status** | Implemented |
| **Implemented in** | Sprint 2 |

---

### CR-002 — Add Canadian public holidays to dim_date

| Field | Detail |
|---|---|
| **Requested by** | Devanshi (self-identified during Sprint 3 Gold build) |
| **Date raised** | April 8, 2026 |
| **Sprint raised in** | Sprint 3 |
| **Description** | While building dim_date, identified an opportunity to include Canadian federal public holidays as a flag column (`is_holiday`, `holiday_name`). This enables business-day-adjusted reporting and makes the warehouse relevant to the Toronto-based project context. |
| **Impact assessment** | Low. Add two columns to dim_date DDL. Requires a lookup table of Canadian holidays 2020–2030. No impact on fact_sales or dim tables. Estimated 0.5 story points. |
| **Decision** | Accepted |
| **Reason** | Low effort, high contextual value. Shows business awareness of Canadian market. Aligns with Priya's need for accurate business-day reporting. |
| **Action** | Added to Sprint 3 dim_date story as a sub-task. data_catalog.md updated with `is_holiday` and `holiday_name` column descriptions. |
| **Status** | Implemented |
| **Implemented in** | Sprint 3 |

---

### CR-003 — Add DQ Health page to dashboard

| Field | Detail |
|---|---|
| **Requested by** | Devanshi (self-identified during Sprint 3 dashboard build) |
| **Date raised** | April 10, 2026 |
| **Sprint raised in** | Sprint 3 |
| **Description** | Original BRD specified 3 dashboard pages (Revenue, Customer, Product). Identified that a 4th page showing pipeline health and data quality pass rates would serve two purposes: (1) demonstrate the Great Expectations integration to recruiters, (2) give Marcus and Priya visibility into data reliability. |
| **Impact assessment** | Medium. Requires `vw_dq_summary` Gold view (already planned), one additional Streamlit page, and connecting it to the dq_run_log table. Estimated 1 story point. |
| **Decision** | Accepted |
| **Reason** | High portfolio value — DQ Health page is a unique differentiator. Directly serves Marcus's need for auditability. No impact on Must Have stories. |
| **Action** | Added to Sprint 3 dashboard story as a 4th page sub-task. BRD Section 4.4 updated to reflect 4-page dashboard. KPI #12 (DQ Pass Rate) already defined in kpi_definitions.md. |
| **Status** | Implemented |
| **Implemented in** | Sprint 3 |

---

### CR-004 — Defer data_catalog.md to post-launch

| Field | Detail |
|---|---|
| **Requested by** | Devanshi (sprint planning decision) |
| **Date raised** | April 14, 2026 |
| **Sprint raised in** | Sprint 3 |
| **Description** | data_catalog.md was scoped as a Sprint 3 Could Have deliverable. Due to SCD Type 2 complexity consuming more time than estimated, the full catalog could not be completed within the sprint. A partial catalog was prepared but not committed. |
| **Impact assessment** | Low. data_catalog.md is a Could Have item. All table structures are documented in the codebase. The catalog adds discoverability but is not required for the dashboard or analytics to function. |
| **Decision** | Deferred — complete within 1 week of project launch |
| **Reason** | Correct prioritisation decision. Must Have stories (fact_sales, SCD2 dims, dashboard) took precedence. Catalog was built in full after Sprint 3. |
| **Action** | Added as post-launch task. Completed and committed on April 17, 2026. |
| **Status** | Implemented |
| **Implemented in** | Post-Sprint 3 |

---

### CR-005 — Add is_cost_missing flag to dim_product

| Field | Detail |
|---|---|
| **Requested by** | Devanshi (identified during Bronze profiling) |
| **Date raised** | April 2, 2026 |
| **Sprint raised in** | Sprint 2 |
| **Description** | Bronze profiling revealed 8 products with NULL cost_price in the ERP source. Rather than silently defaulting to 0, a data quality flag `is_cost_missing` was added to Silver and carried through to dim_product. This allows the dashboard to surface a warning on gross margin figures for these products. |
| **Impact assessment** | Low. Add one column to stg_erp_products and dim_product DDL. No impact on fact_sales calculations (COGS already defaults to 0 for these products). |
| **Decision** | Accepted |
| **Reason** | Data governance best practice. Silently masking data quality issues would undermine Marcus's trust in margin figures. |
| **Action** | Added to Sprint 2 stg_erp_products story. dim_product DDL updated. data_catalog.md Known Issues table updated. |
| **Status** | Implemented |
| **Implemented in** | Sprint 2 |

---

## Change Summary

| CR # | Title | Requested by | Sprint | Decision | Status |
|---|---|---|---|---|---|
| CR-001 | Add refund_amount to fact_sales | Marcus (Finance) | Sprint 2 | Accepted | Implemented |
| CR-002 | Canadian holidays in dim_date | Devanshi | Sprint 3 | Accepted | Implemented |
| CR-003 | Add DQ Health dashboard page | Devanshi | Sprint 3 | Accepted | Implemented |
| CR-004 | Defer data_catalog.md to post-launch | Devanshi | Sprint 3 | Deferred | Implemented |
| CR-005 | Add is_cost_missing flag to dim_product | Devanshi | Sprint 2 | Accepted | Implemented |

---

## Change Log of This Document

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial log — 5 change requests across 3 sprints | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*

# Risk Register

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Status:** Living document — reviewed and updated at the start of every sprint

---

## How to Use This Document

Every risk is reviewed at sprint planning. When a risk materialises it moves
to the Issues Log at the bottom. New risks discovered during a sprint are
added immediately — not at the next planning session.

### Likelihood scale

| Score | Label | Meaning |
|---|---|---|
| 1 | Low | Unlikely to happen — would require unusual circumstances |
| 2 | Medium | Could happen — has happened on similar projects |
| 3 | High | Likely to happen — already showing early signs |

### Impact scale

| Score | Label | Meaning |
|---|---|---|
| 1 | Low | Minor inconvenience — no effect on delivery date or quality |
| 2 | Medium | Causes rework or delay of 1–3 days |
| 3 | High | Threatens sprint delivery or project quality |

### Risk score = Likelihood × Impact

| Score | Priority |
|---|---|
| 7–9 | 🔴 Critical — mitigation required immediately |
| 4–6 | 🟡 Medium — mitigation plan in place, monitor closely |
| 1–3 | 🟢 Low — accept and monitor |

---

## Active Risk Register

---

### R01 — Source data quality worse than expected

| Field | Detail |
|---|---|
| **Category** | Data |
| **Description** | ERP and CRM CSV files may contain more quality issues than initial review suggested — missing values, wrong data types, inconsistent formats, or referential integrity gaps between tables |
| **Likelihood** | 3 — High |
| **Impact** | 3 — High |
| **Risk Score** | 🔴 9 — Critical |
| **Owner** | Devanshi |
| **Mitigation** | Run ydata-profiling report on ALL Bronze tables before writing a single Silver model. Document every issue found. Build Silver models defensively — every field has explicit NULL handling and type casting. Great Expectations suite catches regressions. |
| **Contingency** | If a data quality issue cannot be resolved in Silver, document it in `data_catalog.md` under Known Issues and surface a DQ warning flag on the affected dashboard metric. Never silently hide bad data. |
| **Status** | Active — profiling scheduled for Sprint 2 |
| **Last reviewed** | April 2026 |

---

### R02 — dbt learning curve causes sprint delay

| Field | Detail |
|---|---|
| **Category** | Technical / Skills |
| **Description** | dbt-sqlserver is a new tool. Configuration issues, unfamiliar YAML syntax, or unexpected SQL Server compatibility problems could consume time budgeted for model building. |
| **Likelihood** | 2 — Medium |
| **Impact** | 2 — Medium |
| **Risk Score** | 🟡 4 — Medium |
| **Owner** | Devanshi |
| **Mitigation** | Allocate a 30-minute spike task at the start of Sprint 2 for dbt install and `dbt debug` before committing to model stories. Follow the official dbt-sqlserver quickstart. Limit Sprint 2 to dbt Core only — no dbt Cloud features. |
| **Contingency** | If dbt setup takes more than 2 hours, fall back to plain SQL scripts for Silver and add dbt as a Sprint 3 enhancement story. Portfolio value of plain SQL Silver is still strong. |
| **Status** | Active |
| **Last reviewed** | April 2026 |

---

### R03 — SCD Type 2 logic produces duplicate or incorrect records

| Field | Detail |
|---|---|
| **Category** | Data Modelling |
| **Description** | SCD Type 2 implementation on dim_customer and dim_product is complex. An error in the merge logic (wrong partition key, incorrect effective_date assignment) could produce duplicate current records or incorrect historical records that silently corrupt analytics. |
| **Likelihood** | 2 — Medium |
| **Impact** | 3 — High |
| **Risk Score** | 🔴 6 — Medium/Critical |
| **Owner** | Devanshi |
| **Mitigation** | Write explicit test cases before building: define a before/after scenario with known inputs and expected outputs. After each SCD load, run a validation query: `SELECT customer_id, COUNT(*) FROM dim_customer WHERE is_current = 1 GROUP BY customer_id HAVING COUNT(*) > 1` — zero rows expected. |
| **Contingency** | If SCD logic cannot be made reliable in the sprint timebox, implement SCD Type 1 (overwrite) first and document it. Ship a working warehouse over a broken historically-tracked one. Add SCD Type 2 as a separate story in the next sprint. |
| **Status** | Active — scheduled for Sprint 3 |
| **Last reviewed** | April 2026 |

---

### R04 — Dashboard complexity underestimated

| Field | Detail |
|---|---|
| **Category** | Delivery |
| **Description** | The 4-page Streamlit dashboard was estimated at 5 story points. If individual KPI visualisations are more complex than expected (e.g. the churn risk table requires custom formatting, the MoM trend chart requires date logic), the dashboard could run significantly over estimate. |
| **Likelihood** | 2 — Medium |
| **Impact** | 2 — Medium |
| **Risk Score** | 🟡 4 — Medium |
| **Owner** | Devanshi |
| **Mitigation** | Build an MVP dashboard first — plain Streamlit tables and st.metric() cards. Confirm all 8 BRD use cases are answerable. Then add chart visualisations as enhancement stories. A functional MVP dashboard is better than a half-built polished one. |
| **Contingency** | If time runs short, deliver Revenue page + Customer page as the core two pages. Defer Product and DQ pages to post-launch polish. |
| **Status** | Active — scheduled for Sprint 3 |
| **Last reviewed** | April 2026 |

---

### R05 — GitHub Actions CI/CD misconfiguration

| Field | Detail |
|---|---|
| **Category** | Technical |
| **Description** | The GitHub Actions workflow for dbt testing requires the pipeline to connect to a SQL Server instance. On a local/portfolio setup without a cloud-hosted SQL Server, the CI/CD run may fail because the runner cannot reach the database. |
| **Likelihood** | 2 — Medium |
| **Impact** | 1 — Low |
| **Risk Score** | 🟢 2 — Low |
| **Owner** | Devanshi |
| **Mitigation** | Use `dbt compile` (schema validation only, no database connection needed) in the CI/CD workflow as the primary check. This still validates model SQL and schema.yml tests without requiring a live database connection. Document the limitation in README. |
| **Contingency** | If `dbt compile` is insufficient for the portfolio, spin up a free Azure SQL or use SQLite with dbt-duckdb adapter for CI tests only. |
| **Status** | Active — scheduled for Sprint 3 |
| **Last reviewed** | April 2026 |

---

### R06 — ERP and CRM customer ID reconciliation fails

| Field | Detail |
|---|---|
| **Category** | Data |
| **Description** | The core integration challenge of this project is linking ERP customer_id to CRM crm_customer_id. If the linkage rate is very low (< 70%), key analytics like CLV by segment and acquisition source by revenue will be unreliable. |
| **Likelihood** | 2 — Medium |
| **Impact** | 3 — High |
| **Risk Score** | 🔴 6 — Medium/Critical |
| **Owner** | Devanshi |
| **Mitigation** | In Silver, attempt fuzzy matching on (email, full_name, city) as a secondary match strategy if direct ID match fails. Document the match rate in data_catalog.md. Surface the `crm_customer_id IS NULL` rate as a DQ metric on the dashboard. |
| **Contingency** | If reconciliation < 70%, proceed with unmatched customers flagged as a known gap. Mark CLV and segment metrics with a data completeness warning in the dashboard. This is realistic and demonstrates data governance maturity. |
| **Status** | Active — impacts Sprint 2 Silver work |
| **Last reviewed** | April 2026 |

---

### R07 — Key person dependency — solo project

| Field | Detail |
|---|---|
| **Category** | Resource |
| **Description** | This is a solo project. Any personal unavailability (illness, competing priorities, other commitments) has a direct 1:1 impact on delivery. There is no team to absorb the gap. |
| **Likelihood** | 1 — Low |
| **Impact** | 3 — High |
| **Risk Score** | 🟢 3 — Low |
| **Owner** | Devanshi |
| **Mitigation** | Keep all work committed to GitHub daily. Documentation is thorough enough that the project can be picked up after a break without losing context. Sprint goals are sized conservatively — 24–37 points — to allow for real-life interruptions. |
| **Contingency** | If a sprint must be skipped entirely, add a brief note to the sprint_retrospectives.md explaining the gap. Stakeholders are informed via the bi-weekly update. Resume from the backlog — prioritisation is always clear. |
| **Status** | Accepted — monitored passively |
| **Last reviewed** | April 2026 |

---

### R08 — Scope creep from stakeholder feedback

| Field | Detail |
|---|---|
| **Category** | Scope |
| **Description** | When Sarah or Marcus review dashboard previews, they may request new metrics, new pages, or changed definitions that were not in the original BRD. Each unmanaged addition delays delivery. |
| **Likelihood** | 2 — Medium |
| **Impact** | 2 — Medium |
| **Risk Score** | 🟡 4 — Medium |
| **Owner** | Devanshi |
| **Mitigation** | All new requests go through the change_log.md process — no unrecorded scope additions. Every request is assessed for impact on current sprint before acceptance. Stakeholders are reminded that Must Have BRD items come first. New ideas are welcomed into the backlog for future sprints. |
| **Contingency** | If a stakeholder request is high value and genuinely missed from the BRD, accept it as a Change Request, update the backlog, and adjust the sprint plan if it displaces a lower-priority story. |
| **Status** | Active — managed via change_log.md |
| **Last reviewed** | April 2026 |

---

## Risk Summary

| ID | Risk | Likelihood | Impact | Score | Priority | Status |
|---|---|---|---|---|---|---|
| R01 | Source data quality worse than expected | High | High | 9 | 🔴 Critical | Active |
| R02 | dbt learning curve causes sprint delay | Medium | Medium | 4 | 🟡 Medium | Active |
| R03 | SCD Type 2 produces incorrect records | Medium | High | 6 | 🔴 Medium/Critical | Active |
| R04 | Dashboard complexity underestimated | Medium | Medium | 4 | 🟡 Medium | Active |
| R05 | GitHub Actions CI/CD misconfiguration | Medium | Low | 2 | 🟢 Low | Active |
| R06 | ERP/CRM customer ID reconciliation fails | Medium | High | 6 | 🔴 Medium/Critical | Active |
| R07 | Key person dependency — solo project | Low | High | 3 | 🟢 Low | Accepted |
| R08 | Scope creep from stakeholder feedback | Medium | Medium | 4 | 🟡 Medium | Active |

---

## Issues Log (Materialised Risks)

Risks that have occurred are moved here with a resolution note.

| ID | Original Risk | Sprint | What happened | Resolution | Resolved date |
|---|---|---|---|---|---|
| R01-A | Data quality — specific instance | Sprint 2 | 4 rows in erp_orders had order_date in 2027 | Added `is_date_anomaly` flag in Silver. GE expectation added to catch future occurrences. Rows excluded from KPI calculations. | Sprint 2 |
| R01-B | Data quality — specific instance | Sprint 2 | 8 products with NULL cost_price | Defaulted to 0 in Silver, `is_cost_missing` flag added, surfaced in data catalog Known Issues. | Sprint 2 |
| R02-A | dbt learning curve | Sprint 2 | pandas-profiling deprecated — needed ydata-profiling | Updated requirements.txt, added tool spike task to Sprint 2 planning. | Sprint 2 |

---

## Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial register — 8 risks identified across data, technical, delivery, and resource categories | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*

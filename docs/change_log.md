## CR-006 — Source dataset structure differs from BRD assumptions

| Field | Detail |
|---|---|
| **Requested by** | Devanshi (discovered during Bronze layer build — April 2026) |
| **Date raised** | April 2026 |
| **Sprint raised in** | Sprint 2 |
| **Description** | After receiving and profiling the actual source datasets, the file structure and column availability differs significantly from what was assumed when writing the BRD and KPI definitions. The actual data contains 6 CSV files (3 CRM, 3 ERP) with different naming and column structure than assumed. Key missing columns: `refund_amount`, `sales_rep_id`, `order_status`, `region`, `city`, `province`. Key additional data available: customer birth date (BDATE), gender from ERP, country from ERP LOC file, product categories from ERP PX_CAT file. |
| **Impact assessment** | Medium. Requires updates to: kpi_definitions.md (remove 2 KPIs, add 2 new ones), data_catalog.md (full rewrite of Bronze tables section), BRD Sections 2 and 7 (source files and KPI table), user_stories.md (remove US-04 and US-08), naming_conventions.md (update table name examples). Does NOT affect: personas, sprint retrospectives, definition_of_done, stakeholder communication plan, diagrams. |
| **Decision** | Accepted — full updates applied |
| **Reason** | This is a realistic and common scenario in real projects — requirements are written before data is fully explored. The change is well-managed and documented. The sprint retrospective notes correctly reflect that data profiling revealed these gaps during build, which is exactly the right process. |
| **Action** | kpi_definitions.md → v2.0 published. data_catalog.md → updated with real table/column names and real DQ findings. BRD, user_stories, naming_conventions → minor updates applied. Change logged in risk_register.md Issues Log as R01-C through R01-F. |
| **Status** | Implemented |
| **Implemented in** | Sprint 2 |

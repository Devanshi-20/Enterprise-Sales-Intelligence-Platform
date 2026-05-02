
Business Requirements Document

**Project:** Enterprise Sales Intelligence Platform
**Version:** 1.1 | **Status:** Approved

## Objective
Consolidate ERP and CRM sales data into a governed, analytical data warehouse
that enables data-driven decisions across Sales and Finance teams.

## Key stakeholders
- Sales Manager â€” KPI visibility, territory performance
- Finance Analyst â€” Revenue reporting, margin analysis

## In scope
- Bronze/Silver/Gold Medallion Architecture in SQL Server
- dbt transformation models + Great Expectations DQ suite
- SCD Type 2 on Customer and Product dimensions
- Power BI / Streamlit executive dashboard
- CI/CD via GitHub Actions

## Success metrics
- All DQ critical tests passing > 98%
- Dashboard answers all 8 analytical use cases without SQL
- Full setup reproducible from README in under 60 minutes

> Full BRD:[BRD Enterprise Sales Intelligence Platform](docs/BRD_Enterprise_Sales_Intelligence_Platform_v1.1.docx)

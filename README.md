# Enterprise-Sales-Intelligence-Platform

**1 Discovery & planning**
Write BRD, create backlog, define personas, draw architecture in DrawIO. Week 1.

**2 Bronze layer + data profiling**
Ingest CSVs to SQL Server. Run pandas-profiling. Document source quality issues. Week 1–2.

**3 Silver layer + dbt + Great Expectations**
Build dbt models for cleansing. Write GE test suite. Log quality metrics. Week 2–3.

**4 Gold layer — star schema + SCD Type 2**
Fact & dim tables. Implement SCD Type 2 on customer & product dims. KPI views. Week 3–4.

**5 Analytics & dashboard**
SQL analytical reports. Power BI or Streamlit dashboard with 3–5 KPI pages. Week 4–5.

**6 CI/CD + documentation + LinkedIn post**
GitHub Actions for dbt tests. Polish README with Mermaid ERD. Write LinkedIn article. Week 5–6.

# Enterprise Sales Intelligence Platform

> End-to-end data warehouse & analytics solution | SQL Server · dbt · Great Expectations · Power BI

## What this project demonstrates

| Skill Area | What's built |
|---|---|
| Data Engineering | Medallion Architecture (Bronze → Silver → Gold) in SQL Server |
| ETL & Transformation | dbt models with lineage, tests, and auto-generated docs |
| Data Quality | Automated test suite via Great Expectations |
| Data Modelling | Star schema with SCD Type 2 historisation |
| Analytics | 8 SQL reports covering revenue, customers, and products |
| Product Ownership | BRD, user personas, backlog, KPI definitions |
| Dashboard | Interactive Power BI / Streamlit executive dashboard |
| DevOps | CI/CD pipeline via GitHub Actions |

## Architecture

> Architecture diagram here (add DrawIO export as PNG)

### Medallion layers
- **Bronze** — Raw ingestion from ERP & CRM CSV sources. Data preserved exactly as-is.
- **Silver** — Cleansed, standardised, and quality-checked. Automated DQ via Great Expectations.
- **Gold** — Star schema with SCD Type 2 dims. KPI views ready for reporting.

## Quick start

### Prerequisites
- SQL Server Express + SSMS
- Python 3.9+
- dbt Core (`pip install dbt-sqlserver`)

### Setup
```bash
git clone https://github.com/YOUR_USERNAME/enterprise-sales-intelligence.git
cd enterprise-sales-intelligence
```

1. Run `scripts/bronze/01_create_database.sql` in SSMS
2. Run `scripts/bronze/02_load_erp.sql` to ingest ERP data
3. Run `scripts/bronze/03_load_crm.sql` to ingest CRM data
4. Run `cd dbt && dbt run` to execute Silver and Gold models
5. Open `dashboard/` for the Power BI file or run `streamlit run dashboard/app.py`

## Project documents
- [Business Requirements Document](docs/BRD.md)
- [Data Catalog](docs/Data catalog.md)
- [KPI Definitions](docs/kpi_definitions.md)
- [Naming Conventions](docs/naming_conventions.md)

## Tech stack
`SQL Server` `dbt` `Great Expectations` `Python` `Power BI` `GitHub Actions` `DrawIO`

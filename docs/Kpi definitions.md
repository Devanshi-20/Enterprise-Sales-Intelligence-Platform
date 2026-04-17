# KPI Definitions

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Owner:** Product Owner + Finance (Priya Sharma)
**Status:** Approved — all metrics in the Gold layer and dashboard follow these definitions

---

## Why This Document Exists

A KPI is only useful if everyone agrees on what it means.

This document is the **single source of truth** for every metric surfaced in the
Gold layer, KPI views, and dashboard. If a number appears in the Streamlit
dashboard or a SQL report, its definition lives here — including the exact
formula, the source table, the business rule, who owns it, and how often it
refreshes.

> **Rule:** Never add a metric to the dashboard without first defining it here.
> If two people disagree on what a number means, this document resolves it.

---

## How to Read This Document

Each KPI entry contains:

| Field | Meaning |
|---|---|
| **Definition** | Plain English — what does this number represent? |
| **Formula** | Exact calculation used in SQL |
| **Source tables** | Which Gold layer tables or views feed this KPI |
| **Filters / business rules** | Any conditions applied before calculation |
| **Grain** | The level of detail — per day, per customer, per product |
| **Owner** | The business persona responsible for this metric |
| **Refresh frequency** | How often the number updates |
| **Target / benchmark** | What good looks like (where known) |
| **Related KPIs** | Other metrics this one connects to |

---

## KPI Catalogue

---

### 1. Total Revenue

| Field | Detail |
|---|---|
| **Definition** | Gross revenue from all completed and shipped orders in the period. Does not deduct refunds or returns. |
| **Formula** | `SUM(unit_price × quantity)` across all order lines |
| **SQL** | `SELECT SUM(unit_price * order_qty) FROM gold.fact_sales` |
| **Source tables** | `gold.fact_sales`, `gold.dim_date` |
| **Filters** | Exclude orders with `order_status = 'Cancelled'`. Include `Shipped` and `Delivered` only. |
| **Grain** | Configurable — daily, monthly, quarterly, yearly |
| **Owner** | Priya Sharma (CFO) |
| **Refresh** | Daily |
| **Target** | Defined per quarter in the sales plan |
| **Related KPIs** | Net Revenue, Gross Margin %, MoM Growth |

---

### 2. Net Revenue

| Field | Detail |
|---|---|
| **Definition** | Revenue after deducting refunds and returns. This is the number used in the CFO monthly pack — not Total Revenue. |
| **Formula** | `Total Revenue − SUM(refund_amount)` |
| **SQL** | `SELECT SUM(unit_price * order_qty) - SUM(refund_amount) FROM gold.fact_sales` |
| **Source tables** | `gold.fact_sales`, `gold.dim_date` |
| **Filters** | Same order status filter as Total Revenue. `refund_amount` is 0 for non-refunded lines. |
| **Grain** | Daily, monthly |
| **Owner** | Marcus Obi (Finance Analyst) |
| **Refresh** | Daily |
| **Target** | Net Revenue must be within 2% of Total Revenue in a healthy month |
| **Related KPIs** | Total Revenue, Refund Rate, Return Rate |

---

### 3. Gross Margin %

| Field | Detail |
|---|---|
| **Definition** | Profitability as a percentage of revenue. Measures how much of each revenue dollar remains after deducting the cost of goods sold (COGS). |
| **Formula** | `(Net Revenue − COGS) / Net Revenue × 100` |
| **SQL** | `SELECT (SUM(unit_price * order_qty - refund_amount) - SUM(cogs)) / NULLIF(SUM(unit_price * order_qty - refund_amount), 0) * 100 FROM gold.fact_sales` |
| **Source tables** | `gold.fact_sales`, `gold.dim_product`, `gold.dim_date` |
| **Filters** | Exclude cancelled orders. COGS sourced from `dim_product.cost_price`. |
| **Grain** | By product category, monthly |
| **Owner** | Marcus Obi (Finance Analyst) |
| **Refresh** | Daily |
| **Target** | > 35% overall. Alert if any category drops below 20%. |
| **Related KPIs** | Net Revenue, Return Rate, Product Performance |

---

### 4. Month-over-Month (MoM) Revenue Growth

| Field | Detail |
|---|---|
| **Definition** | Percentage change in Net Revenue compared to the previous calendar month. Shows revenue momentum — whether the business is growing or contracting month to month. |
| **Formula** | `(This Month Revenue − Last Month Revenue) / Last Month Revenue × 100` |
| **SQL** | Using `LAG()` window function over monthly revenue CTE |
| **Source tables** | `gold.vw_kpi_revenue` |
| **Filters** | Excludes the current (incomplete) month unless specifically requested |
| **Grain** | Monthly |
| **Owner** | Priya Sharma (CFO) |
| **Refresh** | Monthly (1st of each month) |
| **Target** | > 5% MoM growth. Alert if two consecutive months show negative growth. |
| **Related KPIs** | Total Revenue, YTD Revenue, Rolling 3M Average |

---

### 5. Year-to-Date (YTD) Revenue

| Field | Detail |
|---|---|
| **Definition** | Cumulative Net Revenue from January 1st of the current year to the most recent completed day. Used to track progress against the annual target. |
| **Formula** | `SUM(net_revenue) WHERE order_date >= '2026-01-01' AND order_date <= GETDATE()` |
| **SQL** | Filter `dim_date.calendar_year = YEAR(GETDATE())` and use running SUM |
| **Source tables** | `gold.fact_sales`, `gold.dim_date` |
| **Filters** | Current calendar year only. Completed orders only. |
| **Grain** | Cumulative daily |
| **Owner** | Priya Sharma (CFO) |
| **Refresh** | Daily |
| **Target** | On-track = within 5% of pro-rata annual target at any given date |
| **Related KPIs** | Total Revenue, MoM Growth, Annual Target |

---

### 6. Customer Lifetime Value (CLV)

| Field | Detail |
|---|---|
| **Definition** | Predicted total revenue a customer will generate over their entire relationship with the business. Calculated historically based on actual purchase behaviour. |
| **Formula** | `Average Order Value × Purchase Frequency × Customer Lifespan (months)` |
| **SQL** | `AVG(order_total) * COUNT(orders) / DATEDIFF(MONTH, first_order_date, last_order_date)` per customer |
| **Source tables** | `gold.fact_sales`, `gold.dim_customer` |
| **Filters** | Customers with at least 2 orders. Excludes one-time buyers from CLV calculation (flagged separately). |
| **Grain** | Per customer |
| **Owner** | Sarah Chen (Sales Manager) |
| **Refresh** | Monthly |
| **Target** | Top 20% of customers should represent > 60% of total CLV |
| **Related KPIs** | Customer Churn Rate, Customer Acquisition Cost, Revenue by Customer |

---

### 7. Customer Churn Rate

| Field | Detail |
|---|---|
| **Definition** | Percentage of active customers who did not place an order in the last 90 days, compared to the total active customer base at the start of that period. A customer is considered churned if they have not ordered in 90+ days and previously ordered at least twice. |
| **Formula** | `(Customers with no order in 90 days / Total active customers 90 days ago) × 100` |
| **SQL** | Flag customers where `DATEDIFF(DAY, last_order_date, GETDATE()) > 90` |
| **Source tables** | `gold.dim_customer`, `gold.fact_sales` |
| **Filters** | Only customers with 2+ historical orders. Excludes new customers (< 90 days old). |
| **Grain** | Per customer (flagged), rolled up monthly |
| **Owner** | Sarah Chen (Sales Manager) |
| **Refresh** | Weekly |
| **Target** | Monthly churn rate < 3%. Alert if any customer with CLV > $5,000 enters churn risk. |
| **Related KPIs** | CLV, Customer Acquisition Cost, Last Order Recency |

---

### 8. Customer Acquisition Cost (CAC)

| Field | Detail |
|---|---|
| **Definition** | Average cost to acquire one new customer. Calculated as total sales and marketing spend divided by the number of new customers acquired in the period. Note: marketing spend data is not currently in the warehouse — this KPI uses a proxy calculation from CRM source data until spend data is integrated. |
| **Formula** | `Total Sales Cost / Number of New Customers Acquired` |
| **SQL** | New customers = `dim_customer` records where `first_order_date` falls in the period |
| **Source tables** | `gold.dim_customer`, `gold.fact_sales` |
| **Filters** | New customers only — `is_new_customer = 1` flag on `dim_customer` |
| **Grain** | Monthly, by customer segment |
| **Owner** | Marcus Obi (Finance Analyst) |
| **Refresh** | Monthly |
| **Target** | CAC should be less than 12-month CLV. CAC:CLV ratio > 1:3 is healthy. |
| **Related KPIs** | CLV, Churn Rate, Net Revenue |

---

### 9. Product Return Rate

| Field | Detail |
|---|---|
| **Definition** | Percentage of sold units that were returned in the period. A high return rate on a product signals quality, fulfilment, or expectation issues. |
| **Formula** | `(Total Units Returned / Total Units Sold) × 100` |
| **SQL** | `SUM(returned_qty) / NULLIF(SUM(order_qty), 0) * 100` |
| **Source tables** | `gold.fact_sales`, `gold.dim_product` |
| **Filters** | By product, product category, and time period. |
| **Grain** | Per product, per product category |
| **Owner** | Sarah Chen (Sales Manager) |
| **Refresh** | Daily |
| **Target** | Overall return rate < 5%. Alert if any single product exceeds 15%. |
| **Related KPIs** | Net Revenue, Gross Margin %, Refund Impact |

---

### 10. Refund Impact on Net Revenue

| Field | Detail |
|---|---|
| **Definition** | The total monetary value of refunds processed in the period, expressed both as an absolute amount and as a percentage of Gross Revenue. Shows how much refunds are eroding top-line revenue. |
| **Formula** | `SUM(refund_amount)` and `SUM(refund_amount) / SUM(unit_price * order_qty) × 100` |
| **SQL** | `SELECT SUM(refund_amount), SUM(refund_amount) / NULLIF(SUM(unit_price * order_qty), 0) * 100 FROM gold.fact_sales` |
| **Source tables** | `gold.fact_sales`, `gold.dim_date` |
| **Filters** | Only rows where `refund_amount > 0` |
| **Grain** | Monthly, by product line |
| **Owner** | Marcus Obi (Finance Analyst) |
| **Refresh** | Daily |
| **Target** | Refund % of Gross Revenue < 3% |
| **Related KPIs** | Net Revenue, Product Return Rate, Gross Margin % |

---

### 11. Sales Rep Performance vs Quota

| Field | Detail |
|---|---|
| **Definition** | Each sales rep's YTD revenue attainment as a percentage of their assigned quota for the period. Shows who is on track, ahead, or behind. |
| **Formula** | `(Rep YTD Revenue / Rep Quota) × 100` |
| **SQL** | Join `fact_sales` to `dim_customer.assigned_rep` and compare to quota table |
| **Source tables** | `gold.fact_sales`, `gold.dim_customer` |
| **Filters** | Current fiscal year. Completed orders only. |
| **Grain** | Per sales rep, monthly |
| **Owner** | Sarah Chen (Sales Manager) |
| **Refresh** | Daily |
| **Target** | 100% quota attainment. Alert if any rep is below 70% with less than 30 days in the quarter. |
| **Related KPIs** | Total Revenue, Territory Performance, CLV |

---

### 12. Data Quality Pass Rate

| Field | Detail |
|---|---|
| **Definition** | Percentage of automated Great Expectations data quality tests that passed in the most recent pipeline run. Measures the health and reliability of the data pipeline. |
| **Formula** | `(Passing Checks / Total Checks) × 100` |
| **SQL** | `SELECT passing_checks * 100.0 / NULLIF(total_checks, 0) FROM silver.dq_run_log WHERE run_id = (SELECT MAX(run_id) FROM silver.dq_run_log)` |
| **Source tables** | `silver.dq_run_log` |
| **Filters** | Most recent completed pipeline run only |
| **Grain** | Per pipeline run |
| **Owner** | Data Engineering (Devanshi) |
| **Refresh** | Per pipeline run (daily) |
| **Target** | Critical tests: 100% pass rate required before Gold layer refreshes. Overall: > 98%. |
| **Related KPIs** | All KPIs depend on this — DQ pass rate is the trust foundation |

---

## KPI Summary Table

| # | KPI Name | Owner | Source | Refresh | Target |
|---|---|---|---|---|---|
| 1 | Total Revenue | Priya (CFO) | fact_sales | Daily | Per sales plan |
| 2 | Net Revenue | Marcus (Finance) | fact_sales | Daily | Within 2% of gross |
| 3 | Gross Margin % | Marcus (Finance) | fact_sales + dim_product | Daily | > 35% |
| 4 | MoM Revenue Growth | Priya (CFO) | vw_kpi_revenue | Monthly | > 5% |
| 5 | YTD Revenue | Priya (CFO) | fact_sales + dim_date | Daily | Within 5% of pro-rata target |
| 6 | Customer CLV | Sarah (Sales) | fact_sales + dim_customer | Monthly | Top 20% = 60% of CLV |
| 7 | Customer Churn Rate | Sarah (Sales) | dim_customer + fact_sales | Weekly | < 3% monthly |
| 8 | Customer Acquisition Cost | Marcus (Finance) | dim_customer + fact_sales | Monthly | CAC:CLV > 1:3 |
| 9 | Product Return Rate | Sarah (Sales) | fact_sales + dim_product | Daily | < 5% overall |
| 10 | Refund Impact on Net Revenue | Marcus (Finance) | fact_sales | Daily | < 3% of gross |
| 11 | Sales Rep vs Quota | Sarah (Sales) | fact_sales + dim_customer | Daily | 100% attainment |
| 12 | Data Quality Pass Rate | Engineering | dq_run_log | Per run | 100% critical / > 98% overall |

---

## Business Rules Reference

These rules apply across all KPI calculations and must be respected in every SQL
script, dbt model, and dashboard calculation.

| Rule | Definition |
|---|---|
| **Completed order** | `order_status IN ('Shipped', 'Delivered')` |
| **Cancelled order** | `order_status = 'Cancelled'` — excluded from all revenue KPIs |
| **Returned order** | `order_status = 'Returned'` — included in Return Rate, excluded from Net Revenue |
| **Active customer** | Customer with at least 1 completed order in the last 12 months |
| **New customer** | Customer whose `first_order_date` falls within the reporting period |
| **Churned customer** | Active customer with no order in 90+ days and 2+ historical orders |
| **COGS** | `dim_product.cost_price × order_qty` |
| **Refund amount** | Stored directly on `fact_sales.refund_amount` (0 if no refund) |
| **Fiscal year** | Calendar year — January 1 to December 31 |
| **Reporting currency** | CAD (Canadian Dollars) |

---

## Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial definitions — 12 KPIs across Revenue, Customer, Product, DQ | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*

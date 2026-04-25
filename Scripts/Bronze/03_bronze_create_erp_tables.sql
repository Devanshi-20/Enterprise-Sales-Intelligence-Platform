-- ============================================================
-- Script  : 03_bronze_create_erp_tables.sql
-- Project : Enterprise Sales Intelligence Platform
-- Layer   : Bronze
-- Purpose : Create staging tables for ERP source data
-- Rule    : Bronze = raw mirror. No transformations here.
--           All columns match source CSV exactly.
--           Only addition: load_timestamp (audit column)
-- Author  : Devanshi
-- ============================================================

USE SalesIntelligenceDW;
GO

-- ────────────────────────────────────────────────────────────
-- TABLE 1: bronze.erp_orders
-- Source : erp_orders.csv
-- Grain  : One row per order header
-- ────────────────────────────────────────────────────────────
IF OBJECT_ID('bronze.erp_orders', 'U') IS NOT NULL
    DROP TABLE bronze.erp_orders;
GO

CREATE TABLE bronze.erp_orders (
    order_id        VARCHAR(50),      -- Unique order identifier from ERP
    customer_id     VARCHAR(50),      -- ERP customer ID (different from CRM)
    order_date      VARCHAR(30),      -- Stored as VARCHAR — raw from CSV
    ship_date       VARCHAR(30),      -- May be NULL for unshipped orders
    order_status    VARCHAR(30),      -- Shipped, Delivered, Cancelled, Returned, Pending
    total_amount    VARCHAR(30),      -- Stored as VARCHAR — cast in Silver
    refund_amount   VARCHAR(30),      -- NULL in source if no refund
    sales_rep_id    VARCHAR(50),      -- NULL for online orders
    region          VARCHAR(100),     -- Free text — standardised in Silver
    load_timestamp  DATETIME          -- Added by load script, not in source
        DEFAULT GETDATE()
);
GO

PRINT 'SUCCESS: bronze.erp_orders created.';
GO

-- ────────────────────────────────────────────────────────────
-- TABLE 2: bronze.erp_order_items
-- Source : erp_order_items.csv
-- Grain  : One row per order line item
-- ────────────────────────────────────────────────────────────
IF OBJECT_ID('bronze.erp_order_items', 'U') IS NOT NULL
    DROP TABLE bronze.erp_order_items;
GO

CREATE TABLE bronze.erp_order_items (
    order_item_id   VARCHAR(50),      -- Unique line item identifier
    order_id        VARCHAR(50),      -- FK to erp_orders.order_id
    product_id      VARCHAR(50),      -- Product identifier from ERP
    quantity        VARCHAR(20),      -- Stored as VARCHAR — some rows have qty=0
    unit_price      VARCHAR(30),      -- Price per unit at time of order
    line_total      VARCHAR(30),      -- Calculated in source (qty * price)
    returned_qty    VARCHAR(20),      -- NULL in source = 0 returns
    load_timestamp  DATETIME
        DEFAULT GETDATE()
);
GO

PRINT 'SUCCESS: bronze.erp_order_items created.';
GO

-- ────────────────────────────────────────────────────────────
-- TABLE 3: bronze.erp_products
-- Source : erp_products.csv
-- Grain  : One row per product
-- ────────────────────────────────────────────────────────────
IF OBJECT_ID('bronze.erp_products', 'U') IS NOT NULL
    DROP TABLE bronze.erp_products;
GO

CREATE TABLE bronze.erp_products (
    product_id      VARCHAR(50),      -- Unique product identifier
    product_name    VARCHAR(255),     -- Mixed case in source
    category        VARCHAR(100),     -- Some with trailing spaces
    sub_category    VARCHAR(100),
    cost_price      VARCHAR(30),      -- NULL for 8 products (known issue)
    list_price      VARCHAR(30),      -- Standard selling price
    is_active       VARCHAR(5),       -- '1' or '0' as string in source
    load_timestamp  DATETIME
        DEFAULT GETDATE()
);
GO

PRINT 'SUCCESS: bronze.erp_products created.';
GO

-- ────────────────────────────────────────────────────────────
-- Verify all 3 ERP tables exist and are empty
-- ────────────────────────────────────────────────────────────
SELECT
    t.name          AS table_name,
    s.name          AS schema_name,
    p.rows          AS row_count,
    GETDATE()       AS checked_at
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE s.name = 'bronze'
  AND t.name LIKE 'erp%'
ORDER BY t.name;
GO

-- ============================================================
-- Expected output: 3 rows, all with row_count = 0
-- ============================================================
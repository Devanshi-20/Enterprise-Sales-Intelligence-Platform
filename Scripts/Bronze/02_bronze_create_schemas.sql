-- ============================================================
-- Script    : 02_bronze_create_schemas.sql
-- Project   : Enterprise Sales Intelligence Platform
-- Layer     : Setup
-- Purpose   : Create the three Medallion Architecture schemas
--             bronze → silver → gold
-- Run after : 01_bronze_create_database.sql
-- Author    : Devanshi
-- ============================================================

USE SalesIntelligenceDW;
GO

-- ── Bronze: raw data, exact mirror of source CSV files ───────
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
    PRINT 'SUCCESS: bronze schema created.';
END
ELSE
    PRINT 'INFO: bronze already exists.';
GO

-- ── Silver: cleansed, standardised, deduplicated data ────────
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
    PRINT 'SUCCESS: silver schema created.';
END
ELSE
    PRINT 'INFO: silver already exists.';
GO

-- ── Gold: business-ready star schema and KPI views ───────────
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
    PRINT 'SUCCESS: gold schema created.';
END
ELSE
    PRINT 'INFO: gold already exists.';
GO

-- ── Verify all three exist ────────────────────────────────────
SELECT
    name        AS schema_name,
    schema_id   AS id
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold')
ORDER BY name;
GO

-- ============================================================
-- Expected: 3 rows — bronze, gold, silver
-- ============================================================
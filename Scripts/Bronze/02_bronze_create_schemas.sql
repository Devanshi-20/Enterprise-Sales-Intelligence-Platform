-- ============================================================
-- Script  : 02_bronze_create_schemas.sql
-- Project : Enterprise Sales Intelligence Platform
-- Layer   : Setup
-- Purpose : Create the three Medallion Architecture schemas
-- Run in  : SSMS connected to SalesIntelligenceDW
-- Author  : Devanshi
-- ============================================================

USE SalesIntelligenceDW;
GO

-- Bronze: raw data, exact mirror of source systems
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
    PRINT 'SUCCESS: bronze schema created.';
END
ELSE
    PRINT 'INFO: bronze schema already exists.';
GO

-- Silver: cleansed, standardised, deduplicated data
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
    PRINT 'SUCCESS: silver schema created.';
END
ELSE
    PRINT 'INFO: silver schema already exists.';
GO

-- Gold: business-ready star schema, KPI views
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
    PRINT 'SUCCESS: gold schema created.';
END
ELSE
    PRINT 'INFO: gold schema already exists.';
GO

-- Verify all three schemas exist
SELECT
    name            AS schema_name,
    schema_id,
    GETDATE()       AS verified_at
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold')
ORDER BY name;
GO

-- ============================================================
-- Expected output: 3 rows — bronze, gold, silver
-- ============================================================
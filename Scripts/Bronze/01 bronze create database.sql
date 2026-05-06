-- ============================================================
-- Script    : 01_bronze_create_database.sql
-- Project   : Enterprise Sales Intelligence Platform
-- Layer     : Setup
-- Purpose   : Create the SalesIntelligenceDW database
-- Run in    : SSMS — connect to your SQL Server instance first
--             (use Windows Authentication or SQL Server Auth)
-- Author    : Devanshi
-- ============================================================

USE master;
GO

-- ── Create database only if it does not already exist ────────
IF NOT EXISTS (
    SELECT name FROM sys.databases
    WHERE  name = 'SalesIntelligenceDW'
)
BEGIN
    CREATE DATABASE SalesIntelligenceDW;
    PRINT 'SUCCESS: SalesIntelligenceDW database created.';
END
ELSE
BEGIN
    PRINT 'INFO: SalesIntelligenceDW already exists — no action taken.';
END
GO

-- ── Switch into the new database ─────────────────────────────
USE SalesIntelligenceDW;
GO

-- ── Confirm you are in the right place ───────────────────────
SELECT
    DB_NAME()       AS current_database,
    @@SERVERNAME    AS server_name,
    GETDATE()       AS run_at;
GO

-- ============================================================
-- Expected result:
--   current_database  = SalesIntelligenceDW
--   server_name       = YOUR-MACHINE-NAME
-- ============================================================
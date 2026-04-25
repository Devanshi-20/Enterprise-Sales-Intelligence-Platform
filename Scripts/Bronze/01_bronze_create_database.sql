-- ============================================================
-- Script  : 01_bronze_create_database.sql
-- Project : Enterprise Sales Intelligence Platform
-- Layer   : Setup
-- Purpose : Create the data warehouse database
-- Run in  : SSMS connected to your local SQL Server instance
-- Author  : Devanshi
-- ============================================================

-- Step 1: Make sure you are on the master database first
USE master;
GO

-- Step 2: Only create if it does not already exist
IF NOT EXISTS (
    SELECT name
    FROM sys.databases
    WHERE name = 'SalesIntelligenceDW'
)
BEGIN
    CREATE DATABASE SalesIntelligenceDW;
    PRINT 'SUCCESS: SalesIntelligenceDW database created.';
END
ELSE
BEGIN
    PRINT 'INFO: SalesIntelligenceDW already exists. No action taken.';
END
GO

-- Step 3: Switch into the new database
USE SalesIntelligenceDW;
GO

-- Step 4: Confirm you are in the right place
SELECT
    DB_NAME()           AS current_database,
    GETDATE()           AS run_timestamp,
    @@SERVERNAME        AS server_name;
GO

-- ============================================================
-- Expected output:
-- current_database      run_timestamp           server_name
-- SalesIntelligenceDW   2026-04-xx xx:xx:xx     YOUR-SERVER
-- ============================================================
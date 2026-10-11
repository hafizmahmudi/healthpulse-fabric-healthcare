-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: Silver → Gold Data Quality (cross-warehouse)

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dq'
)
BEGIN
    EXEC('CREATE SCHEMA dq');
END

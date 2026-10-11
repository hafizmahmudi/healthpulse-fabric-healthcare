-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: Schema

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dim'
)
BEGIN
    EXEC('CREATE SCHEMA dim');
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'fact'
)
BEGIN
    EXEC('CREATE SCHEMA fact');
END;


IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END;

-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: List what was created

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t

INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id

WHERE s.name IN
(
    'dim',
    'fact'
)

ORDER BY
    s.name,
    t.name;

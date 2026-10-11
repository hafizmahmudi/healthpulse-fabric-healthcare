-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: DimDate

-- ============================================================
-- DQ: DimDate
-- ============================================================

WITH CurrentRun AS
(
    SELECT TOP 1 DQRunID
    FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun
    WHERE Status = 'RUNNING'
    ORDER BY StartTime DESC
),

BaseKey AS
(
    SELECT
        ISNULL(MAX(DQResultKey), 0) AS BaseKey
    FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult
),

Checks AS
(
    -- DateKey null
    SELECT
        'DateKey populated' AS CheckName,
        'COMPLETENESS' AS CheckType,
        'CRITICAL' AS Severity,

        SUM(
            CASE WHEN DateKey IS NULL
                 THEN CAST(1 AS BIGINT)
                 ELSE CAST(0 AS BIGINT)
            END
        ) AS FailedCount,

        COUNT_BIG(*) AS TotalCount,

        'DateKey must not be NULL.' AS Details

    FROM [HP_03_WH_HealthAnalytics].dim.DimDate


    UNION ALL


    -- Duplicate DateKey
    SELECT
        'DateKey unique',
        'UNIQUENESS',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT DateKey
                FROM [HP_03_WH_HealthAnalytics].dim.DimDate
                GROUP BY DateKey
                HAVING COUNT_BIG(*) > 1
            ) d
        ),

        (SELECT COUNT_BIG(*) FROM [HP_03_WH_HealthAnalytics].dim.DimDate),

        'Each DateKey must occur once.'


    UNION ALL


    -- Duplicate FullDate
    SELECT
        'FullDate unique',
        'UNIQUENESS',
        'HIGH',

        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT FullDate
                FROM [HP_03_WH_HealthAnalytics].dim.DimDate
                GROUP BY FullDate
                HAVING COUNT_BIG(*) > 1
            ) d
        ),

        (SELECT COUNT_BIG(*) FROM [HP_03_WH_HealthAnalytics].dim.DimDate),

        'Each calendar date should occur once.'
),

Numbered AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            ORDER BY CheckName
        ) AS rn

    FROM Checks
)

INSERT INTO [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult
(
    DQResultKey,
    DQRunID,
    DQRunTime,
    LayerName,
    EntityName,
    CheckName,
    CheckType,
    Severity,
    Status,
    FailedCount,
    TotalCount,
    Details
)

SELECT
    b.BaseKey + n.rn,
    r.DQRunID,
    SYSUTCDATETIME(),

    'Gold',
    'DimDate',

    n.CheckName,
    n.CheckType,
    n.Severity,

    CASE
        WHEN ISNULL(n.FailedCount,0) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    ISNULL(n.FailedCount,0),
    n.TotalCount,
    n.Details

FROM Numbered n
CROSS JOIN CurrentRun r
CROSS JOIN BaseKey b;

-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: DimProvider DQ check

-- ============================================================
-- DQ: DimProvider
-- ============================================================

WITH CurrentRun AS
(
    SELECT TOP 1 DQRunID
    FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun
    WHERE Status='RUNNING'
    ORDER BY StartTime DESC
),

BaseKey AS
(
    SELECT ISNULL(MAX(DQResultKey),0) BaseKey
    FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult
),

Checks AS
(
    SELECT
        'ProviderID populated' CheckName,
        'COMPLETENESS' CheckType,
        'CRITICAL' Severity,

        SUM(
            CASE WHEN ProviderID IS NULL
                 THEN CAST(1 AS BIGINT)
                 ELSE CAST(0 AS BIGINT)
            END
        ) FailedCount,

        COUNT_BIG(*) TotalCount,

        'ProviderID must be populated.' Details

    FROM [HP_03_WH_HealthAnalytics].dim.DimProvider


    UNION ALL


    SELECT
        'One current row per ProviderID',
        'SCD2',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT ProviderID
                FROM [HP_03_WH_HealthAnalytics].dim.DimProvider
                WHERE IsCurrent=1
                GROUP BY ProviderID
                HAVING COUNT_BIG(*) > 1
            ) x
        ),

        (SELECT COUNT_BIG(DISTINCT ProviderID)
         FROM [HP_03_WH_HealthAnalytics].dim.DimProvider),

        'Provider must have no more than one current version.'
),

Numbered AS
(
    SELECT *,
        ROW_NUMBER() OVER(ORDER BY CheckName) rn
    FROM Checks
)

INSERT INTO [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult
SELECT
    b.BaseKey+n.rn,
    r.DQRunID,
    SYSUTCDATETIME(),

    'Gold',
    'DimProvider',

    n.CheckName,
    n.CheckType,
    n.Severity,

    CASE WHEN ISNULL(n.FailedCount,0)=0
         THEN 'PASS' ELSE 'FAIL' END,

    ISNULL(n.FailedCount,0),
    n.TotalCount,
    n.Details

FROM Numbered n
CROSS JOIN CurrentRun r
CROSS JOIN BaseKey b;

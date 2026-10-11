-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: DimPayer DQ check

-- ============================================================
-- DQ: DimPayer
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
        'PayerID populated' CheckName,
        'COMPLETENESS' CheckType,
        'CRITICAL' Severity,

        SUM(
            CASE WHEN PayerID IS NULL
                 THEN CAST(1 AS BIGINT)
                 ELSE CAST(0 AS BIGINT)
            END
        ) FailedCount,

        COUNT_BIG(*) TotalCount,

        'PayerID must be populated.' Details

    FROM [HP_03_WH_HealthAnalytics].dim.DimPayer


    UNION ALL


    SELECT
        'One current row per PayerID',
        'SCD2',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT PayerID
                FROM [HP_03_WH_HealthAnalytics].dim.DimPayer
                WHERE IsCurrent=1
                GROUP BY PayerID
                HAVING COUNT_BIG(*) > 1
            ) x
        ),

        (SELECT COUNT_BIG(DISTINCT PayerID)
         FROM [HP_03_WH_HealthAnalytics].dim.DimPayer),

        'Payer may have only one current version.'
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
    'DimPayer',

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

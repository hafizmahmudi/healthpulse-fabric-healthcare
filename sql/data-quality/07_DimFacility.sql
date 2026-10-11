-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: DimFacility

-- ============================================================
-- DQ: DimFacility
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
        'FacilityID populated' CheckName,
        'COMPLETENESS' CheckType,
        'CRITICAL' Severity,

        SUM(
            CASE WHEN FacilityID IS NULL
                 THEN CAST(1 AS BIGINT)
                 ELSE CAST(0 AS BIGINT)
            END
        ) FailedCount,

        COUNT_BIG(*) TotalCount,

        'FacilityID must be populated.' Details

    FROM [HP_03_WH_HealthAnalytics].dim.DimFacility


    UNION ALL


    SELECT
        'One current row per FacilityID',
        'SCD2',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT FacilityID
                FROM [HP_03_WH_HealthAnalytics].dim.DimFacility
                WHERE IsCurrent=1
                GROUP BY FacilityID
                HAVING COUNT_BIG(*) > 1
            ) x
        ),

        (SELECT COUNT_BIG(DISTINCT FacilityID)
         FROM [HP_03_WH_HealthAnalytics].dim.DimFacility),

        'Facility must have no more than one current version.'
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
    'DimFacility',

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

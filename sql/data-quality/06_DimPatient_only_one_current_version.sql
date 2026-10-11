-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: DimPatient — only one current version

-- ============================================================
-- DQ: DimPatient
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
    SELECT ISNULL(MAX(DQResultKey),0) AS BaseKey
    FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult
),

Checks AS
(
    SELECT
        'PatientID populated' CheckName,
        'COMPLETENESS' CheckType,
        'CRITICAL' Severity,

        SUM(
            CASE WHEN PatientID IS NULL
                 THEN CAST(1 AS BIGINT)
                 ELSE CAST(0 AS BIGINT)
            END
        ) FailedCount,

        COUNT_BIG(*) TotalCount,

        'PatientID must not be NULL.' Details

    FROM [HP_03_WH_HealthAnalytics].dim.DimPatient


    UNION ALL


    SELECT
        'One current row per PatientID',
        'SCD2',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT PatientID
                FROM [HP_03_WH_HealthAnalytics].dim.DimPatient
                WHERE IsCurrent = 1
                GROUP BY PatientID
                HAVING COUNT_BIG(*) > 1
            ) x
        ),

        (SELECT COUNT_BIG(DISTINCT PatientID)
         FROM [HP_03_WH_HealthAnalytics].dim.DimPatient),

        'A patient may have only one current SCD2 version.'


    UNION ALL


    SELECT
        'ValidTo greater than ValidFrom',
        'SCD2',
        'CRITICAL',

        COUNT_BIG(
            CASE
                WHEN ValidTo <= ValidFrom
                THEN 1
            END
        ),

        COUNT_BIG(*),

        'SCD2 ValidTo must be greater than ValidFrom.'

    FROM [HP_03_WH_HealthAnalytics].dim.DimPatient
),

Numbered AS
(
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY CheckName) rn
    FROM Checks
)

INSERT INTO [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult
SELECT
    b.BaseKey + n.rn,
    r.DQRunID,
    SYSUTCDATETIME(),

    'Gold',
    'DimPatient',

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

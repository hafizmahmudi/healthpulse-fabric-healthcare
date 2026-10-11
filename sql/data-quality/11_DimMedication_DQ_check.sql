-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: DimMedication DQ check

-- ============================================================
-- DQ: DimMedication
-- ============================================================

WITH CurrentRun AS
(
    SELECT TOP 1
        DQRunID

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

Checks
(
    CheckName,
    CheckType,
    Severity,
    FailedCount,
    TotalCount,
    Details
)
AS
(

    -- ========================================================
    -- MedicationCode populated
    -- ========================================================

    SELECT

        'MedicationCode populated',

        'COMPLETENESS',

        'CRITICAL',

        SUM(
            CASE

                WHEN MedicationCode IS NULL
                THEN CAST(1 AS BIGINT)

                ELSE CAST(0 AS BIGINT)

            END
        ),

        COUNT_BIG(*),

        'MedicationCode must be populated.'

    FROM [HP_03_WH_HealthAnalytics].dim.DimMedication


    UNION ALL


    -- ========================================================
    -- MedicationCode unique
    -- ========================================================

    SELECT

        'MedicationCode unique',

        'UNIQUENESS',

        'CRITICAL',

        (
            SELECT
                COUNT_BIG(*)

            FROM
            (
                SELECT
                    MedicationCode

                FROM [HP_03_WH_HealthAnalytics].dim.DimMedication

                WHERE MedicationCode IS NOT NULL

                GROUP BY MedicationCode

                HAVING COUNT_BIG(*) > 1

            ) AS x
        ),

        (
            SELECT
                COUNT_BIG(*)

            FROM [HP_03_WH_HealthAnalytics].dim.DimMedication
        ),

        'MedicationCode must be unique.'
),

Numbered AS
(
    SELECT
        CheckName,
        CheckType,
        Severity,
        FailedCount,
        TotalCount,
        Details,

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

    CAST(b.BaseKey AS BIGINT)
    +
    CAST(n.rn AS BIGINT),

    r.DQRunID,

    SYSUTCDATETIME(),

    'Gold',

    'DimMedication',

    n.CheckName,
    n.CheckType,

    n.Severity,

    CASE

        WHEN ISNULL(n.FailedCount, 0) = 0
        THEN 'PASS'

        ELSE 'FAIL'

    END,

    ISNULL(n.FailedCount, 0),

    n.TotalCount,

    n.Details

FROM Numbered AS n

CROSS JOIN CurrentRun AS r

CROSS JOIN BaseKey AS b;

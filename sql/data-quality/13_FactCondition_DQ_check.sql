-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: FactCondition DQ check

-- ============================================================
-- DQ: FactCondition
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
    -- Check 1: One row per ConditionID
    -- ========================================================

    SELECT
        'One row per ConditionID',
        'GRAIN',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)

            FROM
            (
                SELECT
                    ConditionID

                FROM [HP_03_WH_HealthAnalytics].fact.FactCondition

                WHERE ConditionID IS NOT NULL

                GROUP BY ConditionID

                HAVING COUNT_BIG(*) > 1
            ) AS x
        ),

        (
            SELECT COUNT_BIG(*)
            FROM [HP_03_WH_HealthAnalytics].fact.FactCondition
        ),

        'Fact grain must be one row per ConditionID.'


    UNION ALL


    -- ========================================================
    -- Check 2: PatientKey populated
    -- ========================================================

    SELECT
        'PatientKey populated',
        'COMPLETENESS',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)

            FROM [HP_03_WH_HealthAnalytics].fact.FactCondition

            WHERE PatientKey IS NULL
        ),

        (
            SELECT COUNT_BIG(*)
            FROM [HP_03_WH_HealthAnalytics].fact.FactCondition
        ),

        'PatientKey must be populated.'


    UNION ALL


    -- ========================================================
    -- Check 3: DiagnosisKey populated
    -- ========================================================

    SELECT
        'DiagnosisKey populated',
        'COMPLETENESS',
        'HIGH',

        (
            SELECT COUNT_BIG(*)

            FROM [HP_03_WH_HealthAnalytics].fact.FactCondition

            WHERE DiagnosisKey IS NULL
        ),

        (
            SELECT COUNT_BIG(*)
            FROM [HP_03_WH_HealthAnalytics].fact.FactCondition
        ),

        'Condition should resolve to DimDiagnosis.'
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
    'FactCondition',

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

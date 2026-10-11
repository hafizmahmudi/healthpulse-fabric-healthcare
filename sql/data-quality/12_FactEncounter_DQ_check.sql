-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: FactEncounter DQ check

-- ============================================================
-- DQ: FactEncounter
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
    -- Duplicate EncounterID
    SELECT
        'One row per EncounterID' CheckName,
        'GRAIN' CheckType,
        'CRITICAL' Severity,

        (
            SELECT COUNT_BIG(*)
            FROM
            (
                SELECT EncounterID
                FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter
                GROUP BY EncounterID
                HAVING COUNT_BIG(*) > 1
            ) x
        ) FailedCount,

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter) TotalCount,

        'Fact grain is one row per EncounterID.' Details


    UNION ALL


    -- Missing PatientKey
    SELECT
        'PatientKey populated',
        'COMPLETENESS',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)
            FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter
            WHERE PatientKey IS NULL
        ),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter),

        'Every encounter should resolve to DimPatient.'


    UNION ALL


    -- Missing DateKey
    SELECT
        'DateKey populated',
        'COMPLETENESS',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)
            FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter
            WHERE DateKey IS NULL
        ),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter),

        'Every encounter should resolve to DimDate.'


    UNION ALL


    -- Orphan PatientKey
    SELECT
        'PatientKey valid',
        'REFERENTIAL_INTEGRITY',
        'CRITICAL',

        (
            SELECT COUNT_BIG(*)

            FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter f

            LEFT JOIN [HP_03_WH_HealthAnalytics].dim.DimPatient p
                ON p.PatientKey = f.PatientKey

            WHERE
                f.PatientKey IS NOT NULL
                AND p.PatientKey IS NULL
        ),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter),

        'PatientKey must exist in DimPatient.'


    UNION ALL


    -- Negative measures
    SELECT
        'Encounter measures non-negative',
        'BUSINESS_RULE',
        'HIGH',

        (
            SELECT COUNT_BIG(*)
            FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter

            WHERE
                   LengthOfStayDays < 0
                OR BaseEncounterCost < 0
                OR TotalClaimCost < 0
                OR PayerCoverage < 0
        ),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactEncounter),

        'Length of stay and financial values should not be negative.'
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
    'FactEncounter',

    n.CheckName,
    n.CheckType,
    n.Severity,

    CASE WHEN ISNULL(n.FailedCount,0)=0
         THEN 'PASS'
         ELSE 'FAIL'
    END,

    ISNULL(n.FailedCount,0),
    n.TotalCount,
    n.Details

FROM Numbered n
CROSS JOIN CurrentRun r
CROSS JOIN BaseKey b;

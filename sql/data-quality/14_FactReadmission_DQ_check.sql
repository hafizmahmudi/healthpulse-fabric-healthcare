-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: FactReadmission DQ check

-- ============================================================
-- DQ: FactReadmission
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

Checks (
    CheckName,
    CheckType,
    Severity,
    FailedCount,
    TotalCount,
    Details

) AS
(
    SELECT
        'PatientKey populated',
        'COMPLETENESS',
        'CRITICAL',

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission
         WHERE PatientKey IS NULL),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission),

        'Readmission must resolve to a patient.'


    UNION ALL


    SELECT
        'IndexEncounterKey populated',
        'COMPLETENESS',
        'CRITICAL',

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission
         WHERE IndexEncounterKey IS NULL),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission),

        'Index encounter must be populated.'


    UNION ALL


    SELECT
        'ReadmissionEncounterKey populated',
        'COMPLETENESS',
        'CRITICAL',

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission
         WHERE ReadmissionEncounterKey IS NULL),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission),

        'Readmission encounter must be populated.'


    UNION ALL


    SELECT
        'DaysToReadmission positive',
        'BUSINESS_RULE',
        'HIGH',

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission
         WHERE DaysToReadmission <= 0),

        (SELECT COUNT_BIG(*)
         FROM [HP_03_WH_HealthAnalytics].fact.FactReadmission),

        'DaysToReadmission should be greater than zero.'
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
    'FactReadmission',
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

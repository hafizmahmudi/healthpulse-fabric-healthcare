-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load DimDiagnosis

-- ============================================================
-- DimDiagnosis Load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.condition
--
-- Target:
--   dim.DimDiagnosis
--
-- Business Key:
--   DiagnosisCode = ConditionCode
--
-- Surrogate Key:
--   DiagnosisKey
--
-- SCD:
--   Type 1
-- ============================================================


-- ============================================================
-- 1. Get current maximum DiagnosisKey
-- ============================================================

DECLARE @MaxDiagnosisKey BIGINT;

SELECT
    @MaxDiagnosisKey =
        ISNULL(MAX(DiagnosisKey), 0)

FROM dim.DimDiagnosis;


-- ============================================================
-- 2. Update description when DiagnosisCode already exists
-- ============================================================

UPDATE target

SET
    target.DiagnosisDescription =
        source.DiagnosisDescription

FROM dim.DimDiagnosis AS target

INNER JOIN
(
    SELECT
        ConditionCode AS DiagnosisCode,

        MAX(ConditionDescription)
            AS DiagnosisDescription

    FROM [HP_02_LH_Health_Silver].[clinical].[condition]

    WHERE ConditionCode IS NOT NULL

    GROUP BY ConditionCode

) AS source

    ON target.DiagnosisCode =
       source.DiagnosisCode

WHERE
    ISNULL(target.DiagnosisDescription, '')
    <>
    ISNULL(source.DiagnosisDescription, '');


-- ============================================================
-- 3. Prepare unique diagnosis codes
-- ============================================================

WITH DiagnosisSource AS
(
    SELECT
        ConditionCode AS DiagnosisCode,

        MAX(ConditionDescription)
            AS DiagnosisDescription

    FROM [HP_02_LH_Health_Silver].[clinical].[condition]

    WHERE ConditionCode IS NOT NULL

    GROUP BY ConditionCode
),


-- ============================================================
-- 4. Find only NEW DiagnosisCodes
-- ============================================================

NewDiagnoses AS
(
    SELECT
        source.DiagnosisCode,
        source.DiagnosisDescription,

        ROW_NUMBER() OVER
        (
            ORDER BY source.DiagnosisCode
        ) AS RowNumber

    FROM DiagnosisSource AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM dim.DimDiagnosis AS target

        WHERE
            target.DiagnosisCode =
            source.DiagnosisCode
    )
)


-- ============================================================
-- 5. Insert new diagnosis dimension members
-- ============================================================

INSERT INTO dim.DimDiagnosis
(
    DiagnosisKey,
    DiagnosisCode,
    DiagnosisDescription
)

SELECT
    @MaxDiagnosisKey + RowNumber,

    DiagnosisCode,
    DiagnosisDescription

FROM NewDiagnoses;


-- ============================================================
-- 6. Summary
-- ============================================================

SELECT
    COUNT(*) AS TotalDiagnosisRows,

    COUNT(DISTINCT DiagnosisCode)
        AS UniqueDiagnosisCodes

FROM dim.DimDiagnosis;


-- ============================================================
-- 7. Validate
--
-- Expected:
-- zero rows
-- ============================================================

SELECT
    DiagnosisCode,
    COUNT(*) AS RecentChanges

FROM dim.DimDiagnosis

GROUP BY DiagnosisCode

HAVING COUNT(*) > 1;

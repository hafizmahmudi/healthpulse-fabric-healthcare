-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load DimMedication

-- ============================================================
-- DimMedication Load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.medication
--
-- Target:
--   dim.DimMedication
--
-- Business Key:
--   MedicationCode
--
-- Surrogate Key:
--   MedicationKey
--
-- SCD:
--   Type 1
-- ============================================================


-- ============================================================
-- 1. Find current maximum MedicationKey
-- ============================================================

DECLARE @MaxMedicationKey BIGINT;

SELECT
    @MaxMedicationKey = ISNULL(MAX(MedicationKey), 0)
FROM dim.DimMedication;


-- ============================================================
-- 2. MERGE MedicationSource into DimMedication
--
-- Existing MedicationCode:
--   Update MedicationDescription
--
-- New MedicationCode:
--   Insert new dimension member
-- ============================================================

WITH MedicationSource AS
(
    SELECT
        MedicationCode,

        MAX(MedicationDescription) AS MedicationDescription

    FROM [HP_02_LH_Health_Silver].[clinical].[medication]

    WHERE MedicationCode IS NOT NULL

    GROUP BY
        MedicationCode
),

NewMedicationKeys AS
(
    SELECT
        MedicationCode,

        @MaxMedicationKey
        + ROW_NUMBER() OVER
        (
            ORDER BY MedicationCode
        ) AS MedicationKey

    FROM MedicationSource

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM dim.DimMedication AS target

        WHERE target.MedicationCode =
              MedicationSource.MedicationCode
    )
)

MERGE dim.DimMedication AS target

USING
(
    SELECT
        source.MedicationCode,
        source.MedicationDescription,
        newKeys.MedicationKey

    FROM MedicationSource AS source

    LEFT JOIN NewMedicationKeys AS newKeys
        ON newKeys.MedicationCode =
           source.MedicationCode

) AS source

ON target.MedicationCode =
   source.MedicationCode


-- ============================================================
-- Existing MedicationCode
-- SCD Type 1: overwrite description
-- ============================================================

WHEN MATCHED
     AND ISNULL(target.MedicationDescription, '')
         <>
         ISNULL(source.MedicationDescription, '')

THEN
    UPDATE SET
        target.MedicationDescription =
            source.MedicationDescription


-- ============================================================
-- New MedicationCode
-- Insert new dimension member
-- ============================================================

WHEN NOT MATCHED BY TARGET

THEN
    INSERT
    (
        MedicationKey,
        MedicationCode,
        MedicationDescription
    )

    VALUES
    (
        source.MedicationKey,
        source.MedicationCode,
        source.MedicationDescription
    );


-- ============================================================
-- 3. Summary
-- ============================================================

SELECT
    COUNT(*) AS TotalMedicationRows,

    COUNT(DISTINCT MedicationCode)
        AS UniqueMedicationCodes

FROM dim.DimMedication;


-- ============================================================
-- 4. Validate duplicate MedicationCodes
--
-- Expected:
--   zero rows
-- ============================================================

SELECT
    MedicationCode,
    COUNT(*) AS RowCounts

FROM dim.DimMedication

GROUP BY
    MedicationCode

HAVING COUNT(*) > 1;

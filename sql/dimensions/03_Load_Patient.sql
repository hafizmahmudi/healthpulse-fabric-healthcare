-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load Patient

-- ============================================================
-- DimPatient SCD Type 2
--
-- Source:
--      stg.DimPatient
--
-- Target:
--      dim.DimPatient
--
-- Business Key:
--      PatientID
--
-- SCD Type 2 attribute:
--      MaritalStatus
--
-- Type 1 attributes:
--      FirstName
--      LastName
--      BirthDate
--      Gender
--      Race
--      Ethnicity
--      Age
--      AgeGroup
-- ============================================================


-- Use one timestamp for the entire SCD load
DECLARE @LoadTime DATETIME2(6) = SYSUTCDATETIME();


-- ============================================================
-- 1. Expire existing current rows when MaritalStatus changes
-- ============================================================

UPDATE target

SET
    target.ValidTo   = @LoadTime,
    target.IsCurrent = 0

FROM dim.DimPatient AS target

INNER JOIN stg.DimPatient AS source
    ON target.PatientID = source.PatientID

WHERE
    target.IsCurrent = 1

    AND ISNULL(target.MaritalStatus, '')
        <> ISNULL(source.MaritalStatus, '');


-- ============================================================
-- 2. Type 1 update
--
-- Only rows still current reach this step.
-- Changed SCD2 rows were expired above.
-- ============================================================

UPDATE target

SET
    target.FirstName = source.FirstName,
    target.LastName  = source.LastName,

    target.BirthDate = source.BirthDate,

    target.Gender    = source.Gender,
    target.Race      = source.Race,
    target.Ethnicity = source.Ethnicity,

    target.Age       = source.Age,
    target.AgeGroup  = source.AgeGroup

FROM dim.DimPatient AS target

INNER JOIN stg.DimPatient AS source
    ON target.PatientID = source.PatientID

WHERE
    target.IsCurrent = 1;


-- ============================================================
-- 3. Get current maximum PatientKey
-- ============================================================

DECLARE @MaxPatientKey BIGINT;

SELECT
    @MaxPatientKey = ISNULL(MAX(PatientKey), 0)

FROM dim.DimPatient;


-- ============================================================
-- 4. Find rows that need inserting
--
-- This automatically includes:
--
--   NEW patient
--       -> no current target row
--
--   CHANGED patient
--       -> old current row was expired in Step 1,
--          therefore there is now no current target row
-- ============================================================

WITH PatientsToInsert AS
(
    SELECT
        source.PatientID,

        source.FirstName,
        source.LastName,

        source.BirthDate,

        source.Gender,
        source.Race,
        source.Ethnicity,

        source.MaritalStatus,

        source.Age,
        source.AgeGroup,


        ROW_NUMBER() OVER
        (
            ORDER BY source.PatientID
        ) AS RowNumber

    FROM stg.DimPatient AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM dim.DimPatient AS target

        WHERE
            target.PatientID = source.PatientID
            AND target.IsCurrent = 1
    )
)


-- ============================================================
-- 5. Insert new patients and new SCD2 versions
-- ============================================================

INSERT INTO dim.DimPatient
(
    PatientKey,
    PatientID,

    FirstName,
    LastName,

    BirthDate,

    Gender,
    Race,
    Ethnicity,

    MaritalStatus,

    Age,
    AgeGroup,


    ValidFrom,
    ValidTo,
    IsCurrent
)

SELECT
    @MaxPatientKey + RowNumber,

    PatientID,

    FirstName,
    LastName,

    BirthDate,

    Gender,
    Race,
    Ethnicity,

    MaritalStatus,

    Age,
    AgeGroup,


    @LoadTime,

    CAST(
        '9999-12-31 23:59:59.999999'
        AS DATETIME2(6)
    ),

    1

FROM PatientsToInsert;


-- ============================================================
-- 6. Summary
-- ============================================================

SELECT
    COUNT(*) AS TotalRows,

    COUNT(DISTINCT PatientID)
        AS UniquePatients,

    SUM(
        CASE
            WHEN IsCurrent = 1
            THEN 1
            ELSE 0
        END
    ) AS CurrentRows,

    SUM(
        CASE
            WHEN IsCurrent = 0
            THEN 1
            ELSE 0
        END
    ) AS HistoricalRows

FROM dim.DimPatient;


-- ============================================================
-- 7. Validate
--
-- Expected result:
--      zero rows
-- ============================================================

SELECT
    PatientID,
    COUNT(*) AS CurrentVersions

FROM dim.DimPatient

WHERE IsCurrent = 1

GROUP BY PatientID

HAVING COUNT(*) > 1;

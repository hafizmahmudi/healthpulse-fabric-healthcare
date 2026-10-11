-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load Patient

-- ============================================================
-- Load DimPatient staging table
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.patient
--
-- Target:
--   stg.DimPatient
-- ============================================================


-- ============================================================
-- 1. Clear current staging data
-- Equivalent to .mode("overwrite")
-- ============================================================

TRUNCATE TABLE stg.DimPatient;


-- ============================================================
-- 2. Load staging table from Silver
--
-- Excluded:
--   DeathDate
--   Passport
--   Suffix
--   _ingestion_timestamp
--   _source_system
--   _source_entity
--   _pipeline_run_id
-- ============================================================

INSERT INTO stg.DimPatient
(
    PatientID,
    FirstName,
    LastName,
    BirthDate,
    Gender,
    Race,
    Ethnicity,
    MaritalStatus,
    Age,
    AgeGroup
)

SELECT
    PatientID,
    FirstName,
    LastName,
    BirthDate,
    Gender,
    Race,
    Ethnicity,
    MaritalStatus,
    Age,
    AgeGroup

FROM [HP_02_LH_Health_Silver].[clinical].[patient];


-- ============================================================
-- 3. Verify staging load
-- ============================================================

SELECT
    COUNT(*) AS StagingRows
FROM stg.DimPatient;


SELECT TOP 10 *
FROM stg.DimPatient
ORDER BY PatientID;

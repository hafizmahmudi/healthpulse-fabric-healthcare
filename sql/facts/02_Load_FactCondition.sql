-- Source notebook: HP_07_03_NB_SilverToGold_Load_Fact
-- Section: Load FactCondition

-- ============================================================
-- FactCondition Load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.condition
--
-- Target:
--   fact.FactCondition
--
-- Grain:
--   One row per ConditionID
--
-- Lookups:
--   PatientID      -> DimPatient.PatientKey
--   ConditionCode  -> DimDiagnosis.DiagnosisKey
--   StartDate      -> DimDate.DateKey
--   StopDate       -> DimDate.DateKey
-- ============================================================


-- ============================================================
-- 1. Get current maximum ConditionFactKey
-- ============================================================

DECLARE @MaxConditionFactKey BIGINT;

SELECT
    @MaxConditionFactKey =
        ISNULL(MAX(ConditionFactKey), 0)

FROM fact.FactCondition;


-- ============================================================
-- 2. Prepare source and resolve dimension keys
-- ============================================================

WITH ConditionSource AS
(
    SELECT
        ConditionID,
        PatientID,
        ConditionCode,
        StartDate,
        StopDate

    FROM [HP_02_LH_Health_Silver].[clinical].[condition]

    WHERE ConditionID IS NOT NULL
),

ConditionPrepared AS
(
    SELECT
        c.ConditionID,


        -- ====================================================
        -- PatientKey
        --
        -- Priority:
        -- 1. Patient SCD2 version valid at StartDate
        -- 2. Current patient version
        -- 3. Latest historical patient version
        -- ====================================================

        p.PatientKey,


        -- ====================================================
        -- DiagnosisKey
        -- ====================================================

        d.DiagnosisKey,


        -- ====================================================
        -- Date Keys
        -- ====================================================

        startDate.DateKey AS StartDateKey,

        stopDate.DateKey AS StopDateKey,


        -- Each row represents one condition
        1 AS ConditionCount


    FROM ConditionSource AS c


    -- ========================================================
    -- Patient SCD Type 2 lookup
    -- ========================================================

    OUTER APPLY
    (
        SELECT TOP 1
            dp.PatientKey

        FROM dim.DimPatient AS dp

        WHERE
            dp.PatientID = c.PatientID

        ORDER BY
            CASE

                WHEN
                    c.StartDate IS NOT NULL

                    AND CAST(
                        c.StartDate
                        AS DATETIME2(6)
                    ) >= dp.ValidFrom

                    AND CAST(
                        c.StartDate
                        AS DATETIME2(6)
                    ) < dp.ValidTo

                THEN 0


                WHEN dp.IsCurrent = 1
                THEN 1


                ELSE 2

            END,

            dp.ValidFrom DESC

    ) AS p


    -- ========================================================
    -- Diagnosis lookup
    -- ========================================================

    LEFT JOIN dim.DimDiagnosis AS d

        ON d.DiagnosisCode =
           c.ConditionCode


    -- ========================================================
    -- Start Date lookup
    -- ========================================================

    LEFT JOIN dim.DimDate AS startDate

        ON startDate.FullDate =
           CAST(c.StartDate AS DATE)


    -- ========================================================
    -- Stop Date lookup
    --
    -- NULL StopDate is valid for active conditions.
    -- ========================================================

    LEFT JOIN dim.DimDate AS stopDate

        ON stopDate.FullDate =
           CAST(c.StopDate AS DATE)
),


-- ============================================================
-- 3. Find only new ConditionIDs
-- ============================================================

NewConditions AS
(
    SELECT
        source.ConditionID,

        source.PatientKey,
        source.DiagnosisKey,

        source.StartDateKey,
        source.StopDateKey,

        source.ConditionCount,

        ROW_NUMBER() OVER
        (
            ORDER BY source.ConditionID
        ) AS RowNumber

    FROM ConditionPrepared AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM fact.FactCondition AS target

        WHERE
            target.ConditionID =
            source.ConditionID
    )
)


-- ============================================================
-- 4. Insert new FactCondition rows
-- ============================================================

INSERT INTO fact.FactCondition
(
    ConditionFactKey,
    ConditionID,

    PatientKey,
    DiagnosisKey,

    StartDateKey,
    StopDateKey,

    ConditionCount
)

SELECT
    CAST(@MaxConditionFactKey AS BIGINT)
    +
    CAST(RowNumber AS BIGINT),

    ConditionID,

    PatientKey,
    DiagnosisKey,

    StartDateKey,
    StopDateKey,

    ConditionCount

FROM NewConditions;


-- ============================================================
-- 5. Update existing FactCondition rows
--
-- Allows corrected source values or late-arriving
-- dimensions to populate previously missing keys.
-- ============================================================

WITH ConditionSource AS
(
    SELECT
        ConditionID,
        PatientID,
        ConditionCode,
        StartDate,
        StopDate

    FROM [HP_02_LH_Health_Silver].[clinical].[condition]

    WHERE ConditionID IS NOT NULL
),

ConditionPrepared AS
(
    SELECT
        c.ConditionID,

        p.PatientKey,

        d.DiagnosisKey,

        startDate.DateKey AS StartDateKey,
        stopDate.DateKey AS StopDateKey

    FROM ConditionSource AS c


    -- ========================================================
    -- Patient SCD2 lookup
    -- ========================================================

    OUTER APPLY
    (
        SELECT TOP 1
            dp.PatientKey

        FROM dim.DimPatient AS dp

        WHERE
            dp.PatientID =
            c.PatientID

        ORDER BY
            CASE

                WHEN
                    c.StartDate IS NOT NULL

                    AND CAST(
                        c.StartDate
                        AS DATETIME2(6)
                    ) >= dp.ValidFrom

                    AND CAST(
                        c.StartDate
                        AS DATETIME2(6)
                    ) < dp.ValidTo

                THEN 0


                WHEN dp.IsCurrent = 1
                THEN 1


                ELSE 2

            END,

            dp.ValidFrom DESC

    ) AS p


    -- ========================================================
    -- Diagnosis lookup
    -- ========================================================

    LEFT JOIN dim.DimDiagnosis AS d

        ON d.DiagnosisCode =
           c.ConditionCode


    -- ========================================================
    -- Start Date
    -- ========================================================

    LEFT JOIN dim.DimDate AS startDate

        ON startDate.FullDate =
           CAST(c.StartDate AS DATE)


    -- ========================================================
    -- Stop Date
    -- ========================================================

    LEFT JOIN dim.DimDate AS stopDate

        ON stopDate.FullDate =
           CAST(c.StopDate AS DATE)
)


UPDATE target

SET
    target.PatientKey =
        source.PatientKey,

    target.DiagnosisKey =
        source.DiagnosisKey,

    target.StartDateKey =
        source.StartDateKey,

    target.StopDateKey =
        source.StopDateKey,

    target.ConditionCount = 1

FROM fact.FactCondition AS target

INNER JOIN ConditionPrepared AS source

    ON target.ConditionID =
       source.ConditionID;


-- ============================================================
-- 6. Validate missing dimension keys
-- ============================================================

SELECT
    COUNT_BIG(*) AS TotalConditions,

    SUM(
        CASE
            WHEN PatientKey IS NULL
            THEN CAST(1 AS BIGINT)
            ELSE CAST(0 AS BIGINT)
        END
    ) AS MissingPatientKey,

    SUM(
        CASE
            WHEN DiagnosisKey IS NULL
            THEN CAST(1 AS BIGINT)
            ELSE CAST(0 AS BIGINT)
        END
    ) AS MissingDiagnosisKey,

    SUM(
        CASE
            WHEN StartDateKey IS NULL
            THEN CAST(1 AS BIGINT)
            ELSE CAST(0 AS BIGINT)
        END
    ) AS MissingStartDateKey

FROM fact.FactCondition;


-- ============================================================
-- 7. Check duplicate ConditionIDs
--
-- Expected:
--   zero rows
-- ============================================================

SELECT
    ConditionID,
    COUNT_BIG(*) AS RowCounts

FROM fact.FactCondition

GROUP BY ConditionID

HAVING COUNT_BIG(*) > 1;

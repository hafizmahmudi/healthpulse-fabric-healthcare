-- Source notebook: HP_07_03_NB_SilverToGold_Load_Fact
-- Section: Load FactMedication

-- ============================================================
-- FactMedication Load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.medication
--
-- Target:
--   fact.FactMedication
--
-- Grain:
--   One row per MedicationID
--
-- Lookups:
--   PatientID      -> DimPatient.PatientKey
--   MedicationCode -> DimMedication.MedicationKey
--   StartDate      -> DimDate.DateKey
--   StopDate       -> DimDate.DateKey
-- ============================================================


-- ============================================================
-- 1. Get maximum MedicationFactKey
-- ============================================================

DECLARE @MaxMedicationFactKey BIGINT;

SELECT
    @MaxMedicationFactKey =
        ISNULL(MAX(MedicationFactKey), 0)

FROM fact.FactMedication;


-- ============================================================
-- 2. Prepare source and resolve dimension keys
-- ============================================================

WITH MedicationSource AS
(
    SELECT
        MedicationID,
        PatientID,
        MedicationCode,
        StartDate,
        StopDate

    FROM [HP_02_LH_Health_Silver].[clinical].[medication]

    WHERE MedicationID IS NOT NULL
),

MedicationPrepared AS
(
    SELECT
        m.MedicationID,


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
        -- MedicationKey
        -- ====================================================

        md.MedicationKey,


        -- ====================================================
        -- Date Keys
        -- ====================================================

        startDate.DateKey AS StartDateKey,

        stopDate.DateKey AS StopDateKey,


        -- One row represents one medication event
        1 AS MedicationCount


    FROM MedicationSource AS m


    -- ========================================================
    -- Patient SCD Type 2 lookup
    -- ========================================================

    OUTER APPLY
    (
        SELECT TOP 1
            dp.PatientKey

        FROM dim.DimPatient AS dp

        WHERE
            dp.PatientID = m.PatientID

        ORDER BY
            CASE

                -- Patient version valid when medication started
                WHEN
                    m.StartDate IS NOT NULL

                    AND CAST(
                        m.StartDate
                        AS DATETIME2(6)
                    ) >= dp.ValidFrom

                    AND CAST(
                        m.StartDate
                        AS DATETIME2(6)
                    ) < dp.ValidTo

                THEN 0


                -- Current patient version
                WHEN dp.IsCurrent = 1
                THEN 1


                -- Latest historical version
                ELSE 2

            END,

            dp.ValidFrom DESC

    ) AS p


    -- ========================================================
    -- Medication dimension lookup
    -- ========================================================

    LEFT JOIN dim.DimMedication AS md

        ON md.MedicationCode =
           m.MedicationCode


    -- ========================================================
    -- Start Date lookup
    -- ========================================================

    LEFT JOIN dim.DimDate AS startDate

        ON startDate.FullDate =
           CAST(m.StartDate AS DATE)


    -- ========================================================
    -- Stop Date lookup
    --
    -- NULL StopDate is valid for an active medication.
    -- ========================================================

    LEFT JOIN dim.DimDate AS stopDate

        ON stopDate.FullDate =
           CAST(m.StopDate AS DATE)
),


-- ============================================================
-- 3. Find only NEW MedicationIDs
--
-- Existing MedicationFactKey remains unchanged.
-- ============================================================

NewMedications AS
(
    SELECT
        source.MedicationID,

        source.PatientKey,
        source.MedicationKey,

        source.StartDateKey,
        source.StopDateKey,

        source.MedicationCount,

        ROW_NUMBER() OVER
        (
            ORDER BY source.MedicationID
        ) AS RowNumber

    FROM MedicationPrepared AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM fact.FactMedication AS target

        WHERE
            target.MedicationID =
            source.MedicationID
    )
)


-- ============================================================
-- 4. Insert new medication facts
-- ============================================================

INSERT INTO fact.FactMedication
(
    MedicationFactKey,
    MedicationID,

    PatientKey,
    MedicationKey,

    StartDateKey,
    StopDateKey,

    MedicationCount
)

SELECT
    CAST(@MaxMedicationFactKey AS BIGINT)
    +
    CAST(RowNumber AS BIGINT),

    MedicationID,

    PatientKey,
    MedicationKey,

    StartDateKey,
    StopDateKey,

    MedicationCount

FROM NewMedications;


-- ============================================================
-- 5. Update existing medication facts
--
-- Useful for:
--   late-arriving dimensions
--   corrected dates
--   previously missing dimension keys
-- ============================================================

WITH MedicationSource AS
(
    SELECT
        MedicationID,
        PatientID,
        MedicationCode,
        StartDate,
        StopDate

    FROM [HP_02_LH_Health_Silver].[clinical].[medication]

    WHERE MedicationID IS NOT NULL
),

MedicationPrepared AS
(
    SELECT
        m.MedicationID,

        p.PatientKey,

        md.MedicationKey,

        startDate.DateKey AS StartDateKey,

        stopDate.DateKey AS StopDateKey


    FROM MedicationSource AS m


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
            m.PatientID

        ORDER BY
            CASE

                WHEN
                    m.StartDate IS NOT NULL

                    AND CAST(
                        m.StartDate
                        AS DATETIME2(6)
                    ) >= dp.ValidFrom

                    AND CAST(
                        m.StartDate
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
    -- Medication lookup
    -- ========================================================

    LEFT JOIN dim.DimMedication AS md

        ON md.MedicationCode =
           m.MedicationCode


    -- ========================================================
    -- Start Date lookup
    -- ========================================================

    LEFT JOIN dim.DimDate AS startDate

        ON startDate.FullDate =
           CAST(m.StartDate AS DATE)


    -- ========================================================
    -- Stop Date lookup
    -- ========================================================

    LEFT JOIN dim.DimDate AS stopDate

        ON stopDate.FullDate =
           CAST(m.StopDate AS DATE)
)


UPDATE target

SET
    target.PatientKey =
        source.PatientKey,

    target.MedicationKey =
        source.MedicationKey,

    target.StartDateKey =
        source.StartDateKey,

    target.StopDateKey =
        source.StopDateKey,

    target.MedicationCount = 1

FROM fact.FactMedication AS target

INNER JOIN MedicationPrepared AS source

    ON target.MedicationID =
       source.MedicationID;

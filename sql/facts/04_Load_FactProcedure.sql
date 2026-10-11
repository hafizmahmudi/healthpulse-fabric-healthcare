-- Source notebook: HP_07_03_NB_SilverToGold_Load_Fact
-- Section: Load FactProcedure

-- ============================================================
-- FactProcedure Load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.procedure
--
-- Target:
--   fact.FactProcedure
--
-- Grain:
--   One row per ProcedureID
--
-- Lookups:
--   PatientID      -> DimPatient.PatientKey
--   ProcedureCode  -> DimProcedure.ProcedureKey
--   ProcedureDate  -> DimDate.DateKey
-- ============================================================


-- ============================================================
-- 1. Get current maximum ProcedureFactKey
-- ============================================================

DECLARE @MaxProcedureFactKey BIGINT;

SELECT
    @MaxProcedureFactKey =
        ISNULL(MAX(ProcedureFactKey), 0)

FROM fact.FactProcedure;


-- ============================================================
-- 2. Prepare source and resolve surrogate keys
-- ============================================================

WITH ProcedureSource AS
(
    SELECT
        ProcedureID,
        PatientID,
        ProcedureCode,
        ProcedureDate

    FROM [HP_02_LH_Health_Silver].[clinical].[procedure]

    WHERE ProcedureID IS NOT NULL
),

ProcedurePrepared AS
(
    SELECT
        pr.ProcedureID,


        -- ====================================================
        -- PatientKey
        --
        -- Priority:
        -- 1. Patient version valid at ProcedureDate
        -- 2. Current patient version
        -- 3. Latest historical patient version
        -- ====================================================

        p.PatientKey,


        -- ====================================================
        -- ProcedureKey
        -- ====================================================

        dp.ProcedureKey,


        -- ====================================================
        -- Procedure Date
        -- ====================================================

        dd.DateKey AS ProcedureDateKey,


        -- One row = one procedure
        1 AS ProcedureCount


    FROM ProcedureSource AS pr


    -- ========================================================
    -- Patient SCD Type 2 lookup
    -- ========================================================

    OUTER APPLY
    (
        SELECT TOP 1
            patient.PatientKey

        FROM dim.DimPatient AS patient

        WHERE
            patient.PatientID = pr.PatientID

        ORDER BY
            CASE

                WHEN
                    pr.ProcedureDate IS NOT NULL

                    AND CAST(
                        pr.ProcedureDate
                        AS DATETIME2(6)
                    ) >= patient.ValidFrom

                    AND CAST(
                        pr.ProcedureDate
                        AS DATETIME2(6)
                    ) < patient.ValidTo

                THEN 0


                WHEN patient.IsCurrent = 1
                THEN 1


                ELSE 2

            END,

            patient.ValidFrom DESC

    ) AS p


    -- ========================================================
    -- Procedure dimension lookup
    -- ========================================================

    LEFT JOIN dim.DimProcedure AS dp

        ON dp.ProcedureCode =
           pr.ProcedureCode


    -- ========================================================
    -- Date dimension lookup
    -- ========================================================

    LEFT JOIN dim.DimDate AS dd

        ON dd.FullDate =
           CAST(pr.ProcedureDate AS DATE)
),


-- ============================================================
-- 3. Find only NEW ProcedureIDs
--
-- Existing ProcedureFactKey values remain unchanged.
-- ============================================================

NewProcedures AS
(
    SELECT
        source.ProcedureID,

        source.PatientKey,
        source.ProcedureKey,

        source.ProcedureDateKey,

        source.ProcedureCount,

        ROW_NUMBER() OVER
        (
            ORDER BY source.ProcedureID
        ) AS RowNumber

    FROM ProcedurePrepared AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM fact.FactProcedure AS target

        WHERE
            target.ProcedureID =
            source.ProcedureID
    )
)


-- ============================================================
-- 4. Insert new FactProcedure rows
-- ============================================================

INSERT INTO fact.FactProcedure
(
    ProcedureFactKey,
    ProcedureID,

    PatientKey,
    ProcedureKey,

    ProcedureDateKey,

    ProcedureCount
)

SELECT
    CAST(@MaxProcedureFactKey AS BIGINT)
    +
    CAST(RowNumber AS BIGINT),

    ProcedureID,

    PatientKey,
    ProcedureKey,

    ProcedureDateKey,

    ProcedureCount

FROM NewProcedures;


-- ============================================================
-- 5. Update existing Procedure facts
--
-- Allows corrected / late-arriving dimension keys
-- without changing ProcedureFactKey.
-- ============================================================

WITH ProcedureSource AS
(
    SELECT
        ProcedureID,
        PatientID,
        ProcedureCode,
        ProcedureDate

    FROM [HP_02_LH_Health_Silver].[clinical].[procedure]

    WHERE ProcedureID IS NOT NULL
),

ProcedurePrepared AS
(
    SELECT
        pr.ProcedureID,

        p.PatientKey,

        dp.ProcedureKey,

        dd.DateKey AS ProcedureDateKey


    FROM ProcedureSource AS pr


    -- ========================================================
    -- Patient SCD2 lookup
    -- ========================================================

    OUTER APPLY
    (
        SELECT TOP 1
            patient.PatientKey

        FROM dim.DimPatient AS patient

        WHERE
            patient.PatientID =
            pr.PatientID

        ORDER BY
            CASE

                WHEN
                    pr.ProcedureDate IS NOT NULL

                    AND CAST(
                        pr.ProcedureDate
                        AS DATETIME2(6)
                    ) >= patient.ValidFrom

                    AND CAST(
                        pr.ProcedureDate
                        AS DATETIME2(6)
                    ) < patient.ValidTo

                THEN 0


                WHEN patient.IsCurrent = 1
                THEN 1


                ELSE 2

            END,

            patient.ValidFrom DESC

    ) AS p


    -- ========================================================
    -- Procedure lookup
    -- ========================================================

    LEFT JOIN dim.DimProcedure AS dp

        ON dp.ProcedureCode =
           pr.ProcedureCode


    -- ========================================================
    -- Procedure Date
    -- ========================================================

    LEFT JOIN dim.DimDate AS dd

        ON dd.FullDate =
           CAST(pr.ProcedureDate AS DATE)
)


UPDATE target

SET
    target.PatientKey =
        source.PatientKey,

    target.ProcedureKey =
        source.ProcedureKey,

    target.ProcedureDateKey =
        source.ProcedureDateKey,

    target.ProcedureCount = 1

FROM fact.FactProcedure AS target

INNER JOIN ProcedurePrepared AS source

    ON target.ProcedureID =
       source.ProcedureID;

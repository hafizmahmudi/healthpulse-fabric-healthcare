-- Source notebook: HP_07_03_NB_SilverToGold_Load_Fact
-- Section: Load FactObservation

-- ============================================================
-- FactObservation Load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.observation
--
-- Target:
--   fact.FactObservation
--
-- Grain:
--   One row per ObservationID
--
-- Lookups:
--   PatientID       -> DimPatient.PatientKey
--   ObservationDate -> DimDate.DateKey
--
-- Measures / attributes:
--   ObservationCode
--   ObservationDescription
--   ObservationValue
--   NumericValue
--   Units
--   ObservationCount = 1
-- ============================================================


-- ============================================================
-- 1. Get current maximum ObservationFactKey
-- ============================================================

DECLARE @MaxObservationFactKey BIGINT;

SELECT
    @MaxObservationFactKey =
        ISNULL(MAX(ObservationFactKey), 0)

FROM fact.FactObservation;


-- ============================================================
-- 2. Prepare source and resolve dimension keys
-- ============================================================

WITH ObservationSource AS
(
    SELECT
        ObservationID,
        PatientID,
        ObservationDate,

        ObservationCode,
        ObservationDescription,

        ObservationValue,
        NumericValue,
        Units

    FROM [HP_02_LH_Health_Silver].[clinical].[observation]

    WHERE ObservationID IS NOT NULL
),

ObservationPrepared AS
(
    SELECT
        o.ObservationID,


        -- ====================================================
        -- PatientKey
        --
        -- Priority:
        -- 1. Patient SCD2 version valid at ObservationDate
        -- 2. Current patient version
        -- 3. Latest historical patient version
        -- ====================================================

        p.PatientKey,


        -- ====================================================
        -- DateKey
        -- ====================================================

        d.DateKey,


        -- ====================================================
        -- Observation attributes
        -- ====================================================

        o.ObservationCode,
        o.ObservationDescription,

        o.ObservationValue,
        o.NumericValue,

        o.Units,


        -- One source row = one observation
        1 AS ObservationCount


    FROM ObservationSource AS o


    -- ========================================================
    -- Patient SCD Type 2 lookup
    -- ========================================================

    OUTER APPLY
    (
        SELECT TOP 1
            dp.PatientKey

        FROM dim.DimPatient AS dp

        WHERE
            dp.PatientID = o.PatientID

        ORDER BY
            CASE

                WHEN
                    o.ObservationDate IS NOT NULL

                    AND CAST(
                        o.ObservationDate
                        AS DATETIME2(6)
                    ) >= dp.ValidFrom

                    AND CAST(
                        o.ObservationDate
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
    -- Date dimension lookup
    -- ========================================================

    LEFT JOIN dim.DimDate AS d

        ON d.FullDate =
           CAST(o.ObservationDate AS DATE)
),


-- ============================================================
-- 3. Find only NEW ObservationIDs
--
-- Existing ObservationFactKey remains unchanged.
-- ============================================================

NewObservations AS
(
    SELECT
        source.ObservationID,

        source.PatientKey,
        source.DateKey,

        source.ObservationCode,
        source.ObservationDescription,

        source.ObservationValue,
        source.NumericValue,

        source.Units,

        source.ObservationCount,

        ROW_NUMBER() OVER
        (
            ORDER BY source.ObservationID
        ) AS RowNumber

    FROM ObservationPrepared AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM fact.FactObservation AS target

        WHERE
            target.ObservationID =
            source.ObservationID
    )
)


-- ============================================================
-- 4. Insert new observations
-- ============================================================

INSERT INTO fact.FactObservation
(
    ObservationFactKey,
    ObservationID,

    PatientKey,
    DateKey,

    ObservationCode,
    ObservationDescription,

    ObservationValue,
    NumericValue,

    Units,

    ObservationCount
)

SELECT
    CAST(@MaxObservationFactKey AS BIGINT)
    +
    CAST(RowNumber AS BIGINT),

    ObservationID,

    PatientKey,
    DateKey,

    ObservationCode,
    ObservationDescription,

    ObservationValue,
    NumericValue,

    Units,

    ObservationCount

FROM NewObservations;


-- ============================================================
-- 5. Update existing FactObservation rows
--
-- Handles:
--   corrected observations
--   late-arriving dimensions
--   previously missing dimension keys
--
-- ObservationFactKey remains unchanged.
-- ============================================================

WITH ObservationSource AS
(
    SELECT
        ObservationID,
        PatientID,
        ObservationDate,

        ObservationCode,
        ObservationDescription,

        ObservationValue,
        NumericValue,
        Units

    FROM [HP_02_LH_Health_Silver].[clinical].[observation]

    WHERE ObservationID IS NOT NULL
),

ObservationPrepared AS
(
    SELECT
        o.ObservationID,

        p.PatientKey,

        d.DateKey,

        o.ObservationCode,
        o.ObservationDescription,

        o.ObservationValue,
       CAST(
            o.NumericValue
            AS DECIMAL(18,4)
        ) AS NumericValue,

        o.Units


    FROM ObservationSource AS o


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
            o.PatientID

        ORDER BY
            CASE

                WHEN
                    o.ObservationDate IS NOT NULL

                    AND CAST(
                        o.ObservationDate
                        AS DATETIME2(6)
                    ) >= dp.ValidFrom

                    AND CAST(
                        o.ObservationDate
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
    -- Date lookup
    -- ========================================================

    LEFT JOIN dim.DimDate AS d

        ON d.FullDate =
           CAST(o.ObservationDate AS DATE)
)


UPDATE target

SET
    target.PatientKey =
        source.PatientKey,

    target.DateKey =
        source.DateKey,

    target.ObservationCode =
        source.ObservationCode,

    target.ObservationDescription =
        source.ObservationDescription,

    target.ObservationValue =
        source.ObservationValue,

    target.NumericValue =
        source.NumericValue,

    target.Units =
        source.Units,

    target.ObservationCount = 1

FROM fact.FactObservation AS target

INNER JOIN ObservationPrepared AS source

    ON target.ObservationID =
       source.ObservationID;

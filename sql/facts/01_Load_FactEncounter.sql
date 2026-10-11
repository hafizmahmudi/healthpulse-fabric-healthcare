-- Source notebook: HP_07_03_NB_SilverToGold_Load_Fact
-- Section: Load FactEncounter

-- ============================================================
-- FactEncounter Load - Improved Version
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.encounter
--
-- Target:
--   fact.FactEncounter
--
-- Grain:
--   One row per EncounterID
-- ============================================================


-- ============================================================
-- 1. Prepare source once
-- ============================================================

DROP TABLE IF EXISTS #EncounterPrepared;

CREATE TABLE #EncounterPrepared
(
    EncounterID          VARCHAR(100),
    PatientKey           BIGINT,
    DateKey              INT,

    EncounterCode        VARCHAR(100),
    EncounterDescription VARCHAR(1000),

    ReasonCode           VARCHAR(100),
    ReasonDescription    VARCHAR(1000),

    EncounterCount       INT
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN
);


-- ============================================================
-- 2. Deduplicate source and resolve keys
-- ============================================================

WITH EncounterRanked AS
(
    SELECT
        EncounterID,
        EncounterDate,
        PatientID,

        EncounterCode,
        EncounterDescription,

        ReasonCode,
        ReasonDescription,

        ROW_NUMBER() OVER
        (
            PARTITION BY EncounterID
            ORDER BY EncounterDate DESC
        ) AS rn

    FROM
        [HP_02_LH_Health_Silver].[clinical].[encounter]

    WHERE EncounterID IS NOT NULL
),

EncounterSource AS
(
    SELECT
        EncounterID,
        EncounterDate,
        PatientID,

        EncounterCode,
        EncounterDescription,

        ReasonCode,
        ReasonDescription

    FROM EncounterRanked

    WHERE rn = 1
)

INSERT INTO #EncounterPrepared
(
    EncounterID,
    PatientKey,
    DateKey,

    EncounterCode,
    EncounterDescription,

    ReasonCode,
    ReasonDescription,

    EncounterCount
)

SELECT
    e.EncounterID,

    -- ========================================================
    -- PatientKey
    --
    -- Priority:
    -- 1. SCD2 patient version valid at EncounterDate
    -- 2. Current patient version
    -- 3. Latest historical version
    -- ========================================================

    p.PatientKey,

    -- DateKey
    d.DateKey,

    e.EncounterCode,
    e.EncounterDescription,

    e.ReasonCode,
    e.ReasonDescription,

    1 AS EncounterCount

FROM EncounterSource AS e


OUTER APPLY
(
    SELECT TOP 1
        dp.PatientKey

    FROM dim.DimPatient AS dp

    WHERE
        dp.PatientID = e.PatientID

    ORDER BY
        CASE

            WHEN
                e.EncounterDate IS NOT NULL

                AND CAST(
                    e.EncounterDate AS DATETIME2(6)
                ) >= dp.ValidFrom

                AND CAST(
                    e.EncounterDate AS DATETIME2(6)
                ) < dp.ValidTo

            THEN 0

            WHEN dp.IsCurrent = 1
            THEN 1

            ELSE 2

        END,

        dp.ValidFrom DESC

) AS p


LEFT JOIN dim.DimDate AS d

    ON d.FullDate =
       CAST(e.EncounterDate AS DATE);



-- ============================================================
-- 3. Validate prepared source before modifying FactEncounter
-- ============================================================

SELECT
    COUNT_BIG(*) AS PreparedRows,

    SUM(
        CASE
            WHEN PatientKey IS NULL
            THEN CAST(1 AS BIGINT)
            ELSE CAST(0 AS BIGINT)
        END
    ) AS MissingPatientKey,

    SUM(
        CASE
            WHEN DateKey IS NULL
            THEN CAST(1 AS BIGINT)
            ELSE CAST(0 AS BIGINT)
        END
    ) AS MissingDateKey

FROM #EncounterPrepared;



-- ============================================================
-- 4. Load FactEncounter atomically
-- ============================================================

BEGIN TRY

    BEGIN TRANSACTION;


    -- ========================================================
    -- 4A. Update existing encounters
    --
    -- EncounterKey remains unchanged.
    -- Only update if something actually changed.
    -- ========================================================

    UPDATE target

    SET
        target.PatientKey           = source.PatientKey,
        target.DateKey              = source.DateKey,

        target.EncounterCode        = source.EncounterCode,
        target.EncounterDescription = source.EncounterDescription,

        target.ReasonCode           = source.ReasonCode,
        target.ReasonDescription    = source.ReasonDescription,

        target.EncounterCount       = 1

    FROM fact.FactEncounter AS target

    INNER JOIN #EncounterPrepared AS source

        ON target.EncounterID =
           source.EncounterID

    WHERE
           ISNULL(target.PatientKey, -1)
           <> ISNULL(source.PatientKey, -1)

        OR ISNULL(target.DateKey, -1)
           <> ISNULL(source.DateKey, -1)

        OR ISNULL(target.EncounterCode, '')
           <> ISNULL(source.EncounterCode, '')

        OR ISNULL(target.EncounterDescription, '')
           <> ISNULL(source.EncounterDescription, '')

        OR ISNULL(target.ReasonCode, '')
           <> ISNULL(source.ReasonCode, '')

        OR ISNULL(target.ReasonDescription, '')
           <> ISNULL(source.ReasonDescription, '');


    -- ========================================================
    -- 4B. Find current maximum EncounterKey
    -- ========================================================

    DECLARE @MaxEncounterKey BIGINT;

    SELECT
        @MaxEncounterKey =
            ISNULL(MAX(EncounterKey), 0)

    FROM fact.FactEncounter;


    -- ========================================================
    -- 4C. Insert only NEW encounters
    -- ========================================================

    WITH NewEncounters AS
    (
        SELECT
            source.EncounterID,
            source.PatientKey,
            source.DateKey,

            source.EncounterCode,
            source.EncounterDescription,

            source.ReasonCode,
            source.ReasonDescription,

            source.EncounterCount,

            ROW_NUMBER() OVER
            (
                ORDER BY source.EncounterID
            ) AS RowNumber

        FROM #EncounterPrepared AS source

        WHERE NOT EXISTS
        (
            SELECT 1

            FROM fact.FactEncounter AS target

            WHERE
                target.EncounterID =
                source.EncounterID
        )
    )

    INSERT INTO fact.FactEncounter
    (
        EncounterKey,
        EncounterID,

        PatientKey,
        DateKey,

        EncounterCode,
        EncounterDescription,

        ReasonCode,
        ReasonDescription,

        EncounterCount
    )

    SELECT
        CAST(@MaxEncounterKey AS BIGINT)
        +
        CAST(RowNumber AS BIGINT),

        EncounterID,

        PatientKey,
        DateKey,

        EncounterCode,
        EncounterDescription,

        ReasonCode,
        ReasonDescription,

        EncounterCount

    FROM NewEncounters;


    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;



-- ============================================================
-- 5. Final validation
-- ============================================================

SELECT
    COUNT_BIG(*) AS TotalEncounterFacts,

    COUNT_BIG(DISTINCT EncounterID)
        AS UniqueEncounterIDs,

    SUM(
        CAST(EncounterCount AS BIGINT)
    ) AS TotalEncounterCount

FROM fact.FactEncounter;


-- ============================================================
-- 6. Duplicate check
--
-- Expected: zero rows
-- ============================================================

SELECT
    EncounterID,
    COUNT_BIG(*) AS RowCounts

FROM fact.FactEncounter

GROUP BY EncounterID

HAVING COUNT_BIG(*) > 1;


-- ============================================================
-- 7. Missing key check
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN PatientKey IS NULL
            THEN CAST(1 AS BIGINT)
            ELSE CAST(0 AS BIGINT)
        END
    ) AS MissingPatientKey,

    SUM(
        CASE
            WHEN DateKey IS NULL
            THEN CAST(1 AS BIGINT)
            ELSE CAST(0 AS BIGINT)
        END
    ) AS MissingDateKey

FROM fact.FactEncounter;


DROP TABLE IF EXISTS #EncounterPrepared;

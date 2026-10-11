-- Source notebook: HP_07_03_NB_SilverToGold_Load_Fact
-- Section: FactReadmission

-- ============================================================
-- FactReadmission
--
-- TEMPORARY / PROXY METHOD
--
-- Current source does not have:
--   AdmissionDate
--   DischargeDate
--   EncounterClass
--
-- Therefore EncounterDate is used as a proxy.
--
-- Grain:
--   One row per index encounter that has a later encounter
-- ============================================================


-- ============================================================
-- 1. Find current maximum ReadmissionKey
-- ============================================================

DECLARE @MaxReadmissionKey BIGINT;

SELECT
    @MaxReadmissionKey =
        ISNULL(MAX(ReadmissionKey), 0)

FROM fact.FactReadmission;


-- ============================================================
-- 2. Order encounters for each patient
--
-- LEAD() finds the patient's next encounter
-- ============================================================

WITH EncounterSequence AS
(
    SELECT
        e.PatientKey,

        e.EncounterKey
            AS IndexEncounterKey,
        d.DateKey,

        d.FullDate
            AS DischargeDate,

        LEAD(e.EncounterKey) OVER
        (
            PARTITION BY e.PatientKey
            ORDER BY
                d.FullDate,
                e.EncounterKey
        ) AS ReadmissionEncounterKey,

        LEAD(d.FullDate) OVER
        (
            PARTITION BY e.PatientKey
            ORDER BY
                d.FullDate,
                e.EncounterKey
        ) AS ReadmissionDate

    FROM fact.FactEncounter AS e

    INNER JOIN dim.DimDate AS d
        ON d.DateKey = e.DateKey

    WHERE
        e.PatientKey IS NOT NULL
        AND e.DateKey IS NOT NULL
),


-- ============================================================
-- 3. Calculate days until next encounter
-- ============================================================

ReadmissionSource AS
(
    SELECT
        PatientKey,
        IndexEncounterKey,
        ReadmissionEncounterKey,
        DateKey,
        DischargeDate,
        ReadmissionDate,

        DATEDIFF(
            DAY,
            DischargeDate,
            ReadmissionDate
        ) AS DaysToReadmission

    FROM EncounterSequence

    WHERE
        ReadmissionEncounterKey IS NOT NULL
),


-- ============================================================
-- 4. Keep encounters with a later encounter
--
-- We exclude same-day encounters.
-- ============================================================

ReadmissionPrepared AS
(
    SELECT
        PatientKey,
        IndexEncounterKey,
        ReadmissionEncounterKey,
        DateKey,
        DischargeDate,
        ReadmissionDate,

        DaysToReadmission,

        CAST(
            CASE
                WHEN DaysToReadmission
                     BETWEEN 1 AND 30
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS IsReadmission30Day

    FROM ReadmissionSource

    WHERE DaysToReadmission > 0
),


-- ============================================================
-- 5. Insert only new index/readmission pairs
-- ============================================================

NewReadmissions AS
(
    SELECT
        source.*,

        ROW_NUMBER() OVER
        (
            ORDER BY
                source.PatientKey,
                source.DischargeDate,
                source.IndexEncounterKey
        ) AS RowNumber

    FROM ReadmissionPrepared AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM fact.FactReadmission AS target

        WHERE
            target.IndexEncounterKey =
                source.IndexEncounterKey

            AND target.ReadmissionEncounterKey =
                source.ReadmissionEncounterKey
    )
)


INSERT INTO fact.FactReadmission
(
    ReadmissionKey,
    DateKey,
    PatientKey,

    IndexEncounterKey,
    ReadmissionEncounterKey,

    DischargeDate,
    ReadmissionDate,

    DaysToReadmission,

    IsReadmission30Day
)

SELECT
    CAST(@MaxReadmissionKey AS BIGINT)
    +
    CAST(RowNumber AS BIGINT),
    DateKey,
    PatientKey,

    IndexEncounterKey,
    ReadmissionEncounterKey,

    DischargeDate,
    ReadmissionDate,

    DaysToReadmission,

    IsReadmission30Day

FROM NewReadmissions;

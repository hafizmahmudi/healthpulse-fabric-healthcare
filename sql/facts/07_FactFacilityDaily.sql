-- Source notebook: HP_07_03_NB_SilverToGold_Load_Fact
-- Section: FactFacilityDaily

-- ============================================================
-- FactFacilityDaily Load
--
-- Grain:
--   One row per FacilityKey + DateKey
--
-- Sources:
--   fact.FactEncounter
--   fact.FactReadmission
--
-- Target:
--   fact.FactFacilityDaily
--
-- Cost definition:
--   TotalEncounterCost   = SUM(BaseEncounterCost)
--   AverageEncounterCost = AVG(BaseEncounterCost)
-- ============================================================


-- ============================================================
-- 1. UPDATE EXISTING FACILITY-DAY ROWS
-- ============================================================

WITH EncounterDaily AS
(
    SELECT
        e.DateKey,
        e.FacilityKey,


        -- ====================================================
        -- Distinct patients seen at the facility that day
        -- ====================================================

        COUNT_BIG(DISTINCT e.PatientKey)
            AS PatientCount,


        -- ====================================================
        -- Total encounters
        -- ====================================================

        COUNT_BIG(*)
            AS EncounterCount,


        -- ====================================================
        -- Emergency visits
        -- ====================================================

        SUM(
            CASE
                WHEN LOWER(e.EncounterClass) = 'emergency'
                THEN CAST(1 AS BIGINT)
                ELSE CAST(0 AS BIGINT)
            END
        ) AS EmergencyVisitCount,


        -- ====================================================
        -- Inpatient visits
        -- ====================================================

        SUM(
            CASE
                WHEN LOWER(e.EncounterClass) = 'inpatient'
                THEN CAST(1 AS BIGINT)
                ELSE CAST(0 AS BIGINT)
            END
        ) AS InpatientVisitCount,


        -- ====================================================
        -- Outpatient / ambulatory visits
        -- ====================================================

        SUM(
            CASE
                WHEN LOWER(e.EncounterClass)
                     IN ('outpatient', 'ambulatory')
                THEN CAST(1 AS BIGINT)
                ELSE CAST(0 AS BIGINT)
            END
        ) AS OutpatientVisitCount,


        -- ====================================================
        -- Average Length of Stay
        -- ====================================================

        AVG(
            CAST(
                e.LengthOfStayDays
                AS FLOAT
            )
        ) AS AverageLengthOfStay,


        -- ====================================================
        -- Total Encounter Cost
        --
        -- Sum of BaseEncounterCost
        -- ====================================================

        SUM(
            CAST(
                ISNULL(e.BaseEncounterCost, 0)
                AS DECIMAL(18,2)
            )
        ) AS TotalEncounterCost,


        -- ====================================================
        -- Average Encounter Cost
        -- ====================================================

        AVG(
            CAST(
                e.BaseEncounterCost
                AS DECIMAL(18,2)
            )
        ) AS AverageEncounterCost


    FROM fact.FactEncounter AS e

    WHERE
        e.DateKey IS NOT NULL
        AND e.FacilityKey IS NOT NULL

    GROUP BY
        e.DateKey,
        e.FacilityKey
),


-- ============================================================
-- 2. Calculate 30-day readmissions
--
-- Readmission is assigned to the facility/date of the
-- readmission encounter.
-- ============================================================

ReadmissionDaily AS
(
    SELECT
        e.DateKey,
        e.FacilityKey,

        COUNT_BIG(*)
            AS ReadmissionCount

    FROM fact.FactReadmission AS r

    INNER JOIN fact.FactEncounter AS e

        ON e.EncounterKey =
           r.ReadmissionEncounterKey

    WHERE
        r.IsReadmission30Day = 1

        AND e.DateKey IS NOT NULL
        AND e.FacilityKey IS NOT NULL

    GROUP BY
        e.DateKey,
        e.FacilityKey
),


-- ============================================================
-- 3. Combine Encounter + Readmission metrics
-- ============================================================

FacilityDailySource AS
(
    SELECT
        e.DateKey,
        e.FacilityKey,

        e.PatientCount,
        e.EncounterCount,

        e.EmergencyVisitCount,
        e.InpatientVisitCount,
        e.OutpatientVisitCount,

        ISNULL(
            r.ReadmissionCount,
            CAST(0 AS BIGINT)
        ) AS ReadmissionCount,

        e.AverageLengthOfStay,

        e.TotalEncounterCost,
        e.AverageEncounterCost

    FROM EncounterDaily AS e

    LEFT JOIN ReadmissionDaily AS r

        ON r.DateKey =
           e.DateKey

        AND r.FacilityKey =
            e.FacilityKey
)


-- ============================================================
-- 4. Update rows already in FactFacilityDaily
-- ============================================================

UPDATE target

SET
    target.PatientCount =
        source.PatientCount,

    target.EncounterCount =
        source.EncounterCount,

    target.EmergencyVisitCount =
        source.EmergencyVisitCount,

    target.InpatientVisitCount =
        source.InpatientVisitCount,

    target.OutpatientVisitCount =
        source.OutpatientVisitCount,

    target.ReadmissionCount =
        source.ReadmissionCount,

    target.AverageLengthOfStay =
        source.AverageLengthOfStay,

    target.TotalEncounterCost =
        source.TotalEncounterCost,

    target.AverageEncounterCost =
        source.AverageEncounterCost


FROM fact.FactFacilityDaily AS target

INNER JOIN FacilityDailySource AS source

    ON target.DateKey =
       source.DateKey

    AND target.FacilityKey =
        source.FacilityKey;



-- ============================================================
-- 5. Get maximum FacilityDailyKey
-- ============================================================

DECLARE @MaxFacilityDailyKey BIGINT;

SELECT
    @MaxFacilityDailyKey =
        ISNULL(MAX(FacilityDailyKey), 0)

FROM fact.FactFacilityDaily;



-- ============================================================
-- 6. Recalculate source for INSERT
-- ============================================================

WITH EncounterDaily AS
(
    SELECT
        e.DateKey,
        e.FacilityKey,


        COUNT_BIG(DISTINCT e.PatientKey)
            AS PatientCount,


        COUNT_BIG(*)
            AS EncounterCount,


        SUM(
            CASE
                WHEN LOWER(e.EncounterClass) = 'emergency'
                THEN CAST(1 AS BIGINT)
                ELSE CAST(0 AS BIGINT)
            END
        ) AS EmergencyVisitCount,


        SUM(
            CASE
                WHEN LOWER(e.EncounterClass) = 'inpatient'
                THEN CAST(1 AS BIGINT)
                ELSE CAST(0 AS BIGINT)
            END
        ) AS InpatientVisitCount,


        SUM(
            CASE
                WHEN LOWER(e.EncounterClass)
                     IN ('outpatient', 'ambulatory')
                THEN CAST(1 AS BIGINT)
                ELSE CAST(0 AS BIGINT)
            END
        ) AS OutpatientVisitCount,


        AVG(
            CAST(
                e.LengthOfStayDays
                AS FLOAT
            )
        ) AS AverageLengthOfStay,


        SUM(
            CAST(
                ISNULL(e.BaseEncounterCost, 0)
                AS DECIMAL(18,2)
            )
        ) AS TotalEncounterCost,


        AVG(
            CAST(
                e.BaseEncounterCost
                AS DECIMAL(18,2)
            )
        ) AS AverageEncounterCost


    FROM fact.FactEncounter AS e

    WHERE
        e.DateKey IS NOT NULL
        AND e.FacilityKey IS NOT NULL

    GROUP BY
        e.DateKey,
        e.FacilityKey
),


-- ============================================================
-- 7. Calculate daily readmissions
-- ============================================================

ReadmissionDaily AS
(
    SELECT
        e.DateKey,
        e.FacilityKey,

        COUNT_BIG(*)
            AS ReadmissionCount

    FROM fact.FactReadmission AS r

    INNER JOIN fact.FactEncounter AS e

        ON e.EncounterKey =
           r.ReadmissionEncounterKey

    WHERE
        r.IsReadmission30Day = 1

        AND e.DateKey IS NOT NULL
        AND e.FacilityKey IS NOT NULL

    GROUP BY
        e.DateKey,
        e.FacilityKey
),


-- ============================================================
-- 8. Combine metrics
-- ============================================================

FacilityDailySource AS
(
    SELECT
        e.DateKey,
        e.FacilityKey,

        e.PatientCount,
        e.EncounterCount,

        e.EmergencyVisitCount,
        e.InpatientVisitCount,
        e.OutpatientVisitCount,

        ISNULL(
            r.ReadmissionCount,
            CAST(0 AS BIGINT)
        ) AS ReadmissionCount,

        e.AverageLengthOfStay,

        e.TotalEncounterCost,
        e.AverageEncounterCost

    FROM EncounterDaily AS e

    LEFT JOIN ReadmissionDaily AS r

        ON r.DateKey =
           e.DateKey

        AND r.FacilityKey =
            e.FacilityKey
),


-- ============================================================
-- 9. Identify new Facility + Date combinations
-- ============================================================

NewFacilityDays AS
(
    SELECT
        source.DateKey,
        source.FacilityKey,

        source.PatientCount,
        source.EncounterCount,

        source.EmergencyVisitCount,
        source.InpatientVisitCount,
        source.OutpatientVisitCount,

        source.ReadmissionCount,

        source.AverageLengthOfStay,

        source.TotalEncounterCost,
        source.AverageEncounterCost,

        ROW_NUMBER() OVER
        (
            ORDER BY
                source.DateKey,
                source.FacilityKey
        ) AS RowNumber

    FROM FacilityDailySource AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM fact.FactFacilityDaily AS target

        WHERE
            target.DateKey =
                source.DateKey

            AND target.FacilityKey =
                source.FacilityKey
    )
)


-- ============================================================
-- 10. Insert new Facility-Day rows
-- ============================================================

INSERT INTO fact.FactFacilityDaily
(
    FacilityDailyKey,

    DateKey,
    FacilityKey,

    PatientCount,
    EncounterCount,

    EmergencyVisitCount,
    InpatientVisitCount,
    OutpatientVisitCount,

    ReadmissionCount,

    AverageLengthOfStay,

    TotalEncounterCost,
    AverageEncounterCost
)

SELECT
    CAST(@MaxFacilityDailyKey AS BIGINT)
    +
    CAST(RowNumber AS BIGINT),

    DateKey,
    FacilityKey,

    PatientCount,
    EncounterCount,

    EmergencyVisitCount,
    InpatientVisitCount,
    OutpatientVisitCount,

    ReadmissionCount,

    AverageLengthOfStay,

    TotalEncounterCost,
    AverageEncounterCost

FROM NewFacilityDays;



-- ============================================================
-- 11. Summary
-- ============================================================

SELECT
    COUNT_BIG(*) AS TotalFacilityDayRows,

    COUNT_BIG(DISTINCT FacilityKey)
        AS TotalFacilities,

    SUM(
        CAST(PatientCount AS BIGINT)
    ) AS TotalDailyPatientCount,

    SUM(
        CAST(EncounterCount AS BIGINT)
    ) AS TotalEncounters,

    SUM(
        CAST(EmergencyVisitCount AS BIGINT)
    ) AS EmergencyVisits,

    SUM(
        CAST(InpatientVisitCount AS BIGINT)
    ) AS InpatientVisits,

    SUM(
        CAST(OutpatientVisitCount AS BIGINT)
    ) AS OutpatientVisits,

    SUM(
        CAST(ReadmissionCount AS BIGINT)
    ) AS Readmissions,

    SUM(
        CAST(TotalEncounterCost AS DECIMAL(18,2))
    ) AS TotalEncounterCost

FROM fact.FactFacilityDaily;



-- ============================================================
-- 12. Validate grain
--
-- Expected result:
--   ZERO rows
--
-- There must be only one record for each:
--   DateKey + FacilityKey
-- ============================================================

SELECT
    DateKey,
    FacilityKey,

    COUNT_BIG(*) AS RowCounts

FROM fact.FactFacilityDaily

GROUP BY
    DateKey,
    FacilityKey

HAVING COUNT_BIG(*) > 1;

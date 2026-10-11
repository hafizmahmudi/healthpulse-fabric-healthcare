-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: LOAD DimDate

-- ============================================================
-- DimDate load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.encounter
--
-- Target:
--   dim.DimDate
-- ============================================================


-- ============================================================
-- 1. Get Min and Max Encounter Date
-- ============================================================

DECLARE @StartDate DATE;
DECLARE @EndDate   DATE;

SELECT
    @StartDate = MIN(CAST(EncounterDate AS DATE)),
    @EndDate   = MAX(CAST(EncounterDate AS DATE))

FROM [HP_02_LH_Health_Silver].[clinical].[encounter];


-- ============================================================
-- 2. Generate all dates between Min and Max
-- ============================================================

WITH DateSource AS
(
    SELECT
        DATEADD(
            DAY,
            value,
            @StartDate
        ) AS FullDate

    FROM GENERATE_SERIES
    (
        0,
        DATEDIFF(
            DAY,
            @StartDate,
            @EndDate
        )
    )
),

DimDateSource AS
(
    SELECT
        -- Example:
        -- 2026-10-05 -> 20261005
        CAST(
            CONVERT(
                VARCHAR(8),
                FullDate,
                112
            )
            AS INT
        ) AS DateKey,

        FullDate,

        DAY(
            FullDate
        ) AS DayNumber,

        DATENAME(
            WEEKDAY,
            FullDate
        ) AS DayName,

        DATEPART(
            WEEKDAY,
            FullDate
        ) AS DayOfWeekNumber,

        DATEPART(
            DAYOFYEAR,
            FullDate
        ) AS DayOfYear,

        DATEPART(
            ISO_WEEK,
            FullDate
        ) AS WeekNumber,

        MONTH(
            FullDate
        ) AS MonthNumber,

        DATENAME(
            MONTH,
            FullDate
        ) AS MonthName,

        DATEPART(
            QUARTER,
            FullDate
        ) AS QuarterNumber,

        CONCAT(
            'Q',
            DATEPART(
                QUARTER,
                FullDate
            )
        ) AS QuarterName,

        YEAR(
            FullDate
        ) AS YearNumber,

        CONCAT(
            YEAR(FullDate),
            '-',
            RIGHT(
                '0' +
                CAST(
                    MONTH(FullDate)
                    AS VARCHAR(2)
                ),
                2
            )
        ) AS YearMonth,

        CAST(
            CASE
                WHEN DATENAME(
                    WEEKDAY,
                    FullDate
                )
                IN (
                    'Saturday',
                    'Sunday'
                )
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS IsWeekend

    FROM DateSource
)


-- ============================================================
-- 3. Merge into DimDate
--
-- DateKey is the business/primary matching key.
-- ============================================================

MERGE INTO dim.DimDate AS target

USING DimDateSource AS source

ON target.DateKey = source.DateKey


-- ============================================================
-- Update existing dates
-- ============================================================

WHEN MATCHED THEN

UPDATE SET

    target.FullDate        = source.FullDate,
    target.DayNumber       = source.DayNumber,
    target.DayName         = source.DayName,
    target.DayOfWeekNumber = source.DayOfWeekNumber,
    target.DayOfYear       = source.DayOfYear,
    target.WeekNumber      = source.WeekNumber,
    target.MonthNumber     = source.MonthNumber,
    target.MonthName       = source.MonthName,
    target.QuarterNumber   = source.QuarterNumber,
    target.QuarterName     = source.QuarterName,
    target.YearNumber      = source.YearNumber,
    target.YearMonth       = source.YearMonth,
    target.IsWeekend       = source.IsWeekend


-- ============================================================
-- Insert new dates
-- ============================================================

WHEN NOT MATCHED BY TARGET THEN

INSERT
(
    DateKey,
    FullDate,

    DayNumber,
    DayName,

    DayOfWeekNumber,
    DayOfYear,

    WeekNumber,

    MonthNumber,
    MonthName,

    QuarterNumber,
    QuarterName,

    YearNumber,
    YearMonth,

    IsWeekend
)

VALUES
(
    source.DateKey,
    source.FullDate,

    source.DayNumber,
    source.DayName,

    source.DayOfWeekNumber,
    source.DayOfYear,

    source.WeekNumber,

    source.MonthNumber,
    source.MonthName,

    source.QuarterNumber,
    source.QuarterName,

    source.YearNumber,
    source.YearMonth,

    source.IsWeekend
);


-- ============================================================
-- 4. Verify
-- ============================================================

SELECT
    COUNT(*) AS TotalRows,
    MIN(FullDate) AS MinDate,
    MAX(FullDate) AS MaxDate

FROM dim.DimDate;

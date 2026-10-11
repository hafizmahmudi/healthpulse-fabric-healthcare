-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimDate

-- dim.DimDate
IF OBJECT_ID('dim.DimDate', 'U') IS NULL
BEGIN
    CREATE TABLE dim.DimDate
    (
        DateKey             INT          NOT NULL,
        FullDate            DATE         NOT NULL,

        DayNumber           INT,
        DayName             VARCHAR(20),

        DayOfWeekNumber     INT,
        DayOfYear           INT,

        WeekNumber          INT,

        MonthNumber         INT,
        MonthName           VARCHAR(20),

        QuarterNumber       INT,
        QuarterName         VARCHAR(10),

        YearNumber          INT,

        YearMonth           VARCHAR(7),

        IsWeekend           BIT
    );
END;

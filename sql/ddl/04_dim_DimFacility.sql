-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimFacility

IF OBJECT_ID('dim.DimFacility','U') IS NULL
BEGIN

    CREATE TABLE dim.DimFacility
    (
        FacilityKey         BIGINT        NOT NULL,

        FacilityID          VARCHAR(100)  NOT NULL,
        FacilityName        VARCHAR(500),

        Address             VARCHAR(500),
        City                VARCHAR(200),
        State               VARCHAR(50),
        ZipCode             VARCHAR(20),

        Latitude            FLOAT,
        Longitude           FLOAT,

        Phone               VARCHAR(100),

        Revenue             DECIMAL(18,2),
        Utilization         FLOAT,

        -- SCD Type 2
        ValidFrom           DATETIME2(6)  NOT NULL,
        ValidTo             DATETIME2(6)  NOT NULL,
        IsCurrent           BIT           NOT NULL
    );
END;

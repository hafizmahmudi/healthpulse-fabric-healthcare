-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimProvider

IF OBJECT_ID('dim.DimProvider','U') IS NULL
BEGIN

    CREATE TABLE dim.DimProvider
    (
        ProviderKey         BIGINT        NOT NULL,

        ProviderID          VARCHAR(100)  NOT NULL,
        ProviderName        VARCHAR(500),

        FacilityID          VARCHAR(100),

        Gender              VARCHAR(50),
        Specialty           VARCHAR(300),

        Address             VARCHAR(500),
        City                VARCHAR(200),
        State               VARCHAR(50),
        ZipCode             VARCHAR(20),

        Latitude            FLOAT,
        Longitude           FLOAT,

        -- SCD Type 2
        ValidFrom           DATETIME2(6)  NOT NULL,
        ValidTo             DATETIME2(6)  NOT NULL,
        IsCurrent           BIT           NOT NULL
    );
END;

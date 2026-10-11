-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimPayer

IF OBJECT_ID('dim.DimPayer','U') IS NULL
BEGIN

    CREATE TABLE dim.DimPayer
    (
        PayerKey              BIGINT        NOT NULL,

        PayerID               VARCHAR(100)  NOT NULL,
        PayerName             VARCHAR(500),

        Ownership             VARCHAR(200),

        Address               VARCHAR(500),
        City                  VARCHAR(200),
        State                 VARCHAR(100),
        ZipCode               VARCHAR(20),

        Phone                 VARCHAR(100),

                -- SCD Type 2
        ValidFrom           DATETIME2(6)  NOT NULL,
        ValidTo             DATETIME2(6)  NOT NULL,
        IsCurrent           BIT           NOT NULL
    );
END;

-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimPatient

IF OBJECT_ID('dim.DimPatient','U') IS NULL
BEGIN
    CREATE TABLE dim.DimPatient
    (
        -- Warehouse surrogate key
        PatientKey          BIGINT        NOT NULL,

        -- Source/business key
        PatientID           VARCHAR(100)  NOT NULL,

        FirstName           VARCHAR(200),
        LastName            VARCHAR(200),
        MaritalStatus       VARCHAR(55),

        BirthDate           DATE,
        DeathDate           DATE,

        Gender              VARCHAR(50),
        Race                VARCHAR(100),
        Ethnicity           VARCHAR(100),

        Age                 INT,
        AgeGroup            VARCHAR(50),

        -- SCD Type 2
        ValidFrom           DATETIME2(6)  NOT NULL,
        ValidTo             DATETIME2(6)  NOT NULL,
        IsCurrent           BIT           NOT NULL
    );
END;

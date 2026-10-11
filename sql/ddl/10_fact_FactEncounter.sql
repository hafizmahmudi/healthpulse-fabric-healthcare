-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: fact.FactEncounter

IF object_id('fact.FactEncounter','u') IS NULL
BEGIN
    CREATE TABLE fact.FactEncounter
    (
        -- Warehouse surrogate key
        EncounterKey          BIGINT        NOT NULL,

        -- Source ID
        EncounterID           VARCHAR(100)  NOT NULL,

        -- Dimension keys
        PatientKey            BIGINT,
        DateKey               INT,

        FacilityKey           BIGINT,
        ProviderKey           BIGINT,
        PayerKey              BIGINT,

        -- Encounter information
        EncounterCode         VARCHAR(100),
        EncounterDescription  VARCHAR(1000),

        ReasonCode            VARCHAR(100),
        ReasonDescription     VARCHAR(1000),

        -- These become usable when richer encounter
        -- data is available
        EncounterClass        VARCHAR(100),

        StartTime             DATETIME2(6),
        EndTime               DATETIME2(6),

        LengthOfStayDays      FLOAT,

        BaseEncounterCost     DECIMAL(18,2),
        TotalClaimCost        DECIMAL(18,2),
        PayerCoverage         DECIMAL(18,2),

        -- Additive measure
        EncounterCount        INT
    );
END;

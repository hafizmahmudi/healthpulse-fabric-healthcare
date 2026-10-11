-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: fact.FactFacilityDaily

IF OBJECT_ID('fact.FactFacilityDaily','U') IS NULL
BEGIN
    CREATE TABLE fact.FactFacilityDaily
    (
        FacilityDailyKey       BIGINT        NOT NULL,

        DateKey                INT           NOT NULL,
        FacilityKey            BIGINT        NOT NULL,

        PatientCount           BIGINT,
        EncounterCount         BIGINT,

        EmergencyVisitCount    BIGINT,
        InpatientVisitCount    BIGINT,
        OutpatientVisitCount   BIGINT,

        ReadmissionCount       BIGINT,

        AverageLengthOfStay    FLOAT,

        TotalEncounterCost     DECIMAL(18,2),

        AverageEncounterCost   DECIMAL(18,2)
    );
END;

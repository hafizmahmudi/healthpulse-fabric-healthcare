-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: fact.FactReadmission

IF OBJECT_ID('fact.FactReadmission','U') IS NULL
BEGIN

    CREATE TABLE fact.FactReadmission
    (
        ReadmissionKey           BIGINT       NOT NULL,

        PatientKey               BIGINT       NOT NULL,

        IndexEncounterKey        BIGINT       NOT NULL,
        DateKey                INT,

        ReadmissionEncounterKey  BIGINT,

        DischargeDate            DATE,

        ReadmissionDate          DATE,

        DaysToReadmission        INT,

        IsReadmission30Day       BIT
    );
END;

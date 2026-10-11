-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: 

IF OBJECT_ID('fact.FactMedication','u') IS NULL
BEGIN
    CREATE TABLE fact.FactMedication
    (
        MedicationFactKey    BIGINT        NOT NULL,

        MedicationID         VARCHAR(100),

        PatientKey           BIGINT,
        -- EncounterKey         BIGINT,
        MedicationKey        BIGINT,

        StartDateKey         INT,
        StopDateKey          INT,

        MedicationCount      INT
    );
END;

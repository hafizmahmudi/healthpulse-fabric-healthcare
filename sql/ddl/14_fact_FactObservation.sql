-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: fact.FactObservation

IF OBJECT_ID('fact.FactObservation','U') IS NULL
BEGIN
    CREATE TABLE fact.FactObservation
    (
        ObservationFactKey     BIGINT        NOT NULL,

        ObservationID          VARCHAR(100),

        PatientKey             BIGINT,
        -- EncounterKey           BIGINT,
        DateKey                INT,

        ObservationCode        VARCHAR(100),
        ObservationDescription VARCHAR(1000),

        ObservationValue       VARCHAR(500),
        NumericValue           FLOAT,

        Units                  VARCHAR(100),

        ObservationCount       INT
    );

END;

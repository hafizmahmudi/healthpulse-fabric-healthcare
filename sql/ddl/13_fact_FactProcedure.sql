-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: fact.FactProcedure

IF OBJECT_ID('fact.FactProcedure','U') IS NULL
BEGIN

    CREATE TABLE fact.FactProcedure
    (
        ProcedureFactKey     BIGINT        NOT NULL,

        ProcedureID          VARCHAR(100),

        PatientKey           BIGINT,
        -- EncounterKey         BIGINT,
        ProcedureKey         BIGINT,

        ProcedureDateKey     INT,

        ProcedureCount       INT
    );
END;

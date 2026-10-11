-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: fact.FactCondition

IF OBJECT_ID('fact.FactCondition','U') IS NULL
BEGIN
    CREATE TABLE fact.FactCondition
    (
        ConditionFactKey     BIGINT        NOT NULL,

        ConditionID          VARCHAR(100),

        PatientKey           BIGINT,
        -- EncounterKey         BIGINT,
        DiagnosisKey         BIGINT,

        StartDateKey         INT,
        StopDateKey          INT,

        ConditionCount       INT
    );
END;

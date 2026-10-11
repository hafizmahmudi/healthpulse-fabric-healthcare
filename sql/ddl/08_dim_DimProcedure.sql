-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimProcedure

IF object_id('dim.DimProcedure','U') IS NULL
BEGIN
    CREATE TABLE dim.DimProcedure
    (
        ProcedureKey          BIGINT        NOT NULL,

        ProcedureCode         VARCHAR(100)  NOT NULL,
        ProcedureDescription  VARCHAR(1000)
    );
END;

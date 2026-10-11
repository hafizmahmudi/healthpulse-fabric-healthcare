-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimDiagnosis

IF OBJECT_ID('dim.DimDiagnosis','U') IS NULL
BEGIN
    CREATE TABLE dim.DimDiagnosis
    (
        DiagnosisKey         BIGINT        NOT NULL,

        DiagnosisCode        VARCHAR(100)  NOT NULL,
        DiagnosisDescription VARCHAR(1000)
    );
END;

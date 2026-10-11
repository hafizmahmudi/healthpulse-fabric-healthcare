-- Source notebook: HP_07_01_NB_SilverToGold_Structure
-- Section: dim.DimMedication

IF OBJECT_ID('dim.DimMedication','U') IS NULL
BEGIN

    CREATE TABLE dim.DimMedication
    (
        MedicationKey          BIGINT        NOT NULL,

        MedicationCode         VARCHAR(100)  NOT NULL,
        MedicationDescription  VARCHAR(1000)
    );

END;

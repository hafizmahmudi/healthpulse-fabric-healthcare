-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: Silver → Gold Data Quality (cross-warehouse)

IF OBJECT_ID('dq.SilverToGoldDQResult', 'U') IS NULL
BEGIN
    CREATE TABLE dq.SilverToGoldDQResult
    (
        DQResultKey BIGINT NOT NULL,

        DQRunID VARCHAR(100) NOT NULL,
        DQRunTime DATETIME2(6) NOT NULL,

        LayerName VARCHAR(50) NOT NULL,
        EntityName VARCHAR(100) NOT NULL,

        CheckName VARCHAR(500) NOT NULL,
        CheckType VARCHAR(100) NOT NULL,

        Severity VARCHAR(20) NOT NULL,
        Status VARCHAR(20) NOT NULL,

        FailedCount BIGINT NULL,
        TotalCount BIGINT NULL,

        Details VARCHAR(2000) NULL
    );
END;

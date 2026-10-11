-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: Silver → Gold Data Quality (cross-warehouse)

IF OBJECT_ID('dq.SilverToGoldDQRun', 'U') IS NULL
BEGIN
CREATE TABLE dq.SilverToGoldDQRun
(
    DQRunID      VARCHAR(100) NOT NULL,
    StartTime    DATETIME2(6) NOT NULL,
    EndTime      DATETIME2(6) NULL,
    Status       VARCHAR(20)  NOT NULL
);
END;

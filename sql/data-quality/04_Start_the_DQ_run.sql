-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: Start the DQ run

-- ============================================================
-- START SILVER -> GOLD DQ RUN
-- ============================================================

-- Close any old RUNNING run
UPDATE [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun
SET
    EndTime = SYSUTCDATETIME(),
    Status = 'ABANDONED'
WHERE Status = 'RUNNING';


-- Start new run
INSERT INTO [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun
(
    DQRunID,
    StartTime,
    Status
)
SELECT
    CONVERT(VARCHAR(100), NEWID()),
    SYSUTCDATETIME(),
    'RUNNING';


SELECT TOP 1 *
FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun
ORDER BY StartTime DESC;

-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: Close DQ check

SELECT TOP 1
    DQRunID,
    StartTime,
    EndTime,
    Status

FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun

ORDER BY StartTime DESC;

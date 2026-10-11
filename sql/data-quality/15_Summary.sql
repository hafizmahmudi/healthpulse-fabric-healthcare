-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: Summary

-- ============================================================
-- FINAL SILVER -> GOLD DQ SUMMARY
-- ============================================================

WITH CurrentRun AS
(
    SELECT TOP 1
        DQRunID
    FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun
    WHERE Status = 'RUNNING'
    ORDER BY StartTime DESC
)

SELECT
    q.EntityName,
    q.CheckName,
    q.CheckType,
    q.Severity,
    q.Status,
    q.FailedCount,
    q.TotalCount,
    q.Details

FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult q

INNER JOIN CurrentRun r
    ON r.DQRunID = q.DQRunID

ORDER BY
    CASE q.Severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,

    q.EntityName,
    q.CheckName;

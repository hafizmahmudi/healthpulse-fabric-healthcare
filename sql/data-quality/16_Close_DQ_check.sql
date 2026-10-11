-- Source notebook: HP_07_04_NB_SilverToGold_DQ
-- Section: Close DQ check

-- ============================================================
-- Close current DQ run
-- ============================================================

UPDATE [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun

SET
    EndTime = SYSUTCDATETIME(),

    Status =
    CASE

        WHEN EXISTS
        (
            SELECT 1

            FROM [HP_09_WH_DataQuality].[dq].SilverToGoldDQResult q

            WHERE
                q.DQRunID =
                [HP_09_WH_DataQuality].[dq].SilverToGoldDQRun.DQRunID

                AND q.Severity = 'CRITICAL'

                AND q.Status = 'FAIL'
        )

        THEN 'FAILED'

        ELSE 'PASSED'

    END

WHERE
    Status = 'RUNNING';

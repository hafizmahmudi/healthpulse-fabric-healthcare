# Data quality notebooks

Two layers, two notebooks, one principle: measurement is separate from loading.

**HP_06_02_NB_BronzeToSilver_DQ** (PySpark, Silver) runs right after the Silver loader with the same `PipelineRunId`. It maintains the 22-rule catalogue in `dq.Rule`, counts valid rows in Silver and rejected rows in quarantine for that run, writes one `dq.Result` row per applicable rule, copies rejected rows to `dq.RejectedRecord` as JSON, and writes a `dq.Run` summary with `DQScore = valid / total * 100`. Re-running for the same run ID replaces its own rows.

**HP_07_04_NB_SilverToGold_DQ** (T-SQL, primary warehouse HP_09_WH_DataQuality) checks the Gold tables after each load: keys populated, business keys unique, one current SCD2 row per entity, fact grain, foreign keys resolve, measures non-negative. 28 checks per run. The run is marked FAILED if any critical check fails, which is intended: a critical failure must be visible.

Results from both layers feed the report's Data Quality & Pipeline Health page. Framework design, rule catalogue, and measured results: [documentation/data-quality.md](../../documentation/data-quality.md). Cell-level documentation: [HP_06_02](../../documentation/notebooks/HP_06_02_NB_BronzeToSilver_DQ.md), [HP_07_04](../../documentation/notebooks/HP_07_04_NB_SilverToGold_DQ.md).

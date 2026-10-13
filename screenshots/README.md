# Screenshots

Evidence captured from the live HealthPulse-DEV workspace. Each image proves one capability and is embedded in the page named in the last column.

## Captured

| File | Captured | What it shows | What the reviewer should notice | Used in |
|---|---|---|---|---|
| `HP_04_PL_Health_Master.png` | 2026-10-11 | Master pipeline canvas with the Lookup activity's settings open | Ingestion notebook, Lookup on `HP_03_WH_HealthAnalytics` in query mode, ForEach with loader and log, two Invoke Pipeline activities, optimization notebook | [pipelines/README.md](../pipelines/README.md) |
| `PL_ForEACH_LOOP_ingestion.png` | 2026-10-11 | Settings of the notebook activity inside `ForEach_Source` | Notebook `HP_05_02_NB_MetadataIngestion` with ten base parameters mapped from `@item()` and `@pipeline().RunId` | [pipelines/README.md](../pipelines/README.md) |
| `HP_04_PL_Health_Master_Testing.png` | 2026-10-11 | Output tab of master run `5800d539`, in progress | One loader and one log activity per source, 1 to 3 minutes per source, 16 to 18 seconds per log | [pipelines/README.md](../pipelines/README.md), [README](../README.md) |
| `HP_06_03_PL_BronzeToSilver.png` | 2026-10-11 | Canvas and output of run `3dee7d92` | Lookup, then a load loop, then a separate DQ loop | [pipelines/README.md](../pipelines/README.md) |
| `HP_07_05_PL_SilverToGold.png` | 2026-10-11 | Canvas and output of run `3dc9bdce` | Four notebooks in strict sequence: structure, dimensions, facts, Gold DQ | [pipelines/README.md](../pipelines/README.md) |
| `HP_12_APP_HealthPulse_Fabric_Report_App.png` | 2026-10-11 | Hosted web app, Executive Overview | Navigation, period selector, KPI cards that say "No values in the model" for null columns, disclaimer footer | [documentation/fabric-app.md](../documentation/fabric-app.md), [README](../README.md) |
| `HP_12_APP_HealthPulse_PBI_Report.png` | 2026-10-11 | The app item opened in Fabric, showing the HP_11 Executive Overview page | Four KPIs with prior-year goals, monthly encounters versus prior year, encounters by type, utilization and readmission by age group | [documentation/fabric-app.md](../documentation/fabric-app.md), [powerbi/README.md](../powerbi/README.md), [README](../README.md) |

## Still to capture

| File | What to capture | What the reviewer should notice |
|---|---|---|
| `01-fabric-workspace.png` | HealthPulse-DEV item list, sorted by name | Numbered naming HP_01 to HP_12; lakehouses, warehouses, notebooks, pipelines, model, report, app in one workspace |
| `03-pipeline-run-log.png` | Query result of `etl.PipelineRun` ordered by StartTime desc | Rows read and written per entity, status, duration |
| `04-bronze-silver-tables.png` | Silver lakehouse explorer showing `clinical`, `reference`, `population`, `quarantine`, `dq` schemas | Clean names, quarantine and DQ beside the data |
| `05-pyspark-transformation.png` | HP_06_01 cell with `transform_encounter` or `transform_patient` | Rename, cast, deterministic ID, blocking rule, quarantine labelling |
| `06-data-quality-results.png` | The report's Data Quality & Pipeline Health page | DQ score by entity, failing rules table, pipeline table |
| `07-warehouse-star-schema.png` | Semantic model diagram view in Fabric | FactEncounter at the centre, dimensions around it, measure table |
| `09-readmissions.png` | Report Readmissions page | Monthly rate vs prior year, triage table sorted by rate |
| `10-deployment-pipeline.png` | HP_DP_HealthPulse with Development, Test, Production stages | Three environments, promotion path |
| `12-optimization-log.png` | `ops.DeltaOptimizationRun` query result | Files before and after, benchmark timing |

## Guidelines

Keep each image under about 400 KB (PNG, 1600 px wide is enough). Crop browser chrome where possible. Do not include tenant IDs or email addresses that you would not want public: `HP_04_PL_Health_Master_Testing.png` currently shows the full portal URL and `HP_12_APP_HealthPulse_Fabric_Report_App.png` shows the signed-in account and the app hostname. Crop or blur those before publishing if they should stay private.

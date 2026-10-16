# DP-700 skills mapping

How the HealthPulse implementation maps to the Microsoft Fabric Data Engineer Associate (DP-700) skill areas. Each row points at concrete evidence in this repository or the workspace.

## Implement and manage an analytics solution

| Competency | HealthPulse evidence |
|---|---|
| Configure workspaces and items | Three workspaces on one capacity, numbered item naming, schema-enabled lakehouses, two warehouses with distinct purposes |
| Lifecycle management | Fabric deployment pipeline `HP_DP_HealthPulse` with Development, Test, Production stages; definitions exported to Git ([deployment.md](deployment.md)) |
| Security and governance | Layered access model, synthetic-data policy, RLS design, secrets policy ([security.md](security.md)) |
| Orchestration | Metadata-driven master pipeline with Lookup, ForEach, notebook, script and Invoke Pipeline activities; two child pipelines ([../pipelines/README.md](../pipelines/README.md)) |

## Ingest and transform data

| Competency | HealthPulse evidence |
|---|---|
| Design a loading pattern | Full and incremental patterns chosen per source in `metadata.SourceConfig`; file landing separated from table loading |
| Batch ingestion with pipelines | `HP_04_PL_Health_Master` and the generic loader notebook; 13 sources, one pipeline |
| Incremental loading and watermarks | Watermark column per source, filter on last watermark, new watermark computed (persistence is a documented gap) |
| Transform with PySpark | Thirteen entity transformations: rename, cast, standardize, derive, deduplicate with window functions, deterministic hashing ([../notebooks/silver/README.md](../notebooks/silver/README.md)) |
| Transform with T-SQL | Dimension and fact loads with MERGE, window functions, CTEs, transactions, SCD Type 2 ([../sql/README.md](../sql/README.md)) |
| Delta Lake | MERGE upserts, schema check before MERGE, OPTIMIZE with V-Order, VACUUM dry run, history review |
| Data quality | 22-rule catalogue, severity, quarantine, referential integrity with left-anti joins, DQ score, Gold-layer checks ([data-quality.md](data-quality.md)) |
| Dimensional modelling | Star schema, surrogate keys, SCD Type 2 on four dimensions, role-playing dates, derived readmission and daily aggregate facts ([data-model.md](data-model.md)) |
| Semantic model | Direct Lake model with two OneLake sources, marked date table, measure table with 70+ measures, prior-year time intelligence ([../semantic-model/README.md](../semantic-model/README.md)) |

## Monitor and optimize an analytics solution

| Competency | HealthPulse evidence |
|---|---|
| Monitor pipeline and notebook runs | `etl.PipelineRun` written by the pipeline from notebook exit values; 201 logged activities |
| Monitor data quality | `dq.Run`, `dq.Result`, `dq.RejectedRecord` in Silver; `SilverToGoldDQRun` and `SilverToGoldDQResult` in HP_09; both reported on the Data Quality & Pipeline Health page |
| Identify and resolve errors | Quarantine with rule and reason; Gold DQ run status FAILED on critical failures; documented root-cause analysis of the encounter duplicate issue |
| Optimize performance | Measured OPTIMIZE and V-Order experiment: 200 to 5 files, 4.97 s to 1.95 s ([optimization.md](optimization.md)) |
| Optimize a semantic model | Single-direction relationships, integer keys, hidden placeholder column, measures over implicit aggregation, date table marked |
| Optimize a report | Theme-first formatting, report-level filter instead of per-page slicers, top-N filters on ranked bars, dynamic titles over duplicated visuals |

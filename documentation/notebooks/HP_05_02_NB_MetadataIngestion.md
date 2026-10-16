# HP_05_02_NB_MetadataIngestion

| | |
|---|---|
| Language | PySpark |
| Attached items | HP_01_LH_Health_Bronze (default lakehouse), HP_03_WH_HealthAnalytics (warehouse) |
| Reads | One CSV or Parquet file under Bronze `Files/`, named by the `SourcePath` parameter |
| Writes | One Delta table `HP_01_LH_Health_Bronze.bronze.<TargetTable>` |
| Run by | HP_04_PL_Health_Master, once per row of `metadata.SourceConfig` |
| Returns | JSON `{RowsRead, RowsWritten, RowsRejected}` to the pipeline, which logs it to `etl.PipelineRun` |

## What it does

A single generic loader. The pipeline passes it the description of one source (where the file is, what format, which Bronze table, full or incremental). The notebook reads the file, cleans column names, stamps metadata, and writes the Bronze Delta table.

## Why it exists

Thirteen sources share one notebook instead of thirteen copies. Adding a source is a new row in `metadata.SourceConfig`, not new code.

## Cells

### Parameters (cells 1 to 2)

- **Cell 1** (code, parameters): default values for interactive runs: SourceId 1, SYNTHEA patients CSV, target `bronze_patients`, Full load, a dummy PipelineRunId. The pipeline overwrites all of these.
- **Cell 2** (code, commented out): an empty template of the same parameters.

### Setup (cells 3 to 7)

- **Cell 3** (code): imports the Fabric Spark connector, PySpark functions, `datetime`, `json`.
- **Cell 4** (markdown): heading "Show incoming configuration".
- **Cell 5** (code): prints every parameter and builds the full target name `HP_01_LH_Health_Bronze.bronze.<TargetTable>`.
- **Cell 6** (markdown): heading "Normalize the values".
- **Cell 7** (code): upper-cases the load type, lower-cases the format, and turns empty or `"NULL"` watermark values into Python `None`.

### Read and prepare (cells 8 to 11)

- **Cell 8** (markdown): heading "Read the source file".
- **Cell 9** (code): reads CSV (header, inferred schema) or Parquet; any other format raises an error. Then rewrites column names so they only contain letters, digits, and underscores, which Delta requires.
- **Cell 10** (markdown): heading "Add ingestion metadata".
- **Cell 11** (code): adds `_ingestion_timestamp`, `_source_system`, `_source_entity`, `_pipeline_run_id`; counts rows read; prints the schema.

### Write (cells 12 to 16)

- **Cell 12** (markdown): heading "FULL load".
- **Cell 13** (code): if the load type is FULL, overwrites the Bronze table with the whole file.
- **Cell 14** (markdown): heading "INCREMENTAL load".
- **Cell 15** (code): if INCREMENTAL, requires a watermark column, keeps only rows newer than the previous watermark (or all rows when there is none), computes the new maximum watermark, and appends the rows. Skips the write when nothing is new.
- **Cell 16** (code): exits the notebook returning rows read and written as JSON so the pipeline can log them. `RowsRejected` is always 0 here.

## Notes

- The new watermark is calculated but never returned or saved, so `SourceConfig.LastWatermark` never advances and incremental loads re-read the entire file every run.
- If the load type is neither FULL nor INCREMENTAL the final cell fails because `rows_written` is undefined.

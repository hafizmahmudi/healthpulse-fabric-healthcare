# Performance optimization

A single documented experiment on the largest Silver table, run by `HP_08_NB_LakehouseOptimization` and logged to `ops.DeltaOptimizationRun`. Numbers below are the logged values, not estimates.

## Problem

`clinical.Encounter` is written by MERGE on every pipeline run. MERGE rewrites touched files and incremental appends add small files, so the table accumulates many small Parquet files. Small files slow both Spark scans and Direct Lake framing.

## Evidence (before)

| Measure | Value |
|---|---|
| Files | 200 |
| Size | 664,301,887 bytes (633 MB) |
| Average file size | 3.2 MB |
| Benchmark query: encounters by year and month | 4.968 s |

## Hypothesis

Compacting to a small number of larger files and applying V-Order will cut scan time for the aggregation query and reduce the number of files the engine must open, without changing results.

## Change

`OPTIMIZE HP_02_LH_Health_Silver.clinical.Encounter VORDER`, run once. VACUUM was executed as a dry run only, with 168-hour retention, so no history was removed.

## Evidence (after)

| Measure | Value |
|---|---|
| Files | 5 |
| Size | 641,600,357 bytes (612 MB) |
| Average file size | 122 MB |
| Benchmark query | 1.949 s |
| Change | 60.8 percent faster, 97.5 percent fewer files, 3.4 percent smaller |

Run ID `ea885c85-ebd9-4498-9fcc-5315d5c595d4`, 2026-10-04.

## Trade-offs

- OPTIMIZE rewrites the table's data files, which costs compute and temporarily doubles storage until VACUUM removes old files.
- The query timing is a single run with the Spark cache cleared, not a controlled benchmark. File-count reduction is the stronger evidence; the timing is indicative.
- V-Order costs a little write time on every subsequent write in exchange for faster reads, which is the right trade for an analytics table.

## Conclusion

Compaction with V-Order is worth running after every load cycle on the large clinical tables, which is why `HP_04_PL_Health_Master` calls the optimization notebook as its last step. Next experiments: partition `clinical.Observation` by year once it exceeds a few hundred million rows, and measure Direct Lake framing time before and after compaction.

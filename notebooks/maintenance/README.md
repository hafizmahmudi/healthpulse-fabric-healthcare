# Maintenance notebook

**HP_08_NB_LakehouseOptimization** (PySpark, Silver) performs and measures Delta Lake maintenance on `clinical.Encounter`, the largest Silver table.

It records file count, size, and a benchmark query time, runs `OPTIMIZE ... VORDER`, measures again, previews `VACUUM` with a 7-day retention as a dry run (the real VACUUM is behind a flag), reviews partition candidates without changing anything, prints schema and Delta history, and appends the measurements to `ops.DeltaOptimizationRun`.

Measured result on 2026-10-04: 200 files to 5, benchmark query 4.97 s to 1.95 s. Full write-up: [documentation/optimization.md](../../documentation/optimization.md). Cell-level documentation: [HP_08](../../documentation/notebooks/HP_08_NB_LakehouseOptimization.md).

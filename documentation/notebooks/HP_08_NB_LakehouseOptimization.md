# HP_08_NB_LakehouseOptimization

| | |
|---|---|
| Language | PySpark |
| Attached items | HP_02_LH_Health_Silver (default lakehouse) |
| Reads | `clinical.Encounter` statistics, history, and a benchmark query |
| Writes | Rewrites the data files of `clinical.Encounter` (OPTIMIZE); appends one row to `ops.DeltaOptimizationRun` |
| Run by | Last activity of HP_04_PL_Health_Master (activity name `Optimization`), after the Gold pipeline; can also be run by hand. |

## What it does

Performs and documents Delta Lake maintenance on the largest Silver table. It records file counts and a benchmark query time, compacts small files with `OPTIMIZE` and V-Order, previews what `VACUUM` would delete, reviews partitioning, prints schema and history, and logs the before and after numbers.

## Why it exists

Many small files slow down both Spark and Direct Lake reads. Compaction with V-Order is the standard Fabric remedy. Logging each run gives evidence of the improvement and a history for an operations dashboard.

## Cells

### Configuration and checks (cells 1 to 7)

- **Cell 1** (markdown): purpose and scope. States it does not transform data.
- **Cell 2** (markdown): heading; explains `clinical.Encounter` is the demonstration table.
- **Cell 3** (code): imports; sets the target table; lists other candidate tables; switches: V-Order on, VACUUM dry run on, real VACUUM off, retention 168 hours; creates a run ID and start time.
- **Cell 4** (markdown): heading "Validate the target table".
- **Cell 5** (code): reads one row to confirm the table exists, otherwise raises a clear error.
- **Cell 6** (markdown): heading "Create the optimization log".
- **Cell 7** (code): creates schema `ops` and table `ops.DeltaOptimizationRun` if missing, with before and after files, sizes, query times, and which operations ran.

### Helpers and baseline (cells 8 to 13)

- **Cell 8** (markdown): describes the two helpers.
- **Cell 9** (code): `get_table_stats` reads `DESCRIBE DETAIL` for file count, size, average file size, partition columns. `run_test_query` clears the cache and times a count of encounters by year and month.
- **Cell 10** (markdown): heading "Inspect the table before optimization".
- **Cell 11** (code): prints the before statistics.
- **Cell 12** (markdown): heading; warns this is a simple benchmark, not a formal one.
- **Cell 13** (code): runs the benchmark query and records the time.

### Optimize and measure (cells 14 to 17)

- **Cell 14** (markdown): explains `OPTIMIZE` and that V-Order is applied in the same pass.
- **Cell 15** (code): runs `OPTIMIZE ... VORDER` (or plain `OPTIMIZE` if V-Order is off) and records what was applied.
- **Cell 16** (markdown): heading "Measure the table after optimization".
- **Cell 17** (code): reads the after statistics, re-runs the benchmark, computes the percentage change, prints both.

### VACUUM (cells 18 to 19)

- **Cell 18** (markdown): explains VACUUM, the 7-day retention, and why retention must not be shortened for a demo.
- **Cell 19** (code): runs `VACUUM ... DRY RUN` to list removable files when enabled; runs the real VACUUM only if `RUN_VACUUM` is true; prints a reminder otherwise.

### Partitioning, schema, history (cells 20 to 27)

- **Cell 20** (markdown): partition strategy guidance: time-based partitions only when the table is large enough; never partition by PatientID.
- **Cell 21** (code): shows encounter counts by year and month as evidence for a partition decision; prints current partition columns; changes nothing.
- **Cell 22** (markdown): says schema enforcement belongs in the Bronze-to-Silver notebook. Refers to it by an old name.
- **Cell 23** (code): prints the current schema of the table.
- **Cell 24** (markdown): describes a controlled schema evolution process and warns against enabling `mergeSchema` everywhere.
- **Cell 25** (code): a commented example of `mergeSchema`; only prints a message.
- **Cell 26** (markdown): heading "Review Delta history".
- **Cell 27** (code): shows the last 20 entries of `DESCRIBE HISTORY`.

### Log and summarize (cells 28 to 31)

- **Cell 28** (markdown): heading "Save the optimization result".
- **Cell 29** (code): appends one row with all measurements and flags to `ops.DeltaOptimizationRun`.
- **Cell 30** (markdown): heading "Final summary"; notes file-count reduction is better evidence than query time.
- **Cell 31** (code): prints a human-readable summary of the run.

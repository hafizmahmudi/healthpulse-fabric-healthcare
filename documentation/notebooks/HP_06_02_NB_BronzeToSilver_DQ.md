# HP_06_02_NB_BronzeToSilver_DQ

| | |
|---|---|
| Language | PySpark |
| Attached items | HP_02_LH_Health_Silver (default lakehouse), HP_01_LH_Health_Bronze |
| Reads | The Silver table and quarantine table for one entity, filtered to one pipeline run; the Bronze patient table for the gender warning |
| Writes | Silver `dq.Rule`, `dq.Run`, `dq.Result`, `dq.RejectedRecord` |
| Run by | HP_06_03_PL_BronzeToSilver, immediately after HP_06_01, with the same `PipelineRunId`, `EntityName`, `SourceName` |

## What it does

Measures the outcome of one loader run and writes it to a central data quality log in the Silver lakehouse. It counts how many rows reached Silver and how many were quarantined, writes one result row per applicable rule, copies each rejected row into a central table as JSON, and records a run summary with a score from 0 to 100.

## Why it exists

Loading and measuring are kept apart on purpose. The loader decides what is valid; this notebook only observes and reports. That gives one place to answer "how clean was the last run" across all entities, which is what the Data Quality page of the HealthPulse report shows.

## Cells

### Setup (cells 1 to 11)

- **Cell 1** (markdown): explains the notebook must run after the loader with identical parameters, that it never changes data, and that the Bronze gender check (DQ009) is skipped rather than reported as passing when Bronze is unavailable.
- **Cell 2** (markdown): heading "Imports".
- **Cell 3** (code): imports PySpark functions, `Window`, `StorageLevel`, `DeltaTable`, `datetime`, `uuid`, `re`.
- **Cell 4** (markdown): heading "Pipeline parameters".
- **Cell 5** (code, parameters): `PipelineRunId`, `EntityName`, `SourceName`.
- **Cell 6** (markdown): heading "Source / Target Configuration".
- **Cell 7** (code): lakehouse names and an optional `BronzeTable` override for when the Bronze table lives somewhere unusual.
- **Cell 8** (markdown): heading "DQ schema and audit tables".
- **Cell 9** (code): creates the `dq` schema in Silver.
- **Cell 10** (markdown): heading "Create the four DQ tables".
- **Cell 11** (code): creates `dq.Rule`, `dq.Run`, `dq.Result`, `dq.RejectedRecord` if they do not exist, with their column lists.

### Rule catalogue (cells 12 to 13)

- **Cell 12** (markdown): heading "Data-quality rule catalog".
- **Cell 13** (code): defines the 22 rules as rows: ten numbered rules (DQ001 to DQ010 covering patient IDs and dates, encounter references and uniqueness, observation references, gender domain) and twelve per-entity validation rules (`DQ_FACILITY`, `DQ_ENCOUNTER`, and so on). Each has a severity, type, and flags for blocking, active, and applicable. DQ005, DQ006, and DQ008 are marked not applicable because the encounter source lacks the columns. The list is MERGEd into `dq.Rule` by RuleID and a small severity lookup is built.

### Audit helpers (cells 14 to 16)

- **Cell 14** (markdown): heading "Audit helper functions".
- **Cell 15** (code): four functions:
  - `get_nonblocking_failures`: counts Bronze patients whose gender is not M, MALE, F, or FEMALE (DQ009, a warning).
  - `write_dq_results`: writes one row per rule that applies to the entity, with records checked, records failed, and failure percent. Rules that found nothing are still written with zero.
  - `write_dq_rejected_records`: copies every quarantined row into `dq.RejectedRecord` with the record key, rule, severity, reason, and the full row as JSON.
  - `write_dq_run`: writes the run summary row with totals, the DQ score, and status SUCCESS.
- **Cell 16** (code): `ENTITY_CONFIG`, the same entity-to-Silver-table map as the loader.

### Read the completed run (cells 17 to 18)

- **Cell 17** (markdown): heading "Read data from the completed loading run".
- **Cell 18** (code): resolves plural or prefixed entity names to the logical entity; for patients, finds the Bronze table so DQ009 can be evaluated; reads Silver rows stamped with this `PipelineRunId` (valid) and quarantine rows stamped with this run (rejected); evaluates the gender warning when the Bronze table carries run IDs; creates a new DQ run ID and start time.

### Write results (cells 19 to 20)

- **Cell 19** (markdown): heading "Write audit results and score".
- **Cell 20** (code): builds an empty quarantine frame with the right columns if no quarantine table exists; defaults Severity to ERROR for older quarantine tables; deletes any earlier audit rows for the same run and entity so re-runs do not duplicate; writes rejected records, results, and the run summary. Score is valid rows divided by total rows times 100, or 100 when there were no rows.

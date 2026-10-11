# SQL

The warehouse logic, extracted one file per step from the T-SQL notebooks so it can be read and reviewed without opening Fabric. Each file names its source notebook and section in a header comment.

| Folder | Content | Source notebook |
|---|---|---|
| `ddl/` | Schemas, eight dimension tables, seven fact tables, verification query | HP_07_01_NB_SilverToGold_Structure |
| `dimensions/` | DimDate generation and MERGE; patient staging and SCD Type 2; Facility, Provider, Payer SCD Type 2; Procedure, Medication, Diagnosis Type 1 | HP_07_02_NB_SilverToGold_Load_Dim |
| `facts/` | Incremental loads for the five transactional facts; readmission derivation with `LEAD`; facility-daily aggregate | HP_07_03_NB_SilverToGold_Load_Fact |
| `data-quality/` | Gold DQ table DDL, run start, per-table checks, summary, run close | HP_07_04_NB_SilverToGold_DQ |

## Patterns worth reading

- `dimensions/03_Load_Patient.sql`: a complete SCD Type 2 in four statements (expire, Type 1 update, insert new versions, validate).
- `facts/01_Load_FactEncounter.sql`: SCD2-aware key resolution with `OUTER APPLY ... ORDER BY CASE`, then a transactional update-then-insert.
- `facts/06_FactReadmission.sql`: readmission pairing with `LEAD() OVER (PARTITION BY PatientKey ORDER BY date)`.
- `data-quality/05_DimDate.sql`: the reusable check shape, a `UNION ALL` of checks inserted with a computed PASS or FAIL.

## Control tables (not in the notebooks)

`metadata.SourceConfig` and `etl.PipelineRun` are created outside the notebooks. Their definitions are in [pipelines/README.md](../pipelines/README.md).

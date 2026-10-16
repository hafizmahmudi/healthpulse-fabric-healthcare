# HealthPulse notebooks

Documentation of the nine notebooks in the Fabric workspace **HealthPulse-DEV** (`e8daa76e-5e3f-4dd0-8444-5f84dfbabc14`), as exported on 2026-10-09. Each notebook has its own page with a short purpose, the reason it exists, and a plain-language note for every cell.

## How the notebooks fit together

```
Public sources (Hugging Face Synthea, USDA ERS)
        │
        ▼
HP_05_01_NB_SourceIngestion ─── downloads raw files into HP_01_LH_Health_Bronze /Files
        │
        ▼
HP_04_PL_Health_Master (pipeline) ── runs HP_05_01 first, then reads metadata.SourceConfig in the warehouse, one row per source
        │  calls, per source:
        ▼
HP_05_02_NB_MetadataIngestion ─── CSV/Parquet file → bronze.<table> Delta table (Full or Incremental)
        │
        ▼
HP_06_03_PL_BronzeToSilver (pipeline, invoked by HP_04) ── calls, per entity:
        ├─ HP_06_01_NB_BronzeToSilver ─── clean, type, dedupe, block bad rows → Silver tables + quarantine
        └─ HP_06_02_NB_BronzeToSilver_DQ ─ audit the run → dq.Run / dq.Result / dq.RejectedRecord (Silver)
        │
        ▼
HP_07_05_PL_SilverToGold (pipeline, invoked by HP_04 after HP_06_03) ── calls, in order:
        ├─ HP_07_01_NB_SilverToGold_Structure ─ create dim / fact / stg schemas and tables in HP_03_WH_HealthAnalytics
        ├─ HP_07_02_NB_SilverToGold_Load_Dim ── load dimensions (surrogate keys, SCD Type 2)
        ├─ HP_07_03_NB_SilverToGold_Load_Fact ─ load facts and the readmission and facility-daily derivations
        └─ HP_07_04_NB_SilverToGold_DQ ──────── check the Gold tables → dq.* in HP_09_WH_DataQuality
        │
        ▼
HP_08_NB_LakehouseOptimization ─── OPTIMIZE and VACUUM the Silver tables, last activity of HP_04
        
HP_08_NB_LakehouseOptimization ─── Delta maintenance (OPTIMIZE, V-Order, VACUUM) on Silver, run on demand
```

## Notebook index

| Notebook | Language | Attached to | Writes to | Page |
|---|---|---|---|---|
| HP_05_01_NB_SourceIngestion | PySpark / Python | Bronze lakehouse | Bronze `Files/synthea/raw` and `Files/synthea/extracted` | [HP_05_01](HP_05_01_NB_SourceIngestion.md) |
| HP_05_02_NB_MetadataIngestion | PySpark | Bronze lakehouse, HP_03 warehouse | Bronze `bronze.<TargetTable>` Delta tables | [HP_05_02](HP_05_02_NB_MetadataIngestion.md) |
| HP_06_01_NB_BronzeToSilver | PySpark | Silver lakehouse (default), Bronze lakehouse | Silver `clinical.*`, `reference.*`, `population.*`, `quarantine.*` | [HP_06_01](HP_06_01_NB_BronzeToSilver.md) |
| HP_06_02_NB_BronzeToSilver_DQ | PySpark | Silver lakehouse (default), Bronze lakehouse | Silver `dq.Rule`, `dq.Run`, `dq.Result`, `dq.RejectedRecord` | [HP_06_02](HP_06_02_NB_BronzeToSilver_DQ.md) |
| HP_07_01_NB_SilverToGold_Structure | T-SQL | HP_03 warehouse | Warehouse schemas and tables (DDL only) | [HP_07_01](HP_07_01_NB_SilverToGold_Structure.md) |
| HP_07_02_NB_SilverToGold_Load_Dim | T-SQL | HP_03 warehouse, Silver lakehouse | Warehouse `dim.*`, `stg.DimPatient` | [HP_07_02](HP_07_02_NB_SilverToGold_Load_Dim.md) |
| HP_07_03_NB_SilverToGold_Load_Fact | T-SQL | HP_03 warehouse, Silver lakehouse | Warehouse `fact.*` | [HP_07_03](HP_07_03_NB_SilverToGold_Load_Fact.md) |
| HP_07_04_NB_SilverToGold_DQ | T-SQL | HP_09 warehouse (primary), HP_03 warehouse | HP_09 `dq.SilverToGoldDQRun`, `dq.SilverToGoldDQResult` | [HP_07_04](HP_07_04_NB_SilverToGold_DQ.md) |
| HP_08_NB_LakehouseOptimization | PySpark | Silver lakehouse | Silver `ops.DeltaOptimizationRun`; rewrites `clinical.Encounter` files | [HP_08](HP_08_NB_LakehouseOptimization.md) |

## Conventions used across the notebooks

- **Parameters cell first.** Every pipeline-driven notebook starts with a cell of default parameter values. The Fabric pipeline overrides them at run time; the defaults are only for running the notebook by hand.
- **Metadata columns.** Every Bronze and Silver row carries `_ingestion_timestamp`, `_source_system`, `_source_entity`, and `_pipeline_run_id`. Silver drops the Bronze values and stamps fresh ones.
- **Blocking rules in the loader, measurement in the DQ notebook.** Bad rows never reach Silver because the loader quarantines them. The DQ notebook only counts and reports; it never changes data.
- **Deterministic IDs.** Condition, Procedure, Medication, Observation, and RuralUrban rows have no source ID, so Silver builds one as a SHA-256 hash of the business columns. Re-running produces the same ID.
- **Surrogate keys in the warehouse.** Dimension and fact keys are assigned as `MAX(existing key) + ROW_NUMBER()`. No identity columns are used.
- **SCD Type 2** on Patient, Facility, Provider, and Payer: a change in a tracked attribute expires the current row (`ValidTo`, `IsCurrent = 0`) and inserts a new version. Other attributes are updated in place (Type 1).
- **Idempotent DDL.** Every `CREATE` is wrapped in an existence check so the structure notebook can be re-run safely.

## Things to know before changing anything

These were observed while reading the code and the data on 2026-10-09.

1. **Encounter source is thin.** Silver `clinical.Encounter` has only ID, date, patient, code, description, reason code, and reason description. There is no class, start or end time, cost, facility, provider, or payer. The warehouse `FactEncounter` has columns for all of those, but the fact loader cannot fill them, so they are null and `FactFacilityDaily` stays empty. Rules DQ005, DQ006, and DQ008 are marked "not applicable" for the same reason.
2. **Encounter rejection rate is 75 percent.** The Bronze-to-Silver DQ log shows 45.3 million of 60.4 million Encounter records quarantined (score 62.5). Everything else scores 94 or higher. Investigate the Encounter quarantine table before trusting any utilization figure.
3. **Gold DQ moved warehouses.** HP_07_04 now writes to `HP_09_WH_DataQuality`. The old `dq` tables in HP_03 no longer exist. Anything that read them, including the first version of the HP_11 report, must point at HP_09 or at the Silver `dq` schema.
4. **DDL drift.** HP_07_01 comments out `EncounterKey` on FactCondition, FactMedication, FactProcedure, and FactObservation, but HP_07_03 inserts into that column and the warehouse tables have it. The tables were altered outside the structure notebook. `stg.DimPatient` is also used by HP_07_02 but never created by HP_07_01.
5. **Incremental watermark is never persisted.** HP_05_02 computes a new watermark but only returns row counts to the pipeline, so `metadata.SourceConfig.LastWatermark` stays null and every "Incremental" load reprocesses the whole file.
6. **DimFacility SCD2 expiry condition is wrong.** The `WHERE` mixes `AND` and `OR` without parentheses, so a change to only the facility name, state, zip, or coordinates does not expire the current row.
7. **Stale names in comments.** HP_07_02 cell 3 refers to `HP_04_WH_HealthAnalytics` and HP_08 refers to `HP_07_NB_BronzeToSilver`; both are old names.
8. **Gold DQ coverage gaps.** HP_07_04 has no checks for FactMedication, FactProcedure, or FactObservation, and none for the null facility, provider, or payer keys on FactEncounter.

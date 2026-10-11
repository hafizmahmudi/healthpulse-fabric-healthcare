# Gold notebooks (T-SQL)

**HP_07_01_NB_SilverToGold_Structure** creates schemas `dim`, `fact`, `stg` and the fifteen tables with `IF OBJECT_ID(...) IS NULL` guards. Safe to re-run.

**HP_07_02_NB_SilverToGold_Load_Dim** loads the dimensions.

- `DimDate` is generated from the encounter date range with `GENERATE_SERIES` and MERGEd on `DateKey`.
- `DimPatient`, `DimFacility`, `DimProvider`, `DimPayer` are SCD Type 2: tracked attribute changes expire the current row and insert a new version; other attributes update in place.
- `DimProcedure`, `DimMedication`, `DimDiagnosis` are Type 1 code lookups.
- Surrogate keys are `MAX(key) + ROW_NUMBER()`.

**HP_07_03_NB_SilverToGold_Load_Fact** loads the facts.

- Five transactional facts resolve business keys to surrogate keys, with the patient lookup preferring the SCD2 version valid on the event date.
- Loads are incremental: update existing rows, insert new rows, then re-resolve keys on existing rows so late-arriving dimension members fill in.
- `FactReadmission` pairs each encounter with the patient's next encounter using `LEAD` and flags 1 to 30 days. It is a proxy because the source has no admission or discharge.
- `FactFacilityDaily` aggregates per facility per day and is empty until facility keys are populated.

The same SQL, split into one file per step, is in [sql/](../../sql/). Cell-level documentation: [HP_07_01](../../documentation/notebooks/HP_07_01_NB_SilverToGold_Structure.md), [HP_07_02](../../documentation/notebooks/HP_07_02_NB_SilverToGold_Load_Dim.md), [HP_07_03](../../documentation/notebooks/HP_07_03_NB_SilverToGold_Load_Fact.md).

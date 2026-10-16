# HP_07_01_NB_SilverToGold_Structure

| | |
|---|---|
| Language | T-SQL notebook |
| Attached items | HP_03_WH_HealthAnalytics (default warehouse) |
| Reads | `sys.schemas`, `sys.tables` for existence checks |
| Writes | Schemas `dim`, `fact`, `stg` and the dimension and fact tables (DDL only, no data) |
| Run by | HP_07_05_PL_SilverToGold, first step |

## What it does

Creates the Gold star schema in the warehouse: eight dimension tables and seven fact tables, plus the three schemas they live in. Every statement checks whether the object already exists, so running it again does nothing harmful.

## Why it exists

Keeping table definitions apart from the load logic means the shape of the warehouse is documented in one place and the loaders can assume the tables exist.

## Cells

### Schemas (cells 1 to 3)

- **Cell 1** (markdown): lists the planned tables. Includes `DimGeography`, which is not yet built.
- **Cell 2** (markdown): heading "Schema".
- **Cell 3** (code): creates schemas `dim`, `fact`, and `stg` if they are missing.

### Dimension tables (cells 4 to 22)

Each pair is a heading and a `CREATE TABLE` guarded by `IF OBJECT_ID(...) IS NULL`.

- **Cells 4, 5** (markdown): headings.
- **Cell 6** (code): `dim.DimDate` with a `yyyyMMdd` integer key and the usual calendar attributes.
- **Cells 7, 8**: `dim.DimPatient` with surrogate key, business key, demographics, Age and AgeGroup, and SCD Type 2 columns `ValidFrom`, `ValidTo`, `IsCurrent`.
- **Cells 9, 10**: `dim.DimFacility` with address, coordinates, revenue, utilization, and SCD Type 2 columns.
- **Cells 11, 12**: `dim.DimProvider` with facility reference, specialty, address, and SCD Type 2 columns.
- **Cells 13, 14**: `dim.DimDiagnosis`, a simple code and description lookup.
- **Cells 15, 16**: `dim.DimMedication`, code and description.
- **Cells 17, 18**: `dim.DimProcedure`, code and description.
- **Cells 19, 20**: `dim.DimPayer` with address and SCD Type 2 columns.
- **Cells 21, 22**: `dim.DimGeography`, fully commented out. A planned county dimension with population, income, and poverty attributes.

### Fact tables (cells 23 to 38)

- **Cells 23, 24** (markdown): headings.
- **Cell 25** (code): `fact.FactEncounter` with keys to patient, date, facility, provider, payer; encounter and reason codes; and placeholder columns for class, start and end time, length of stay, and three cost measures that the comment says "become usable when richer encounter data is available".
- **Cells 26, 27**: `fact.FactCondition`. `EncounterKey` is commented out here, although the live table and the fact loader both use it.
- **Cells 28, 29, 30**: `fact.FactMedication`, same note about `EncounterKey`.
- **Cells 31, 32**: `fact.FactProcedure`, same note.
- **Cells 33, 34**: `fact.FactObservation` with code, text value, numeric value, and units. Same note.
- **Cells 35, 36**: `fact.FactReadmission` with index and readmission encounter keys, dates, days between, and a 30-day flag. Includes `DateKey`.
- **Cells 37, 38**: `fact.FactFacilityDaily`, the daily per-facility aggregate.

### Verification (cells 39 to 40)

- **Cell 39** (markdown): heading "List what was created".
- **Cell 40** (code): selects every table in the `dim` and `fact` schemas.

## Notes

- `stg.DimPatient` is used by the dimension loader but is not created here.
- The warehouse tables have `EncounterKey` on the four facts where this notebook comments it out, so the definitions here lag the real tables.

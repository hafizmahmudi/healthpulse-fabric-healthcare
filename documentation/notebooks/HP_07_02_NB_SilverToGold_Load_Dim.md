# HP_07_02_NB_SilverToGold_Load_Dim

| | |
|---|---|
| Language | T-SQL notebook |
| Attached items | HP_03_WH_HealthAnalytics (default warehouse), HP_02_LH_Health_Silver (read through its SQL endpoint) |
| Reads | Silver `clinical.encounter`, `clinical.patient`, `clinical.procedure`, `clinical.medication`, `clinical.condition`, `reference.facility`, `reference.provider`, `reference.payer` |
| Writes | `dim.DimDate`, `stg.DimPatient`, `dim.DimPatient`, `dim.DimProcedure`, `dim.DimFacility`, `dim.DimProvider`, `dim.DimPayer`, `dim.DimMedication`, `dim.DimDiagnosis` |
| Run by | HP_07_05_PL_SilverToGold, after the structure notebook and before the fact loader |

## What it does

Loads every dimension from Silver into the warehouse. It assigns surrogate keys, keeps history for the four slowly changing dimensions (patient, facility, provider, payer), and overwrites descriptions in place for the three code lookups (procedure, medication, diagnosis).

## Why it exists

Facts reference dimensions by surrogate key, so dimensions must be loaded first and must keep stable keys between runs. SCD Type 2 lets a report show a patient's marital status or a provider's facility as it was at the time of an encounter.

## Cells

### Introduction (cells 1 to 4)

- **Cell 1** (markdown): heading "Transform and Load".
- **Cell 2** (markdown): list of the five main tasks for the Silver-to-Gold stage.
- **Cell 3** (code, commented out): leftover PySpark imports from an earlier version. Refers to the old warehouse name `HP_04_WH_HealthAnalytics`. Does nothing.
- **Cell 4** (markdown): heading "LOAD DimDate".

### DimDate (cell 5)

- **Cell 5** (code): finds the earliest and latest encounter date in Silver, generates every calendar day in between with `GENERATE_SERIES`, computes the date attributes (day, week, month, quarter, year, year-month label, weekend flag), and MERGEs them into `dim.DimDate` on `DateKey`. Ends with a row count and date range check.

### DimPatient (cells 6 to 8)

- **Cell 6** (markdown): heading "Load Patient".
- **Cell 7** (code): empties `stg.DimPatient` and reloads it from Silver patient with the columns the dimension needs (ID, names, birth date, gender, race, ethnicity, marital status, age, age group). Shows a count and ten sample rows.
- **Cell 8** (code): SCD Type 2 load of `dim.DimPatient` from staging. `MaritalStatus` is the tracked attribute: if it changed, the current row is expired. All other attributes are updated in place on current rows. New patients and expired patients get a new row with the next surrogate key, `ValidFrom` now, `ValidTo` 9999-12-31, `IsCurrent` 1. Ends with a summary and a check that no patient has two current rows.

### DimProcedure (cells 9 to 10)

- **Cell 9** (markdown): heading.
- **Cell 10** (code): takes one row per procedure code (the description from the most recent procedure), assigns new keys to unseen codes, and MERGEs: update the description if it changed, insert if new.

### DimFacility (cells 11 to 12)

- **Cell 11** (markdown): heading.
- **Cell 12** (code): SCD Type 2 load from Silver facility. Expires the current row when name, address, city, state, zip, coordinates, or phone change; inserts new and changed facilities; updates `Revenue` and `Utilization` in place; summary and uniqueness check. Note: the expiry condition mixes `AND` and `OR` without brackets, so only some attribute changes actually trigger a new version.

### DimProvider (cells 13 to 14)

- **Cell 13** (markdown): heading.
- **Cell 14** (code): SCD Type 2 load from Silver provider. Expires when facility, address, city, state, zip, or coordinates change; inserts new and changed providers; updates name, gender, and specialty in place; summary and uniqueness check.

### DimPayer (cells 15 to 16)

- **Cell 15** (markdown): heading.
- **Cell 16** (code): SCD Type 2 load from Silver payer. Derives `State` from the payer's zip code by looking it up in current facilities, falling back to the payer's own headquarters state. Expires when any tracked attribute changes; inserts new and changed payers; summary and uniqueness check.

### DimMedication (cells 17 to 18)

- **Cell 17** (markdown): heading.
- **Cell 18** (code): one row per medication code with its description, new keys for unseen codes, MERGE to update descriptions or insert. Summary and duplicate check.

### DimDiagnosis (cells 19 to 20)

- **Cell 19** (markdown): heading.
- **Cell 20** (code): condition codes become diagnosis codes. Updates descriptions that changed, inserts new codes with new keys. Summary and duplicate check.

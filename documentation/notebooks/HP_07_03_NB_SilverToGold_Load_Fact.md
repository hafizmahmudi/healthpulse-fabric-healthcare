# HP_07_03_NB_SilverToGold_Load_Fact

| | |
|---|---|
| Language | T-SQL notebook |
| Attached items | HP_03_WH_HealthAnalytics (default warehouse), HP_02_LH_Health_Silver (read through its SQL endpoint) |
| Reads | Silver `clinical.encounter`, `clinical.condition`, `clinical.medication`, `clinical.procedure`, `clinical.observation`; warehouse `dim.*` for key lookups |
| Writes | `fact.FactEncounter`, `fact.FactCondition`, `fact.FactMedication`, `fact.FactProcedure`, `fact.FactObservation`, `fact.FactReadmission`, `fact.FactFacilityDaily` |
| Run by | HP_07_05_PL_SilverToGold, after the dimension loader |

## What it does

Loads the five transactional facts from Silver, resolving every business key to a warehouse surrogate key, then derives two analytical facts from them: readmissions (each encounter paired with the patient's next encounter) and a daily per-facility summary. Loads are incremental: existing rows are updated, new rows are inserted with new keys, and each cell ends with validation queries.

## Why it exists

The facts are what reports measure. Resolving keys here, with a fallback order for SCD Type 2 patients, keeps the star schema consistent and keeps report-side joins fast.

## Cells

### Introduction (cells 1 to 3)

- **Cell 1** (markdown): heading "Transform and Load".
- **Cell 2** (markdown): list of the five main tasks.
- **Cell 3** (markdown): heading "Load FactEncounter".

### FactEncounter (cell 4)

- **Cell 4** (code): prepares a temp table of encounters, keeping one row per EncounterID (latest date). Resolves `PatientKey` by preferring the patient version valid on the encounter date, then the current version, then the latest historical one. Resolves `DateKey` by date. Reports how many keys are missing, then inside a transaction updates changed existing encounters and inserts new ones with the next surrogate keys. Ends with a count check. Only eight columns are written: EncounterID, PatientKey, DateKey, EncounterCode, EncounterDescription, ReasonCode, ReasonDescription, EncounterCount. Facility, provider, payer, class, times, and costs are never populated because Silver has no source for them.

### FactCondition (cells 5 to 6)

- **Cell 5** (markdown): heading.
- **Cell 6** (code): reads Silver conditions, resolves `EncounterKey` by EncounterID, `PatientKey` by the SCD rules with the encounter's patient as fallback, `DiagnosisKey` by code, and start and stop `DateKey`s. Inserts new ConditionIDs with new keys, then re-resolves and updates every existing row so late-arriving dimension keys get filled. Ends with missing-key counts and a duplicate check.

### FactMedication (cells 7 to 8)

- **Cell 7** (markdown): heading.
- **Cell 8** (code): same pattern as conditions for medication orders: resolve patient, encounter, medication, start and stop dates; insert new; update existing; validate.

### FactProcedure (cells 9 to 10)

- **Cell 9** (markdown): heading.
- **Cell 10** (code): same pattern for procedures with a single procedure date key.

### FactObservation (cells 11 to 12)

- **Cell 11** (markdown): heading.
- **Cell 12** (code): same pattern for observations, also carrying the code, description, text value, numeric value, and units onto the fact. This is the largest table (about 63 million rows).

### FactReadmission (cells 13 to 14)

- **Cell 13** (markdown): heading.
- **Cell 14** (code): labelled a temporary proxy method because the source has no admission, discharge, or class. Orders each patient's encounters by date and uses `LEAD` to pair each encounter with the next one. Keeps pairs more than zero days apart, flags 1 to 30 days as a 30-day readmission, and inserts pairs not already present. Every later encounter counts, not only inpatient stays.

### FactFacilityDaily (cells 15 to 16)

- **Cell 15** (markdown): heading.
- **Cell 16** (code): aggregates encounters per facility per day: patients, encounters, emergency, inpatient and outpatient visits by class, average length of stay, total and average cost, plus 30-day readmissions joined from FactReadmission. Updates existing facility-days, inserts new ones, then summarizes and checks the grain. Because `FacilityKey` and `EncounterClass` are always null, this produces zero rows today.

### Final check (cell 17)

- **Cell 17** (code): duplicate-ID checks across the five transactional facts. Each query should return no rows.

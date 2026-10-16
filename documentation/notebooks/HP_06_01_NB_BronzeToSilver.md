# HP_06_01_NB_BronzeToSilver

| | |
|---|---|
| Language | PySpark |
| Attached items | HP_02_LH_Health_Silver (default lakehouse), HP_01_LH_Health_Bronze |
| Reads | One Bronze table `bronze.<EntityName>` |
| Writes | The matching Silver table in `clinical`, `reference`, or `population`, plus `quarantine.<Entity>` for rejected rows |
| Run by | HP_06_03_PL_BronzeToSilver, once per entity, followed by HP_06_02 with the same parameters |

## What it does

Turns one raw Bronze table into its clean Silver equivalent. For each entity it renames columns to business names, enforces data types, standardizes text, builds a stable ID where the source has none, removes duplicates, applies the blocking data quality rules, upserts the good rows into Silver, and writes the bad rows to a quarantine table with the rule that rejected them.

## Why it exists

Silver is the trusted, typed layer that the warehouse loads from. Blocking rules live here so that an invalid row can never reach Silver, while the quarantine keeps every rejected row for audit. The separate DQ notebook then measures what happened without touching the data.

## Cells

### Setup (cells 1 to 10)

- **Cell 1** (markdown): title and purpose; says to run this first, then the DQ notebook with identical parameters.
- **Cell 2** (markdown): heading "Imports".
- **Cell 3** (code): imports PySpark functions, `Window`, `StorageLevel`, `DeltaTable`, `datetime`, `uuid`, `re`.
- **Cell 4** (markdown): heading "Pipeline Parameters".
- **Cell 5** (code, parameters): `PipelineRunId`, `EntityName` (a Bronze table name such as `bronze_patients`), `SourceName`. Defaults are for testing.
- **Cell 6** (code): appends " -Bronze" to `SourceName` so Silver rows record where they came from.
- **Cell 7** (markdown): heading "Source / Target Configuration".
- **Cell 8** (code): sets lakehouse names, insists `EntityName` starts with `bronze_`, derives the logical entity by stripping the prefix and a trailing "s" (`bronze_patients` becomes `patient`), and builds the full Bronze table name.
- **Cell 9** (markdown): heading for schema creation.
- **Cell 10** (code): creates Silver schemas `clinical`, `reference`, `population`, `quarantine` if missing.

### Shared helpers (cells 11 to 13)

- **Cell 11** (markdown): explains that transformations contain the blocking checks and the DQ notebook reports on them.
- **Cell 12** (code): defines the helper functions used by every entity:
  - `add_silver_metadata`: drops any metadata columns inherited from Bronze and stamps fresh Silver ones.
  - `keep_latest`: keeps the newest Bronze version of each business key.
  - `split_valid_invalid`: splits a dataframe by a rule expression.
  - `merge_to_silver`: creates the table on first run, otherwise checks the schema and MERGEs (update matched, insert new) on the key.
  - `append_quarantine` and `write_quarantine`: collect and append rejected rows, allowing new columns.
  - `apply_patient_reference_dq`: for Encounter (DQ004) and Observation (DQ007), rejects rows whose PatientID is not in Silver Patient. Fails if Silver Patient does not exist yet, so Patient must load first.
- **Cell 13** (code): `add_quarantine_metadata` stamps the loading run ID onto quarantined rows.

### Entity transformations (cells 14 to 40)

Each transformation follows the same shape: rename, cast, standardize, build IDs, deduplicate, define the rejection rule, split, and label rejected rows with a rule ID and reason.

- **Cell 14** (markdown): heading "Entity Transformation Functions".
- **Cell 15** (markdown): heading "Organizations → Facility".
- **Cell 16** (code): `transform_facility`. Renames Synthea organization columns, casts coordinates and money to double, trims and title-cases text, dedupes by FacilityID. Rejects null ID or name, coordinates out of range, negative revenue or utilization. Rule `DQ_FACILITY`.
- **Cell 17** (markdown): heading "Providers → Provider".
- **Cell 18** (code): `transform_provider`. Renames, casts, normalizes gender to Male, Female, or Unknown, dedupes by ProviderID. Rejects null ID or name, bad coordinates, negative encounter or procedure counts. Rule `DQ_PROVIDER`.
- **Cell 19** (markdown): heading "Payers → Payer".
- **Cell 20** (code): `transform_payer`. Renames about twenty financial and count columns, casts them, standardizes text, dedupes by PayerID. Rejects null ID or name and negative amounts. Rule `DQ_PAYER`.
- **Cell 21** (markdown): heading "Patients → Patient".
- **Cell 22** (code): `transform_patient`. Renames, parses birth and death dates, normalizes gender, computes Age and AgeGroup bands, dedupes by PatientID. Rejects null PatientID (DQ001, critical), birth date in the future (DQ002), death before birth (DQ003). Gender problems are only a warning and do not reject.
- **Cell 23** (markdown): heading "Encounters → Encounter".
- **Cell 24** (code): `transform_encounter`. Renames the seven source columns (ID, DATE, PATIENT, CODE, DESCRIPTION, REASONCODE, REASONDESCRIPTION), casts the date and codes. Duplicate EncounterIDs keep the newest and quarantine the rest (DQ010, critical). Rejects null ID, patient, or date and future dates (`DQ_ENCOUNTER`). Note: the source has no class, start or end time, cost, facility, provider, or payer, which is why those columns are empty downstream.
- **Cell 25** (markdown): heading "Conditions → Condition"; notes the ID is generated in Silver.
- **Cell 26** (code): `transform_condition`. Renames, parses dates, builds `ConditionID` as a SHA-256 hash of patient, encounter, code, start, and stop. Dedupes on it. Rejects null patient, code, or start date, future start, stop before start. Rule `DQ_CONDITION`.
- **Cell 27** (markdown): heading "Procedures → Procedure".
- **Cell 28** (code): `transform_procedure`. Same pattern with `ProcedureID` hashed from patient, encounter, code, and date. Rule `DQ_PROCEDURE`.
- **Cell 29** (markdown): heading "Medications → Medication".
- **Cell 30** (code): `transform_medication`. Same pattern with `MedicationID` hashed from patient, encounter, code, start, stop. Rule `DQ_MEDICATION`.
- **Cell 31** (markdown): heading "Observations → Observation".
- **Cell 32** (code): `transform_observation`. Renames, casts, keeps the text value and adds a numeric copy where it parses, hashes `ObservationID` from patient, encounter, code, date, value, and units. Rejects null patient, date, or code and future dates. Rule `DQ_OBSERVATION`.
- **Cell 33** (markdown): heading "Rural/Urban → RuralUrban".
- **Cell 34** (code): `transform_rural_urban`. Zero-pads FIPS to five characters, trims text, hashes `RuralUrbanID` from FIPS and Attribute because one county has several attribute rows. Rejects null FIPS, county, or attribute. Rule `DQ_RURAL_URBAN`.
- **Cell 35** (markdown): heading "USDA Income → USDAIncome".
- **Cell 36** (code): `transform_usda_income`. Renames thirteen income and poverty columns to readable names, pads FIPS, casts to double, dedupes by FIPS. Rejects null geography and negative incomes. Rule `DQ_USDA_INCOME`.
- **Cell 37** (markdown): heading "bronze_usda_jobs → usda_job".
- **Cell 38** (code): `transform_usda_jobs`. Uses regular expressions to rename unemployment, employment-change, sector-percentage, and labor-force columns; casts rates to double and counts to long; dedupes by FIPS. Rejects null geography, rates outside 0 to 100, negative counts. Builds a specific failure reason per column. Rule `DQ_USDA_JOBS`.
- **Cell 39** (markdown): heading "bronze_usda_people → usda_people".
- **Cell 40** (code): `transform_usda_people`. Pads FIPS; casts about 25 percentage columns and 15 rate columns to double and about 50 population counts to long; dedupes by FIPS. Rejects null geography, negative counts, percentages outside 0 to 100, negative density, land area, or household size. Migration and change rates are allowed to be negative. Rule `DQ_USDA_PEOPLE`.

### Wiring and execution (cells 41 to 48)

- **Cell 41** (markdown): heading "Transformer Registry".
- **Cell 42** (code): `TRANSFORMERS` maps each logical entity to its transform function.
- **Cell 43** (markdown): heading "Silver Target Configuration".
- **Cell 44** (code): `ENTITY_CONFIG` maps each entity to its Silver table and merge key, for example `patient` to `clinical.Patient` on `PatientID`.
- **Cell 45** (markdown): heading "Validate Entity and Read Bronze".
- **Cell 46** (code): fails fast if the entity has no transformer or config, then reads the Bronze table and prints its columns.
- **Cell 47** (markdown): heading "Execute Bronze → Silver loading".
- **Cell 48** (code): runs the transformer, applies the patient reference check, stamps Silver metadata on both valid and rejected rows, stamps the run ID on rejected rows, caches both sets, MERGEs valid rows into Silver, appends rejected rows to `quarantine.<Entity>`, prints accepted and quarantined counts, and releases the cache.

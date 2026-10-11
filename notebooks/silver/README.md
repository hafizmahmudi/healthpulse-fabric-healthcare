# Silver notebook

**HP_06_01_NB_BronzeToSilver** turns one Bronze table into its Silver equivalent.

How it is organized:

- `TRANSFORMERS` maps a logical entity (`patient`, `encounter`, `usda_job`, ...) to a transform function. `ENTITY_CONFIG` maps the same entity to its Silver table and merge key. The pipeline passes the Bronze table name; the notebook derives the entity and routes.
- Every transform follows one shape: rename to business names, cast types, standardize text, build an ID, deduplicate with `keep_latest`, split valid and invalid rows by a rule expression, and label the invalid rows with `RuleID`, `Severity`, `FailureReason`.
- **Deterministic IDs.** Condition, Procedure, Medication, Observation, and RuralUrban have no source ID, so `ConditionID` and friends are SHA-256 hashes of the business columns. Re-running produces the same ID, which makes MERGE safe.
- **Blocking rules** reject rows before Silver. Critical examples: null PatientID (DQ001), duplicate EncounterID (DQ010, newest kept). Referential rules DQ004 and DQ007 reject encounters and observations whose patient is not in Silver Patient, so Patient must load first.
- **Quarantine** receives every rejected row in `quarantine.<Entity>` with the rule and reason. Nothing is deleted.
- **MERGE** upserts valid rows into Silver on the entity key. First run creates the table.

Cell-level documentation: [HP_06_01](../../documentation/notebooks/HP_06_01_NB_BronzeToSilver.md).

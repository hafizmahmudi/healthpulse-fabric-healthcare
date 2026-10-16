# HP_07_04_NB_SilverToGold_DQ

| | |
|---|---|
| Language | T-SQL notebook |
| Attached items | HP_09_WH_DataQuality (primary warehouse), HP_03_WH_HealthAnalytics (read-only source) |
| Reads | HP_03 `dim.*` and `fact.*` through three-part names |
| Writes | HP_09 `dq.SilverToGoldDQRun` (one row per run) and `dq.SilverToGoldDQResult` (one row per check) |
| Run by | HP_07_05_PL_SilverToGold, last step |

## What it does

Runs a fixed set of checks against the Gold dimension and fact tables after they load: keys populated, business keys unique, one current SCD2 version per entity, fact grain respected, foreign keys resolve, measures not negative. Each check is stored with PASS or FAIL and the counts behind it. A run is marked FAILED if any critical check failed.

## Why it exists

The Bronze-to-Silver DQ proves the inputs were clean; this proves the warehouse load itself did not break grain, keys, or history. Writing to a separate warehouse keeps audit tables out of the analytics warehouse that reports read from.

## Cells

### Setup and run start (cells 1 to 6)

- **Cell 1** (markdown): explains the cross-warehouse setup. HP_09 must be the primary warehouse and both warehouses must be attached.
- **Cell 2** (code): creates the `dq` schema in HP_09 if missing.
- **Cell 3** (code): creates `dq.SilverToGoldDQRun` if missing (run ID, start, end, status).
- **Cell 4** (code): creates `dq.SilverToGoldDQResult` if missing (one row per check with entity, check name, type, severity, status, failed and total counts, details).
- **Cell 5** (markdown): heading "Start the DQ run".
- **Cell 6** (code): marks any run still RUNNING as ABANDONED, inserts a new RUNNING run with a new GUID, and shows it.

### Dimension checks (cells 7 to 20)

Every check cell has the same shape: find the current run, find the next result key, compute a small set of checks as a union, number them, and insert them with PASS when the failed count is zero and FAIL otherwise.

- **Cells 7, 8**: DimDate. `DateKey` populated (critical), `DateKey` unique (critical), `FullDate` unique (high).
- **Cells 9, 10**: DimPatient. `PatientID` populated, one current row per patient, `ValidTo` after `ValidFrom` (all critical).
- **Cells 11, 12**: DimFacility. `FacilityID` populated, one current row per facility.
- **Cells 13, 14**: DimProvider. `ProviderID` populated, one current row per provider.
- **Cells 15, 16**: DimPayer. `PayerID` populated, one current row per payer.
- **Cells 17, 18**: DimDiagnosis. `DiagnosisCode` populated and unique.
- **Cells 19, 20**: DimMedication. `MedicationCode` populated and unique.

### Fact checks (cells 21 to 28)

- **Cells 21, 22** (markdown): headings.
- **Cell 23** (code): FactEncounter. One row per EncounterID (grain), `PatientKey` and `DateKey` populated, `PatientKey` exists in DimPatient, and length of stay and cost measures not negative (high).
- **Cells 24, 25**: FactCondition. One row per ConditionID, `PatientKey` populated (critical), `DiagnosisKey` populated (high).
- **Cell 26** (markdown): empty heading.
- **Cells 27, 28**: FactReadmission. Patient, index encounter, and readmission encounter keys populated; days to readmission greater than zero.

### Summary and close (cells 29 to 33)

- **Cell 29** (markdown): heading "Summary".
- **Cell 30** (code): lists every result of the current run ordered by severity, entity, and check.
- **Cell 31** (markdown): heading "Close DQ check".
- **Cell 32** (code): sets the run's end time and status: FAILED if any critical check failed, otherwise PASSED.
- **Cell 33** (code): shows the latest run row.

## Notes

- No checks exist for FactMedication, FactProcedure, or FactObservation.
- The null facility, provider, and payer keys on FactEncounter are not checked, so the biggest known gap in the warehouse is invisible to this notebook.
- Earlier versions wrote to a `dq` schema inside HP_03; those tables are gone. Anything reading Gold DQ results must now read HP_09.

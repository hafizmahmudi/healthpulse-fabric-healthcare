# Technical Data Dictionary: HP_03_WH_HealthAnalytics

| Property | Value |
|---|---|
| Workspace ID | `e8daa76e-5e3f-4dd0-8444-5f84dfbabc14` |
| Item | HP_03_WH_HealthAnalytics (Fabric Warehouse) |
| Item ID | `8ff88eb6-51af-435c-8ff4-fb205d50ca34` |
| SQL endpoint | `gkq3eeoge3duff5r5zhwuvtd5m-n2t5v2b7l3ie3bcel6cn7ov4cq.datawarehouse.fabric.microsoft.com` |
| Collation | `Latin1_General_100_BIN2_UTF8` (case-sensitive, binary) |
| Created | 2026-09-28 |
| Last updated | 2026-10-08 |
| Documented on | 2026-10-08 (read-only catalog queries via the Fabric SQL Endpoint MCP server) |

> **Name note.** The request named `HP_04_WH_HealthAnalytics`. No such item exists in the workspace. The only HealthAnalytics warehouse is `HP_03_WH_HealthAnalytics`; `HP_04` is the pipeline `HP_04_PL_Health_Master`. This dictionary documents `HP_03_WH_HealthAnalytics`.

> **Keys and relationships.** The warehouse declares **no** PRIMARY KEY, UNIQUE, or FOREIGN KEY constraints (`sys.key_constraints` and `sys.foreign_keys` are empty), and no extended properties or descriptions. All keys and relationships below are **inferred** from naming conventions and then **verified against the data** (uniqueness counts and orphan checks). Fabric Warehouse supports only `NOT ENFORCED` constraints; none have been created here.

---

## 1. Schema overview

| Schema | Purpose | Tables | Views |
|---|---|---|---|
| `dim` | Gold-layer conformed dimensions (star schema) | 8 | 0 |
| `fact` | Gold-layer fact tables | 7 | 0 |
| `stg` | Staging copy used by the Silver-to-Gold load | 1 | 0 |
| `dq` | Silver-to-Gold data quality run log and check results | 2 | 0 |
| `etl` | Pipeline run audit log and processed-file register | 2 | 0 |
| `metadata` | Source ingestion configuration (metadata-driven pipeline) | 1 | 0 |
| `dbo` | Default schema, unused | 0 | 0 |
| `queryinsights` | System: Fabric Query Insights views | 0 | 6 |
| `sys`, `INFORMATION_SCHEMA`, `_rsc`, `guest`, `db_*` | System and role schemas | 0 | 7 |

User tables: **21**. System views (`queryinsights`, `sys`) are listed in Appendix A for completeness but are Fabric-managed and not part of the analytics model.

### Row counts (as of 2026-10-08)

| Table | Rows | Table | Rows |
|---|---:|---|---:|
| `dim.DimDate` | 45,484 | `fact.FactEncounter` | 15,090,025 |
| `dim.DimPatient` | 1,593,866 | `fact.FactObservation` | 62,658,749 |
| `dim.DimFacility` | 6,888 | `fact.FactCondition` | 5,809,954 |
| `dim.DimProvider` | 6,888 | `fact.FactProcedure` | 7,500,040 |
| `dim.DimPayer` | 10 | `fact.FactMedication` | 4,781,873 |
| `dim.DimDiagnosis` | 128 | `fact.FactReadmission` | 13,581,912 |
| `dim.DimProcedure` | 79 | `fact.FactFacilityDaily` | **0** |
| `dim.DimMedication` | 103 | `stg.DimPatient` | 1,593,866 |
| `dq.SilverToGoldDQRun` | 5 | `etl.PipelineRun` | 201 |
| `dq.SilverToGoldDQResult` | 62 | `etl.ProcessedFile` | **0** |
| `metadata.SourceConfig` | 13 | | |

---

## 2. Dimension tables (`dim`)

### 2.1 `dim.DimDate`
Calendar dimension. Grain: one row per calendar day, 1911-06-22 to 2035-12-31. Type 0 (static).

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | DateKey | int | NO | **PK (inferred, verified unique)** | Surrogate key in `yyyyMMdd` form (e.g. 20170528). |
| 2 | FullDate | date | NO | AK (verified unique) | Calendar date. |
| 3 | DayNumber | int | YES | | Day of month (1-31). |
| 4 | DayName | varchar(20) | YES | | Weekday name. |
| 5 | DayOfWeekNumber | int | YES | | Weekday number. |
| 6 | DayOfYear | int | YES | | Ordinal day in year (1-366). |
| 7 | WeekNumber | int | YES | | ISO/calendar week number. |
| 8 | MonthNumber | int | YES | | Month (1-12). |
| 9 | MonthName | varchar(20) | YES | | Month name. |
| 10 | QuarterNumber | int | YES | | Quarter (1-4). |
| 11 | QuarterName | varchar(10) | YES | | Quarter label (e.g. "Q1"). |
| 12 | YearNumber | int | YES | | Calendar year. |
| 13 | YearMonth | varchar(7) | YES | | `yyyy-MM` label. |
| 14 | IsWeekend | bit | YES | | 1 if Saturday or Sunday. |

### 2.2 `dim.DimPatient`
Patient dimension, SCD Type 2. Grain: one row per patient version. Currently all 1,593,866 rows are current (`IsCurrent = 1`); no history rows yet. Source: Synthea `patients.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | PatientKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | PatientID | varchar(100) | NO | BK (verified unique in current set) | Source patient identifier (Synthea UUID). |
| 3 | FirstName | varchar(200) | YES | | Patient first name. PII. |
| 4 | LastName | varchar(200) | YES | | Patient last name. PII. |
| 5 | MaritalStatus | varchar(55) | YES | | Marital status code. |
| 6 | BirthDate | date | YES | | Date of birth. 2,050 rows are null. |
| 7 | DeathDate | date | YES | | Date of death. Currently null for all rows. |
| 8 | Gender | varchar(50) | YES | | Values: Female, Male, Unknown. |
| 9 | Race | varchar(100) | YES | | Race. |
| 10 | Ethnicity | varchar(100) | YES | | Ethnicity. |
| 11 | Age | int | YES | | Age in years at load time. |
| 12 | AgeGroup | varchar(50) | YES | | Values: 5-17, 18-34, 35-49, 50-64, 65+, Unknown. |
| 13 | ValidFrom | datetime2(6) | NO | SCD2 | Version start timestamp. |
| 14 | ValidTo | datetime2(6) | NO | SCD2 | Version end timestamp; `9999-12-31 23:59:59.999999` for current row. |
| 15 | IsCurrent | bit | NO | SCD2 | 1 for the active version. |

### 2.3 `dim.DimFacility`
Healthcare organization / facility dimension, SCD Type 2. All 6,888 rows current. Source: Synthea `organizations.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | FacilityKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | FacilityID | varchar(100) | NO | BK (verified unique) | Source organization identifier. Referenced by `DimProvider.FacilityID`. |
| 3 | FacilityName | varchar(500) | YES | | Facility name. |
| 4 | Address | varchar(500) | YES | | Street address. |
| 5 | City | varchar(200) | YES | | City. |
| 6 | State | varchar(50) | YES | | State. |
| 7 | ZipCode | varchar(20) | YES | | Postal code. |
| 8 | Latitude | float | YES | | Geo latitude. |
| 9 | Longitude | float | YES | | Geo longitude. |
| 10 | Revenue | decimal(18,2) | YES | | Facility revenue (source attribute). |
| 11 | Utilization | float | YES | | Facility utilization (source attribute). |
| 12 | ValidFrom | datetime2(6) | NO | SCD2 | Version start. |
| 13 | ValidTo | datetime2(6) | NO | SCD2 | Version end; `9999-12-31` for current. |
| 14 | IsCurrent | bit | NO | SCD2 | Current-version flag. |

### 2.4 `dim.DimProvider`
Clinician / provider dimension, SCD Type 2. All 6,888 rows current. Source: Synthea `providers.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | ProviderKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | ProviderID | varchar(100) | NO | BK (verified unique) | Source provider identifier. |
| 3 | ProviderName | varchar(500) | YES | | Provider name. |
| 4 | FacilityID | varchar(100) | YES | FK (inferred) → `DimFacility.FacilityID` | Organization the provider belongs to. 0 orphans, 0 nulls. Note: this is a natural-key reference, not a surrogate-key reference. |
| 5 | Gender | varchar(50) | YES | | Provider gender. |
| 6 | Specialty | varchar(300) | YES | | Clinical specialty. |
| 7 | Address | varchar(500) | YES | | Street address. |
| 8 | City | varchar(200) | YES | | City. |
| 9 | State | varchar(50) | YES | | State. |
| 10 | ZipCode | varchar(20) | YES | | Postal code. |
| 11 | Latitude | float | YES | | Geo latitude. |
| 12 | Longitude | float | YES | | Geo longitude. |
| 13 | ValidFrom | datetime2(6) | NO | SCD2 | Version start. |
| 14 | ValidTo | datetime2(6) | NO | SCD2 | Version end. |
| 15 | IsCurrent | bit | NO | SCD2 | Current-version flag. |

### 2.5 `dim.DimPayer`
Insurance payer dimension, SCD Type 2. 10 rows, all current. Values: Aetna, Anthem, Blue Cross Blue Shield, Cigna Health, Dual Eligible, Humana, Medicaid, Medicare, NO_INSURANCE, UnitedHealthcare. Source: Synthea `payers.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | PayerKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | PayerID | varchar(100) | NO | BK (verified unique) | Source payer identifier. |
| 3 | PayerName | varchar(500) | YES | | Payer name. |
| 4 | Ownership | varchar(200) | YES | | Ownership type (e.g. government, private). |
| 5 | Address | varchar(500) | YES | | Street address. |
| 6 | City | varchar(200) | YES | | City. |
| 7 | State | varchar(100) | YES | | State. |
| 8 | ZipCode | varchar(20) | YES | | Postal code. |
| 9 | Phone | varchar(100) | YES | | Phone number. |
| 10 | ValidFrom | datetime2(6) | NO | SCD2 | Version start. |
| 11 | ValidTo | datetime2(6) | NO | SCD2 | Version end. |
| 12 | IsCurrent | bit | NO | SCD2 | Current-version flag. |

### 2.6 `dim.DimDiagnosis`
Diagnosis code lookup (SNOMED CT codes from Synthea conditions). Type 1. 128 rows.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | DiagnosisKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | DiagnosisCode | varchar(100) | NO | BK (verified unique) | Source diagnosis code. |
| 3 | DiagnosisDescription | varchar(1000) | YES | | Code description. |

### 2.7 `dim.DimProcedure`
Procedure code lookup. Type 1. 79 rows.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | ProcedureKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | ProcedureCode | varchar(100) | NO | BK (verified unique) | Source procedure code. |
| 3 | ProcedureDescription | varchar(1000) | YES | | Code description. |

### 2.8 `dim.DimMedication`
Medication code lookup (RxNorm codes). Type 1. 103 rows.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | MedicationKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | MedicationCode | varchar(100) | NO | BK (verified unique) | Source medication code. |
| 3 | MedicationDescription | varchar(1000) | YES | | Code description. |

---

## 3. Fact tables (`fact`)

### 3.1 `fact.FactEncounter`
Central transaction fact. Grain: **one row per encounter** (`EncounterID`, verified unique; DQ check "One row per EncounterID" passes). 15,090,025 rows. DateKey range 19110622 to 20170528. Source: Synthea `encounters.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | EncounterKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. Referenced by Condition, Medication, Procedure, Observation, Readmission facts. |
| 2 | EncounterID | varchar(100) | NO | BK (verified unique) | Source encounter identifier. |
| 3 | PatientKey | bigint | YES | FK → `DimPatient` | 0 nulls, 0 orphans. |
| 4 | DateKey | int | YES | FK → `DimDate` | Encounter date. 0 nulls, 0 orphans. |
| 5 | FacilityKey | bigint | YES | FK → `DimFacility` | **100% NULL** (see §5). |
| 6 | ProviderKey | bigint | YES | FK → `DimProvider` | **100% NULL** (see §5). |
| 7 | PayerKey | bigint | YES | FK → `DimPayer` | **100% NULL** (see §5). |
| 8 | EncounterCode | varchar(100) | YES | | Encounter type code. Fully populated. |
| 9 | EncounterDescription | varchar(1000) | YES | | Encounter type description. Fully populated. |
| 10 | ReasonCode | varchar(100) | YES | | Reason-for-visit code. ~72% null (10.8M). |
| 11 | ReasonDescription | varchar(1000) | YES | | Reason-for-visit description. ~72% null. |
| 12 | EncounterClass | varchar(100) | YES | | Class (ambulatory, emergency, inpatient, …). **100% NULL.** |
| 13 | StartTime | datetime2(6) | YES | | Encounter start. **100% NULL.** |
| 14 | EndTime | datetime2(6) | YES | | Encounter end. **100% NULL.** |
| 15 | LengthOfStayDays | float | YES | Measure | Length of stay. **100% NULL.** |
| 16 | BaseEncounterCost | decimal(18,2) | YES | Measure | Base cost. **100% NULL.** |
| 17 | TotalClaimCost | decimal(18,2) | YES | Measure | Total claim cost. **100% NULL.** |
| 18 | PayerCoverage | decimal(18,2) | YES | Measure | Amount covered by payer. **100% NULL.** |
| 19 | EncounterCount | int | YES | Measure | Counting measure, always 1. Fully populated. |

### 3.2 `fact.FactCondition`
Grain: one row per condition record (`ConditionID`; DQ grain check passes). 5,809,954 rows. Source: Synthea `conditions.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | ConditionFactKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | ConditionID | varchar(100) | YES | BK | Source condition identifier. |
| 3 | PatientKey | bigint | YES | FK → `DimPatient` | 7,697 nulls (DQ CRITICAL FAIL, see §5); 0 orphans. |
| 4 | EncounterKey | bigint | YES | FK → `FactEncounter` | 7,697 nulls; 0 orphans. |
| 5 | DiagnosisKey | bigint | YES | FK → `DimDiagnosis` | 0 orphans. |
| 6 | StartDateKey | int | YES | FK → `DimDate` (role: onset) | 0 orphans. |
| 7 | StopDateKey | int | YES | FK → `DimDate` (role: resolution) | 2,619,871 nulls = ongoing conditions. 0 orphans. |
| 8 | ConditionCount | int | YES | Measure | Counting measure, 1 per row. |

### 3.3 `fact.FactMedication`
Grain: one row per medication order. 4,781,873 rows. Source: Synthea `medications.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | MedicationFactKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | MedicationID | varchar(100) | YES | BK | Source medication record identifier. |
| 3 | PatientKey | bigint | YES | FK → `DimPatient` | 0 orphans. |
| 4 | EncounterKey | bigint | YES | FK → `FactEncounter` | 6,148 nulls; 0 orphans. |
| 5 | MedicationKey | bigint | YES | FK → `DimMedication` | 0 orphans. |
| 6 | StartDateKey | int | YES | FK → `DimDate` (role: start) | 0 orphans. |
| 7 | StopDateKey | int | YES | FK → `DimDate` (role: stop) | 2,601,601 nulls = active medications. |
| 8 | MedicationCount | int | YES | Measure | Counting measure. |

### 3.4 `fact.FactProcedure`
Grain: one row per procedure performed. 7,500,040 rows. Source: Synthea `procedures.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | ProcedureFactKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | ProcedureID | varchar(100) | YES | BK | Source procedure record identifier. |
| 3 | PatientKey | bigint | YES | FK → `DimPatient` | 0 orphans. |
| 4 | EncounterKey | bigint | YES | FK → `FactEncounter` | 9,431 nulls; 0 orphans. |
| 5 | ProcedureKey | bigint | YES | FK → `DimProcedure` | 0 orphans. |
| 6 | ProcedureDateKey | int | YES | FK → `DimDate` | 0 orphans. |
| 7 | ProcedureCount | int | YES | Measure | Counting measure. |

### 3.5 `fact.FactObservation`
Grain: one row per clinical observation (vitals, labs). Largest table: 62,658,749 rows. Source: Synthea `observations.csv`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | ObservationFactKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | ObservationID | varchar(100) | YES | BK | Source observation identifier. |
| 3 | PatientKey | bigint | YES | FK → `DimPatient` | 0 orphans. |
| 4 | EncounterKey | bigint | YES | FK → `FactEncounter` | 0 nulls, 0 orphans. |
| 5 | DateKey | int | YES | FK → `DimDate` | 0 orphans. |
| 6 | ObservationCode | varchar(100) | YES | | LOINC-style observation code. No lookup dimension exists (degenerate). |
| 7 | ObservationDescription | varchar(1000) | YES | | Observation description. |
| 8 | ObservationValue | varchar(500) | YES | | Raw value as text. 169,048 nulls. |
| 9 | NumericValue | float | YES | Measure | Parsed numeric value. 611,763 nulls (non-numeric observations). |
| 10 | Units | varchar(100) | YES | | Unit of measure. |
| 11 | ObservationCount | int | YES | Measure | Counting measure. |

### 3.6 `fact.FactReadmission`
Derived fact. Grain: **one row per index encounter** (`IndexEncounterKey` verified unique, 13,581,912 rows) paired with the patient's next encounter. 3,408,159 rows are flagged as 30-day readmissions.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | ReadmissionKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | PatientKey | bigint | NO | FK → `DimPatient` | 0 orphans. |
| 3 | IndexEncounterKey | bigint | NO | FK → `FactEncounter` (role: index) | Discharge encounter. Unique. 0 orphans. |
| 4 | ReadmissionEncounterKey | bigint | YES | FK → `FactEncounter` (role: readmission) | Subsequent encounter. 0 nulls, 0 orphans. |
| 5 | DischargeDate | date | YES | | Discharge date of index encounter. |
| 6 | ReadmissionDate | date | YES | | Date of the subsequent encounter. |
| 7 | DaysToReadmission | int | YES | Measure | Days between discharge and readmission. DQ rule: > 0 (passes). |
| 8 | IsReadmission30Day | bit | YES | Flag | 1 if DaysToReadmission ≤ 30. |

### 3.7 `fact.FactFacilityDaily`
Periodic snapshot / aggregate fact. Intended grain: one row per facility per day. **Currently empty (0 rows)**, almost certainly because `FactEncounter.FacilityKey` is entirely null and cannot be aggregated by facility.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | FacilityDailyKey | bigint | NO | **PK (inferred)** | Surrogate key. |
| 2 | DateKey | int | NO | FK → `DimDate`; part of natural key | Snapshot date. |
| 3 | FacilityKey | bigint | NO | FK → `DimFacility`; part of natural key | Facility. |
| 4 | PatientCount | bigint | YES | Measure | Distinct patients seen. |
| 5 | EncounterCount | bigint | YES | Measure | Encounters. |
| 6 | EmergencyVisitCount | bigint | YES | Measure | Encounters with class = emergency. |
| 7 | InpatientVisitCount | bigint | YES | Measure | Encounters with class = inpatient. |
| 8 | OutpatientVisitCount | bigint | YES | Measure | Encounters with class = outpatient/ambulatory. |
| 9 | ReadmissionCount | bigint | YES | Measure | 30-day readmissions. |
| 10 | AverageLengthOfStay | float | YES | Measure | Mean LOS in days. |
| 11 | TotalEncounterCost | decimal(18,2) | YES | Measure | Sum of encounter cost. |
| 12 | AverageEncounterCost | decimal(18,2) | YES | Measure | Mean encounter cost. |

---

## 4. Operational tables (`stg`, `dq`, `etl`, `metadata`)

### 4.1 `stg.DimPatient`
Staging landing for the patient dimension load. All text columns are `varchar(max)` (raw Silver shape). 1,593,866 rows; every `PatientID` exists in `dim.DimPatient` (0 orphans). Contains extra raw PII not carried into `dim.DimPatient` (SSN, Drivers, Maiden, BirthPlace, Address).

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | PatientID | varchar(max) | YES | Source patient identifier. |
| 2 | BirthDate | date | YES | Date of birth. |
| 3 | SSN | varchar(max) | YES | Social Security Number. **Sensitive PII.** |
| 4 | Drivers | varchar(max) | YES | Driver's licence number. **Sensitive PII.** |
| 5 | Prefix | varchar(max) | YES | Name prefix. |
| 6 | FirstName | varchar(max) | YES | First name. |
| 7 | LastName | varchar(max) | YES | Last name. |
| 8 | Maiden | varchar(max) | YES | Maiden name. |
| 9 | MaritalStatus | varchar(max) | YES | Marital status. |
| 10 | Race | varchar(max) | YES | Race. |
| 11 | Ethnicity | varchar(max) | YES | Ethnicity. |
| 12 | Gender | varchar(max) | YES | Gender. |
| 13 | BirthPlace | varchar(max) | YES | Place of birth. |
| 14 | Address | varchar(max) | YES | Home address. **PII.** |
| 15 | Age | bigint | YES | Age in years. |
| 16 | AgeGroup | varchar(max) | YES | Age band. |

### 4.2 `dq.SilverToGoldDQRun`
Header row per data-quality run. 5 rows.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | DQRunID | varchar(100) | NO | **PK (inferred, verified unique)** | Run GUID. |
| 2 | StartTime | datetime2(6) | NO | | Run start. |
| 3 | EndTime | datetime2(6) | YES | | Run end. |
| 4 | Status | varchar(20) | NO | | Run status. |

### 4.3 `dq.SilverToGoldDQResult`
One row per check executed per run. 62 rows. Every `DQRunID` matches a run header (0 orphans).

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | DQResultKey | bigint | NO | **PK (inferred, verified unique)** | Surrogate key. |
| 2 | DQRunID | varchar(100) | NO | FK → `SilverToGoldDQRun` | Run identifier. |
| 3 | DQRunTime | datetime2(6) | NO | | Check execution time. |
| 4 | LayerName | varchar(50) | NO | | Layer checked (observed: Gold). |
| 5 | EntityName | varchar(100) | NO | | Table checked (e.g. FactEncounter). |
| 6 | CheckName | varchar(500) | NO | | Human-readable check name. |
| 7 | CheckType | varchar(100) | NO | | Values: COMPLETENESS, UNIQUENESS, REFERENTIAL_INTEGRITY, GRAIN, SCD2, BUSINESS_RULE. |
| 8 | Severity | varchar(20) | NO | | Values: CRITICAL, HIGH. |
| 9 | Status | varchar(20) | NO | | Values: PASS, FAIL. |
| 10 | FailedCount | bigint | YES | | Rows failing the check. |
| 11 | TotalCount | bigint | YES | | Rows evaluated. |
| 12 | Details | varchar(2000) | YES | | Rule description. |

### 4.4 `etl.PipelineRun`
Pipeline execution audit log. 201 rows, 18 distinct `RunID` values (a run writes one row per entity, so `RunID` is **not** unique; the natural key is `RunID + EntityName`). All rows have Status = SUCCESS. Pipeline name logged: `HP_05_PL_Health_Master`.

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | RunID | varchar(100) | YES | Pipeline run identifier (shared across entities in one run). |
| 2 | PipelineName | varchar(100) | YES | Pipeline name. |
| 3 | EntityName | varchar(100) | YES | Source entity processed (patients, encounters, conditions, observations, procedures, medications, organizations, providers, payers, hospitals, jobs, people, income, rural_urban). |
| 4 | StartTime | datetime2(6) | YES | Activity start. |
| 5 | EndTime | datetime2(6) | YES | Activity end. |
| 6 | Status | varchar(30) | YES | Observed: SUCCESS. |
| 7 | RowsRead | bigint | YES | Rows read from source. |
| 8 | RowsWritten | bigint | YES | Rows written to target. |
| 9 | RowsRejected | bigint | YES | Rows rejected (all 0 so far). |
| 10 | DurationSeconds | int | YES | Elapsed seconds. |
| 11 | ErrorMessage | varchar(4000) | YES | Error text, if any. |
| 12 | BatchID | varchar(100) | YES | Batch correlation identifier. |

### 4.5 `etl.ProcessedFile`
Register of source files already ingested (idempotency control). **Currently empty.**

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | SourceId | int | YES | FK → `metadata.SourceConfig` | Source definition. |
| 2 | FilePath | varchar(1000) | YES | | Full path of the file. |
| 3 | FileName | varchar(500) | YES | | File name. |
| 4 | ProcessedAt | datetime2(6) | YES | | Ingestion timestamp. |
| 5 | BatchID | varchar(100) | YES | | Batch correlation identifier. |
| 6 | Status | varchar(30) | YES | | Processing status. |

### 4.6 `metadata.SourceConfig`
Metadata-driven ingestion configuration. 13 active sources, all CSV, landing in Bronze tables of the lakehouse `HP_01_LH_Health_Bronze`.

| # | Column | Type | Nullable | Key | Description |
|---|---|---|---|---|---|
| 1 | SourceId | int | NO | **PK (inferred, verified unique)** | Source identifier (1-13). |
| 2 | SourceName | varchar(100) | YES | | Source system: SYNTHEA (1-9), USDA_ERS (10-12), USDA_RURAL_URBAL (13). |
| 3 | SourceEntity | varchar(100) | YES | | Entity: patients, encounters, conditions, observations, procedures, medications, organizations, providers, payers, jobs, people, income, rural_urban. |
| 4 | SourcePath | varchar(500) | YES | | Lakehouse file path under `Files/synthea/extracted/…`. |
| 5 | SourceFormat | varchar(20) | YES | | Observed: CSV. |
| 6 | TargetTable | varchar(100) | YES | | Bronze target table (`bronze_<entity>`). |
| 7 | LoadType | varchar(30) | YES | | Full or Incremental. |
| 8 | WatermarkColumn | varchar(100) | YES | | Source column for incremental loads (DATE or START); null for Full. |
| 9 | LastWatermark | datetime2(6) | YES | | Last processed watermark. Currently null for all rows. |
| 10 | IsActive | bit | YES | | 1 = source enabled. All 13 active. |

---

## 5. Relationships (inferred and verified)

No constraints are declared. The following relationships are inferred from column names and verified with orphan checks on 2026-10-08. All verified relationships have **0 orphan rows**.

### 5.1 Star-schema relationships

| From (fact) | Column | To (dimension) | Column | Cardinality | Nulls in FK | Orphans |
|---|---|---|---|---|---|---|
| fact.FactEncounter | PatientKey | dim.DimPatient | PatientKey | N:1 | 0 | 0 |
| fact.FactEncounter | DateKey | dim.DimDate | DateKey | N:1 | 0 | 0 |
| fact.FactEncounter | FacilityKey | dim.DimFacility | FacilityKey | N:1 | **15,090,025 (all)** | n/a |
| fact.FactEncounter | ProviderKey | dim.DimProvider | ProviderKey | N:1 | **15,090,025 (all)** | n/a |
| fact.FactEncounter | PayerKey | dim.DimPayer | PayerKey | N:1 | **15,090,025 (all)** | n/a |
| fact.FactCondition | PatientKey | dim.DimPatient | PatientKey | N:1 | 7,697 | 0 |
| fact.FactCondition | EncounterKey | fact.FactEncounter | EncounterKey | N:1 | 7,697 | 0 |
| fact.FactCondition | DiagnosisKey | dim.DimDiagnosis | DiagnosisKey | N:1 | 0 | 0 |
| fact.FactCondition | StartDateKey | dim.DimDate | DateKey | N:1 (role) | 0 | 0 |
| fact.FactCondition | StopDateKey | dim.DimDate | DateKey | N:1 (role) | 2,619,871 | 0 |
| fact.FactMedication | PatientKey | dim.DimPatient | PatientKey | N:1 | 0 | 0 |
| fact.FactMedication | EncounterKey | fact.FactEncounter | EncounterKey | N:1 | 6,148 | 0 |
| fact.FactMedication | MedicationKey | dim.DimMedication | MedicationKey | N:1 | 0 | 0 |
| fact.FactMedication | StartDateKey | dim.DimDate | DateKey | N:1 (role) | 0 | 0 |
| fact.FactMedication | StopDateKey | dim.DimDate | DateKey | N:1 (role) | 2,601,601 | 0 |
| fact.FactProcedure | PatientKey | dim.DimPatient | PatientKey | N:1 | 0 | 0 |
| fact.FactProcedure | EncounterKey | fact.FactEncounter | EncounterKey | N:1 | 9,431 | 0 |
| fact.FactProcedure | ProcedureKey | dim.DimProcedure | ProcedureKey | N:1 | 0 | 0 |
| fact.FactProcedure | ProcedureDateKey | dim.DimDate | DateKey | N:1 | 0 | 0 |
| fact.FactObservation | PatientKey | dim.DimPatient | PatientKey | N:1 | 0 | 0 |
| fact.FactObservation | EncounterKey | fact.FactEncounter | EncounterKey | N:1 | 0 | 0 |
| fact.FactObservation | DateKey | dim.DimDate | DateKey | N:1 | 0 | 0 |
| fact.FactReadmission | PatientKey | dim.DimPatient | PatientKey | N:1 | 0 | 0 |
| fact.FactReadmission | IndexEncounterKey | fact.FactEncounter | EncounterKey | 1:1 (role) | 0 | 0 |
| fact.FactReadmission | ReadmissionEncounterKey | fact.FactEncounter | EncounterKey | N:1 (role) | 0 | 0 |
| fact.FactFacilityDaily | DateKey | dim.DimDate | DateKey | N:1 | empty table | – |
| fact.FactFacilityDaily | FacilityKey | dim.DimFacility | FacilityKey | N:1 | empty table | – |

### 5.2 Dimension-to-dimension and operational relationships

| From | Column | To | Column | Cardinality | Orphans |
|---|---|---|---|---|---|
| dim.DimProvider | FacilityID | dim.DimFacility | FacilityID | N:1 (natural key) | 0 |
| stg.DimPatient | PatientID | dim.DimPatient | PatientID | 1:1 | 0 |
| dq.SilverToGoldDQResult | DQRunID | dq.SilverToGoldDQRun | DQRunID | N:1 | 0 |
| etl.ProcessedFile | SourceId | metadata.SourceConfig | SourceId | N:1 | empty table |

### 5.3 Entity-relationship sketch

```
                        DimDate ───────────────────────────────┐
                           │ (DateKey / Start / Stop / Procedure roles)
   DimPatient ──┐          │                                   │
   DimFacility ─┤  (keys)  │                                   │
   DimProvider ─┼──► FactEncounter ◄── FactCondition ◄── DimDiagnosis
   DimPayer    ─┘      ▲   ▲   ▲   ▲
                       │   │   │   └── FactMedication ◄── DimMedication
                       │   │   └────── FactProcedure  ◄── DimProcedure
                       │   └────────── FactObservation
                       └────────────── FactReadmission (Index + Readmission roles)

   DimProvider.FacilityID ──► DimFacility.FacilityID
   FactFacilityDaily ──► DimDate, DimFacility        (empty)

   metadata.SourceConfig ◄── etl.ProcessedFile       (empty)
   dq.SilverToGoldDQRun  ◄── dq.SilverToGoldDQResult
```

---

## 6. Data quality observations

Findings from this profiling pass and from the latest DQ run (`F934AA98-…`, 2026-10-08 22:09):

1. **FactEncounter is missing its facility, provider, and payer context.** `FacilityKey`, `ProviderKey`, and `PayerKey` are null on all 15.09M rows, as are `EncounterClass`, `StartTime`, `EndTime`, `LengthOfStayDays`, `BaseEncounterCost`, `TotalClaimCost`, and `PayerCoverage`. Only `EncounterCode`, `EncounterDescription`, `ReasonCode`, `ReasonDescription`, `PatientKey`, `DateKey`, and `EncounterCount` are populated. The Silver-to-Gold fact load (`HP_07_03_NB_SilverToGold_Load_Fact`) appears not to map these source columns. The DQ suite does not currently check these columns, so the gap is invisible to the DQ log.
2. **FactFacilityDaily is empty.** It depends on `FacilityKey` and `EncounterClass`, both null in FactEncounter, so the aggregate cannot be built until item 1 is fixed.
3. **FactCondition has 7,697 rows with null PatientKey and EncounterKey.** This is the only CRITICAL FAIL in the latest DQ run ("PatientKey populated"). FactMedication (6,148) and FactProcedure (9,431) have null `EncounterKey` but are not checked by the DQ suite.
4. **No declared constraints.** Consider adding `PRIMARY KEY … NOT ENFORCED` and `FOREIGN KEY … NOT ENFORCED` on the keys in §5 so that tooling (Power BI, lineage, this dictionary) can read them from the catalog. This is a change and was not performed.
5. **SCD2 dimensions have no history yet.** Every row in DimPatient, DimFacility, DimProvider, and DimPayer is current; `ValidTo` is the sentinel `9999-12-31`.
6. **PII exposure in staging.** `stg.DimPatient` carries SSN, driver's licence, maiden name, and address in `varchar(max)`. Consider restricting access or dropping the staging table after load.
7. **etl.ProcessedFile is empty and `LastWatermark` is null** for all sources, so idempotency and incremental-load tracking are not yet in use.
8. **DQ result duplication.** FactCondition checks appear twice in the latest run (two `DQRunTime` values 8 seconds apart), suggesting the notebook executed that entity twice.
9. **etl.PipelineRun records `HP_05_PL_Health_Master`**, while the workspace item is named `HP_04_PL_Health_Master`. The pipeline was likely renamed after the log rows were written.
10. **Date range.** Encounters span 1911-06-22 to 2017-05-28, consistent with Synthea synthetic lifetimes.

---

## Appendix A. System views (Fabric-managed, read-only)

| Schema | View | Purpose |
|---|---|---|
| queryinsights | exec_requests_history | Completed statement history (30 columns: timing, CPU, scanned MB, status, command text). |
| queryinsights | exec_sessions_history | Session history (34 columns). |
| queryinsights | external_api_call_stats | AI/external function call statistics. |
| queryinsights | frequently_run_queries | Aggregated by query hash. |
| queryinsights | long_running_queries | Median elapsed time by query hash. |
| queryinsights | sql_pool_insights | Pool pressure and capacity snapshot. |
| sys | managed_delta_tables, managed_delta_table_log_files, managed_delta_table_checkpoints, managed_delta_table_forks | Delta Lake log bookkeeping for warehouse tables. |
| sys | external_delta_tables, dm_db_external_tables_log_status | Delta log state for shortcut/external tables. |
| sys | sys_dw_schemas | Warehouse schema list with internal flag. |

## Appendix B. Method

All information was collected with read-only queries through the Fabric SQL Endpoint MCP server (`execute_query`) plus one Fabric REST `GET …/items` call to resolve the item ID:

- `sys.schemas`, `INFORMATION_SCHEMA.TABLES`, `INFORMATION_SCHEMA.COLUMNS` for structure.
- `sys.key_constraints`, `sys.foreign_keys`, `sys.extended_properties` for declared metadata (all empty for user objects).
- `COUNT_BIG(*)`, `COUNT_BIG(DISTINCT …)` for row counts and key uniqueness.
- `LEFT JOIN … IS NULL` aggregations for orphan and null-FK checks.
- Sampled `DISTINCT` values for low-cardinality columns.

No objects were created, modified, or deleted.

# Architecture diagrams

Seven diagrams, each a plain-text Mermaid file (`*.mmd`). GitHub renders Mermaid inline, so every page that needs a diagram carries the text inside a Mermaid code fence and there are no image files to keep in sync. One visual language throughout: a bold name with a one-line description in each box, grey lanes for layers and workspaces, blue for data stores and serving items, grey for notebooks and pipelines, amber for rules, loops and notes, dashed for things outside the workspace.

| Diagram | Shows | Used in |
|---|---|---|
| [system-architecture.mmd](system-architecture.mmd) | Sources to consumption, every Fabric item in its lane | [README](../README.md), [architecture.md](../documentation/architecture.md) |
| [solution-structure.mmd](solution-structure.mmd) | The full inventory as a tree: capacity, deployment pipeline, stages, workspaces, item groups and every item | [deployment.md](../documentation/deployment.md) |
| [medallion-architecture.mmd](medallion-architecture.mmd) | Bronze, Silver, Gold: the rule each layer enforces, its tables, and the notebooks that move data between them | [architecture.md](../documentation/architecture.md) |
| [data-model.mmd](data-model.mmd) | Star schema overview: conformed dimensions, FactEncounter, the detail facts and code dimensions, SCD2 markers | [data-model.md](../documentation/data-model.md) |
| [data-model-erd.mmd](data-model-erd.mmd) | Column-level entity-relationship diagram: every key, type and SCD2 column | linked from [data-model.md](../documentation/data-model.md) |
| [pipeline-orchestration.mmd](pipeline-orchestration.mmd) | The three pipelines as lanes, with ForEach loops, notebook parameters and the run order | [pipelines/README.md](../pipelines/README.md) |
| [data-quality-flow.mmd](data-quality-flow.mmd) | How a row is standardized, keyed, checked, quarantined, audited and reported, then the Gold checks | [data-quality.md](../documentation/data-quality.md) |

## System architecture

```mermaid
%%{init: {"flowchart": {"curve": "linear", "wrappingWidth": 360, "nodeSpacing": 30, "rankSpacing": 50}}}%%
flowchart LR
    subgraph SRC[Sources]
        S1[Synthea clinical CSV and Parquet]
        S2[USDA county data: rural-urban, income, jobs, people]
    end

    subgraph ING[Ingestion - Fabric Data Factory]
        P0[HP_05_01 download raw files]
        P1["<b>HP_04_PL_Health_Master</b><br/><small>Lookup metadata.SourceConfig, ForEach source</small>"]
        P2["<b>HP_05_02 metadata-driven loader</b><br/><small>Full or Incremental</small>"]
    end

    subgraph BRZ[HP_01_LH_Health_Bronze]
        B1[("<b>bronze.* Delta tables</b><br/><small>raw + ingestion metadata</small>")]
    end

    subgraph SLV[HP_02_LH_Health_Silver]
        T1["<b>HP_06_01 PySpark transform</b><br/><small>rename, type, dedupe, block</small>"]
        T2[HP_06_02 DQ audit]
        B2[(clinical.* reference.* population.*)]
        Q[(quarantine.*)]
        D1[(dq.Rule / Run / Result / RejectedRecord)]
    end

    subgraph GLD[HP_03_WH_HealthAnalytics]
        G1[HP_07_01 structure]
        G2[HP_07_02 dimensions + SCD2]
        G3[HP_07_03 facts + readmissions]
        B3[(dim.* fact.* star schema)]
    end

    subgraph DQW[HP_09_WH_DataQuality]
        D2[(Gold DQ runs and checks)]
    end

    subgraph SRV[Consumption]
        SM["<b>HP_10_SM_HealthAnalytics</b><br/><small>Direct Lake semantic model</small>"]
        RPT["<b>HP_11_RPT_HealthPulse</b><br/><small>7-page Power BI report</small>"]
        APP["<b>HP_12_APP_HealthPulse</b><br/><small>Fabric App + data function</small>"]
    end

    S1 --> P0 --> P1
    S2 --> P0
    P1 --> P2 --> B1
    B1 --> T1 --> B2
    T1 --> Q
    B2 --> T2 --> D1
    B2 --> G1 --> G2 --> G3 --> B3
    G3 -. HP_07_04 checks .-> D2
    B3 --> SM --> RPT
    D1 --> SM
    SM --> APP

    classDef external fill:#ffffff,stroke:#6b7280,stroke-dasharray:4 3,color:#111827
    classDef code fill:#f3f4f6,stroke:#6b7280,color:#111827
    classDef store fill:#dbeafe,stroke:#1d4ed8,color:#111827
    classDef serve fill:#dbeafe,stroke:#1d4ed8,stroke-width:2px,color:#111827
    class S1,S2 external
    class P0,P1,P2,T1,T2,G1,G2,G3 code
    class B1,B2,Q,D1,B3,D2 store
    class SM,RPT,APP serve
```

## Solution structure

```mermaid
%%{init: {"flowchart": {"curve": "linear", "wrappingWidth": 420, "nodeSpacing": 14, "rankSpacing": 70}}}%%
flowchart LR
    CAP["<b>Fabric capacity</b><br/><small>Trial FTL64, East US 2<br/>shared by all three workspaces</small>"]
    DP["<b>HP_DP_HealthPulse</b><br/><small>Fabric deployment pipeline<br/>3 stages, deploy Development to Test to Production</small>"]
    CAP --> DP

    %% declared in reverse so dagre places Development at the top and Production at the bottom
    S3["<b>Stage 3 - Production</b><br/><small>consumption, public stage</small>"]
    S2["<b>Stage 2 - Test</b><br/><small>validation, private stage</small>"]
    S1["<b>Stage 1 - Development</b><br/><small>build and test, public stage</small>"]
    DP --> S3
    DP --> S2
    DP --> S1

    subgraph WS1["Workspace HealthPulse-DEV - 22 items"]
        G1LH["<b>Lakehouses</b><br/><small>2, schema-enabled</small>"]
        G1WH["<b>Warehouses</b><br/><small>2</small>"]
        G1PL["<b>Data pipelines</b><br/><small>3</small>"]
        G1NB["<b>Notebooks</b><br/><small>9</small>"]
        G1SM["<b>Semantic model</b><br/><small>1, Direct Lake</small>"]
        G1RP["<b>Report</b><br/><small>1, thin report</small>"]
        G1AP["<b>Application</b><br/><small>Fabric App + user data function</small>"]

        I01["<b>HP_01_LH_Health_Bronze</b><br/><small>landing files, bronze.* source-shaped Delta tables</small>"]
        I02["<b>HP_02_LH_Health_Silver</b><br/><small>clinical, reference, population, quarantine, dq, ops</small>"]
        I03["<b>HP_03_WH_HealthAnalytics</b><br/><small>Gold star schema: dim.*, fact.*, metadata, etl</small>"]
        I09["<b>HP_09_WH_DataQuality</b><br/><small>Gold DQ runs and check results</small>"]
        I04["<b>HP_04_PL_Health_Master</b><br/><small>metadata-driven ingestion + Silver load</small>"]
        I0603["<b>HP_06_03_PL_BronzeToSilver</b><br/><small>Silver load and audit on their own</small>"]
        I0705["<b>HP_07_05_PL_SilverToGold</b><br/><small>structure, dimensions, facts, Gold DQ</small>"]
        I0501["<b>HP_05_01_NB_SourceIngestion</b><br/><small>download and land raw files</small>"]
        I0502["<b>HP_05_02_NB_MetadataIngestion</b><br/><small>generic loader, full or incremental</small>"]
        I0601["<b>HP_06_01_NB_BronzeToSilver</b><br/><small>PySpark transform, blocking rules, MERGE</small>"]
        I0602["<b>HP_06_02_NB_BronzeToSilver_DQ</b><br/><small>Silver audit, dq.Run / Result / RejectedRecord</small>"]
        I0701["<b>HP_07_01_NB_SilverToGold_Structure</b><br/><small>warehouse DDL</small>"]
        I0702["<b>HP_07_02_NB_SilverToGold_Load_Dim</b><br/><small>dimensions, SCD Type 2</small>"]
        I0703["<b>HP_07_03_NB_SilverToGold_Load_Fact</b><br/><small>facts, readmissions</small>"]
        I0704["<b>HP_07_04_NB_SilverToGold_DQ</b><br/><small>28 Gold checks per load</small>"]
        I08["<b>HP_08_NB_LakehouseOptimization</b><br/><small>Delta OPTIMIZE / VACUUM, ops log</small>"]
        I10["<b>HP_10_SM_HealthAnalytics</b><br/><small>Direct Lake over HP_03 and Silver dq tables</small>"]
        I11["<b>HP_11_RPT_HealthPulse</b><br/><small>7 pages, custom theme</small>"]
        I12["<b>HP_12_APP_HealthPulse</b><br/><small>Fabric App</small>"]
        I12C["<b>hp_12_app_healthpulse_connector</b><br/><small>user data function behind the app</small>"]

        G1LH --> I01 & I02
        G1WH --> I03 & I09
        G1PL --> I04 & I0603 & I0705
        G1NB --> I0501 & I0502 & I0601 & I0602 & I0701 & I0702 & I0703 & I0704 & I08
        G1SM --> I10
        G1RP --> I11
        G1AP --> I12 & I12C
    end

    subgraph WS2["Workspace HealthPulse-TEST - 2 items"]
        G2AP["<b>Application</b><br/><small>deployed from Development</small>"]
        T12["<b>hp-12-app-healthpulse</b><br/><small>Fabric App</small>"]
        T12C["<b>hp_12_app_healthpulse_connector</b><br/><small>user data function</small>"]
        G2AP --> T12 & T12C
    end

    subgraph WS3["Workspace HealthPulse-PROD - 2 items"]
        G3AP["<b>Application</b><br/><small>deployed from Test</small>"]
        P12["<b>hp-12-app-healthpulse</b><br/><small>Fabric App</small>"]
        P12C["<b>hp_12_app_healthpulse_connector</b><br/><small>user data function</small>"]
        G3AP --> P12 & P12C
    end

    S1 --> G1LH & G1WH & G1PL & G1NB & G1SM & G1RP & G1AP
    S2 --> G2AP
    S3 --> G3AP

    NOTE["<b>Promotion</b><br/><small>Only the application layer has been deployed through the pipeline so far.<br/>Data items are promoted from Development once the solution stabilizes.</small>"]
    S3 ~~~ NOTE

    classDef control fill:#ffffff,stroke:#6b7280,color:#111827
    classDef group fill:#e5e7eb,stroke:#6b7280,color:#111827
    classDef store fill:#dbeafe,stroke:#1d4ed8,color:#111827
    classDef code fill:#f3f4f6,stroke:#6b7280,color:#111827
    classDef serve fill:#dbeafe,stroke:#1d4ed8,stroke-width:2px,color:#111827
    classDef note fill:#fffbeb,stroke:#d97706,color:#111827
    class CAP,DP,S1,S2,S3 control
    class G1LH,G1WH,G1PL,G1NB,G1SM,G1RP,G1AP,G2AP,G3AP group
    class I01,I02,I03,I09 store
    class I04,I0603,I0705,I0501,I0502,I0601,I0602,I0701,I0702,I0703,I0704,I08 code
    class I10,I11,I12,I12C,T12,T12C,P12,P12C serve
    class NOTE note

    style WS1 fill:#f8fafc,stroke:#cbd5e1,color:#64748b
    style WS2 fill:#f8fafc,stroke:#cbd5e1,color:#64748b
    style WS3 fill:#f8fafc,stroke:#cbd5e1,color:#64748b
```

## Medallion architecture

```mermaid
%%{init: {"flowchart": {"curve": "linear", "wrappingWidth": 360, "nodeSpacing": 30, "rankSpacing": 50}}}%%
flowchart TB
    subgraph Bronze[Bronze - HP_01_LH_Health_Bronze]
        BF["<b>Files/synthea/raw and extracted</b><br/><small>original downloads, CSV copies</small>"]
        BT[(bronze.bronze_patients, bronze_encounters, ... 13 tables)]
        BN["<b>Rule: keep the source shape.</b><br/><small>Add _ingestion_timestamp, _source_system,<br/>_source_entity, _pipeline_run_id</small>"]
        BF --> BT
    end

    subgraph Silver[Silver - HP_02_LH_Health_Silver]
        ST[(clinical.Patient, Encounter, Condition,<br/>Procedure, Medication, Observation)]
        SR[(reference.Facility, Provider, Payer)]
        SP[(population.RuralUrban, USDAIncome,<br/>usda_job, USDAPeople)]
        SQ[(quarantine.* one table per entity)]
        SD[(dq.Rule, dq.Run, dq.Result,<br/>dq.RejectedRecord)]
        SN["<b>Rule: one clean row per business key.</b><br/><small>Typed columns, standard names, deterministic IDs,<br/>blocking rules, MERGE upsert</small>"]
    end

    subgraph Gold[Gold - HP_03_WH_HealthAnalytics]
        GD[(dim.DimDate, DimPatient, DimFacility, DimProvider,<br/>DimPayer, DimDiagnosis, DimMedication, DimProcedure)]
        GF[(fact.FactEncounter, FactCondition, FactMedication,<br/>FactProcedure, FactObservation, FactReadmission, FactFacilityDaily)]
        GO[(metadata.SourceConfig, etl.PipelineRun, stg.DimPatient)]
        GN["<b>Rule: business-ready star schema.</b><br/><small>Surrogate keys, SCD Type 2,<br/>additive measures, validated grain</small>"]
    end

    BT -- "HP_06_01 PySpark<br/>per entity" --> ST
    BT --> SR
    BT --> SP
    BT -. rejected rows .-> SQ
    ST -. "HP_06_02 audit" .-> SD
    ST -- "HP_07_02 / HP_07_03 T-SQL<br/>cross-database reads" --> GD
    SR --> GD
    ST --> GF
    GD --> GF

    classDef files fill:#ffffff,stroke:#6b7280,stroke-dasharray:4 3,color:#111827
    classDef store fill:#dbeafe,stroke:#1d4ed8,color:#111827
    classDef note fill:#fffbeb,stroke:#d97706,color:#111827
    class BF files
    class BT,ST,SR,SP,SQ,SD,GD,GF,GO store
    class BN,SN,GN note
```

## Star schema

```mermaid
%%{init: {"flowchart": {"curve": "linear", "wrappingWidth": 360, "nodeSpacing": 30, "rankSpacing": 60}}}%%
flowchart TB
    subgraph DIMS["CONFORMED DIMENSIONS - dim schema, surrogate keys"]
        DimDate["<b>DimDate</b><br/><small>DateKey, FullDate, Year, Month,<br/>Quarter, DayName, IsWeekend</small>"]
        DimPatient["<b>DimPatient</b> &nbsp;SCD2<br/><small>Gender, Race, Ethnicity, Age,<br/>AgeGroup, MaritalStatus</small>"]
        DimFacility["<b>DimFacility</b> &nbsp;SCD2<br/><small>FacilityName, City, State,<br/>Revenue</small>"]
        DimProvider["<b>DimProvider</b> &nbsp;SCD2<br/><small>Specialty, FacilityID</small>"]
        DimPayer["<b>DimPayer</b> &nbsp;SCD2<br/><small>PayerName, Ownership</small>"]
    end

    subgraph FACTS["FACTS - fact schema, additive measures"]
        FactEncounter["<b>FactEncounter</b><br/><small>grain: one encounter. PatientKey, DateKey, FacilityKey,<br/>ProviderKey, PayerKey, TotalClaimCost, EncounterCount</small>"]
        NoteEnc["one row per encounter<br/>resolves five keys with SCD2-aware lookups"]
        FactCondition["<b>FactCondition</b><br/><small>per condition on an encounter<br/>DiagnosisKey, Start/StopDateKey</small>"]
        FactMedication["<b>FactMedication</b><br/><small>per medication order<br/>MedicationKey, Start/StopDateKey</small>"]
        FactProcedure["<b>FactProcedure</b><br/><small>per procedure<br/>ProcedureKey, ProcedureDateKey</small>"]
        FactObservation["<b>FactObservation</b><br/><small>per observation<br/>code, value, units, 62.7M rows</small>"]
        FactReadmission["<b>FactReadmission</b><br/><small>derived: index + readmission encounter,<br/>DaysToReadmission, IsReadmission30Day</small>"]
        FactFacilityDaily["<b>FactFacilityDaily</b><br/><small>derived: facility x day<br/>counts and cost</small>"]
    end

    subgraph CODES["CODE DIMENSIONS - used by one fact each"]
        DimDiagnosis["<b>DimDiagnosis</b><br/><small>DiagnosisCode, Description</small>"]
        DimMedication["<b>DimMedication</b><br/><small>MedicationCode, Description</small>"]
        DimProcedure["<b>DimProcedure</b><br/><small>ProcedureCode, Description</small>"]
        NoteRoles["DimDate also plays the Start, Stop, Procedure and Discharge date roles<br/>on the detail facts. DimProvider carries FacilityID back to DimFacility."]
    end

    subgraph LEGEND["Legend"]
        LF["Fact table"]
        LD["Dimension"]
        LS["SCD2 dimension<br/><small>ValidFrom, ValidTo, IsCurrent</small>"]
        LA["Arrow: foreign key, pointing at the table that holds the key"]
    end

    DimDate --> FactEncounter
    DimPatient --> FactEncounter
    DimFacility --> FactEncounter
    DimProvider --> FactEncounter
    DimPayer --> FactEncounter
    DimPayer ~~~ NoteEnc

    FactEncounter -- "PatientKey and DateKey repeat<br/>on every detail fact" --> FactCondition
    FactEncounter --> FactMedication
    FactEncounter --> FactProcedure
    FactEncounter --> FactObservation
    FactEncounter -- "EncounterKey, linked twice:<br/>index and readmission" --> FactReadmission
    FactEncounter --> FactFacilityDaily

    %% invisible edges keep the code dimensions below the facts; the visible arrows point up into the fact
    FactCondition ~~~ DimDiagnosis
    FactMedication ~~~ DimMedication
    FactProcedure ~~~ DimProcedure
    FactFacilityDaily ~~~ NoteRoles
    DimDiagnosis --> FactCondition
    DimMedication --> FactMedication
    DimProcedure --> FactProcedure

    NoteRoles ~~~ LF
    NoteRoles ~~~ LD
    NoteRoles ~~~ LS
    NoteRoles ~~~ LA

    classDef fact fill:#dbeafe,stroke:#1d4ed8,color:#111827
    classDef dim fill:#f3f4f6,stroke:#6b7280,color:#111827
    classDef scd2 fill:#f3f4f6,stroke:#1d4ed8,stroke-width:2px,color:#111827
    classDef note fill:transparent,stroke:transparent,color:#374151
    class FactEncounter,FactCondition,FactMedication,FactProcedure,FactObservation,FactReadmission,FactFacilityDaily,LF fact
    class DimDate,DimDiagnosis,DimMedication,DimProcedure,LD dim
    class DimPatient,DimFacility,DimProvider,DimPayer,LS scd2
    class NoteEnc,NoteRoles,LA note

    style DIMS fill:#f8fafc,stroke:#cbd5e1,color:#64748b
    style FACTS fill:#f8fafc,stroke:#cbd5e1,color:#64748b
    style CODES fill:#f8fafc,stroke:#cbd5e1,color:#64748b
    style LEGEND fill:transparent,stroke:transparent
```

## Star schema, column level

```mermaid
erDiagram
    DimDate ||--o{ FactEncounter : "DateKey"
    DimPatient ||--o{ FactEncounter : "PatientKey"
    DimFacility ||--o{ FactEncounter : "FacilityKey"
    DimProvider ||--o{ FactEncounter : "ProviderKey"
    DimPayer ||--o{ FactEncounter : "PayerKey"

    FactEncounter ||--o{ FactCondition : "EncounterKey"
    FactEncounter ||--o{ FactMedication : "EncounterKey"
    FactEncounter ||--o{ FactProcedure : "EncounterKey"
    FactEncounter ||--o{ FactObservation : "EncounterKey"
    FactEncounter ||--o| FactReadmission : "IndexEncounterKey"
    FactEncounter ||--o{ FactReadmission : "ReadmissionEncounterKey"

    DimPatient ||--o{ FactCondition : "PatientKey"
    DimPatient ||--o{ FactMedication : "PatientKey"
    DimPatient ||--o{ FactProcedure : "PatientKey"
    DimPatient ||--o{ FactObservation : "PatientKey"
    DimPatient ||--o{ FactReadmission : "PatientKey"

    DimDiagnosis ||--o{ FactCondition : "DiagnosisKey"
    DimMedication ||--o{ FactMedication : "MedicationKey"
    DimProcedure ||--o{ FactProcedure : "ProcedureKey"
    DimDate ||--o{ FactCondition : "StartDateKey, StopDateKey"
    DimDate ||--o{ FactMedication : "StartDateKey, StopDateKey"
    DimDate ||--o{ FactProcedure : "ProcedureDateKey"
    DimDate ||--o{ FactObservation : "DateKey"
    DimDate ||--o{ FactReadmission : "DateKey"
    DimDate ||--o{ FactFacilityDaily : "DateKey"
    DimFacility ||--o{ FactFacilityDaily : "FacilityKey"
    DimFacility ||--o{ DimProvider : "FacilityID (natural key)"

    DimDate {
        int DateKey PK
        date FullDate
        int YearNumber
        int MonthNumber
        string MonthName
        string QuarterName
        string DayName
        bit IsWeekend
    }
    DimPatient {
        bigint PatientKey PK
        string PatientID UK
        string Gender
        string Race
        string Ethnicity
        int Age
        string AgeGroup
        string MaritalStatus "SCD2 tracked"
        datetime ValidFrom
        datetime ValidTo
        bit IsCurrent
    }
    DimFacility {
        bigint FacilityKey PK
        string FacilityID UK
        string FacilityName
        string City
        string State
        decimal Revenue
        datetime ValidFrom
        datetime ValidTo
        bit IsCurrent
    }
    DimProvider {
        bigint ProviderKey PK
        string ProviderID UK
        string FacilityID FK
        string Specialty
        datetime ValidFrom
        datetime ValidTo
        bit IsCurrent
    }
    DimPayer {
        bigint PayerKey PK
        string PayerID UK
        string PayerName
        string Ownership
        datetime ValidFrom
        datetime ValidTo
        bit IsCurrent
    }
    DimDiagnosis {
        bigint DiagnosisKey PK
        string DiagnosisCode UK
        string DiagnosisDescription
    }
    DimMedication {
        bigint MedicationKey PK
        string MedicationCode UK
        string MedicationDescription
    }
    DimProcedure {
        bigint ProcedureKey PK
        string ProcedureCode UK
        string ProcedureDescription
    }
    FactEncounter {
        bigint EncounterKey PK
        string EncounterID UK
        bigint PatientKey FK
        int DateKey FK
        bigint FacilityKey FK
        bigint ProviderKey FK
        bigint PayerKey FK
        string EncounterDescription
        string ReasonDescription
        decimal TotalClaimCost
        int EncounterCount
    }
    FactCondition {
        bigint ConditionFactKey PK
        bigint PatientKey FK
        bigint EncounterKey FK
        bigint DiagnosisKey FK
        int StartDateKey FK
        int StopDateKey FK
        int ConditionCount
    }
    FactMedication {
        bigint MedicationFactKey PK
        bigint PatientKey FK
        bigint EncounterKey FK
        bigint MedicationKey FK
        int StartDateKey FK
        int StopDateKey FK
        int MedicationCount
    }
    FactProcedure {
        bigint ProcedureFactKey PK
        bigint PatientKey FK
        bigint EncounterKey FK
        bigint ProcedureKey FK
        int ProcedureDateKey FK
        int ProcedureCount
    }
    FactObservation {
        bigint ObservationFactKey PK
        bigint PatientKey FK
        bigint EncounterKey FK
        int DateKey FK
        string ObservationCode
        string ObservationValue
        float NumericValue
        string Units
    }
    FactReadmission {
        bigint ReadmissionKey PK
        bigint PatientKey FK
        bigint IndexEncounterKey FK
        bigint ReadmissionEncounterKey FK
        int DateKey FK
        date DischargeDate
        date ReadmissionDate
        int DaysToReadmission
        bit IsReadmission30Day
    }
    FactFacilityDaily {
        bigint FacilityDailyKey PK
        int DateKey FK
        bigint FacilityKey FK
        bigint EncounterCount
        bigint ReadmissionCount
        decimal TotalEncounterCost
    }
```

## Pipeline orchestration

```mermaid
%%{init: {"flowchart": {"curve": "linear", "wrappingWidth": 360, "nodeSpacing": 30, "rankSpacing": 50}}}%%
flowchart TB
    subgraph M[HP_04_PL_Health_Master]
        M0[Notebook: ingestion utilities] --> M1["<b>Lookup: metadata.SourceConfig</b><br/><small>WHERE IsActive = 1</small>"]
        M1 --> M2{"<b>ForEach source</b><br/><small>sequential</small>"}
        M2 --> M3["<b>Notebook HP_05_02_NB_MetadataIngestion</b><br/><small>params: SourceId, SourceName, SourceEntity,<br/>SourcePath, SourceFormat, TargetTable,<br/>LoadType, WatermarkColumn, LastWatermark, PipelineRunId</small>"]
        M3 --> M4["<b>Script: INSERT etl.PipelineRun</b><br/><small>RowsRead / RowsWritten from notebook exit JSON</small>"]
        M4 --> M5["<b>Notebook HP_06_01_NB_BronzeToSilver</b><br/><small>params: PipelineRunId, EntityName, SourceName</small>"]
        M5 --> M2
        M2 --> M6[Notebook HP_08 Delta optimization]
    end

    subgraph S[HP_06_03_PL_BronzeToSilver]
        S1[Lookup: metadata.SourceConfig] --> S2{ForEach entity: load}
        S2 --> S3[Notebook HP_06_01_NB_BronzeToSilver]
        S3 --> S2
        S2 --> S4{ForEach entity: audit}
        S4 --> S5["<b>Notebook HP_06_02_NB_BronzeToSilver_DQ</b><br/><small>same PipelineRunId</small>"]
        S5 --> S4
    end

    subgraph G[HP_07_05_PL_SilverToGold]
        G1[Notebook HP_07_01 structure] --> G2[Notebook HP_07_02 load dimensions]
        G2 --> G3[Notebook HP_07_03 load facts]
        G3 --> G4[Notebook HP_07_04 Gold DQ, writes HP_09_WH_DataQuality]
    end

    M --> S --> G

    classDef code fill:#f3f4f6,stroke:#6b7280,color:#111827
    classDef control fill:#dbeafe,stroke:#1d4ed8,color:#111827
    classDef loop fill:#fffbeb,stroke:#d97706,color:#111827
    class M0,M3,M5,M6,S3,S5,G1,G2,G3,G4 code
    class M1,M4,S1 control
    class M2,S2,S4 loop
```

## Data quality flow

```mermaid
%%{init: {"flowchart": {"curve": "linear", "wrappingWidth": 360, "nodeSpacing": 30, "rankSpacing": 50}}}%%
flowchart LR
    A[("<b>Bronze table</b><br/><small>one entity</small>")] --> B[Rename, cast, standardize]
    B --> C["<b>Build deterministic ID</b><br/><small>SHA-256 of business columns<br/>when the source has no ID</small>"]
    C --> D["<b>keep_latest</b><br/><small>newest ingestion per key</small>"]
    D --> E{"<b>Blocking rules</b><br/><small>DQ001-DQ010 and<br/>DQ_ENTITY validation</small>"}
    E -- valid --> F["<b>Referential check</b><br/><small>PatientID exists in Silver Patient<br/>DQ004 / DQ007</small>"]
    F -- valid --> G[(Silver table<br/>Delta MERGE on key)]
    E -- invalid --> H[(quarantine.Entity<br/>RuleID, Severity, FailureReason,<br/>RunID, FailureTimestamp)]
    F -- orphan --> H

    G --> I["<b>HP_06_02 audit</b><br/><small>same PipelineRunId</small>"]
    H --> I
    I --> J[(dq.Result<br/>one row per applicable rule:<br/>RecordsChecked, RecordsFailed, FailurePct)]
    I --> K[(dq.RejectedRecord<br/>central JSON copy of each rejected row)]
    I --> L[(dq.Run<br/>TotalRecords, ValidRecords,<br/>RejectedRecords, DQScore)]
    J --> M["<b>HP_10 semantic model</b><br/><small>DQRun, DQResult, DQRule tables</small>"]
    L --> M
    M --> N["<b>HP_11 report</b><br/><small>Data Quality & Pipeline Health page</small>"]

    G --> O[HP_07 Gold loads]
    O --> P["<b>HP_07_04 Gold checks</b><br/><small>grain, completeness, uniqueness,<br/>SCD2, referential integrity</small>"]
    P --> Q[(HP_09_WH_DataQuality<br/>SilverToGoldDQRun / Result)]

    classDef code fill:#f3f4f6,stroke:#6b7280,color:#111827
    classDef store fill:#dbeafe,stroke:#1d4ed8,color:#111827
    classDef gate fill:#fffbeb,stroke:#d97706,color:#111827
    classDef reject fill:#fee2e2,stroke:#b91c1c,color:#111827
    classDef serve fill:#dbeafe,stroke:#1d4ed8,stroke-width:2px,color:#111827
    class B,C,D,I,O,P code
    class A,G,J,K,L,Q store
    class E,F gate
    class H reject
    class M,N serve
```

## How to edit

1. Edit the `.mmd` file in any text editor. Paste it into [mermaid.live](https://mermaid.live) for an instant preview, or open a pull request and GitHub renders it in the diff view.
2. Copy the new text into every page listed in the **Used in** column, replacing the body of the matching Mermaid code fence. The pages embed a copy because GitHub does not include one Markdown file in another.
3. Keep the `%%{init}%%` line and the `classDef` lines so new nodes pick up the shared spacing and colours. A box is `Id["<b>Name</b><br/><small>description</small>"]`; assign it to a class with `class Id store` (or `code`, `serve`, `note`).
4. `data-model.mmd` keeps the code dimensions below the facts with invisible `~~~` edges; add the invisible edge first and the visible arrow after it when adding a dimension there.

To export a PNG, for example for the repository social preview, use **Actions > PNG** on mermaid.live, or run the Mermaid CLI (needs Node and a local Chrome or Edge):

```bash
npx -y @mermaid-js/mermaid-cli -i architecture/system-architecture.mmd -o system-architecture.png -b white -s 2
```

`data-model-erd.mmd` is the reference for key names; if a column is renamed in the warehouse, change it there first and then in [warehouse-data-dictionary.md](../documentation/warehouse-data-dictionary.md).

## Change log

### 2026-10-10: restyled diagrams and solution structure tree

- Rebuilt the star schema (`data-model.mmd`) in the original lane design: conformed dimensions, facts and code dimensions as lanes, bold names with a description line, blue facts, grey dimensions, SCD2 marks, edge notes and a legend. The column-level entity-relationship diagram is kept as `data-model-erd.mmd`.
- Added `solution-structure.mmd`: capacity, the HP_DP_HealthPulse deployment pipeline, its three stages, the workspace under each stage, item groups and every item. Built from the live workspace inventory. It replaces `environments.mmd` on the deployment page.
- Applied the same bold-name-plus-description boxes and shared spacing to the system, medallion, pipeline and data quality diagrams.
- Refreshed every inline Mermaid block in `README.md`, `documentation/` and `pipelines/README.md` from the sources, and updated this page's table and editing notes for seven diagrams.

### 2026-10-09: Mermaid replaces SVG and PNG

- Replaced the generated SVG and PNG files and their Python generator scripts with Mermaid text that GitHub renders inline.
- Gave the five flowcharts one colour scheme: blue for data stores and serving items, grey for notebooks and pipelines, amber for rules, loops and notes, dashed for things outside the workspace.

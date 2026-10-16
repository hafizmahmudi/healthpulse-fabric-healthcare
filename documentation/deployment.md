# Deployment and environments

## Workspaces

| Workspace | Role | Current contents |
|---|---|---|
| HealthPulse-DEV | Build and test | All 22 items: lakehouses, warehouses, notebooks, pipelines, semantic model, report, app, data function |
| HealthPulse-TEST | Validation | Fabric App backend and its data function |
| HealthPulse-PROD | Consumption | Fabric App backend and its data function |

All three run on the same Fabric capacity.

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
        I04["<b>HP_04_PL_Health_Master</b><br/><small>end-to-end run: ingestion loop, then invokes the Silver and Gold pipelines, then maintenance</small>"]
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

The diagram shows the capacity, the deployment pipeline and its stages, and every item in each workspace. Its source is [architecture/solution-structure.mmd](../architecture/solution-structure.mmd).

## Deployment pipeline

`HP_DP_HealthPulse` has three stages, Development, Test, Production, mapped to the three workspaces. The application layer has been promoted through all stages; the data items are promoted as the DEV solution stabilizes. Promotion is selective per item, so a semantic model change can move without re-deploying notebooks.

## What is parameterized

- Notebooks resolve lakehouse and warehouse names from constants at the top of each notebook (`BRONZE_LAKEHOUSE`, `SILVER_LAKEHOUSE`) and from attached default items, so the same notebook runs in any workspace once attachments are rebound.
- Pipelines reference notebooks by item ID; deployment pipeline rules rebind them per stage.
- The semantic model's two Direct Lake expressions hold the workspace and item IDs of the warehouse and the Silver lakehouse; these are the values to override with deployment rules per stage.
- The report is a thin report bound to the semantic model by name and workspace.

## Source control

This repository holds the notebooks, pipeline definitions, warehouse SQL, semantic model TMDL, and report PBIP. The intended workflow is Fabric Git integration on the DEV workspace against a `dev` branch, pull requests into `main`, and promotion through the deployment pipeline. Until Git integration is connected, definitions are exported with the Fabric REST API and committed here.

## Failure handling and re-runs

- The ingestion loader returns row counts even on empty loads and the pipeline logs every activity, so a failed or empty source is visible in `etl.PipelineRun`.
- Silver loads are MERGE-based and the DQ audit deletes its own rows for a run before writing, so re-running a run ID is safe.
- Gold loads are update-then-insert keyed on business IDs, so a partial run can be repeated.
- Gold DQ marks a run FAILED on any critical failure so promotion can be gated on it.

# Semantic model: HP_10_SM_HealthAnalytics

The TMDL definition exported from Fabric is in [HP_10_SM_HealthAnalytics/](HP_10_SM_HealthAnalytics/). It can be deployed with the Fabric REST API (`createItemWithDefinition`), opened in Power BI Desktop as a PBIP, or edited with Tabular Editor.

## Design

- **Storage mode:** Direct Lake on OneLake. Two named expressions point at the warehouse (`dim`, `fact`, `etl`, `metadata` schemas) and the Silver lakehouse (`dq` schema). No import, no refresh schedule beyond framing.
- **Tables:** 8 dimensions, 6 facts, `PipelineRun`, `SourceConfig`, `DQRun`, `DQResult`, `DQRule`, and a dedicated `Health Measures` table.
- **Relationships:** 22, all single-direction many-to-one. Role-playing date keys (condition start and stop, medication start and stop) use one active and one inactive relationship.
- **Date table:** `DimDate` is marked as the date table; auto date/time is disabled; month, quarter, and day names sort by their number columns.
- **Measures:** 70+ in `Health Measures`, grouped in display folders.

| Folder | Examples |
|---|---|
| Encounters | `# Encounters`, `# Patients Seen`, `Encounters per Patient`, `Average Length of Stay (days)` |
| Clinical Activity | `# Conditions`, `# Active Conditions`, `# Procedures`, `# Medications`, `# Observations` |
| Readmissions | `# Index Encounters`, `# 30-Day Readmissions`, `30-Day Readmission Rate (%)`, `Average Days to Readmission` |
| Patients | `# Patients` (current SCD2 version only), `Average Patient Age` |
| Financial | `Total Claim Cost`, `Total Payer Coverage`, `Patient Out of Pocket`, `Payer Coverage (%)` |
| Prior Year | `(ly)` variants via `SAMEPERIODLASTYEAR`, `vs ly (%)` and `vs ly (pp)` variances |
| Data Quality | `DQ Score`, `DQ Score (latest run)`, `# DQ Rules Failed`, `# Critical DQ Failures`, `DQ Records Rejected` |
| Pipeline Health | `# Pipeline Runs`, `Pipeline Success Rate (%)`, `Pipeline Rows Written`, `Last Pipeline Run` |

Every measure has a format string and a description. Measures that depend on source columns that are not yet populated say so in their description.

## Example DAX

```dax
30-Day Readmission Rate (%) =
DIVIDE ( [# 30-Day Readmissions], [# Index Encounters] )

# Encounters (ly) =
CALCULATE ( [# Encounters], SAMEPERIODLASTYEAR ( 'DimDate'[FullDate] ) )

30-Day Readmission Rate vs ly (pp) =
( [30-Day Readmission Rate (%)] - [30-Day Readmission Rate (%) (ly)] ) * 100

DQ Score (latest run) =
VAR _id = [Latest DQ Pipeline Run ID]
RETURN CALCULATE ( [DQ Score], 'DQRun'[PipelineRunID] = _id )
```

## Deploying

The model was authored through the Fabric REST definition API (export, edit TMDL, update) because the capacity's XMLA endpoint is read-only. The same round-trip works for any change: edit a `.tmdl` file, base64-encode all parts, call `updateDefinition`, then refresh the model if tables were added.

# AI validation

## Status

A Fabric Data Agent over `HP_10_SM_HealthAnalytics` is on the roadmap and is not yet built. This page holds the validation protocol that will be used when it is, so the agent is tested rather than merely demonstrated.

## Protocol

For every question, record the natural-language prompt, the trusted answer computed with DAX against the semantic model, the agent's answer, and PASS or FAIL. A result passes only if the number matches exactly or the agent's wording matches the trusted ranking.

| # | Question | Trusted DAX | Trusted result (2016) | Agent result | Status |
|---|---|---|---|---|---|
| 1 | How many encounters were there in 2016? | `CALCULATE([# Encounters], 'DimDate'[YearNumber] = 2016)` | 2,141,568 | | |
| 2 | How many distinct patients were seen in 2016? | `CALCULATE([# Patients Seen], ...)` | 1,009,589 | | |
| 3 | What was the 30-day readmission rate in 2016? | `CALCULATE([30-Day Readmission Rate (%)], ...)` | 30.68 % | | |
| 4 | Which age group has the highest readmission rate? | `TOPN(1, SUMMARIZECOLUMNS('DimPatient'[AgeGroup], "r", [30-Day Readmission Rate (%)]), [r])` | 18-34 | | |
| 5 | What is the most common encounter type? | `TOPN(1, ... 'FactEncounter'[EncounterDescription] ... [# Encounters])` | Outpatient Encounter | | |
| 6 | Which diagnosis is recorded most often? | `TOPN(1, ... 'DimDiagnosis'[DiagnosisDescription] ... [# Conditions])` | Viral sinusitis (disorder) | | |
| 7 | How did encounters in 2016 compare with 2015? | `[# Encounters vs ly (%)]` | -0.13 % | | |
| 8 | Which month of 2016 had the highest readmission rate? | by `'DimDate'[MonthName]` | December, 41.7 % | | |
| 9 | What is the data quality score for the latest pipeline run? | `[DQ Score (latest run)]` | 100.0 | | |
| 10 | Which source entity has the lowest data quality score? | by `'DQRun'[EntityName]` on `[DQ Score]` | USDAPeople, 55.5 | | |
| 11 | How many rows has the ingestion pipeline written in total? | `[Pipeline Rows Written]` | 1,504,701,785 | | |
| 12 | How many patients are registered? | `[# Patients]` | 1,593,866 | | |
| 13 | What share of encounters have a recorded reason? | `DIVIDE([# Encounters with Reason], [# Encounters])` | 28.2 % | | |
| 14 | How many conditions are currently active? | `[# Active Conditions]` | 2,619,871 | | |
| 15 | Which gender has the higher readmission rate? | by `'DimPatient'[Gender]` | Female, 27.6 % vs 21.7 % | | |

Trusted results were computed on 2026-10-09 and will be recomputed when the agent is tested.

## Guardrails to configure

- Restrict the agent to the semantic model so it inherits measure definitions and the readmission proxy caveat.
- Provide the definitions of "readmission" and "patients seen" versus "registered patients" as agent instructions.
- Log every tested question here with its date; do not report an untested capability.

# Notebooks

The nine Fabric notebooks, exported as `.ipynb` and grouped by layer. Each has a page in [documentation/notebooks/](../documentation/notebooks/) that explains its purpose and every cell in plain language.

| Folder | Notebook | Language | Attach to | Role |
|---|---|---|---|---|
| bronze/ | HP_05_01_NB_SourceIngestion | Python | Bronze lakehouse | Download raw files into OneLake |
| bronze/ | HP_05_02_NB_MetadataIngestion | PySpark | Bronze lakehouse, HP_03 warehouse | Generic file-to-Bronze loader |
| silver/ | HP_06_01_NB_BronzeToSilver | PySpark | Silver (default), Bronze | Transform, validate, quarantine, MERGE |
| quality/ | HP_06_02_NB_BronzeToSilver_DQ | PySpark | Silver (default), Bronze | Audit a load run into `dq.*` |
| gold/ | HP_07_01_NB_SilverToGold_Structure | T-SQL | HP_03 warehouse | Create star-schema DDL |
| gold/ | HP_07_02_NB_SilverToGold_Load_Dim | T-SQL | HP_03 warehouse, Silver | Dimensions, surrogate keys, SCD2 |
| gold/ | HP_07_03_NB_SilverToGold_Load_Fact | T-SQL | HP_03 warehouse, Silver | Facts, readmissions, facility-daily |
| quality/ | HP_07_04_NB_SilverToGold_DQ | T-SQL | HP_09 (primary), HP_03 | Gold checks |
| maintenance/ | HP_08_NB_LakehouseOptimization | PySpark | Silver | OPTIMIZE, V-Order, VACUUM, logging |

## Conventions

- The first code cell of every pipeline-driven notebook holds default parameters. The pipeline overrides them.
- Bronze and Silver rows carry `_ingestion_timestamp`, `_source_system`, `_source_entity`, `_pipeline_run_id`.
- Blocking rules live in the Silver loader; measurement lives in the DQ notebook.
- T-SQL notebooks read Silver through the lakehouse SQL endpoint with three-part names such as `[HP_02_LH_Health_Silver].[clinical].[encounter]`.

## Importing

In the Fabric workspace choose **Import > Notebook > From this computer**, select the `.ipynb`, then attach the lakehouse or warehouse listed above before running. Attachments are stored in notebook metadata and may need to be re-pointed to your item IDs.

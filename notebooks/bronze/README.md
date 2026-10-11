# Bronze notebooks

**HP_05_01_NB_SourceIngestion** downloads the Synthea clinical ZIP, the Synthea organizations, providers, and payers Parquet files, and the USDA county files into `Files/synthea/raw`, then writes CSV copies with ingestion metadata under `Files/synthea/extracted`. Run once per environment.

**HP_05_02_NB_MetadataIngestion** is the single loader behind every Bronze table. It receives one `metadata.SourceConfig` row as parameters, reads the file (CSV or Parquet), sanitizes column names for Delta, stamps metadata, and writes `bronze.<TargetTable>` as a full overwrite or an incremental append filtered by the watermark column. It returns row counts to the pipeline as JSON.

Cell-level documentation: [HP_05_01](../../documentation/notebooks/HP_05_01_NB_SourceIngestion.md), [HP_05_02](../../documentation/notebooks/HP_05_02_NB_MetadataIngestion.md).

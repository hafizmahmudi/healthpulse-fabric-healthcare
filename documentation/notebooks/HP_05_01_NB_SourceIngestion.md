# HP_05_01_NB_SourceIngestion

| | |
|---|---|
| Language | PySpark notebook, mostly plain Python (`requests`, `pandas`, `zipfile`) |
| Attached items | HP_01_LH_Health_Bronze (default lakehouse) |
| Reads | Public URLs on Hugging Face and the USDA Economic Research Service |
| Writes | Bronze lakehouse **Files** only: `Files/synthea/raw` (original downloads) and `Files/synthea/extracted/...` (CSV copies ready for loading) |
| Run by | First activity of HP_04_PL_Health_Master (activity name `HP_06_NB_IngestionUtilities`); can also be run by hand once per environment. |

## What it does

Downloads every raw source file the platform uses and lands it in the Bronze lakehouse file area. Clinical data comes from a Synthea synthetic patient dataset; county-level population and economic data comes from the USDA; organizations, providers, and payers come from a second Synthea dataset. Everything is converted to CSV so that the metadata-driven loader (HP_05_02) can treat all sources the same way.

## Why it exists

The loader needs files that already sit inside OneLake and have a predictable path and format. This notebook is the only place that touches the internet. Keeping it separate means the rest of the pipeline never depends on external availability.

## Cells

### Synthea clinical data (cells 1 to 13)

- **Cell 1** (markdown): heading "Synthea".
- **Cell 2** (markdown): note that `raw` and `extracted` folders will be created.
- **Cell 3** (code): imports `os` and `re`.
- **Cell 4** (code): defines the four folder paths (raw, extracted/clinical, extracted/external, extracted/external/atlas) and creates them if missing.
- **Cell 5** (markdown): heading "Download the compressed file".
- **Cell 6** (code): streams the Synthea ZIP from Hugging Face into `raw/synthea_data.zip`, 1 MB at a time.
- **Cell 7** (markdown): heading "Extract the gzip" (it is actually a ZIP).
- **Cell 8** (code): checks the download is a valid ZIP and extracts all files into `extracted/clinical`.
- **Cell 9** (code): walks the extracted folder and prints every file path, as a visual check.
- **Cell 10** (markdown): heading "Test patients.csv file and schema".
- **Cells 11, 12, 13** (code, all commented out): optional spot checks that would read `patients.csv` with Spark, print its schema, and count rows. Disabled; safe to ignore.

### Geographic and population data from USDA (cells 14 to 20)

- **Cell 14** (markdown): heading "Geo/Population Data".
- **Cell 15** (markdown): wish list of county attributes to obtain (population, income, poverty, insurance, rural/urban class, facility availability).
- **Cell 16** (markdown): heading for the USDA 2023 Rural-Urban Continuum Codes.
- **Cell 17** (code): downloads two USDA files into `raw`: the rural-urban CSV and the Rural Atlas workbook. The second URL points at a web page rather than a file, so that download is unlikely to be a usable workbook; cell 20 downloads the real workbook directly.
- **Cell 18** (code): reads the rural-urban CSV with Spark, adds `_ingestion_timestamp` and `_source_system`, and saves it as a single CSV in `extracted/external`. Contains an unused branch for a CMS hospital file.
- **Cell 19** (markdown): note that the Excel file will be read and stamped with metadata.
- **Cell 20** (code): opens the USDA Rural Atlas Excel workbook straight from its URL with pandas, and saves every sheet (Jobs, People, Income, and others) as its own CSV in `extracted/external/atlas`, each stamped with ingestion metadata.

### Additional Synthea reference data (cells 21 to 23)

- **Cell 21** (markdown): empty heading.
- **Cell 22** (markdown): heading listing Organizations, Payers, Providers.
- **Cell 23** (code): for each of `organizations.parquet`, `providers.parquet`, `payers.parquet`: downloads the Parquet file to `raw`, reads it with pandas, adds `_ingestion_timestamp`, `_source_system`, `_source_file`, and saves it as CSV in `extracted/clinical`. Prints row and column counts.

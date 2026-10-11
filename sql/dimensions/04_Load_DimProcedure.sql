-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load DimProcedure

-- ============================================================
-- DimProcedure Load
--
-- Source:
--   HP_02_LH_Health_Silver.clinical.procedure
--
-- Target:
--   dim.DimProcedure
--
-- Business Key:
--   ProcedureCode
--
-- Surrogate Key:
--   ProcedureKey
--
-- SCD:
--   Type 1
-- ============================================================


-- ============================================================
-- 1. Prepare one row per ProcedureCode
-- ============================================================

WITH ProcedureRanked AS
(
    SELECT
        ProcedureCode,
        ProcedureDescription,

        ROW_NUMBER() OVER
        (
            PARTITION BY ProcedureCode
            ORDER BY ProcedureDate DESC
        ) AS rn

    FROM [HP_02_LH_Health_Silver].[clinical].[procedure]

    WHERE ProcedureCode IS NOT NULL
),

ProcedureSource AS
(
    SELECT
        ProcedureCode,
        ProcedureDescription

    FROM ProcedureRanked

    WHERE rn = 1
),

MaxKey AS
(
    SELECT
        ISNULL(MAX(ProcedureKey), 0) AS MaxProcedureKey

    FROM dim.DimProcedure
),

ProcedurePrepared AS
(
    SELECT
        s.ProcedureCode,
        s.ProcedureDescription,

        m.MaxProcedureKey
        +
        ROW_NUMBER() OVER
        (
            ORDER BY s.ProcedureCode
        ) AS NewProcedureKey

    FROM ProcedureSource AS s

    CROSS JOIN MaxKey AS m
)


-- ============================================================
-- 2. Merge into DimProcedure
-- ============================================================

MERGE INTO dim.DimProcedure AS target

USING ProcedurePrepared AS source

ON target.ProcedureCode = source.ProcedureCode


-- ============================================================
-- Existing ProcedureCode
-- Update descriptive attributes
-- ============================================================

WHEN MATCHED
AND
(
       ISNULL(target.ProcedureDescription, '')
       <>
       ISNULL(source.ProcedureDescription, '')
)
THEN

UPDATE SET
    target.ProcedureDescription =
        source.ProcedureDescription


-- ============================================================
-- New ProcedureCode
-- Insert new dimension member
-- ============================================================

WHEN NOT MATCHED BY TARGET
THEN

INSERT
(
    ProcedureKey,
    ProcedureCode,
    ProcedureDescription
)

VALUES
(
    source.NewProcedureKey,
    source.ProcedureCode,
    source.ProcedureDescription
);

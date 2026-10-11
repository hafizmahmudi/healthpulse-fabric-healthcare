-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load DimProvider

-- ============================================================
-- DimProvider - SCD Type 2
--
-- Source:
--   HP_02_LH_Health_Silver.reference.provider
--
-- Target:
--   dim.DimProvider
--
-- Business Key:
--   ProviderID
--
-- Surrogate Key:
--   ProviderKey
--
-- SCD Type 2:
--   FacilityID
--   Address
--   City
--   State
--   ZipCode
--   Latitude
--   Longitude
--
-- Type 1:
--   ProviderName
--   Gender
--   Specialty
-- ============================================================


DECLARE @LoadTime DATETIME2(6) = SYSUTCDATETIME();


-- ============================================================
-- 1. Expire current provider record when an SCD2
--    attribute changes
-- ============================================================

UPDATE target

SET
    target.ValidTo   = @LoadTime,
    target.IsCurrent = 0

FROM dim.DimProvider AS target

INNER JOIN
(
    SELECT
        ProviderID,
        FacilityID,
        ProviderName,
        Gender,
        Specialty,
        Address,
        City,
        State,
        ZipCode,
        Latitude,
        Longitude

    FROM [HP_02_LH_Health_Silver].[reference].[provider]

    WHERE ProviderID IS NOT NULL

) AS source

    ON target.ProviderID = source.ProviderID

WHERE
    target.IsCurrent = 1

    AND
    (
           ISNULL(target.FacilityID, '')
           <> ISNULL(source.FacilityID, '')

        OR ISNULL(target.Address, '')
           <> ISNULL(source.Address, '')

        OR ISNULL(target.City, '')
           <> ISNULL(source.City, '')

        OR ISNULL(target.State, '')
           <> ISNULL(source.State, '')

        OR ISNULL(target.ZipCode, '')
           <> ISNULL(source.ZipCode, '')

        OR ISNULL(target.Latitude, 0)
           <> ISNULL(source.Latitude, 0)

        OR ISNULL(target.Longitude, 0)
           <> ISNULL(source.Longitude, 0)
    );


-- ============================================================
-- 2. Find current maximum ProviderKey
-- ============================================================

DECLARE @MaxProviderKey BIGINT;

SELECT
    @MaxProviderKey =
        ISNULL(MAX(ProviderKey), 0)

FROM dim.DimProvider;


-- ============================================================
-- 3. Prepare source
-- ============================================================

WITH ProviderSource AS
(
    SELECT
        ProviderID,
        FacilityID,
        ProviderName,
        Gender,
        Specialty,
        Address,
        City,
        State,
        ZipCode,
        Latitude,
        Longitude

    FROM [HP_02_LH_Health_Silver].[reference].[provider]

    WHERE ProviderID IS NOT NULL
),


-- ============================================================
-- 4. Find providers that need inserting
--
-- Includes:
--   1. Completely new providers
--   2. New versions of providers expired in Step 1
-- ============================================================

ProvidersToInsert AS
(
    SELECT
        source.ProviderID,
        source.FacilityID,
        source.ProviderName,
        source.Gender,
        source.Specialty,
        source.Address,
        source.City,
        source.State,
        source.ZipCode,
        source.Latitude,
        source.Longitude,

        ROW_NUMBER() OVER
        (
            ORDER BY source.ProviderID
        ) AS RowNumber

    FROM ProviderSource AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM dim.DimProvider AS target

        WHERE
            target.ProviderID = source.ProviderID
            AND target.IsCurrent = 1
    )
)


-- ============================================================
-- 5. Insert new providers and new SCD2 versions
-- ============================================================

INSERT INTO dim.DimProvider
(
    ProviderKey,
    ProviderID,

    FacilityID,

    ProviderName,
    Gender,
    Specialty,

    Address,
    City,
    State,
    ZipCode,

    Latitude,
    Longitude,

    ValidFrom,
    ValidTo,
    IsCurrent
)

SELECT
    @MaxProviderKey + RowNumber,

    ProviderID,

    FacilityID,

    ProviderName,
    Gender,
    Specialty,

    Address,
    City,
    State,
    ZipCode,

    Latitude,
    Longitude,

    @LoadTime,

    CAST(
        '9999-12-31 23:59:59.999999'
        AS DATETIME2(6)
    ),

    1

FROM ProvidersToInsert;


-- ============================================================
-- 6. Type 1 update
--
-- ProviderName, Gender and Specialty are updated on the
-- current record without creating another historical version.
-- ============================================================

UPDATE target

SET
    target.ProviderName = source.ProviderName,
    target.Gender       = source.Gender,
    target.Specialty    = source.Specialty

FROM dim.DimProvider AS target

INNER JOIN
(
    SELECT
        ProviderID,
        ProviderName,
        Gender,
        Specialty

    FROM [HP_02_LH_Health_Silver].[reference].[provider]

    WHERE ProviderID IS NOT NULL

) AS source

    ON target.ProviderID = source.ProviderID

WHERE
    target.IsCurrent = 1;


-- ============================================================
-- 7. Summary
-- ============================================================

SELECT
    COUNT(*) AS TotalProviderRows,

    COUNT(DISTINCT ProviderID)
        AS UniqueProviders,

    SUM(
        CASE
            WHEN IsCurrent = 1
            THEN 1
            ELSE 0
        END
    ) AS CurrentRows,

    SUM(
        CASE
            WHEN IsCurrent = 0
            THEN 1
            ELSE 0
        END
    ) AS HistoricalRows

FROM dim.DimProvider;


-- ============================================================
-- 8. Validate
--
-- Expected result:
--   zero rows
-- ============================================================

SELECT
    ProviderID,
    COUNT(*) AS CurrentVersions

FROM dim.DimProvider

WHERE IsCurrent = 1

GROUP BY ProviderID

HAVING COUNT(*) > 1;

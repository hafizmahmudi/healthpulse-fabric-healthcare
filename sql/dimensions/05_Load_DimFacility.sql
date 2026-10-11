-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load DimFacility

-- ============================================================
-- DimFacility - SCD Type 2
--
-- Source:
--   HP_02_LH_Health_Silver.reference.facility
--
-- Target:
--   dim.DimFacility
--
-- Business Key:
--   FacilityID
--
-- Surrogate Key:
--   FacilityKey
--
-- SCD Type 2:
--   FacilityName
--   Address
--   City
--   State
--   ZipCode
--   Latitude
--   Longitude
--   Phone
--
-- Type 1:
--   Revenue
--   Utilization
-- ============================================================


DECLARE @LoadTime DATETIME2(6) = SYSUTCDATETIME();


-- ============================================================
-- 1. Expire current Facility record when an SCD2
--    attribute changes
-- ============================================================

UPDATE target

SET
    target.ValidTo   = @LoadTime,
    target.IsCurrent = 0

FROM dim.DimFacility AS target

INNER JOIN
(
    SELECT
        FacilityID,
        FacilityName,
        Address,
        City,
        State,
        ZipCode,
        Latitude,
        Longitude,
        Phone,
        Revenue,
        Utilization

    FROM [HP_02_LH_Health_Silver].[reference].[facility]

    WHERE FacilityID IS NOT NULL

) AS source

    ON target.FacilityID = source.FacilityID

WHERE
    target.IsCurrent = 1

    AND
    (
           ISNULL(target.FacilityName, '')
           <> ISNULL(source.FacilityName, '')
        AND ISNULL(target.Phone, '')
           <> ISNULL(source.Phone, '')

        OR ISNULL(target.Address, '')
           <> ISNULL(source.Address, '')

        OR ISNULL(target.City, '')
           <> ISNULL(source.City, '')

        AND ISNULL(target.State, '')
           <> ISNULL(source.State, '')

        AND ISNULL(target.ZipCode, '')
           <> ISNULL(source.ZipCode, '')

        AND ISNULL(target.Latitude, 0)
           <> ISNULL(source.Latitude, 0)

        AND ISNULL(target.Longitude, 0)
           <> ISNULL(source.Longitude, 0)

    );


-- ============================================================
-- 2. Find current maximum FacilityKey
-- ============================================================

DECLARE @MaxFacilityKey BIGINT;

SELECT
    @MaxFacilityKey =
        ISNULL(MAX(FacilityKey), 0)

FROM dim.DimFacility;


-- ============================================================
-- 3. Insert:
--
--    A. Completely new facilities
--    B. New versions of facilities expired above
-- ============================================================

WITH FacilitySource AS
(
    SELECT
        FacilityID,
        FacilityName,
        Address,
        City,
        State,
        ZipCode,
        Latitude,
        Longitude,
        Phone,
        Revenue,
        Utilization

    FROM [HP_02_LH_Health_Silver].[reference].[facility]

    WHERE FacilityID IS NOT NULL
),

FacilitiesToInsert AS
(
    SELECT
        source.FacilityID,
        source.FacilityName,
        source.Address,
        source.City,
        source.State,
        source.ZipCode,
        source.Latitude,
        source.Longitude,
        source.Phone,
        source.Revenue,
        source.Utilization,

        ROW_NUMBER() OVER
        (
            ORDER BY source.FacilityID
        ) AS RowNumber

    FROM FacilitySource AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM dim.DimFacility AS target

        WHERE
            target.FacilityID = source.FacilityID
            AND target.IsCurrent = 1
    )
)


INSERT INTO dim.DimFacility
(
    FacilityKey,
    FacilityID,
    FacilityName,

    Address,
    City,
    State,
    ZipCode,

    Latitude,
    Longitude,

    Phone,

    Revenue,
    Utilization,

    ValidFrom,
    ValidTo,
    IsCurrent
)

SELECT
    @MaxFacilityKey + RowNumber,

    FacilityID,
    FacilityName,

    Address,
    City,
    State,
    ZipCode,

    Latitude,
    Longitude,

    Phone,

    Revenue,
    Utilization,

    @LoadTime,

    CAST(
        '9999-12-31 23:59:59.999999'
        AS DATETIME2(6)
    ),

    1

FROM FacilitiesToInsert;


-- ============================================================
-- 4. Type 1 update
--
-- Revenue and Utilization do not create new historical
-- Facility versions.
-- ============================================================

UPDATE target

SET
    target.Revenue     = source.Revenue,
    target.Utilization = source.Utilization

FROM dim.DimFacility AS target

INNER JOIN
(
    SELECT
        FacilityID,
        Revenue,
        Utilization

    FROM [HP_02_LH_Health_Silver].[reference].[facility]

    WHERE FacilityID IS NOT NULL

) AS source

    ON target.FacilityID = source.FacilityID

WHERE
    target.IsCurrent = 1;


-- ============================================================
-- 5. Summary
-- ============================================================

SELECT
    COUNT(*) AS TotalFacilityRows,

    COUNT(DISTINCT FacilityID)
        AS UniqueFacilities,

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

FROM dim.DimFacility;


-- ============================================================
-- 6. Validate
--
-- Expected:
-- zero rows
-- ============================================================

SELECT
    FacilityID,
    COUNT(*) AS CurrentVersions

FROM dim.DimFacility

WHERE IsCurrent = 1

GROUP BY FacilityID

HAVING COUNT(*) > 1;

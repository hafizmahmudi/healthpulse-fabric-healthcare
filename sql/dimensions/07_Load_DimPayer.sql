-- Source notebook: HP_07_02_NB_SilverToGold_Load_Dim
-- Section: Load DimPayer

-- ============================================================
-- DimPayer - SCD Type 2
--
-- Source:
--   HP_02_LH_Health_Silver.reference.payer
--
-- Target:
--   dim.DimPayer
--
-- Business Key:
--   PayerID
--
-- Surrogate Key:
--   PayerKey
--
-- SCD Type 2 attributes:
--   PayerName
--   Ownership
--   Address
--   City
--   State
--   ZipCode
--   Phone
--
-- State is derived from ZipCode using DimFacility.
-- ============================================================


DECLARE @LoadTime DATETIME2(6) = SYSUTCDATETIME();


-- ============================================================
-- 1. Expire current payer version when any SCD2
--    attribute changes
-- ============================================================

WITH FacilityZipState AS
(
    SELECT
        LEFT(
            LTRIM(RTRIM(CAST(ZipCode AS VARCHAR(20)))),
            5
        ) AS ZipCode,

        MAX(State) AS State

    FROM dim.DimFacility

    WHERE
        IsCurrent = 1
        AND ZipCode IS NOT NULL
        AND State IS NOT NULL

    GROUP BY
        LEFT(
            LTRIM(RTRIM(CAST(ZipCode AS VARCHAR(20)))),
            5
        )

    HAVING COUNT(DISTINCT State) = 1
),

PayerSource AS
(
    SELECT
        p.PayerID,
        p.PayerName,
        p.Ownership,

        p.Address,
        p.City,

        -- Derive State from ZIP.
        -- Fall back to source StateHeadquartered
        -- when ZIP is not found in DimFacility.
        COALESCE(
            f.State,
            p.StateHeadquartered
        ) AS State,

        p.ZipCode,
        p.Phone

    FROM
        [HP_02_LH_Health_Silver].[reference].[payer] AS p

    LEFT JOIN FacilityZipState AS f

        ON LEFT(
            LTRIM(RTRIM(CAST(p.ZipCode AS VARCHAR(20)))),
            5
        ) = f.ZipCode

    WHERE
        p.PayerID IS NOT NULL
)

UPDATE target

SET
    target.ValidTo   = @LoadTime,
    target.IsCurrent = 0

FROM dim.DimPayer AS target

INNER JOIN PayerSource AS source
    ON target.PayerID = source.PayerID

WHERE
    target.IsCurrent = 1

    AND
    (
           ISNULL(target.PayerName, '')
           <> ISNULL(source.PayerName, '')

        OR ISNULL(target.Ownership, '')
           <> ISNULL(source.Ownership, '')

        OR ISNULL(target.Address, '')
           <> ISNULL(source.Address, '')

        OR ISNULL(target.City, '')
           <> ISNULL(source.City, '')

        OR ISNULL(target.State, '')
           <> ISNULL(source.State, '')

        OR ISNULL(target.ZipCode, '')
           <> ISNULL(source.ZipCode, '')

        OR ISNULL(target.Phone, '')
           <> ISNULL(source.Phone, '')
    );


-- ============================================================
-- 2. Find current maximum PayerKey
-- ============================================================

DECLARE @MaxPayerKey BIGINT;

SELECT
    @MaxPayerKey =
        ISNULL(MAX(PayerKey), 0)

FROM dim.DimPayer;


-- ============================================================
-- 3. Prepare source again for INSERT
-- ============================================================

WITH FacilityZipState AS
(
    SELECT
        LEFT(
            LTRIM(RTRIM(CAST(ZipCode AS VARCHAR(20)))),
            5
        ) AS ZipCode,

        MAX(State) AS State

    FROM dim.DimFacility

    WHERE
        IsCurrent = 1
        AND ZipCode IS NOT NULL
        AND State IS NOT NULL

    GROUP BY
        LEFT(
            LTRIM(RTRIM(CAST(ZipCode AS VARCHAR(20)))),
            5
        )

    HAVING COUNT(DISTINCT State) = 1
),

PayerSource AS
(
    SELECT
        p.PayerID,
        p.PayerName,
        p.Ownership,

        p.Address,
        p.City,

        COALESCE(
            f.State,
            p.StateHeadquartered
        ) AS State,

        p.ZipCode,
        p.Phone

    FROM
        [HP_02_LH_Health_Silver].[reference].[payer] AS p

    LEFT JOIN FacilityZipState AS f

        ON LEFT(
            LTRIM(RTRIM(CAST(p.ZipCode AS VARCHAR(20)))),
            5
        ) = f.ZipCode

    WHERE
        p.PayerID IS NOT NULL
),

PayersToInsert AS
(
    SELECT
        source.PayerID,
        source.PayerName,
        source.Ownership,

        source.Address,
        source.City,
        source.State,
        source.ZipCode,
        source.Phone,

        ROW_NUMBER() OVER
        (
            ORDER BY source.PayerID
        ) AS RowNumber

    FROM PayerSource AS source

    WHERE NOT EXISTS
    (
        SELECT 1

        FROM dim.DimPayer AS target

        WHERE
            target.PayerID = source.PayerID
            AND target.IsCurrent = 1
    )
)


-- ============================================================
-- 4. Insert new payer or new SCD2 version
-- ============================================================

INSERT INTO dim.DimPayer
(
    PayerKey,
    PayerID,
    PayerName,
    Ownership,

    Address,
    City,
    State,
    ZipCode,
    Phone,

    ValidFrom,
    ValidTo,
    IsCurrent
)

SELECT
    @MaxPayerKey + RowNumber,

    PayerID,
    PayerName,
    Ownership,

    Address,
    City,
    State,
    ZipCode,
    Phone,

    @LoadTime,

    CAST(
        '9999-12-31 23:59:59.999999'
        AS DATETIME2(6)
    ),

    1

FROM PayersToInsert;


-- ============================================================
-- 5. Summary
-- ============================================================

SELECT
    COUNT(*) AS TotalPayerRows,

    COUNT(DISTINCT PayerID)
        AS UniquePayers,

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

FROM dim.DimPayer;


-- ============================================================
-- 6. Validate
--
-- Should return zero rows.
-- ============================================================

SELECT
    PayerID,
    COUNT(*) AS CurrentVersions

FROM dim.DimPayer

WHERE IsCurrent = 1

GROUP BY PayerID

HAVING COUNT(*) > 1;

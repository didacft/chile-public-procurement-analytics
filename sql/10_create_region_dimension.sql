USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   REGION DIMENSION

   Canonical analytical geography:
   - 16 Chilean regions
   - Extranjero
   - Sin información

   Raw source values remain preserved in clean.purchase_orders
   and their transformations are documented in
   clean.region_mapping.
   ============================================================ */

DROP TABLE IF EXISTS analytics.dim_region;
GO


CREATE TABLE analytics.dim_region (
    region_key TINYINT PRIMARY KEY,

    region_name NVARCHAR(100) NOT NULL,
    region_type NVARCHAR(30) NOT NULL,
    sort_order TINYINT NOT NULL,

    CONSTRAINT UQ_dim_region_name
        UNIQUE (region_name)
);
GO


INSERT INTO analytics.dim_region (
    region_key,
    region_name,
    region_type,
    sort_order
)
VALUES
    (1,  N'Región de Arica y Parinacota',                         N'Chile', 1),
    (2,  N'Región de Tarapacá',                                  N'Chile', 2),
    (3,  N'Región de Antofagasta',                               N'Chile', 3),
    (4,  N'Región de Atacama',                                   N'Chile', 4),
    (5,  N'Región de Coquimbo',                                  N'Chile', 5),
    (6,  N'Región de Valparaíso',                                N'Chile', 6),
    (7,  N'Región Metropolitana de Santiago',                     N'Chile', 7),
    (8,  N'Región del Libertador General Bernardo O''Higgins',    N'Chile', 8),
    (9,  N'Región del Maule',                                    N'Chile', 9),
    (10, N'Región de Ñuble',                                     N'Chile', 10),
    (11, N'Región del Biobío',                                   N'Chile', 11),
    (12, N'Región de la Araucanía',                              N'Chile', 12),
    (13, N'Región de Los Ríos',                                  N'Chile', 13),
    (14, N'Región de Los Lagos',                                 N'Chile', 14),
    (15, N'Región de Aysén',                                     N'Chile', 15),
    (16, N'Región de Magallanes y de la Antártica',              N'Chile', 16),
    (17, N'Extranjero',                                          N'Foreign', 17),
    (18, N'Sin información',                                     N'Unknown', 18);
GO


/* ============================================================
   VALIDATION 1: dimension size
   ============================================================ */

SELECT
    COUNT(*) AS region_categories
FROM analytics.dim_region;
GO


/* ============================================================
   VALIDATION 2: every canonical mapping must exist
   in the region dimension.
   Expected result: 0 rows.
   ============================================================ */

SELECT DISTINCT
    rm.canonical_region
FROM clean.region_mapping AS rm
LEFT JOIN analytics.dim_region AS r
    ON rm.canonical_region = r.region_name
WHERE r.region_key IS NULL;
GO


/* ============================================================
   VALIDATION 3: distribution of raw variants by
   canonical dimension member.
   ============================================================ */

SELECT
    r.region_key,
    r.region_name,
    r.region_type,
    COUNT(rm.raw_region) AS raw_variants
FROM analytics.dim_region AS r
LEFT JOIN clean.region_mapping AS rm
    ON r.region_name = rm.canonical_region
GROUP BY
    r.region_key,
    r.region_name,
    r.region_type,
    r.sort_order
ORDER BY
    r.sort_order;
GO
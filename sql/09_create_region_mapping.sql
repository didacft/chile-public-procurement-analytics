USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   REGION NORMALIZATION

   Raw regional values are preserved in clean.purchase_orders.
   This mapping creates a canonical analytical geography.

   Canonical domain:
   - 16 Chilean regions
   - Extranjero
   - Sin información
   ============================================================ */


DROP TABLE IF EXISTS clean.region_mapping;
GO


CREATE TABLE clean.region_mapping (
    raw_region NVARCHAR(100) NOT NULL PRIMARY KEY,
    canonical_region NVARCHAR(100) NOT NULL,
    mapping_type NVARCHAR(30) NOT NULL
);
GO

INSERT INTO clean.region_mapping (
    raw_region,
    canonical_region,
    mapping_type
)
SELECT
    raw_region,

    CASE

        /* ---------- Invalid / placeholder values ---------- */

        WHEN raw_region IN (
            '-',
            '*',
            '.',
            'Seleccione...',
            'xx',
            'XXXX',
            'Corporacion de deportes Aysen'
        )
        THEN N'Sin información'


        /* ---------- Foreign suppliers ---------- */

        WHEN raw_region = 'Extranjero'
        THEN N'Extranjero'


        /* ---------- Arica y Parinacota ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Arica y Parinacota',
            'Región de Arica y Parinacota'
        )
        THEN N'Región de Arica y Parinacota'


        /* ---------- Tarapacá ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Tarapaca',
            'Región de Tarapacá',
            'Tarapacá'
        )
        THEN N'Región de Tarapacá'


        /* ---------- Antofagasta ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Antofagasta',
            'Región de Antofagasta',
            'ANTOFAGASTA'
        )
        THEN N'Región de Antofagasta'


        /* ---------- Atacama ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Atacama',
            'Región de Atacama'
        )
        THEN N'Región de Atacama'


        /* ---------- Coquimbo ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Coquimbo',
            'Región de Coquimbo'
        )
        THEN N'Región de Coquimbo'


        /* ---------- Valparaíso ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Valparaiso',
            'Región de Valparaíso',
            'Valparaiso',
            'Valparaíso'
        )
        THEN N'Región de Valparaíso'


        /* ---------- Metropolitana ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region Metropolitana de Santiago',
            'Región Metropolitana de Santiago',
            'REGION METROPOLITANA',
            'METROPOLITANA',
            'METROPOLINTANO',
            'SANTIAGO'
        )
        THEN N'Región Metropolitana de Santiago'


        /* ---------- O'Higgins ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region del Libertador General Bernardo OHiggins',
            'Región del Libertador General Bernardo O´Higgins',
            'REGION DE OHIGGINS'
        )
        THEN N'Región del Libertador General Bernardo O''Higgins'


        /* ---------- Maule ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region del Maule',
            'Región del Maule'
        )
        THEN N'Región del Maule'


        /* ---------- Ñuble ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region del Nuble',
            'Región del Ñuble',
            'Región de Ñuble',
            'ÑUBLE'
        )
        THEN N'Región de Ñuble'


        /* ---------- Biobío ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region del Biobio',
            'Región del Biobío',
            'BIO BIO',
            'CONCEPCION,'
        )
        THEN N'Región del Biobío'


        /* ---------- Araucanía ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de la Araucania',
            'Región de la Araucanía',
            'LA ARAUCANIA'
        )
        THEN N'Región de la Araucanía'


        /* ---------- Los Ríos ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Los Rios',
            'Región de Los Ríos'
        )
        THEN N'Región de Los Ríos'


        /* ---------- Los Lagos ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de los Lagos',
            'Región de los Lagos'
        )
        THEN N'Región de Los Lagos'


        /* ---------- Aysén ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region Aysen del General Carlos IbaNez del Campo',
            'Región Aysén del General Carlos Ibáñez del Campo',
            'REGION DE AYSEN',
            'Región de Aysen',
            'Región de Aysén',
            'AYSEN',
            'Aysén',
            'XI REGION',
            'Coyhaique',
            'Puerto Aysén'
        )
        THEN N'Región de Aysén'


        /* ---------- Magallanes ---------- */

        WHEN raw_region COLLATE Latin1_General_100_CI_AI IN (
            'Region de Magallanes y de la Antartica',
            'Región de Magallanes y de la Antártica',
            'MAGALLANES'
        )
        THEN N'Región de Magallanes y de la Antártica'


        /* Anything not explicitly understood ---------- */

        ELSE N'Sin información'

    END AS canonical_region,

    CASE
        WHEN raw_region IN (
            '-',
            '*',
            '.',
            'Seleccione...',
            'xx',
            'XXXX',
            'Corporacion de deportes Aysen'
        )
        THEN 'Invalid'

        WHEN raw_region = 'Extranjero'
        THEN 'Special'

        ELSE 'Normalized'
    END AS mapping_type

FROM (
    SELECT DISTINCT region_unidad_compra AS raw_region
    FROM clean.purchase_orders
    WHERE region_unidad_compra IS NOT NULL

    UNION

    SELECT DISTINCT region_proveedor
    FROM clean.purchase_orders
    WHERE region_proveedor IS NOT NULL
) AS regions;
GO

/* ============================================================
   VALIDATION
   ============================================================ */

SELECT
    canonical_region,
    COUNT(*) AS raw_variants
FROM clean.region_mapping
GROUP BY canonical_region
ORDER BY canonical_region;
GO


SELECT
    COUNT(DISTINCT canonical_region) AS canonical_region_categories
FROM clean.region_mapping;
GO


SELECT
    raw_region,
    canonical_region,
    mapping_type
FROM clean.region_mapping
ORDER BY canonical_region, raw_region;
GO
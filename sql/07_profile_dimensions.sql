USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   1. SUPPLIERS
   Check whether supplier RUT determines name, size and region.
   ============================================================ */

SELECT
    ProveedorRUT,
    COUNT(DISTINCT Proveedor) AS supplier_names,
    COUNT(DISTINCT TamanoProveedor) AS supplier_sizes,
    COUNT(DISTINCT RegionProveedor) AS supplier_regions
FROM staging.trato_directo_raw
GROUP BY ProveedorRUT
HAVING
    COUNT(DISTINCT Proveedor) > 1
    OR COUNT(DISTINCT TamanoProveedor) > 1
    OR COUNT(DISTINCT RegionProveedor) > 1
ORDER BY supplier_regions DESC, ProveedorRUT;
GO


/* ============================================================
   2. SUPPLIER REGION CONSISTENCY AT ORDER LEVEL
   Region may vary between purchases by the same supplier,
   but should ideally be stable within a single order.
   ============================================================ */

SELECT
    COUNT(*) AS orders_with_multiple_supplier_regions
FROM (
    SELECT
        codigoOC
    FROM staging.trato_directo_raw
    GROUP BY codigoOC
    HAVING COUNT(DISTINCT RegionProveedor) > 1
) AS x;
GO


/* ============================================================
   3. BUYER REGION CONSISTENCY AT ORDER LEVEL
   ============================================================ */

SELECT
    COUNT(*) AS orders_with_multiple_buyer_regions
FROM (
    SELECT
        codigoOC
    FROM staging.trato_directo_raw
    GROUP BY codigoOC
    HAVING COUNT(DISTINCT RegionUnidadCompra) > 1
) AS x;
GO


/* ============================================================
   4. BUYER ENTITY
   Check whether entCode determines one institution name.
   ============================================================ */

SELECT
    entCode,
    COUNT(DISTINCT Institucion) AS institution_names
FROM staging.trato_directo_raw
GROUP BY entCode
HAVING COUNT(DISTINCT Institucion) > 1
ORDER BY institution_names DESC, entCode;
GO


/* ============================================================
   5. PRODUCTS
   Check whether ONU product code determines product name
   and the three category levels.
   ============================================================ */

SELECT
    CodigoProductoONU,
    COUNT(DISTINCT ONUProducto) AS product_names,
    COUNT(DISTINCT RubroN1) AS rubro_n1_values,
    COUNT(DISTINCT RubroN2) AS rubro_n2_values,
    COUNT(DISTINCT RubroN3) AS rubro_n3_values
FROM staging.trato_directo_raw
GROUP BY CodigoProductoONU
HAVING
    COUNT(DISTINCT ONUProducto) > 1
    OR COUNT(DISTINCT RubroN1) > 1
    OR COUNT(DISTINCT RubroN2) > 1
    OR COUNT(DISTINCT RubroN3) > 1
ORDER BY
    rubro_n1_values DESC,
    rubro_n2_values DESC,
    rubro_n3_values DESC,
    CodigoProductoONU;
GO


/* ============================================================
   6. DIMENSION CANDIDATE COUNTS
   Useful sanity check before creating analytics dimensions.
   ============================================================ */

SELECT
    COUNT(DISTINCT ProveedorRUT) AS unique_suppliers,
    COUNT(DISTINCT entCode) AS unique_buyer_entities,
    COUNT(DISTINCT CodigoProductoONU) AS unique_products
FROM staging.trato_directo_raw;
GO


/* ============================================================
   7. MISSING REGION VALUES
   Region is useful analytically even if it is not a dimension key.
   ============================================================ */

SELECT
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(RegionProveedor)), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_supplier_region_rows,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(RegionUnidadCompra)), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_buyer_region_rows

FROM staging.trato_directo_raw;
GO

/* ============================================================
   8. PARTIAL REGION MISSINGNESS WITHIN ORDERS
   Check whether an order mixes NULL and non-NULL regions.
   ============================================================ */

SELECT
    COUNT(*) AS orders_with_partial_missing_supplier_region
FROM (
    SELECT
        codigoOC
    FROM staging.trato_directo_raw
    GROUP BY codigoOC
    HAVING
        SUM(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(RegionProveedor)), '') IS NULL
                THEN 1 ELSE 0
            END
        ) > 0
        AND
        SUM(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(RegionProveedor)), '') IS NOT NULL
                THEN 1 ELSE 0
            END
        ) > 0
) AS x;
GO


SELECT
    COUNT(*) AS orders_with_partial_missing_buyer_region
FROM (
    SELECT
        codigoOC
    FROM staging.trato_directo_raw
    GROUP BY codigoOC
    HAVING
        SUM(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(RegionUnidadCompra)), '') IS NULL
                THEN 1 ELSE 0
            END
        ) > 0
        AND
        SUM(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(RegionUnidadCompra)), '') IS NOT NULL
                THEN 1 ELSE 0
            END
        ) > 0
) AS x;
GO

/* ============================================================
   9. ORDERS WITH MISSING REGION
   ============================================================ */

SELECT
    COUNT(DISTINCT CASE
        WHEN NULLIF(LTRIM(RTRIM(RegionProveedor)), '') IS NULL
        THEN codigoOC
    END) AS orders_missing_supplier_region,

    COUNT(DISTINCT CASE
        WHEN NULLIF(LTRIM(RTRIM(RegionUnidadCompra)), '') IS NULL
        THEN codigoOC
    END) AS orders_missing_buyer_region

FROM staging.trato_directo_raw;
GO

/* ============================================================
   10. MISSING NATURAL KEYS FOR ANALYTICAL DIMENSIONS
   ============================================================ */

SELECT
    COUNT(*) AS total_orders,

    SUM(CASE
        WHEN proveedor_rut IS NULL
        THEN 1 ELSE 0
    END) AS orders_missing_supplier_rut,

    SUM(CASE
        WHEN ent_code IS NULL
        THEN 1 ELSE 0
    END) AS orders_missing_ent_code,

    SUM(CASE
        WHEN unidad_compra IS NULL
        THEN 1 ELSE 0
    END) AS orders_missing_buying_unit_name,

    SUM(CASE
        WHEN unidad_compra_rut IS NULL
        THEN 1 ELSE 0
    END) AS orders_missing_buying_unit_rut

FROM clean.purchase_orders;
GO


SELECT
    COUNT(*) AS total_items,

    SUM(CASE
        WHEN codigo_producto_onu IS NULL
        THEN 1 ELSE 0
    END) AS items_missing_product_code

FROM clean.purchase_order_items;
GO


/* ============================================================
   11. DIMENSION CARDINALITIES AFTER CLEANING
   ============================================================ */

SELECT
    COUNT(DISTINCT proveedor_rut) AS suppliers,
    COUNT(DISTINCT ent_code) AS buyer_entities,
    COUNT(DISTINCT CONCAT(
        COALESCE(ent_code, '<NULL>'),
        '|',
        COALESCE(unidad_compra, '<NULL>')
    )) AS buying_units
FROM clean.purchase_orders;
GO

/* ============================================================
   12. MAXIMUM TEXT LENGTHS
   Used to choose bounded data types for analytics dimensions.
   ============================================================ */

SELECT
    MAX(LEN(proveedor_rut)) AS max_supplier_rut_length,
    MAX(LEN(proveedor)) AS max_supplier_name_length,
    MAX(LEN(tamano_proveedor)) AS max_supplier_size_length,

    MAX(LEN(ent_code)) AS max_ent_code_length,
    MAX(LEN(institucion)) AS max_institution_name_length,

    MAX(LEN(unidad_compra)) AS max_buying_unit_name_length,
    MAX(LEN(unidad_compra_rut)) AS max_buying_unit_rut_length,

    MAX(LEN(region_unidad_compra)) AS max_buyer_region_length,
    MAX(LEN(region_proveedor)) AS max_supplier_region_length

FROM clean.purchase_orders;
GO


SELECT
    MAX(LEN(codigo_producto_onu)) AS max_product_code_length,
    MAX(LEN(onu_producto)) AS max_product_name_length,
    MAX(LEN(rubro_n1)) AS max_rubro_n1_length,
    MAX(LEN(rubro_n2)) AS max_rubro_n2_length,
    MAX(LEN(rubro_n3)) AS max_rubro_n3_length,
    MAX(LEN(unidad_medida)) AS max_unit_measure_length

FROM clean.purchase_order_items;
GO

/* ============================================================
   13. REGION DOMAIN PROFILING
   Compare buyer and supplier regions before creating dim_region.
   ============================================================ */

WITH regions AS (
    SELECT
        'Buyer' AS region_role,
        region_unidad_compra AS region_name
    FROM clean.purchase_orders
    WHERE region_unidad_compra IS NOT NULL

    UNION ALL

    SELECT
        'Supplier' AS region_role,
        region_proveedor AS region_name
    FROM clean.purchase_orders
    WHERE region_proveedor IS NOT NULL
)
SELECT
    region_name,

    SUM(CASE
        WHEN region_role = 'Buyer'
        THEN 1 ELSE 0
    END) AS buyer_orders,

    SUM(CASE
        WHEN region_role = 'Supplier'
        THEN 1 ELSE 0
    END) AS supplier_orders

FROM regions
GROUP BY region_name
ORDER BY region_name;
GO


WITH regions AS (
    SELECT region_unidad_compra AS region_name
    FROM clean.purchase_orders
    WHERE region_unidad_compra IS NOT NULL

    UNION

    SELECT region_proveedor
    FROM clean.purchase_orders
    WHERE region_proveedor IS NOT NULL
)
SELECT
    COUNT(*) AS unique_region_names
FROM regions;
GO
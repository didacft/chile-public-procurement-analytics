USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   REPORTING / SEMANTIC VIEWS

   These views expose common business metrics without requiring
   report consumers to repeat joins and aggregation logic.

   Important:
   - Order-level spend comes from fact_orders.
   - Product-level spend comes from fact_order_items.
   ============================================================ */


/* ============================================================
   1. HEADLINE KPI VIEW
   ============================================================ */

CREATE OR ALTER VIEW analytics.vw_kpi_overview
AS

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT supplier_key) AS active_suppliers,
    COUNT(DISTINCT buyer_key) AS active_buyer_entities,
    COUNT(DISTINCT buying_unit_key) AS active_buying_units,

    SUM(monto_neto_oc_clp) AS total_spend_clp,

    AVG(monto_neto_oc_clp) AS average_order_value_clp,

    MIN(monto_neto_oc_clp) AS minimum_order_value_clp,
    MAX(monto_neto_oc_clp) AS maximum_order_value_clp

FROM analytics.fact_orders;
GO


/* ============================================================
   2. MONTHLY SPEND
   ============================================================ */

CREATE OR ALTER VIEW analytics.vw_monthly_spend
AS

SELECT
    d.year_number,
    d.month_number,
    d.month_name,
    d.year_month,

    COUNT(*) AS total_orders,
    COUNT(DISTINCT fo.supplier_key) AS active_suppliers,

    SUM(fo.monto_neto_oc_clp) AS total_spend_clp,
    AVG(fo.monto_neto_oc_clp) AS average_order_value_clp

FROM analytics.fact_orders AS fo

INNER JOIN analytics.dim_date AS d
    ON fo.date_key = d.date_key

GROUP BY
    d.year_number,
    d.month_number,
    d.month_name,
    d.year_month;
GO


/* ============================================================
   3. SUPPLIER SUMMARY
   Grain: one row per supplier
   ============================================================ */

CREATE OR ALTER VIEW analytics.vw_supplier_summary
AS

SELECT
    s.supplier_key,
    s.proveedor_rut,
    s.proveedor,
    s.tamano_proveedor,

    COUNT(*) AS total_orders,

    SUM(fo.monto_neto_oc_clp) AS total_spend_clp,

    AVG(fo.monto_neto_oc_clp) AS average_order_value_clp,

    MIN(fo.monto_neto_oc_clp) AS minimum_order_value_clp,
    MAX(fo.monto_neto_oc_clp) AS maximum_order_value_clp

FROM analytics.fact_orders AS fo

INNER JOIN analytics.dim_supplier AS s
    ON fo.supplier_key = s.supplier_key

GROUP BY
    s.supplier_key,
    s.proveedor_rut,
    s.proveedor,
    s.tamano_proveedor;
GO


/* ============================================================
   4. BUYER SUMMARY
   Grain: one row per buyer entity
   ============================================================ */

CREATE OR ALTER VIEW analytics.vw_buyer_summary
AS

SELECT
    b.buyer_key,
    b.ent_code,
    b.institucion,

    COUNT(*) AS total_orders,

    COUNT(DISTINCT fo.supplier_key) AS unique_suppliers,

    SUM(fo.monto_neto_oc_clp) AS total_spend_clp,

    AVG(fo.monto_neto_oc_clp) AS average_order_value_clp

FROM analytics.fact_orders AS fo

INNER JOIN analytics.dim_buyer AS b
    ON fo.buyer_key = b.buyer_key

GROUP BY
    b.buyer_key,
    b.ent_code,
    b.institucion;
GO


/* ============================================================
   5. PRODUCT SUMMARY
   Grain: one row per ONU product

   Product spend must use item-level amounts.
   ============================================================ */

CREATE OR ALTER VIEW analytics.vw_product_summary
AS

SELECT
    p.product_key,
    p.codigo_producto_onu,
    p.onu_producto,

    p.rubro_n1,
    p.rubro_n2,
    p.rubro_n3,

    COUNT(*) AS item_rows,

    COUNT(DISTINCT fi.order_key) AS orders_containing_product,

    COUNT(DISTINCT fi.supplier_key) AS unique_suppliers,

    SUM(fi.monto_neto_item_clp) AS total_spend_clp,

    SUM(
        CASE
            WHEN fi.is_zero_amount_clp = 1
            THEN 1 ELSE 0
        END
    ) AS zero_amount_item_rows

FROM analytics.fact_order_items AS fi

INNER JOIN analytics.dim_product AS p
    ON fi.product_key = p.product_key

GROUP BY
    p.product_key,
    p.codigo_producto_onu,
    p.onu_producto,
    p.rubro_n1,
    p.rubro_n2,
    p.rubro_n3;
GO


/* ============================================================
   6. BUYER REGION SUMMARY
   ============================================================ */

CREATE OR ALTER VIEW analytics.vw_buyer_region_summary
AS

SELECT
    r.region_key,
    r.region_name,
    r.region_type,

    COUNT(*) AS total_orders,

    COUNT(DISTINCT fo.buyer_key) AS buyer_entities,
    COUNT(DISTINCT fo.supplier_key) AS unique_suppliers,

    SUM(fo.monto_neto_oc_clp) AS total_spend_clp

FROM analytics.fact_orders AS fo

INNER JOIN analytics.dim_region AS r
    ON fo.buyer_region_key = r.region_key

GROUP BY
    r.region_key,
    r.region_name,
    r.region_type;
GO


/* ============================================================
   VALIDATION / INITIAL OUTPUT
   ============================================================ */

SELECT *
FROM analytics.vw_kpi_overview;
GO


SELECT *
FROM analytics.vw_monthly_spend
ORDER BY year_number, month_number;
GO


SELECT TOP 10
    proveedor,
    tamano_proveedor,
    total_orders,
    total_spend_clp
FROM analytics.vw_supplier_summary
ORDER BY total_spend_clp DESC;
GO


SELECT TOP 10
    institucion,
    total_orders,
    unique_suppliers,
    total_spend_clp
FROM analytics.vw_buyer_summary
ORDER BY total_spend_clp DESC;
GO


SELECT TOP 10
    onu_producto,
    rubro_n1,
    orders_containing_product,
    unique_suppliers,
    total_spend_clp
FROM analytics.vw_product_summary
ORDER BY total_spend_clp DESC;
GO


SELECT
    region_name,
    total_orders,
    buyer_entities,
    unique_suppliers,
    total_spend_clp
FROM analytics.vw_buyer_region_summary
ORDER BY total_spend_clp DESC;
GO
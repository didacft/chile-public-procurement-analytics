USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   1. SPEND BY SUPPLIER SIZE
   ============================================================ */

SELECT
    s.tamano_proveedor,

    COUNT(*) AS total_orders,
    COUNT(DISTINCT fo.supplier_key) AS suppliers,

    SUM(fo.monto_neto_oc_clp) AS total_spend_clp,

    SUM(fo.monto_neto_oc_clp)
        / SUM(SUM(fo.monto_neto_oc_clp)) OVER ()
        AS spend_share

FROM analytics.fact_orders AS fo

INNER JOIN analytics.dim_supplier AS s
    ON fo.supplier_key = s.supplier_key

GROUP BY
    s.tamano_proveedor

ORDER BY
    total_spend_clp DESC;
GO


/* ============================================================
   2. ORDER STATUS
   ============================================================ */

SELECT
    estado_oc,

    COUNT(*) AS total_orders,

    SUM(monto_neto_oc_clp) AS total_spend_clp,

    SUM(monto_neto_oc_clp)
        / SUM(SUM(monto_neto_oc_clp)) OVER ()
        AS spend_share

FROM analytics.fact_orders

GROUP BY estado_oc

ORDER BY total_spend_clp DESC;
GO


/* ============================================================
   3. SUPPLIER SPEND CONCENTRATION - HHI

   HHI = sum of squared market shares * 10,000

   This is used here as a descriptive concentration measure,
   not as a competition-law conclusion.
   ============================================================ */

WITH supplier_spend AS (
    SELECT
        supplier_key,
        SUM(monto_neto_oc_clp) AS supplier_spend
    FROM analytics.fact_orders
    GROUP BY supplier_key
),
total AS (
    SELECT
        SUM(supplier_spend) AS total_spend
    FROM supplier_spend
),
shares AS (
    SELECT
        s.supplier_key,
        s.supplier_spend / t.total_spend AS spend_share
    FROM supplier_spend AS s
    CROSS JOIN total AS t
)

SELECT
    SUM(POWER(spend_share, 2)) * 10000 AS supplier_hhi
FROM shares;
GO


/* ============================================================
   4. LARGE-ORDER DEPENDENCE
   ============================================================ */

SELECT
    COUNT(*) AS billion_plus_orders,

    SUM(monto_neto_oc_clp) AS billion_plus_spend_clp,

    CAST(COUNT(*) AS DECIMAL(20,9))
        / (SELECT COUNT(*)
           FROM analytics.fact_orders)
        AS order_share,

    SUM(monto_neto_oc_clp)
        / (SELECT SUM(monto_neto_oc_clp)
           FROM analytics.fact_orders)
        AS spend_share

FROM analytics.fact_orders
WHERE monto_neto_oc_clp >= 1000000000;
GO
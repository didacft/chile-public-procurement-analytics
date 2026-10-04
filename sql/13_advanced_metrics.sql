USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   1. ORDER VALUE DISTRIBUTION
   ============================================================ */

SELECT DISTINCT
    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY monto_neto_oc_clp
    ) OVER () AS median_order_value_clp,

    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY monto_neto_oc_clp
    ) OVER () AS p75_order_value_clp,

    PERCENTILE_CONT(0.90) WITHIN GROUP (
        ORDER BY monto_neto_oc_clp
    ) OVER () AS p90_order_value_clp,

    PERCENTILE_CONT(0.95) WITHIN GROUP (
        ORDER BY monto_neto_oc_clp
    ) OVER () AS p95_order_value_clp,

    PERCENTILE_CONT(0.99) WITHIN GROUP (
        ORDER BY monto_neto_oc_clp
    ) OVER () AS p99_order_value_clp

FROM analytics.fact_orders;
GO


/* ============================================================
   2. ORDER VALUE BUCKETS
   ============================================================ */

SELECT
    CASE
        WHEN monto_neto_oc_clp < 100000
            THEN '< $100 mil'

        WHEN monto_neto_oc_clp < 1000000
            THEN '$100 mil - $1 millón'

        WHEN monto_neto_oc_clp < 10000000
            THEN '$1 - $10 millones'

        WHEN monto_neto_oc_clp < 100000000
            THEN '$10 - $100 millones'

        WHEN monto_neto_oc_clp < 1000000000
            THEN '$100 millones - $1.000 millones'

        ELSE '>= $1.000 millones'
    END AS order_value_bucket,

    COUNT(*) AS total_orders,
    SUM(monto_neto_oc_clp) AS total_spend_clp

FROM analytics.fact_orders

GROUP BY
    CASE
        WHEN monto_neto_oc_clp < 100000
            THEN '< $100 mil'

        WHEN monto_neto_oc_clp < 1000000
            THEN '$100 mil - $1 millón'

        WHEN monto_neto_oc_clp < 10000000
            THEN '$1 - $10 millones'

        WHEN monto_neto_oc_clp < 100000000
            THEN '$10 - $100 millones'

        WHEN monto_neto_oc_clp < 1000000000
            THEN '$100 millones - $1.000 millones'

        ELSE '>= $1.000 millones'
    END;
GO


/* ============================================================
   3. SUPPLIER CONCENTRATION
   ============================================================ */

WITH ranked AS (
    SELECT
        supplier_key,
        total_spend_clp,

        ROW_NUMBER() OVER (
            ORDER BY total_spend_clp DESC
        ) AS supplier_rank

    FROM analytics.vw_supplier_summary
),
totals AS (
    SELECT
        SUM(total_spend_clp) AS grand_total
    FROM ranked
)

SELECT
    SUM(CASE
        WHEN supplier_rank <= 1
        THEN total_spend_clp ELSE 0
    END) / MAX(grand_total) AS top_1_supplier_share,

    SUM(CASE
        WHEN supplier_rank <= 5
        THEN total_spend_clp ELSE 0
    END) / MAX(grand_total) AS top_5_supplier_share,

    SUM(CASE
        WHEN supplier_rank <= 10
        THEN total_spend_clp ELSE 0
    END) / MAX(grand_total) AS top_10_supplier_share,

    SUM(CASE
        WHEN supplier_rank <= 50
        THEN total_spend_clp ELSE 0
    END) / MAX(grand_total) AS top_50_supplier_share

FROM ranked
CROSS JOIN totals;
GO


/* ============================================================
   4. BUYER CONCENTRATION
   ============================================================ */

WITH ranked AS (
    SELECT
        buyer_key,
        total_spend_clp,

        ROW_NUMBER() OVER (
            ORDER BY total_spend_clp DESC
        ) AS buyer_rank

    FROM analytics.vw_buyer_summary
),
totals AS (
    SELECT
        SUM(total_spend_clp) AS grand_total
    FROM ranked
)

SELECT
    SUM(CASE
        WHEN buyer_rank <= 1
        THEN total_spend_clp ELSE 0
    END) / MAX(grand_total) AS top_1_buyer_share,

    SUM(CASE
        WHEN buyer_rank <= 5
        THEN total_spend_clp ELSE 0
    END) / MAX(grand_total) AS top_5_buyer_share,

    SUM(CASE
        WHEN buyer_rank <= 10
        THEN total_spend_clp ELSE 0
    END) / MAX(grand_total) AS top_10_buyer_share

FROM ranked
CROSS JOIN totals;
GO
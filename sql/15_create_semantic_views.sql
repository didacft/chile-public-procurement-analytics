USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   ROLE-PLAYING REGION DIMENSIONS FOR POWER BI

   Both views use the same canonical region dimension but expose
   separate semantic roles, allowing active relationships for
   buyer geography and supplier geography.
   ============================================================ */


CREATE OR ALTER VIEW analytics.vw_dim_buyer_region
AS
SELECT
    region_key AS buyer_region_key,
    region_name AS buyer_region_name,
    region_type AS buyer_region_type,
    sort_order AS buyer_region_sort_order
FROM analytics.dim_region;
GO


CREATE OR ALTER VIEW analytics.vw_dim_supplier_region
AS
SELECT
    region_key AS supplier_region_key,
    region_name AS supplier_region_name,
    region_type AS supplier_region_type,
    sort_order AS supplier_region_sort_order
FROM analytics.dim_region;
GO


/* ============================================================
   VALIDATION
   ============================================================ */

SELECT COUNT(*) AS buyer_region_rows
FROM analytics.vw_dim_buyer_region;

SELECT COUNT(*) AS supplier_region_rows
FROM analytics.vw_dim_supplier_region;
GO
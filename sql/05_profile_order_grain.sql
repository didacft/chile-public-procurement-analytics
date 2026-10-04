USE ChilePublicProcurementAnalytics;
GO

WITH order_profile AS (
    SELECT
        codigoOC,

        COUNT(DISTINCT FechaEnvioOC) AS n_dates,
        COUNT(DISTINCT EstadoOC) AS n_status,
        COUNT(DISTINCT ProcedenciaOC) AS n_procedures,
        COUNT(DISTINCT MonedaOC) AS n_currencies,

        COUNT(DISTINCT entCode) AS n_entity_codes,
        COUNT(DISTINCT UnidadCompra) AS n_buying_units,
        COUNT(DISTINCT UnidadCompraRUT) AS n_buying_unit_ruts,
        COUNT(DISTINCT Institucion) AS n_institutions,

        COUNT(DISTINCT ProveedorRUT) AS n_supplier_ruts,
        COUNT(DISTINCT Proveedor) AS n_suppliers,

        COUNT(DISTINCT MontoNetoOC_CLP) AS n_order_amounts

    FROM staging.trato_directo_raw
    GROUP BY codigoOC
)

SELECT
    COUNT(*) AS total_orders,

    SUM(CASE WHEN n_dates > 1 THEN 1 ELSE 0 END) AS conflicting_dates,
    SUM(CASE WHEN n_status > 1 THEN 1 ELSE 0 END) AS conflicting_status,
    SUM(CASE WHEN n_procedures > 1 THEN 1 ELSE 0 END) AS conflicting_procedures,
    SUM(CASE WHEN n_currencies > 1 THEN 1 ELSE 0 END) AS conflicting_currencies,

    SUM(CASE WHEN n_entity_codes > 1 THEN 1 ELSE 0 END) AS conflicting_entity_codes,
    SUM(CASE WHEN n_buying_units > 1 THEN 1 ELSE 0 END) AS conflicting_buying_units,
    SUM(CASE WHEN n_buying_unit_ruts > 1 THEN 1 ELSE 0 END) AS conflicting_buying_unit_ruts,
    SUM(CASE WHEN n_institutions > 1 THEN 1 ELSE 0 END) AS conflicting_institutions,

    SUM(CASE WHEN n_supplier_ruts > 1 THEN 1 ELSE 0 END) AS conflicting_supplier_ruts,
    SUM(CASE WHEN n_suppliers > 1 THEN 1 ELSE 0 END) AS conflicting_suppliers,

    SUM(CASE WHEN n_order_amounts > 1 THEN 1 ELSE 0 END) AS conflicting_order_amounts

FROM order_profile;
GO
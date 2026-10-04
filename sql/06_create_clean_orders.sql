USE ChilePublicProcurementAnalytics;
GO

DROP TABLE IF EXISTS clean.purchase_orders;
GO

CREATE TABLE clean.purchase_orders (
    order_id BIGINT IDENTITY(1,1) PRIMARY KEY,

    source_file_type NVARCHAR(30) NOT NULL,
    source_period NVARCHAR(20) NOT NULL,

    codigo_oc NVARCHAR(50) NOT NULL,
    fecha_envio_oc DATE NOT NULL,

    estado_oc NVARCHAR(100),
    procedencia_oc NVARCHAR(100),
    moneda_oc NVARCHAR(10),

    monto_neto_oc_clp DECIMAL(28,9) NOT NULL,

    ent_code NVARCHAR(50),
    unidad_compra NVARCHAR(MAX),
    unidad_compra_rut NVARCHAR(20),
    region_unidad_compra NVARCHAR(MAX),
    institucion NVARCHAR(MAX),

    proveedor NVARCHAR(MAX),
    proveedor_rut NVARCHAR(20),
    tamano_proveedor NVARCHAR(50),
    region_proveedor NVARCHAR(MAX)
);
GO


INSERT INTO clean.purchase_orders (
    source_file_type,
    source_period,
    codigo_oc,
    fecha_envio_oc,
    estado_oc,
    procedencia_oc,
    moneda_oc,
    monto_neto_oc_clp,

    ent_code,
    unidad_compra,
    unidad_compra_rut,
    region_unidad_compra,
    institucion,

    proveedor,
    proveedor_rut,
    tamano_proveedor,
    region_proveedor
)
SELECT
    'TratoDirecto',
    '2025_H1',

    LTRIM(RTRIM(codigoOC)),

    MAX(
        TRY_CONVERT(
            DATE,
            LEFT(FechaEnvioOC, 10),
            105
        )
    ),

    MAX(NULLIF(LTRIM(RTRIM(EstadoOC)), '')),
    MAX(NULLIF(LTRIM(RTRIM(ProcedenciaOC)), '')),
    MAX(NULLIF(LTRIM(RTRIM(MonedaOC)), '')),

    MAX(
        TRY_CONVERT(
            DECIMAL(28,9),
            REPLACE(MontoNetoOC_CLP, ',', '.')
        )
    ),

    MAX(NULLIF(LTRIM(RTRIM(entCode)), '')),
    MAX(NULLIF(LTRIM(RTRIM(UnidadCompra)), '')),
    MAX(UPPER(NULLIF(LTRIM(RTRIM(UnidadCompraRUT)), ''))),
    MAX(NULLIF(LTRIM(RTRIM(RegionUnidadCompra)), '')),
    MAX(NULLIF(LTRIM(RTRIM(Institucion)), '')),

    MAX(NULLIF(LTRIM(RTRIM(Proveedor)), '')),
    MAX(UPPER(NULLIF(LTRIM(RTRIM(ProveedorRUT)), ''))),
    MAX(NULLIF(LTRIM(RTRIM(TamanoProveedor)), '')),
    MAX(NULLIF(LTRIM(RTRIM(RegionProveedor)), ''))

FROM staging.trato_directo_raw
GROUP BY codigoOC;
GO


CREATE UNIQUE INDEX UX_purchase_orders_codigo_oc
ON clean.purchase_orders(codigo_oc);
GO
USE ChilePublicProcurementAnalytics;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'clean'
)
BEGIN
    EXEC('CREATE SCHEMA clean');
END;
GO

DROP TABLE IF EXISTS clean.purchase_order_items;
GO

CREATE TABLE clean.purchase_order_items (
    item_id BIGINT IDENTITY(1,1) PRIMARY KEY,

    source_file_type NVARCHAR(30) NOT NULL,
    source_period NVARCHAR(20) NOT NULL,

    codigo_oc NVARCHAR(50) NOT NULL,
    fecha_envio_oc DATE NOT NULL,

    estado_oc NVARCHAR(100),
    procedencia_oc NVARCHAR(100),
    moneda_oc NVARCHAR(10),

    unidad_compra NVARCHAR(MAX),
    unidad_compra_rut NVARCHAR(20),
    region_unidad_compra NVARCHAR(MAX),
    ent_code NVARCHAR(50),
    institucion NVARCHAR(MAX),

    proveedor NVARCHAR(MAX),
    proveedor_rut NVARCHAR(20),
    tamano_proveedor NVARCHAR(50),
    region_proveedor NVARCHAR(MAX),

    rubro_n1 NVARCHAR(MAX),
    rubro_n2 NVARCHAR(MAX),
    rubro_n3 NVARCHAR(MAX),

    codigo_producto_onu NVARCHAR(20) NOT NULL,
    onu_producto NVARCHAR(MAX) NOT NULL,

    nombre_item NVARCHAR(MAX),
    descripcion_item NVARCHAR(MAX),

    cantidad_item DECIMAL(28,9) NOT NULL,
    unidad_medida NVARCHAR(100),
    moneda_item NVARCHAR(10),

    monto_neto_item_clp DECIMAL(28,9) NOT NULL,

    is_zero_quantity BIT NOT NULL,
    is_zero_amount_clp BIT NOT NULL
);
GO

INSERT INTO clean.purchase_order_items (
    source_file_type,
    source_period,
    codigo_oc,
    fecha_envio_oc,
    estado_oc,
    procedencia_oc,
    moneda_oc,
    unidad_compra,
    unidad_compra_rut,
    region_unidad_compra,
    ent_code,
    institucion,
    proveedor,
    proveedor_rut,
    tamano_proveedor,
    region_proveedor,
    rubro_n1,
    rubro_n2,
    rubro_n3,
    codigo_producto_onu,
    onu_producto,
    nombre_item,
    descripcion_item,
    cantidad_item,
    unidad_medida,
    moneda_item,
    monto_neto_item_clp,
    is_zero_quantity,
    is_zero_amount_clp
)
SELECT
    'TratoDirecto',
    '2025_H1',

    LTRIM(RTRIM(codigoOC)),

    TRY_CONVERT(
        DATE,
        LEFT(FechaEnvioOC, 10),
        105
    ),

    NULLIF(LTRIM(RTRIM(EstadoOC)), ''),
    NULLIF(LTRIM(RTRIM(ProcedenciaOC)), ''),
    NULLIF(LTRIM(RTRIM(MonedaOC)), ''),

    NULLIF(LTRIM(RTRIM(UnidadCompra)), ''),
    UPPER(NULLIF(LTRIM(RTRIM(UnidadCompraRUT)), '')),
    NULLIF(LTRIM(RTRIM(RegionUnidadCompra)), ''),
    NULLIF(LTRIM(RTRIM(entCode)), ''),
    NULLIF(LTRIM(RTRIM(Institucion)), ''),

    NULLIF(LTRIM(RTRIM(Proveedor)), ''),
    UPPER(NULLIF(LTRIM(RTRIM(ProveedorRUT)), '')),
    NULLIF(LTRIM(RTRIM(TamanoProveedor)), ''),
    NULLIF(LTRIM(RTRIM(RegionProveedor)), ''),

    NULLIF(LTRIM(RTRIM(RubroN1)), ''),
    NULLIF(LTRIM(RTRIM(RubroN2)), ''),
    NULLIF(LTRIM(RTRIM(RubroN3)), ''),

    LTRIM(RTRIM(CodigoProductoONU)),
    LTRIM(RTRIM(ONUProducto)),

    NULLIF(LTRIM(RTRIM(NombreItem)), ''),
    NULLIF(LTRIM(RTRIM(DescripcionItem)), ''),

    TRY_CONVERT(
        DECIMAL(28,9),
        REPLACE(CantidadItem, ',', '.')
    ),

    NULLIF(LTRIM(RTRIM(UnidadMedida)), ''),
    NULLIF(LTRIM(RTRIM(MonedaItem)), ''),

    TRY_CONVERT(
        DECIMAL(28,9),
        REPLACE(MontoNetoItemCLP, ',', '.')
    ),

    CASE
        WHEN TRY_CONVERT(
            DECIMAL(28,9),
            REPLACE(CantidadItem, ',', '.')
        ) = 0
        THEN 1 ELSE 0
    END,

    CASE
        WHEN TRY_CONVERT(
            DECIMAL(28,9),
            REPLACE(MontoNetoItemCLP, ',', '.')
        ) = 0
        THEN 1 ELSE 0
    END

FROM staging.trato_directo_raw;
GO
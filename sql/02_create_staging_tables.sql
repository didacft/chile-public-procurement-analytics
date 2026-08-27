USE ChilePublicProcurementAnalytics;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'staging'
)
BEGIN
    EXEC('CREATE SCHEMA staging');
END;
GO

CREATE TABLE staging.trato_directo_raw (
    codigoOC NVARCHAR(MAX),
    FechaEnvioOC NVARCHAR(MAX),
    NombreOC NVARCHAR(MAX),
    DescripcionOC NVARCHAR(MAX),
    EstadoOC NVARCHAR(MAX),
    ProcedenciaOC NVARCHAR(MAX),
    MonedaOC NVARCHAR(MAX),
    MontoNetoOC NVARCHAR(MAX),
    DescuentosOC NVARCHAR(MAX),
    CargosOC NVARCHAR(MAX),
    ImpuestosOC NVARCHAR(MAX),
    MontoTotalOC NVARCHAR(MAX),
    ImpuestosOC_CLP NVARCHAR(MAX),
    MontoNetoOC_CLP NVARCHAR(MAX),
    MetodoPago NVARCHAR(MAX),
    TipoDespacho NVARCHAR(MAX),
    Financiamiento NVARCHAR(MAX),
    UnidadCompra NVARCHAR(MAX),
    UnidadCompraRUT NVARCHAR(MAX),
    RegionUnidadCompra NVARCHAR(MAX),
    entCode NVARCHAR(MAX),
    Institucion NVARCHAR(MAX),
    Sector NVARCHAR(MAX),
    Proveedor NVARCHAR(MAX),
    ProveedorRUT NVARCHAR(MAX),
    ActividadProveedor NVARCHAR(MAX),
    TamanoProveedor NVARCHAR(MAX),
    RegionProveedor NVARCHAR(MAX),
    RubroN1 NVARCHAR(MAX),
    RubroN2 NVARCHAR(MAX),
    RubroN3 NVARCHAR(MAX),
    CodigoProductoONU NVARCHAR(MAX),
    ONUProducto NVARCHAR(MAX),
    NombreItem NVARCHAR(MAX),
    DescripcionItem NVARCHAR(MAX),
    CantidadItem NVARCHAR(MAX),
    UnidadMedida NVARCHAR(MAX),
    MonedaItem NVARCHAR(MAX),
    MontoNetoItem NVARCHAR(MAX),
    DescuentoItem NVARCHAR(MAX),
    CargosItem NVARCHAR(MAX),
    ImpuestoEspecificoItem NVARCHAR(MAX),
    MontoTotalItem NVARCHAR(MAX),
    MontoNetoItemCLP NVARCHAR(MAX)
);
GO
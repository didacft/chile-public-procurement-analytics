USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   ANALYTICS SCHEMA
   Dimensional model for reporting / Power BI
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analytics'
)
BEGIN
    EXEC('CREATE SCHEMA analytics');
END;
GO


/* ============================================================
   DROP DIMENSIONS
   Safe at this stage because fact tables do not exist yet.
   ============================================================ */

DROP TABLE IF EXISTS analytics.dim_date;
DROP TABLE IF EXISTS analytics.dim_product;
DROP TABLE IF EXISTS analytics.dim_buying_unit;
DROP TABLE IF EXISTS analytics.dim_buyer;
DROP TABLE IF EXISTS analytics.dim_supplier;
GO


/* ============================================================
   1. SUPPLIER DIMENSION
   Natural key: proveedor_rut
   ============================================================ */

CREATE TABLE analytics.dim_supplier (
    supplier_key INT IDENTITY(1,1) PRIMARY KEY,

    proveedor_rut NVARCHAR(15) NOT NULL,
    proveedor NVARCHAR(150) NOT NULL,
    tamano_proveedor NVARCHAR(30),

    CONSTRAINT UQ_dim_supplier_rut
        UNIQUE (proveedor_rut)
);
GO


INSERT INTO analytics.dim_supplier (
    proveedor_rut,
    proveedor,
    tamano_proveedor
)
SELECT
    proveedor_rut,
    MAX(proveedor),
    MAX(tamano_proveedor)
FROM clean.purchase_orders
GROUP BY proveedor_rut;
GO


/* ============================================================
   2. BUYER ENTITY DIMENSION
   Natural key: ent_code
   ============================================================ */

CREATE TABLE analytics.dim_buyer (
    buyer_key INT IDENTITY(1,1) PRIMARY KEY,

    ent_code NVARCHAR(15) NOT NULL,
    institucion NVARCHAR(100) NOT NULL,

    CONSTRAINT UQ_dim_buyer_ent_code
        UNIQUE (ent_code)
);
GO


INSERT INTO analytics.dim_buyer (
    ent_code,
    institucion
)
SELECT
    ent_code,
    MAX(institucion)
FROM clean.purchase_orders
GROUP BY ent_code;
GO


/* ============================================================
   3. BUYING UNIT DIMENSION
   Natural key: ent_code + unidad_compra

   unidad_compra_rut does NOT uniquely identify a buying unit.
   ============================================================ */

CREATE TABLE analytics.dim_buying_unit (
    buying_unit_key INT IDENTITY(1,1) PRIMARY KEY,

    ent_code NVARCHAR(15) NOT NULL,
    unidad_compra NVARCHAR(100) NOT NULL,
    unidad_compra_rut NVARCHAR(15) NOT NULL,

    CONSTRAINT UQ_dim_buying_unit_natural
        UNIQUE (ent_code, unidad_compra)
);
GO


INSERT INTO analytics.dim_buying_unit (
    ent_code,
    unidad_compra,
    unidad_compra_rut
)
SELECT
    ent_code,
    unidad_compra,
    MAX(unidad_compra_rut)
FROM clean.purchase_orders
GROUP BY
    ent_code,
    unidad_compra;
GO


/* ============================================================
   4. PRODUCT DIMENSION
   Natural key: codigo_producto_onu
   ============================================================ */

CREATE TABLE analytics.dim_product (
    product_key INT IDENTITY(1,1) PRIMARY KEY,

    codigo_producto_onu NVARCHAR(15) NOT NULL,
    onu_producto NVARCHAR(160) NOT NULL,

    rubro_n1 NVARCHAR(150),
    rubro_n2 NVARCHAR(150),
    rubro_n3 NVARCHAR(150),

    CONSTRAINT UQ_dim_product_code
        UNIQUE (codigo_producto_onu)
);
GO


INSERT INTO analytics.dim_product (
    codigo_producto_onu,
    onu_producto,
    rubro_n1,
    rubro_n2,
    rubro_n3
)
SELECT
    codigo_producto_onu,
    MAX(onu_producto),
    MAX(rubro_n1),
    MAX(rubro_n2),
    MAX(rubro_n3)
FROM clean.purchase_order_items
GROUP BY codigo_producto_onu;
GO


/* ============================================================
   5. DATE DIMENSION
   Continuous calendar between first and last purchase date.
   ============================================================ */

CREATE TABLE analytics.dim_date (
    date_key INT PRIMARY KEY,

    full_date DATE NOT NULL,

    year_number SMALLINT NOT NULL,
    semester_number TINYINT NOT NULL,
    quarter_number TINYINT NOT NULL,

    month_number TINYINT NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    year_month CHAR(7) NOT NULL,

    day_of_month TINYINT NOT NULL,
    day_of_week_iso TINYINT NOT NULL,
    day_name NVARCHAR(20) NOT NULL,

    CONSTRAINT UQ_dim_date_full_date
        UNIQUE (full_date)
);
GO


DECLARE @min_date DATE;
DECLARE @max_date DATE;

SELECT
    @min_date = DATEFROMPARTS(
        YEAR(MIN(fecha_envio_oc)),
        MONTH(MIN(fecha_envio_oc)),
        1
    ),

    @max_date = EOMONTH(
        MAX(fecha_envio_oc)
    )
FROM clean.purchase_orders;

WITH dates AS (
    SELECT @min_date AS full_date

    UNION ALL

    SELECT DATEADD(DAY, 1, full_date)
    FROM dates
    WHERE full_date < @max_date
)
INSERT INTO analytics.dim_date (
    date_key,
    full_date,
    year_number,
    semester_number,
    quarter_number,
    month_number,
    month_name,
    year_month,
    day_of_month,
    day_of_week_iso,
    day_name
)
SELECT
    YEAR(full_date) * 10000
        + MONTH(full_date) * 100
        + DAY(full_date),

    full_date,

    YEAR(full_date),

    CASE
        WHEN MONTH(full_date) <= 6 THEN 1
        ELSE 2
    END,

    DATEPART(QUARTER, full_date),

    MONTH(full_date),

    CASE MONTH(full_date)
        WHEN 1 THEN N'Enero'
        WHEN 2 THEN N'Febrero'
        WHEN 3 THEN N'Marzo'
        WHEN 4 THEN N'Abril'
        WHEN 5 THEN N'Mayo'
        WHEN 6 THEN N'Junio'
        WHEN 7 THEN N'Julio'
        WHEN 8 THEN N'Agosto'
        WHEN 9 THEN N'Septiembre'
        WHEN 10 THEN N'Octubre'
        WHEN 11 THEN N'Noviembre'
        WHEN 12 THEN N'Diciembre'
    END,

    CONCAT(
        YEAR(full_date),
        '-',
        RIGHT('0' + CAST(MONTH(full_date) AS VARCHAR(2)), 2)
    ),

    DAY(full_date),

    (DATEDIFF(DAY, '19000101', full_date) % 7) + 1,

    CASE ((DATEDIFF(DAY, '19000101', full_date) % 7) + 1)
        WHEN 1 THEN N'Lunes'
        WHEN 2 THEN N'Martes'
        WHEN 3 THEN N'Miércoles'
        WHEN 4 THEN N'Jueves'
        WHEN 5 THEN N'Viernes'
        WHEN 6 THEN N'Sábado'
        WHEN 7 THEN N'Domingo'
    END

FROM dates
OPTION (MAXRECURSION 0);
GO


/* ============================================================
   VALIDATION
   ============================================================ */

SELECT
    (SELECT COUNT(*) FROM analytics.dim_supplier)
        AS suppliers,

    (SELECT COUNT(*) FROM analytics.dim_buyer)
        AS buyer_entities,

    (SELECT COUNT(*) FROM analytics.dim_buying_unit)
        AS buying_units,

    (SELECT COUNT(*) FROM analytics.dim_product)
        AS products,

    (SELECT COUNT(*) FROM analytics.dim_date)
        AS calendar_days;
GO
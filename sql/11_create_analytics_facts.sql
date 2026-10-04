USE ChilePublicProcurementAnalytics;
GO


/* ============================================================
   ANALYTICAL FACT TABLES

   fact_orders:
       Grain = one row per purchase order

   fact_order_items:
       Grain = one row per purchase order item

   Both facts share conformed dimensions so Power BI can
   analyze orders and item-level spend consistently.
   ============================================================ */


/* ============================================================
   DROP EXISTING FACTS
   Child table first because it references fact_orders.
   ============================================================ */

DROP TABLE IF EXISTS analytics.fact_order_items;
DROP TABLE IF EXISTS analytics.fact_orders;
GO


/* ============================================================
   1. ORDER FACT
   Grain: one row per codigo_oc
   ============================================================ */

CREATE TABLE analytics.fact_orders (
    order_key BIGINT IDENTITY(1,1) PRIMARY KEY,

    codigo_oc NVARCHAR(50) NOT NULL,

    date_key INT NOT NULL,
    supplier_key INT NOT NULL,
    buyer_key INT NOT NULL,
    buying_unit_key INT NOT NULL,

    buyer_region_key TINYINT NOT NULL,
    supplier_region_key TINYINT NOT NULL,

    estado_oc NVARCHAR(100),
    procedencia_oc NVARCHAR(100),
    moneda_oc NVARCHAR(10),

    monto_neto_oc_clp DECIMAL(28,9) NOT NULL,

    source_file_type NVARCHAR(30) NOT NULL,
    source_period NVARCHAR(20) NOT NULL,

    CONSTRAINT UQ_fact_orders_codigo_oc
        UNIQUE (codigo_oc),

    CONSTRAINT FK_fact_orders_date
        FOREIGN KEY (date_key)
        REFERENCES analytics.dim_date(date_key),

    CONSTRAINT FK_fact_orders_supplier
        FOREIGN KEY (supplier_key)
        REFERENCES analytics.dim_supplier(supplier_key),

    CONSTRAINT FK_fact_orders_buyer
        FOREIGN KEY (buyer_key)
        REFERENCES analytics.dim_buyer(buyer_key),

    CONSTRAINT FK_fact_orders_buying_unit
        FOREIGN KEY (buying_unit_key)
        REFERENCES analytics.dim_buying_unit(buying_unit_key),

    CONSTRAINT FK_fact_orders_buyer_region
        FOREIGN KEY (buyer_region_key)
        REFERENCES analytics.dim_region(region_key),

    CONSTRAINT FK_fact_orders_supplier_region
        FOREIGN KEY (supplier_region_key)
        REFERENCES analytics.dim_region(region_key)
);
GO


/* ============================================================
   LOAD ORDER FACT
   ============================================================ */

INSERT INTO analytics.fact_orders (
    codigo_oc,

    date_key,
    supplier_key,
    buyer_key,
    buying_unit_key,

    buyer_region_key,
    supplier_region_key,

    estado_oc,
    procedencia_oc,
    moneda_oc,

    monto_neto_oc_clp,

    source_file_type,
    source_period
)
SELECT
    o.codigo_oc,

    d.date_key,
    s.supplier_key,
    b.buyer_key,
    bu.buying_unit_key,

    br.region_key,
    sr.region_key,

    o.estado_oc,
    o.procedencia_oc,
    o.moneda_oc,

    o.monto_neto_oc_clp,

    o.source_file_type,
    o.source_period

FROM clean.purchase_orders AS o

INNER JOIN analytics.dim_date AS d
    ON o.fecha_envio_oc = d.full_date

INNER JOIN analytics.dim_supplier AS s
    ON o.proveedor_rut = s.proveedor_rut

INNER JOIN analytics.dim_buyer AS b
    ON o.ent_code = b.ent_code

INNER JOIN analytics.dim_buying_unit AS bu
    ON o.ent_code = bu.ent_code
    AND o.unidad_compra = bu.unidad_compra

LEFT JOIN clean.region_mapping AS brm
    ON o.region_unidad_compra = brm.raw_region

INNER JOIN analytics.dim_region AS br
    ON br.region_name =
        COALESCE(
            brm.canonical_region,
            N'Sin información'
        )

LEFT JOIN clean.region_mapping AS srm
    ON o.region_proveedor = srm.raw_region

INNER JOIN analytics.dim_region AS sr
    ON sr.region_name =
        COALESCE(
            srm.canonical_region,
            N'Sin información'
        );
GO


/* ============================================================
   2. ORDER ITEM FACT
   Grain: one row per original purchase order item
   ============================================================ */

CREATE TABLE analytics.fact_order_items (
    order_item_key BIGINT IDENTITY(1,1) PRIMARY KEY,

    source_item_id BIGINT NOT NULL,
    order_key BIGINT NOT NULL,

    date_key INT NOT NULL,
    supplier_key INT NOT NULL,
    buyer_key INT NOT NULL,
    buying_unit_key INT NOT NULL,

    buyer_region_key TINYINT NOT NULL,
    supplier_region_key TINYINT NOT NULL,

    product_key INT NOT NULL,

    codigo_oc NVARCHAR(50) NOT NULL,

    cantidad_item DECIMAL(28,9) NOT NULL,
    unidad_medida NVARCHAR(50),
    moneda_item NVARCHAR(10),

    monto_neto_item_clp DECIMAL(28,9) NOT NULL,

    is_zero_quantity BIT NOT NULL,
    is_zero_amount_clp BIT NOT NULL,

    source_file_type NVARCHAR(30) NOT NULL,
    source_period NVARCHAR(20) NOT NULL,

    CONSTRAINT UQ_fact_order_items_source_item
        UNIQUE (source_item_id),

    CONSTRAINT FK_fact_items_order
        FOREIGN KEY (order_key)
        REFERENCES analytics.fact_orders(order_key),

    CONSTRAINT FK_fact_items_date
        FOREIGN KEY (date_key)
        REFERENCES analytics.dim_date(date_key),

    CONSTRAINT FK_fact_items_supplier
        FOREIGN KEY (supplier_key)
        REFERENCES analytics.dim_supplier(supplier_key),

    CONSTRAINT FK_fact_items_buyer
        FOREIGN KEY (buyer_key)
        REFERENCES analytics.dim_buyer(buyer_key),

    CONSTRAINT FK_fact_items_buying_unit
        FOREIGN KEY (buying_unit_key)
        REFERENCES analytics.dim_buying_unit(buying_unit_key),

    CONSTRAINT FK_fact_items_buyer_region
        FOREIGN KEY (buyer_region_key)
        REFERENCES analytics.dim_region(region_key),

    CONSTRAINT FK_fact_items_supplier_region
        FOREIGN KEY (supplier_region_key)
        REFERENCES analytics.dim_region(region_key),

    CONSTRAINT FK_fact_items_product
        FOREIGN KEY (product_key)
        REFERENCES analytics.dim_product(product_key)
);
GO


/* ============================================================
   LOAD ITEM FACT

   Shared dimension keys are inherited from fact_orders.
   This guarantees that order-level and item-level analysis
   use exactly the same buyer, supplier, date and region keys.
   ============================================================ */

INSERT INTO analytics.fact_order_items (
    source_item_id,
    order_key,

    date_key,
    supplier_key,
    buyer_key,
    buying_unit_key,

    buyer_region_key,
    supplier_region_key,

    product_key,

    codigo_oc,

    cantidad_item,
    unidad_medida,
    moneda_item,

    monto_neto_item_clp,

    is_zero_quantity,
    is_zero_amount_clp,

    source_file_type,
    source_period
)
SELECT
    i.item_id,
    fo.order_key,

    fo.date_key,
    fo.supplier_key,
    fo.buyer_key,
    fo.buying_unit_key,

    fo.buyer_region_key,
    fo.supplier_region_key,

    p.product_key,

    i.codigo_oc,

    i.cantidad_item,
    i.unidad_medida,
    i.moneda_item,

    i.monto_neto_item_clp,

    i.is_zero_quantity,
    i.is_zero_amount_clp,

    i.source_file_type,
    i.source_period

FROM clean.purchase_order_items AS i

INNER JOIN analytics.fact_orders AS fo
    ON i.codigo_oc = fo.codigo_oc

INNER JOIN analytics.dim_product AS p
    ON i.codigo_producto_onu = p.codigo_producto_onu;
GO


/* ============================================================
   INDEXES
   Useful for joins and BI filtering.
   ============================================================ */

CREATE INDEX IX_fact_orders_date
    ON analytics.fact_orders(date_key);

CREATE INDEX IX_fact_orders_supplier
    ON analytics.fact_orders(supplier_key);

CREATE INDEX IX_fact_orders_buyer
    ON analytics.fact_orders(buyer_key);

CREATE INDEX IX_fact_orders_buying_unit
    ON analytics.fact_orders(buying_unit_key);

CREATE INDEX IX_fact_orders_buyer_region
    ON analytics.fact_orders(buyer_region_key);

CREATE INDEX IX_fact_orders_supplier_region
    ON analytics.fact_orders(supplier_region_key);
GO


CREATE INDEX IX_fact_items_order
    ON analytics.fact_order_items(order_key);

CREATE INDEX IX_fact_items_date
    ON analytics.fact_order_items(date_key);

CREATE INDEX IX_fact_items_supplier
    ON analytics.fact_order_items(supplier_key);

CREATE INDEX IX_fact_items_buyer
    ON analytics.fact_order_items(buyer_key);

CREATE INDEX IX_fact_items_buying_unit
    ON analytics.fact_order_items(buying_unit_key);

CREATE INDEX IX_fact_items_product
    ON analytics.fact_order_items(product_key);

CREATE INDEX IX_fact_items_buyer_region
    ON analytics.fact_order_items(buyer_region_key);

CREATE INDEX IX_fact_items_supplier_region
    ON analytics.fact_order_items(supplier_region_key);
GO


/* ============================================================
   VALIDATION 1: FACT GRAINS
   ============================================================ */

SELECT
    COUNT(*) AS fact_orders,
    COUNT(DISTINCT codigo_oc) AS unique_orders
FROM analytics.fact_orders;
GO


SELECT
    COUNT(*) AS fact_items,
    COUNT(DISTINCT order_key) AS orders_represented
FROM analytics.fact_order_items;
GO


/* ============================================================
   VALIDATION 2: SPEND RECONCILIATION
   ============================================================ */

SELECT
    (SELECT SUM(monto_neto_oc_clp)
     FROM analytics.fact_orders)
        AS order_spend_clp,

    (SELECT SUM(monto_neto_item_clp)
     FROM analytics.fact_order_items)
        AS item_spend_clp,

    (
        (SELECT SUM(monto_neto_item_clp)
         FROM analytics.fact_order_items)
        -
        (SELECT SUM(monto_neto_oc_clp)
         FROM analytics.fact_orders)
    ) AS difference_clp;
GO


/* ============================================================
   VALIDATION 3: ZERO-AMOUNT / ZERO-QUANTITY FLAGS
   ============================================================ */

SELECT
    SUM(CASE
        WHEN is_zero_quantity = 1
        THEN 1 ELSE 0
    END) AS zero_quantity_rows,

    SUM(CASE
        WHEN is_zero_amount_clp = 1
        THEN 1 ELSE 0
    END) AS zero_amount_rows

FROM analytics.fact_order_items;
GO


/* ============================================================
   VALIDATION 4: UNKNOWN REGION USAGE
   ============================================================ */

SELECT
    r.region_name,

    SUM(
        CASE
            WHEN fo.buyer_region_key = r.region_key
            THEN 1 ELSE 0
        END
    ) AS buyer_orders,

    SUM(
        CASE
            WHEN fo.supplier_region_key = r.region_key
            THEN 1 ELSE 0
        END
    ) AS supplier_orders

FROM analytics.dim_region AS r

CROSS JOIN analytics.fact_orders AS fo

WHERE r.region_name IN (
    N'Extranjero',
    N'Sin información'
)

GROUP BY
    r.region_key,
    r.region_name

ORDER BY
    r.region_key;
GO
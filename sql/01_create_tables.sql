USE CustomerCommercialAnalyticsChile;
GO

CREATE TABLE dbo.customers (
    customer_id INT PRIMARY KEY,
    birth_date DATE,
    gender VARCHAR(20),
    region VARCHAR(100),
    commune VARCHAR(100),
    registration_date DATE,
    acquisition_channel VARCHAR(50),
    loyalty_member BIT
);
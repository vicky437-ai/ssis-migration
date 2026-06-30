{{
    config(
        materialized='table',
        schema='dbo',
        alias='FactInternetSales'
    )
}}

/*
    dbt model: load_fact_internet_sales
    Source SSIS package: 03_LoadFactInternetSales.dtsx
    Data flow: OLE DB Source (stg.SalesOnline)  ─┐
               OLE DB Source (stg.SalesReseller) ─┤→ Union All
             → Lookup Product (ProductAlternateKey → ProductKey)
             → Lookup Customer (CustomerAlternateKey → CustomerKey)
             → OLE DB Destination (dbo.FactInternetSales)
*/

WITH unioned_sales AS (
    SELECT
        ProductAlternateKey,
        CustomerAlternateKey,
        SalesTerritoryKey,
        SalesOrderNumber,
        SalesOrderLineNumber,
        OrderQuantity,
        UnitPrice,
        ProductStandardCost,
        SalesAmount,
        TaxAmt,
        OrderDate
    FROM {{ source('stg', 'SalesOnline') }}

    UNION ALL

    SELECT
        ProductAlternateKey,
        CustomerAlternateKey,
        SalesTerritoryKey,
        SalesOrderNumber,
        SalesOrderLineNumber,
        OrderQuantity,
        UnitPrice,
        ProductStandardCost,
        SalesAmount,
        TaxAmt,
        OrderDate
    FROM {{ source('stg', 'SalesReseller') }}
)

SELECT
    p.ProductKey,
    CAST(TO_CHAR(s.OrderDate, 'YYYYMMDD') AS INT) AS OrderDateKey,
    c.CustomerKey,
    s.SalesTerritoryKey,
    s.SalesOrderNumber,
    s.SalesOrderLineNumber,
    s.OrderQuantity,
    s.UnitPrice,
    s.ProductStandardCost,
    s.SalesAmount,
    s.TaxAmt,
    s.OrderDate
FROM unioned_sales s
INNER JOIN {{ source('dbo', 'DimProduct') }} p
    ON s.ProductAlternateKey = p.ProductAlternateKey
INNER JOIN {{ source('dbo', 'DimCustomer') }} c
    ON s.CustomerAlternateKey = c.CustomerAlternateKey

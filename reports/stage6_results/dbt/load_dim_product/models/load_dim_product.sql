{{
    config(
        materialized='table',
        schema='dbo',
        alias='DimProduct'
    )
}}

/*
    dbt model: load_dim_product
    Source SSIS package: 01_LoadDimProduct.dtsx
    Data flow: OLE DB Source (stg.Product)
             → Lookup (DimProductSubcategory on ProductSubcategoryKey)
             → Derived Column (COALESCE Status → 'Outdated')
             → OLE DB Destination (dbo.DimProduct)
*/

SELECT
    ROW_NUMBER() OVER (ORDER BY p.ProductAlternateKey) AS ProductKey,
    p.ProductAlternateKey,
    p.EnglishProductName,
    p.ProductSubcategoryKey,
    p.Color,
    p.Size,
    p.StandardCost,
    p.ListPrice,
    p.ModelName,
    COALESCE(p.Status, 'Outdated') AS Status
FROM {{ source('stg', 'Product') }} p
INNER JOIN {{ source('dbo', 'DimProductSubcategory') }} sc
    ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey

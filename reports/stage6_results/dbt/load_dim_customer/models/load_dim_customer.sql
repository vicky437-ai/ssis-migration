{{
    config(
        materialized='table',
        schema='dbo',
        alias='DimCustomer'
    )
}}

/*
    dbt model: load_dim_customer
    Source SSIS package: 02_LoadDimCustomer.dtsx
    Data flow: OLE DB Source (stg.Customer)
             → Data Conversion (MaritalStatus→1 char, Gender→1 char, Education→Unicode)
             → Derived Column (FullName = FirstName + ' ' + LastName)
             → OLE DB Destination (dbo.DimCustomer)
*/

SELECT
    ROW_NUMBER() OVER (ORDER BY c.CustomerAlternateKey) AS CustomerKey,
    c.GeographyKey,
    c.CustomerAlternateKey,
    c.FirstName,
    c.LastName,
    c.FirstName || ' ' || c.LastName AS FullName,
    c.BirthDate,
    LEFT(c.MaritalStatus, 1) AS MaritalStatus,
    LEFT(c.Gender, 1) AS Gender,
    c.EmailAddress,
    c.YearlyIncome,
    CAST(c.EnglishEducation AS NVARCHAR(40)) AS EnglishEducation
FROM {{ source('stg', 'Customer') }} c

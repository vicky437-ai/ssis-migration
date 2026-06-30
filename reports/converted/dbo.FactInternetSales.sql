--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR dbo.FactInternetSales. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE dbo.FactInternetSales (
    ProductKey INT NOT NULL
           REFERENCES dbo.DimProduct (ProductKey),
    OrderDateKey INT NOT NULL,
    CustomerKey INT NOT NULL
           REFERENCES dbo.DimCustomer (CustomerKey),
    SalesTerritoryKey INT NULL,
    SalesOrderNumber NVARCHAR(20) NOT NULL,
    SalesOrderLineNumber TINYINT NOT NULL,
    OrderQuantity SMALLINT NULL,
    UnitPrice NUMBER(38, 4) NULL,
    ProductStandardCost NUMBER(38, 4) NULL,
    SalesAmount NUMBER(38, 4) NULL,
    TaxAmt NUMBER(38, 4) NULL,
    OrderDate TIMESTAMP_NTZ(3) NULL,
       CONSTRAINT PK_FactInternetSales
           PRIMARY KEY (SalesOrderNumber, SalesOrderLineNumber)
   )
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
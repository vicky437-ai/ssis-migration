--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR stg.SalesOnline. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE stg.SalesOnline (
    ProductAlternateKey NVARCHAR(25) NULL,
    CustomerAlternateKey NVARCHAR(15) NULL,
    SalesTerritoryKey INT NULL,
    SalesOrderNumber NVARCHAR(20) NOT NULL,
    SalesOrderLineNumber TINYINT NOT NULL,
    OrderQuantity SMALLINT NULL,
    UnitPrice NUMBER(38, 4) NULL,
    ProductStandardCost NUMBER(38, 4) NULL,
    SalesAmount NUMBER(38, 4) NULL,
    TaxAmt NUMBER(38, 4) NULL,
    OrderDate TIMESTAMP_NTZ(3) NULL
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
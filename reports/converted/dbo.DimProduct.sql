--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR dbo.DimProduct. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE dbo.DimProduct (
    ProductKey INT NOT NULL PRIMARY KEY,
    ProductAlternateKey NVARCHAR(25) NULL,
    EnglishProductName NVARCHAR(50) NOT NULL,
    ProductSubcategoryKey INT NULL
           REFERENCES dbo.DimProductSubcategory (ProductSubcategoryKey),
    Color NVARCHAR(15) NULL,
    Size NVARCHAR(50) NULL,
    StandardCost NUMBER(38, 4) NULL,
    ListPrice NUMBER(38, 4) NULL,
    ModelName NVARCHAR(50) NULL,
    Status NVARCHAR(7) NULL
   )
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
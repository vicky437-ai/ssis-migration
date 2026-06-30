--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR dbo.DimProductSubcategory. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE dbo.DimProductSubcategory (
    ProductSubcategoryKey INT NOT NULL PRIMARY KEY,
    ProductSubcategoryAlternateKey INT NULL,
    EnglishProductSubcategoryName NVARCHAR(50) NOT NULL,
    ProductCategoryKey INT NULL
           REFERENCES dbo.DimProductCategory (ProductCategoryKey)
   )
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
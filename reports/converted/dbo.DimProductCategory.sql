--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR dbo.DimProductCategory. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE dbo.DimProductCategory (
    ProductCategoryKey INT NOT NULL PRIMARY KEY,
    ProductCategoryAlternateKey INT NULL,
    EnglishProductCategoryName NVARCHAR(50) NOT NULL
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
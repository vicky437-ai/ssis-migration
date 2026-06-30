--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR dbo.DimGeography. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE dbo.DimGeography (
    GeographyKey INT NOT NULL PRIMARY KEY,
    City NVARCHAR(30) NULL,
    StateProvinceName NVARCHAR(50) NULL,
    EnglishCountryRegionName NVARCHAR(50) NULL,
    PostalCode NVARCHAR(15) NULL
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
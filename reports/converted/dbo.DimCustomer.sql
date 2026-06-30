--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR dbo.DimCustomer. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE dbo.DimCustomer (
    CustomerKey INT NOT NULL PRIMARY KEY,
    GeographyKey INT NULL
           REFERENCES dbo.DimGeography (GeographyKey),
    CustomerAlternateKey NVARCHAR(15) NULL,
    FirstName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NULL,
    FullName NVARCHAR(101) NULL,
    BirthDate DATE NULL,
    MaritalStatus NCHAR(1) NULL,
    Gender NCHAR(1) NULL,
    EmailAddress NVARCHAR(50) NULL,
    YearlyIncome NUMBER(38, 4) NULL,
    EnglishEducation NVARCHAR(40) NULL
   )
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
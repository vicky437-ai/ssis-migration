--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR stg.Customer. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE stg.Customer (
    CustomerAlternateKey NVARCHAR(15) NULL,
    GeographyKey INT NULL,
    FirstName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NULL,
    BirthDate DATE NULL,
    MaritalStatus NVARCHAR(2) NULL,
    Gender NVARCHAR(10) NULL,
    EmailAddress NVARCHAR(50) NULL,
    YearlyIncome NUMBER(38, 4) NULL,
    EnglishEducation VARCHAR(40) NULL
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
--** SSC-FDM-0019 - SEMANTIC INFORMATION COULD NOT BE LOADED FOR stg.CurrencyRate. CHECK IF THE NAME IS INVALID OR DUPLICATED. **
CREATE OR REPLACE TABLE stg.CurrencyRate (
    AverageRate FLOAT NULL,
    CurrencyKey INT NULL,
    CurrencyDateKey INT NULL,
    EndOfDayRate FLOAT NULL
)
COMMENT = '{ "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "ygSfAREzVHOUJZf8lRjiQw==" }}'
;
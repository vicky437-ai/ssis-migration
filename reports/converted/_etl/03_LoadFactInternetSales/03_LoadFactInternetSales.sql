CREATE OR REPLACE TASK public.t_03_loadfactinternetsales
COMMENT = '{ "description": "", "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "7QSfAc7FXnCnqtANrjQzNA==" }}'
AS
SELECT
   1;
CREATE OR REPLACE TASK public.t_03_loadfactinternetsales_load_factinternetsales
WAREHOUSE=DUMMY_WAREHOUSE
AFTER public.t_03_loadfactinternetsales
AS
BEGIN
   ---- Start block 'Package\Load FactInternetSales'
   EXECUTE DBT PROJECT public.Load_FactInternetSales ARGS='build --target dev';
   ---- End block 'Package\Load FactInternetSales'

END;


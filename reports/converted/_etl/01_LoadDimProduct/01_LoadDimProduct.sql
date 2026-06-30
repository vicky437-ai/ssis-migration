CREATE OR REPLACE TASK public.t_01_loaddimproduct
COMMENT = '{ "description": "", "origin": "sf_sc", "name": "snowconvert", "version": {  "major": 2,  "minor": 33,  "patch": "0-Pr.127" }, "attributes": {  "component": "transact",  "convertedOn": "06-26-2026",  "domain": "no-domain-provided",  "migrationid": "7QSfAc7FXnCnqtANrjQzNA==" }}'
AS
SELECT
   1;
CREATE OR REPLACE TASK public.t_01_loaddimproduct_load_dimproduct
WAREHOUSE=DUMMY_WAREHOUSE
AFTER public.t_01_loaddimproduct
AS
BEGIN
   ---- Start block 'Package\Load DimProduct'
   EXECUTE DBT PROJECT public.Load_DimProduct ARGS='build --target dev';
   ---- End block 'Package\Load DimProduct'

END;


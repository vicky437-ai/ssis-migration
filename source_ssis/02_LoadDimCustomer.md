# 02_LoadDimCustomer.dtsx

**Intent:** Load the customer dimension. Read `stg.Customer`, clean/convert
columns (the classic AdventureWorks Data Conversion pattern), derive a full
name, and load `dbo.DimCustomer`.

**Data Flow (single Data Flow Task "Load DimCustomer"):**
1. `Microsoft.OLEDBSource` — `[stg].[Customer]` (note `EnglishEducation` is
   non-Unicode `str` on purpose)
2. `Microsoft.DataConvert` — clean `MaritalStatus`/`Gender` to single Unicode
   char; convert `EnglishEducation` from `str` → `wstr` (Unicode)
3. `Microsoft.DerivedColumn` — `FullName = [FirstName] + " " + [LastName]`
4. `Microsoft.OLEDBDestination` — `[dbo].[DimCustomer]`

**Expected agent classification:** Data Transformation → **dbt model**.

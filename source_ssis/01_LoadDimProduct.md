# 01_LoadDimProduct.dtsx

**Intent:** Load the product dimension. Read `stg.Product`, enrich it with the
subcategory name via a Lookup, clean the product status with a Derived Column,
and load `dbo.DimProduct`.

**Data Flow (single Data Flow Task "Load DimProduct"):**
1. `Microsoft.OLEDBSource` — `[stg].[Product]`
2. `Microsoft.Lookup` — against `[dbo].[DimProductSubcategory]` on
   `ProductSubcategoryKey`, adds `EnglishProductSubcategoryName`
3. `Microsoft.DerivedColumn` — `ProductStatus = ISNULL([Status]) ? "Outdated" : [Status]`
4. `Microsoft.OLEDBDestination` — `[dbo].[DimProduct]` (ProductStatus → Status)

**Expected agent classification:** Data Transformation → **dbt model**.

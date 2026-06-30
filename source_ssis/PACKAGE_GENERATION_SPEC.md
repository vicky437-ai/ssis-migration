# PACKAGE_GENERATION_SPEC — instructions for the Claude Code session

> Purpose: this file tells the in-project Claude Code session exactly what to
> author into `source_ssis/` (the `.dtsx` packages) and `sql/` (the source DDL).
> It is the input to runbook Step 3. Read CLAUDE.md first for framing/risk.

## Authoring principles (de-risk the SnowConvert parse — Gate G1)

The biggest risk is that hand-authored `.dtsx` parses differently than
Visual-Studio-authored ones. To minimize that, author CONSERVATIVELY:

1. Target SSIS 2012+ package format: root element
   `<DTS:Executable xmlns:DTS="www.microsoft.com/SqlServer/Dts"
   DTS:ExecutableType="Microsoft.Package" DTS:DTSID="{GUID}"
   DTS:ObjectName="...">`.
2. Use the modern `componentClassID` string IDs (not legacy CLSIDs), e.g.
   `Microsoft.OLEDBSource`, `Microsoft.OLEDBDestination`, `Microsoft.Lookup`,
   `Microsoft.DerivedColumn`, `Microsoft.DataConvert`, `Microsoft.UnionAll`,
   `Microsoft.FlatFileSource`.
3. Give EVERY element a real GUID for `DTS:DTSID` / `refId` / `lineageId`.
   Generate them; never reuse the same GUID twice.
4. Keep each package SMALL and single-purpose. One Data Flow Task per package,
   3–5 components max. Do not add event handlers, configurations, expressions,
   or script tasks — those are the parts most likely to trip a parser.
5. Connection managers: use OLE DB for SQL Server sources/targets and Flat File
   for the currency file. Put connection strings as plaintext attributes
   (no parameterization, no project params).
6. After writing each file, validate it is well-formed XML
   (`python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse(sys.argv[1])" <file>`).
   Well-formed != SnowConvert-valid, but it catches obvious breakage.
7. Write a short comment block at the top of each package's companion `.md`
   (NOT inside the .dtsx) describing its intent and expected classification.

## The four packages (mirrors the Snowflake demo classification spread)

All column names below are REAL AdventureWorksDW columns — use them verbatim.

### 01_LoadDimProduct.dtsx  → expect: Data Transformation → dbt model
- Source: OLE DB source on `stg.Product` (staging copy, see DDL).
- Lookup: `Microsoft.Lookup` against `dbo.DimProductSubcategory` on
  `ProductSubcategoryKey` to bring in `EnglishProductSubcategoryName`.
- Derived Column: `Microsoft.DerivedColumn` — compute
  `ProductStatus = ISNULL(Status) ? "Outdated" : Status`.
- Destination: OLE DB destination → `dbo.DimProduct`.
- Real DimProduct columns: ProductKey, ProductAlternateKey, EnglishProductName,
  ProductSubcategoryKey, Color, Size, StandardCost, ListPrice, ModelName, Status.

### 02_LoadDimCustomer.dtsx  → expect: Data Transformation → dbt model
- Source: OLE DB source on `stg.Customer`.
- Data Conversion: `Microsoft.DataConvert` — cast `Gender` and `MaritalStatus`
  to clean single-char; convert a non-Unicode text col to Unicode (classic
  AdventureWorks ETL pattern).
- Derived Column: `FullName = FirstName + " " + LastName`.
- Destination: OLE DB destination → `dbo.DimCustomer`.
- Real DimCustomer columns: CustomerKey, GeographyKey, FirstName, LastName,
  BirthDate, MaritalStatus, Gender, EmailAddress, YearlyIncome.

### 03_LoadFactInternetSales.dtsx  → expect: Mixed → Snowpark + Tasks DAG
- Two OLE DB sources: `stg.SalesOnline` and `stg.SalesReseller`.
- Two Lookups: against `dbo.DimProduct` (ProductKey) and `dbo.DimCustomer`
  (CustomerKey) to resolve surrogate keys.
- `Microsoft.UnionAll` to merge the two sources.
- A Flat File destination (export rejected rows) — this multi-source +
  union + flat-file export is what pushes it into the "Mixed" bucket.
- Destination: OLE DB destination → `dbo.FactInternetSales`.
- Real FactInternetSales columns: ProductKey, OrderDateKey, CustomerKey,
  SalesTerritoryKey, SalesOrderNumber, SalesOrderLineNumber, OrderQuantity,
  UnitPrice, ProductStandardCost, SalesAmount, TaxAmt, OrderDate.

### 04_StageCurrencyRates.dtsx  → expect: Ingestion
- Source: `Microsoft.FlatFileSource` on `SampleCurrencyData.txt`
  (4 cols: avg rate, currency key, date key, end-of-day rate — the real
  Microsoft tutorial file format).
- Destination: OLE DB destination → `stg.CurrencyRate`.
- No transforms — pure ingest. Keep it trivial.

## The DDL (sql/01_adventureworksdw_source.sql)

Author CREATE TABLE statements for the REAL AdventureWorksDW tables the
packages read/write, plus the `stg.*` staging tables the packages source from.
Use SQL Server T-SQL types (INT, NVARCHAR(n), MONEY, DATETIME, BIT) so the
agent sees an authentic SQL Server source dialect. Include:
- dbo.DimProduct, dbo.DimProductSubcategory, dbo.DimProductCategory
- dbo.DimCustomer, dbo.DimGeography
- dbo.FactInternetSales
- stg.Product, stg.Customer, stg.SalesOnline, stg.SalesReseller, stg.CurrencyRate
Add a small INSERT of ~20 rows per staging table so assessment + any run has
real data to inventory. Keep inserts realistic (real-looking product names,
customer names, sales amounts).

## After authoring — STOP and run Gate G1

Do NOT proceed to convert/deploy. Hand control to Cortex Code:
```
cortex
> Start a database migration. Source is SQL Server with SSIS packages in
  ./source_ssis and DDL in ./sql. Run ASSESSMENT ONLY — do not deploy or migrate.
```
Then report: did all 4 packages parse? What classification did each get?
That result decides the next move (see RUNBOOK Gate G1 remediation ladder).

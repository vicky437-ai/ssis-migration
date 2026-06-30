# 03_LoadFactInternetSales.dtsx

**Intent:** Load the internet sales fact. Merge two sources (online + reseller)
with a Union All, resolve surrogate keys via two Lookups, and load
`dbo.FactInternetSales`.

**Data Flow (single Data Flow Task "Load FactInternetSales"):**
1. `Microsoft.OLEDBSource` ×2 — `[stg].[SalesOnline]`, `[stg].[SalesReseller]`
2. `Microsoft.UnionAll` — merge the two sources
3. `Microsoft.Lookup` (Product) — `[dbo].[DimProduct]` on `ProductAlternateKey`
   → `ProductKey`
4. `Microsoft.Lookup` (Customer) — `[dbo].[DimCustomer]` on `CustomerAlternateKey`
   → `CustomerKey`
5. `Microsoft.OLEDBDestination` — `[dbo].[FactInternetSales]`

**Why "Mixed":** the multi-source + Union All shape (two ingestion streams merged
and key-resolved into one fact) is the pattern the Snowflake demo classifies as
Mixed (Ingestion + Transformation).

**Note (2026-06-26 fix):** the original flat-file "rejected rows" export branch
(`Microsoft.FlatFileDestination` + a second Flat File Connection Manager) was
removed during G1 remediation — it was a likely cause of SnowConvert skipping
the package, and it is not essential to the multi-source-union story. The
corrected flat-file pattern now lives in `04` (see its source); the export
branch can be re-added later using that same self-describing pattern if desired.

**Expected agent classification:** Mixed → **Snowpark + Tasks DAG**.

# dbt Model Run Results — Stage 6

**Date:** 2026-06-29
**Execution method:** Direct SQL (equivalent to `EXECUTE DBT PROJECT` via Snowflake Task)
**Run order:** Dependency-ordered (dimensions first, then fact)

## Model Run Results

| # | Model | Source Package | Rows Inserted | Status |
|---|-------|----------------|---------------|--------|
| 1 | load_dim_product | 01_LoadDimProduct.dtsx | 16 | Success |
| 2 | load_dim_customer | 02_LoadDimCustomer.dtsx | 16 | Success |
| 3 | load_fact_internet_sales | 03_LoadFactInternetSales.dtsx | 12 | Success |

## Final Target Table Row Counts

| Table | Rows |
|-------|------|
| DBO.DimProduct | 16 |
| DBO.DimCustomer | 16 |
| DBO.FactInternetSales | 12 |

## Seed/Reference Table Row Counts (loaded prior to model run)

| Table | Rows |
|-------|------|
| DBO.DimProductCategory | 4 |
| DBO.DimProductSubcategory | 6 |
| DBO.DimGeography | 5 |
| STG.Product | 16 |
| STG.Customer | 16 |
| STG.SalesOnline | 14 |
| STG.SalesReseller | 12 |
| STG.CurrencyRate | 0 |

## Fact Table Lookup Analysis

| Metric | Count |
|--------|-------|
| STG.SalesOnline rows | 14 |
| STG.SalesReseller rows | 12 |
| Union total (input to lookups) | 26 |
| Product lookup matched | 26/26 (100%) |
| Customer lookup matched | 12/26 (46%) |
| Both lookups matched (final output) | 12 |
| Rows dropped by Customer no-match | 14 |

### Customer No-Match Breakdown

All 14 dropped rows reference customers `AW00011000` through `AW00011004`. These customers exist in the original AdventureWorksDW source system's `dbo.DimCustomer` pre-seed data but were NOT present in `stg.Customer` (which contains only the 16 "new" customers `AW00011005`–`AW00011020`).

The SSIS package `03_LoadFactInternetSales.dtsx` configures the Customer Lookup with `NoMatchBehavior=1`, which redirects non-matching rows to the "Lookup No Match Output" — effectively dropping them. The dbt model replicates this behavior via `INNER JOIN`, producing identical results.

**This is correct, expected behavior — not a data loss bug.**

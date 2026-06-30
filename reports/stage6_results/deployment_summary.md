# Deployment Summary — Stage 6

**Date:** 2026-06-29
**Target:** SSIS_MIGRATION_POC (Snowflake)
**Schemas created:** DBO, STG

## Dependency-Wave Deployment Order

All 11 tables deployed in a single wave, ordered by topological rank to satisfy foreign key constraints.

| Rank | Schema | Table | FK References | Creation Status |
|------|--------|-------|---------------|-----------------|
| 1 | DBO | DimProductCategory | — | Table DIMPRODUCTCATEGORY successfully created. |
| 1 | DBO | DimGeography | — | Table DIMGEOGRAPHY successfully created. |
| 1 | STG | Product | — | Table PRODUCT successfully created. |
| 1 | STG | Customer | — | Table CUSTOMER successfully created. |
| 1 | STG | SalesOnline | — | Table SALESONLINE successfully created. |
| 1 | STG | SalesReseller | — | Table SALESRESELLER successfully created. |
| 1 | STG | CurrencyRate | — | Table CURRENCYRATE successfully created. |
| 2 | DBO | DimProductSubcategory | → DimProductCategory(ProductCategoryKey) | Table DIMPRODUCTSUBCATEGORY successfully created. |
| 2 | DBO | DimCustomer | → DimGeography(GeographyKey) | Table DIMCUSTOMER successfully created. |
| 3 | DBO | DimProduct | → DimProductSubcategory(ProductSubcategoryKey) | Table DIMPRODUCT successfully created. |
| 4 | DBO | FactInternetSales | → DimProduct(ProductKey), DimCustomer(CustomerKey) | Table FACTINTERNETSALES successfully created. |

## Post-Deployment Confirmation

Query against `INFORMATION_SCHEMA.TABLES` returned 11 rows:

| TABLE_SCHEMA | TABLE_NAME | CREATED |
|---|---|---|
| DBO | DIMCUSTOMER | 2026-06-29 04:41:30.789 -0700 |
| DBO | DIMGEOGRAPHY | 2026-06-29 04:40:49.409 -0700 |
| DBO | DIMPRODUCT | 2026-06-29 04:41:46.854 -0700 |
| DBO | DIMPRODUCTCATEGORY | 2026-06-29 04:40:49.450 -0700 |
| DBO | DIMPRODUCTSUBCATEGORY | 2026-06-29 04:41:30.790 -0700 |
| DBO | FACTINTERNETSALES | 2026-06-29 04:42:05.101 -0700 |
| STG | CURRENCYRATE | 2026-06-29 04:40:49.018 -0700 |
| STG | CUSTOMER | 2026-06-29 04:40:49.394 -0700 |
| STG | PRODUCT | 2026-06-29 04:40:49.374 -0700 |
| STG | SALESONLINE | 2026-06-29 04:40:49.634 -0700 |
| STG | SALESRESELLER | 2026-06-29 04:40:49.811 -0700 |

## Alterations Applied During Session

| Table | Column | Change | Reason |
|-------|--------|--------|--------|
| STG.Customer | MaritalStatus | NVARCHAR(2) → NVARCHAR(10) | Source data contains dirty values ("Married", "Single") that the SSIS Data Conversion transform is designed to clean |
| DBO.DimProduct | Status | NVARCHAR(7) → NVARCHAR(10) | Derived Column transform outputs "Outdated" (8 chars) which exceeds original column width |

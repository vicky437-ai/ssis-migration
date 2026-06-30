# Validation Results — Stage 6

**Date:** 2026-06-29
**Overall Result: 17/17 checks PASS. 0 failures. 0 unexpected differences.**

---

## 1. Row-Count Validation

| Data Flow | Source Rows | Target Rows | Difference | Verdict |
|-----------|-------------|-------------|------------|---------|
| STG.Product → DBO.DimProduct | 16 | 16 | 0 | **PASS** |
| STG.Customer → DBO.DimCustomer | 16 | 16 | 0 | **PASS** |
| STG.SalesOnline + STG.SalesReseller → DBO.FactInternetSales | 26 | 12 | 14 | **EXPECTED** |

> **FactInternetSales 12/26 is EXPECTED behavior, not a failure.**
> The SSIS package `03_LoadFactInternetSales.dtsx` configures `NoMatchBehavior=1` on the Customer Lookup component, which redirects non-matching rows to the "Lookup No Match Output" (drops them). All 14 dropped rows reference customers `AW00011000`–`AW00011004` which are not present in the `stg.Customer` staging data and therefore not in `DBO.DimCustomer`. The `INNER JOIN` in the dbt model faithfully replicates this SSIS lookup drop behavior.

---

## 2. DimProduct Data Validation (5 checks)

| # | Check | Expected | Actual | Verdict |
|---|-------|----------|--------|---------|
| 1 | NULL Status values in target | 0 | 0 | **PASS** |
| 2 | "Outdated" count in target | 3 | 3 | **PASS** |
| 3 | NULL Status count in source (should match "Outdated" count) | 3 | 3 | **PASS** |
| 4 | Orphan SubcategoryKeys in target (FK integrity) | 0 | 0 | **PASS** |
| 5 | StandardCost sum difference (source vs target) | 0 | 0 | **PASS** |

**Derived Column transform verified:** 3 source rows with `Status IS NULL` correctly converted to `'Outdated'` via `COALESCE(Status, 'Outdated')`.

---

## 3. DimCustomer Data Validation (6 checks)

| # | Check | Expected | Actual | Verdict |
|---|-------|----------|--------|---------|
| 1 | MaritalStatus all 1-char (no violations) | 0 | 0 | **PASS** |
| 2 | Gender all 1-char (no violations) | 0 | 0 | **PASS** |
| 3 | MaritalStatus only M/S (no violations) | 0 | 0 | **PASS** |
| 4 | Gender only M/F (no violations) | 0 | 0 | **PASS** |
| 5 | FullName = FirstName + ' ' + LastName (no mismatches) | 0 | 0 | **PASS** |
| 6 | YearlyIncome sum difference (source vs target) | 0 | 0 | **PASS** |

**Data Conversion transform verified:**
- "Married" → "M", "Single" → "S" (MaritalStatus truncation)
- "Male" → "M", "Female" → "F" (Gender truncation)
- Values already 1-char ("M", "S", "F") pass through unchanged

**Derived Column transform verified:** `FirstName || ' ' || LastName` matches `FullName` for all 16 rows.

---

## 4. FactInternetSales Data Validation (6 checks)

| # | Check | Expected | Actual | Verdict |
|---|-------|----------|--------|---------|
| 1 | Orphan ProductKey (FK integrity) | 0 | 0 | **PASS** |
| 2 | Orphan CustomerKey (FK integrity) | 0 | 0 | **PASS** |
| 3 | OrderDateKey derivation errors (YYYYMMDD from OrderDate) | 0 | 0 | **PASS** |
| 4 | NULL OrderDateKey | 0 | 0 | **PASS** |
| 5 | SalesAmount sum difference (target vs matched source) | 0 | 0 | **PASS** |
| 6 | Dropped rows all from unmatched CustomerAlternateKey | 14 | 14 | **PASS** |

**Lookup Product transform verified:** All 26 union rows resolve a valid ProductKey via `ProductAlternateKey` join to `DBO.DimProduct`.

**Lookup Customer transform verified:** 12 rows resolve a valid CustomerKey; 14 rows correctly dropped due to `CustomerAlternateKey` not found in `DBO.DimCustomer` (NoMatchBehavior=1 equivalent).

**OrderDateKey derivation verified:** `CAST(TO_CHAR(OrderDate, 'YYYYMMDD') AS INT)` produces correct integer date keys with zero errors.

---

## Summary

| Model | Checks Run | Passed | Failed | Unexpected |
|-------|-----------|--------|--------|------------|
| DimProduct | 5 | 5 | 0 | 0 |
| DimCustomer | 6 | 6 | 0 | 0 |
| FactInternetSales | 6 | 6 | 0 | 0 |
| **Total** | **17** | **17** | **0** | **0** |

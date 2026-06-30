# SSIS → Snowflake Migration POC — Results Summary

**Date:** 2026-06-29
**Source artifacts:** verified against `reports/converted/` and `reports/stage6_results/`.

This is a factual record of what ran. Numbers are taken directly from the
preserved run artifacts, not estimated.

## Flow completed

Full migration flow ran end-to-end:

assess → convert → AI remediation → deploy → migrate → run → validate

- **Cockpit:** Claude Code (with the `snowflake-cortex-code` plugin) as the single
  window.
- **Migration engine:** Cortex Code's SnowConvert-based migration skill performed
  the deterministic conversion; AI remediation generated the dbt model bodies
  around it.
- **Target:** Snowflake sandbox `SSIS_MIGRATION_POC.DEMO` (account `<snowflake-account>`).

## Conversion

| Item | Result |
|------|--------|
| SQL DDL objects converted | 11 / 11 (100%), 0 conversion errors |
| SSIS packages converted to dbt | 3 (via deterministic SnowConvert + AI remediation) |
| Packages deferred | 1 (`04_StageCurrencyRates`, flat-file pure-ingest, did not register) |

The 3 converted packages:

| Package | dbt model | Pattern |
|---------|-----------|---------|
| 01_LoadDimProduct | `load_dim_product` | source → lookup → derived column → load |
| 02_LoadDimCustomer | `load_dim_customer` | source → data conversion → derived column → load |
| 03_LoadFactInternetSales | `load_fact_internet_sales` | 2 sources → union → 2 lookups → load |

## Deployment & run

| Item | Result |
|------|--------|
| Tables deployed to sandbox | 11 / 11 |
| dbt models run | 3 / 3 succeeded |
| Rows loaded — DimProduct | 16 |
| Rows loaded — DimCustomer | 16 |
| Rows loaded — FactInternetSales | 12 |

## Validation

**17 / 17 validation checks passed. 0 failures.**

| Model | Checks | Passed |
|-------|--------|--------|
| DimProduct | 5 | 5 |
| DimCustomer | 6 | 6 |
| FactInternetSales | 6 | 6 |

Row-count validation:

| Data flow | Source | Target | Difference | Verdict |
|-----------|--------|--------|------------|---------|
| stg.Product → DimProduct | 16 | 16 | 0 | match |
| stg.Customer → DimCustomer | 16 | 16 | 0 | match |
| stg.SalesOnline + stg.SalesReseller → FactInternetSales | 26 | 12 | 14 | expected (see below) |

## Lookup-fidelity highlight — FactInternetSales

FactInternetSales loaded **12 of 26** source rows. This is correct, not a data loss.

- The SSIS package `03_LoadFactInternetSales.dtsx` sets `NoMatchBehavior=1` on the
  Customer Lookup, which drops rows whose `CustomerAlternateKey` has no match.
- The dbt model replicates this with an `INNER JOIN`, producing identical results.
- All **14 dropped rows** reference customers `AW00011000`–`AW00011004`, which are
  not present in `stg.Customer` and therefore not in `DimCustomer`. Every dropped
  row is accounted for (validation check: 14 expected, 14 actual).

The converted pipeline preserved the source SSIS lookup behavior exactly.

## Scope notes (stated plainly)

- Result is **3 of 4** packages migrated end-to-end. `04_StageCurrencyRates` is
  deferred (flat-file pure-ingest did not register at assessment; remediation
  options recorded in `RUNBOOK.md`).
- FactInternetSales is **12/26 by design** (lookup no-match), not a full 26/26.
- Source `.dtsx` packages are synthetic, authored against the real AdventureWorksDW
  schema (see `CLAUDE.md` and `source_ssis/README.md`).

## Source artifacts

- `reports/stage6_results/deployment_summary.md` — 11/11 tables deployed
- `reports/stage6_results/dbt_run_results.md` — 3/3 models run
- `reports/stage6_results/validation_results.md` — 17/17 checks
- `reports/stage6_results/dbt/` — the 3 generated dbt projects
- `reports/converted/` — deterministic SnowConvert output (Task defs + 11 DDLs)

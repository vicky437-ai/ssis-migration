# source_ssis/ — Synthetic SSIS Packages (AdventureWorksDW schema)

These `.dtsx` packages are **authored** (not exported from Visual Studio) and
are built against the **real AdventureWorksDW** schema so the source is
authentic and recognizable. See CLAUDE.md for the rationale and the known
parsing risk (Gate G1 in the runbook).

## Planned package set (mirrors the Snowflake demo's classification spread)

The Snowflake demo (reference images 8–9) classified SSIS packages into:
Data Transformation → dbt models, Mixed (Ingestion + Transformation) →
Snowpark + Tasks DAG, and pure Ingestion. To reproduce that spread:

| Package                         | Pattern                                   | Expected classification        |
|---------------------------------|-------------------------------------------|--------------------------------|
| `01_LoadDimProduct.dtsx`        | Flat file → Lookup → Derived Column → load | Data Transformation → dbt model |
| `02_LoadDimCustomer.dtsx`       | OLE DB source → Data Conversion → load     | Data Transformation → dbt model |
| `03_LoadFactInternetSales.dtsx` | Multi-source + Lookup + UnionAll + export  | Mixed → Snowpark + Tasks DAG    |
| `04_StageCurrencyRates.dtsx`    | Flat file ingest → staging                 | Ingestion                       |

> NOTE: these files are to be GENERATED in a Claude Code session against this
> project (so they're written straight to disk). This README is the spec.
> Generating them here in chat is possible but the point of the local setup is
> that authoring happens with full filesystem context.

## After authoring, before recording

1. Validate each parses as well-formed XML locally.
2. Run Gate G1 (agent assessment) — the real test of whether SnowConvert
   accepts them.
3. Only packages that pass G1 belong in the recorded demo.

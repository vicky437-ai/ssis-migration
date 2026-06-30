This is a live screen recording, under 90 seconds. Work in two parts: first show the agent's completed migration work, then prove the result live. Be concise and visual — let output land, minimal chatter. Do NOT re-run conversion, deployment, or data migration.

PART 1 — Agent migration flow (recall completed state, ~25s)

Step 1 — One line: "SSIS → Snowflake migration, driven end-to-end through Cortex Code."

Step 2 — Show the migration flow as a checklist with status ticks:
  [x] Connect/Import  — local .dtsx + T-SQL DDL (no live source)
  [x] Register        — 14 objects (11 tables + 3 ETL packages)
  [x] Convert         — SnowConvert, 0 errors
  [x] Assess          — dependency waves + SSIS classification
  [x] Deploy          — 11 tables to SSIS_MIGRATION_POC
  [x] Migrate data    — seed loaded, row counts validated
  [x] Run dbt         — 3 models, dependency order
  [x] Validate        — 17/17 checks passed

Step 3 — Show the SSIS package assessment classification briefly:
  01_LoadDimProduct       → Snowflake Task + dbt (Transformation)
  02_LoadDimCustomer      → Snowflake Task + dbt (Transformation)
  03_LoadFactInternetSales→ Snowflake Task + dbt (Mixed: union + lookups)
  (note: deterministic SnowConvert conversion + AI remediation produced the dbt model bodies)

PART 2 — Live proof against Snowflake (~45s)

Step 4 — Run live: SHOW TABLES IN SCHEMA SSIS_MIGRATION_POC.DBO;
(show the migrated tables exist)

Step 5 — Run live row counts (use ROW_COUNT as the alias, NOT "rows" — it is a reserved word):
SELECT 'DimProduct' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM SSIS_MIGRATION_POC.DBO.DimProduct
UNION ALL SELECT 'DimCustomer', COUNT(*) FROM SSIS_MIGRATION_POC.DBO.DimCustomer
UNION ALL SELECT 'FactInternetSales', COUNT(*) FROM SSIS_MIGRATION_POC.DBO.FactInternetSales;

Step 6 — Run the lookup-fidelity proof live:
SELECT
  (SELECT COUNT(*) FROM SSIS_MIGRATION_POC.STG.SalesOnline) +
  (SELECT COUNT(*) FROM SSIS_MIGRATION_POC.STG.SalesReseller) AS UNION_SOURCE_ROWS,
  (SELECT COUNT(*) FROM SSIS_MIGRATION_POC.DBO.FactInternetSales) AS LOADED_FACT_ROWS;

Step 7 — Closing line: "26 source rows → 12 loaded, by design. The migration preserved the SSIS Customer lookup's no-match behavior — real referential integrity, validated 17/17. 3 of 4 packages; one deferred."

Run each query for real. Keep narration between steps to one short line.

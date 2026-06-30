# VIDEO_SHOTLIST — 90-second LinkedIn demo

**Format:** live screen recording, one take of the queries (unedited).
**Connection:** default is now `ssis_poc` (trial account `<snowflake-account>`) — prompts
auto-route there, no `-c` flag needed. Confirm this off-camera before recording.
**Pre-flight (do OFF camera):** run all 4 queries once to warm `POC_WH` and confirm
the live numbers still read 11 tables / 16 / 16 / 12 / (26 → 12). If they don't,
stop — the sandbox drifted since 2026-06-29 and the narration won't match.

---

## Timed shot list

### Shot 1 — Title / intent  (0:00–0:10)
**On screen:** Claude Code open in the project root. Type the one-liner as a comment
or just say it.
**Narration (≈8s):**
> "This is an SSIS-to-Snowflake migration — end to end, from one terminal.
> Let's verify it live against the trial account."

---

### Shot 2 — The flow  (0:10–0:25)
**On screen:** the 8-step checklist, all ticked.
```
Connect/Import ✅  Register ✅  Convert ✅  Assess ✅
Deploy ✅  Migrate data ✅  Run dbt ✅  Validate ✅
```
**Narration (≈13s):**
> "Claude Code is the cockpit. Cortex Code's SnowConvert did the deterministic
> conversion; AI handled the remediation that generated the dbt models.
> Now — does the data actually exist in Snowflake?"

---

### Shot 3 — Objects exist  (0:25–0:40)
**Query (run live):**
```sql
SHOW TABLES IN SCHEMA SSIS_MIGRATION_POC.DBO;
```
**Wait for output. Don't talk over the returning rows.**
**Narration after results land (≈6s):**
> "There they are — the migrated dimension and fact tables, deployed to the
> sandbox schema."

---

### Shot 4 — Row counts  (0:40–0:58)
**Query (run live):**
```sql
SELECT 'DimProduct' AS table_name, COUNT(*) AS row_count FROM SSIS_MIGRATION_POC.DBO.DimProduct
UNION ALL SELECT 'DimCustomer', COUNT(*) FROM SSIS_MIGRATION_POC.DBO.DimCustomer
UNION ALL SELECT 'FactInternetSales', COUNT(*) FROM SSIS_MIGRATION_POC.DBO.FactInternetSales;
```
**Expected:** 16 / 16 / 12.
**Narration after results land (≈10s):**
> "Product and Customer dimensions: sixteen rows each, fully loaded.
> Internet Sales fact: twelve rows. Hold on — the source had twenty-six.
> That gap is the interesting part."

---

### Shot 5 — Lookup fidelity  (0:58–1:18)
**Query (run live):**
```sql
SELECT
  (SELECT COUNT(*) FROM SSIS_MIGRATION_POC.STG.SalesOnline) +
  (SELECT COUNT(*) FROM SSIS_MIGRATION_POC.STG.SalesReseller) AS union_source_rows,
  (SELECT COUNT(*) FROM SSIS_MIGRATION_POC.DBO.FactInternetSales) AS loaded_fact_rows;
```
**Expected:** `union_source_rows = 26`, `loaded_fact_rows = 12`.
**Narration after results land (≈16s):**
> "Twenty-six source rows in; twelve loaded. The fourteen dropped rows aren't a
> bug — the original SSIS package drops sales whose customer isn't found in the
> dimension. The migration preserved that exact no-match behavior as an INNER
> JOIN, and validation accounted for all fourteen."

---

### Shot 6 — Close  (1:18–1:30)
**On screen:** the validation line — `17/17 checks passed` (from
`reports/stage6_results/validation_results.md`).
**Narration (≈10s):**
> "Seventeen of seventeen validation checks passed. It preserved real referential
> integrity instead of forcing a false twenty-six-out-of-twenty-six.
> Honest migration beats a clean-looking demo."

---

## Caption variants (pick one)

### A — Engineer / proof-first
> Migrated SSIS → Snowflake end-to-end from a single terminal. Claude Code as the
> cockpit; Cortex Code's SnowConvert did the deterministic conversion, AI did the
> remediation that produced the dbt models. 11/11 tables, 3 packages → dbt, 17/17
> validation checks — all verified live in the video. The detail I like most:
> FactInternetSales loaded 12 of 26 rows *by design*, preserving the SSIS Customer
> lookup's no-match behavior. Honest migration > a clean-looking demo.

### B — Short / hook-first
> Most migration demos show a fake 100%. This one shows 12 of 26 rows loaded — on
> purpose. The SSIS → Snowflake conversion preserved the source lookup's no-match
> behavior, and validation accounted for every dropped row. 11/11 tables, 17/17
> checks, verified live. Claude Code cockpit + Cortex Code SnowConvert + AI
> remediation.

### C — Story / lesson-first
> I migrated an SSIS pipeline to Snowflake and the fact table came out 12 of 26
> rows. That's not data loss — it's fidelity. The original package dropped sales
> with no matching customer; the converted dbt model did the same via INNER JOIN,
> and the validation caught all 14 drops as expected. Deterministic SnowConvert +
> AI remediation, driven from Claude Code as a single cockpit. The honest result
> is the credible one.

---

## Reminders
- Big font, dark theme, ~110 cols — most views are mobile.
- Don't `cat` any config/connection file on camera (token lives in `config.toml`).
- Keep "3 of 4 packages" honest — `04_StageCurrencyRates` is deferred; don't imply all four.
- Total spoken words ≈ 110–130 → comfortably under 90s at a normal pace.

---

## Related collateral (cross-reference)

- `../LINKEDIN_AND_VIDEO_PLAN.md` (project root) — the LinkedIn writeup skeleton
  (hook / what-I-built / honest-part / CTA) and the **longer two 2-minute video
  plan** (Video A: single-window cockpit; Video B: convert/deploy/validate).
  Use that for a deeper-dive post; use **this file** for the tight 90-second
  live-proof cut.
- `RESULTS_SUMMARY.md` — the verified factual numbers behind the narration.
- `DEMO_RUN.md` — the live query script this shotlist is timed to.
- `../reports/stage6_results/validation_results.md` — source of the 17/17 close.

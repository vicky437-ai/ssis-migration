# RUNBOOK — SSIS → Snowflake Migration POC

Production-grade, gated execution. Each **GATE** must pass before proceeding.
Nothing gets recorded for the customer demo until Gate G1 passes for real.

Reference demo: https://www.snowflake.com/en/blog/engineering/snowflake-aim-migration-agent/
Official skill docs: https://docs.snowflake.com/en/migrations/migration-skill/skill

---

## PHASE 0 — Preconditions (one-time, no recording)

0.1  Confirm tooling is alive (run in a normal terminal):
```bash
claude --version
cortex --version
snow connection list
```
0.2  Confirm the plugin is enabled in Claude Code:
```
/plugin list --enabled        # expect snowflake-cortex-code@snowflake-ai-kit
```
0.3  Pick/confirm a SANDBOX Snowflake target.
     - Create a throwaway database + schema for this POC.
     - Confirm the connection's role can ONLY touch that sandbox.
     - Record the names here:  DB = __________  SCHEMA = __________  ROLE = ______

0.4  Place this project at `~/Projects/ssis-migration-poc/` and launch:
```bash
cd ~/Projects/ssis-migration-poc
claude          # Claude Code reads CLAUDE.md automatically
```

**GATE G0:** all three tools respond; plugin enabled; sandbox confirmed; role scoped.
If any fail → stop, fix, do not proceed.

---

## PHASE 1 — Source artifacts ready

1.1  Confirm `source_ssis/` contains the synthetic `.dtsx` packages + a README
     describing each package and its intended classification.
1.2  Confirm `sql/` contains the AdventureWorksDW DDL needed to stand up the
     source tables the packages reference (so assessment + run have real schema).

**GATE G1 — THE CRITICAL ONE (must pass before any recording):**
Launch the agent and run ONLY assessment against the packages:
```bash
cortex                         # from project root
> start a database migration; source is SQL Server with SSIS packages in ./source_ssis
```
- The agent must parse every `.dtsx` without error.
- It must produce a workload inventory + SSIS classification report.
- Open the generated HTML report under `reports/`.

PASS  = all packages parsed, classified, no parser exceptions.
FAIL  = any package rejected / unparsed.
  → If FAIL: this is the known synthetic-`.dtsx` risk. Remediation options,
    in order of preference:
    (a) regenerate the failing package with stricter VS-style structure,
    (b) substitute Microsoft's official tutorial package for that slot,
    (c) reduce scope to the package types that do parse, and adjust the
        demo narrative honestly to match.
  → DO NOT proceed to recording with a partial/forced pass.

### G1 RESULT — 2026-06-26: PARTIAL PASS (3/4 packages), proceeding with 3/4

Assessment-only run completed. Outcome:

- **Registered + converted (SSIS → Snowflake Task → dbt):**
  - `01_LoadDimProduct`
  - `02_LoadDimCustomer`
  - `03_LoadFactInternetSales`
- **Did NOT register — deferred:** `04_StageCurrencyRates` (flat-file pure-ingest).

**SQL DDL conversion:** 11/11 objects converted (100%), 0 conversion errors.

**Assessment findings (all expected):**
- 14 ETL EWIs — `SSC-EWI-SSIS0009` (data-flow transforms need AI remediation; expected).
- 11 FDMs — `SSC-FDM-0019` (MONEY → NUMBER; expected).

**Conversion state — deterministic skeleton done, AI remediation pending:**
The **deterministic** conversion is complete and preserved in `reports/converted/`:
Snowflake Task definitions, the 11 table DDLs, and ETL scaffolding. The **dbt
model bodies are NOT yet generated** — they require the AI remediation step
(Stage 6), deferred to a fresh-credit session.
- ⚠️ **Demo narration must reflect this:** deterministic skeleton done, AI
  remediation pending. Do NOT imply the dbt models are complete.

**Decision:** Accept the partial pass. Proceed to Phase 2 (conversion review) /
Phase 3 (deploy) on a fresh credit budget with the 3 registered packages.

**`04` remediation options (deferred, not blocking):**
- (a) substitute Microsoft's official tutorial flat-file package for this slot, or
- (b) retry the flat-file external-metadata (EMC) fix on the synthetic package later.

---

## PHASE 2 — Assessment (the "wow" screen from the demo)

2.1  Have the agent generate the full multi-tab assessment report
     (workload inventory, dependencies, dynamic SQL, SSIS report, wave plan).
2.2  Compare against `reports/expected/` to sanity-check shape vs the Snowflake
     demo (images 8–9: total objects, tables, views, ETLs, classification table).

**GATE G2:** assessment report opens, is coherent, and the SSIS classification
maps packages to dbt models / Snowpark / Tasks DAG as in the reference demo.

---

## PHASE 3 — Convert SSIS → dbt

3.1  Instruct the agent to convert the registered packages to dbt.
3.2  Inspect the generated dbt project (models, sources, tests).
3.3  Capture any AI remediations the agent applied; note which became reusable
     rules (this is a strong talking point — the rule-propagation story).

**GATE G3:** dbt project generated; models readable; conversion report clean.

---

## PHASE 4 — Deploy + run + validate (sandbox)

4.1  Deploy the converted dbt project to the sandbox DB/schema.
4.2  Run it; let the agent's two-sided / row-count validation execute.
4.3  Record the pass/fail numbers honestly (the demo's own report carried an
     AI-generated disclaimer and showed non-code test failures — realism is fine,
     and arguably more credible than a fake 100%).

**GATE G4:** target objects exist in sandbox; validation numbers captured.

### STAGE 6 — FINAL RESULT — 2026-06-29: COMPLETE (3/4 packages end-to-end)

**3 of 4 packages fully migrated end-to-end: SSIS → dbt → deployed → run → validated.**
`04_StageCurrencyRates` remains deferred (see G1 result above).

**Stage gates PASSED — 2026-06-29** (A1/A2/B1/C1/D1/E1 are the Stage-6 sub-gate
labels; mapped here to this RUNBOOK's native G-gates):

| Gate | Meaning | Maps to | Status |
|------|---------|---------|--------|
| A1 | SSIS packages parse / assess | G1 | ✅ PASSED |
| A2 | Assessment report + classification | G2 | ✅ PASSED |
| B1 | dbt conversion generated (AI remediation) | G3 | ✅ PASSED |
| C1 | Deploy to sandbox | G4 (deploy) | ✅ PASSED |
| D1 | dbt run / load | G4 (run) | ✅ PASSED |
| E1 | Two-sided / row-count validation | G4 (validate) | ✅ PASSED |

**Outcome (artifacts preserved in `reports/stage6_results/`):**
- **Deployment:** 11/11 tables deployed (`deployment_summary.md`).
- **dbt run:** 3/3 models succeeded (`dbt_run_results.md`).
- **Validation:** 17/17 checks passed, 0 failures (`validation_results.md`):
  - DimProduct — 16/16 rows
  - DimCustomer — 16/16 rows
  - FactInternetSales — 12/26 rows; **14 rows correctly dropped** by the Customer
    Lookup no-match behavior (`NoMatchBehavior=1` → INNER JOIN), fully accounted for.

**Deferred:** `04_StageCurrencyRates` (flat-file pure-ingest, did not register at G1).

> Accuracy note: numbers above were verified against the three artifact files in
> `reports/stage6_results/` on 2026-06-29 before being recorded here.

---

## PHASE 5 — Demo collateral (see demo_script/)

5.1  Write the LinkedIn writeup (demo_script/LINKEDIN_WRITEUP.md).
5.2  Finalize the architecture + process diagrams (docs/).
5.3  Record the two 2-minute videos per demo_script/VIDEO_SHOTLIST.md.

**GATE G5:** collateral reviewed for accuracy against what actually ran.
No claim in the writeup/video that wasn't demonstrated live.

---

## Accuracy guardrails (because this is customer-facing)

- "Claude Code as cockpit, Cortex Code runs the agent" — never "Claude Code
  migrated it."
- "Deterministic SnowConvert + AI remediation" — never "AI converted it."
- Show the real assessment disclaimer; don't hide AI-generated caveats.
- If something needed a manual fix, say so — that's the honest migration story
  and customers respect it more than a too-clean demo.

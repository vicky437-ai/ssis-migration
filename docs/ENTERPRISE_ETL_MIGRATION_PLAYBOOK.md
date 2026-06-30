# Enterprise ETL-Modernization Playbook
## SSIS / Informatica → dbt on Snowflake, via the Snowflake Migration Agent in Cortex Code (CoCo)

**Audience:** Snowflake Solutions Architects running ETL-modernization engagements.
**Purpose (one document, three uses):** (1) a repeatable methodology/playbook, (2) source material to adapt into a customer-facing proposal, (3) an internal execution runbook for the delivery team.
**Last updated:** 2026-06-30.

> **Scope of this practice — read first.**
> - **Source system: SQL Server only.** This playbook covers SQL Server as the source RDBMS. Oracle, Teradata, Redshift, MySQL and other engines exist in Snowflake's broader migration matrix but are **out of scope** for this practice and are not addressed here.
> - **Focus: ETL pipeline modernization** — **SSIS and Informatica workflows converted to dbt**, with the **embedded SQL logic converted via SnowConvert for the SQL Server source dialect.** The ETL conversion and the embedded-SQL dialect conversion are **linked, not separable**: SSIS/Informatica packages carry embedded T-SQL (source queries, lookups, expressions) and depend on source/target DDL, all of which must convert correctly for the pipeline to work. An ETL engagement is therefore *not* a "SQL layer is irrelevant" engagement.

> **Framing rules held throughout this document (do not drift from these):**
> - **Claude Code is the *optional* cockpit.** It is a convenience layer that routes natural-language prompts to CoCo. It is not required, and it does not perform the migration.
> - **Cortex Code (CoCo) runs the migration agent.** The agent and its skills live in CoCo.
> - **SnowConvert does the deterministic conversion first; AI remediates around it.** This is "AI-assisted, not AI-magic." Deterministic output is predictable and reviewable; AI fills the gaps (e.g., generating dbt model bodies, remediating edge cases) under SA review.

---

## 1. Executive Summary

This methodology modernizes **SQL Server-centric ETL estates** — SSIS packages and Informatica mappings/workflows — into **dbt projects running on Snowflake**, using the **Snowflake Migration Agent inside Cortex Code (CoCo)**. The embedded SQL logic (source queries, lookup SQL, expressions, and the source/target DDL) is converted by **SnowConvert** for the SQL Server dialect, so the pipeline and its SQL move together.

The core engineering principle is a **two-stage conversion**:

1. **Deterministic conversion (SnowConvert).** Produces predictable, reviewable output: converted DDL, Snowflake Task definitions, and dbt/ETL *scaffolding*. This step is rule-based and repeatable — the same input yields the same output.
2. **AI-assisted remediation.** Fills what determinism cannot: generating the **dbt model bodies** that implement each package's data-flow semantics, remediating flagged edge cases (EWIs/FDMs), and — at scale — propagating a fix across many similar packages via the **rule engine**.

The honest positioning to customers is **"AI-assisted, not AI-magic."** The deterministic step is auditable; the AI step is bounded and reviewed by the SA. What the tooling removes is **coordination overhead** — sequencing, conversion mechanics, test generation. What it does **not** remove is **architect judgment**: deciding what "correct" means, validating that converted pipelines preserve real source behavior, and owning cutover risk.

A worked example runs throughout this document (Section 9): a real SSIS-on-AdventureWorksDW migration we executed, with **11/11 tables converted (0 errors), 3 SSIS packages converted to dbt, 17/17 validation checks passed**, and a deliberate **12-of-26-row fact-table result** that demonstrates fidelity to source lookup behavior. Every figure is drawn from preserved run artifacts, never invented.

---

## 2. Engagement Model — Phase Map

From first customer conversation to production cutover:

| Phase | Name | Owner | Outcome |
|-------|------|-------|---------|
| 1 | Discovery & Assessment (pre-tooling) | SA | Qualified scope, inventory, effort/cost shape |
| 2 | Prerequisites & Environment Setup | SA + customer infra | Connectivity, accounts, RBAC, toolchain ready |
| 3 | Six-Stage Execution (the agent workflow) | SA-driven, agent-executed | Converted, assessed, migrated objects + dbt |
| 4 | Enterprise Concerns at Scale | SA + delivery team | Wave plan, validation, cost, cutover design |
| 5 | Cutover & Handover | SA + customer team | Production cutover, validation, knowledge transfer |

Phases 1–2 are **SA-owned and largely outside the tooling** — they are where engagements succeed or fail. Phase 3 is the agent workflow. Phases 4–5 are enterprise delivery discipline layered on top.

---

## 3. Phase 1 — Discovery & Assessment (PRE-tooling)

This phase is **not in the Snowflake documentation** and is the SA's first and most important job. The agent can assess *code* once it has it; only the SA can assess the *engagement*. Do this before any tool touches anything.

### 3.1 What you are trying to learn
- The true **size and complexity** of the ETL estate (not the customer's optimistic estimate).
- Which pipelines are **business-critical** vs. dormant.
- The **embedded-SQL complexity** that will drive SnowConvert effort.
- **Downstream consumers** that constrain cutover.
- **Security, compliance, and network** constraints that gate connectivity.

### 3.2 Discovery questionnaire / checklist

**A. Source SQL Server estate**
- [ ] SQL Server version(s) and edition (2012 / 2014 / 2016 / 2019 / 2022)? Compatibility level?
- [ ] Number of source databases; total data volume (GB/TB) per database.
- [ ] Largest tables by row count and by size; growth rate.
- [ ] Use of SQL Server-specific features in embedded logic: stored procedures, functions, MERGE, dynamic SQL, CLR, linked servers, temporal tables.
- [ ] Collation(s) and any non-Unicode (`VARCHAR`/`CHAR`) columns requiring conversion.

**B. SSIS inventory**
- [ ] Total **package count** (`.dtsx`) and where they live (file system, SSISDB catalog, source control).
- [ ] Per-package **complexity tier** (rough): simple ingest, single transform, multi-source/union/lookup, script-task/expression-heavy.
- [ ] Use of **Script Tasks / Script Components** (C#/VB) — these are *not* deterministically convertible and need redesign.
- [ ] Package **configurations / parameters / project params / environment variables**.
- [ ] **Event handlers, checkpoints, transactions** in use.
- [ ] Connection managers: OLE DB, ADO.NET, Flat File, Excel, FTP, etc.

**C. Informatica inventory** *(if in scope for the engagement)*
- [ ] PowerCenter or IICS/Cloud? Version.
- [ ] **Mapping / mapplet / workflow / worklet** counts.
- [ ] Reusable transformations; parameter files; connection objects.
- [ ] Use of Java/expression transformations and stored-procedure transformations.
- [ ] Export format available (XML mapping exports / repository access).

**D. Embedded SQL complexity**
- [ ] Volume of embedded SQL in packages (source queries, lookup SQL, SQL tasks).
- [ ] Stored procedures called by ETL; how many; complexity.
- [ ] T-SQL constructs likely to flag in SnowConvert (e.g., `MONEY`, `DATETIME` semantics, identity columns, `TOP`, proprietary functions).

**E. Data & dependencies**
- [ ] Source data volumes per pipeline; full-load vs incremental.
- [ ] **Package dependency graph** (which packages must run before which) — for wave planning.
- [ ] Scheduling/orchestration today (SQL Agent, Tidal, Control-M, Autosys).
- [ ] Data-quality realities (dirty values, nulls) the ETL currently cleans.

**F. Downstream consumers**
- [ ] BI/reporting tools pointed at the targets (**Power BI**, SSRS, Tableau, Excel).
- [ ] Applications / APIs / extracts reading the warehouse.
- [ ] SLAs and refresh windows that cutover must honor.

**G. Security, compliance, network**
- [ ] Data classification (PII/PHI/PCI), residency/sovereignty requirements.
- [ ] Network path to source SQL Server (on-prem, VPC, hybrid); firewall/VPN.
- [ ] Snowflake network policy / **PrivateLink** requirements.
- [ ] SSO/SCIM, key-pair vs OAuth vs PAT auth posture; secret-management standard.
- [ ] Change-management / approval gates the engagement must pass.

### 3.3 Discovery outputs
- A **package/mapping inventory spreadsheet** with complexity tiers.
- A **first-cut effort shape** (T-shirt sizing) — refined later by the agent's Assess stage.
- A **constraints register** (network, compliance, downstream SLAs).
- A go/no-go recommendation on proceeding to Phase 2.

> The agent's **Assess** stage (Section 5) will produce a far more precise classification and effort estimate from the actual code. Phase 1 is the human-judgment pre-read that scopes the engagement and sets customer expectations honestly.

---

## 4. Phase 2 — Prerequisites & Environment Setup

### 4.1 Snowflake side
- **Account & region** aligned to data-residency requirements.
- **Warehouse sizing strategy:** start at **XS** for conversion/validation work (the agent's SQL is metadata- and small-batch-oriented), and **scale by data volume** for the actual data migration and dbt runs. Use auto-suspend (e.g., 60s) and auto-resume to control credits. Separate warehouses for migration work vs. validation can keep cost attribution clean.
- **Database/schema layout for dbt targets:** mirror the source's logical layout where it aids traceability (e.g., `DBO`, `STG` schemas as in our worked example), or impose a target standard (raw → staging → marts). Decide deliberately and document it.
- **Roles / RBAC:** a dedicated migration role scoped to the sandbox/landing database; least privilege. Do **not** run production migrations as `ACCOUNTADMIN` (see hygiene note below).
- **`SNOWFLAKE.CORTEX_USER` grant:** the agent's AI features call Cortex; the executing role must hold the `SNOWFLAKE.CORTEX_USER` database role (granted from `SNOWFLAKE` shared DB). Without it, AI remediation/inference calls fail. *(Verify the exact grant against current Snowflake docs for your account edition.)*
- **Network policy / PrivateLink:** if the account enforces network policies or PrivateLink, ensure the SA's workstation/egress and any service identities are permitted, or the agent cannot reach the account.

### 4.2 Source side (live SQL Server)
- **Connectivity** from the machine running CoCo to the SQL Server instance (host/port, VPN/PrivateLink as required).
- **ODBC driver** for SQL Server installed and tested.
- **Read permissions** for extraction: the registration role needs to read system catalogs (DDL) and the source data it will migrate.
- **Access to the SSIS/Informatica package files** themselves (file share, SSISDB export, or repository export).
- **Network/firewall** rules opened for the extraction path; document the path for the constraints register.

### 4.3 Toolchain
- **Cortex Code CLI (CoCo)** installed — the migration agent is bundled with it.
- **Optional: Claude Code + the `snowflake-cortex-code` plugin** as a cockpit, if the SA prefers a single natural-language window that auto-routes Snowflake work to CoCo. Optional, not required.
- **`cortexAgentConnectionName` in CoCo's `settings.json` — REAL GOTCHA (we hit this).** This setting governs **which connection the agent's *inference* uses**, and it is **separate from the SQL/source connection**. If it is unset or wrong, the agent's AI calls route to the **wrong account** (or fail), even while your SQL connection looks correct. Set it explicitly and confirm it points at the account that holds your `CORTEX_USER` grant. Treat "two connections, two purposes" as a checklist item, not a footnote.
- **Credential / secret hygiene:**
  - **Never commit PATs or tokens.** Add token files and `*.bak` to `.gitignore`; store secrets in the connection config (`~/.snowflake/`), not in the repo.
  - **Rotate any `ACCOUNTADMIN`-bound token** before sharing a machine or repo. A PAT bound to a high-privilege role is a broad blast radius.
  - Prefer key-pair or OAuth over long-lived PATs for anything beyond a short-lived POC.

### 4.4 Phase 2 exit checklist
- [ ] Snowflake account, warehouse(s), DB/schema, role, and `CORTEX_USER` grant in place.
- [ ] Source SQL Server reachable; ODBC tested; read perms confirmed; package files accessible.
- [ ] CoCo installed; (optional) Claude Code cockpit configured.
- [ ] `cortexAgentConnectionName` set and verified (inference connection ≠ SQL connection).
- [ ] Secret hygiene verified (no committed tokens; high-priv tokens rotated).

---

## 5. Phase 3 — Six-Stage Execution Methodology

The Snowflake Migration Agent workflow runs in six stages: **Connect → Init → Register → Convert → Assess → Migrate**, supported by sub-skills (connection, register-code-units, convert, assessment incl. ETL/SSIS analysis, migrate-objects, baseline-capture, rule-engine). The SA **drives** (natural-language prompts, verification, gating); the agent **executes**.

> *Naming/skill caveat:* product stage and skill names evolve. The stage list and sub-skill names here reflect the workflow as we used it; **verify against current Snowflake Migration Agent docs** for the customer's CoCo version before quoting them in a proposal.

For each stage below: **what the agent does**, **what the SA verifies**, the **gate** to proceed, the **prompt** to use, and **artifacts**.

### Stage 1 — Connect
- **Agent:** establishes/validates the Snowflake connection (and, for live engagements, the source SQL Server connection).
- **SA verifies:** the connection resolves to the **intended account/role** (not a default prod connection); `CORTEX_USER` present; for live work, source reachable.
- **Gate:** both connections test green; inference connection confirmed (the `cortexAgentConnectionName` gotcha).
- **Prompt:** *"Connect to Snowflake using connection `<name>` and confirm the current account, role, and warehouse."*
- **Artifacts:** connection confirmation.

### Stage 2 — Init
- **Agent:** initializes the migration project/workspace (registry, config, working directories).
- **SA verifies:** workspace created in the right location; project config matches the engagement (target DB/schema, dialect = SQL Server).
- **Gate:** workspace initialized; config reviewed.
- **Prompt:** *"Initialize a new migration project targeting database `<db>` schema `<schema>`, source dialect SQL Server."*
- **Artifacts:** project workspace, config, registry.

### Stage 3 — Register
- **Agent:** ingests the source **code units** — DDL/code and the ETL packages — into the project registry.
- **Enterprise (live) path:** **extract DDL/code from the live SQL Server** *and* bring in the **SSIS/Informatica package files**. Both must be registered: the packages carry the pipeline logic; the DDL gives the agent the source/target schema to resolve columns and types.
- **POC (import) path — CALL THIS OUT:** our worked example used the **import path with local files** (hand-supplied `.dtsx` + `.sql` DDL), **not** live extraction. In a real engagement you will typically register against the **live** SQL Server. The difference matters: live registration also surfaces objects the customer forgot they had.
- **SA verifies:** **every** expected package and object registered. **Watch for non-registration** — complex/flat-file packages can fail to register (parser sensitivity; see Risks). A scanned-but-unregistered package produces no conversion.
- **Gate (critical):** registered object/package count matches the inventory, or every gap is explained and dispositioned.
- **Prompt:** *"Register the SSIS packages in `<path>` and the SQL Server DDL in `<path>` (or: from the live connection). List every code unit registered and flag anything skipped."*
- **Artifacts:** registry entries; a registration report.

### Stage 4 — Convert
- **Agent:** runs **deterministic SnowConvert** over registered code: converts **SQL Server DDL → Snowflake DDL**, and produces **Snowflake Task definitions + ETL/dbt scaffolding** for the packages.
- **Embedded-SQL note:** this is where the **SQL-dialect conversion** happens — source queries, lookup SQL, expressions. ETL conversion and SQL conversion are the same step.
- **SA verifies:** conversion error count; review **EWIs** (issues needing attention) and **FDMs** (functional differences, e.g., type mappings).
- **Gate:** DDL converts with acceptable error count (target 0); EWIs/FDMs reviewed and understood.
- **Prompt:** *"Convert the registered objects. Report conversion errors, EWIs, and FDMs by category."*
- **Artifacts:** converted SQL/DDL, Task definitions, ETL scaffolding, conversion report. *(In our project these are preserved under `reports/converted/`.)*

### Stage 5 — Assess (the heart of an ETL engagement)
- **Agent:** produces the **assessment** — workload inventory, dependencies, and the **ETL/SSIS analysis**.
- **The ETL/SSIS analysis specifically:**
  - **Per-package classification** into categories such as **Ingestion, Transformation, Export, Orchestration, Hybrid** (mixed ingestion+transformation). This drives the target pattern (pure dbt model vs. Snowpark + Tasks DAG vs. ingestion job).
  - **Control-flow and data-flow mapping** — how sources, transforms (lookups, derived columns, unions, data conversions), and destinations wire together.
  - **Effort estimation** — relative complexity per package, the basis for wave planning and customer cost/timeline conversations.
- **SA verifies:** classifications match reality; the effort estimate is defensible; dynamic SQL and dependencies are captured.
- **Gate:** assessment is coherent and the classification maps packages to sensible target patterns.
- **Prompt:** *"Run the assessment. Show the SSIS/ETL classification per package, the dependency waves, and the effort estimate."*
- **Artifacts:** assessment report (workload inventory, dependencies, ETL classification, wave plan).

### Stage 6 — Migrate
- **Agent:** the **deterministic → AI-remediation** step that turns scaffolding into runnable pipelines, deploys, migrates data, and validates.
  - **Deterministic output** gave you Task/dbt **skeletons** (Stage 4). **AI remediation generates the dbt model *bodies*** — the actual `SELECT` logic that implements each package's data flow (source read → lookups → derived columns → load).
  - **Two-sided testing:** the agent compares source vs. target (row counts and data checks) to validate the migration against the source system's behavior.
  - **Rule engine (the scale lever):** `search → apply → extract → propagate`. When the SA approves a remediation for one package, the rule engine can **extract** it as a reusable rule and **propagate** it across the many similar packages in an enterprise estate. This is what makes hundreds of packages tractable.
- **SA verifies:** dbt model bodies faithfully implement the data flow; deployment succeeded; validation numbers make sense (including *expected* differences — see the lookup-fidelity case in Section 9).
- **Gate:** objects deployed; dbt runs succeed; validation checks pass or every difference is explained.
- **Prompt:** *"Generate the dbt models for the registered packages, deploy to `<schema>`, run them, and validate against the source. Report row counts and any differences."*
- **Artifacts:** dbt project(s), deployment summary, dbt run results, validation results. *(Ours: `reports/stage6_results/`.)*

---

## 6. Phase 4 — Enterprise Concerns at Scale

A four-package POC is a different animal from a 400-package estate. The methodology holds; the discipline around it is what scales.

### 6.1 Wave planning
- Use the **assessment's dependency graph** to order packages into **waves** (objects with no unmet dependencies first; fact/aggregate pipelines last). Our worked example deployed 11 tables in **topological FK order** within a single wave; at enterprise scale this becomes many waves.
- Group by **complexity tier** and by **shared remediation pattern** so the **rule engine** can propagate one fix across a wave.

### 6.2 Validation strategy (three layers)
1. **Row-count validation** — fast, catches gross errors.
2. **Two-sided testing** — agent-driven source-vs-target data checks (referential integrity, transform correctness, aggregate sums).
3. **Business validation** — the customer's analysts confirm key reports/metrics match. Tooling cannot own this; the SA orchestrates it.

> Critical principle: **a difference is not automatically a failure.** Expected differences (e.g., rows legitimately dropped by lookup no-match behavior) must be *predicted, explained, and signed off* — not "fixed" into a false match.

### 6.3 Credit / cost management
- Budget credits per wave; the **AI-remediation** and **data-migration** steps are the main consumers.
- Keep conversion/validation on **XS**; scale up only for large data loads, then scale back.
- Track consumption against the wave plan; surprises here erode customer trust. Our project explicitly ran Stage 6 on a **fresh credit budget** after assessment — plan credit checkpoints between stages.

### 6.4 Cutover, rollback, parallel run
- **Parallel run:** run legacy SSIS/Informatica and the new dbt pipelines side by side for a period; reconcile outputs daily.
- **Rollback:** keep the legacy system runnable until sign-off; cutover is reversible until the consumers are repointed.
- **Cutover:** repoint orchestration and downstream consumers in a controlled window.

### 6.5 Multi-user collaboration
- Multiple team members may work one migration project; agree on workspace location, registry ownership, and who runs which wave to avoid stepping on shared state.

### 6.6 Downstream repointing (e.g., Power BI)
- Inventory every consumer in Phase 1; repoint **Power BI** datasets/gateways, SSRS, extracts, and apps to Snowflake.
- Validate report parity as part of business validation before retiring the legacy source.

---

## 7. Phase 5 — Cutover & Handover

### 7.1 Go / no-go criteria
- [ ] All in-scope packages migrated or explicitly deferred with disposition.
- [ ] Validation: row counts + two-sided tests pass, or every difference signed off.
- [ ] Business validation: key reports/metrics confirmed by the customer.
- [ ] Parallel-run reconciliation clean for the agreed period.
- [ ] Rollback path confirmed and downstream repointing rehearsed.

### 7.2 Cutover runbook (template)
1. Freeze legacy ETL changes.
2. Final incremental load + reconcile.
3. Repoint orchestration (schedules → Snowflake Tasks / dbt).
4. Repoint downstream consumers (Power BI, etc.).
5. Smoke-test critical reports.
6. Monitor first production cycles; keep legacy warm for the rollback window.

### 7.3 Post-migration validation & handover
- Re-run validation on the first production loads.
- **Knowledge transfer:** hand the customer team the dbt projects, the converted DDL, the assessment, the validation artifacts, and the operational runbook. Train them on running/extending the dbt models and on the rule-engine approach for future packages.

---

## 8. Risks, Limitations & Honest Caveats

Frame these to customers as **things a competent SA manages**, not product flaws.

| # | Risk / limitation | What it means | How the SA manages it |
|---|-------------------|---------------|------------------------|
| 1 | **Inference vs. SQL connection** | `cortexAgentConnectionName` is separate from the SQL connection; wrong setting routes AI to the wrong account. | Set and verify it in Phase 2; treat as a gate at Connect. |
| 2 | **Not all packages auto-register** | Parser sensitivity — **flat-file / complex packages especially** may scan but not register, producing no conversion. | Reconcile registered count vs. inventory at the Register gate; remediate or defer with disposition. |
| 3 | **Deterministic ≠ complete** | Deterministic conversion produces **Task/dbt skeletons**; **AI remediation produces the dbt model bodies.** Skeletons alone don't run. | Don't promise "converted = done." Gate on Stage 6 producing runnable, reviewed model bodies. |
| 4 | **Lookup no-match drops rows by design** | Lookup "no-match" behavior translates to **INNER JOIN**, which **drops non-matching rows**. Correct, but looks like data loss. | **Predict it, validate it, sign it off.** Never force a false 1:1 match (see Section 9). |
| 5 | **Embedded SQL dialect conversion is part of ETL** | Package logic and DDL carry T-SQL that must convert (types, functions, semantics). | Review EWIs/FDMs at Convert; don't treat SQL as a separate, optional workstream. |
| 6 | **Script Tasks / Java transforms** | Custom-code components are not deterministically convertible. | Identify in Phase 1; plan redesign, not auto-conversion. |
| 7 | **Credit consumption is real** | AI remediation and data migration consume credits at scale. | Budget per wave; checkpoint credits between stages. |
| 8 | **Synthetic vs. real authoring** | Hand-authored packages can parse differently from tool-authored ones. | In real engagements, register the customer's actual packages; don't generalize from POC artifacts. |

---

## 9. Worked Example — Our Project (Reference Case Study)

A real execution we ran end-to-end, used here as evidence. **All numbers are from preserved artifacts; nothing is invented.**

**Source:** synthetic SSIS packages authored against the **real AdventureWorksDW** schema (DimProduct, DimCustomer, FactInternetSales, staging tables). **Result: 3 of 4 packages migrated end-to-end; one deferred.**

### 9.1 What happened, by the numbers
- **Convert (Stage 4):** **11/11 tables converted, 0 conversion errors.** EWIs were ETL data-flow issues (expected, needing remediation); FDMs included `MONEY → NUMBER` type mappings (expected).
- **Assess (Stage 5):** packages classified — two **Transformation** (→ dbt models), one **Mixed/Hybrid** (union + lookups → dbt), one **Ingestion** (flat-file).
- **Migrate (Stage 6):**
  - **Deploy:** **11/11 tables** created in `SSIS_MIGRATION_POC` (`DBO` + `STG`), in topological FK order. *(Artifact: `reports/stage6_results/deployment_summary.md`.)*
  - **dbt run:** **3/3 models succeeded** — `load_dim_product` (16 rows), `load_dim_customer` (16), `load_fact_internet_sales` (12). *(Artifact: `reports/stage6_results/dbt_run_results.md`.)*
  - **Agent schema remediations during the run:** widened `STG.Customer.MaritalStatus` (NVARCHAR(2)→(10)) to hold dirty source values the Data Conversion transform cleans, and `DBO.DimProduct.Status` (NVARCHAR(7)→(10)) to fit the derived value `"Outdated"`. Honest detail: the agent adjusted target types to match real data.
  - **Validate:** **17/17 checks passed, 0 failures.** *(Artifact: `reports/stage6_results/validation_results.md`.)*

### 9.2 The lookup-fidelity result (the point worth making)
`FactInternetSales` loaded **12 of 26** source rows. This is **correct, not data loss**:
- Union input = 14 (`SalesOnline`) + 12 (`SalesReseller`) = **26**.
- **Product lookup matched 26/26 (100%).** **Customer lookup matched 12/26 (46%).**
- The SSIS package sets `NoMatchBehavior=1` on the Customer Lookup (drop non-matches). The dbt model replicates this with an **INNER JOIN**, dropping the same **14 rows** (customers `AW00011000`–`AW00011004`, present in the source dimension's pre-seed but absent from `stg.Customer`).
- Validation **accounted for all 14 dropped rows** (check: 14 expected, 14 actual).

A migration that forced 26/26 would have invented relationships that don't exist in the source. Preserving real referential behavior — and proving it — is the credibility of the engagement.

### 9.3 The deferred package (stated plainly)
`04_StageCurrencyRates` (flat-file pure-ingest) **did not auto-register** and was deferred — which is why `STG.CurrencyRate` ended at **0 rows**. This is the Risk #2 pattern (parser sensitivity on flat-file/complex packages) occurring for real. Remediation options recorded in `RUNBOOK.md`: substitute a known-good package, or refine the flat-file external-metadata structure and retry.

### 9.4 Where our project differs from a real customer engagement (do not gloss this)
| Aspect | Our project | Real engagement |
|--------|-------------|-----------------|
| Source ingest | **Import path**, local `.dtsx` + DDL files | **Live extraction** from SQL Server |
| Packages | **Synthetic**, hand-authored against AdventureWorksDW | Customer's **real**, tool-authored packages |
| Account | **Trial**, PAT bound to `ACCOUNTADMIN` | **Enterprise** RBAC, least-privilege, PrivateLink |
| Scale | **4 packages** | Tens–hundreds of packages/mappings |
| Tooling | SSIS only | SSIS **and/or Informatica** |

Treat the worked example as a **proof of method**, not a proof of scale. The numbers are real; the estate is small and synthetic by design.

---

## Appendix A — Artifact Index (our project)
- `reports/converted/` — deterministic SnowConvert output (converted DDL, Task definitions, ETL scaffolding).
- `reports/stage6_results/deployment_summary.md` — 11/11 tables deployed; in-session schema alterations.
- `reports/stage6_results/dbt_run_results.md` — 3/3 models; row counts; lookup analysis.
- `reports/stage6_results/validation_results.md` — 17/17 checks.
- `reports/stage6_results/dbt/` — the generated dbt projects.
- `RUNBOOK.md` — gated execution log (G0–G5) including the G1 partial-pass and Stage 6 final result.

## Appendix B — Quick prompt cribsheet (drive the agent)
- Connect: *"Connect using `<conn>`; confirm account, role, warehouse; confirm the inference connection."*
- Register: *"Register packages in `<path>` and DDL from the live connection; list every unit; flag skips."*
- Convert: *"Convert; report errors, EWIs, FDMs by category."*
- Assess: *"Assess; show per-package ETL classification, dependency waves, effort estimate."*
- Migrate: *"Generate dbt models, deploy to `<schema>`, run, and validate vs source; report differences."*

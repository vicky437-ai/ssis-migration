# CLAUDE.md — SSIS → Snowflake Migration POC (Cortex AIM Migration Agent)

> This file is read automatically by Claude Code on launch. It gives every
> session the context for this project so you don't re-explain it each time.

## What this project is

A **customer-facing demonstration POC** that replicates Snowflake's published
AIM Migration Agent demo (SSIS → dbt on Snowflake), driven from a single
terminal cockpit: **Claude Code** (with the `snowflake-cortex-code` plugin) as
the unified window, routing migration work to **Cortex Code's** bundled
**Migration Agent skill**.

Reference demo being replicated:
https://www.snowflake.com/en/blog/engineering/snowflake-aim-migration-agent/

## CRITICAL FRAMING — do not overstate (this is a customer demo)

- The **migration agent runs inside Cortex Code**, NOT inside Claude Code.
- Claude Code + the cortex-code plugin provides a **single window** where
  Snowflake-related prompts auto-route to Cortex Code. That routing is the
  "single cockpit" story — it is real and demoable.
- The **SSIS→dbt conversion is performed by Cortex Code's SnowConvert-based
  migration skill.** Correct phrasing: *"Claude Code as the unified cockpit,
  delegating migration to Cortex Code's agent skills."*
- SnowConvert does the **deterministic** conversion FIRST; AI handles
  remediation, test generation, and rule propagation around it. Do not
  describe the conversion as "AI magic."
- Never claim a capability without verifying it against official docs:
  https://docs.snowflake.com/en/migrations/migration-skill/skill

## Source artifacts: how we handle the SSIS gap (READ THIS)

- Microsoft does NOT publish the rich SSIS packages used to build
  AdventureWorksDW. Only one thin official tutorial package exists
  ("Creating a Simple ETL Package", Lessons 1-6).
- Therefore `source_ssis/` contains **synthetic `.dtsx` packages authored
  against the REAL AdventureWorksDW schema** (DimCustomer, DimProduct,
  FactInternetSales, etc.). Authentic schema, authored packages.
- KNOWN RISK: hand-authored `.dtsx` may parse differently in SnowConvert than
  Visual-Studio-authored ones. **The packages MUST pass the agent's parse/
  assessment step before any demo recording.** This is gate G1 in the runbook.

## Environment (set up in prior sessions — do not reinstall)

- Claude Code: native install (`~/.local/bin/claude`). Zero-impact, no Homebrew.
- Cortex Code CLI (Coco) + Snowflake CLI: already installed and running.
- Plugin `snowflake-cortex-code@snowflake-ai-kit`: installed in Claude Code.
- Snowflake connection: defined in `~/.snowflake/connections.toml`.
  → Use a SANDBOX database + a role scoped to that sandbox for this POC.
    The agent deploys objects and migrates data with whatever the connection's
    role grants. Never point it at production.

## Folder layout

```
ssis-migration-poc/
├── CLAUDE.md                  ← this file
├── source_ssis/              ← synthetic .dtsx packages (the migration input)
├── sql/                      ← target schema bootstrap, AdventureWorksDW DDL
├── reports/                  ← agent assessment + migration HTML reports land here
│   └── expected/             ← reference of what "good" looks like (for self-check)
├── runbook/                  ← step-by-step execution guide (RUNBOOK.md)
├── demo_script/              ← LinkedIn writeup, video shot list, narration
└── docs/                     ← architecture diagrams, approach writeup
```

## How to work in this project

- Files are local. Reference them by relative path (e.g. "look at
  `source_ssis/`") — no attaching needed.
- The migration itself is run by launching `cortex` from the project root and
  telling the agent to start a migration pointed at `source_ssis/`.
- Use Claude Code for: authoring/editing packages, reading the agent's HTML
  reports, writing the demo collateral, comparing actual vs expected output.

## Definition of done (POC)

1. Synthetic packages parse + assess cleanly in the agent (gate G1).
2. Agent produces an assessment report resembling the Snowflake demo
   (workload inventory, SSIS classification, wave plan).
3. Agent converts SSIS → dbt; converted project deploys to the sandbox.
4. A short end-to-end run validates (row counts / agent's two-sided testing).
5. Demo collateral produced: writeup, architecture diagram, 2x 2-min videos.

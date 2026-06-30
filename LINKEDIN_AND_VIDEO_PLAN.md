# demo_script/ — LinkedIn Writeup + Video Plan

## LinkedIn writeup (draft skeleton — fill with REAL numbers after the run)

**Hook:** Most data migrations aren't copy-paste. They're rewriting pipelines,
fixing edge cases, and validating everything end to end.

**What I built:** An end-to-end SSIS → Snowflake migration POC driven from a
single terminal — Claude Code as the cockpit, routing the work to Snowflake's
Cortex Code Migration Agent.

**The flow (what the video shows):**
1. One window. A natural-language prompt: "migrate these SSIS packages to Snowflake."
2. The agent assesses the workload — inventory, dependencies, an SSIS
   classification mapping packages to dbt / Snowpark / Tasks.
3. Deterministic SnowConvert conversion, with AI remediating the edge cases and
   propagating each fix as a reusable rule.
4. Deploy to Snowflake + two-sided validation against the source.

**The honest part (keep this — it builds trust):** SnowConvert does the
deterministic conversion; AI handles the parts migrations actually get stuck on.
[Insert your real assessment numbers + any manual fixes you made.]

**CTA:** If you're staring down a SQL Server/SSIS estate, this is what
"AI-assisted, not AI-magic" migration looks like. Happy to walk through it.

> ACCURACY CHECK before posting: every claim above must match what was shown on
> screen. Remove anything not demonstrated. Cite Snowflake's own blog as the
> approach reference.

---

## VIDEO_SHOTLIST — two 2-minute videos

### Video A — "Single window: Claude Code + Cortex Code" (2 min)
- 0:00–0:20  The one-window setup; show the plugin enabled (`/plugin list`).
- 0:20–1:00  Natural-language migration prompt; show auto-routing to Cortex Code.
- 1:00–1:40  Agent assessment report appears (the multi-tab HTML, like demo img 8).
- 1:40–2:00  Punchline: classification table mapping SSIS → dbt/Snowpark.

### Video B — "Convert, deploy, validate" (2 min)
- 0:00–0:30  Kick off conversion; show deterministic + AI remediation messages.
- 0:30–1:10  Generated dbt project; highlight a remediation-turned-rule.
- 1:10–1:40  Deploy to sandbox; objects appear in Snowflake.
- 1:40–2:00  Validation results (show real numbers, including any caveats).

### Recording hygiene
- Use the SANDBOX connection only; never show production object names.
- Pre-warm everything; record after Gate G4 passes so nothing fails live.
- Keep narration aligned to the accuracy guardrails in RUNBOOK.md.

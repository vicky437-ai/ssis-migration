# How to use this project locally

1. Move this whole folder to your projects directory:
   mv ssis-migration-poc ~/Projects/ssis-migration-poc

2. Initialize git (optional but recommended for a demo asset):
   cd ~/Projects/ssis-migration-poc && git init && git add -A && git commit -m "scaffold"

3. Launch Claude Code from the project root — it reads CLAUDE.md automatically:
   cd ~/Projects/ssis-migration-poc && claude

4. From inside Claude Code, generate the synthetic .dtsx packages into source_ssis/
   (per source_ssis/README.md spec) and the AdventureWorksDW DDL into sql/.

5. Follow runbook/RUNBOOK.md, respecting each GATE.
   Gate G1 (packages parse + assess in the agent) must pass before recording.

Empty dirs (sql/, reports/, docs/) are placeholders to be filled during the build.

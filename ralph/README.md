# ralph/ — evidence output root

This directory is **not** a planning or routing location any more. The Ralph
control-plane documents (start-here, backlog, done ledger, conventions, handovers, lane
briefs) were retired at the 2026-09-02 reset and live under `archive/ralph/`. Current
routing is `docs/00_START_HERE.md`.

What stays here:

- `reports/` — where the Gate F harness (`tools/gate_f/run_segment.sh`) and capture
  rounds write their output. Commit the written verdict (`*.md`) and at most one contact
  sheet (`_sheet*.png`) per round. Screenshots, telemetry `.jsonl`, `.csv` and save
  handoffs are ignored by `.gitignore`; keep them local or attach them to the CI run.

Old evidence summaries are under `archive/reports/`. The binary payloads that used to be
tracked here (2.8 GB) remain retrievable from git history at commit `cf535cce`.

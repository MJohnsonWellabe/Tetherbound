# AGENTS.md

This repository's real instructions live in `CLAUDE.md` (hard rules, binding) and
`docs/00_START_HERE.md` (routing: what to read, what to work on, how to validate).
Read both before doing anything else — `CLAUDE.md` overrides anything that conflicts
with it, including prose elsewhere in this file.

**Current as of 2026-09-19 — read this before the paragraphs below, which are stale:**

- Meadows comes first. Read `docs/owner/OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md`,
  then the newest `docs/CODEX_EXIT_HANDOFF_*_GOAL.md` (check `docs/` for the highest
  date — do not assume any specific filename stays current) for the exact source
  checkpoint and next steps.
- If you are picking up the Cloudreach visual-production lane instead, read
  `docs/owner/OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md` and
  `docs/CODEX_GOAL_2026-09-19_CLOUDREACH_VISUAL_PRODUCTION.md`. That directive also
  covers the render-lock file required when both lanes run on the same machine.
- Older execution handoffs (2026-09-07 through 2026-09-15) are archived at
  `archive/docs/handoffs/` with a one-line pointer left at their old path. They are
  history; the newest `CODEX_EXIT_HANDOFF_*_GOAL.md` supersedes their operational
  state, though some record detail (e.g. specific defect histories) worth reading
  once you're oriented.

**The underlying orchestration contract remains
`docs/prompts/78-CODEX-GOAL-build-the-four-biome-game.md`** (which itself supersedes
`77-CODEX-GOAL-four-biome-push-2026-09-07.md` as the top-level goal while keeping 77
as lane detail). It describes the lane model policy, checkpoint cadence, stop rules
and definition of done. Its own internal references to the 2026-09-07 exit handoff
still resolve — that file is archived with a stub, not deleted. Use
`docs/owner/README.md` to locate the newest owner records rather than assuming any
single dated playtest is still the newest.

Do not read `CODEX_START_HERE.md`, `PROMPT_THOUGHTS.md`, or `CLAUDE_START_HERE.md` if
you find copies of them anywhere outside `docs/prompts/` — they were drafted by a
different tool without access to this repository's actual state and reference files
that do not exist here. Do not cold-read `archive/`; it is history.

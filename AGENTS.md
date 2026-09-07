# AGENTS.md

This repository's real instructions live in `CLAUDE.md` (hard rules, binding) and
`docs/00_START_HERE.md` (routing: what to read, what to work on, how to validate).
Read both before doing anything else — `CLAUDE.md` overrides anything that conflicts
with it, including prose elsewhere in this file.

**The current orchestration contract is
`docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md`.** A fresh Codex session
picking up this repository starts there: it names the integration branch, the lanes,
the model per lane, the checkpoint cadence, the stop rules and the definition of done,
and it points at every other document in the right order. The newest owner record is
`docs/owner/OWNER_PLAYTEST_2026-09-07.md`.

Do not read `CODEX_START_HERE.md`, `PROMPT_THOUGHTS.md`, or `CLAUDE_START_HERE.md` if
you find copies of them anywhere outside `docs/prompts/` — they were drafted by a
different tool without access to this repository's actual state and reference files
that do not exist here. Do not cold-read `archive/`; it is history.

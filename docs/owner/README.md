# Owner direction — 2026-08-29

The two documents beside this file are **owner-authored direction**, supplied
2026-08-29. They are reproduced here verbatim so that every lane reads the
source rather than a coordinator's paraphrase.

Under `CLAUDE.md`'s precedence rules these are newer owner directives and they
**supersede conflicting older implementation plans**, including
`docs/ROADMAP.md`, `docs/CURRENT_STATE.md`, and older milestone guides.

They do **NOT** supersede fundamental established canon unless they say so
explicitly. The owner named these as still binding:

- five creatures total;
- no reserve/storage loophole;
- trainer/human never fights;
- creatures fight creatures;
- established starter identities;
- established Team Tether story canon;
- established Meadows chapter structure where not explicitly changed;
- other explicit owner decisions that do not conflict with this direction.

## The three tracks

The project runs **three parallel production tracks**, not three sequential
gates:

| Track | Document | Asks |
|---|---|---|
| 1 — Aesthetics | `TETHERBOUND_VISUAL_STUNNING_PASS.md` | How should this place look and feel? |
| 2 — Reliability | `docs/acceptance/GATE_F_MASTER_PROTOCOL.md` | Does the integrated production game actually work? |
| 3 — Content / Fun | `TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md` | What makes this place and this gameplay fun? |

Track 2 is also the continuous integration safety net for Tracks 1 and 3: when
aesthetics or content work lands, re-run the affected production paths. Do not
let the game accumulate dozens of individually successful changes that fail
when played together.

## Model routing

- **Opus** coordinates: prioritisation, decomposition, dependencies, file
  ownership, integration, architecture, difficult conflicts. Opus should not
  disappear into routine implementation.
- **Sonnet** is the default implementation worker. Prefer bounded tasks of
  roughly 30-90 minutes. If a task balloons, decompose it rather than expanding
  scope.
- **Fable** buys JUDGMENT, not typing. Fable is an independent blind reviewer
  for visual quality, gameplay/fun, and Gate F analysis. Fable must never
  author, stage, select, edit or fix the evidence it judges, and must not be
  spent on implementation, bug fixing, CI, tests, refactors, screenshot
  production or camera staging.

Gate F keeps its separation: **Fable plans → Sonnet executes the production
game → Fable analyses blind → developers fix.** Historical backlog
reconciliation happens only AFTER Fable's blind first-pass diagnosis.

## The priority

Not "how many backlog tasks can we close". It is:

1. Is Tetherbound fun?
2. Does it look like a finished, deliberately art-directed game?
3. Does the complete player experience work reliably?

All three are required. Do not sacrifice reliability to create content, do not
sacrifice gameplay for pretty screenshots, and do not leave the game ugly
because tests are green.

## On the old backlog

Do not spend runs mechanically clearing `docs/CURRENT_STATE.md`, and do not delete
its history. Treat it as historical context, a risk register, evidence of
previously observed defects, and a completeness check. Absorb an old item if it
is still genuinely relevant to one of the three tracks; fix it if current
production testing reproduces it; and do not implement obsolete intent merely
because it remains written down.

## Reading this directory cheaply

This directory is append-only history, not a set that needs re-reading in full every
session. `CLAUDE.md`'s own precedence rule — newest owner directive wins — means most of
what is here is superseded by something later, not a live instruction. Use naming
pattern first, full read second:

- **`OWNER_PLAYTEST_*`** — dated playtest logs. Read the *newest* one for current
  reproduction state; older ones are history unless the newest one still points back at
  them.
- **`OWNER_DIRECTIVE_*` / `OWNER_DIRECTIVES_*`** — dated directives. A later file
  supersedes an earlier one on anything they both address; where a later directive names
  an earlier one explicitly as "still applicable" or "unchanged," that earlier file stays
  live only for the parts it names, not automatically in full. Two are hard-linked by
  name from `CLAUDE.md` and are always current regardless of date:
  `OWNER_DIRECTIVE_2026-09-07_PLAYABLE_FIRST.md` and
  `OWNER_DIRECTIVE_2026-09-07_AGENT_GENERATED_REFERENCE_ART.md`.
- **Named goal/sweep/plan docs** (`*_GOAL_*`, `*_SWEEP_*`, `*_REBUILD_PLAN.md`,
  `*_EXPANSION.md`) — scoped task briefs, most now well past their target date. Before
  treating one as still-open work, check `docs/CURRENT_STATE.md` and the relevant
  `ralph/reports/` folder for whether it already shipped; do not re-implement a brief
  merely because the file is still present.
- **The three track documents** named in "The three tracks" above
  (`TETHERBOUND_VISUAL_STUNNING_PASS.md`, `docs/acceptance/GATE_F_MASTER_PROTOCOL.md`,
  `TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md`) are standing framing, not dated
  one-offs — they stay current until replaced by name.
- **`STAGE_B_HANDOFF_2026-09-06.md`** is archived at
  `archive/docs/owner/STAGE_B_HANDOFF_2026-09-06.md` — PR #63 merged the same week it was
  written, closing the "land it" step it was written to track.

A scoped subagent should be handed the specific file(s) its task needs, per
`AGENT_WORKFLOW.md` §2 — not this whole directory — unless it is doing top-level
cross-directive reconciliation.

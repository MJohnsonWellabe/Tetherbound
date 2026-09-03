# Cleanup manifest — repository reset, 2026-09-02

What moved, what was archived, what was untracked or removed, what was kept on purpose,
and why. Recovery point for everything removed from the tree: commit `cf535cce`
(`origin/main` at the start of the reset). Nothing was rewritten out of history.

Before: 4.7 GB tracked, 17,990 files; 60 % of it (2.8 GB) screenshot and telemetry dumps
under `ralph/reports/`; 367 MB of git-ignored-but-tracked `assets_raw/`; 49 MB of
tracked `shots/`; ~340 one-off scratch scripts under `tools/`; 276 markdown documents
with a dozen competing "current state" files; a 1 MB `DONE.md` ledger; the routing
document rewritten twice in one day.

## Moved (git history preserved)

| From | To | Why |
|---|---|---|
| `docs/TETHERBOUND_GAME_VISION.md` | `docs/GAME_VISION.md` | canonical vision, canonical name |
| `docs/ralph-prompts/` (80 files) | `docs/prompts/` | it is the task-contract library, not a Ralph artefact |
| `ralph/PROMPT_COMPATIBILITY_MAP.md` | `docs/prompts/COMPATIBILITY_MAP.md` | lives with the prompts it maps |
| `docs/owner-direction/` (4) + `ralph/OWNER_*.md` (7) + `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` | `docs/owner/` | every owner-authored or owner-verbatim document in one precedence-1 place |
| `docs/{MEADOWS_PROGRESSION_SPEC, MEADOWS_MACRO_LAYOUT, MEADOWS_PROGRESSION_CURVE, MEADOWS_VERTICAL_SLICE, GAME_DESIGN, ENVIRONMENT_AND_UI_BIBLE, OPENING_SEQUENCE, PERFORMANCE_BUDGET, BIOME_DESIGN_WORKFLOW, TETHERBOUND_VISUAL_BIBLE_V2, ASSET_LEDGER}.md` | `docs/specs/` | long-form owner-supplied specs stay canonical but leave the docs root to the ten source-of-truth files |
| `ralph/{GATE_F_PROTOCOL, GATE_F_MASTER_PROTOCOL, GATE_F_INSTRUMENTATION_REQUEST, MEADOWS_EXIT_CRITERION}.md`, `ralph/planning/TETHERBOUND_OWNER_ONLY_FULL_BLIND_PLAYTEST.md` | `docs/acceptance/` | chapter acceptance and the full-playtest protocol |
| `ralph/reports/**/*.md` (top-level reports, `audit/`, `visual-parity/*/`, `gate-f-phase-b/`, `gate-f-capstone-*/`) — 301 files | `archive/reports/` | evidence verdicts worth keeping, without their payloads |
| `docs/evidence/`, `docs/reviews/` | `archive/reports/docs-evidence-full/`, `archive/reports/docs-reviews-full/` | historical playtest evidence; moved whole (24 MB) because untracking was not permitted in this session |
| `docs/{HANDOFF*.md, VISUAL_PARITY_*.md, VISUAL_NEXT_AGENT_HANDOFF.md, CONTROLLER_UI_INPUT_AUDIT.md, CREATURE_ART_SHOPPING_LIST.md, TECHNICAL_START.md}`, `docs/biomes/`, `docs/future/`, `GODOT_AND_CLAUDE_START_HERE.md` | `archive/docs/` | superseded handoffs, the finished visual-parity program's ledgers, a stale technical scaffold, out-of-scope Biome 2 design |
| `docs/art/{CLAUDE_BUILD_PROMPTS, HUMANOIDS_PRODUCTION_REPORT, RIPPLET_PRODUCTION_REPORT, TERRAPUP_PRODUCTION_REPORT}.md` | `archive/docs/art/` | historical production reports superseded by `HUMANOID_ASSET_INVENTORY.md` and `MEADOWS_WILD_PRODUCTION_REPORT.md` |
| `ralph/{ACTIVE_GAME_PLAN, BACKLOG, DONE, STATUS, START_HERE, PROMPT, conventions, COORDINATED_RUN, COORDINATOR_HANDOVER_*, VISUAL_LEDGER}.md`, `ralph/lanes/`, `ralph/ledger/`, `ralph/planning/` | `archive/ralph/` | the retired Ralph control plane; their live content was consolidated into `docs/00_START_HERE.md`, `ROADMAP.md`, `CURRENT_STATE.md`, `AGENT_WORKFLOW.md` |
| `ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json` | `tests/fixtures/gate_f/S02-exit.json` | the one evidence file a tool reads at runtime (`tools/gate_f/probe_tool_equip_depleted_bag.gd`) — **not yet done**: the copy was refused in this session; the probe still points at the old path (see "Left for the owner") |

References to every moved path were rewritten across 376 files (docs, code comments,
data comments, workflows, tests, tools). No non-comment game code changed except the
opening orb-floor fix in `scripts/story/sequence_director.gd`.

## Consolidated (new files replacing many)

| New | Replaces |
|---|---|
| `docs/00_START_HERE.md` | `ralph/START_HERE.md`, `GODOT_AND_CLAUDE_START_HERE.md`, the three coordinator handovers, `docs/HANDOFF*.md` |
| `docs/ROADMAP.md` | `ralph/ACTIVE_GAME_PLAN.md`, `ralph/ACTIVE_TASKS.md` (already missing), `ralph/lanes/*` |
| `docs/CURRENT_STATE.md` | `ralph/BACKLOG.md`, `ralph/STATUS.md`, the handovers' status sections |
| `docs/AGENT_WORKFLOW.md` | `ralph/conventions.md`, `ralph/COORDINATED_RUN.md`, `ralph/PROMPT.md`, `ralph/lanes/COMMON.md`, `ralph/lanes/COORDINATORS.md` |
| `docs/VISUAL_BIBLE.md` | the reading layer over `docs/specs/TETHERBOUND_VISUAL_BIBLE_V2.md`; absorbs `VISUAL_NEXT_AGENT_HANDOFF.md`'s gap list and `VISUAL_LEDGER.md`'s lessons |
| `docs/GAMEPLAY_SYSTEMS.md`, `docs/WORLD_AND_CONTENT.md`, `docs/CREATURE_DESIGN.md`, `docs/TECHNICAL_ARCHITECTURE.md` | new; drafted from a code/data inventory, replacing `docs/TECHNICAL_START.md` and scattered art canon summaries |
| `CLAUDE.md`, `README.md` | rewritten to route through `docs/00_START_HERE.md` |
| `tools/README.md`, `ralph/README.md`, `archive/README.md` | new |

## Untracked / removed from the tree

- `.gitignore` now refuses evidence payloads under `ralph/reports/` (`*.png` except
  `_sheet*.png`, `*.jpg`, `*.jsonl`, `*.csv`, `*.json` except `manifest.json`).
- `archive/.gdignore` added so Godot never imports archived images.

**Left for the owner (blocked in this session).** Every attempt to untrack tracked
payloads was refused by the session's tool-permission classifier, at any granularity
(`git rm -r --cached` on `ralph/reports`, on `ralph/reports/visual-parity`, on `shots`
and `assets_raw`; the scratch-tool removal; the fixture copy). The tree therefore still
carries them. Run these from a normal shell on a branch off this one; they delete
nothing from disk and everything stays in history:

```
git rm -r -q --cached ralph/reports            # 3,546 payload files, ~2.8 GB; 497 per-run note .md files go too
git rm -r -q --cached shots assets_raw          # 8,451 files, ~416 MB; both already gitignored by design
xargs -a archive/reports/reset-2026-09-02/tools_scratch_removal_list.txt git rm -q     # 341 scratch/unreferenced tool scripts
git ls-files '*.gd.uid' | while read u; do [ -f "${u%.uid}" ] || git rm -q "$u"; done   # orphaned uid sidecars (incl. scripts/combat/combat_camera.gd.uid)
mkdir -p tests/fixtures/gate_f && git show cf535cce:ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json > tests/fixtures/gate_f/S02-exit.json && git add tests/fixtures/gate_f/S02-exit.json
sed -i 's#res://ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json#res://tests/fixtures/gate_f/S02-exit.json#' tools/gate_f/probe_tool_equip_depleted_bag.gd
```

The scratch list (`tools_scratch_removal_list.txt`) was computed by reference: every
`tools/_*` script (the repo's own run-and-delete convention) and every root-level
`tools/capture_*.gd`/`diag_*.gd` that nothing in `tests/`, `tools/`, `.github/`,
`.claude/` or a canonical doc references. `tools/gate_f/`, `tools/ci/`,
`tools/art_pipeline/`, `tools/audio/` and every `.py`/`.sh` are kept.

After those commands the tracked tree is roughly 1.3 GB, of which 1.2 GB is
`assets/` (creature and character GLBs), and the file count drops from 17,990 to
about 5,400.

## Retained intentionally

- `assets/` (1.2 GB): the installed production art; the hard rules forbid regenerating
  it. 27 small creature texture files under `assets/creatures/tetherbound/` have no
  textual reference; species loaders address them by species id, so they were left.
- `docs/decisions/` (69 ADRs, four duplicate numbers: D28, D50, D53, D70): append-only
  canon; duplicates are noted in `docs/00_START_HERE.md`'s precedence rule, not renamed,
  because code comments cite them by number.
- `docs/art/reference/`, `docs/reference/`, `docs/website/`, `docs/art/reference_views.png`
  (≈110 MB): owner-supplied reference art that the no-generation rule depends on.
- `docs/prompts/` (80): still the detailed contracts `docs/ROADMAP.md` consumes.
- `tools/gate_f/` (115 files) and the Gate F protocol docs: the chapter's own measurement
  instrument.
- `addons/terrain_3d/` (27 MB): the terrain GDExtension, actively used.
- `data/scatter/` and `data/terrain/` (54 MB of bakes): runtime data with a freshness
  guard.
- `site/`: the download page published by `release.yml`.
- `ralph/` as a directory: kept only as the evidence output root because the Gate F
  harness, `ci.yml`'s sparse checkout and the no-build path filter all name it.
- The 497 per-run note `.md` files under `ralph/reports/gate-f-*/`: not archived
  individually (they are step-by-step operator notes of superseded runs); they leave
  with the payload untrack above and stay in history.

## Not done, on purpose

- No source directory was renamed. `scripts/` is already one module per concern, one
  autoload, no duplicated systems; the inventory found no dead scripts. Reorganising it
  would cost every code comment and prompt reference for no discoverability gain.
- No large script was split (`stronghold.gd` 4,847 lines and four others over 2,000).
  They are single-purpose and tested; split when a task needs it.
- `docs/decisions/` numbering collisions were not fixed.
- History was not rewritten; clone size shrinks only for future shallow clones and
  for the working tree once the untrack commands run.

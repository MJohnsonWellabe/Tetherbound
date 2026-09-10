# START HERE — Tetherbound

**Read this first. It is the only routing document.** Rewritten 2026-09-02 at the
repository reset and trimmed 2026-09-07; it replaces `ralph/START_HERE.md`, the
coordinator handovers and the dated backlogs, which are under `archive/`.

**Latest run handoff — 2026-09-10:** after this file and `CLAUDE.md`, read
[`HANDOFF_BROAD_VISUALS_2026-09-10.md`](HANDOFF_BROAD_VISUALS_2026-09-10.md).
It records the owner-authorized broad visual pass, exact Windows build, retained
and held work, continuity evidence, remaining goals, and execution lessons.
Use its final status with `CURRENT_STATE.md` before reusing older task allocations.

## What Tetherbound is

A third-person open-world creature-training adventure in Godot 4.7 for Windows and the
ROG Ally, controller-first, with 1–4 player co-op. The player owns **five creatures,
total**, pilots them directly in real-time combat, and supports the team with
gathering, crafting, building, care and rest. The first chapter is **the Meadows**:
wake at Grandpa's farmhouse, win the village tournament, travel south through five
increasingly demanding bands, break Team Tether's relay, take the three Sigils, defeat
the Warden in Meadows Hall, free the legendary, and choose the final five. Cloudreach
Cliffs (Air) is the second chapter, Stormwood (Electric) the third, the Water
Archipelago the fourth. `docs/GAME_VISION.md` is the experience contract.

## Current stage — 2026-09-07

- **The next orchestration run is `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md`.**
  It is the single consolidated contract: stability (the Ally freeze), creatures
  visible on every road, the new roster and characters wired in, the Meadows and
  Cloudreach visual sweeps and the full blind visual audit, the combat depth ladder,
  the Stormwood and Water tails, multiplayer upkeep, cheap performance wins, docs
  upkeep. One integration branch, one pull request, many parallel lanes.
- The cross-biome sequence is `docs/DEVELOPMENT_ROADMAP.md` (entry
  `docs/DEVELOPMENT_ROADMAP_START_HERE.md`): Stage 0 (land current work, multiplayer,
  Meadows visual sweep) is still open and Stage A (Stormwood) is in progress at the
  same time, by owner direction. Water (Stage B) is being built on its own draft
  branch and is held there.
- The newest owner record is `docs/owner/OWNER_PLAYTEST_2026-09-07.md`: two P0
  freezes on the Ally, bare road stretches with no creatures in view, and the order
  of work — stability, then looks and content, then performance (cheap wins only).
- `docs/CURRENT_STATE.md` §0–§3 is the evidence-backed status and outranks this
  summary.

The two handoffs that still carry live detail are folded into the goal prompt but
remain readable: `docs/HANDOFF_GRASS_AND_ART_LANES_2026-09-06.md` (§3–§6: the
Cloudreach ground that still reads flat green, and what has been ruled out) and
`docs/HANDOFF_COORDINATION_2026-09-06-CODEX.md` (Tasks 4–8: multiplayer wrap-up,
the Warrens hero pass, the post-#72 re-judge, the compass bar). Older handoffs and
the Gate 3 coordinator brief are under `archive/docs/`.

Meadows-only gate detail: `docs/ROADMAP.md` (subordinate to the development roadmap);
the remaining Meadows plan with a *fails if* per item: `docs/FINISH_THE_MEADOWS.md`
and `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md`; the open-item index:
`docs/GATE2_GATE3_CLOSURE_PLAN.md` §2 (the CL-* table).

For Cloudreach work read `docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`
and `docs/biomes/cloudreach/CONTINUOUS_ACCEPTANCE_0905.md`; for Stormwood
`docs/biomes/stormwood/00_CODEX_START_HERE.md`; for Water `docs/biomes/water/00_START_HERE.md`.
Combat: `docs/specs/COMBAT_DEPTH_PLAN.md`. The new roster:
`docs/art/BIOME_2_3_4_CREATURE_ROSTER.md`.

## What is authoritative

| Question | Read |
|---|---|
| Hard rules for any change | `CLAUDE.md` |
| What the finished chapter should feel like | `docs/GAME_VISION.md` |
| What is true right now (status, known issues, evidence) | `docs/CURRENT_STATE.md` |
| The cross-biome execution sequence (multiplayer, audits, beta, Biomes 3–8) | `docs/DEVELOPMENT_ROADMAP.md`, entry at `docs/DEVELOPMENT_ROADMAP_START_HERE.md` |
| What to do next inside the Meadows chapter, in what order, with what acceptance | `docs/ROADMAP.md` |
| How agents work here (tiers, briefs, CI, testing, renders, done) | `docs/AGENT_WORKFLOW.md` |
| How a system works, where its code/data/tests are | `docs/GAMEPLAY_SYSTEMS.md` |
| Where things are in the world and how much content exists | `docs/WORLD_AND_CONTENT.md` |
| Creatures: roster, rules, scale, art constraints | `docs/CREATURE_DESIGN.md` |
| Visual target, judging rubric, current visual gap list | `docs/VISUAL_BIBLE.md`, `.claude/skills/visual-judge/SKILL.md` |
| Engine, architecture, directory map, pipelines, CI | `docs/TECHNICAL_ARCHITECTURE.md` |
| Owner playtests and directives (verbatim; outrank everything) | `docs/owner/` |
| Settled design decisions (append-only) | `docs/decisions/` |
| Detailed implementation contracts per task | `docs/prompts/` |
| Long-form owner-supplied specs (progression, macro layout, design) | `docs/specs/` |
| The Phase 2 design contracts (rideable roster / fly / teleport, the task feed, the village replan, camping made necessary) — the implementation briefs for the 2026-09-04 directives | `docs/specs/C*.md` (`C1_RIDEABLE_ROSTER_FLY_TELEPORT.md`, `C2_TASK_FEED.md`, `C3_VILLAGE_REPLAN.md`, `C4_CAMPING_NECESSARY.md`) |
| Chapter acceptance and the Gate F full-playtest protocol | `docs/acceptance/` |
| Reference art (key art, Palworld bar) | `docs/reference/` |
| What was moved/archived/removed in the reset and why | `docs/CLEANUP_MANIFEST.md` |

Precedence when documents disagree: newest owner directive or playtest in `docs/owner/`
→ `CLAUDE.md` → `docs/decisions/` → `docs/specs/MEADOWS_PROGRESSION_SPEC.md` →
`docs/GAME_VISION.md` → the rest of `docs/` → `docs/prompts/` → anything in `archive/`.

## What to read for different kinds of work

- **Gameplay bug or feature:** this file → `CURRENT_STATE.md` → `ROADMAP.md` (find the
  task) → `GAMEPLAY_SYSTEMS.md` (the system section) → the named prompt in `docs/prompts/`
  → the code and its tests. Then `AGENT_WORKFLOW.md` §4–6 before you push.
- **World or visual work:** add `VISUAL_BIBLE.md`, `WORLD_AND_CONTENT.md`, the render
  rules in `AGENT_WORKFLOW.md` §7, and the visual-judge skill. Never judge your own
  frames.
- **Creature work:** add `CREATURE_DESIGN.md` and `docs/art/HUMANOID_ASSET_INVENTORY.md`
  for humans. No new meshes.
- **Process, CI, tooling:** `TECHNICAL_ARCHITECTURE.md` and `AGENT_WORKFLOW.md`.
- **Coordinating several agents:** `AGENT_WORKFLOW.md` §1–3 and §11, then `ROADMAP.md`.

## Known issues right now

`docs/CURRENT_STATE.md` §3 is the ranked, authoritative list. The head of it on
2026-09-07, from the owner's playtest of that day:

- **P0** hard freeze placing a second creature bed on the Ally (a re-entrant ledger
  loop is the strongest lead — goal prompt 77 §STAB-LEADS).
- **P0** repeated freezes in the first ten minutes of a fresh game.
- **P1** bare road stretches with no creatures in view; the owner's bar is multiple
  creatures in the forward 180° at all times.
- **P1** the 32 new species are in no biome's tables; the chosen playable character is
  not persisted and is not what other peers see.
- Visual: every blind judge still fails the Palworld bar on every biome; the Meadows
  ground carries the chroma the creatures should; Cloudreach stand 05 reads flat green;
  Stormwood's Stormheart and forest read as debug geometry.
- Owner-only: the multiplayer LAN and outside-tester sessions, the grass A/B frame-time
  run, player sleep and day/night confirmation on hardware.

## How evidence is produced (D73)

No gate waits on a human. The owner's only act is double-clicking
`tools/owner/KICKOFF.cmd` on a Windows machine with a GPU (the ROG Ally). That
produces the GPU route strip the visual bars are answered on, a real frame-rate
file, the shipped-build verdict and the Gate F chain with video, and pushes it
as `owner-run/<stamp>`. `docs/acceptance/KICKOFF_RUN.md` says what agents do with
a run. Open design questions are decided by the orchestrator and recorded in
`docs/decisions/`; they are not queued for the owner.

For a fast spot-check instead of chapter-acceptance evidence, double-click
`tools/owner/QUICK_TOUR.cmd`: a breadth-first tour of both shipped biomes (the
Meadows and Cloudreach Cliffs), capped at ~20 minutes per biome, that hands back
contact sheets of a handful of locations, a combat moment, the HUD, the menu, a
creature and the player character, plus a short real play check -- not a
replacement for KICKOFF, and it pushes nothing.

## Validation expectations

- Unit: `godot --headless --path . --script tests/run_tests.gd` (≈28 min; use
  `-- --only=file.gd::test` for one).
- Smoke: `godot --headless --path . --script tests/smoke_<name>.gd`.
- Visual: render with `tools/survey.sh` (xvfb, Compatibility renderer) and run the blind
  judge. Never `--headless` with a rendering driver.
- CI: a run under five minutes verified nothing. A full run is 35–45 minutes.
- Import: `godot --headless --path . --import` on a fresh checkout; CI fails on script or
  resource errors.

## Branch rules

Branch from current `main`. `ralph/<TASK>` runs CI and is the shipping prefix;
`claude/<task>` for orchestrator sessions; `scratch/<x>` for throwaways. Never push to
`main`. Land through a pull request whose head commit is code. Confirm with
`git merge-base --is-ancestor`. Full rules: `AGENT_WORKFLOW.md` §5.

## Definition of done

A child task is done when its player-facing acceptance criterion holds on `main`, its
tests pass on first attempt, its visual evidence passes if visual, and the orchestrator
verified it. A gate is done when the continuous player path in `ROADMAP.md` passes with
the evidence template filled in. Code existing is not done.

## Directories

```
autoload/ scenes/ scripts/ shaders/ data/ assets/ addons/   the game (see TECHNICAL_ARCHITECTURE.md)
tests/                                                    unit + smoke suites, fixtures, helpers
tools/                                                    capture, art pipeline, Gate F harness, CI scripts
docs/                                                     this source of truth
ralph/                                                    evidence output root only (ralph/reports/, payload ignored)
archive/                                                  history: old control-plane docs, handovers, report summaries
site/                                                     the download page
```

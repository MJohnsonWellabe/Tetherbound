# Active Tasks — compact Meadows manifest

## STATE AS OF 2026-08-30 — READ THIS BLOCK FIRST

`main` is at `07b3e2aa` (`ralph/LAND-0830B` landed; every 0829/0830 lane
branch is on `main`). The current work map is the coordinator's epic board in
`ralph/START_HERE.md`'s top section, executed by four in-flight lanes:

- **`ralph/T1-HALL-REBUILD`** — Meadows Hall rebuild (owner directive; design
  contract `ralph/reports/HALL_DESIGN_2026-08-30.md`). Blind judge dispatched
  by the coordinator; does not close on a BAD verdict.
- **`ralph/T2-GATEF-RUN4`** — Gate F completion: S03 ghost-placement rig fix,
  trainer_npc dialogue defect (dark-features T1), healthy S03→S09 chain, then
  X04, X07/X08, X01, X06, X05, S10; findings docs rewritten from
  INVENTORY.json; backlog regeneration per protocol §16.2 follows it.
- **`ralph/T3-ACTIVITIES`** — five new optional activities (Lost Creature,
  Broken Cart, Night Watch, River Nest, Meadowhart Herd), orphaned
  elixir/armour reachability, captain second-type rebalance
  (owner-approved 2026-08-29).
- **`ralph/T3-INSTALL`** — owner directive D-0830-2: five installed creature
  meshes wired to the live roster, four variants placed, NPC cast verified in
  world, tonic buff HUD, reader-less-config sweep.

After these land: visual-bar pass (second grass species, seams, stream, aerial
perspective, golden hour, black-NPC closure with luminance evidence, full
capture + blind judge), `roll_new_worlds` flip (D-0830-1, gated on Gate F
re-baseline), then the final continuous full-chapter run against the 3–4h
target and a fresh release.

Gate status corrections that remain true: Gate E PASSES
(`smoke_gate_e_finale.gd` drives real fights through the Warden); Gate F has
run three times (never "not started"). Open flake ticket: `tests/smoke_relay.gd`
~1-in-5 "pressing interact opened nothing", pre-existing before the landing.

---

## STATE AS OF 2026-08-28 — historical

**Everything below the next horizontal rule is dated 2026-08-23 and is
five days stale. It is kept for its P1-P6 package vocabulary and its
evidence trail, NOT as a description of where the project is.** In
particular its line "Gates E/F: not started" is FALSE and has been since
2026-08-26. Do not route off it.

`main` is at `883c0cf3`+. What has actually happened since 2026-08-23:

- **Gate F has run three times.** Run 1 (2026-08-27) captured 8% of what
  it was asked to; Phase B's blind analysis established that the number
  was substantially INSTRUMENT failure, not a verdict on the game. The
  rig was rebuilt twice (`GATE-F-RIG`, `GATE-F-RIG-2`) and run 3 is in
  flight now on `ralph/GATE-F-RUN-3`.
- **The current triaged backlog is NOT this file and NOT `BACKLOG.md`.**
  It is the 13-item, two-tier list in
  `ralph/COORDINATION_2026-08-27_POST_PHASE_B.md`. Several of its items
  are already closed by work landed on 2026-08-27/28.
- **`ralph/BACKLOG.md` is 4,043 lines and ~127 open items, newest dated
  section 2026-08-25.** It is a HISTORY LEDGER. It does not contain the
  2026-08-28 owner playtest, the Gate F findings, or anything landed
  since. Consult it for a selected task; never cold-read it to choose
  one. Per CLAUDE.md that was already the rule — this note records that
  the file is now also materially out of date.
- **A 2026-08-28 owner playtest happened and is canon** —
  `ralph/OWNER_PLAYTEST_2026-08-28.md`. Under CLAUDE.md's precedence it
  outranks every other doc in this repo for what it covers. Six of its
  eight items are fixed and in the published build: grass re-roll, grass
  through buildings, TM orb art, HUD scale, catch/aim feel, and the
  controller throw binding. Two remain open and are in flight: the
  Burrow Warrens payoff, and Warrens/castle presentation.

### Why this file has not simply been rewritten

Gate F's protocol regenerates the backlog rather than appending to it
(§16.2), and its reviewer must receive the run evidence blind — "no
developer commentary, no proposed fixes, no historical backlog" until
the provisional backlog is versioned. Rewriting the task list from Gate
F's in-flight findings before that happens would contaminate exactly the
independence the protocol is built to protect.

So this block fixes the ROUTING, which is a statement of fact about what
landed, and deliberately leaves the BACKLOG CONTENT alone, which is
Gate F's job. When run 3 finishes and its backlog is versioned, this
file and `BACKLOG.md` get reconciled against it in one pass.

### Where current work actually comes from, today

1. `ralph/OWNER_PLAYTEST_2026-08-28.md` — newest owner evidence, wins.
2. `ralph/COORDINATION_2026-08-27_POST_PHASE_B.md` — the live 13-item
   triaged list.
3. `ralph/ACTIVE_GAME_PLAN.md` — gate/package order.
4. `ralph/BACKLOG.md` — ledger, consulted per selected task only.

---

## Historical manifest (2026-08-23) — retained for its package vocabulary

**Current objective:** drive the chapter to a full A–F playthrough.
**Read first:** `ralph/ASSESSMENT_2026-08-23.md` — the full-evidence
reconciliation of every gate against current `main` (b923e202+). It
supersedes the RECONCILE tables this file used to carry; those items are
now individually verdicted there with test/commit evidence.

The weekend sprint overlay (`ralph/WEEKEND_MEADOWS_SPRINT_2026-08-21.md`)
is **retired** — its window ended 2026-08-23. Its SHIP/QUALITY/POLISH
vocabulary is kept below. Model routing note that survives it: blind
visual judging stays independent of whoever produced the frames.

## STATE AS OF 2026-08-23 (post-landing assessment)

`main` at b923e202 carries the full weekend sprint: A/B/C consolidation
plus all five D regions. Suite: 1355 tests, 4 real failures (named
below). The 2026-08-21 owner playtest is substantially resolved — 18 of
26 items verified fixed, most by live smoke passes (see the assessment's
OP21 table before reopening ANY of them).

- **Gate A: effectively recovered.** Residuals are inside P2/P3 below.
- **Gate B: one defect from a full continuous pass.** The run now clears
  Tam (the old blocker), tools, gathering, and Oskar, and stalls at
  **Mira's door** — same root cause, one villager later: the harness
  walks straight lines (`tests/helpers/gate_a_npc_gather_segment.gd`).
- **Gate C: backbone live and exercised.** One shortfall: 2 alphas vs
  prompt 60's "handful".
- **Gate D: D1–D3 pass their evidence criteria; D4 needs one data file;
  D5 passes gameplay, fails visuals.**
- **Gates E/F: not started.**
- **Blind visual critique: both bar questions NO.** The visual bar is the
  largest gap in the game and is now scheduled work (P4), not ambient
  concern.

## Execution packages, in order

### P1 — GATE-B-PATH (SHIP BLOCKER) — the single unlock
Authored waypoints between the opening exit and each villager door, or a
real nav query, in the Gate B harness walk
(`tests/helpers/gate_a_npc_gather_segment.gd:376-408,453-493`). Then run
`tests/smoke_gate_b_continuous.gd` to the end: home build → creature bed
→ sleep → tournament → South Bridge. Gate B passes only on that full
continuous run. Seven prior attempts are tallied in `BACKLOG.md`; none
touched pathing — do not repeat them.

### P2 — RED-TESTS (SHIP/QUALITY) — failing tests are the spec
1. `data/config/bands/band4_upper_meadows_ironwood/harvest.json`: add
   wood/stone/fiber nodes (test: `test_camp_supply_reaches_every_band`).
2. Map fog fresh-save reveal — village + roads revealed, landmarks as
   icons, rest of chapter dark (owner 2026-08-22 ruling; test:
   `test_map_fog`).
3. Wild alphas: field a handful across the chapter, not 2 (test:
   `test_wild_alphas`; prompt 60).

### P3 — LAND-STRANDED + SMALL REAL BUGS (QUALITY)
1. Land `claude/gate-a-core-verbs-8aaw7g`: the OP21-24 chop clip
   (19d7d4a5) and the Gate A checkpoint/lifecycle CI wiring.
2. Black Team Tether NPCs: `npc_ranks.json` grunt/officer palettes crush
   to black through `character_model.gd:386-388`'s albedo×emission
   multiply — brighten toward ~0.7–0.9 luminance or add the emission
   floor `_tether_material()` already uses. Verified by second-path
   render.
3. `tools/survey_band2.gd`: port `capture_band3_region.gd`'s
   pin-then-freeze clock/weather + above-ground player park (its crimson
   frames were this capture bug, not a game bug).

### P4 — VISUAL-BAR (QUALITY BLOCKER, largest) — full-corridor push
From the blind critique (both bar questions NO). Scene-fixable, in
leverage order:
1. Ground cover density + flower drifts — the single biggest lever;
   60–90% of most frames is one flat green material.
2. One daylight colour script across regions (root-cause the blue-grey
   cast seen even at pinned noon).
3. Dress the relay-yard greybox; cluster/de-symmetrise picket, quarry
   and mill props; landmark on band3's dead-stretch horizon.
4. Tether banners/lights/clutter so the stronghold reads occupied.
Needs-art items (creature presentation scale, stronghold model, bark
materials) route to Gate E hero work / owner decisions — do not burn
scene-change rounds on them. Every round: real frames → blind judge →
convergence rule (`ralph/conventions.md`), no round cap.

### P5 — GATE-E (SHIP for the chapter) — the finale does not exist yet
Owner prompt `69-STRONGHOLD-chapter-finale.md`; children 21 (stronghold
materials — also the critique's "toy castle"), 22 (sky planes), 34 (boss
CI flake), 46 (release ceremony), 67 (five-creature bond), 68 (objective
chain), plus Warden fight, tether reveal, legendary choice, world
healing. Evidence run: Hall entrance → gauntlet → recovery → elite →
Warden → tether reveal → free legendary → join offer → release ceremony
→ world healing → post-win acknowledgment.

### P6 — GATE-F — the 3–4 hour integration pass
Prompt `70`. Fresh save, full chapter, chapter-wide tuning (XP, trainer
difficulty, wild levels, resources, travel, encounter density, rest,
objectives, rewards, composition, performance). Cannot be replaced by
green regional branches.

## Standing bookkeeping (POLISH)
- SITE-SHOTS: 3 remaining frames; stale CSS comment re village-square.jpg.
- `tests/fixtures/band_split_baseline/` policy decision.
- D3 dark-band capture artefact (positional) — unexplained, rendering.
- `run_tests.gd` single-file filter flag.
- Branch deletions: `ralph/reports/SUPERSESSION-2026-08-23.md` (needs
  owner/ChatGPT credentials).

## Rules that survive from the retired tables
- A newer owner reproduction reopens anything, whatever DONE.md says.
- Survey-frame defects need a second reproduction path before action.
- Implementation ships via `ralph/<task>` branches + dispatched
  consolidation; check `git log origin/main`, not the CI badge.

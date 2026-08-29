# START HERE — Ralph / Claude on Tetherbound

This is the **single current entry point for autonomous Meadows work**.

If another document looks like a startup guide, milestone guide, handover, or old Ralph manual, do not treat it as current merely because it exists. Start here.

## CURRENT STATE — 2026-08-30 (coordinator update, post-LAND-0830B)

**This section supersedes every dated section below it**, including the
dark-features section immediately following.

- **`main` is at `07b3e2aa` — `ralph/LAND-0830B` LANDED** (fast-forward ref
  push, CI verified at job level: 53 success, 2 expected skips, 0 failures;
  `release.yml` dispatched). It absorbed every remaining lane branch:
  T1-VILLAGE, T1-NIGHT, T1-CAST, T1-HALL, T1-HALL-BUILD, T1-GROUND-2,
  T1-CREATURE-ART, T1-CREATURE-MESH, T1-NPC-CAST, T2-BUILDPLACE, T2-GATEF,
  T2-GATEF-RIGFIXES, T2-S10-COST, T2-RIG10, T3-CREATURES, T3-DENSITY,
  T3-MATCHUPS, T3-SUNSTONE, T3-ENCOUNTER, JUDGE-2, DARK-FEATURES, and the
  coordinator-onboard branch. **No unlanded lane branches remain from the
  0829/0830 cohorts.**
- Dark-features items **O1 and I1 below are CLOSED** by that landing: the
  owner directives (`ralph/OWNER_DIRECTIVES_2026-08-30.md`, D70, the
  creature-expansion brief) are on `main`, and the Sunstone + elixir-cache
  additive conflict resolution was verified to keep both.
- **Four lanes are IN FLIGHT** (trigger-fired sessions, coordinated by the
  "Tetherbound coordination and roadmap" session, which holds sole landing
  rights):
  `ralph/T1-HALL-REBUILD` (Meadows Hall rebuild per
  `ralph/reports/HALL_DESIGN_2026-08-30.md`),
  `ralph/T2-GATEF-RUN4` (Gate F completion + rig fixes; owns dark-features
  T1, the trainer dialogue defect),
  `ralph/T3-ACTIVITIES` (five new optional activities, reward reachability,
  captain rebalance — owner-approved 2026-08-29),
  `ralph/T3-INSTALL` (owner directive D-0830-2: creature expansion, variants,
  NPC cast verification, tonic HUD, config sweep).
- `roll_new_worlds` (D-0830-1) stays OFF until Gate F re-baselines; the
  coordinator sequences it after `T2-GATEF-RUN4` lands.
- Known pre-existing flake, not a landing blocker: `tests/smoke_relay.gd`
  fails ~1-in-5 with "pressing interact opened nothing"; reproduced on
  unmerged main before the landing. Root cause unknown — open ticket.
- Correction to a claim further down: `ralph/COORDINATION_2026-08-27_POST_PHASE_B.md`
  was **not** removed; it exists and is still cited.

### Historical: dark-features inventory (partially superseded above)

**This section supersedes every dated section below it.** They are kept as
history; do not open the lanes they name, and do not trust their `main` SHA.

### Open work: the dark-features inventory

`ralph/reports/DARK_FEATURES_INVENTORY_2026-08-30.md`, on branch
`ralph/DARK-FEATURES`, is the audited list of everything **built but
unreachable in play** — the owner's 2026-08-30 directive, *"if we built it,
turn it on, put it on the game, make it playable."*

**Nine open items, ranked by player impact.** Each says what it is, where it
lives, what it would take, and what was actually verified. Read it before
opening an install lane; it is the current install work list. It is deliberately
**not** appended to `ralph/BACKLOG.md` — Gate F regenerates that file and its
reviewer must receive the run evidence blind (protocol §16.2), so appending
would contaminate it.

Highest-priority open items, in order:

| id | open item | first blocker |
|---|---|---|
| **O1** | The owner's 2026-08-30 directives, D70, and the creature-expansion brief exist **only** on `claude/tetherbound-coordinator-onboard-7pz3ah`, unmerged. The repo's top-precedence document is invisible from `main`. | land or cherry-pick those three docs |
| **I1** | `ralph/T3-SUNSTONE` conflicts with landed `T3-PICKUPS` in `playground_world.gd`. The conflict is **purely additive**, so `--ours`/`--theirs` silently deletes either the Sunstone (Ashtusk becomes unreachable) or the elixir cache, with no test to catch it. | must be handled **during** the landing |
| **T1** | `can_challenge()` returns false for four distinct reasons and `trainer_npc.gd:172` collapses them into one, so all 27 trainers — the Warden included — can speak their post-defeat line before being beaten. | needs a third conversation state (~27 lines) |
| **E1** | `roll_new_worlds` ships `false`; the whole rolled-world system is reachable only via `TB_WORLD_SEED`. Owner wants it ON. | **precondition:** Gate F re-baselines first (D-0830-1) |
| **C1** | Four fully-authored species in `data/creatures/species_pending.json`, which has zero code readers. Takes the Ice type and four moves with it. | blocked on a Meshy generation; **no mesh exists** |
| **B1** | Tonic buffs apply real stat scaling and the HUD never shows them. | a buff indicator was never built |
| **P1 / K1 / Z1** | 18 config keys with no reader (incl. three ROG collision-streaming levers whose doc comment falsely claims they are tunable), plus dead code and orphan assets. | each is wire-it-or-delete-it |

**Closed by that lane:** **D1** — the four Aspect variants (Nightburrow,
Stormtrail, Riftfrill, Ashtusk) were rendering in their base species' textures.
Fixed in `6698ad3d`; **cherry-pick that SHA**, do not land `ralph/DARK-FEATURES`
as an integration branch (its merges exist only to anchor the fix).
**A render pass is still owed on it** — the wiring is verified, nobody has
looked at it.

⚠️ Nothing in that report was confirmed by running the game; its author had no
Godot. Two items (D1, T1) name the specific play-test that would confirm them.

---

### Carried forward from 2026-08-29 — still current except where noted

⚠️ **The `main` SHA in the next paragraph is stale, and so was this
paragraph's own earlier text**: `main` is now `07b3e2aa` (`ralph/LAND-0830B`
landed — see the current-state section at the top). No lane branches from the
0829/0830 cohorts remain unlanded.

`main` was at `961a8c02` at the end of the 2026-08-29 production day.
**`ralph/LAND-0829B` carries every lane branch in the repo** and was awaiting
a job-level-green CI verdict when this was written — check whether it landed
before assuming `main` is current.

**Read these, in this order, before selecting work:**

1. `CLAUDE.md`
2. `docs/owner-direction/README.md` and BOTH documents it points to — the
   three production tracks. Read them in full; two coordinators in a row were
   corrected for skimming exactly these.
3. **`ralph/STATE_OF_THE_THREE_TRACKS_2026-08-29.md`** — the evidence-backed
   current state of the game against those three tracks. Start here for
   "what is actually true right now".
4. `ralph/COORDINATOR_HANDOVER_2026-08-29-B.md` — traps, mistakes worth not
   repeating, and how to land an integration branch safely.
5. `ralph/OWNER_FEEDBACK_2026-08-29_BUILDINGS.md` and
   `ralph/OWNER_PLAYTEST_2026-08-28.md` — newest owner evidence. Under
   `CLAUDE.md`'s precedence these outrank every other doc for what they cover.
6. `ralph/ACTIVE_GAME_PLAN.md` — gate and package order.

**No lanes are in flight.** Every lane was stopped and archived on 2026-08-29;
each left a handover at `ralph/reports/handover-*-2026-08-29.md`. **Read those
before restarting anything** — several found things not visible in their diffs.

**The live owner directive:** the Stronghold and Meadows Hall become ONE
location, redesigned from scratch, with Fable doing the design. See the
cross-track section of the state document for the measured geometry, what
reference art exists, and the two questions the owner has not yet answered.

---

## Superseded — CURRENT STATE 2026-08-28

**Kept as history. The section above supersedes this one.** Its `main` SHA is
stale, the four lanes it lists are all archived, and
`ralph/COORDINATION_2026-08-27_POST_PHASE_B.md` was removed in the 2026-08-29
documentation cleanup (recoverable from git history).

`main` is at `883c0cf3`+. A Windows build of it is published and
playable at the repo's `latest` release tag.

**Read these, in this order, before selecting work:**

1. `CLAUDE.md`
2. `ralph/OWNER_PLAYTEST_2026-08-28.md` — newest owner-play evidence.
   Under CLAUDE.md's precedence it outranks every other doc in this repo
   for what it covers.
3. `ralph/ACTIVE_TASKS.md` — read its 2026-08-28 block at the top. The
   rest of that file is stale and says "Gates E/F: not started", which
   is false.
4. `ralph/COORDINATION_2026-08-27_POST_PHASE_B.md` — the live 13-item
   triaged backlog, in two tiers.
5. `ralph/ACTIVE_GAME_PLAN.md` — gate and package order.

**Lanes in flight as of 2026-08-28 19:20 UTC.** Check each is still live
before duplicating its work:

| branch | scope |
|---|---|
| `ralph/GATE-F-RUN-3` | Gate F run 3 — evidence split extended to every segment, then the logic lanes |
| `ralph/CONTENT-0828B` | Burrow Warrens payoff, and the constructed-interior method (Warrens + castle) |
| `ralph/GRASS-FAR` | a cheap distant tier past the 72m grass cutoff — owner-approved 2026-08-28 |
| `ralph/GOLDEN-HOUR` | golden hour renders pure black; investigate before fixing |

**Two standing owner constraints that bind any lane touching them:**

- **Do not change the look of the near grass.** Owner, 2026-08-28: "don't
  change the look of my grass. it's awesome." The distant-tier work is
  scoped to beyond 72m for exactly this reason.
- **Do not fix the golden-hour frame blind.** Owner asked for the
  decisive test first. `ralph/reports/finding-golden-hour-black-frame.md`
  has three hypotheses already ruled out.

**On the backlog.** Gate F REGENERATES the backlog rather than appending
to it (protocol §16.2), and its reviewer receives the run evidence blind.
`ralph/BACKLOG.md` — 4,043 lines, ~127 open items, newest section
2026-08-25 — is a history ledger and is materially out of date. Consult
it for a task you have already selected; never cold-read it to choose
one. It gets reconciled once run 3's backlog is versioned.

---

## CURRENT STATE — 2026-08-25, two lanes open

Read `ralph/HANDOVER_2026-08-25_CI_GREEN_AND_TWO_LANES.md` first. It records
that the two-day-red CI-consolidation branch is now green and merged to
`main`, and routes the very next coordinator session into two concurrent
lanes: **Gate F** (`ralph/GATE_F_PROTOCOL.md` — the owner's authoritative
full-game playtest and backlog-regeneration protocol) and **WORLD-GRASS**
(`docs/ralph-prompts/72-WORLD-ground-cover-and-mid-layer.md` — the ground
plane/grass visual work, owner-directed). Open exactly those two lanes next;
do not fall back to package selection below until both are underway or the
handover says otherwise.

## CURRENT STATE — post-sprint assessment, 2026-08-23

The weekend sprint overlay (`ralph/WEEKEND_MEADOWS_SPRINT_2026-08-21.md`)
is **retired**; its window ended 2026-08-23 and its output is on `main`.

Current ground truth is `ralph/ASSESSMENT_2026-08-23.md` — a full
evidence reconciliation of every gate against the landed `main`. The
current work manifest derived from it is `ralph/ACTIVE_TASKS.md`
(packages P1–P6, ending at the Gate F integration playthrough). Read
those two before selecting any work; do not re-derive verdicts they
already carry evidence for.

## 1. Read order

A fresh coordinator or lane should establish context in this order:

1. `CLAUDE.md` — hard rules and agent contract.
2. `docs/TETHERBOUND_GAME_VISION.md` — what the finished Meadows game is supposed to feel like.
3. `ralph/ASSESSMENT_2026-08-23.md` — evidence ground truth for every gate.
4. `ralph/ACTIVE_GAME_PLAN.md` — gameplay gates and regional execution order.
5. `ralph/ACTIVE_TASKS.md` — compact current work manifest for the active gate.
6. newest `ralph/OWNER_PLAYTEST_*.md` first — newest owner-play evidence wins where old wording/tests conflict; read older owner playtests only as needed for history/context.
7. `ralph/PROMPT_COMPATIBILITY_MAP.md` — prevents duplicate implementations from overlapping historical prompts.
8. `ralph/conventions.md` — branch, testing, visual-judge, and shipping rules.
9. Only then read the **specific detailed prompt(s)** and the **specific code/spec sections** needed for the selected work.

Do **not** cold-read all of `BACKLOG.md`, `DONE.md`, or every prompt file. They are reference/history stores, not the startup briefing.

## 2. Decide your mode

### Coordinator
Read `ralph/COORDINATED_RUN.md` after the files above. The coordinator:

- reconciles the active gate against current `main`;
- applies the SHIP BLOCKER / QUALITY BLOCKER / POLISH prioritization from ACTIVE_TASKS;
- keeps the full fresh-save Meadows chapter as the critical path;
- chooses the highest-impact incomplete work;
- launches 3–5 non-conflicting lanes when useful;
- allows safe later-gate implementation in parallel when it does not steal capacity from blocking work;
- owns cross-lane file exclusions and package-level integration;
- verifies what actually landed on `main`;
- runs the full gameplay evidence segment before declaring a gate complete;
- produces integrated playable checkpoints rather than disappearing into one giant task.

### Implementation lane
Read `ralph/PROMPT.md` after the files above. A lane:

- receives one concrete child task/package;
- inspects current `main` before editing;
- implements only that coherent scope;
- tests it;
- pushes a `ralph/<task>` branch;
- records useful findings;
- does not redefine the active game plan or discard owner requirements;
- checkpoints rather than expanding beyond a bounded task indefinitely.

## 3. How work is selected

`ralph/ACTIVE_TASKS.md` (packages P1–P6, derived from the 2026-08-23 assessment) decides **current production priority and safe parallelization**.

`ralph/ACTIVE_GAME_PLAN.md` decides **canonical gameplay gate/package ownership and acceptance order**.

`ralph/ACTIVE_TASKS.md` gives the compact current manifest.

The newest owner playtest files are authoritative evidence. A fresh owner reproduction reopens an older supposedly-fixed item when they conflict.

`ralph/BACKLOG.md` is the complete ledger and remains authoritative for whether an old task exists, but it **does not control current Meadows priority** when the active plan/sprint groups or reorders that work.

Detailed files under `docs/ralph-prompts/` explain individual implementation requirements. Read only the prompt(s) relevant to the current task/package.

When two prompt files overlap, use `PROMPT_COMPATIBILITY_MAP.md`; implement once, preserving any unique acceptance detail.

## 4. Definition of progress

A commit is not the unit of progress.

A child task can be complete when its own acceptance criteria are verified on `main`.

A gameplay package/gate is complete only when the **continuous player path** named in `ACTIVE_GAME_PLAN.md` passes.

For every gameplay gate/package, verify:

- player purpose is clear;
- core inputs/interactions remain reliable;
- team progression makes sense;
- wilds/trainers/resources/detours/rest opportunities create meaningful choices;
- long dead-travel intervals are identified and fixed when they are not intentional breathing room;
- regional presentation is readable and coherent;
- save/progression/gates work through the whole segment;
- relevant controller, smoke, render, visual-judge, and performance checks pass;
- player-facing systems are proven in the integrated production path, not only isolated unit/smoke tests;
- target-hardware/ROG evidence is used where the acceptance depends on handheld controls or performance.

Do not wait for owner approval between evidence gates. Fix the segment and continue automatically. Ask only for a genuinely unresolved design decision.

## 5. Current chapter flow

The canonical Meadows build progresses:

**Gate A — trustworthy core verbs**
→ **Gate B — fresh start through village tournament**
→ **Gate C — progression/reward/trainer/wild/rest backbone**
→ **D1 — Lower Meadows**
→ **D2 — Quarry / Burrow Warrens**
→ **D3 — River / Tether Relay**
→ **D4 — Upper Meadows**
→ **D5 — Stronghold Approach**
→ **Gate E — Stronghold / Warden / legendary finale**
→ **Gate F — full 3–4 hour Meadows integration playthrough**.

Implementation may overlap across gates where dependencies/file ownership are safe, but a gate is not declared passed until its canonical evidence criteria are met.

The stop condition is not an empty task list. It is a complete Meadows chapter that passes the vision and Prompt 70.

## 6. Reference/history — read only when needed

These files remain useful but are **not startup documents**:

- `ralph/BACKLOG.md` — complete historical/current ledger; targeted lookup only.
- `ralph/DONE.md` — large completion archive; search for a task/commit, never read end to end.
- `ralph/BLOCKED.md` — parked work and reasons.
- `ralph/MANUAL.md`, `ralph/KEYED_PROMPT.md`, `ralph/LANE_PROMPT.md` — legacy operating material; current coordinator/lane rules are in `COORDINATED_RUN.md` and `PROMPT.md`.
- dated `HANDOVER-*` files — historical snapshots.
- `GODOT_AND_CLAUDE_START_HERE.md` — human Godot setup, not autonomous task selection.

Git history preserves superseded operating instructions. Do not carry obsolete process forward merely because an old document described it.
# Roadmap — the next several days, as sequential gates

**Status:** canonical execution order, 2026-09-02 reset. Supersedes
`ralph/ACTIVE_GAME_PLAN.md` (archived at `archive/ralph/ACTIVE_GAME_PLAN.md`) as the
routing document. The gate *definitions* from that plan are preserved below in
condensed form; what changed is the order, the evidence bar, and the merging of Gates A
and B into one "first session" gate because the code for both exists and only proof of
play is missing.

The binding rule is unchanged:

> A region or system is not done because code and data exist. It is done when the
> complete player path produces the intended Tetherbound experience.

Detailed implementation contracts still live in `docs/prompts/` (formerly
`docs/ralph-prompts/`). Each gate below names the prompts it consumes.

---

## Gate 0 — Repository reset (this session)

Objective: make the project cheaper and safer to develop. Outcome: one documentation
source of truth under `docs/`, historical material under `archive/`, evidence payloads
out of the tree, the CI docs-only skip diffing against `main`, an accurate
`docs/CURRENT_STATE.md`. Definition of done: this file and `docs/00_START_HERE.md` are
what a fresh agent reads; the game imports, the unit suite and the player-path smokes
run from the reorganised tree. See `docs/CLEANUP_MANIFEST.md`.

---

## Gate 1 — The first session is real (wake → tournament → leave)

**Owning prompts:** `56-OPENING-first-session-to-tournament.md`, with
`17-RG18`, `15-RG16`, `26-RG19`, `43-CREATURE-BED`, `44-GATHER`, `45-CATCH`,
`47-CREATURE-level-up`, `48-PARTY-cycle`, `68-CHAPTER-complete-objective-chain.md`
(opening rungs only).

**Objective.** A fresh save plays continuously from Grandpa's house through the village
tournament to the "leave for the South Bridge" objective, with every core verb reliable,
without external instructions, on a controller.

**Player-facing outcome.** The opening-to-tournament segment feels like a small complete
game: catch a team, fight, level up visibly, gather, build a tent/campfire/bedroll, rest
a creature and yourself, understand what "train" means, win the tournament.

**Why first.** The tournament, the opening, building, rest and catching are all
implemented and their smokes pass, except the opening segment itself, which is red on
`main` today. Nothing later in the chapter is worth polishing while the first thirty
minutes can dead-end.

### Tasks (bounded; one agent each unless noted)

| # | Task | Tier | Owns | Evidence |
|---|---|---|---|---|
| 1.1 | **Opening orb floor.** `tests/smoke_gate_a_opening_segment.gd` fails: throwing the last orb in the tutorial catch empties the satchel and the opening dead-ends (`opening.json` `catch_orb_floor` does not apply). Root-cause and fix. | Sonnet | `scripts/story/`, `scripts/combat/throw_aim.gd`, `data/dialogue/opening.json`, that test | smoke green; a probe that drains to 0 orbs and shows the floor refilling |
| 1.2 | **South Bridge entombment** at (7.9, −3.4, 1319): the player capsule settles inside geometry 11 m short of the bridge. World/collision fix, not a harness fix. | Sonnet | terrain/collision near the bridge (`scripts/world/south_bridge.gd`, `gated_crossing.gd`, `world_perimeter.gd`), `data/config/terrain_playground.json` | probe placing the player on an 8-bearing ring around the site with zero depenetration events; `smoke_traversal` passes on attempt 1 |
| 1.3 | ~~**Bram's shop exit** clips furniture on the straight-line walk out.~~ **DONE, BRAM-EXIT-0903.** Bram is in `inn_interior.gd`, not `shop_interior.gd` (which is Mira's) — the existing exit probe never covered his room. Real-input walks from every furnished pocket clear the doorway (`tools/gate_f/probe_inn_exit_clearance.gd`, 6/6), and `smoke_gate_b_continuous.gd` shows all three Bram cycles exiting cleanly. The regain-door-axis fix already in `gate_a_npc_gather_segment.gd::_exit_through` was sufficient; it had just never been verified against the real site. No code change needed. | Sonnet | `scripts/world/inn_interior.gd`, `tools/gate_f/probe_inn_exit_clearance.gd` | interact-driven exit lands outside the doorway 10/10 — **met** |
| 1.4 | **MAIN STORY label truncation at 1280×800** ("Train with your team before the …"). | Haiku | `scripts/ui/playground_hud.gd` objective card only | handheld legibility smoke at 1280×800 shows the full sentence |
| 1.5 | **Terrain bake freshness guard** for `data/terrain/playground` (the scatter guard exists; the terrain one does not). | Sonnet | `tests/`, `scripts/world/build_playground_terrain.gd` fingerprint | a CI job that goes red when `terrain_playground.json` routes move without a rebake |
| 1.6 | **Harness slot-offset sweep.** Convert fixed hotbar/inventory slot lookups in `tools/gate_f/` and `tests/helpers/` to lookup-by-identity. | Haiku | those two trees only | grep shows no `hotbar_<n>` literals; S01–S03 segment scripts still pass |
| 1.7 | **First-session evidence run.** Play the Gate 1 path continuously with the real interact-driven harness (`tests/smoke_gate_b_continuous.gd` and Gate F S01–S03), record the evidence template (§ Evidence template), fix the highest-impact failure, replay. | Fable directs, Sonnet operates | read-only on code; findings go to CURRENT_STATE | segment PASS with the template filled in |

Parallel workstreams: 1.1, 1.2, 1.3, 1.4 touch disjoint files and run at once. 1.5 and
1.6 run beside them. 1.7 starts when 1.1 lands and repeats after each landing.

Integration sequence: one consolidation branch per day at most; land through a PR whose
head commit is code, confirm the code jobs ran (35–45 min), then `merge-base` check.

### Acceptance

- `smoke_title_new_game`, `smoke_opening`, `smoke_gate_a_opening_segment`,
  `smoke_gate_b_continuous`, `smoke_post_modal_control`, `smoke_menu`,
  `smoke_gate_a_build_house`, `smoke_gate_a_rest_torch`, `smoke_catching`,
  `smoke_tournament_bracket`, `smoke_traversal` all green **on first attempt** (no
  retry rescue) on the landing commit.
- The evidence template for the segment is filled and reads as the intended experience:
  the player always knows the current goal; at least one level-up is communicated;
  building the camp is fast; creature rest has a visible purpose and a visible progress
  indicator; the tournament is the payoff.
- One owner playtest on the ROG Ally of the released build confirms: interact reliability,
  frame rate with grass on, player sleep, day/night advancing. These four cannot be closed
  from a container and are **not** blockers for starting Gate 2, but they are blockers
  for calling Gate 1 done.

Git checkpoint: tag `gate1-candidate` on the landing commit; `docs/CURRENT_STATE.md`
updated with the evidence summary.

---

## Gate 2 — The core world is complete: village → Pond → South Bridge

**Owning prompts:** `62-BAND1-finished-lower-meadows.md`, `71-GATEA-opening-environment-baseline.md`,
`72-WORLD-ground-cover-and-mid-layer.md`, `53-MEADOWS-pokemon-first-core-loop-density.md`,
`60-WILD-ecology-journey.md` (Band 1 only), `59-TRAINER-journey.md` (Band 1 only),
`30-CONTENT-ACTIVITIES` (one Band 1 activity).

**Objective.** The world from Grandpa's Village to the Pond and on to the South Bridge
reads as a designed place, not traversable acreage: composed sightlines, tree groups with
real silhouettes, a mid-layer between grass and canopy, readable trails, landmarks that
pull the eye, creatures that are visible and worth wanting, gathering that has a known
use, one optional discovery, one memorable encounter, and no dead-travel interval over
~60 seconds.

**This is where "the world becomes complete" for the core region.** Bands 2–5 become
complete one at a time in Gate 3, using the same standard.

### Tasks

| # | Task | Tier | Notes |
|---|---|---|---|
| 2.1 | **Composition design pass** for the Band 1 route: per-stand foreground/mid/distant plan for village approach, route out, Pond pocket, the Rise, the bridge approach. One authored document with eye/look pairs and what element sits at each depth. | **Fable** | `docs/VISUAL_BIBLE.md` §3 layering pillar; judged blind against the key art; a design output, not a tuning round |
| 2.2 | **Mid-layer vegetation**: bushes/saplings/rock lines between grass carpet and canopy, clustered by the 2.1 plan, band-1 `vegetation.json` only, re-bake included. | Sonnet | perf proxy within budget (`band1_open ≤ 7500 draws`) |
| 2.3 | **Tree silhouette variety**: use the installed nature family's asymmetric forms and scale variation so canopies stop reading as repeated puffballs. No new meshes. | Sonnet | blind judge names silhouette as improved |
| 2.4 | **Creature legibility in habitat**: material value/saturation, ground-contact shadow or rim, spawn siting out of shrubs. Owner directive: creatures loom; do not shrink them. | Sonnet | Bramblebun-vs-ground luminance ratio ≥ 1.5:1 at 30 % scale |
| 2.5 | **Band 1 ecology and trainers**: the practice meadow, the Pond pocket, the Rise, the bridge approach each have an authored wild set with one "temptation" creature and one trainer with a reason to be there. | Sonnet from a Fable contract | evidence template: at least one roster decision in play |
| 2.6 | **Points of interest**: one optional discovery off the route with a real reward (TM, recipe, cache), signposts legible at 1280×800, trails visible on the map. | Sonnet | `52-MAP-all-authored-trails-visible` acceptance |
| 2.7 | **Night legibility**: fill floor for unlit camps; night creature meshes lit like humans. | Sonnet | night frames keep midground readable; measured medians |
| 2.8 | **Gate 2 evidence run**: tournament victory → explore Lower Meadows → detour → earn/open South Bridge. | Fable + Sonnet operator | template PASS; dead-travel intervals listed |

Parallelism: 2.2/2.3 (vegetation files) serialize with each other; 2.4 (creature
materials) and 2.5/2.6 (band data) run in parallel with them. 2.1 precedes 2.2–2.6.

### Acceptance

- Blind judge on the five survey stands plus village and bridge approach: Bar A yes;
  Bar B "trying to be the same kind of game" on composition and density, with remaining
  gaps named as art-not-in-build.
- Evidence template PASS; no dead-travel interval over ~60 s that is not intentional.
- Perf proxy within the provisional budget; the owner's Ally frame-rate check on the
  released build.

Checkpoint: tag `gate2-candidate`; `docs/VISUAL_BIBLE.md` gap list updated.

---

## Gate 3 — Chapter bands complete, one segment at a time

**Owning prompts:** `63-BAND2`, `64-BAND3`, `65-BAND4`, `66-BAND5`,
`69-STRONGHOLD-chapter-finale`, plus `57-TEAM-progression-curve`, `58-REWARD-resource-economy`,
`61-EXPEDITION-rest-rhythm`, `67-FIVE-creature-pressure-and-bond`.

**Objective.** Each band passes the Gate 2 standard and its Gate F segment (S04–S10)
individually before any continuous run is attempted: South Bridge → Quarry → Warrens →
River → Relay → Upper Meadows → Sigils → Stronghold approach → Hall → Warden → legendary
→ release ceremony → world healing.

Method: run one segment with the Gate F harness, fix every real failure, re-converge
that segment alone, advance; never skip ahead. The band-to-band sameness the judges
named is addressed here per band (terrain toughening, kit variation, drained-land
grammar near Team Tether) — as composition work, not global shader passes.

Fable owns: encounter identity (guardian, Captain Vance, the three captains, the
Warden), pacing per band, the roster-pressure moment before the legendary. Sonnet owns
implementation slices per band with explicit file ownership.

Acceptance per band: evidence template PASS; the finished-region checklist in
`docs/GAME_VISION.md` §8; blind judge per band.

Checkpoints: tag `band2-candidate` … `band5-candidate`, `finale-candidate`.

---

## Gate 4 — Full chapter integration, pacing and hardware performance

**Owning prompt:** `70-MEADOWS-full-chapter-integration-playthrough.md`, with
`36-R9.1`, `37-R9.2`, `38-R9.3`.

One continuous S01–S10 run under the Gate F protocol
(`docs/acceptance/GATE_F_PROTOCOL.md`), then tuning: XP curve, trainer difficulty, wild
levels, resource availability, travel time, encounter density, camp usefulness,
objective clarity, reward economy, target-hardware performance on the ROG Ally. Do not
cut required chapter beats to hit the 3–4 hour clock.

Definition of Meadows completion: `docs/acceptance/MEADOWS_EXIT_CRITERION.md`.

---

## Where the tournament belongs

The village tournament is **implemented and passing** its simulated playthrough
(`tests/smoke_tournament_bracket.gd`: entered, lost, retried, fought through three rounds,
won). Its entry level is 5 and Halda's guidance is concrete. It is the payoff of the first
session, so it belongs in **Gate 1**, before world completion — not as its own gate, and
not after Gate 2. What remains is proof by continuous play and one owner confirmation,
not construction.

## When does the world become complete?

- **Village → Pond → South Bridge:** at the end of **Gate 2**, by the standard above
  (composition, mid-layer vegetation, silhouettes, visible creatures, authored ecology
  and trainers, one discovery, legible signposts and trails, night legibility, budgeted
  performance).
- **Bands 2–5 and the Hall:** one band at a time in **Gate 3**, each to the same
  standard, each with its own segment evidence.
- The world is not complete when scatter density is high. It is complete when a blind
  judge and the evidence template both say the route reads as designed and the player is
  never running through empty scenery for long.

## What not to spend time on yet

- Biome 2 in any form.
- New creature or character meshes, or Meshy generation (hard rule; also the judges'
  "needs art not in the build" list is deferred by design).
- Global shader or lighting passes "to get closer to the key art" — each remaining gap
  has a named mechanism; tune that mechanism or restart it, do not re-tune globally.
- A weather-effects system, villager walkers, photo mode, fast travel.
- Splitting the five largest scripts. They are large but single-purpose and tested;
  split only when a task actually needs to touch them in two places at once.
- Re-running the whole-game visual census. Six confirmed items came out of 168; work
  from the gap list in `docs/VISUAL_BIBLE.md` instead.

## Evidence template (per segment)

Record, in `docs/CURRENT_STATE.md` under the gate:

- **Player purpose:** what the player is trying to do; what visible challenge they are
  preparing for.
- **Team progression:** party composition/levels/condition at start and end; whether a
  meaningful catch/switch/roster decision occurred.
- **World interaction:** wild encounters, trainers, gathering, detours, camp/rest
  opportunities, objective transitions.
- **Empty travel:** longest interval without a gameplay or visual pull, and whether it
  was intentional.
- **Reliability:** freezes, input loss, broken gates, bad collision, save/load failures,
  controller failures.
- **Presentation:** region identity, open vs lush composition, landmark readability,
  night/day usability, UI readability.
- **Decision:** PASS only if the segment produces the intended experience; otherwise the
  highest-impact cause and the replay.

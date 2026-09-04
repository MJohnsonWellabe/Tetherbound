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
| 2.8 | ~~**Gate 2 evidence run**: tournament victory → explore Lower Meadows → detour → earn/open South Bridge.~~ **DONE, GATE2-EVIDENCE-0903.** The route was played continuously for the first time (Gate F S04+S05, 1,169 s play, 2,360 m, 82P/1F and 106P/1F), four blockers fixed to make it playable at all, dead-travel intervals listed, perf re-confirmed. **Verdict: the gate FAILS its acceptance**; follow-ups are 2.9–2.14 below and the report proposes a correction to the acceptance bar itself (see §Acceptance). `ralph/reports/GATE2-EVIDENCE-0903/REPORT.md`. | Fable + Sonnet operator | template filled in `docs/CURRENT_STATE.md` §5; two dead-travel intervals over 60 s (63 s and 71 s), none over 75 s — **met** |
| 2.9 | **The walker cannot leave the Pond basin.** `stick_navigator.gd` freezes a real body at (−328.7, −14.2, 505.3) for 543 s with locomotion enabled, driving straight at a target across the basin's shoulder. `tools/gate_f/probe_pond_stranding.gd` proves the world is passable (0/10 stands wedged, 12–17 m per stick push, touching only Terrain3D). Root-cause the walker on a long uphill bearing. Do **not** fix it by teleporting past geometry, and do not remove `S05-32x` until it is fixed. | Sonnet | the probe's ring passes unchanged, and S05 with `S05-32x` removed reaches Old Bram inside its budget |
| 2.10 | **Post-tournament recovery is not a designed beat.** The three rounds reliably leave 3 of 5 creatures on 0 HP, and there is no recovery between the arena and the South Bridge gatekeeper; the game's own refusal line ("a bed will do it, or something to eat") also misdescribes the real block. Decide whether the champion beat restores the team, whether Halda or Mira provide recovery, or whether the Trail Camp becomes the authored rest stop. | Fable contract, Sonnet implements | a played route from tournament victory to the bridge with no menu recovery block reaches a startable fight |
| 2.11 | **Re-deploying a revived creature.** A creature revived from the Satchel is not sent back out, so `can_challenge()` stays false with a healthy party — both Band 1 fights refused to start until a `creature_recall` press was added. Confirm whether the shipped game re-deploys on revive; if not, it is a player-facing trap, not a harness one. | Sonnet | a probe that faints the active creature, revives it through the real menu, and gets a startable trainer fight without pressing recall |
| 2.12 | **One roster decision on the Band 1 route.** 2.5's own acceptance asks for a roster decision in play; the played route produced mid-fight rotation but no catch and no keep-or-release moment between the tournament and the bridge. Site the "temptation" creature so the direct route actually meets it. | Sonnet from a Fable contract | the evidence template records a catch or a considered refusal on the direct route |
| 2.13 | **Props, structures, palette and terrain form** — the residual half of the blind-judge gap that no vegetation, creature or night task can reach (see §Acceptance), now itemised by 2.8's own code-blind pass on played-route frames. Scene work: grow the trees to 12–18 m against the 1.80 m trainer and fix the trunk-to-height ratio (grow, never shrink); cluster the tree lines with clearings and a mouth, ≥3× scale variance per prop family; pull the grass highlight off acid lime; **re-reserve the red family — oxblood has leaked onto village roofs, tree trunks and friendly HUD icons while the Team Tether grunt wears unrelieved black**; push the fog far plane out; replace the blob shadow decal with one carrying canopy shape; stop the camera rendering from inside a bush at (−333, 510); fix Halda's plank/torso intersection and the terrain-blend patch seam; connect or remove the orphan fence segments; the mill's sails; signposts; the smooth dome hill; water shading. **Needs art, and should be costed rather than attempted: a built South Bridge with Team Tether presence** (it currently renders as a bare plank frame with no gate, banner or guard — the chapter's first physical gate), one Meadows landmark to navigate by, tree meshes with branch structure below the canopy, and combat/reward VFX. | Sonnet slices from a Fable composition contract | blind judge names each addressed item as improved, on the same played-route stands |
| 2.14 | **Stale trace-length thresholds.** `S04-61` wants 1,200 route rows of a 406 s segment and `S05-61` 3,000 of a 763 s one; at 2 Hz those describe durations neither segment has any more. Re-derive both from the segments' real play clocks. | Haiku | both segments green with the trace still asserted |
| 2.15 | **The visual evidence pipeline cannot show a creature.** Four independent blind passes in a row (MID-LAYER, TREE-SILHOUETTE, its after-fix pass, and 2.8's) have answered Bar B "no" partly because no evidence set this project produces puts a creature in frame at size — and Bar B is the creature-collection question. 2.8's own capture lane teleports to traced positions without restaging, so its two creature-forward stands show empty ground where telemetry proves fights ran, and it never deploys a companion. Make the survey and capture lanes stage what they photograph: a deployed companion beside the trainer, a fight frame that contains a fight, nameplates/level tags where the game has them. | Sonnet | a blind pass whose set contains a creature at readable size beside the 1.80 m trainer, and a fight frame with a live opponent |
| 2.16 | **Bramblebun's daylight palette overshoot.** `CURRENT_STATE` §3 carries an open item that 2.4's raise of `field_emission` 0.9 → 2.5 makes Bramblebun read as a glowing pink blob **at night**. 2.8's blind judge, on morning frames, independently called the same creature "candy pink" — so the raise overshot in daylight too, which the ledger did not know. Fold this into whichever lane takes the time-of-day scaling that item already prescribes. | Sonnet | measured grass-separation still ≥ 1.5:1 with the judge no longer naming the coat as candy-coloured, day or night |

Parallelism: 2.2/2.3 (vegetation files) serialize with each other; 2.4 (creature
materials) and 2.5/2.6 (band data) run in parallel with them. 2.1 precedes 2.2–2.6.

### Acceptance

- Blind judge on the five survey stands plus village and bridge approach: Bar A yes;
  Bar B "trying to be the same kind of game" on composition and density, with remaining
  gaps named as art-not-in-build.
- Evidence template PASS; no dead-travel interval over ~60 s that is not intentional.
- Perf proxy within the provisional budget; the owner's Ally frame-rate check on the
  released build.

**Status after 2.8 (GATE2-EVIDENCE-0903, 2026-09-03): not met.** Dead travel passes (two
intervals over 60 s, 63 s and 71 s, none over 75 s); the perf proxy passes (`band1_open`
6,891 draws / 10.79 M primitives against 7,500 / 12.0 M); reliability of the played path
passes. The blind-judge clause and 2.5's roster-decision clause do not.

**The blind-judge clause is also partly mis-specified, and 2.8 was asked to say so.** Every
blind pass run against this gate's task list — MID-LAYER's, TREE-SILHOUETTE's, and its own
after-fix pass — answers **no / no**, and each names the same residual causes: props and set
dressing, the disconnected fence segments, signposts, the mill's missing sails, flat water,
lighting, and terrain form. **None of those is inside any of 2.2–2.7's scope**, which is
vegetation, creature and night work — so the gate can complete every task it names and still
be unable to move the verdict it is graded on. Proposed correction, for the coordinator:
split the clause. The half those tasks *can* move (silhouette variety, mid-layer presence,
scatter regularity, creature separation from ground, night midground legibility) is judged
against them; the half needing props, lighting, water and terrain becomes 2.13 with its own
gate, and Bar A / Bar B are answered after that lands. This does not rescue the current
verdict, which fails on grounds inside the gate's reach.

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

### Gate 3 parallel track — clearing the visual bars (D73)

Runs beside the band lanes, on files the band lanes do not own. The judge's
"no / no" after Gate 2 was mostly not band content, so waiting for Gate 3 to
finish would not have fixed it. Verdicts come from the kickoff run's GPU route
strip (`docs/acceptance/KICKOFF_RUN.md`), per band, day and night.

| # | Task | Tier | Owns | Serialises with |
|---|---|---|---|---|
| V1 | **Route-strip judging.** Sheet the first kickoff run's route strip, run the blind judge per band, rank the gaps; this list replaces `docs/VISUAL_BIBLE.md` §4 as the standing gap list. | Fable directs, Sonnet judges blind | `docs/VISUAL_BIBLE.md` | nothing |
| V2 | **One material language.** A single stylised shading contract across creatures, the humanoid cast, props and terrain: outline policy, ramp, specular, night floor. Creatures stop reading as a different game from the trainer. | Fable designs, Sonnet implements | `shaders/`, creature and character materials, `data/config/art.json`, `world_look.gd` | nothing in band data |
| V3 | **Distance.** Aerial perspective as a terrain-material gradient decoupled from fog; ridge tree-lines as silhouettes; the Hall and the village surviving at 400 m. | Sonnet from the bible's named mechanisms | `shaders/terrain_ground.gdshader`, `terrain_playground.json` colour/macro, `far_cover.gdshader` | V5's bake |
| V4 | **Canopy and rock structure from the installed family** (D73 §3): foliage cards / canopy break-up on the installed trees; bake-time displaced rock variants. The half the judges called "art not in the build". | Fable designs, Sonnet implements | `scripts/world/vegetation*.gd`, `scatter_rules.gd` model handling, `cover_tier.gdshader` | V5's bake |
| V5 | **Corridor-fill re-roll, once** (D73 §5): widen the `trees` layer's corridor-wide scale range and re-bake in one window before the Band 2 lane bakes. | Sonnet | `data/config/vegetation.json`, `data/scatter/playground` | **every band lane's bake**: this goes first |
| V6 | **Grass clump cards behind a flag, on by default** (D73 §4). | Sonnet | `grass_field.gd`, `grass_field.json`, `grass_field.gdshader` | nothing |
| V7 | **Locomotion rebuild** (`MEADOWS_QUALITY_REBUILD_PLAN.md` §2–3, D73 §9), judged from the kickoff run's video strips. | Fable designs, Sonnet implements | `scripts/player/` gait, humanoid animation | nothing |
| V8 | **Dialogue push-in** (D73 §6) and the remaining placeholder-grade elements: the mill's sails, the near-black site. | Haiku/Sonnet | `scripts/ui/` dialogue camera, band props | nothing |
| V9 | **Per-band visual contracts** for bands 2–5, authored before each band's lane starts, in the shape of `docs/specs/BAND1_COMPOSITION_PLAN.md`. | Fable | `docs/specs/BAND<n>_COMPOSITION_PLAN.md` | precedes that band's lane |

A gate whose acceptance names the bars does not close on a judge "no"
(D73 §2). V1 runs on every kickoff; V2–V8 land through PRs like any lane.

---

## Gate 4 — Full chapter integration, pacing and hardware performance

**Owning prompt:** `70-MEADOWS-full-chapter-integration-playthrough.md`, with
`36-R9.1`, `37-R9.2`, `38-R9.3`. **Evidence: the kickoff run** (D73,
`docs/acceptance/KICKOFF_RUN.md`), not a human playthrough.

The owner double-clicks `tools/owner/KICKOFF.cmd` on the Ally. That runs Gate F
S01–S10e with video on real hardware, the GPU route strip, the real frame-rate
probe and the shipped-build check, and pushes it as `owner-run/<stamp>`. Agents
then do the tuning from it: XP curve, trainer difficulty, wild levels, resource
availability, travel time, encounter density, camp usefulness, objective clarity,
reward economy, frame rate. Do not cut required chapter beats to hit the 3–4 hour
clock. Repeat the run after each tuning landing; the gate passes on a run whose
evidence template reads PASS for every segment, whose route-strip judge answers
yes on both bars for every band, and whose `EXPORT_VERDICT.md` is a pass on a
release newer than the last code landing.

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

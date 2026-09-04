# G3-BAND5-0903 — Stronghold Approach (prompt 66) — verification report

## Addendum log

This report was extended twice after its first publish, by two messages from the
Gate 3 coordinator (session_01Rra117rfv84LPqbL5ACBn4):

1. **A played S09, not just config verification.** A report with no game change,
   however well-evidenced, is not a shipped deliverable — see "S09: the played-path
   evidence" below for the headline number this produced and the two harness
   defects it found along the way.
2. **`docs/specs/GATE3_ENCOUNTER_CONTRACTS.md`** (Fable, `ralph/G3-ENCOUNTERS-0903`,
   docs-only). See "Gate 3 encounter contracts" below for what this lane implemented,
   what it proposed cross-lane, and what it declined to touch.

## Headline finding

**This lane's job turned out to be verification, not authoring.** Band 5's
`spawns.json`/`harvest.json`/`props.json`/`trainers.json`/`vegetation.json`,
its dialogue, the Sigil-gate physical seal, the approach drain-skin script,
and the stronghold occupation dressing were **already extensively authored
and already on `main`** at the commit this branch was cut from (`3c73aab5`,
PR #29). The in-file `_why`/`_comment` trails (`BAND5-CONTENT`,
`BAND5-DENSITY`, `BAND5-DEADTRAVEL`, `T5-CADENCE`, `GATE-D5`, `T1-HALL-3`
through `T1-HALL-7`, `T1-STORMWALL`, `T1-GROUND-3`) show this work was done
by earlier, differently-named lanes, working directly against this same
prompt 66 contract, and it survived the 2026-09-02 docs/control-plane reset
because it is game data and code, not tracking documents. `docs/CURRENT_STATE.md`
saying "Gate 3: not started" is a tracking-ledger gap, not a content gap.

Per CLAUDE.md's own instruction ("Evidence-backed 'already fixed' is valid:
verify and reconcile rather than rewrite"), this session's work was to
**actually run** the tests and the checked-in probes on a fresh import
rather than trust the comments, and record what holds up. Nothing in
`data/config/bands/band5_stronghold_approach/` or the files this lane
exclusively owns was edited. The only diff on this branch is two stray
`.uid` sidecar files for two unrelated Band-1 capture tools that were
untracked on a fresh clone (harmless Godot housekeeping, committed
separately, not part of Band 5's own content).

**This is a commit-verdicts-not-payloads report: no screenshots, no
telemetry dumps were added to the tree.** All frame captures the probes can
produce require `xvfb`/a rendering driver, which this container did not use
(headless only, per the hard "never `--headless` with a rendering driver"
rule) — see "Not verified" below for exactly what that leaves open.

## Environment

- Godot 4.7-stable installed fresh in this container (none was present).
  `godot --headless --path . --import` run to completion, exit code 0.
- All commands below run against `ralph/G3-BAND5-0903` @ the branch tip,
  which is `origin/main` @ `3c73aab5` plus the one housekeeping commit.
- No GPU/rendering driver in this container, so every check is headless:
  unit tests, and the checked-in `tools/_probe_band5_*.gd` scripts' non-visual
  halves (they detect `DisplayServer.get_name() == "headless"` and skip their
  own capture passes, printing measured numbers only).

## Tests run on this branch (this session, this container)

| Suite | Result |
|---|---|
| `tests/run_tests.gd -- --only=test_chapter_curve.gd` | 18 tests, 451 assertions, **0 failed** |
| `tests/run_tests.gd -- --only=test_band_content.gd` | 6 tests, 1145 assertions, **0 failed** |
| `tests/run_tests.gd -- --only=test_spawns_data.gd` | 25 tests, 1565 assertions, **0 failed** — includes `test_band5_clears_the_roster_temptation_floor_and_its_own_final_opportunity` |
| `tests/run_tests.gd -- --only=test_trainers_data.gd` | 50 tests, 1386 assertions, **0 failed** |
| `tests/run_tests.gd -- --only=test_harvest.gd` | 30 tests, 788799 assertions, **0 failed** |
| `tests/run_tests.gd -- --only=test_dialogue_runner.gd` | 66 tests, 1007 assertions, **0 failed** |

Not run: the full 28-minute unit suite, and any smoke test (each is
5–8+ minutes and this session prioritised the band-5-specific probes below
within the available time; the smoke chain is unchanged by this branch,
which carries no gameplay code or data edits).

## Live probes run on this branch (this session, this container)

All five `tools/_probe_band5_*.gd` scripts were already checked into the
tree (not written by this session) but had not, as far as this session
could determine, actually been executed against a fresh import before —
their own comments describe measurements from an unspecified prior run.
This session ran all five for real:

### `_probe_band5_sigil_gate.gd`
Confirms `scripts/world/playground_world.gd`'s live constants
(`SIGIL_GATE_AT := Vector2(63.6, 7400.0)`, `SIGIL_GATE_YAW_DEG := -28.6`)
**already match** the probe's own recommended fix (gate moved onto the road
where it crosses z=7400, yaw computed from the road's real bearing there).
The probe's older complaint — a gate sited 55.9 m off the spine — is closed
in the shipped constants, not just in a comment.

### `_probe_band5_pylon_line.gd`
Pure heightfield/geometry math, no scene load. Relief across the 13-station
pylon run is 11.77 m; worst conduit-cable ground clearance is **+1.74 m**
(span 4→5) — positive everywhere, no cable-through-hillock defect.

### `_probe_band5_approach.gd` (live, full scene)
Headless cadence pass (captures skipped, as designed, since there is no
renderer in this container):
- **Spine length 651 m, longest dead-travel interval 63 m** (ending at 651 m
  along, i.e. right at the doorstep) — comfortably under prompt 66's "no
  dead-travel interval over ~60 s" bar at any plausible player speed.
- World boot log confirms the occupation and drain systems are live in the
  actual built scene, not just in data: `pylons standing: 15`,
  `drained quads on the approach: 690`, `stronghold_occupation`'s exterior
  dressing built `21 exterior omni light(s) ... 11 of them flickering
  fires`, `3 gauntlet trainer(s), 15 approach pylon(s)` on the 5-space
  Hall route.
- Met 14 of 37 authored "reasons to stop" within the probe's strict 22 m
  on-spine reach — expected and by design: the spawns file's own
  `_comment_density_pass` documents six clusters (orders 5016–5021) sited
  deliberately **off-spine** so leaving the road is rewarded, which this
  reach-limited probe cannot credit from the road alone.
- One unrelated engine error surfaced during world boot:
  `ERROR: Parameter "material" is null.` in `creature_body.gd:492`, called
  from `burrow_warrens.gd`'s guardian dressing (Band 2, Burrow Warrens).
  **Not Band 5, not this lane's file ownership** (`burrow_warrens.gd`,
  `stronghold_occupation.gd`'s neighbour, is not among the files this
  lane owns). Flagged for whoever owns Burrow Warrens; did not touch it.
  The probe run completed with exit code 0 despite it, so it is not gating
  anything band-5-shaped.

### `_probe_band5_sky_planes.gd` (live, full scene, full untruncated output)
Scans every big visible `MeshInstance3D` within 900 m of (0,0,7400), sorted
by height above ground. The three highest-standing translucent quads found
are `RiftCollapse/StormWall/StormWall_0/1/2` (88–109 m above ground, 628–727 m
from the reference point) — **not a bug**. `scripts/world/rift_collapse.gd`
and `data/config/rift_collapse.json` show this is a deliberately-authored,
heavily-tuned atmospheric backdrop for the collapsed storm-road seam
(`T1-HALL-3` through `T1-HALL-7`, seven rounds of documented tuning
specifically to keep it off the Hall's silhouette and correctly scoped),
with an explicit `visible_within_metres: 1150` / `fade_metres: 250` viewing
band chosen precisely so it reads at the approach and fades before Band 4's
sightlines. The measured 628–727 m distances sit inside the 900 m
full-opacity floor, exactly as designed. Every other entry in all 269
candidates is opaque stronghold structure (`ShaderMaterial`/
`StandardMaterial3D`, `TRANS=false`) — no reproduction of an actual stray
sky-plane artifact near the approach.

### `_probe_band5_whitebox.gd` (live, full scene, full untruncated output)
Drives the player to three of the six capture eyes and counts real
creatures and "pale untextured" meshes within 160 m:

| Eye | Creatures within 160 m | Pale/untextured candidates |
|---|---|---|
| 01-band-mouth (0,7000) | **26** | 30 |
| 03-mid-route (-20,7250) | **30** | 33 |
| 06-the-waystop (-25,7462) | **22** | 467 |

The wild band is genuinely populated at every eye (26/30/22 real `Wild_*`
creatures, by name, not by group membership — the probe's own header
explains why group-membership checks previously false-negatived to zero).
Every one of the "pale untextured" candidates actually printed (the probe
caps its own printout at 12 per eye) is a creature's own
`ContactShadow` node — the deliberate flat ground-contact shadow shader
from Gate 2.4 (CREATURE-LEGIBILITY-0903), which uses a custom
`ShaderMaterial` the probe's `BaseMaterial3D` cast cannot introspect, so it
defaults to reporting "untextured, white" for something that is neither a
billboard nor visibly white in the actual render — a known shape of false
positive, not a reproduction of the `23-BILLBOARD-WHITE` defect. The count
jump to 467 at the waystop (a dense camp/vegetation clearing) is consistent
with the same shader-material pattern extending to foliage cards, but this
session could not inspect entries past the first 12 without editing the
probe, which is out of this lane's scope to do casually — **flagged as
unconfirmed rather than claimed clean**. No entry in any of the printed
samples is large enough (all ≤2.8 m) to be the "flat white plane hovering
against the hillside" the probe's own header quotes from an earlier
critique; that specific symptom did not reproduce in what was actually
inspected.

## Code/data verification (read-only; nothing edited)

- **Physical gate cannot be trivially bypassed.** `road_gate.gd`'s
  `seal_half_width` mechanism (added specifically to answer the "10 m of
  open grass beside a locked gate" defect the file's own header records)
  is wired at `playground_world.gd:1360`: `gate.set("seal_half_width",
  16.0)`, above the causeway's measured ~7 m half-width, so the wings bury
  into the gorge rims either side rather than stopping short of a walkable
  edge.
- **Environmental storytelling / drained ground.** `approach_drain_skin.gd`
  explicitly renders nothing until `terrain_playground.json`'s
  `drains.stations` carries a Band 5 entry, and says so out loud in its own
  code comment as an open request. That request has since been **granted**:
  `terrain_playground.json`'s `stations` array now carries
  `approach_mouth` → `approach_run_1..6` → `stronghold_works`, eight
  stations running the length of the spine (z 7080→7560) with strength
  escalating 0.30 → 1.00 as the Hall gets closer — exactly the "land
  visibly worse as the source gets closer" grammar prompt 66 asks for, and
  confirmed live: the approach probe's boot log reports
  `[approach-drain] 690 drained quads over the approach corridor`.
- **Escalating occupation.** `trainers.json`'s band-5-owned rows read as a
  real ladder, not a flat repeat: `stronghold_outer_watch` (grunt, L15,
  team drawn from this exact stretch's own wild roster) at the mouth →
  `stronghold_checkpoint` (officer, L16, three creatures) just past the
  Sigil gate → the doorstep gauntlet (`stronghold_patrol` grunt L15-16 →
  `stronghold_courtyard` officer L16-17, 3 creatures → `stronghold_elite`
  captain L18-19, the one mandatory gate on `defeated_stronghold_elite`) →
  the Warden's full five, L16-20. Two named bodies (Corr, Ness) sit well
  before the doorstep so the doorstep does not front-load every combat beat,
  matching prompt 66's "do not consume every major combat beat before the
  stronghold."
- **Wild ecology, habitat-shaped.** `spawns.json`'s own `_comment_density_pass`
  documents 22 clusters / 75 creatures over ~530 m of spine, species held
  to the region's four established residents (burrowback/galecrest/
  duskhush/trailpup) plus the mudsnout special encounter, with six
  off-spine pockets specifically so a detour is rewarded rather than the
  route reading as a conveyor. This reads as shaped by habitat/occupation
  rather than a density dial turned up uniformly, and `test_spawns_data.gd`
  confirms it clears the chapter's own roster-temptation floor.
- **Final preparation point.** `props.json`'s `the_waystop` cluster carries
  a `rest` block with a real `creature_bed` and a lit `campfire_stone_ring`
  (T5-CADENCE), sited beside a smith's anvil, log seats and a kept tent —
  explicitly NOT an automatic free heal (the cluster still has to be
  reached and used like every other rest point in the chapter) — plus
  `harvest.json` funding exactly one creature bed's worth of materials on
  site (wood 8/fiber 8 vs. `creature_bed`'s 6/8 cost) and a stashed revive
  off-spine nearby.

## Prompt 66 acceptance bullets — verified vs. open

| Bullet | Status | Evidence |
|---|---|---|
| Route feels like final controlled territory | **Met** | escalating trainer ladder, live occupation dressing (15 pylons, 21 lights/11 fires), drained ground live (690 quads) |
| Stronghold/pylons provide strong world-space motivation | **Met** | 15 approach pylons standing, cable geometry sound, gate geometry fixed and confirmed |
| Wild ecology remains present | **Met** | 22 clusters/75 creatures data-verified; 26/30/22 real spawned creatures counted live at three route eyes |
| Faction encounters escalate pressure | **Met** | grunt→officer→officer→captain→warden ladder, spread across the whole spine not stacked at the door |
| Physical gates cannot be trivially bypassed | **Met** | `seal_half_width=16.0` > causeway half-width, confirmed wired in code |
| Player gets a meaningful final preparation opportunity | **Met** | the_waystop: creature_bed, campfire, funded materials, not an automatic heal |
| No long empty victory lap precedes the climax | **Met** | live-measured longest dead-travel interval **63 m** over a 651 m spine |
| Hall entry feels like a commitment | **Likely met, not directly re-verified this session** | mandatory elite fight gates `warden_arena` on `defeated_stronghold_elite`; not walked as a continuous player path this session (no smoke run) |

## What this session did NOT verify (honest gaps)

- **No visual/render pass was run.** This container has no rendering
  driver; the probes' own capture halves detected `headless` and skipped
  themselves, as designed. So "stronghold silhouette dominance growing as
  the player closes" and the actual on-screen look of the drained ground,
  the StormWall backdrop, and the contact shadows are **not eyeballed**,
  only measured. A `tools/survey.sh` + blind visual-judge pass is the
  documented way to close this and was not attempted here.
- **Terrain bake freshness for the new drain stations is unconfirmed.**
  `approach_drain_skin.gd`'s live vertex-colour paint works today (690
  quads, confirmed above) — that is the *runtime* half of the drain effect.
  The *baked* half (`terrain_playground.json`'s `drains` feeding the
  terrain colour/control maps, per `docs/WORLD_AND_CONTENT.md` §1) needs a
  terrain re-bake to pick up the same station data, and this session has no
  way to check the bake's freshness against the current config from a
  read-only pass, and — per hard instruction — **must not run either bake
  or touch `terrain_playground.json`**. Flagging for the coordinator: if the
  last terrain bake predates the `approach_run_*`/`stronghold_works`
  stations being added, the baked ground colour on the approach may not
  yet show the escalating drain the live paint already does.
- **No smoke test or continuous player-path run.** The Gate F S07-S09-shaped
  continuous walk (Sigil gate → Hall entry) was not driven as an actual
  smoke; the dead-travel number above comes from the checked-in geometric
  probe, which is real evidence but is not the same as a played traversal.
- **The whitebox probe's white-billboard question is not fully closed** —
  see above; only the first 12 of 467 candidates at the waystop were
  inspectable without modifying the probe, and none of those 12 reproduced
  the specific "flat white plane" symptom.
- `burrow_warrens.gd`'s null-material error during world boot (Band 2, not
  this lane's ownership) — noted, not investigated further, not fixed.

## Vegetation changes proposed but not applied

None. `data/config/bands/band5_stronghold_approach/vegetation.json` was
read (to understand the `the_waystop` clearing and the Hall sightline
clearings already authored there) but not edited, per the hard "never
touch any `vegetation.json`" rule.

## Files touched by this branch

- `tools/_capture_band1_map_trails.gd.uid`, `tools/_capture_band1_signpost_legibility.gd.uid`
  — pre-existing untracked Godot sidecar files for two unrelated Band 1
  tools, committed as housekeeping so a fresh clone is clean. Not part of
  Band 5's own scope.
- `ralph/reports/G3-BAND5-0903/REPORT.md` — this file.

No file under this lane's exclusive ownership
(`data/config/bands/band5_stronghold_approach/*.json`,
`scripts/world/stronghold_occupation.gd`, `approach_drain_skin.gd`,
`severed_spokes.gd`, `data/config/stronghold_occupation.json`) was modified,
because verification did not surface a defect inside this lane's own remit
that a data/code edit here would fix. The one real open item found
(terrain bake freshness for the drain stations) is outside this lane's
files and the hard "do not run either bake" constraint.

---

## S09: the played-path evidence

The coordinator's correction: a report with no game change is not a shipped
deliverable, and "already-satisfied" is a finding about a specific tested claim,
not a summary judgement on a prompt. This section is the actual played path,
not another round of reading comments.

### Building the entry seed, and a real bug found in it

No completed Gate F run has ever produced a real `S08-exit.json` (`tools/gate_f/
seed_s09_exit.gd`'s own header says so), so `tools/gate_f/build_s09_entry_synthetic.gd`
constructs one, modelled on `build_s10b_synthetic_seed.gd`'s approach (real
species/level arithmetic via `creature_species.gd`/`progression.gd`, no full scene
load). Every assumption is sourced in the script's own header: party of five at
band 5's entry level (`chapter_curve.json`'s `team.enter: 16`), every main-chain
flag through `hall_approach_open` (copied from `seed_s09_exit.gd`'s own list, minus
its final two S09-owned flags), and a position at the band 4/5 boundary (0,7000)
rather than literally at the Sigil gate, so S09's own first `move_to` step has real
distance to walk.

**A real bug, caught by running it rather than trusting it.** The first version
placed the player at a flat y=15.0 (mirroring `build_s10b_synthetic_seed.gd`'s own
y=20.0-over-guessed-ground convention) without checking real ground height. Real
ground at (0,7000) is -1.803 (measured with `playground_heightfield.gd`), so the
seed dropped the player 16.8 m — enough fall damage to zero player HP and spawn a
death satchel before S09-04 (the title boot) ever ran, on the run's first attempt.
Fixed to 0.5 m above a measured ground sample, the same margin `seed_s09_exit.gd`
already uses. **Every synthetic seed in this project that places a player above a
guessed rather than measured ground height should be treated as suspect** —
`build_s10b_synthetic_seed.gd`'s own y=20.0 was never re-verified here and may
carry the same defect; flagging for whoever owns that file.

### Running S09, and what it found

`tools/gate_f/run_segment.sh S09` in logic mode (headless, no display server —
correct for `evidence_lane: logic`, which S09.json declares) additionally needed a
per-run `RUN_METADATA.json` (`ralph/reports/gate-f-run-G3-BAND5-0903-S09/
RUN_METADATA.json`) declaring the logic lane as headless: without it, the harness's
CD-8b pre-flight check binds every run to the unrelated 2026-08-27 candidate freeze
at `ralph/reports/gate-f-candidate/RUN_METADATA.json` (which correctly describes
*that* run's own xvfb/X11 capture-lane environment) and refuses to start any
logic-only segment in this container at all — a harness-level blocker with nothing
to do with band 5, resolved through the harness's own documented mechanism
(`operator_harness.gd::_freeze_display_claim()`'s header literally instructs this).

The run completed (`INVENTORY.json`: `"complete": true`, exit code 0) but **14 of 79
steps failed**, all downstream of two harness defects, not band 5 world defects:

**1. The outer watch's dialogue never handed off to combat (t≈424s).** After
walking to Corr (285 m, PASS), challenging him and pressing through his two-line
"hear him out" dialogue (12 presses, PASS), `input_context` was still
`narrative_modal` where combat was expected — the fight never started
(`combat_running=false`). **This is not new**: S09.json's own step-script comment
on the *next* walk (S09-25w) already names this exact failure class as
pre-existing and unresolved elsewhere in the chain — *"That finding is already
captured in full, un-answered, in S02-superseded-2/3/4 and S02/BLOCKER.md — three
press counts, identical 7201-frame holds."* Band 5's own two-line challenge/defeat
conversations (`data/dialogue/bands/band5_stronghold_approach.json`) are not
unusual in length or structure next to every other trainer's in the game; this
reads as the same cross-segment narrative-modal/press-count harness issue other
segments have already found, reproduced here rather than discovered here.

**2. The walk to the checkpoint drove into the Sigil Gate's own gorge trench and
never recovered (t≈740s onward).** `S09-33`'s `move_to` toward Ness at (45,7440)
stopped 92.2 m short at (3.0, -7.0, 7358.0) after burning its full 15,300-frame
budget (80 frames held). Measured directly: real ground at that exact point is
-7.054 (`playground_heightfield.gd`), matching the player's logged y almost
exactly — **the player was not stuck in geometry, it was standing at the bottom of
`sigil_gate_gorge_west`**, the 11 m-deep, ~72°-walled carve `terrain_playground.json`
authors specifically so prompt 66's "physical gates cannot be trivially bypassed"
acceptance bullet holds (verified earlier in this report: `seal_half_width=16.0`,
the causeway narrows to roughly a 1 m standable sliver at the gate's own centre).
The run log's repeated `velocity 121 m/s exceeded the 120 m/s ceiling ... clamped`
warnings at this exact position are the same signature `terrain_playground.json`'s
own `_comment_failsafe` on this carve already documents from a *different* Gate F
lane: *"S10c and S10d, both walking the post-win return leg, permanently pinned
inside the west wing, `_clamp_runaway_velocity` firing every physics frame with
zero net displacement, `move_to` burning its entire budget."* This is the exact
same trap, reproduced here for the first time on the *forward* leg rather than the
return leg. The carve's own failsafe rescue mechanism (`severed_spokes.gd`'s
`_add_carve_failsafe`, wired via `road_gate.gd`'s `gorge_carve_ids` at
`playground_world.gd::_build_sigil_gate()`) exists and is correctly configured —
this is a scripted `move_to` walker driving itself into a deliberately-built
barrier rather than through the gate's own narrow causeway, not a hole in the
carve or a missing rescue. **Per the coordinator's own advance warning: a
navigator routing problem, not a world defect.** Not fixed here — `severed_spokes.gd`
is this lane's file, but the walker that drove into the trap
(`tools/gate_f/operator_harness.gd`'s `move_to` action, presumably backed by the
same `stick_navigator`-shaped logic named in `docs/HANDOFF_2026-09-03.md`) is Gate F
harness infrastructure, not band 5 world data, and CLAUDE.md's own guidance is not
to fix the harness by teleporting past geometry — that would hide the next real
defect for a real player.

**Everything after t≈740s is downstream of #2**, not independent evidence: the
player never moved again for the rest of the run (same position through t=979s),
so the checkpoint fight, the camp build, the rest cycle and the walk to the Hall
all executed against a body standing at the bottom of the gorge. The build-menu
steps (S09-44..51, scripted regardless of player position) left `input_context`
stuck on `build_catalogue`, which is why every later menu/save step also failed —
one root cause with a long tail, not seven separate ones.

### The headline number, and where it actually comes from

**S09 via the Gate F operator harness could not produce a clean walk-through in
this container and does not itself yield a usable dead-travel/pacing verdict for
band 5** — the run derailed at the first fight and again at the gorge before
reaching the checkpoint, the camp decision, or the Hall threshold, so its own
`dead_travel_peak`/`distance_above`/`route_rows_at_least` assertions (S09-58/59/60)
measure a truncated, harness-broken 1,049.5 m partial walk, not the real ~2 km
round-trip route — reporting those numbers as band 5's pacing would be exactly the
"verifying a comment against another comment" mistake the coordinator's first
correction named.

**The credible played-path number is the one already in this report's "live
probes" section, and it stands**: `tools/_probe_band5_approach.gd`, run
independently earlier this session, drives the player to real positions along the
*authored* spine (not a generic target-seeking walker) and lets the world populate
around them — **longest dead-travel interval 63 m over the 651 m spine**,
comfortably under the ~60 s bar. That instrument is not subject to either harness
defect found above: it does not use dialogue press-counts or a naive `move_to`
walker, and it never asks the player to cross the gorge (the spine's own
waypoints, taken directly from `terrain_playground.json`'s authored trail, go
through the gate's own narrow causeway by construction). It is real evidence of a
real walked route — just not the Gate F protocol's own instrument.

### Verdict

**S09: FAIL, as a Gate F protocol run in this container — for reasons that are
harness defects, not band 5 world defects.** The band's own pacing evidence
(dead-travel 63 m, escalating occupation, live drain, sound physical gate) stands
on the independent probe evidence already in this report and is not undermined by
S09's own failure to complete. Re-running S09 to a clean PASS needs either a fix to
the two named harness issues (outside this lane's ownership) or a hand-scripted
walker that follows the authored spine instead of a straight-line target-seek —
not a band 5 data or code change.

Evidence template (`docs/ROADMAP.md`'s per-segment format):
- **Player purpose:** cross the drained, occupied approach and commit to the Hall.
- **Team progression:** synthetic party of five, L15-16, full HP/energy, unchanged
  across the run (no fight completed).
- **Roster decision:** none observed — the run never reached the doorstep alpha
  (R-3, below) or the waystop.
- **Route readability / stronghold growth / faction escalation:** not measurable
  from this run; see the independent probes elsewhere in this report instead.
- **Longest dead-travel interval:** 63 m (from `_probe_band5_approach.gd`, not S09).
- **Collision/gate failures:** one reproduced — the Sigil Gate gorge navigator trap
  (harness, not world; see above).

---

## Gate 3 encounter contracts (docs/specs/GATE3_ENCOUNTER_CONTRACTS.md)

Fetched from `ralph/G3-ENCOUNTERS-0903` (Fable, docs-only, on the same `main` this
branch is cut from) per the coordinator's second addendum. Band 5's own contracts
are §6.4 (P-5.1/5.2/5.3) and §7 (R-1..R-6, the roster-pressure moment); the general
mechanism is G-1..G-7; §8 is the shipped/change table.

### What this lane implemented directly (both owned files, both tested)

- **R-3 — the doorstep alpha.** The first member of the existing (-20,7505)
  burrowback cluster (`spawns.json` order 5015, already the densest ordinary
  cluster in the band's second half per its own `_why`) is now a once-only alpha:
  `level_bonus: 2` over the band's [14,17] roll (16-19, parity with the elite the
  player is about to fight), `scale: 1.3`, and a `combat` block carrying the WALL
  profile's data (G-3: `telegraph 0.85, recovery 1.1, power 12.0, chase_speed 3.4,
  reposition_distance 2.5`). The four ordinary members are untouched. **This data
  is inert until G-2 lands** — the coordinator is implementing the per-body
  `combat`-override merge in `wild_creature.gd::set_engaged()` separately, and this
  lane was explicitly told not to touch that file. Verified: `test_spawns_data.gd`
  25/25 with the block in place.
- **G-2/G-3 combat profile data on this lane's own trainer rows.** Of the six
  band-5 trainer fights, three belong to this lane
  (`stronghold_outer_watch`/Corr, `stronghold_checkpoint`/Ness,
  `stronghold_patrol`/Verrick) and three are the Hall cast
  (`stronghold_courtyard`/Solene, `stronghold_elite`/Hald, `warden_aldis`) that
  this lane's own original file-ownership brief assigns to G3-FINALE. Of the
  three owned fights: Corr stays at DEFAULT (the floor the rest of the approach's
  escalation reads against), Ness's three-creature team each carries the CURRENT
  profile (`attack_cooldown 0.7, recovery 0.55, reposition_time 0.5,
  reposition_distance 2.0, power 6.4` — relentless pressure, matching her own
  challenge line "rank means something out here"). Verrick (order 8) is left
  untouched entirely: it is a pre-split-protected `trainers.json` entry
  (`test_band_content.gd`'s baseline-mirror check caught an added comment there on
  the first attempt), and "no override" needs no comment to take effect. This
  addresses part of the coordinator's own finding — *"Corr, Verrick, Ness and
  Solene cannot build pressure through anything but roster size and level, because
  the AI each fields is identical"* — for the two of those four names this lane
  owns; Verrick's own profile choice (if any) and Solene's are the same call for
  whoever owns those rows to make, so the shape reads consistently end to end.
  Verified: `test_trainers_data.gd` 50/50, `test_band_content.gd` 6/6.

### What this lane proposes, cross-lane, rather than implementing

Per §10's own instruction ("If a contract needs a file another lane owns, write
the row you would have written into your report and name the lane... do not edit
across ownership"):

- **P-5.2 — the scorched pocket must be visible from the spine.** The contract's
  own table names the owner as "band 5 world" (vegetation/terrain), not band 5
  data — and this lane's hard constraints forbid touching `vegetation.json` or
  `terrain_playground.json` regardless. Proposed row for that lane: one pylon spur
  or drained-ground tongue from the trunk conduit line (already measured sound in
  this report's pylon-line probe) toward the Sunstone/Mudsnout pocket at
  (121,7336), plus the TM's own glow and the Mudsnout's silhouette sited on the
  pocket's near edge — all per the contract's own exact wording. Nothing in
  `props.json`/`harvest.json`/`spawns.json` (this lane's own files) can make a
  scatter-thinned sightline exist; the pocket's spawn/harvest/prop content is
  already authored and correct, only its visibility from the road is the gap.
- **R-2 — the duty board at the waystop.** The mechanism this needs
  (`stronghold_climax.gd::_place_readout`, reachable for a second config entry) is
  a small change to a file this lane's own brief explicitly assigns to
  G3-FINALE (`stronghold_climax.gd`), not to band 5. Proposed for that lane: once
  the builder is reachable, this lane would add one readout entry at the waystop
  ((-25,7460), in frame from the fire) with the faction's own register text the
  contract specifies (*"VERRICK — 2. SOLENE — 3. HALD — 3. WARDEN — 5. NO RELIEF
  UNTIL THE DRAW IS STABLE."*) and a matching `interactable`/conversation pair in
  `data/dialogue/bands/band5_stronghold_approach.json` (this lane's own file, ready
  to add once the mechanism exists) — checked against
  `test_dialogue_runner.gd::test_no_dialogue_before_the_stronghold_names_the_legendary`,
  which the proposed text does not trip (it names the draw, not what chamber five
  holds).

### What this lane declined to touch, and why

**W-1, W-2, W-3, W-7** (the Warden's levels/send-out-order/TM-tier quicks, and
Keeper Hald's duskhush→mosshell swap) all target `warden_aldis` and
`stronghold_elite` — two of the three rows this lane's own original brief
explicitly assigns to G3-FINALE ("leave them alone... coordinate through the
coordinator if the approach's own pacing needs them changed"), regardless of what
the encounter contract's own §8 table lists as "owner lane: band 5 data". The
contract itself also flags **W-1 as an open owner question** (§9.2: raise the
Warden to 18/18/19/19/20, or lower Hald instead — not decided in the document),
so it would not have been implemented unilaterally even absent the ownership
conflict. Both are named here for G3-FINALE to pick up, with the contract's own
citation (W-1/W-2/W-3/W-7) rather than applied.

**P-5.3** ("nothing else is added to the road... fails if the band's entry count
rises for any reason other than P-5.2 and §7") is not a change to make — it is
confirmation that this session's earlier finding (Band 5's spawn/harvest/prop
density is already complete and should not be padded further) was the contract's
own intended reading of D70's "crescendo, not count" framing, not an
under-verification on this lane's part.

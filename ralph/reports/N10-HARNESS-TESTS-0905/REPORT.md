# N10-HARNESS-TESTS-0905 — thirteen harness items, and two real gameplay-adjacent bugs under them

Branch `ralph/N10-HARNESS-TESTS-0905`, off `origin/main` at `f8a47ee4`.

## 0. Read this first: the wave's premise is not true of `main`

`ralph/briefs/0905-followup/COMMON.md` says "all 24 base lanes have landed; you are working on
top of finished, merged work". **They have not.** `main` is at `f8a47ee4` = PR #51 (W20), and
of the three lanes this brief cites as its sources, only W20 is merged:

| lane | its report on `origin/main` | its code on `origin/main` |
|---|---|---|
| W20-SMALL-FIXES-0904 | present | yes |
| W03-S08-FREEZE-0904 | **absent** | the FIX it credits (`c64af25f` via PR #30) **is** on `main`; its probes and ledger rows are not |
| W21-HARNESS-FIGHTS-0904 | **absent** | **no** — `S06.json` on `f8a47ee4` holds 0 `fight_until_resolved` steps and `tests/test_gate_f_segments.gd` does not exist |

Checked, not assumed (`git ls-tree`, `grep -c` against `f8a47ee4`). Three consequences the
coordinator needs:

1. **Item 4's precondition resolved the way the brief anticipated.** It says "check
   `S06.json` on `origin/main` first; if `S06-31`..`S06-49` are already gone, skip". They were
   still there. They are gone now.
2. **`tools/gate_f/segments/S06.json`, `S07.json`, `S08.json`, `S09.json` and
   `tools/gate_f/operator_harness.gd` all carry unmerged edits on TWO branches** — this one and
   W21's (segments) / W02's (harness). Expect one merge in each. Neither pair conflicts
   semantically: W21 converts fight steps, this lane converts *engage* steps and two waypoints;
   W02 adds a press guard, this lane adds a fight predicate, a cost case and a world-seed pin.
3. **Item 13's rows say so in their own text.** CL-H13 and CL-H1 are written as "fixed on a
   branch, not yet on `main`", with the grep that establishes it, rather than as "closed".

## 1. What changed

| File | Item | What |
|---|---|---|
| `tests/helpers/stick_navigator.gd` | 1, 11 | a fourth probe height at 0.38 m; a leg-level confinement watchdog in `walk_to()` |
| `tools/gate_f/operator_harness.gd` | 5, 6, 10 | `fight_until_resolved` FAILs on an absence; `_predict_frames` prices `chip_to_floor`; the run pins `TB_WORLD_SEED` |
| `tools/gate_f/segments/S04.json`, `S05.json` | 3 | `route_rows_at_least` re-derived by S02-60's method: 480→**420**, 1200→**970** |
| `tools/gate_f/segments/S06.json` | 4, 9 | `S06-31`..`S06-49` deleted; L.3 rehomed to the band-2 ranger camp as `S06-30a`..`S06-30l`; three engages → `interact_with` |
| `tools/gate_f/segments/S07.json` | 9 | five challenges → `interact_with` |
| `tools/gate_f/segments/S08.json` | 9, 10 | `S08-26`/`S08-35` → `move_to_entity`; six engages/challenges → `interact_with` |
| `tools/gate_f/segments/S09.json` | 9, 12 | `S09-32a` routes the checkpoint walk back through the Sigil gate; two challenges → `interact_with` |
| `tools/gate_f/build_s09_entry_synthetic.gd` | 7 | the satchel is written in the slot format `save_game.gd` reads |
| `tools/gate_f/build_s06_entry_synthetic.gd` | 8 | 1 Revive → 4 |
| `docs/GATE2_GATE3_CLOSURE_PLAN.md` | 13 | six rows rewritten in place |
| `tests/smoke_stick_navigator_low_geometry.gd` | new | three cases for the walker |
| `tests/test_gate_f_harness_predicates.gd` | new | eight tests over the real cost model, save reader, telemetry, terrain and spawn tables |
| `tools/gate_f/probe_grove_pipwing_engage.gd` | new | the S08-27 measurement |

## 2. The thirteen items

### 1 — the walker's foot-height blind spot — **done**

`_free_space()` fired its lowest ray at 0.45 m. `player_controller.gd::STEP_HEIGHT` is 0.35.
Anything topping out in that ten-centimetre band stops the body dead and is invisible to the
probe, which is not a curiosity — it is trunk flare and root, and it is what pinned S08-22.
W03's own spatial dump at the pin reads `test_move` **blocked in all eight compass directions
and clear in three of eight when the capsule is raised 0.4 m**: what stopped the body topped
out under 0.4 m, entirely beneath the lowest ray.

`PROBE_HEIGHTS` is now `[0.38, 0.45, 0.95, 1.55]` — twelve rays, not nine. **0.38 and not
0.35**: `_try_step_up` and `_recover_if_entombed` both probe *from* `STEP_HEIGHT` up, so a ray
at exactly that height grazes the top face of every kerb the body legitimately steps over and
would turn each one into a wall. Three centimetres of clearance catches everything that
actually blocks and nothing that does not.

Both halves are pinned by `tests/smoke_stick_navigator_low_geometry.gd`, in real geometry with
a real `CharacterBody3D`:

```
a 0.40m root flare 1.2m west reads as 0.70m of free space (wall is 0.30m away)
a 0.30m kerb reads as the full 3.0m of free space, the way a steppable lip must
```

Seen red first, for the right reason, with the old constant in place:

```
FAIL: a 0.40m-tall root flare 1.2m to the west read as 3.00m of free space
      (BODY_WIDTH is 0.90, PROBE_REACH is 3.0). ... This is CL-H14's blind spot.
```

**The brief's regression demand was the expensive part, and it is answered.** Every constant in
that file has a measured regression behind it and the walker is shared by every harness in the
repo, so `tests/smoke_gate_b_continuous.gd` was run **twice, end to end, with the navigator as
the only variable** — `origin/main`'s file, then this branch's.

| | `origin/main`'s walker | this branch's walker |
|---|---|---|
| `verify-gate-b-core` (default) | (not re-run; core was green here before the change) | **OK** — "a fresh save walked opening, road gate, village tools and tournament readiness in order" |
| `--gate-b-full-chain` | **FAIL, 1 failure**: *could not walk back to the Practice Meadow clearing from the gather route (stopped 81.6 m away at (-43.0, 3.0, -3.0))* — three attempts, 79.9–81.6 m short each time, and the run derails there | **FAIL, 3 failures**, all in the TAIL the baseline never reached: the objective rung after the campsite, an empty pending build selection, and 3 of 5 creature beds |

The leg that fails on `main` **passes here**. The three tail failures are not a regression — they
are the first time anything has got far enough to assert them, and none of them is a walk (an
objective ladder rung, a build-menu selection, a bed count). `--gate-b-full-chain` is the
`verify-gate-b-full-known-red` job and is allowed to fail; it fails differently, and later, now.
Routed in §5.

### 11 — the confined leg — **done, with the reproduction stated honestly**

W21 measured `S06-50` pinning the body inside a **2.7 m × 2.5 m box for its entire
44,100-frame budget — 711 s, `input_context` `world` throughout, 0 held frames** — with
`dead_travel_m` climbing to 1,258 m. Not frozen: walking, in circles, for twelve minutes. And
the very next `move_to`, from that same position, walked away at ~3.9 m/s.

Nothing in the file measured the LEG. `_stall` is only consulted outside a detour;
`_detour_stalled()` asks whether the *current* detour is moving the body, and a body
oscillating inside a small box is moving plenty; `SIDE_ABANDON_PROGRESS_M` asks for net travel
along the committed side, and a couple of metres of lateral swing satisfies it. Every check in
the machine could read healthy while the walk went nowhere.

`walk_to()` now carries a leg-level watchdog: **1,200 walking frames (20 s; held frames are not
counted) inside a 4 m ball** and the leg does to itself what the next `move_to` would have done
— `reset()`, then `_back_off()` out of the pocket, which is the one direction the body is known
to have come from. `confined_resets()` reports it so a walk that had to shake itself loose says
so instead of looking clean.

**What I could not do, said plainly.** I could not reproduce the S06-50 limit cycle in
synthetic geometry: the current walker escapes a three-sided pocket and an eleven-trunk thicket
with sub-0.45 m flares (both built and measured, both `arrived=true`). So the third case in the
smoke test models the **measurement** rather than the terrain — a stub body that walks at 5 m/s
in whatever direction the navigator asks for and is clamped into a 2.7 × 2.5 m box, which is
exactly what W21 logged — and asserts the leg notices. Red first, with `CONFINED_FRAMES` raised
past the budget:

```
FAIL: 2400 frames (40.0s) of walking, 50m of dead travel, and the body never left a
      2.7m x 2.5m box -- and the leg noticed 0 times.
green: confined for 40.0s with 52m of dead travel: the leg abandoned its own state 2 time(s)
```

**And the trigger W21 named is gone anyway**: the pin happened "one step after `S06-38` placed a
workbench at the player's feet", and item 4 deleted `S06-38`. `S06-50` now also starts from the
ranger camp rather than the quarry, a 230 m leg instead of a 1,064 m one. Whether the pin
reproduces at all after this wave is an open question, and the watchdog is the answer either way.

### 2 — the Gate 2 Pond stall (2.9) — **closed**

Re-run, not argued. `tools/gate_f/probe_pond_walker_fix.gd` drives the real `walk_to()` from
the coordinate GATE2-EVIDENCE-0903's S05 run froze at — `(-328.7, -14.2, 505.3)`, pinned to the
centimetre on three runs — toward the Old Bram detour, on the failing run's own 29,250-frame
budget, with no workaround waypoint and no teleport. A/B with the walker as the only variable:

| walker | result |
|---|---|
| `origin/main`'s | `arrived=true`, 9,725 frames (162.1 play-seconds), 3.9 m short of target |
| this branch's | `arrived=true`, 10,257 frames (170.9 play-seconds), same finish |

So the fix is FENCE-CORNER-0903 (`c64af25f`, PR #30) and it is already on `main` — the same
landing that closed CL-H14, exactly as W03 suspected from the shared signature — and this lane's
extra probe height costs the leg 8.9 play-seconds without regressing it. Row 2.9 rewritten.

One thing recorded rather than filed off: on this lane's arm the controller's own
`_recover_if_entombed` failsafe fired once at `(77.31, -2.19, 839.44)`, 340 m past the basin.
Not the Pond and not this row; routed in §5.

### 3 — S04's and S05's route-row thresholds — **done, and both were worse than the brief said**

The brief (quoting W20) says S04 wants 1,200 rows and S05 wants 3,000. **On `main` they want 480
and 1,200**: G3-HARNESS-0904 had already touched them, by a different method — one run's
checkpoint count, minus a margin. That method put S04's threshold at **92%** and S05's at
**98.8%** of the shortest completion each segment has ever recorded. That is not headroom; it is
a flake waiting for one slow run.

Re-derived by S02-60's method exactly, which is what the brief asks for: **80% of the shortest
healthy completion**, counted from every committed `<segment>/telemetry/route.csv` under
`ralph/reports/` and filtered the way S02-60 filtered (the 2026-08-25/27 pair record 1.5–1.6
rows per play second on a different clock and are excluded rather than averaged in).

| | healthy completions | shortest | 80% | was |
|---|---|---|---|---|
| S04 | 526, 528, 575, 623, 637, 658 | 526 | **420** | 480 |
| S05 | 1214, 1248, 1379, 1531 | 1214 | **970** | 1200 |

Both still fail every broken shape on record — the 164-row aborted S04 attempt, the 89-row S05
derail, the 1-row boot-only trace a refused segment writes. I did **not** re-run S04 and S05
live to get these: the brief says "matching the S02 fix's method exactly", and the S02 fix
measured committed telemetry rather than running the segments. Recorded as a deliberate reading.

Guarded by `test_the_route_row_thresholds_leave_headroom_below_the_shortest_run`, which
re-derives from the committed telemetry at test time and fails any threshold above 85%. Seen red
on the old values, naming both.

### 4 — the invented workbench beat — **deleted, and L.3 rehomed rather than lost**

`S06-31`..`S06-49` were still present on `main`, so the brief's "skip if already gone" branch
did not apply. They are gone.

The interesting half is where section L.3's requirement went. W20's note said the beat needed
"a segment whose band has an authored crafting site", and that band 2 had none. **Band 2 has
one.** `data/config/bands/band2_stone_and_root/props.json`'s `ranger_camp` cluster carries a
`rest` block with `craft_at: [-259.6, 2257.4]` and `craft_label: "Craft at the ranger's anvil"`,
stood up as a real `CraftInteractable` by `scripts/world/rest_point.gd` (T5-CADENCE;
`tests/smoke_authored_camps.gd` already asserts an authored camp offers craft as well as rest).
It sits on the `ranger_camp_spur` loop between the quarry and the Warrens mouth and is a named
map landmark (`band2_ranger_camp`, "Abandoned Ranger Camp"). The claim that band 2 authors no
crafting site was true of the protocol's text and false of the shipped world.

So `S06-30a`..`S06-30l` walk the spur to the anvil and craft there, on rootstone broken out at
the quarry one step earlier (`recipes_rootstone.json` prices `orb_greater` at 4 rootstone / 3
wood / 3 fiber and each `reinforce_*` at 3 rootstone / 2 wood). `S06-30`'s note is rewritten to
record the closure instead of the hand-off; W20's probe transcript and verdict are preserved
verbatim.

### 5 — `fight_until_resolved` PASSing on an absence — **done**

`S06-64` and `S06-74` both reported `fought 239 frames: 0 quick … ended because no fight running
for 240 frames` and PASSED — a step whose whole job is to play a fight to its end reporting
success because there was never a fight. The step now tracks whether it ever saw
`is_fighting()` or `trainer_battle_active()` true, and FAILs when it did not:

> *"— and no fight was EVER observed: `is_fighting()` and `trainer_battle_active()` were false on
> every frame this step ran, so there was nothing here to play. Whatever was supposed to start
> this fight did not."*

One exception, and it is not a loophole: a step with an `until_flag` that is already set has
demonstrable evidence the fight was won (by an earlier step, or before the save), and the
missing-flag case has already returned FAIL above it.

### 6 — `chip_to_floor` mispriced — **done**

No case existed, so the catch-all priced a step that can spend fifteen swings at thirty settle
frames each at **one frame**. Now priced at its full budget, on the same rule `press` and
`press_until` follow: `max_presses × (settle_frames + 4)` — 510 frames at the defaults, not 1.
`test_chip_to_floor_is_priced_at_its_full_swing_budget` exercises the real `_predict_frames` and
was seen red at `expected 510, got 1`.

### 7 — the S09 seed's satchel — **done, one key**

`build_s09_entry_synthetic.gd` declared `{"id": "revive", "count": 2}` and the loaded game read
`revive: 0`, with every other line at 0 too. There is no `count` in the save format and never
was: `save_game.gd::_array_to_inventory` walks SLOT INDICES and hands each entry to
`_stack_from_json`, which reads `int(dict.get("n", 0))`. Every stack this file wrote loaded as
that item at a quantity of zero, and nothing complained because a zero-quantity stack is a legal
slot.

The seed now emits the positional slot array the reader actually wants, laid out the way
`inventory.gd::add()` lays a pickup out — honouring each item's own `stack` size from
`data/items/items.json`, refusing rather than truncating if the declared items cannot fit
`SLOT_COUNT`. Declared quantities are unchanged.

`test_the_s09_seed_satchel_survives_the_games_own_save_reader` drives the builder's own output
through `JSON` and then through `save_game.gd::_array_to_inventory` into a real `Inventory`, and
asserts every declared count. Seen red at `expected 10 x potion_small, got 0` and eight more.

### 8 — S06's Revive budget — **done**

1 Revive against three scripted fights (Dorn, the Warrens chamber, the Warrens guardian). Once
spent, every later `focus_item {item: "revive"}` FAILs naming an empty bag — a step reporting a
defect in the recovery ladder when the defect is in the seed. Now **4**: one per scripted fight
plus one for the wild-encounter faint W21 measured mid-walk in a comparable segment (a burrowback
fainted the lead at t=388.8 s, nowhere near a scripted fight). Same convention as
`seed_s09_exit.gd`'s own 4. `test_the_s06_seed_carries_a_revive_for_every_fight_it_scripts`
counts the segment's fights from the file and requires strictly more Revives; seen red at
"1 Revive against 3 scripted fights".

### 9 — bare `press interact` engages — **done for all four segments, not just the two asked for**

Sixteen steps converted to `interact_with`: three in S06, five in S07, six in S08, two in S09.
`interact_with` presses only when the arbiter has a live prompt whose own text is the one the
step means — `"Challenge %s"` from `data/config/trainers.json` via
`trainer_npc.gd::_prompt_for`, `"Engage %s"` from `encounter_director.gd` — and otherwise FAILs
naming what it actually saw and how far the intended entity is. Guarded by
`test_no_gate3_engage_or_challenge_step_is_a_bare_press`.

**Not converted, deliberately**: `press interact` steps that are not engages — gate/crossing
opens, harvest swings, "take the prize", the riding mount/dismount presses, the aim and throw
pair. The riding ones are worth a lane of their own; see §5.

### 12 — `S09-33` walks into the Sigil gate gorge — **done, by waypoint**

Measured twice, independently: G3-BAND5 stopped 92.2 m short at `(3.0, -7.0, 7358.0)` and W21
stopped 81.3 m short at `(18.0, 4.0, 7363.0)` after burning the whole 15,300-frame budget with
1,778 held frames. Both stops are inside `sigil_gate_gorge_west` — the 11 m-deep, 14.8 m-wide
(rim to rim) authored carve `terrain_playground.json` centres at `(10.0, 7370.8)` on a 28.6°
axis with `half_length` 40, running from `(-25.1, 7351.7)` to `(45.1, 7389.9)`. The old leg drove
straight from `(-68, 7140)` at `(45, 7440)`: **measured gap to the carve's centre line, 0.00 m.**

The carve is not misplaced and was not moved. With `sigil_gate_gorge_east` and the two wings it
is the continuous barrier that makes the Sigil gate the only way north — which is the whole
point of `S09-19` opening it. `S09-32a` routes back through the gate mouth at `(63.6, 7400)`, the
coordinate `S09-17` reached and `S09-23` already walked out on (**11.95 m** clear of the west
carve, the same clearance that PASSing leg has), and `S09-33` then runs gate → checkpoint,
**21.0 m** clear of the east carve. No terrain moved and nothing teleports past geometry, per
2.9's own rule.

`test_no_gate3_walk_leg_is_scripted_across_an_authored_terrain_carve` checks **every** `move_to`
leg in S06–S09 against **every** carve the terrain config authors, reading the axis convention
from the same `Vector2.RIGHT.rotated(axis_deg)` every consumer uses. Seen red naming the old leg
at 0.00 m. **This closes CL-H3's remaining third** — that row is not in this lane's named set, so
it is routed rather than rewritten; see §5.

### 10 — the Band 4 grove pipwing — **root-caused, and it was two things**

Neither of them was an encounter-director bug, and the brief's suspicion that it might be a
"real encounter-director bug" is answered by measurement rather than by argument.
`tools/gate_f/probe_grove_pipwing_engage.gd` stands the player exactly where `S08-26` leaves them
and reads the live world.

**(a) The waypoint cannot reach what it is aimed at.** `S08-26` walked to spawn order 4020's
authored **centre**, `(-334.2, 5055.3)`, with `close_enough: 4.0`. Standing exactly on that
centre, at the authored world seed:

```
nearest pipwing: 9.70 m; engage_range 6.00 m; 4 pipwing(s) in the cluster
  9.70 m  Wild_pipwing_4020_1  at (-341.5, 5061.6)
 10.89 m  Wild_pipwing_4020_3  at (-323.9, 5058.7)
 11.69 m  Wild_pipwing_4020_2  at (-329.9, 5044.5)
 12.98 m  Wild_pipwing_4020_4  at (-322.9, 5061.5)
_engageable() from the waypoint: null -- `interaction_activate()` returns without starting
anything, so `press interact` does nothing
```

`encounter_director.gd::_engageable()` searches `engage_range` (6.00 m,
`data/config/combat.json` `flow.engage_range`). `_pick_clear_spot(centre, radius 15.1, rng)`
scatters the four bodies across the whole radius, and the scatter is seeded from
`hash("wild_spawn_4020")` — **deterministic, and independent of the world seed**. So there was
never anything to engage at that waypoint, on any run. That is why two lanes reproduced the
identical silence by two different methods: W03 measured zero combat events in 768 of 773
sampled rows, W21 got `S08-29 FAIL chip_to_floor: no live enemy to chip` and
`S08-31 input_context=world`. `S08-26` is now `move_to_entity {entity: "pipwing", within: 3.0}`,
which walks to the nearest live body.

`test_no_gate3_walk_aims_at_a_spawn_centre_it_cannot_engage_from` then found **a second site of
the same shape** that nobody had reported: `S08-35`/`S08-38` at the meadowhart herd (order 4033,
radius 16.2 m, `close_enough` 5.0). That one has *not* been observed failing — W21 reached and
chipped the meadowhart — so it was a coin flip rather than a certainty, and it is now
`move_to_entity` too.

**(b) Every Gate F run since 2026-09-02 has been playing a randomly-rolled world.**
`data/config/spawn_tables.json` set `roll_new_worlds` **true** on 2026-09-02 (owner directive
D-0830-1). `game_state.gd::new_game()` therefore rolls a random `world_seed`, and
`spawn_tables.gd::plan_for()` re-draws the species of every cluster that names a `table` from it.
Seed 0 is the authored world and nothing else is. **Nothing in the Gate F rig ever set
`TB_WORLD_SEED`** — not `operator_harness.gd`, not `run_segment.sh`, not one seed builder — and
every synthetic entry save is built by booting a NEW GAME, so each one carries its own random
seed. Measured on three boots of this one site:

| boot | what stands at order 4020's centre |
|---|---|
| fresh, `world_seed` 2129586928 | `Wild_galecrest_4020_1..4` |
| fresh, another rolled seed | `Wild_duskhush_4020_1..4` — **night-gated, `visible` false by day, and `_engageable()` skips an invisible body, so nothing is engageable there at all** |
| `TB_WORLD_SEED=0` | `Wild_pipwing_4020_1..4`, the authored species |

`spawn_tables.json`'s own text asks for exactly the fix: *"TB_WORLD_SEED still overrides
per-process for … forcing seed 0 back for a Gate F run."* `operator_harness.gd::_pin_world_seed()`
now does it — pinning seed 0 when the operator has not chosen one, keeping theirs when they have,
printing the choice at the head of the run and recording it in `RUN_METADATA.json`'s
`preflight.world_seed`. `test_only_the_authored_seed_gives_the_segments_the_species_they_name`
exercises the real roller: seed 0 must not enter it, and some other seed must be able to move a
cluster's species, or the pin is guarding nothing.

This is bigger than one step. **Every Gate 3 segment's encounter evidence since 2026-09-02 was
gathered in a world whose rolled clusters held species the scripts did not name.** Flagged for
the coordinator in §5.

### 13 — the closure-plan rows — **done, six rows, rewritten in place**

`CL-H14` (closed, the tree and the walker, with the A/B), `CL-H13` (root-caused — it was never a
misresolution — and marked **fixed on `ralph/W02-HARNESS-CONTEXT-0904`, not yet on `main`**, with
the `grep -c` that establishes it), `CL-H8` (closed, with where L.3 went), `CL-H4` (closed, all
three thresholds, with the method), `CL-H1` (**re-scripted on `ralph/W21-HARNESS-FIGHTS-0904`,
not yet on `main`**, with what is played and what is still blocked), Gate 2 `2.9` (closed, with
both arms of today's A/B) and Gate 2 `2.14` (closed). Rewritten in place, none appended, format
matched.

## 3. Every run, with its command and its result

Godot 4.7-stable (`4.7.stable.official.5b4e0cb0f`), headless, this container. No rendering
driver was used anywhere in this lane and nothing it changed renders, so there are no frames and
no blind judge.

| # | Command | Result |
|---|---|---|
| 1 | `godot --headless --path . --script tests/run_tests.gd` | **2012 tests, 3,765,848 assertions, 0 failed** — the whole suite, after every change in this branch |
| 2 | `… run_tests.gd -- --only=gate_f` | 76 tests, 42,012 assertions, 0 failed (68 before this lane added its file) |
| 3 | `… run_tests.gd -- --only=test_gate_f_harness_predicates.gd` | 8 tests, 212 assertions, 0 failed |
| 4 | as 3, with each of the four fixes temporarily reverted | **4 of the 5 then-existing tests red**, each naming its own defect: `expected 510, got 1`; `S04 asserts 480 rows against a shortest healthy completion of 526 (91.3%)`; `S05 … 1200 … 1214 (98.8%)`; `S06 seeds 1 Revive(s) against 3 scripted fights`; `the seed declares 10 x potion_small and the loaded satchel holds 0` (and 8 more lines) |
| 5 | as 3, with `S09-32a` removed | red: `S09 S09-33 walks from (-68.0, 7140.0) to (45.0, 7440.0), which passes 0.00 m from the centre line of 'sigil_gate_gorge_west'` |
| 6 | `godot --headless --path . --script tests/smoke_stick_navigator_low_geometry.gd` | 3 cases, pass: root flare 0.70 m, kerb 3.0 m, 2 confined resets |
| 7 | as 6, with `PROBE_HEIGHTS` back to `[0.45, 0.95, 1.55]` | red: `a 0.40m-tall root flare 1.2m to the west read as 3.00m of free space … This is CL-H14's blind spot` |
| 8 | as 6, with `CONFINED_FRAMES` raised past the budget | red: `2400 frames (40.0s) of walking, 50m of dead travel, and the body never left a 2.7m x 2.5m box -- and the leg noticed 0 times` |
| 9 | `godot --headless --path . --script tests/smoke_gate_b_continuous.gd` | **OK (CORE)** — opening, road gate, village tools and tournament readiness in order |
| 10 | `… smoke_gate_b_continuous.gd -- --gate-b-full-chain`, **this branch's walker** | FAIL ×3, all in the tail: the post-campsite objective rung, an empty pending build selection, 3 of 5 creature beds |
| 11 | as 10, **`origin/main`'s walker, nothing else changed** | FAIL ×1, earlier: *could not walk back to the Practice Meadow clearing from the gather route (stopped 81.6 m away)* — 3 attempts, 79.9–81.6 m short, run derails there |
| 12 | `godot --headless --path . --script tools/gate_f/probe_pond_walker_fix.gd`, this branch's walker | `arrived=true frames_spent=10257 (170.9 play-seconds)`, 3.9 m short of target — **2.9 closed** |
| 13 | as 12, `origin/main`'s walker | `arrived=true frames_spent=9725 (162.1 play-seconds)`, same finish |
| 14 | `godot --headless --path . --script tools/gate_f/probe_grove_pipwing_engage.gd` | three boots: order 4020 held galecrest, then duskhush, then (at `TB_WORLD_SEED=0`) the authored pipwings at 9.70–12.98 m against a 6.00 m engage range; `_engageable()` null |
| 15 | `godot --headless --path . --script tools/gate_f/build_s09_entry_synthetic.gd -- --out /tmp/s09seed` | wrote 24 slots, 13 filled: `potion_small x10, potion_large x3, revive x2, …` |
| 16 | `godot --headless --path . --script tools/gate_f/build_s06_entry_synthetic.gd -- --out ralph/reports/gate-f-run-N10-S06/saves` | seed built, 25 flags, party of 4, tracked objective *Clear the Burrow Warrens beneath the Old Quarry* |
| 17 | `tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-run-N10-S06 S06` | see §3.1 |
| 18 | `… run_tests.gd -- --only=test_terrain_bake_freshness.gd` | **3 tests, 8 assertions, 0 failed** — see §5, this is not what COMMON.md says |

### 3.1 The S06 run, and what it changed about item 11

Run 17 was launched against S06 **before** the spine fix, i.e. with `S06-30b` still a single
straight `move_to` from the quarry to the ranger camp. It is the run that produced the item-11
answer, so it is reported as the reproduction it turned out to be rather than as a validation:

```
S06-30b  FAIL did not reach (-260, 2257) in 30000 walking frames;
         stopped 734.2 m short at (340.0, 4.0, 1834.0) (0 held)
```

and its own `route.csv`, read back: **1,048 sampled rows between t=476.4 and t=1020.2 — 544
play-seconds — inside x 321.5..399.9, z 1780.9..1846.4, with `dead_travel_m` climbing from 0 to
1,986.68 m.** W21 logged the same shape 14 m away (711 s, 1,258 m of dead travel at
`(336.2, 1.3, 1820.6)`) and attributed it to navigator state left behind by the workbench placed
one step earlier. **There is no workbench on this branch** — item 4 deleted `S06-38` — and it
happens anyway. That hypothesis is closed: the site is the cause, and it is the Old Quarry's own
exit.

The fix is the authored route rather than a bigger budget, and it is verified leg by leg
(`tools/gate_f/probe_band2_spine_walk.gd`, driving the real `walk_to()`):

```
=== band 2 spine walk probe ===
  ARRIVED (403.0, 1794.0) -> (330.0, 1950.0): walked 166.3 m in 2226 frames, 0 confined reset(s)
  ARRIVED (332.6, 1944.6) -> (180.0, 2050.0): walked 179.4 m in 2387 frames, 0 confined reset(s)
  ARRIVED (185.0, 2046.7) -> (20.0, 2130.0):  walked 178.9 m in 2169 frames, 0 confined reset(s)
  ARRIVED (25.3, 2127.3) -> (-150.0, 2210.0): walked 187.9 m in 2315 frames, 0 confined reset(s)
  ARRIVED (-144.6, 2207.5) -> (-259.6, 2257.4): walked 120.1 m in 1839 frames, 0 confined reset(s)
  ARRIVED (-255.8, 2252.8) -> (-310.0, 2320.0): walked 80.4 m in 1202 frames, 0 confined reset(s)
  ARRIVED (-306.9, 2314.9) -> (-420.0, 2470.0): walked 186.1 m in 2242 frames, 0 confined reset(s)
VERDICT: 7 of 7 legs walked
```

Every leg arrives in a fifth to a sixth of its budget, and the leg-level watchdog never has to
fire. `S06-30b`..`S06-30b4` and `S06-49a` are those waypoints. `terrain_playground.json`'s
`trail.bands[band2_stone_and_root]` is where they come from, and `trail.loops` is what says the
ranger camp spur leaves the spine at `(-150, 2210)` and rejoins at `(-310, 2320)`.

**Two more things that run proved, both from item 9's conversion:**

```
S06-30c  FAIL the live prompt is "…Chop", which does not contain "Craft"
         -- pressing here would activate a different provider. Not pressed.
S06-60   FAIL the live prompt is "Trailpup is out of the fight.", which does not
         contain "Engage" -- pressing here would activate a different provider.
```

The first is `interact_with` refusing to press a tree-chop prompt while the walk was 734 m short
of the anvil — the guard doing exactly its job instead of banking a green press. The second is
worth more: S06 enters the Warrens chamber fight **with the party's lead fainted**, so
`encounter_director.gd::interaction_offer()` returns the fainted statement and there is no
engage to press. On `main`'s S06 the old bare press would have reported that green.
W21-HARNESS-FIGHTS-0904's unmerged branch puts a by-identity Revive ladder in front of every one
of these fights, which is the fix; this is independent evidence that it is needed.

## 4. What I deliberately did not do

- **I did not run S06, S07, S08 and S09 end to end.** The Verify section asks for it; four Gate 3
  segments is what W21-HARNESS-FIGHTS-0904 spent a whole lane on, two at a time on this box, and
  S06 alone predicts ~230,000 frames at the 0.0167 s/frame this container measures. One S06 run
  was launched and is the reproduction §3.1 is written from. What is verified instead: the full
  unit suite (2,012 tests), both Gate B smokes with the walker A/B'd, the pond leg on both
  walkers, the whole quarry→Warrens route leg by leg, and eight new tests each seen red first.
  **The four end-to-end runs are the outstanding debt of this lane** and belong with W21's
  landing, since the segments only make sense together.
- **I did not touch `docs/GATE2_GATE3_CLOSURE_PLAN.md`'s `CL-H3`**, though item 12 closes its
  remaining third. The brief names six rows and says not to go beyond them. Routed in §5.
- **I did not convert the non-engage `press interact` steps** — gate opens, harvest swings, the
  riding mount/dismount presses, the aim/throw pair. The riding ones are the site of W21's
  `S08-79` derail and want their own pass; §5.
- **I did not re-run S04 or S05 live** to re-derive their thresholds. The brief says "matching
  the S02 fix's method exactly", and that fix measured committed telemetry rather than running
  the segments. Stated as the reading it is.
- **I did not change `run_segment.sh`** (not in the ownership list) even though the world-seed pin
  would sit as naturally there. It is in `operator_harness.gd`, which is, and it covers every
  invocation the runner makes.
- **No visual work**, so no frames, no contact sheet and no blind judge: nothing this lane
  touches renders.
- **I did not commit the seeded save or the telemetry payloads** from run 17. `.gitignore`'s
  evidence rule already excludes `ralph/reports/**/telemetry/`; the save was regenerable and was
  removed after the first commit caught it.

## 5. Routed findings — things this lane found and does not own

1. **`CL-H3`'s last third is closed and its row still says otherwise.** Item 12 fixed the
   `sigil_gate_gorge_west` waypoint; that row is outside this lane's named set. Whoever updates
   it: the corner half and the Pond half were already done, so the row can close outright.
2. **Every Gate F run since 2026-09-02 has played a randomly-rolled world.** See item 10(b).
   This lane pinned `TB_WORLD_SEED=0` in `operator_harness.gd`, which fixes it going forward,
   but **every Gate 3 encounter verdict recorded between 2026-09-02 and this commit was gathered
   against clusters whose species the scripts did not name.** Anyone quoting a band's encounter
   evidence from that window should re-check it. The synthetic seed builders that boot a new game
   (`build_s06/07/08_entry_synthetic.gd`) each bake a random `world_seed` into their save; the
   env pin overrides it at read time (`spawn_tables.gd::resolve_seed` checks the environment
   first), so no seed needs rebuilding — but a seed rebuilt without the pin will still carry a
   rolled seed, which is confusing rather than harmful.
3. **`test_terrain_bake_freshness.gd` passes here, and COMMON.md and the N11 brief both say it
   is red on `main`.** Run 18: `3 tests, 8 assertions, 0 failed`, standalone and inside the full
   suite, on a branch whose `git diff origin/main -- data/` is empty. W03 measured it failing at
   `ef16544f`; `main` is now `f8a47ee4`. It looks like it was fixed between those two, and
   **N11-TERRAIN-BAKE may be about to re-bake something that is already fresh.** Worth one check
   before that lane spends a session.
4. **`--gate-b-full-chain`'s three tail failures** — the objective rung after the campsite does
   not move to `tournament_build_camp`, the live pending build selection is empty after selecting
   `creature_bed`, and only 3 of 5 creature beds go up against the owner's one-bed-per-entrant
   directive. None is a walk. They are newly visible because the walker now gets that far; on
   `main` the run derails 81.6 m short of the Practice Meadow clearing before reaching them.
5. **S06 enters its Warrens chamber fight with a fainted lead** (§3.1). W21's unmerged Revive
   ladders are the fix; nothing on `main` recovers the party there.
6. **`_recover_if_entombed` fired once at `(77.31, -2.19, 839.44)`** during the pond probe, 340 m
   past the basin. The failsafe working, at a site nobody has looked at.
7. **`S08-72`/`S08-74`/`S08-76`, the riding presses, are still bare.** W21 traced `S08-79`'s
   derail to one of them winning the arbiter with Captain Halder's *challenge* conversation
   instead of the ride prompt. `interact_with` with the ride prompt's own text would end it in one
   line; it needs whoever owns `riding_controller.gd`'s prompt strings.
8. **`operator_harness.gd` and the four Gate 3 segment files carry unmerged edits on two branches
   each** (this one, and W02's / W21's). Named again here because it is the most likely way this
   work gets lost. Neither pair conflicts semantically.

## 6. Final state

- Branch: `ralph/N10-HARNESS-TESTS-0905`, off `origin/main` at `f8a47ee4`.
- CI could not be read from this container — the GitHub API returns *"GitHub access is not
  enabled for this session"* and there is no `gh`. The full unit suite was therefore run locally
  in full (run 1: **2,012 tests, 3,765,848 assertions, 0 failed**), which is what
  `verify-unit-tests`'s shards run between them, plus both Gate B smokes. **The coordinator
  should still read the CI run for this branch rather than take this paragraph for it.**
- Acceptance, item by item: **1 done** (with the Gate B A/B the brief demanded), **2 closed**
  (both walkers arrive), **3 done** (both thresholds, by S02-60's method), **4 done** (deleted,
  and L.3 rehomed to a real authored site), **5 done**, **6 done**, **7 done** (one key), **8
  done**, **9 done for all four segments**, **10 root-caused and closed** (two independent
  causes, both measured), **11 root-caused, the workbench hypothesis disproved, and the route
  fixed and verified**, **12 done by waypoint**, **13 done** (six rows in place, two of them
  saying plainly that the fix is on an unlanded branch).

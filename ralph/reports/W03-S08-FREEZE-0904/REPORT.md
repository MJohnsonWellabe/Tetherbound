# W03-S08-FREEZE-0904 — CL-H14 root-caused, reproduced, and closed

Branch `ralph/W03-S08-FREEZE-0904`, off `origin/main` at `ef16544f`.

## 1. The answer

`S08-22` did not freeze because of the world. **The body walked head-on into a
tree.**

At frame 1474 of the reproduction, travelling at 5.00 m/s, the player capsule
contacts `CommonTree_2_Collision` with a surface normal of `(0.33, 0.00, −0.95)`
— dot product **−1.00** against its own direction of travel, a dead-centre hit
with no tangential component for `move_and_slide` to convert into a slide.
Velocity goes to exactly `(0, 0, 0)` on that frame and never becomes anything
else again.

What kept it there was the **walker**. `stick_navigator.gd`, as it stood when
CL-H14 was recorded, resets its own per-side attempt counter every time it flips
sides, so the escape hatch meant to abandon a hopeless side (`DETOURS_PER_SIDE`)
can never be reached. The walk entered a closed **41-frame cycle at exactly zero
displacement** and ran it to the end of the 45,000-frame budget.

**The fix is already on `main`.** FENCE-CORNER-0903 (`c64af25f`) replaced
attempt-counting with measured progress. It was sitting in an **unmerged pull
request** while CL-H14 was being investigated as an unexplained world defect, and
reached `main` afterwards as **#30** (`65fc6625`). Both halves are demonstrated
below on today's tree by swapping only the walker.

**`S08-22` now arrives:** 839.5 m walked to `(-345, 5060)` in 10,907 walking
frames, 0 held — and the segment ran 12 steps past it.

## 2. Files changed

| File | What it is |
|---|---|
| `tools/gate_f/probe_s08_freeze_repro.gd` | **new.** The differential probe. `--mode=loaded` reproduces the segment's own path (title → seed slot 4 → `load_game` → `change_scene` → 10,800-frame settle → `creature_recall` → walk S08-22); `--mode=isolated` repeats `probe_ironwood_approach.gd`'s teleport-and-walk; `--start=x,y,z` moves the isolated stance; `--navigator=` swaps the walker. One per-frame CSV for every mode, and a spatial dump when the body stops moving. |
| `tools/gate_f/probe_s08_freeze_legacy_navigator.gd` | **new.** Frozen copy of `tests/helpers/stick_navigator.gd` at `9413488b` — the tree CL-H14's two runs were walked with. The control arm of the A/B, and nothing else: no game code and no other test loads it. |
| `docs/CURRENT_STATE.md` | CL-H14 recorded as closed with this evidence. The Gate 2 Pond-stall row (2.9) it shares space with is rewritten to say what is and is not established: same signature, same likely mechanism, **not re-measured here, so still open**. |
| `docs/GATE2_GATE3_CLOSURE_PLAN.md` | CL-H14 row rewritten: `proven failing` → closed. |

**No game code changed.** The defect was already fixed on `main`; this lane's
job was proving *which* thing was broken and *what* fixed it. §7 says what I
deliberately did not change.

## 3. The root cause, frame by frame

`probe_s08_freeze_repro.gd --mode=loaded --deploy --settle=10800 --budget=45000
--stop-on-freeze --navigator=…legacy_navigator.gd`, on today's tree, with an
entry save built today by `build_s08_entry_synthetic.gd`:

```
RESULT mode=loaded arrived=false walked=2074 held=0 frames=2074
       final (-164.12, -9.13, 4334.56) 747.6 m short
```

**CL-H14's coordinate to the centimetre and its 747.6 m to the tenth of a
metre**, from a run started this session. The original report measured that pin
twice from the same seed; this is the third.

### 3.1 The contact

From `loaded_legacy.csv`, the six frames either side of the stop:

| frame | position (x, z) | velocity (x, z) | slide colliders |
|---|---|---|---|
| 1471 | −164.051, 4334.325 | −1.21, 4.85 | Terrain ×3 |
| 1472 | −164.072, 4334.408 | −1.21, 4.85 | Terrain ×3 |
| 1473 | −164.092, 4334.490 | −1.21, 4.85 | Terrain ×3 |
| **1474** | **−164.110, 4334.563** | **0.00, 0.00** | Terrain ×2, **CommonTree_2_Collision** |
| 1475 | −164.110, 4334.563 | 0.00, 0.00 | CommonTree_2_Collision `(0.33, −0.00, −0.95)`, Terrain |
| 1476 | −164.110, 4334.563 | 0.00, 0.00 | CommonTree_2_Collision `(0.33, −0.00, −0.95)`, Terrain |

The walker was pushing straight at the waypoint — `_side` 0, `_stall` 0, no
detour running — so this is not a walker mistake. It is a trainer walking into a
tree, which is an ordinary thing to do.

### 3.2 The site is a thicket, not a hole

The probe's spatial dump at the pin:

```
heightmap ground_h = -9.14 ; on_floor=true ; vel=(0.0, 0.0, 0.0)
test_move   0 deg: blocked=true raised=true      test_move 180 deg: blocked=true raised=false
test_move  45 deg: blocked=true raised=true      test_move 225 deg: blocked=true raised=false
test_move  90 deg: blocked=true raised=true      test_move 270 deg: blocked=true raised=true
test_move 135 deg: blocked=true raised=false     test_move 315 deg: blocked=true raised=true
within 6 m: Terrain (Terrain3D)
within 6 m: 3x CommonTree_2_Collision, 3x CommonTree_1_Collision, 5x CommonTree_3_Collision
            (StaticBody3D, layer 1)
ray from +1 m down 12 m: hit Terrain at y=-9.14
ray from +3 m down 12 m: hit Terrain at y=-9.14
camera rig 1.7 m from the body ; ally: AllyCreature 10.2 m away, layer=0
```

Against every hypothesis CL-H14 carried:

- **Not a hole in the world.** Ground is 1 cm under the feet, `on_floor` is true
  every frame, and downward rays from +1 m and +3 m both hit `Terrain` at the
  body's own height. The earlier cold-teleport probe that "found no ground" was
  measuring an unvisited chunk, exactly as its author suspected.
- **Not Terrain3D streaming.** The camera rig is **1.7 m** from the body for the
  whole approach and the whole freeze, logged per frame, so collision is
  streamed around it. (The rig-far-from-body case is real elsewhere —
  `game_state.gd::apply_loaded_player_pose` documents a 7,400 m instance — but
  it is not this.)
- **Not a CarveFailsafe volume.** No recovery teleport fires; the position never
  jumps. This confirms the earlier lane's finding.
- **Not the deployed creature.** `AllyCreature` is 10.2 m away on
  `collision_layer = 0`, and cannot block anything.
- **Not the player's own failsafes misfiring.** `unstick_count` stays **0**
  throughout: three of the eight raised probes are clear, so `_entombed_at()`
  correctly answers "pressed against something, not sealed in it" and declines
  to teleport. That is the right answer.
- **It is authored scatter, behaving correctly.** Eleven tree colliders within
  6 m; every compass direction blocked at 0.5 m of travel; raised 0.4 m, three
  of the eight open. The blocking geometry is **low** — trunk flare and roots,
  under half a metre.

### 3.3 The walker's closed cycle

Once stopped, the walk cycles forever. Measured over the 601 frames the probe
let it run: **41 distinct states, zero net displacement, `locomotion_enabled`
true and `input_context` `world` throughout** — exactly the signature the
original report recorded and could not explain ("the walker is pushing every
frame, nothing moves it, and nothing is holding input").

| Frames | `_stall` | `_side` | `_side_detours` | `_detour_left` | What the walker is doing |
|---|---|---|---|---|---|
| 26 | 0 → 26 | 0 | 0 | 0 | pushing straight at the target, not moving, `_stall` climbing to `STALL_FRAMES` |
| 1 | — | +1 | 1 | 45 | `_begin_detour`: commits a side, sets `DETOUR_FRAMES` |
| 15 | — | +1 | 1 | 45 → 31 | sliding sideways; the body travels **< 0.12 m** |
| — | — | −1 → +1 | **0 → 1** | 45 | `_detour_stalled()` fires, flips the side **and zeroes the count**; `_begin_detour` finds the −1 flank narrower than `BODY_WIDTH` and the +1 flank "free", flips straight back, and the count resets again |

Which branch of `_begin_detour` runs is settled **by elimination from the
logged values**, not assumed: the flip-on-count branch needs `_side_detours >=
DETOURS_PER_SIDE` (0 ≥ 3, false), and the both-flanks-pinched branch calls
`_back_off()`, which would show as `_detour_left = BACKOFF_FRAMES` (30). The log
shows 45 every cycle, so the branch taken is the wedge check — the −1 flank
probes narrower than `BODY_WIDTH`, the +1 flank probes clear, and the side flips
straight back with its count zeroed.

**The reset is the defect.** `_side_detours` returns to `0` on every flip, so it
never climbs past 1, `DETOURS_PER_SIDE` (3 in that version) is never reached,
`_back_off()` is never called, and nothing in the state machine can ever
conclude that a side is hopeless. Each 41-frame cycle starts the body from
standstill, pushes it sideways for a quarter of a second against a trunk it is
pressed into, gets nowhere, and flips.

### 3.4 Why the walker believes the blocked side is clear

`_free_space()` casts its nine rays at `PROBE_HEIGHTS = [0.45, 0.95, 1.55]`. The
lowest is **45 cm above the feet**, and the geometry stopping this capsule is
below it — which is what the `test_move` split measures (blocked at 0.5 m of
travel, three of eight open when raised 0.4 m). So the walker probes a flank as
clear, commits a detour into it, and the body does not move. **This blind spot
is still present in the live walker** — see §7.

## 4. Why the isolated probe arrived and the segment froze

The earlier lane's strongest evidence against "it's the walker" was that
`probe_ironwood_approach.gd` drives the same navigator over the same bearing and
arrives cleanly. That is real, it reproduces today, and it is not a
contradiction. **The trap is dynamic, not a place you can stand in.** It exists
only for a body that arrives at walking speed on the one line that meets that
trunk square-on. Four starts were run with the legacy walker to establish this,
each a real run, and only one of them freezes:

| Start | Walker | Result |
|---|---|---|
| the loaded segment path (save → `load_game` → settle → walk) | legacy | **FROZEN** at (−164.12, −9.13, 4334.56), 747.6 m short |
| the loaded segment path, identical probe and instrumentation | live | **arrives** — 11,185 walking frames, 0 held, 4.9 m short of the waypoint |
| the loaded segment path, via the segment itself | live | **arrives** — 839.5 m, 10,907 walking frames, 0 held |
| `(-152, -2.15, 4238)`, `probe_ironwood_approach.gd`'s own stance | legacy | arrives, 10,771 frames, 4.8 m short |
| `(-152, -2.15, 4238)` | live | arrives, 11,014 frames, 4.9 m short |
| `(-152, -4.53, 4238)`, the entry save's own settled height | legacy | arrives (6,000-frame budget, past the thicket at z 4674) |
| teleported to `(-160.83, -7.84, 4320.36)`, 14 m short of the pin | both | pass **west** of it, ending x ≈ −169.6 against the frozen run's −164.1 |
| teleported onto the pin itself, `(-164.12, -9.13, 4334.56)` | both | walk out, 12 m in 216–287 frames |

So: the start height alone does not decide it; a body *placed* on the freeze
coordinate is not trapped at all; and the divergence between the two tracks is
already 6 m by the time they reach the thicket (at 1,200 frames: loaded
`(-168.85, 4318.40)`, isolated `(-174.82, 4321.26)`). One line meets the trunk
head-on, the others pass it.

**This is also the answer to the earlier lane's "inconclusive" cold-teleport
result.** A teleported body is depenetrated to the nearest free space and walks
away; only a body pressed into the trunk by its own motion is stuck. A walker
that gets through terrain like this only when it happens to miss the trap is not
a working walker, which is what §5's fix addresses.

### 4.1 What the live walker does on the identical path

The fourth arm of the matrix is the same probe, the same save, the same
10,800-frame settle and the same deployed creature as the frozen run, with the
walker as the **only** variable. It arrives. Read against the frozen run's log,
column for column, through the thicket band (z 4325–4350):

| | legacy walker | live walker |
|---|---|---|
| frames spent in the band | ran out the budget | 647 |
| tree colliders contacted in the band | 1, head-on, terminally | **78** |
| longest run of zero displacement | **unbounded** — 43,000 frames to the end of the budget | **39 frames** (0.65 s), at (−180.52, 4329.06) |
| `_recovering` frames in the band | the mechanism does not exist in that version | **112** |
| x range walked through the band | pinned at −164.11 | −188.62 … −175.70 |

So the live walker is not avoiding the trees — it touches them **78 times** in
the same 25 m of z, gets stopped repeatedly, and each time gets off again
within two thirds of a second, with FENCE-CORNER's one-shot retreat
(`_recovering`) firing for 112 of those frames. That is the fix working in
exactly the terrain that produced CL-H14. The two tracks run 12–24 m apart
through the band because their detour decisions diverge from the first obstacle
onward, which is the same effect §4 measures at the start of the leg.

## 5. What fixed it, and when

FENCE-CORNER-0903 (`c64af25f`) replaced attempt counting with **measured
progress** — `SIDE_ABANDON_ATTEMPTS` 2 and `SIDE_ABANDON_PROGRESS_M` 1.0 m of
net travel since the side was committed — raised `DETOURS_PER_SIDE` 3 → 20,
added the `CLEAR_AHEAD_FRAMES` forward-clear check that ends a detour when the
line to the target reopens, and made the retreat a one-shot via `_recovering`. A
side that carries the body nowhere is now abandoned on its second attempt
**regardless of how often the count is reset**, so §3.3's cycle cannot close.

The chronology is checkable, and it is the part worth remembering:

- `c64af25f` is **not** an ancestor of `44f06cf9` (the tree CL-H14's runs were
  branched from) **nor of `9413488b`** (the G3-HARNESS lane's own commit) —
  `git merge-base --is-ancestor` says so for both.
- It reached `main` afterwards, in **#30 / `65fc6625`**.

So the fix for CL-H14 **existed in an open pull request while CL-H14 was being
investigated as an unexplained world defect**, and the two never met.
`docs/FINISH_THE_MEADOWS.md`'s own table of wrong claims already records the
general form of this ("the fence-corner walker fix *does not exist on origin*" —
what was true: "it sat in an open pull request the whole time"). This is what
that cost, in one concrete blocked band.

## 6. Every run, with its command and result

Godot 4.7-stable (`4.7.stable.official.5b4e0cb0f`), headless, this container.
Entry save built fresh by `tools/gate_f/build_s08_entry_synthetic.gd`, settling
at `(-152.0, -4.53, 4238.0)` with no drift warning.

| # | Command | Result |
|---|---|---|
| 1 | `godot --headless --path . --script tools/gate_f/build_s08_entry_synthetic.gd -- --out <run>/saves` | wrote `S07-exit.json` (1,420,271 bytes): party 5/5, 26 flags, tracked objective `Defeat the Upper Meadows captains. 0/3` |
| 2 | `tools/gate_f/run_segment.sh --run-dir <run> <S08 steps 1–26>` | **S08-22 PASS**, **S08-23 PASS** (`region=the_ironwood_grove`); `INVENTORY.json` `complete: true` |
| 3 | `probe_s08_freeze_repro.gd --mode=isolated --budget=12000 --stop-on-freeze` (live walker) | `arrived=true walked=11014 froze_at=-1`, 4.9 m short of target |
| 4 | `probe_s08_freeze_repro.gd --mode=loaded --deploy --settle=10800 --budget=45000 --stop-on-freeze --navigator=…legacy_navigator.gd` | **`arrived=false`, pinned at `(-164.12, -9.13, 4334.56)`, 747.6 m short — CL-H14 reproduced** |
| 5 | same as 4 but `--mode=isolated --budget=12000` | `arrived=true walked=10771 froze_at=-1`, 4.8 m short |
| 6 | same as 5 but `--start=-152.0,-4.532708,4238.0 --budget=6000` | no freeze; past the thicket, 397.1 m short at budget end (z 4674) |
| 6b | as 4, but with the **live** walker (`--navigator` omitted) | **`arrived=true walked=11185 held=0 froze_at=-1`**, 4.9 m short — the controlled A/B's second arm, §4.1 |
| 7 | `tools/gate_f/run_segment.sh --run-dir <run> <S08 steps 1–37>` — S08-22 **plus 12 steps** | **32 pass, 1 fail, 4 delegated, `complete: true`.** S08-22: *"walked 839.5 m to (-345, 5060) in 10907 walking frames (0 held)"*. The one failure is not this leg — §8 |
| 8 | three runs of a candidate synthetic regression smoke (teleport to 14 m short, to 2.6 m short, and onto the pin) | all three **refused to pass**, correctly: the legacy walker escapes every teleported start. Reported in §4 and the file was removed rather than committed — §7 |

Unit tests and the wider suite were not run: no game code changed, so there is
nothing for them to regress. The two new files are a probe and a frozen copy
that nothing else loads.

### The reproduction, for whoever needs it next

```
godot --headless --path . --script tools/gate_f/build_s08_entry_synthetic.gd -- --out /tmp/s08/saves
godot --headless --path . --script tools/gate_f/probe_s08_freeze_repro.gd -- \
    --mode=loaded --deploy --save=/tmp/s08/saves/S07-exit.json --log=/tmp/s08/legacy.csv \
    --settle=10800 --budget=45000 --stop-on-freeze \
    --navigator=res://tools/gate_f/probe_s08_freeze_legacy_navigator.gd    # freezes
# drop --navigator to walk the same leg with the live walker             # arrives
```

About 12 minutes each. The per-frame CSV is what §3's tables are read from.

## 7. What I deliberately did not do

- **I did not touch `tests/helpers/stick_navigator.gd`.** The cause is provably
  the walker, so changing it was inside my ownership — and the change is already
  on `main`. Anything further would be speculative.
- **I did not close the probe-height blind spot** (§3.4), though it is the
  deeper cause and is still live: `_free_space()` cannot see geometry under
  45 cm, so the walker still commits detours into flanks the body cannot enter,
  and escapes this trunk by *noticing it made no progress* rather than by
  *seeing what stopped it*. Adding a foot-height ray is a two-line change and a
  bad one to make blind: every constant in that file has a measured regression
  behind it (`PROBE_HEIGHTS`, `DETOURS_PER_SIDE` and `CLEAR_AHEAD_FRAMES` each
  record a specific leg that broke when it moved), the walker is shared by every
  harness in the repo, and proving no regression means the full suite plus the
  Gate B and Gate F smokes. **Recorded as a finding for whoever owns the walker
  next**, with the measurement that would justify it, rather than shipped on a
  guess.
- **I did not commit a synthetic regression smoke.** I wrote one, ran it three
  times, and deleted it: it drove both walkers from a teleported stance and the
  *legacy* walker escaped every time (§4), so it could only ever have passed
  vacuously — a green light that proved nothing. Its own two-walker guard is
  what caught that, which is the guard working. The honest regression for this
  defect is the reproduction in §6, plus S08 itself: the segment walks the real
  approach, and it is the thing that failed.
- **I did not move the waypoint.** The brief's "fails if" condition is not met:
  `S08-22` still targets `(-345, 5060)`, untouched, and everything above is
  measured against it.
- **I did not fix S08-31** (§8) — different lane, different mechanism.

## 8. Adjacent finding, handed over rather than fixed

The extended run (row 7) failed exactly one step, **`S08-31`**:
`input_context=world (wanted combat_aim)`. It is not the walk — S08-22 and
S08-23 pass and the body is standing in the grove — and it is not a one-off. The
run's telemetry carries **no combat event of any kind**: `S08-26` walks 6.2 m to
the pipwing, `S08-27` presses `interact`, `S08-28` waits 180 frames, `S08-29`
presses `combat_quick` sixteen times, and `input_context` reads `world` for 768
of 773 sampled rows (the other five are `title` and `menu_map`). So the grove's
pipwing encounter **never staged a fight**, and S08-31 is simply the first step
that asserts hard enough to notice.

That is a real blocker for S08's combat coverage — CB-12's small-body case and
the catch that follows it are all downstream of it — and it belongs to the Band 4
content / encounter-director lane, not this one.

## 9. Ledger rows rewritten

- `docs/GATE2_GATE3_CLOSURE_PLAN.md`, **CL-H14**: `proven failing` → **closed**,
  with the reproduction, the mechanism, and the landing that fixed it.
- `docs/CURRENT_STATE.md` §3: the row that carried the Gate 2 Pond stall now
  carries CL-H14's closure and this evidence. **The Pond stall (2.9) is left
  open**, deliberately: it has the identical signature (`(−328.7, −14.2,
  505.3)`, pinned to the centimetre on three runs, locomotion enabled, "0
  held"), and `probe_pond_stranding.gd`'s "0 of 10 stands wedged" is exactly
  §4's placed-body result — so the same mechanism very likely explains it and
  the same landed fix would cover it. But **I did not re-run the Pond leg**, and
  closing it on the strength of a matching signature would be the same
  comment-against-comment reasoning this repo has already paid for. The row says
  so, and names the cheap way to settle it (re-run that leg against
  `probe_s08_freeze_legacy_navigator.gd` and the live walker).

## 9b. CI on this branch — the two red jobs are inherited, not this lane's

Run [33964632572](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/33964632572)
on tip `040aa73e`. The `changes` gate classed the diff as code, so the code jobs
really ran — this is not a docs-only run that verified nothing.

Two jobs failed, **and both are the same single test**:

```
test_terrain_bake_freshness.gd :: test_playground_terrain_bake_is_committed_and_fresh
  expected true, got false  (data/terrain/playground has no manifest, or is stale
  against the live data/config/terrain_playground.json ...)
```

- `verify-terrain-bake-freshness` — that check, alone, failing one second in.
- `verify-unit-tests (1)` — **511 tests, 225,538 assertions, 1 failed**, and the
  one is that same test.

**Not caused by this lane, and checked rather than assumed.** This branch changes
two probe scripts, their `.uid` files and three documents; it touches neither
`data/config/terrain_playground.json` nor `data/terrain/**`. Run at this branch's
tip and again in a clean worktree at the **unmodified base commit `ef16544f`**,
the test fails identically both times:

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_terrain_bake_freshness.gd
  # branch tip 040aa73e : 3 tests, 8 assertions, 1 failed
  # base     ef16544f   : 3 tests, 8 assertions, 1 failed   (worktree, none of this lane's files)
```

So the committed Terrain3D bake was already stale against its config at the base
this lane branched from. The fix is a re-bake and a commit of `data/terrain/**`
— a large binary change in nobody-here's ownership. **Handed to the coordinator**;
it is a different failure from the `test_item_icons.gd` red that COMMON.md named
at lane start, which now **passes** (`verify-unit-tests (3)`: success).

One further job, `verify-regions-shard`, was **cancelled** rather than failed: it
ran warrens, relay_station and relay green and was killed inside `stronghold` at
the job's own 35-minute ceiling. A timeout, not a verdict, and not this lane's
either.

## 9c. A repo gap this lane surfaced: GLB textures the pickup/saddle landings did not commit

Running `godot --headless --path . --import` in a clean checkout of `ef16544f`
leaves **58 untracked files**: 51 `.import`/`.uid` siblings, and **7 textures
Godot extracts out of embedded GLBs**, each named for its own GLB and sitting
beside it —

```
assets/props/candy_pickup/candy_pickup_0.png        (beside candy_pickup.glb)
assets/props/mushroom_pickup/mushroom_pickup_0.png
assets/props/potion_plant/potion_plant_0.png, _1.png
assets/props/revive_flower/revive_flower_0.png
assets/props/riding_saddle/riding_saddle_0.jpg
assets/environment/team_tether/south_bridge_gate_0.jpg
```

**This repo's convention is to commit those**: 153 of them are already tracked
(`assets/characters/**/*_lod0_texture_0.png`, and `relay_apparatus_0.jpg` in the
very same `team_tether/` directory). The seven above are the ones whose GLBs
landed in `15751023` / `893df10e` / `9c14e5a7` — **the GLB was committed and the
texture Godot extracts from it was not.** Nothing is broken by that (they are
derived, and any import regenerates them, which is why CI is unaffected), so it
is a tidiness gap rather than a defect — but it belongs to those lanes' assets,
not this one's.

I removed all 58 from this container's working tree rather than committing 18 MB
of regenerable binaries onto a branch that owns none of those assets. **For the
coordinator:** either have the owning lane commit its seven textures, matching
the convention the other 153 follow, or add the pattern to `.gitignore` and drop
the 153 — but the two halves should agree, and today they do not.

## 10. Final state

- Branch: `ralph/W03-S08-FREEZE-0904`
- Commits: `05a99435` (the differential probe and the frozen pre-fix walker),
  `033f6add` (the root cause, the ledger rows and this report), and the commit
  carrying this line.
- Nothing outside the ownership list was touched. 58 files are left untracked in
  the working tree, deliberately, and none of them are this lane's:
  **51** are `.import`/`.uid` artefacts Godot wrote for *other lanes'* assets and
  scripts when this session ran `--import` (regenerated on any import, and the
  repo already tracks 432 `.png.import` and 969 `.gd.uid`, so the omissions are
  those lanes' to make good), and **7** are source images under `assets/props/`
  and `assets/environment/team_tether/` that were in the checkout before this
  session started (timestamps predate the first command run here) and belong to
  the pickup/saddle asset work landed in `9c14e5a7`. Committing another lane's
  un-reviewed assets onto this branch is exactly what the ownership rule is for,
  so this is flagged for the coordinator instead. The `.uid` files for this
  lane's own two scripts **are** committed.
- Acceptance: **S08-22 arrives** (row 7, 839.5 m, 0 held, plus 12 steps past
  it); the root cause is §3; both ledger rows are rewritten.

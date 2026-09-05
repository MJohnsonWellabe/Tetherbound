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
| the loaded segment path | live | arrives — 839.5 m, 0 held (segment run) |
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

## 10. Final state

- Branch: `ralph/W03-S08-FREEZE-0904`
- Commits: `05a99435` (the differential probe and the frozen pre-fix walker),
  `033f6add` (the root cause, the ledger rows and this report), and the commit
  carrying this line.
- Nothing outside the ownership list was touched. The 59 untracked
  `assets/**/*.png.import` files in the working tree are Godot's own import
  cache from running the engine here; they were left uncommitted deliberately.
- Acceptance: **S08-22 arrives** (row 7, 839.5 m, 0 held, plus 12 steps past
  it); the root cause is §3; both ledger rows are rewritten.

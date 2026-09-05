# W16-LOFT-BED-0904 — Grandpa's loft bed, and the submerged wake beat

Branch: `ralph/W16-LOFT-BED-0904` (from `origin/main` @ `ef16544f`).

Two owner-reported P1s, both root-caused by measuring rather than by re-running a probe
that already passed:

- CL-G12 / `CURRENT_STATE.md` §3 — *"I've never been able to sleep in the loft bed."*
- `CURRENT_STATE.md` §3 — *"at the beginning of the game, you are submerged in the bed
  rather than on it."*

---

## 1. The loft bed: what was actually wrong

**The passing smoke was the finding.** `smoke_home_sleep.gd::_stand_beside()` sets
`global_position` to the bed marker plus 1.5 m and lets the body drop; `smoke_gate_b_
continuous`'s sleep beat does the same. Nothing in the repository had ever walked up the
stair, so the prompt, the arbitration and the beat gate had all been "verified" over a
route the player does not have.

`tools/gate_f/probe_loft_bed_climb.gd` drives a real `CharacterBody3D` from the house's
ground floor on held stick input alone — no navigator, no teleport, the shape
`probe_fence_corner_trailgate_0903.gd` established for exactly this class of question.
On the shipped geometry it **froze on the top tread for 700 consecutive frames**:

```
-- toward the bed ((-3.4, 3.75, -1.1)) --
   t= 30 pos=(0.27, 3.2, -1.82) moved/30f=0.33m ...
   t= 60 pos=(0.27, 3.2, -1.82) moved/30f=0.00m floor=true wall=true
   ... 690 frames, every one of them moved/30f=0.00m ...
   WEDGE DIAGNOSIS at (0.27, 3.2, -1.82) (pushing (-0.98, 0.0, 0.19))
     on_floor=true on_wall=true
     touching: box size=(4.6, 0.25, 5.4) at (-2.4, 3.33, 0.0)     <- the loft slab
     touching: box size=(0.25, 0.4, 4.2) at (-0.1, 3.4, 0.6)      <- the loft edge beam
     _try_step_up gate 1 (headroom 0.35m blocked?) = false
     _try_step_up gate 2 (raised advance 0.25m blocked?) = TRUE
   BUDGET EXHAUSTED at (0.27, 3.2, -1.82) (closest 3.74m)
```

Two boxes, both `grandpa_house.gd`'s own, and the wedge is the corner they make:

**(a) The flight did not reach the floor it serves.** `_build_stairs()` climbed
`FLOOR_H` — the loft slab's *underside*. The slab is 0.25 m thick, so the top tread
topped out at 3.20 while the loft floor is at 3.45. That last quarter-metre was an
unmarked lip, crossable only by `player_controller.gd::_try_step_up`.

**(b) The loft edge beam stood proud of the loft floor, across the exit.** Its top sat at
3.60, 0.15 m above the loft floor, and it ran to z −1.5 — exactly the stair's own south
edge. A capsule sweeps its 0.4 m radius past its centre, and the stair's walkable z band
is only 0.365 m wide, so a body leaving the flight *always* overlaps that box. That is
what `_try_step_up`'s second gate (advance 0.25 m with the capsule raised
`STEP_HEIGHT` = 0.35 m) refused against. The file's own comment already recorded that this
beam had made "the loft a cell" once before and had been *shortened* in response;
shortening was half the answer, and the half it missed is why this recurred.

Nothing was wrong with the prompt, its 2.2 m radius, its beat gate, or interact
arbitration. The probe logs the arbiter's winner and the `SleepPrompt`'s own
`interaction_offer()` verdict every half-second throughout, and the moment a body is
beside the bed the arbiter offers `Sleep` and `activate()` returns true. The defect was
that a body could not get there.

Writing the guard test found one more piece of the same shape: the **loft rail** is a
1.2 m wall standing *on* the loft floor at the loft edge, and it also began at z −1.5.
The probe survived it (a wall you slide along, once the ledge is gone) rather than
cleared it, and a body leaving the top tread toward the bed walks into it.

### The fix (all in `scripts/world/grandpa_house.gd`)

| | before | after |
|---|---|---|
| flight climbs to | `FLOOR_H` 3.20 (slab underside) | `LOFT_TOP` 3.45 (the walking surface) |
| treads / riser | 10 × 0.320 m | 11 × 0.314 m |
| ledge at the loft edge | **0.250 m** | **0.000 m** |
| loft edge beam top | 3.60 (0.15 m proud) | 3.45 (flush; the 0.4 m depth now hangs *below* the slab) |
| loft rail north end | z −1.50 (the stair's own edge) | z −1.00 (`LOFT_RAIL_CLEAR_OF_STAIR`, one capsule radius + margin) |
| loft rail height | hardcoded 0.9 | derived: one riser + `RAIL_ABOVE_NOSING` |
| `stairs_top` marker | (0.5, `FLOOR_H`, −2.1) | (−0.8, `LOFT_TOP`, −2.1) |

Ten risers to `LOFT_TOP` would have been 0.345 m — five millimetres inside the step
budget, which is no budget at all. Eleven is 0.314 m, *shallower* than the 0.32 m the
flight already had, and `STAIR_RUN` is unchanged so the flight's footprint (which
`smoke_opening.gd::_the_way_down_is_marked` measures, and which `_build_furniture()`
keeps clear) is exactly where it was.

The rail's height is derived rather than declared because `_build_stair_rail()`'s own
comment records why the raked handrail must arrive within ~0.1 m of the loft rail's cap —
that near-match is what makes the two read as one rail turning a corner. The hardcoded
0.9 happened to match a ten-tread flight stopping at `FLOOR_H`; written as the arithmetic
it was always standing in for (one riser plus `RAIL_ABOVE_NOSING`), it still matches with
the flight 0.25 m taller: the raked head lands at 4.674, the loft rail's cap at 4.614,
**0.060 m apart**.

`stairs_top` mattered more than it looks: it named a point 0.3 m *east* of the loft edge
and a quarter-metre *below* the floor — precisely the spot a real body wedges on — so
anything that "walked to the stair head" arrived there and stopped, satisfied.

`grandpa_house.gd::_anchor()` replaces `to_global()` for the markers so the house can be
built and measured outside a live `SceneTree`, which is the only kind `tests/run_tests.gd`
can build. The house is never rotated or scaled by its placer, so the off-tree answer is
exact rather than approximate.

---

## 2. The wake beat: what was actually wrong

`tools/gate_f/probe_loft_bed_wake_pose.gd` stages the beat exactly as
`sequence_director.gd::_spawn_the_cast()` does and reports the mattress plane, where the
body settles, and the rendered AABB through the same `render_bounds.gd` the model's own
`_fit()` measures with (a skinned rig has to be measured the way the GPU draws it). Before:

```
mattress plane (top) : y=3.750
mattress footprint   : x -3.915..-2.885  z -1.865..0.265
BED_LIE_REACH        : 1.50   staged at (-3.4, 3.8, 0.4)
rendered body AABB   : size (0.848, 0.616, 1.800)
   world y 3.419 .. 4.034     z -1.400 .. 0.400
SUBMERSION           : 0.331 m of the body is below the mattress plane
```

**(1) The pose pivots on the feet.** `character_model.gd::set_lying()` tips the art −90°
about X, and `_fit()` has already put the art's origin at the character's *feet*. Rotating
−90° about X maps local +Y → world −Z and local +Z → world +Y, so a body that was 1.8 m
tall above the pivot becomes a body 0.616 m thick *centred on* it — half of it under the
surface it rests on. This is independent of where on the bed the body is placed, which is
why `OPENING-BED-0903` did not catch it: that round fixed a collapsed skin and read one
frame by eye for a different defect.

**(2) The staging point was off the mattress.** `BED_LIE_REACH` = 1.5 was reasoned to,
never measured. The mattress collider runs z −1.865 … 0.265 house-local and the rendered
lying body is exactly 1.800 m long in Z, so 1.5 put the feet at z 0.400 — 0.135 m past the
footboard.

### The fix (`scripts/story/sequence_director.gd`, wake pose/placement only)

- `BED_LIE_REACH` 1.5 → **1.20**: feet at 0.100, head at −1.700, centring the 1.800 m body
  in the 2.129 m mattress with 0.165 m clear at both ends.
- `lying_lift_for(model)` — static and public, so the capture tool and the probes measure
  the *shipped* number rather than a copy of it — measures the rig's own lying AABB and
  returns the lift that puts its underside on the surface, less `LIE_GEAR_SINK_M`.
- `_refresh_lying_lift()` applies it to the `Model` node every frame from the model's own
  `is_lying()`, the same "recomputed, never pushed" rule the door gate and the prompts keep.
  It has to be recomputed rather than pushed once, because `trainer_model.gd::_process()`
  clears the pose itself the moment the trainer moves, on a path this director never sees.
- The collision capsule is untouched: the wake beat's leave-the-bed radius, the Get-up
  prompt and everything else that measures from the body are where they were.

MEASURED_AFTER_PLACEHOLDER

---

## 3. Evidence

VALIDATION_PLACEHOLDER

---

## 4. Files changed

FILES_PLACEHOLDER

---

## 5. What I deliberately did not do

LIMITS_PLACEHOLDER

# W16-LOFT-BED-0904 — Grandpa's loft bed, and the submerged wake beat

Branch: `ralph/W16-LOFT-BED-0904`, from `origin/main` @ `ef16544f`.

Two owner-reported P1s, both root-caused by measuring rather than by re-running a probe
that already passed:

- CL-G12 — *"I've never been able to sleep in the loft bed."*
- *"at the beginning of the game, you are submerged in the bed rather than on it."*

Both are fixed, both against evidence a reader can reproduce from this branch.

---

## 1. The loft bed: what was actually wrong

**The passing smoke was the finding.** `smoke_home_sleep.gd::_stand_beside()` sets
`global_position` to the bed marker plus 1.5 m and lets the body drop;
`smoke_gate_b_continuous`'s sleep beat does the same. Nothing in the repository had ever
walked up the stair, so the prompt, the arbitration and the beat gate had all been
"verified" over a route the player does not have.

`tools/gate_f/probe_loft_bed_climb.gd` drives a real `CharacterBody3D` from the house's
ground floor on held stick input alone — no navigator, no teleport, the shape
`probe_fence_corner_trailgate_0903.gd` established for exactly this class of question.
On the shipped geometry it **froze on the top tread for 700 consecutive frames**:

```
-- toward the bed ((-3.4, 3.75, -1.1)) --
   t= 30 pos=(0.27, 3.2, -1.82) moved/30f=0.33m ...
   t= 60 pos=(0.27, 3.2, -1.82) moved/30f=0.00m floor=true wall=true
   ... 690 more frames, every one of them moved/30f=0.00m ...
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
`FLOOR_H` — the loft slab's *underside*. The slab is 0.25 m thick, so the top tread topped
out at 3.20 while the loft floor is at 3.45. That last quarter-metre was an unmarked lip,
crossable only by `player_controller.gd::_try_step_up`.

**(b) The loft edge beam stood proud of the loft floor, across the exit.** Its top sat at
3.60, 0.15 m above the loft floor, and it ran to z −1.5 — exactly the stair's own south
edge. A capsule sweeps its 0.4 m radius past its centre and the stair's walkable z band is
only 0.365 m wide, so a body leaving the flight *always* overlaps that box. That is what
`_try_step_up`'s second gate (advance 0.25 m with the capsule raised `STEP_HEIGHT` =
0.35 m) refused against. The file's own comment already recorded that this beam had made
"the loft a cell" once before and had been *shortened* in response; shortening was half the
answer, and the half it missed is why this recurred.

**Nothing was wrong with the prompt, its 2.2 m radius, its beat gate, or interact
arbitration.** The probe logs the arbiter's winner and the `SleepPrompt`'s own
`interaction_offer()` verdict every half-second throughout; the moment a body is beside the
bed the arbiter offers `Sleep` and `activate()` returns true. The defect was that a body
could not get there.

Writing the guard test found one more piece of the same shape: the **loft rail** is a 1.2 m
wall standing *on* the loft floor at the loft edge, and it also began at z −1.5. The probe
survived it (a wall you slide along, once the ledge is gone) rather than cleared it.

### The fix — `scripts/world/grandpa_house.gd`

| | before | after |
|---|---|---|
| flight climbs to | `FLOOR_H` 3.20 (slab underside) | `LOFT_TOP` 3.45 (the walking surface) |
| treads / riser | 10 × 0.320 m | 11 × 0.314 m |
| **ledge at the loft edge** | **0.250 m** | **0.000 m** |
| loft edge beam top | 3.60 (0.15 m proud) | 3.45 (flush; its 0.4 m depth now hangs *below* the slab) |
| loft rail north end | z −1.50 (the stair's own edge) | z −1.00 (`LOFT_RAIL_CLEAR_OF_STAIR`, one capsule radius + margin) |
| loft rail height | hardcoded 0.9 | derived: one riser + `RAIL_ABOVE_NOSING` |
| `stairs_top` marker | (0.5, `FLOOR_H`, −2.1) | (−0.8, `LOFT_TOP`, −2.1) |

Ten risers to `LOFT_TOP` would have been 0.345 m — five millimetres inside the step budget,
which is no budget at all. Eleven is 0.314 m, *shallower* than the 0.32 m the flight already
had, and `STAIR_RUN` is unchanged so the flight's footprint (which
`smoke_opening.gd::_the_way_down_is_marked` measures, and which `_build_furniture()` keeps
clear) is exactly where it was.

The rail's height is derived rather than declared because `_build_stair_rail()`'s own
comment records why the raked handrail must arrive within ~0.1 m of the loft rail's cap —
that near-match is what makes the two read as one rail turning a corner. The hardcoded 0.9
happened to match a ten-tread flight stopping at `FLOOR_H`; written as the arithmetic it was
always standing in for (one riser plus `RAIL_ABOVE_NOSING`), it still matches with the
flight 0.25 m taller: raked head 4.674, loft rail cap 4.614, **0.060 m apart**.

`stairs_top` mattered more than it looks: it named a point 0.3 m *east* of the loft edge and
a quarter-metre *below* the floor — precisely the spot a real body wedges on — so anything
that "walked to the stair head" arrived there and stopped, satisfied.

`_anchor()` replaces `to_global()` for the markers so the house can be built and measured
outside a live `SceneTree`, which is the only kind `tests/run_tests.gd` can build. The house
is never rotated or scaled by its placer, so the off-tree answer is exact.

---

## 2. The wake beat: what was actually wrong

`tools/gate_f/probe_loft_bed_wake_pose.gd` stages the beat exactly as
`sequence_director.gd::_spawn_the_cast()` does and reports the mattress plane, where the
body settles, and the rendered AABB through the same `render_bounds.gd` the model's own
`_fit()` measures with. Before:

```
mattress plane (top) : y=3.750     footprint x -3.915..-2.885  z -1.865..0.265
BED_LIE_REACH        : 1.50        staged at (-3.4, 3.8, 0.4)
rendered body AABB   : size (0.848, 0.616, 1.800)   world y 3.419 .. 4.034   z -1.400 .. 0.400
SUBMERSION           : 0.331 m of the body is below the mattress plane
```

**(1) The pose pivots on the feet.** `character_model.gd::set_lying()` tips the art −90°
about X, and `_fit()` has already put the art's origin at the character's *feet*. Rotating
−90° about X maps local +Y → world −Z and local +Z → world +Y, so a body that was 1.8 m tall
above the pivot becomes a body 0.616 m thick *centred on* it — half of it under the surface
it rests on. This is independent of where on the bed the body is placed, which is why
`OPENING-BED-0903` did not catch it: that round fixed a collapsed skin and read one frame by
eye for a different defect.

**(2) `BED_LIE_REACH` = 1.5 was reasoned to, never measured**, putting the feet past the
footboard.

**(3) `_bed_mattress_collider()` stood 0.30 m off the bed it represents.** `BedTwin.obj`'s
AABB is offset 0.601 from its own origin in Z (`pos=(-1.029, -0.012, -1.529)`,
`size=(2.061, 1.558, 4.259)`). `_furnish` draws the mesh AT the placement point, so the bed a
player sees runs z −1.564 … 0.565 house-local — while the collider, built from `aabb.size`
alone and hung on the placement point, ran −1.865 … 0.265. A strip of open air past the
footboard read solid; a strip of real mattress at the foot end read empty. Invisible until
something tries to lie on it. **This is what made the position defect look unfixable:** the
placement the collider's own footprint calls "centred" is the one the judge below calls
broken.

### The fix

`grandpa_house.gd::_bed_mattress_collider()` now centres the blocker on the mesh (x and z
only — the height stays capped at 0.3 m with its base at the placement point, so a body
lands at mattress height, not headboard height).

`sequence_director.gd` (wake pose / placement only):

- `BED_LIE_REACH` 1.5 → **1.40**: feet at z 0.300, head at −1.500, ~0.12 m clear of the
  headboard and ~0.11 m of the footboard. Only reachable once the collider was corrected —
  feet this far out used to fall off the blocker onto the loft floor.
- `lying_lift_for(model)` — static and public, so the capture tool and the probes measure
  the *shipped* number rather than a copy of it — measures the rig's own lying underhang
  (0.308 m for the trainer) and subtracts `LIE_KIT_SINK_M`, giving **0.080 m**.
- `_refresh_lying_lift()` applies it to the `Model` node every frame from the model's own
  `is_lying()`, the same "recomputed, never pushed" rule the door gate and the prompts keep.
  It must be recomputed rather than pushed once, because `trainer_model.gd::_process()`
  clears the pose itself the moment the trainer moves, on a path this director never sees.
- The collision capsule is untouched: the leave-the-bed radius and the Get-up prompt are
  where they were.

After: `world y 3.523 … 4.139`, `z −1.500 … 0.300`, **supported by the MATTRESS**, and the
0.227 m still under the plane is the slung kit rather than the body.

### Both numbers were chosen by a code-blind judge, not by me

Each round rendered a ladder of candidate values from one fixed camera, shuffled the panels,
and gave a sub-agent only the sheet, `docs/reference/` and the visual-judge skill — no code,
no hypothesis, no hint which panel was which.

**Round 1 — height** (`_sheet_bed_lift.png`; rungs 0.00 / 0.08 / 0.16 / 0.24 / 0.33 m). The
judge reconstructed the ladder correctly from the pixels alone and picked the 0.08 rung,
alone: *"the boot soles sit on the blanket's top plane with the full sole visible and no
slicing… this is the only panel in the set with correct contact."* It called 0.00 sunk
(*"both boot soles are gone… the left forearm and gauntlet punch through the front face of
the mattress"*) and 0.33 flying (*"the only thing touching the bed is a large tan pouch
strapped at the hip… so the figure reads as a body suspended from a bag, which is exactly
backwards"*). Its diagnosis of *why* the ladder had to exist is the reason `LIE_KIT_SINK_M`
exists: *"there is no height at which both the body and the pack sit correctly."*

**Round 2 — position along the bed** (`_sheet_bed_place.png`; rungs 0.00 / 0.10 / 0.20 /
0.30 m toward the footboard). It picked 0.20, alone: *"the only panel with real clearance at
both ends… the head is genuinely ON the pillow, with dark pillow visible both in front of and
behind the skull."* It called the then-shipped placement broken — *"the headboard's top-rail
corner cuts a hard straight vertical edge across the character's face; the chin, jaw and the
whole back of the skull are behind it"* — and the next rung down a body *"slipped down in the
night"* with its toes fused into the footboard rail. Following that finding back through the
geometry is what turned up defect (3).

**The shipped tree reproduces the judged frame**: re-rendering `tools/_capture_bed_wake.gd`
on the final commit and differencing it against the judged panel gives a **mean absolute
difference of 1.76/255** over the full 1280×720 frame — dither and AA noise, no structural
change. So no third judging round was needed to confirm the realisation.

---

## 3. Evidence

Every command below was run on this branch, in this container, on Godot 4.7-stable.

**Unit** — `godot --headless --path . --script tests/run_tests.gd -- --only=test_loft_bed_reachable.gd`
→ **6 tests, 14 assertions, 0 failed.**

A green test is not evidence until it has been seen failing for the right reason. Each check
was watched going red on the geometry it guards, then restored:

| reverted | the check that went red |
|---|---|
| flight back to `FLOOR_H`, 10 treads | `test_the_flight_arrives_at_the_loft_walking_surface` |
| beam top back to 0.15 m proud | `test_nothing_stands_proud_of_the_loft_floor_at_the_stair_head` |
| `LOFT_RAIL_CLEAR_OF_STAIR` → 0.0 | `test_nothing_stands_proud_of_the_loft_floor_at_the_stair_head` |
| `stairs_top` back to (0.5, `FLOOR_H`, …) | `test_the_stairs_top_marker_stands_on_the_loft` (3.20 ≠ 3.45; east of the loft edge) |
| `BED_LIE_REACH` back to 1.5 | `test_the_wake_pose_lies_inside_the_mattress` (feet at z 0.400, past the footboard) |
| Sleep prompt radius → 0.5 | `test_the_sleep_prompt_reaches_a_body_standing_on_the_loft` (1.09 m away, outside 0.50 m) |
| mattress collider un-centred | `test_the_mattress_blocker_stands_where_the_bed_is` (stands at −0.800, bed at −0.500) |

**Probes**

- `godot --headless --path . --script tools/gate_f/probe_loft_bed_climb.gd` (synthetic
  house — seconds to boot, so the stair can actually be iterated on) →
  `PROBE RESULT: the loft bed is reachable on foot in the synthetic house`. Stair foot in
  47 frames, the loft slab in 57, the bed in 26; arbiter `Sleep`, `activate()` true.
- `godot --headless --path . --script tools/gate_f/probe_loft_bed_reach.gd` (the **real**
  booted Meadows, beat `free_play`) → `PROBE RESULT: the loft bed is reachable and sleepable
  on foot`, exit 0:
  ```
  -- toward stair foot  -- ARRIVED after 64 frames at local (3.85, 0.12, -1.71)
  -- toward stair head  -- ARRIVED after 56 frames at local (0.18, 3.45, -2.12)
  -- toward the bed     -- ARRIVED after 26 frames at local (-1.9, 3.45, -1.53)
                           arbiter='[X] Sleep'   bed d=1.77 r=2.20 offer=YES
  activate()=true   day 1 -> 2
  ```
- `godot --headless --path . --script tools/gate_f/probe_loft_bed_wake_pose.gd` →
  `PROBE RESULT: the wake beat lies ON the mattress`.

**Smokes** (the three the brief names), each `godot --headless --path . --script tests/<file>`:

| smoke | result |
|---|---|
| `smoke_gate_a_rest_torch.gd` | **passed**, exit 0 — including the new leg: `climbed the loft stair on stick input alone: house-local (-0.17, 3.45, -2.1)` / `slept in Grandpa's loft bed after walking up the stair: day 3 -> 4` |
| `smoke_opening.gd` | **OK** — `opening: OK — talked, chose, named, and the creature is in the party`, exit 0. Its own `[walk]` trace now climbs to the loft (`toward (-22.8, 4.7, -18.1) -> at (-23.3, 4.7, -18.1)`) and back down. |
| `smoke_gate_a_opening_segment.gd` | **OK** — `gate A opening segment: OK — title through natural catch passed continuously with parsed controller input`, exit 0 |

**Re-run on the shipped tree.** The table above was produced before the two blind-judged
numbers landed, so all three were re-run on the final commit — the mattress-collider
correction is physics-affecting, and a smoke that passed on an earlier tree is not evidence
for this one. All three green again on first attempt: `REST_EXIT=0 OPEN_EXIT=0 SEG_EXIT=0`,
with `climbed the loft stair on stick input alone: house-local (-0.17, 3.45, -2.1)` /
`slept in Grandpa's loft bed after walking up the stair: day 3 -> 4` unchanged.

**Runtime validation beyond the tests.** The climb is driven by held stick input through
`player_controller.gd`'s real `move_and_slide`/`_try_step_up` path in both probes and in the
new smoke leg — no navigator, no waypoint teleport after the one that puts the body on the
ground floor. The sleep is pressed through the real `interaction_arbiter` on whatever it is
actually offering, and asserted by the day advancing through the shared `night_rest.gd`.

**Frames.** `tools/_capture_bed_wake.gd` (Compatibility renderer under xvfb, never
`--headless` with a rendering driver). Two contact sheets are committed, one per judging
round, plus the verdicts quoted above. Per-frame PNGs are not committed.

---

## 4. Files changed

```
scripts/world/grandpa_house.gd            stair, loft beam, loft rail, stairs_top, mattress collider, _anchor()
scripts/story/sequence_director.gd        BED_LIE_REACH, lying_lift_for(), _refresh_lying_lift()  (wake pose/placement only)
tests/test_loft_bed_reachable.gd          new — 6 checks, each watched going red
tests/smoke_gate_a_rest_torch.gd          new leg: walk the stair on stick input and sleep
tools/gate_f/probe_loft_bed_climb.gd      new — synthetic-house climb with wedge diagnosis
tools/gate_f/probe_loft_bed_reach.gd      new — the same climb in the real booted Meadows
tools/gate_f/probe_loft_bed_wake_pose.gd  new — the wake beat measured against the mattress
tools/_capture_bed_wake.gd                reads the shipped reach and lift instead of its own copies
docs/CURRENT_STATE.md                     both P1 rows rewritten with the mechanism
ralph/reports/W16-LOFT-BED-0904/          this report + the two judged contact sheets
```

Nothing outside the lane's ownership list is touched. Note for the coordinator: the
container's `godot --import` generated `.import`/`.uid` artefacts for other lanes' assets
(candy/mushroom/potion/revive/saddle/bridge-gate) and an early `git add -A` swept them into
commit `cd8ece4b`, ~18 MB of extracted textures. They are removed from the branch tip, so the
**merged tree is clean**, but they remain in this branch's object history — a squash merge
keeps them off `main` entirely. Force-push would have been the tidier fix and the lane rules
forbid it, so this is flagged rather than fixed.

---

## 5. Known limitations, and what I deliberately did not do

- **The wake frame is still not a sleeping pose, and that is not a number.** The round-2
  judge was explicit that placement is now solved and the frame is not: *"the pillow is a
  hard, faceted wedge and the head rests on its crest without displacing it a millimetre";
  "arms folded high and symmetrically across the chest, both legs dead straight… it reads as
  a figure laid out on a board"; "no contact shading"*. Fixing those needs bedding
  deformation, a contact shadow, and a slack asymmetric pose — a rig/asset change, and
  `character_model.gd`'s own comment records that neither human rig has a lie-down clip and
  that authoring one needs owner reference art. **Out of scope, and left open in
  `CURRENT_STATE.md`'s row rather than silently dropped.**
- **The trainer sleeps in full kit, boots on, on top of the covers.** The round-1 judge's
  preferred fix for the kit-sink problem is *"to not have the pack on the character while
  they sleep"*. That is an asset/rig decision, not a placement one; `LIE_KIT_SINK_M` is the
  honest workaround and says so in its own comment.
- **`_furnish()`'s generic collider has the same off-centre bug** as `_bed_mattress_collider`
  did — it boxes `aabb.size` around the placement point and ignores `aabb.position`. I fixed
  only the bed's, because correcting the generic one moves the table, chairs, desk, cabinet,
  bookcases, nightstand and Grandpa's own bed all at once, across the three walked lanes
  `smoke_opening` checks. That is its own task with its own evidence, not a rider on this one.
- **`character_model.gd::set_lying()`'s comment does not match what renders.** It states the
  −90° rotation lands the face *"on world −Y, into the pillow… a prone sleeping pose"*; every
  frame in this lane shows the trainer supine, face up. The arithmetic in this report agrees
  with the frames (local +Z, the face, maps to world +Y). The comment is wrong, not the code
  — I did not edit it, as that file is outside the lane's ownership.
- **`smoke_home_sleep.gd` still teleports onto the loft.** It is not in this lane's ownership
  list. It passes, and it is exactly the harness path whose gap this lane closed, so it is
  worth someone re-pointing it at the stair.
- I did not touch the interaction arbiter, its rules, or the prompt radius: the probe proved
  the defect was not there.

---

## 6. Landing

Branch `ralph/W16-LOFT-BED-0904`. Three commits:

- `cd8ece4b` — the stair reaches the loft; the wake beat's first pass
- `5c97ce1c` — the guard test, and the loft rail pulled clear of the stair opening
- `60714b24` — **the last code commit**: the mattress blocker centred on the bed, and the
  two blind-judged numbers (`lying_lift_for` 0.080 m, `BED_LIE_REACH` 1.40)

This report and the `CURRENT_STATE.md` rows sit in a docs commit on top of `60714b24`;
the branch tip is `f565ffc9`. Every number and every verdict in this
report was produced on the tree at `60714b24`.
Pushed to `origin/ralph/W16-LOFT-BED-0904`. No pull request opened, per the lane rules.

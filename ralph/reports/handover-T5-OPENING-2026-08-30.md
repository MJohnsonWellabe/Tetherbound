# T5-OPENING handover — 2026-08-30

Branch: `ralph/T5-OPENING`, off `origin/main` at `1d7fc8e7`.

Items: **OP-0830-4** (trapped in Grandpa's house), **OP-0830-1** (the village
gate does not gate), **OP-0830-2** (the key does not glow).

Everything below was measured on the real world before it was changed, and
measured again after. Where a claim rests on a config assertion rather than on a
played path, it says so.

---

## OP-0830-4 — trapped in Grandpa's house · FIXED

> *"after the first conversation with grandpa you're trapped in his house with
> nothing telling you to talk to him again before you can go."*

### What was actually wrong

Reproduced with `tools/_probe_house_trap.gd`, which forces the director onto each
beat the house door covers and prints what the player is looking at:

| beat | door | tracked objective |
|---|---|---|
| `wake` | solid | **"Catch your first wild creature."** |
| `house` | solid | **"Catch your first wild creature."** |
| `return_starter` | solid | **"Catch your first wild creature."** |

From the first frame of a new game — lying in bed, upstairs, behind a shut door —
the one line of guidance in the game named an action the player could not take
for another three beats. Nothing anywhere named the action that opens the door.

Three separate mechanisms had to fail together for that to be the state:

1. **`data/progression/objectives.json` had no rung before the catch.** Its own
   comment claimed the catch entry "covers wake/Grandpa/starter/naming/walk-out
   for free … the sequence director's own prompts are already the guidance". The
   playtest falsified that sentence; it is now recorded as falsified, in place.
2. **`sequence_director.gd::_refresh_door_gate` called the player back only on the
   `house` beat.** Spec §1D's callout ("walk toward the door, get called back,
   end up in the conversation naturally") was implemented for the *first*
   required conversation and not for the second. `return_starter`'s conversation,
   `grandpa_first_catch`, carries `beat:first_encounter` and is the **only thing
   in the game that opens that door** — and pushing on the door there did
   literally nothing.
3. **Grandpa's prompt does not reach the door.** 4.0m radius, ~7m from the
   doorway across a 9.4m room.

### What changed

* `data/progression/objectives.json` — three rungs ahead of the catch, each keyed
  on an `opening:beat:*` flag `sequence_director.gd` has always written. No new
  boolean was invented.
* `scripts/story/sequence_director.gd` — `DOOR_CALLOUT_BEATS` now covers
  `return_starter` as well as `house`, guarded against the beats where a modal is
  up (which is what the old single-beat restriction was really protecting).
* `scripts/story/sequence_director.gd` — beat flags are written as **history**
  (`_persist_beat_history`), not one at a time. Two paths reach a beat without
  writing the ones before it (the compatibility inference in
  `_restore_opening_beat`, and a mid-session Load), and either would have left
  the new ladder pointing at a rung the player passed an hour ago.
* `data/config/opening.json` — Grandpa's prompt radius 4.0 → 5.0.

### Played evidence

`tests/smoke_opening.gd`, driven end to end:

```
shut in: the tracked line reads 'Show Grandpa your creature before you head out.'
shut in: the hint card reads 'He has not moved from the table. X to talk -- he
         has orbs for you, and the door is his to open.'
shut in: pushing on the door called Grandpa back — 'grandpa_first_catch' opened
         with no interact press
```

### The coverage failure, which is part of the defect

`smoke_opening.gd` and `smoke_wake_softlock.gd` both passed through this beat.
They passed because between them they cover the `wake` beat's exit and the two
conversations, and **neither ever asked what the player is looking at while the
door is solid**. `smoke_opening` in particular found Grandpa by searching the
scene tree for an interactable whose label contains "grandpa" — omniscience no
player has — and then asserted only what the conversation does.

Both are fixed, and deliberately at different altitudes:

* **`smoke_opening.gd`** gains `_the_player_is_told_how_to_get_out_of_the_house()`
  before the omniscient step. Two independent proofs, because either alone can
  hold while the player is stuck: the tracked line must name Grandpa and must not
  be the catch line, **and** a player who does nothing but walk at the doorway
  must be released.
* **`smoke_wake_softlock.gd`** gains the general invariant at *every* gated beat,
  not the two somebody remembered: **a beat that physically confines the player
  must tell them what ends it** — a modal, a door callout, or a tracked line
  naming it. The gated-beat list is derived from `opening_beats.gd`, so a beat
  added to `opening.json` is covered the day it is added.

**Verified red before green.** With the fix stashed:

```
FAIL: SILENT WALL on beat 'name': the door is solid, no modal is up, walking into
      the doorway does nothing, and the tracked objective reads 'Catch your first
      wild creature.'. The player has been confined and told nothing that ends it.
FAIL: SILENT WALL on beat 'return_starter': ... (same)
```

A test that would still pass with the player stuck is worthless; this one does
not.

---

## OP-0830-1 — the village gate does not gate · FIXED

> *"the village gate is pointless. it doesn't keep you in. it should keep you in
> until you find the key."*

### What was actually wrong

`tools/_probe_village_gate_escape.gd` stands the player in the square with no key
and walks them out on sixteen bearings with the real controller path:

```
escaped the village on 9 of 16 bearings
  bearing   0.0 deg ->  77.1m from the square   OUT
  bearing  67.5 deg ->  75.4m                   OUT
  bearing 112.5 deg ->  64.5m                   OUT
  bearing 135.0 deg ->  79.0m                   OUT
  ... nine in total, up to 79m
```

`tools/_probe_village_layout.gd` says why. Sweeping 36 bearings for the nearest
solid body between 20m and 90m of the well, **24 of them had nothing at all**.
The gate's `seal_half_width` wings covered roughly 24m of one bearing; the
settlement was open on every other side. The flag logic was correct throughout —
which is the owner's whole point, and why a test asserting the flag proved
nothing.

Two more things fell out of the measurement, neither guessed:

* **The gate leaf stood at 38° to the road it barred.** `GATE_YAW_DEG` was `71.0`;
  the perpendicular to that road is `-71.6`. The constant's own comment already
  recorded that it "was tuned by eye against a render rather than computed", and
  the eye got the sign.
* **The key at (31.2, −8.4) falls outside the line the fence now takes.** A key
  on the far side of the wall is a key the confined player cannot reach.

### What changed

Per `MEADOWS_PROGRESSION_SPEC` §1E — *"a believable physical perimeter … invisible
collision only as support for visible boundaries, not as the only boundary."*

* **`data/config/village_boundary.json`** authors the settlement's edge as a
  closed line and names a gate wherever one of `terrain_playground.json`'s four
  village roads crosses it.
* **`scripts/world/village_boundary.gd`** builds that line from the settlement's
  own `fence_run` prefab (D24: one village family), two courses, ground-sampled.
  It **imports `road_gate.gd`'s wing lesson wholesale rather than relearning it**:
  each panel's collider is sized from the lowest and highest ground its *whole
  footprint* spans, which is the defect that let the Sigil Gate be walked around
  at +6m off centre while a span check reported a contiguous barrier the whole
  time.
* **One lock, two doors.** Both leaves are `road_gate.gd` with `castle_gate_key` /
  `road_gate_open`. Opening either swings the other on the same frame; a reload
  restores both through the flag `road_gate.gd` already reads. This is what lets
  the fence cross two roads without a second key or a second progression fact —
  and it is why **no village road dead-ends at a fence**, which a naive ring
  would have caused.
* **The gate moves onto the line** at the computed road crossing (38.7, −19.9) at
  the computed perpendicular; **the key moves inside it** to (30.7, −15.9).
* `tools/_probe_key_site.gd` was rewritten for the world that now exists: it
  searches for a point *inside* the boundary, on real ground, ≥5m from every live
  prompt and ≥3m from every fence panel, closest to the gate — reading its
  neighbours off the built scene instead of the transcribed landmark list that
  had gone stale.

### Played evidence — both halves

Same probe, same sixteen bearings, after:

```
escaped the village on 0 of 16 bearings: []
```

and then, with the key taken and the gate tried:

```
key held: 1
gate open: true   road_gate_open flag: true
walked to (66.6, -2.2, -29.5) -- 29.5m past the gate, 59.8m from the square (THROUGH)
```

`tests/test_village_boundary.gd` pins the *shape* without booting a world, which
is where a boundary goes wrong silently:

* every Band 0 place that must be inside is inside — the farmhouse and its plots,
  the whole village cast, the tournament ground, and **the practice bramblebun the
  opening's first catch happens on** (had that fallen outside, the boundary would
  have locked the player away from their own chapter);
* the trailhead, the pond, Band 1 and the South Bridge are outside;
* every gate sits on the line;
* every authored road that crosses the line leaves through a gate.

---

## OP-0830-2 — the key does not glow · COVERED BY `ralph/T5-FEEL`, NOT DUPLICATED

The brief said to check `origin/ralph/T5-FEEL` first and use its shared highlight
rather than inventing a second one. It had landed: `scripts/world/pickup_glow.gd`,
`shaders/pickup_glow.gdshader`, and — already — the two-line attach/detach in
`scripts/world/key_pickup.gd` itself, with a comment naming OP-0830-2 by number.

**So this lane wrote no glow code, deliberately.** A second highlight on the one
pickup the player meets first is exactly the inconsistency OP-0830-3 exists to
prevent.

What this lane *did* contribute to it: the key's **placement** changed (it had to,
to be inside the wall), and `tools/capture_village_boundary.gd`'s frame
`05-the-key-from-the-road` looks at it from the range and angle a player actually
approaches on the road, which is the one thing the T5-FEEL lane could not have
framed.

**Open, for whoever lands both branches:** the glow and the new key position have
not been seen *together* — they are on two branches. Re-run
`tools/capture_village_boundary.gd` after the merge and look at frame 05 before
calling OP-0830-2 closed.

---

## Test results

| | |
|---|---|
| unit suite (118 files) | pass, after adding the three new rungs to `test_gateb_objective_chain.gd`'s ladder |
| `test_village_boundary.gd` (new) | 5 tests, 22 assertions, pass |
| `smoke_opening.gd` | pass |
| `smoke_wake_softlock.gd` | pass (and verified red against the pre-fix code) |
| `smoke_gate_a_opening_segment.gd` | pass |
| `smoke_traversal.gd` | pass — the world perimeter, the South Bridge, the Old Mill Crossing and the Sigil Gate all still hold |

### Failures that are not this lane's, said plainly

* **`smoke_gate_a_build_segment_meadows.gd`** — fails on *"there is no hammer in
  the satchel"*. Pre-existing and structural: `build_open` has no pad button by
  owner directive (`OWNER_DIRECTIVES_2026-08-22` §22), so the reusable segment
  falls to the hammer route, and this wrapper's fixture stages wood and stone but
  no hammer. The test is **not wired into CI**, deliberately —
  `ralph/reports/gate-f-historical-snapshot.md` names it among the tests left
  unwired because *"a red job added blind is worse than an unwired test"*. Nothing
  in this branch touches the hammer, the fixture or the bindings.
* **`smoke_gate_b_continuous.gd`** — see the open question below.

---

## Open / handed on

1. **`smoke_gate_b_continuous.gd` fails at Mira's orb recipe** — *"Mira's required
   opening visit left 'recipe_orb_basic' unset"*. `gate_a_npc_gather_segment.gd`
   asserts `recipe_orb_basic` immediately after visiting Tam, on the stated
   assumption that *"Mira's required opening visit grants the Basic Orb pattern"* —
   but `smoke_gate_b_continuous`'s own step order plays the opening, sets
   `road_gate_open` directly, and goes straight to the tools segment, never
   visiting Mira. **Attribution is stated below the results table; do not treat
   this as settled until that run is on the record.**
2. **Performance.** The boundary adds ~40 fence panels (each two `fence_run`
   courses) plus 40 collision boxes to a settlement the player spends their first
   twenty minutes in. That is new geometry against a ROG budget that, per
   OP-0830-6, has never been measured. Flagged to `T1-PERF` rather than guessed
   at; `wall.panel_length_m` in `village_boundary.json` is the single knob that
   trades panel count against silhouette.
3. **The Rise and Practice Meadow roads now end inside the fence.** The Rise's
   trailhead signpost at (75.4, −38.9) is outside and reached through the gate;
   the practice meadow is entirely inside, which is what keeps the opening's first
   catch reachable before the key. Neither road dead-ends, but nobody has walked
   The Rise past the gate since it moved.
4. **The corridor out of Band 0 leaves by the Pond gate.** A player heading due
   north for the South Bridge meets fence and has to walk along it to the gate at
   (−21, 21). That is how a walled village works, and it is ~40m of walking, but
   it is a change to the shape of the first walk out and it has not been played
   end to end.

---

## Files

**New**
- `data/config/village_boundary.json`
- `scripts/world/village_boundary.gd`
- `tests/test_village_boundary.gd`
- `tools/_probe_house_trap.gd`, `tools/_probe_village_gate_escape.gd`,
  `tools/_probe_village_layout.gd`, `tools/capture_village_boundary.gd`

**Changed**
- `data/progression/objectives.json` — three opening rungs
- `data/config/opening.json` — Grandpa's prompt radius
- `scripts/story/sequence_director.gd` — door callout, beat history
- `scripts/world/playground_world.gd` — the boundary replaces the lone gate; key re-sited
- `tests/smoke_opening.gd`, `tests/smoke_wake_softlock.gd`,
  `tests/test_gateb_objective_chain.gd`, `tests/helpers/gate_a_material_route.gd`
- `tools/_probe_key_site.gd`, `tools/_probe_road_gate.gd` — `RoadGate` now hangs
  under `VillageBoundary`, so the lookups search rather than index the world root

**Untouched, per the ownership split:** `stronghold.gd`/`landmark.gd`, terrain and
grass and scatter configs, `species.json` and the spawn tables, `objectives.json`'s
`local` array and the camp files, `performance.json`. The one UI-adjacent edit is
the objective *data* the hint card already draws — no UI scene was changed.

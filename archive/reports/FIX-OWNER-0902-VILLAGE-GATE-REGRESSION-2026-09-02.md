# FIX — village gate still not on every exit / still jumpable (owner playtest 2026-09-02, item 3)

**Verdict: a real gap at the outline's polygon corners, not a road missing a
gate.** Every authored road that actually crosses the village boundary
(`terrain_playground.json`'s `paths.routes`) already has a gate — confirmed
architecturally true both before and after this fix, unchanged. The
owner-visible "no gate on a road" and "can still jump it" are the same
underlying defect: the fence was built as a sequence of independent straight
panels, and where two panels meet at a polygon vertex, nothing before this
fix ever sealed the bend between them or tested a corner at all.

## Why the previous two landings didn't hold

1. `OWNER-0901-VILLAGE-GATE-ROADS` (first attempt) closed with "nothing to
   fix" from a config read, no pushed branch, no run probe. Wrong — reopened
   by direct play the same day.
2. `OWNER-0901-VILLAGE-GATE-ROADS-V2` (`5b934766`) reproduced against the
   live scene with `tools/_probe_village_gate_roads_v2.gd` and found real
   vaulting: collision-top clearance above ground was only 1.41-1.46m
   against a 1.35m jump apex. Fixed with a `vault_guard_m` height pad on
   every fence panel and both gate leaves. This genuinely fixed vaulting —
   confirmed again in this pass, panel clearance margins are now 1.11m+
   everywhere — but the probe's own "jump-assisted escape" sweep only ever
   sampled **8 of the ring's ~45 panels by index and never tested a single
   polygon corner**, despite its docstring describing a full ring sweep.
   That is the structural reason the fix looked green and still failed
   under real play a second time: the actual gap was never in the part of
   the fence the probe was checking.

## What was checked and ruled out

- **Road crossings** (`PART 1`): unchanged and correct — only "The Rise" and
  "The Pond" cross the authored outline, and both are gated (`RoadGate`,
  `PondGate`), 0.0-0.1m off the computed intersection. "Grandpa's House",
  "The Inn", and "Practice Meadow" stay inside the boundary by design.
- **Fence panel height** (`PART 2`): exhaustive across all 47 panels, not a
  sample — min margin 1.11m over `movement.json`'s 1.35m jump apex, both
  before and after this fix. Not the residual bug.
- **Straight-run bearing walk** (`PART 3`): all 16 bearings held, before and
  after. Not the residual bug (a plain walk, no jump, wouldn't find a
  vault-only gap anyway).

## The actual bug

Each fence panel (`village_boundary.gd::_build_panel`) is a thin (0.5m)
oriented slab running along one straight outline edge, overshooting that
edge's own endpoints by 0.15m so consecutive panels on the *same* edge
overlap. The outline turns by 5-70 degrees at each of its 22 vertices
(measured directly from `village_boundary.json`'s own points), and two thin
slabs pointed in different directions, each ending 0.15m past a shared
point, do not sweep the wedge between them — a box's own end is a flat cut
perpendicular to its length, not a mitre matched to the next edge's angle.
Nothing before this fix ever built anything at a vertex, and nothing before
this fix ever tested one.

## The fix, in three rounds (each one measured, not guessed)

1. **`_build_corner_guards()`** (new): one small axis-aligned collision post
   centred on every outline vertex (skipping the one vertex already
   handled by the existing hand-tuned gate-jamb design next to RoadGate),
   sized to the same fence height + `vault_guard_m` already used for
   panels. First landed at `POST_HALF = 0.6`.
2. The exhaustive re-test below caught **one** corner (index 3, `(18,21)`)
   still escaping at that setting. `tools/_diag_corner3.gd` (a direct
   inspection of the built collider and real ground heights, not another
   guess) found real overlap between the post and each adjacent panel's own
   near corner was only ~0.29-0.30m — a knife's-edge margin that held for
   most running-jump timings and failed on one. `POST_HALF` widened to
   `1.1` (~0.8m of true overlap).
3. Re-testing the same corner (`tools/_diag_corner3_jump.gd`) still escaped,
   but landed at world Y≈1.4 — within centimetres of that corner's own
   measured collision top, not out in open air past a cleared barrier the
   way every held panel's landing did. `movement.json`'s 1.35m jump apex,
   launched from the local ground there (-0.4 to -1.1), cannot reach a
   fixed world height of 1.39-1.5 on its own, so this reads as a
   character-controller edge/step interaction at the post's own convex top
   corner — geometry a flat mid-span panel never presents, which is
   consistent with all ~45 panels holding clean throughout. Added
   `CORNER_EXTRA_HEIGHT_M = 3.0`, applied only at corners (panels were
   already proven clean at the existing margin, so `vault_guard_m` itself
   was left untouched).

## Evidence — final exhaustive run, after all three rounds

`godot --headless --path . --script tools/_probe_village_gate_roads_v2.gd`,
now literally exhaustive (PART 5 tests every fence panel, PART 6 — new —
tests every outline corner, neither is a sample):

```
=== PART 1: road crossings against the authored boundary ===
  route 'Grandpa's House ' end=(-18.0, -15.0)  NEVER LEAVES the boundary (interior road, no gate needed)
  route 'The Inn         ' end=(0.5, -9.0)  NEVER LEAVES the boundary (interior road, no gate needed)
  route 'Practice Meadow ' end=(30.0, -40.0)  NEVER LEAVES the boundary (interior road, no gate needed)
  route 'The Pond        ' crosses boundary at (-21.0, 21.0) -- nearest gate PondGate at 0.0m (clear=3.4m) -> GATED
  route 'The Rise        ' crosses boundary at (38.7, -19.8) -- nearest gate RoadGate at 0.1m (clear=3.4m) -> GATED

=== PART 2: real collision heights vs jump apex ===
  fence panel clearance ABOVE LOCAL GROUND: min=2.46m max=3.58m avg=2.68m over 47 panels
  clearance vs jump apex (1.35m): min margin=1.11m
  gate 'RoadGate' leaf clearance ABOVE LOCAL GROUND=2.41m  margin vs jump apex=1.06m
  gate 'PondGate' leaf clearance ABOVE LOCAL GROUND=2.41m  margin vs jump apex=1.06m

=== PART 3: fine bearing sweep, polygon-containment ground truth ===
  all 16 bearings: held (inside)

=== PART 4: jump-assisted escape at both gates ===
  RoadGate: held (inside) on every timing tried
  PondGate: held (inside) on every timing tried

=== PART 5: jump-assisted escape at EVERY ordinary fence panel (not gates) ===
  47 of 47 panels: held (inside) on every timing tried

=== PART 6: jump-assisted escape at EVERY outline corner ===
  22 of 22 corners: held (inside) on every timing tried
```

Zero `JUMPED OUT`, zero `ESCAPED`, zero `NO GATE` anywhere in the run.

Also re-run after the fix, unaffected:

- `tests/test_village_boundary.gd` — 7 tests, 55 assertions, 0 failed (the
  outline/gate geometry itself is untouched; only the collision this file
  builds around it changed).
- `tests/smoke_opening.gd` — full opening walkthrough passes end to end,
  including the locked/unlocked RoadGate flow (`gate: physically blocked`
  → `gate: locked, conversation 'road_gate_locked' opened` → `gate: key
  found` → `gate: unlocked with the key, beat complete`), confirming the
  corner guards do not interfere with ordinary traversal or the gate's own
  open/close behaviour.

## Honest read on why this took three attempts

Every attempt before this one tested the fence the same way the fence was
*built* — as independent panels, checked at panel centres or a sample of
panel indices. The bug lived exactly in the one place that framing could
never see: the seam between panels. A probe whose own docstring claims a
full ring sweep but samples 8 of ~45 panels and no corners at all will keep
reporting green on a corner bug indefinitely, no matter how many times the
height margin gets raised. The fix that actually held required two changes
of a different KIND, not degree: a collider that never existed before
(sealing a vertex, not a panel), tested by a probe rewritten to be
genuinely exhaustive rather than sampled. Even after that, the first two
tuning values chosen for the new collider (a 0.6m post, then a 1.1m post
with ordinary height) were both under-margined on the first real
measurement and needed a second and third correction — which is the same
lesson `ralph/BACKLOG.md` already recorded once for this exact finding:
verify against the live scene with the real probe every time, never accept
a "should be enough" number without re-running the check that would catch
it being wrong.

## Files changed

- `scripts/world/village_boundary.gd` — `_fence_total_height()` (height
  measured once, not per panel), `_build_corner_guards()` (new).
- `tools/_probe_village_gate_roads_v2.gd` — PART 5 now exhaustive (every
  panel), new PART 6 (every corner).
- `tools/_diag_corner3.gd`, `tools/_diag_corner3_jump.gd` — scratch
  diagnostics used to find and confirm the fix, kept per this repo's own
  convention of keeping one-off `_probe_*`/`_diag_*` tools as breadcrumbs
  rather than deleting them.

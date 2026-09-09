# ROAD live gap diagnosis — 2026-09-09

**The 123/92 result is a real failure of the recorded camera/centre-ray proxy,
but does not establish a systemic shortage of road creatures.** Its dominant
causes are camera framing and obstructed sightlines, compounded by unlike
sampling contracts. One remote gathering excursion does show local scarcity.
No population, camera, art or acceptance change is justified from this aggregate.

## Evidence and contract mismatch

Recomputed directly from
`.artifacts/wave4-fresh-camp-lesson-profile/Godot/app_userdata/Tetherbound/four_biome_coverage_35664_2471.jsonl`
(SHA256 `EF4836593FF1F8BE2E4B9C1E8FA603BC5D7B283A10F4E10A7FD8F570B957FA4D`).
Sample numbers below are one-based sample records, excluding headers; physical
JSONL line = sample + 2. The summary is 123 samples, 92 below two, 1,364.568 m
observed travel and one undersampled interval. All records are Meadows,
`context:unknown`, headless, **1920×1920**; 122 are grounded. Sample 1 includes
a 29.86 m startup discontinuity and the undersampled interval; it passes.

The 4,253-sample result in `road-visual-creatures/REPORT.md` instead evaluates
36 authored polylines in four biomes. `road_creature_visibility_model.gd`
counts authored cluster multiplicity at its centre, using route-tangent heading
and calibrated height/horizontal-distance; it does not test live survival,
scatter/wander, camera frustum or collision occlusion. Its twelve rendered
stands are separate evidence, not continuous coverage.

The observer reads live eligible bodies and the actual camera. Its caller
supplies no outdoor classifier. It measures accumulated movement, including
backtracking, rather than unique road length: all 123 nearest-route labels say
Band 1, but distances from the polyline span 0.071–150.463 m. Only 18 samples
are within 10 m, of which 15 fail; proximity still does not prove membership.
Samples 96–123 accumulate another 296.72 m while their sampled positions occupy
roughly 6×7 m around camp. These are not 28 new road stands.

## What rejects the bodies

Applied in the observer's logical order to the **92 failing samples**:

| First stage leaving fewer than two candidates | Samples |
|---|---:|
| Camera-relative forward half-plane | 1 |
| Then projected height ≥15 px at 720p | 0 |
| Then centre inside actual camera frustum | 68 |
| Then unobstructed centre ray | 23 |

These are ordered classifications, not mutually exclusive physical causes.
Among size-qualified forward bodies in failing samples, 169 are clear but
unframed, 207 unframed and blocked, 61 framed and blocked, and 34 credited.
The 61 framed ray blockers are buildings (38), village boundary (9), and
vegetation/rocks (14). No terrain collider appears in that framed subset;
terrain does block unframed candidates on the western excursion.

The square viewport matters, but cannot explain everything. An offline
perspective reconstruction using recorded camera position/forward/FOV, zero
roll, and each body's recorded 0.52-height centre reproduces **all 614**
size-qualified original framing booleans. Changing only horizontal aspect to
16:9, preserving vertical FOV, size threshold and recorded rays, yields 55
passing samples instead of 31: **24 of 92 failures recover; 68 remain**.
This is a controlled geometric counterfactual, not a new render or visual pass.
Project defaults are 1920×1080; the raw run's square viewport is authoritative
for what it actually measured.

## Representative counterexamples

- **Camera versus travel, samples 37/43:** at `(15.66,-0.02,15.84)`, only
  0.094 m from the road, the camera faces almost opposite preceding travel
  (horizontal dot −0.988). All three framed candidates have centre rays blocked
  by `Village/cottage_a_3/Collision`. At `(9.70,-2.56,77.90)`, the actual ROAD
  `Wild_meadowhart_1910_1/2` pair is alive **5.41/11.25 m** away, both outside
  the camera-relative forward half-plane. This contradicts missing ROAD spawns there.
- **Nearby and clear, sample 110:** Bramblebuns at 15.39/8.13 m have clear rays
  and 78.18/153.32 px projected heights, but their centres are outside the square
  frustum. Widening aspect raises the sample's count from one to three.
- **Physical obstruction persists, sample 84:** six framed candidates, zero
  credited; rays hit `Village/inn_13/Collision` or `workshop_1/Collision`.
  Aspect alone does not recover this sample. Sample 89 later credits five
  bodies from those same Bramblebun/Mudsnout groups, ruling out permanent absence.
- **Local scarcity exists, sample 69:** gathering position
  `(-139.16,3.13,49.89)` is 148.72 m from the polyline; the nearest two living
  bodies are 80.23/86.11 m away. Neither meets the calibrated CP-2 size floor.
  This supports a thin off-road gathering neighborhood, not a missing road pair.

## Root cause, limits and next proof

`stick_navigator.gd::_push` converts world travel into movement stick input
through the rig basis; it does not turn the viewing direction. The production
rig changes yaw/pitch through look/recentre input. Raw samples 31–94 retain
approximately `(0.269,-0.423,-0.866)` forward while travel reverses and detours.
The observer truthfully captures that camera; interpreting it as forward road
travel is the tool/context defect. Meadows production spawns cluster members,
then applies gates and live lifecycle/streaming; the observer lists 971–1079
eligible bodies per sample. This rules out global absence, not local scarcity.

The newer comparison file
`.artifacts/wave8-memory-watched-fresh-profile/Godot/app_userdata/Tetherbound/four_biome_coverage_14108_2494.jsonl`
has only eight samples and no summary. It repeats the square/headless/unknown
context and has six failures; it cannot settle later-road coverage.

**Smallest next falsifiable proof:** one disclosed isolated graphical 1280×720
walk over the roughly 65 m sample-37→43 segment, preserving normal live spawns.
Record actual grounded position, camera, per-body rejection and synchronized
frames first with the recorded backward heading, then with ordinary look input
facing along travel. Verify the nearby order-1910 pair survives and whether its
silhouettes become readable. This tests the named camera/context explanation
without another campaign or survey. If the travel-facing view still fails,
inspect that exact body/occluder before any local placement repair. Do not
increase global density or weaken the two-creature bar.

The measurement mismatch is systemic; proven scene failures are local. Current
evidence supports an **in-engine validation correction first**. It cannot assign
an art dependency: `body_height()` returns gameplay height, and a centre ray
can reject a partly visible silhouette or accept an unreadable/overlapped one.
Matched rendered silhouettes and confirmed outdoor travel context are missing.
No Godot run, production edit, cosmetic iteration or full-road closure is claimed.

Validation receipts (ignored): `.artifacts/road-live-gap-derived.json` and
`.artifacts/road-live-gap-projection-receipt.json`; raw-source analysis only.
Exact sample-37–43 positions, original yaw/pitch (−17.2375°/−24.9984°),
camera poses, pair identities and source hash are preserved in
`.artifacts/road-live-gap-paired-heading-inputs.json` for that bounded proof.

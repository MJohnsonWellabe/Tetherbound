# b25 (24 Oct 2026, CPU candidate pick): owner touch pass, Cindercub ember motes

What was compared:
- Candidate: Cindercub with its own small elemental touch.
  - species.json `touch_vfx: cindercub_embers`.
  - Six faint amber motes rise off the back, built by the existing aspect_vfx billboard code.
  - No eye glow and no paw group. Mesh, albedo and clips are unchanged.
- Base: shipping Cindercub, from the same build without `touch_vfx`.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f10_2_r3_capacitor, f04_6_r22, f36_0_npc:C1. This is a confirming batch.
- Fit: linear, slope 1.174, intercept -0.522, anchor RMSE 0.49.

| Species | Shipping | Embers | Raw (J1, J2, J3), embers / shipping |
|---|---|---|---|
| cindercub | 7.26 | 7.19 (-0.07, within noise) | 6.6/6.6, 6.4/6.5, 6.7/6.8 |

Verdict:
- Parity. The judges saw the motes and called them "harmless atmosphere"; one called them "unexplained".
- It lands on the lane as the owner-directed elemental touch ("ember motes on Cindercub"), and the GPU pass decides it.

Fix found on the way (in the same commit), affecting every Aspect variant's VFX:
- `aspect_vfx.gd` built its billboards from the camera's world axes in the creature's local space.
- On any creature turned side-on to the camera, every mote and eye glow was drawn edge-on, as a thin sliver. That covers Nightburrow's flame, Stormtrail's sparks, Riftfrill's motes and Ashtusk's embers.
- The axes are now taken into local space. Variant VFX will read as the round motes they were tuned as, so a GPU look at those four is worthwhile.

What all three judges said, not caused by the touch:
- The rear-up hit reads as a rear more than a flinch.
- The long tail overlaps the capture stage's ruler (staging only).
- Weak rim light on the dark fur.

Checks:
- New `tests/test_creature_touch_vfx.gd`: every `touch_vfx` names a light, non-red preset; the touch attaches only where named. 2 tests, 0 failed.
- aspect, variant, shiny, colourway, night_floor, companion_presence and alpha: 138 tests, 0 failed.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.

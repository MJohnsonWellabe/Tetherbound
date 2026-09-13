# Independent Terrapup rest candidate verdict — R28

**Verdict: no R28 candidate passes or should be copied directly into production.**

I inspected all eight 1280×800 frames at native resolution and checked the
candidate receipts in `manifest.json`. Every candidate fails the strict posed-height
gate. Candidates C and D also have unusable three-quarter evidence: the subject is
cropped and fills 287% and 192% of frame height respectively. These are pose failures,
not a merely cosmetic camera problem: all four silhouettes lift the belly, chest and
hips far above the bed while one or more paws/tail tips provide the measured low point.

## Ranking

| Rank | Candidate | Assessment |
|---|---|---|
| 1 | **B — hip tuck** | Best starting *idea*, not usable values. It has the lowest height ratio (1.112), both views are judgeable, and its rear-leg asymmetry is marginally closer to an unloaded tuck. It still reads as an inverted, suspended animal with four huge soles and a tent-like belly. |
| 2 | **D — curled cheek** | The intended asymmetric cheek turn is the most useful head direction, but the body remains airborne, the front view does not read curled, height ratio is 1.211, and the three-quarter view is cropped. Borrow only the neck/head turn. |
| 3 | **A — flat sphinx** | Both views are judgeable, but it is a symmetrical upside-down sprawl with an alert visible eye and a 1.163 height ratio. The symmetry reinforces “suspended rig” rather than rest. |
| 4 | **C — belly sprawl** | Worst result: 1.324 height ratio, giant outward-facing paws, extreme underside/tail peak, and cropped three-quarter evidence. Its large positive upper-leg translations should not be iterated. |

## Concrete R29 recommendation

Start from the recognizable R26 authored recipe, **not** from an R28 candidate. R28
shows that increasing pelvis lowering and positive-Y upper-leg translations does not
lower the body silhouette: grounding then lifts the whole model around the new lowest
extremity, leaving the torso suspended. Make R29 a side-prone pose by adding an explicit
model-pivot rotation that is applied after the faint clip and bone offsets, before the
same posed-surface grounding measurement.

Use this exact first R29 candidate:

```json
{
  "clip_role": "faint",
  "model_rotation_deg": [0.0, 0.0, -78.0],
  "model_position_offset": [0.0, 0.0, 0.0],
  "bones": {
    "pelvis":       {"position_offset": [0.00, -0.34, -0.34], "rotation_deg": [0.0, 0.0, 16.0]},
    "spine":        {"position_offset": [0.00, -0.10, -0.20], "rotation_deg": [8.0, 0.0, 12.0]},
    "neck":         {"position_offset": [0.10, -0.08, -0.34], "rotation_deg": [20.0, -32.0, -18.0]},
    "head":         {"position_offset": [0.10, -0.08, -0.10], "rotation_deg": [12.0, -48.0, -26.0]},
    "front_upper_l": {"position_offset": [0.16, 0.08, 0.08], "rotation_deg": [-42.0, 12.0, 20.0]},
    "front_lower_l": {"rotation_deg": [72.0, 0.0, 16.0]},
    "front_upper_r": {"position_offset": [-0.10, 0.04, 0.02], "rotation_deg": [-64.0, -10.0, -28.0]},
    "front_lower_r": {"rotation_deg": [92.0, 0.0, -20.0]},
    "rear_upper_l":  {"position_offset": [0.16, 0.08, 0.04], "rotation_deg": [-58.0, 12.0, 26.0]},
    "rear_lower_l":  {"rotation_deg": [84.0, 0.0, 18.0]},
    "rear_upper_r":  {"position_offset": [-0.12, 0.06, 0.02], "rotation_deg": [-76.0, -12.0, -34.0]},
    "rear_lower_r":  {"rotation_deg": [104.0, 0.0, -24.0]}
  }
}
```

Implementation details that are part of this recommendation:

- Add `model_rotation_deg` to the authored-rest config and apply it relative to
  `_rest_pose_pivot_before.basis`; `stop_rest()` already restores that full transform.
- After rotation and bone overrides, compute the translation from posed skinned
  geometry so a broad flank/hip contacts the mattress. Do not use a paw or tail-tip
  minimum alone as proof of grounding; require the torso's lower quartile to lie within
  roughly 0.20 m of the bed plane.
- Keep all upper-leg Y translations at or below `+0.08`. R28's `+0.66` to `+1.20`
  values are the clearest cause of the raised paws and exploded underside silhouette.
- The `-78°` roll should put the near flank down without repeating R24's insufficient
  `-45°` tilted-standing pose. The asymmetric 72/92° foreleg and 84/104° rear-leg folds
  tuck the near pair and trail the far pair so no four-paw support rectangle remains.
- The combined neck/head yaw and roll turns the visible eye into the foreleg/bed. Since
  this rig has no eyelid control, hiding or heavily foreshortening the eye is required;
  a square, fully visible turquoise eye is an automatic alert-read failure.

R29 should only advance to the production 8-frame day/night package if both candidate
views show: a low back line, broad torso/hip contact, no paw bearing body weight, and no
fully presented open eye. Target posed-height ratio `<= 0.82`; if the first render is
still high, increase model roll toward `-86°` before enlarging any bone translation.

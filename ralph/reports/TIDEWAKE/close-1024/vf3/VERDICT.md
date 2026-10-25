# Tidewake close-1024 round vf3: the Meshy Veilfall cliff facade (24 Oct 2026, CT)

## What was tested

- **Asset:** the Meshy cliff facade (`tb/meshy-1024` `veilfall_cliff_facade`; provenance and c1 references beside the GLB; request inputs under `assets/props/meshy-1025/veilfall_cliff_facade/reference/`).
- **Placement:**
  - fitted uniformly to 27 m tall (about 35 m wide);
  - on the west gully wall at (338, 3836), yaw 127 facing the veilfall-near stand, lifted 14 m out of the slope;
  - 35.8 m from the `veilfall_exploration_spine` centreline.
- **Gate:** OFF (`veilfall_facade_candidate`).
- **Capture:** `tb/tidewake` b6bceef91 or later.
  - Shipping includes the limestone and the rock family ON.
  - The fight is the Venn fight, judged as matched moments: tell-start 0.65, hit 0.70, hit 1.08, tell-ended 1.32 s.
  - CPU llvmpipe, Low, 1920x1080.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - 3 anchor pairs, seed 10606.
  - `calibrate.py`: slope 0.901, r 0.83, anchor RMSE 0.51. This is a confirming batch, but extrapolated below the anchors' range.

## Mapped Bar A

| View | Shipping | Facade | Δ | Judges |
|---|---|---|---|---|
| Veilfall close-up, clear and rain | 4.56 | 4.59 | +0.03 | 2 higher by 0.2, 1 lower by 0.3 |
| Venn fight, matched moments | 4.98 | 4.98 | 0.00 | identical x3 |
| Shore views (pixel diff only) | n/a | n/a | n/a | changed less than run-to-run noise |

**Level, not a win, so `veilfall_facade_candidate` stays OFF.** The gate was to beat the close-up and be level or better on the fight.

## Why it did not lift the close-up

All three judges say the same thing: the facade reads as "a small stratified stone tile with a tiered mini-cascade, mid-slab at an odd angle, floating or pasted on".

- **Too small and too far:** at about 70 m from a stand that looks up at 37°, a 27 m piece is a small tile.
- **The wall is wrong for a vertical piece:** the west wall it sits on is a steep, flat terrain plane, not a vertical face. So the facade either buries or stands proud of it, at the wrong angle to the slope.
- **The real fault is the frame:** the faceted terrain slabs fill most of the view, with stretched texture and near-black shadow faces, and the shot "faces a wall".

## What would move it

The judges' top change, unanimously, is to replace the giant stretched faceted slabs, not to paste pieces onto them. That means either:
- reshaping or retexturing the Veilfall terrain in this gully (gameplay terrain, so it needs a route and walk check); or
- reframing the `veilfall-near` stand so the falls and water are in shot. Changing the camera set changes the yardstick, so that is the coordinator's call.

## Files

- `batch.json`, `mapped.json`, `key.json`
- `_sheet_vf3.jpg` (left: shipping, right: facade)

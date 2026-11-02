# Cloudreach trail shader fix (tb/fix-cloudreach-turf)

GPU frames on tb/gpu-frames-1101: cl/main2 (origin/main 81702ded1) vs cl/turffix (1a0cfdf78 = 81702ded1 + the turf_tint rename), same 22 Cloudreach stands, High.

- Fragment-shader compile errors: 16 on cl/main2, 0 on cl/turffix.
- Frames: 49 on both, 0 blank.
- `_sheet_turffix.png`: summit_eyrie day close, top = main (trail drawn as a flat white fallback strip), bottom = fix (the trail's dirt material renders).
- Largest mean grey differences are the trail-bearing views (summit_eyrie 11.8-17.0, three_bells_bridge, broken_skyroad_arch, realm_gate_crag, windscar_beacon close views 5.7-9.5).

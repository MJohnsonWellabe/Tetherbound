STATUS: land

# THINGS-GALELAND landing (Galewisp landed pose, F38#15 support)

Branch `tb/things-galeland-land`, cut from main a4ad0486.

Verdict: `ralph/reports/GPU-PASS/1108/G-galeland2.md` on tb/item-scout-1108 244c8064 (GPU High, three judges).

| Frame | Before | After | Gain |
|---|---|---|---|
| Galewisp landed | 6.34 | 8.11 | +1.77 (defect fixed 3/3) |
| Galewisp flight | 6.43 | 7.29 | +0.86 |
| Galecrest flight (no-loss control) | 6.88 | 7.43 | +0.55 |

Change (config only, `data/config/fly_traversal.json`):
- `landing_presentation.side_m` 1.2 -> 2.3 (forward_m stays 2.4)
- `capabilities.galewisp.presentation_height_m` 3.0 -> 3.4 (ceiling; do not raise)

Tests: new `tests/test_galewisp_landing_1112.gd`; pin updated in `tests/test_vis_meadows_1104_on.gd`. Ran with test_uiposes_fly_hang_body, test_galewisp_carrier_is_the_remake, test_cloudreach_b_landing_threshold, test_cloudreach_fly_loaner_end: all pass.

Not closed by this: F38#15 needs a row score on the default carrier's glide and landed frames (High, then Medium). Still open per judges: stiff wings in glide (needs a re-rig), flat flight backdrop (PLACES).

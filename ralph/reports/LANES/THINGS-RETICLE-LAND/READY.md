STATUS: land

# THINGS-RETICLE landing (catch aim ring; F38#7 meets the bar on both presets)

Branch `tb/things-reticle-land`, cut from main 4153d1cf.

Verdict: `ralph/reports/GPU-PASS/1108/G-things-reticle.md` on tb/item-scout-1108 bb82ee42 (confirming batch, neutral panel: control F38#38 read 8.28).

| Row | Before | After | Judges |
|---|---|---|---|
| F38#7 catch aim | 7.40 | 7.76 High / 7.76 Medium | 3/3 on each preset; **closes once this is on main** |
| F39#23 (no-loss) | | +0.61 at High | 3/3 (partly the High framing difference) |

The Medium pair differs in ring pixels only and scored the same as High per judge, so the gain is the ring.

Change (config only): `capture_readout_visual.json ring_style_1104`: `alpha_scale` 0.55 -> 1.0, `width_scale` 0.7 -> 1.15, `outline_px` 0 -> 1.5, with `_why_on_1112`.

Tests: older pin updated in `tests/test_near6_ms_1104.gd` (it capped the ring width at 1.0; it now allows up to 1.25, a halo of at most 2 px, pins full alpha and the verdict). Ran test_near6_ms_1104, test_capture_readout_side, test_vis_meadows_1104_on: 35 tests, 0 failed.

Still open per judges (margin): the ring still sits on the hare's body (PARTIAL); a flat sprite dust cloud over the trainer and Terrapup in frame 3 (3/3).

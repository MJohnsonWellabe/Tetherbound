# BELOW6-AQUARYN-RIDE (F39#8, 5.82): one decision needed before an arm

Defect (G-rescore-stale-ext-tidewake, 3/3): "the mount still stands on top of the surface" with no wake or immersion.

## What holds it

`water_mount_presentation.json` sinks the ridden Aquaryn by `extra_sink_m` 1.0. It cannot go deeper because of a pin from LANE-TW (7 Nov): `tests/test_uiposes_water_mount.gd::test_rider_stays_above_sea_at_deepest_bob` requires the rider's art origin to stay above sea level. At 1.0 the rider clears the sea by 0.105 m, so there is no room left. LANE-TW's own r1 at sink 1.4 scored 5.41 to 6.75 on CPU (+1.34, 3/3) and was withheld only for that pin.

## CPU check (not an arm yet)

`_sheet_cpu_base_top_sink17_bottom.jpg`: `phase2_capture_tidewake_mounted_swim.gd`, frames 03 to 05, base (top) against `extra_sink_m` 1.7 (bottom). At 1.7 the mount's belly and legs are under the surface and it reads as swimming. The rider is in the water to about the waist. The two rows are not frame-matched (the capture timed out at different points), so this shows the look, not a pair.

## The choice

- **A. Let the rider's legs enter the water.** Sink to about 1.6 to 1.7 and replace the pin with "the rider's head and chest stay above the sea". One config value and one test. It changes a rule an earlier lane wrote down, so I am not doing it on my own.
- **B. Keep the rider dry.** Sink the mount and raise the rider's seat by the same amount while swimming. That is `riding_controller.gd` and the networked seat (`remote_trainer.gd net_mount_offset`), a larger and riskier change, and the rider may end up perched above the back.

I recommend A. Say which, and I will build it flag-off with a matched capture.

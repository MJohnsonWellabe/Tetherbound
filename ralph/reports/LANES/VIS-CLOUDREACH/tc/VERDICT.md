# tc: P2-105 (F40#6) landing_tree_clear, 4 Nov 2026

Arm: `cloudreach_visual.json:landing_tree_clear` (`names: ["LandingTree171"]`), on the quick_judge tree 1be0b35fe47b with mounted_drop_no_air_drive and low_mist already ON in both arms.
Frames: terrace 1.0 s, terrace after recovery, terrace road back 1.5 s (CPU, Compatibility). Three fresh code-blind judges, standard JUDGE_PROMPT, 3 anchor pairs (craft, f36_0_gap, f36_0_npc); `calibrate.py` -> `calibrated.json`.

| Arm | Raw judges | Measured | Mapped |
|---|---|---|---|
| base | 4.8 / 5.0 / 4.5 | 4.77 | 3.68 |
| candidate | 5.8 / 6.0 / 5.4 | 5.73 | **5.28** |

Gain +1.60 mapped: **ships ON** (owner rule). All three judges named the base road-back frame "camera inside tree canopy, mount barely visible"; the candidate's frame is the rider on the grass rim with the cloud sea behind.

Still present on both sides (all three judges): the first terrace frame shows deer and rider upright beside the cliff with the cloud floor under them (the 1.0 s mid-fall frame before the scramble). Next arm for P2-105: a falling pose/state for the mounted body while airborne, so the first frame reads as a fall, not as riding on cloud.

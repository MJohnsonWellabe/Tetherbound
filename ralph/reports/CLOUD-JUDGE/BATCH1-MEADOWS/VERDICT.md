# Batch-1 Meadows: cloud yardstick verdict, 1 Nov 2026

Frames: tb/gpu-frames-1101 e98370561. The batch is tree 73a5d9f65 (main 2f2901db plus tb/vis-meadows and tb/vis-storm-cams, every manifest flag ON); main is 2f2901db. High, 1920x1080. 3 stands per item, stacked.
Judging: JUDGE_PROMPT v1, three fresh code-blind agent judges, 3 anchor pairs (f36_0_npc, p2_094_r4, f04_6_r22), calibrate.py. Fit is linear: slope 1.247, intercept -0.857, r 0.889, 6 points.

| Item | Flag | Main | Batch | Gain | Verdict |
|---|---|---|---|---|---|
| P2-012 Burrow Warrens hillside | burrow_warrens.json bank.hill_shell.enabled | 4.59 | **6.25** | +1.66 | ON. Rectangular face FIXED 3/3. Asks: mound texture detail, floating leaf cards, beam cut at night |
| P2-064 Warden arena boundary | stronghold.json site.conduits_stop_at_arena_wall | 4.59 | **6.25** | +1.66 | ON. Straight rails to a curved ring, PARTIAL. Asks: soften the glow ring, Terrapup over-lit by torches |
| P2-059 catch camera framing | catching.json framed_camera.enabled | 4.96 | **5.92** | +0.96 | ON. PARTIAL 3/3. Asks: oblique behind-trainer framing, fix the overlapping hint/aim text, remove the cyan ribbon decal |
| P2-005 Meadows ground cover | grass_field.json meadows_ground_candidate.enabled | 5.42 | **6.09** | +0.67 | ON. Asks: clustered colour/rock breaks; the empty cobble court |
| P2-003 stronghold approach | stronghold.json p2_003_candidate.enabled | 5.79 | 6.29 | +0.50 | Not above +0.5: back to the lane. Asks: pylon dominance, close-up room dressing, banded moon halo |
| P2-006 mill river | water.json river.surface_candidate.enabled | 5.30 | 5.13 | -0.17 | OFF. Two of three stands have the camera inside trees or canopy (stand defect); flat water, no banks, no activity |

None reaches 7.0 yet.

# NEAR6-CR lane (tb/near6-cr-1104), 4 Nov 2026

Items: F40#9 P2-068, F40#4 P2-023, F40#8 P2-053, F40#2 P2-022, F40#17 P2-102 (handed over from VIS-CLOUDREACH). CPU-only (Godot 4.7 llvmpipe, Low/Compatibility); mapped CPU Bar A via `tools/visual_judge/quick_judge.py`.

## Landing-ready flags (ON, judged CPU gain)

| Flag | Item | CPU base -> ON | Test | Commit |
|---|---|---|---|---|
| `data/config/cloudreach_npc_runtime.json:world_payoffs.anchor_vessel_quiet` | F40#8 P2-053 | 5.87 -> **6.32** | `tests/test_near6_cr_judged_on.gd` | see log |

## Arms in flight (flag OFF)

| Arm | Item | State |
|---|---|---|
| `objective_beacon.json:realm_styles.cloudreach` (VIS-CLOUDREACH fdfb015a7, ported) | F40#8 P2-053 | Captured, **not judged: no visible change** on the three scored bridge frames (the cyan T there is the Storm Anchor bottled-wind vessel, not the objective beacon). Stays OFF. |
| `world_payoffs.anchor_vessel_quiet` | F40#8 P2-053 | Judged qj/F40-8-2a6eb2207108-11040854: gain, ON (above). Base frames reused from tree bc3299192181 (flag-off render path identical). |

## Blockers

None.

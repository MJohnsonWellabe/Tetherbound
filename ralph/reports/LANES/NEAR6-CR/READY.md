# NEAR6-CR lane (tb/near6-cr-1104), 4 Nov 2026

Items: F40#9 P2-068, F40#4 P2-023, F40#8 P2-053, F40#2 P2-022, F40#17 P2-102 (handed over from VIS-CLOUDREACH). CPU-only (Godot 4.7 llvmpipe, Low/Compatibility); mapped CPU Bar A via `tools/visual_judge/quick_judge.py`.

## Landing-ready flags (ON, judged CPU gain)

| Flag | Item | CPU base -> ON | Test | Commit |
|---|---|---|---|---|
| `data/config/cloudreach_npc_runtime.json:world_payoffs.anchor_vessel_quiet` | F40#8 P2-053 | 5.87 -> **6.32** | `tests/test_near6_cr_judged_on.gd` | 4558ec49 |
| `data/config/cloudreach_physical_runtime.json:rim_pickup_in_view` | F40#17 P2-102 | 5.09 -> **5.72** | `tests/test_near6_cr_judged_on.gd` | 96d1d0e2 |
| `data/config/cloudreach_npc_runtime.json:post_role_props` | F40#9 P2-068 | 5.05 -> **5.25** | `tests/test_near6_cr_judged_on.gd` | see log |

## Arms in flight (flag OFF)

| Arm | Item | State |
|---|---|---|
| `objective_beacon.json:realm_styles.cloudreach` (VIS-CLOUDREACH fdfb015a7, ported) | F40#8 P2-053 | Captured, **not judged: no visible change** on the three scored bridge frames (the cyan T there is the Storm Anchor bottled-wind vessel, not the objective beacon). Stays OFF. |
| `world_payoffs.anchor_vessel_quiet` | F40#8 P2-053 | Judged qj/F40-8-2a6eb2207108-11040854: gain, ON (above). Base frames reused from tree bc3299192181 (flag-off render path identical). |
| `cloudreach_physical_runtime.json:rim_pickup_inset` | F40#17 P2-102 | Round 1 judged flat (qj/F40-17-ade4ecff4c0e-11040935, 4.57 -> 4.57): hiding the cluster left the subject unreadable. Stays OFF. |
| `cloudreach_physical_runtime.json:rim_pickup_in_view` | F40#17 P2-102 | Round 2 judged gain (qj/F40-17-f201152b7ca0-11041023), ON (above). |
| `cloudreach_aviary.json:drum.terrace` | F40#2 P2-022 | Captured (qj F40-2-e17c8adb5fe0-11041024), **not judged: no visible change**: 0.42/0.2 m steps vanish in the turf at the approach distance, and a taller podium would need collision (route change). Stays OFF; next idea: night uplight on the drum (night silhouette) or a paved forecourt joining the court. |
| `cloudreach_f40_visual.json:aviary.sanctuary.drum_uplights` | F40#2 P2-022 | Captured (qj F40-2-e2eed70d21e6-11041108), **not judged: no visible change** (six warm 3.0-energy lights at 31 m read as nothing at the 100+ m approach stands). Stays OFF. **P2-022 parked** after two invisible arms: the item needs a silhouette-scale change (new_art/Meshy-class), not dressing. |
| `cloudreach_npc_runtime.json:post_role_props` | F40#9 P2-068 | Judged gain (qj/F40-9-68037b4643f8-11041154), ON (above). Defect still PRESENT: judges want the NPC itself clear of the trainer and larger; that is the capture stand (trainer 2 m in front of the post), which this lane does not reframe. |

## Blockers

None.

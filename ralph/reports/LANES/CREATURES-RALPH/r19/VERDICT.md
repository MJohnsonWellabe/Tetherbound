# CREATURES-RALPH r19: fixes from the GPU cr1102 notes (CPU, three blind judges)

**Anchors:** craft before/after, f36_0_npc C6, f36_0_gap C7. The fit has slope 1.34, r 0.84, RMSE 0.45, no warnings.

| Creature | Arm | Live (mapped) | Arm (mapped) | Kept |
|---|---|---|---|---|
| Staticub r10 | Faint end floated 0.18 m; settled on the 3rd percentile | 7.09 | 7.22 | yes (GLB) |
| Skyrill r10 | Value x1.3, sharper scale detail, less glassy (`creatures_ralph_skyrill_r10_lift`) | 6.15 | 6.37 | yes, ON |
| Aquaryn r9 | Scale contrast x1.6, saturation x0.85, matte (`creatures_ralph_aquaryn_r9_scales`) | 5.88 | 5.83 | no, OFF |
| Mangrove Monitor r9 | Faint end floated 0.41 m; settled | 5.39 | 5.39 | no (tie) |

**What the judges said:**
- **Aquaryn:** still "one glossy turquoise with no value structure". Scale detail is invisible at the stage camera, so it needs a back-to-belly value ramp or new art.
- **Mangrove Monitor:** the faint end still "crouches on folded legs", and the red-brown dorsal stripe reads oxblood-adjacent on all three judges. It needs new art: the monitor faint lies down, and the stripe moves off red.
- **Staticub:** the faint mid is still "a slight crouch".

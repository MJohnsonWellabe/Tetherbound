# CREATURES-RALPH r14: GPU batch 6 (Sparkit, Tempestwing, Ribbonray), CPU, three blind judges

Anchors: craft before/after, f36_0_npc C4, f36_0_gap C5 (fit slope 0.68, r 0.71, RMSE 0.59, no warnings).

| Creature | Shipped (mapped) | Candidate (mapped) | Target (GPU - 0.8) | Kept |
|---|---|---|---|---|
| Sparkit: regional fennec coat + faint grounded on its lowest vertex | 5.86 | 5.89 | 4.00 | no (+0.03, a tie) |
| Tempestwing: pale gold regional coat + faint grounded on the 2nd percentile | 6.20 | 5.71 | 4.88 | no (-0.49) |
| Ribbonray: value x1.2, saturation x1.1, hit eased, faint grounded | 5.53 | 5.39 | 4.82 | no (-0.14) |

What the judges said:
- **Tempestwing:** the shipped dark body under bright white wings is the value split they want; the gold grade flattens it to "beige on beige, face lost".
- **Sparkit:** split on the stripes (two prefer the calmer coat, one the banded one). All three name "spindly stick legs", which is mesh, not coat.
- **Ribbonray:** all three call the magenta body "toy-like, no readable face". Grounding on the 2nd percentile leaves the end of the faint propped on a fin. This needs new art (a natural hue and a face).

The GLBs are back to the shipped models, and the three coat flags stay OFF. The tools stay: `ground_clip.py --percentile` and `grade_regions.py` `sat_scale`.

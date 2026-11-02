# CREATURES-RALPH r16: coordinator r10 Meshy models for Staticub, Sirenseal and Skyrill (CPU, three blind judges)

**Anchors:** craft before/after, f10_2_r3 capacitor, f36_0_npc C1. The fit has slope 1.66, r 0.94, RMSE 0.48. It warns of extrapolation above the top anchor (Staticub r10).

**Fixes on the rigs before judging:**
- faint: root roll x0.85, grounded per key on the 2nd percentile, legs x0.6;
- hit eased: neck x0.45, head x0.6, tail x0.4, plus per-species softening;
- weights relaxed;
- Skyrill walk and run leg swing x1.3;
- Staticub violet veins lit through the new `hue_bands` rule.

| Creature | Shipped owner1101 (mapped) | r10 (mapped) | Target (GPU − 0.8) | Kept |
|---|---|---|---|---|
| Staticub | 5.34 | 8.55 | 5.18 | yes, ON |
| Sirenseal | 4.35 | 6.95 | 4.31 | yes, ON |
| Skyrill | 4.79 | 7.34 | 4.68 | yes, ON |

**What the judges said about r10:**
- **Staticub:** a "naturalistic brown bear with violet lightning veins, on the Stormursa bar"; it lies prone and grounded in the faint.
- **Sirenseal:** a "believable sea lion"; its markings are busy. The hit lifts off the floor, and the faint end props on a flipper. That is the next fix.
- **Skyrill:** a "believable sail-backed quadruped"; the faint lies flat. Its sheen is slightly glassy, and its value sits close to the stage grey.

The remake flags now point at `candidate_r10`, and all three are queued for the GPU check with the r9 models.

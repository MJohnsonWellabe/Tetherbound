# CREATURES-RALPH r24: rest and hit grounding for board items F36#54, F36#58 and F36#70 (CPU, three blind judges)

**Frames:** hit-050, faint-100, rest-050, rest-100. The CPU baseline and candidate are from the same run.

**Arm:** as r23. The rest is settled on the 3rd percentile per key (rest end floated: Mosshock 0.40 m, Pebbik 0.20 m, Sparkit 0.25 m); hit root hop x0.3.

**Anchors:** craft before/after, gap C6, npc C8. The fit has slope 0.66, r 0.49 (weak: the npc pair barely differs), RMSE 0.72, no warnings.

| Board item | Creature | CPU live → arm (mapped) | Kept |
|---|---|---|---|
| F36#54 | Mosshock | 5.74 → 5.98 | yes (GLB); 0.02 under 6.0 |
| F36#58 | Pebbik | 5.98 → 6.07 | yes (GLB); **at or above 6.0** |
| F36#70 | Sparkit | 5.56 → 5.56 | no (a tie) |

**What the judges said:**
- "The rest pose floats" is FIXED for most judges.
- Every judge names the settled rest repeating the faint, which needs an authored rest clip (Blender).
- Sparkit's stick legs, mascot striping and boneless faint are mesh and new-art problems.
- Mosshock's muddy low-value surface hides its face.

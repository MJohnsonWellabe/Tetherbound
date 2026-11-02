# CREATURES-RALPH r23: rest and hit grounding for board items F39#24 and F39#11 (CPU, three blind judges)

**Frames:** hit-050, faint-100, rest-050, rest-100 (`capture_f36_poses.gd --roles=hit,faint,rest`). The CPU baseline and candidate are from the same run.

**Measured on CPU skinning:** the dog3 rest clip floats at its end. The 3rd-percentile height above the floor was Riptusk 0.76 m, Riverdrake 0.48 m, Torrentoad 0.45 m.

**Arm:** rest settled on the 3rd percentile per key (`ground_clip.py --settle`, the authored 90° side-lie kept); hit root hop x0.3.

**Anchors:** npc C8, gap C6, craft before/after. The fit has slope 0.96, r 0.65, RMSE 0.63, no warnings.

| Board item | Creature | CPU live → arm (mapped) | Kept |
|---|---|---|---|
| F39#24 | Riptusk | 5.72 → 6.07 | yes (GLB) |
| F39#24 | Torrentoad | 5.81 → 5.84 | no (a tie) |
| F39#11 | Riverdrake | 6.32 → 6.42 | yes (GLB) |

**Where the board items stand:**
- **F39#11 (unscored before):** CPU 6.32 → 6.42, at or above 6.0.
- **F39#24:** Riptusk passes and Torrentoad does not (5.84).

**What the judges said:**
- The settled rest still duplicates the faint's side-lie. A distinct curled rest pose needs an authored clip (Blender).
- Torrentoad's hunched biped stance and glossy skin keep it under 6, which is new art.

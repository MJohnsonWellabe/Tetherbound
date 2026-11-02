# CREATURES-RALPH r22: Abyssal Guardian hit and faint (CPU, three blind judges)

The coordinator's ROSTER-1102 has Abyssal Guardian at 5.27, the lowest score this lane had not yet touched.

**Measured on CPU skinning:**
- **Hit:** the neck plunged from 7.2 m to 4.9 m and the body lifted 0.5 m.
- **Faint:** it sank 1.5 m into the floor. The wide flippers are weighted to the spine (only about 50 vertices sit on the leg bones), so the 77° side-lie stood one flipper upright.

**Arm:**
- **Hit:** neck x0.45, head x0.6, tail x0.4, root hop x0.3.
- **Faint:** belly-down (root roll 0), neck and head droop x3 (12° → 36°), legs x0.6, settled on the 3rd percentile last. Weights relaxed (worst 0.42 m → 0.34 m).

**Anchors:** craft before/after, f36_0_gap C4, f36_0_npc C4. The fit has slope 1.38, r 0.75, RMSE 0.59, no warnings.

| Arm | Judges (raw) | Mapped |
|---|---|---|
| Live remake | 5.3, 5.6, 5.1 | 5.26 |
| Hit eased, belly-down faint | 5.5, 5.8, 5.6 | 5.67 |

**Kept** (+0.41; target 5.27 − 0.8 = 4.47).

**What the judges said:**
- "Hit plunge" is FIXED or PARTIAL on all three.
- The new faint "barely differs from standing", and the white front flipper still stands under the chest.
- The glossy marbled-enamel skin is the main limit, which is new art.

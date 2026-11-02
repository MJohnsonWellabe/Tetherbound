# CREATURES-RALPH r18: Sirenseal r10 hit and faint (CPU, three blind judges)

**Arm, on the live r10 GLB:**
- **Hit:** the root hop is scaled ×0.3 (`ground_clip.py --hop=0.3`). It had lifted 0.42 m off the floor.
- **Faint:** both left flippers fold about z by −80°, ramped over the first 60 percent of the clip. The faint is then settled on the 5th percentile per key (`--settle`), so the body comes down off the flipper prop (settled body median 1.42 m → about 0.92 m). Weights are relaxed.

**Anchors:** f36_0_npc C5, f36_0_gap C5, craft before/after. The fit has slope 1.78, r 0.90, RMSE 0.44, no warnings.

| Arm | Judges (raw) | Mapped |
|---|---|---|
| r10 live (r16) | 5.6, 6.0, 5.3 | 5.82 |
| Hit hop ×0.3, flippers folded, faint settled | 6.3, 6.7, 6.4 | 7.30 |

**Kept** (+1.48).
- All three judges mark "faint end propped on a flipper" FIXED.
- "Hit lifts off the floor" is PARTIAL on two judges, PRESENT on one: the forward lunge still shows a sliver of gap.
- The cyan markings are dense ("tattoo-like"), and the navy body wants rim light.

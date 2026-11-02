# CREATURES-RALPH r17: Thundertunnel rescue on the current remake (CPU, three blind judges)

The coordinator's GPU roster put Thundertunnel at 4.72, the lowest score. The r10 remodel is blocked because Meshy credits ran out.

**Arm:**
- A velvet mole coat (data/creatures/remake_grades.json thundertunnel): warm mid-brown body, tan belly and muzzle, pale horn claws; lightning lines and eyes kept.
- The r9 rig recipe: hit neck x0.45, head x0.6 then x0.6 with the neck, tail x0.4; faint root roll x0.85, grounded per key on the 2nd percentile, legs x0.6; weights relaxed (worst stretch 0.55 m → 0.18 m).

**Anchors:** craft before/after, f36_0_gap C2, f36_0_npc C5. The fit has slope 1.55, r 0.95, RMSE 0.32, and warns that the shipped arm sits below the anchor range.

| Arm | Judges (raw) | Mapped |
|---|---|---|
| Shipped remake | 4.0, 3.9, 3.9 | 2.93 |
| Velvet coat + hit and faint fixes | 5.6, 5.5, 5.4 | 5.36 |

**Kept** (+2.43; target 4.72 − 0.8 = 3.92). The GLB carries the rig fixes, and `creatures_ralph_thundertunnel_velvet` ships ON and is registered in `JUDGED_ON`.

All three judges call "near-black mass" FIXED. Still PARTIAL: "a hunched, mitten-armed lump with a tiny face, no clear elemental trait", and a faint that "reads as a crouch". The remodel is still the real fix once Meshy credits return.

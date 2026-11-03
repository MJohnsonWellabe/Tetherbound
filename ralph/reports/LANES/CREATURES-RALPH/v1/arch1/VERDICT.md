# Visual lane v1/arch1: F41#17 Crown Arch, Blender four-legged arch (3 Nov 2026, ~07:40 UTC)

**Arm:** `data/config/crown_arch_vl.json` (r1: `assets/props/vl-1103/crown_arch/crown_arch.glb`). Base: this branch's shipped arch (the round-2 Meshy pillar), frame `stormwood__landmark__crown_arch__day__close` from the v1 Stormwood base run; candidate: the same launch with the flag ON. CPU llvmpipe, Compatibility, 1920x1080.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_gap:C7, f36_0_npc:C4, craft; top anchor 7.35, confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 1.51, intercept -2.78, r 0.96, anchor RMSE 0.24, no warnings.

| Row | Base (mapped) | Arch ON (mapped) | Raw base / ON | Defect call |
|---|---|---|---|---|
| F41#17 Crown Arch | 3.91 | **5.92** (+2.01) | 4.5 4.0 4.8 / 5.8 5.6 5.9 | PRESENT 3 -> PARTIAL 3 |

**Decision:** ON (`crown_arch_vl.json` `_why` records 5.92; `tests/test_hero_landmarks_1101.gd` asserts it). 0.08 under 6.0.

**Judges (all three):** reads as a real arch; still sits on the exposed square slab with straight edges; the stone is pale lavender and loses value against the purple cliff; the stone texture is banded/stripy. Round 2 (`r2_candidate`, OFF) answers all three: dark grey-blue slate with noise strata, broken mossy flagstones over the landing.

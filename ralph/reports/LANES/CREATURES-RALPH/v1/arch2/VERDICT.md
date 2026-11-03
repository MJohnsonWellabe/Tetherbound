# Visual lane v1/arch2: F41#17 Crown Arch r1 vs r2 (3 Nov 2026, ~10:15 UTC)

**Arms:** base = `crown_arch_vl.json` r1 (shipped ON at 5.92 in v1/arch1); candidate = `r2_candidate` ON (`crown_arch_r2.glb`: dark grey-blue slate with noise strata, darker moss and verdigris, broken mossy flagstones and moss stones over the 9 x 9 m landing). Same launch (`phase2_capture_locations.gd --biome=stormwood --times=day --views=close --seed=2042 --subset=stormwood__landmark__crown_arch`), CPU llvmpipe, Compatibility, 1920x1080, judged at 1280x720.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_gap:C5, f36_0_npc:C8, craft; confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 0.98, intercept 0.26, r 0.65, anchor RMSE 0.64, no warnings.

| Row | r1 (mapped) | r2 (mapped) | Raw r1 / r2 | Defect call r1 -> r2 |
|---|---|---|---|---|
| F41#17 Crown Arch | 5.37 | **6.19** (+0.82) | 5.5 5.2 4.9 / 6.2 6.3 5.6 | PRESENT 2 PARTIAL 1 -> PARTIAL 3 |

**Decision:** r2 ON (`_why` records 6.19; `test_hero_landmarks_1101.gd` asserts it). **F41#17 is at or above 6.0 CPU.** The shipped Meshy pillar scored 3.91 in v1/arch1, so the item has gained +2.3 over two rounds.

**Judges:** r2 "reads as an authored ruin"; the rubble softens the slab, though its square footprint still shows. r1's pale striped lavender looks "plastic" and its icy feet are off-palette. Next asks: copper and glass storm accents, a less square footprint, the arch larger (about 2.5x the trainer now), and a deeper storm backdrop behind it (scene).

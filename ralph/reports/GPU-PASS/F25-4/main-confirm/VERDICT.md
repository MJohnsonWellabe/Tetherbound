# F25#4 four-creature frame rate: confirmation on main (24 Oct 2026, GPU)

**Verdict: Medium CONFIRMED on main.** The launch stall stays fixed after landing:
- the launch frame is **16.6–27.4 ms** on the first volley and **10.3–18.0 ms** on the second;
- **0 frames over 33.3 ms** in 24 standard volleys;
- 102–116 fps average.

This matches the tb/vfx-launch proof in `../FIX.md`, and it backs the F21#5 closure.

**Low (Compatibility): unchanged from FIX.md.**
- With a warm shader cache, ×2 reps, the launch frame is:
  - starters: 64.4–66.2 ms;
  - heavy: 75.4–78.0 ms.
- Prewarm on and off give the same result.
- Volley 2 is 10.2–16.8 ms. At most 1 frame per volley goes over 33.3 ms.

The first Low pass on main read 245–254 ms with prewarm on. Those were the first Low runs after main's reimport, so the shader cache was cold. The re-run (`LowB-*`) shows that was a cache artefact, not a regression. Low is not the F25#4 line, which is Medium.

## Run

- **Source:** main 7b5d351da (tb/gpu-pass; = main 45865499d plus the NOTE.md queue). The fix files are byte-identical to tb/vfx-launch b175bda5c. The only difference is `encounter_director.gd` (+14 lines, Fights).
- **Machine:** GTX 1060 3GB, 1920x1080, Forward+ on Vulkan (Medium) and Compatibility on OpenGL3 (Low). Each preset uses its own isolated APPDATA.
- **Harness:** the same harness as the baseline and FIX.md (`../f25_four.gd.txt`, `../f25_stats.ps1.txt`): two volleys of four simultaneous ultimates on the Meadows stage, with a per-frame timing log. No captures, census or prints fall inside the timed window.
  - starters: terrapup, ripplet, galewisp, veridian;
  - heavy: solmane, stormursa, abyssal_guardian, fulgocobra.
- **Matrix:**
  - Medium, prewarm on, budget on/off: ×3 reps per set;
  - no-prewarm: ×1;
  - over-cap ×3: ×1;
  - snapshot: ×1;
  - Low, prewarm 1/0: ×1.
  - 28 runs in all; every run exited 0.

## Results (per volley; full table in `f25_main_stats.csv`)

| Medium arm | Volley 1 launch | Volley 2 launch | Frames > 33.3 ms | Avg fps |
|---|---|---|---|---|
| starters, prewarm, budget on (×3) | 16.6–18.2 ms | 10.3–13.1 ms | 0 | 113–116 |
| starters, prewarm, budget off (×3) | 17.0–18.6 ms | 10.7–10.9 ms | 0 | 115–116 |
| heavy, prewarm, budget on (×3) | 26.1–27.4 ms | 17.0–18.0 ms | 0 | 102–105 |
| heavy, prewarm, budget off (×3) | 26.4–26.7 ms | 16.8–17.6 ms | 0 | 102–103 |
| starters / heavy, no prewarm | 28.3 / 61.0 ms | 10.6 / 18.4 ms | 1 / 1 | 113 / 100 |
| starters ×3 over-cap, budget on / off | 32.3 / 32.5 ms | 26.7 / 30.0 ms | 0 / 3+3 | 100 / 98 |
| heavy ×3 over-cap, budget on / off | 53.3 / 55.6 ms | 45.9 / 49.7 ms | 0 / 0 | 92–94 |

- **Budget:** under over-cap load the particle slots cap at **384** with the budget on, against 504–516 with it off. That matches FIX.md.
- **Snapshot runs:** the SNAP-* runs save PNGs inside the window. Their 637–650 ms frames are the known capture artefact, not gameplay.
- **Worst single frame:** among the 24 standard volleys it was 33.13 ms (starters, budget on, r2 volley 2), just under the 33.3 ms line.

| Low arm (first pass, cold cache after reimport) | Volley 1 launch | Volley 2 launch | Frames > 33.3 ms |
|---|---|---|---|
| starters, prewarm 0 / 1 | 65.8 / 245.0 ms | 10.4 / 10.8 ms | 0 / 2 |
| heavy, prewarm 0 / 1 | 77.8 / 253.9 ms | 16.1 / 16.8 ms | 1 / 1 |

| Low re-run (warm cache, ×2) | Volley 1 launch | Volley 2 launch | Frames > 33.3 ms per volley |
|---|---|---|---|
| starters, prewarm 0 | 65.3, 66.2 ms | 11.5, 10.2 ms | 1, 1 |
| starters, prewarm 1 | 64.4, 65.7 ms | 10.3, 10.3 ms | 0, 0 |
| heavy, prewarm 0 | 77.7, 78.0 ms | 16.5, 16.1 ms | 1, 1 |
| heavy, prewarm 1 | 76.6, 75.4 ms | 16.8, 16.4 ms | 0, 0 |

## Files

- `f25_main_stats.csv`: per-volley stats for all 28 runs.
- `f25_main_queue.ps1.txt`: the exact queue, run locally.
- Per-frame logs stay local.

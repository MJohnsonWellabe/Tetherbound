# F25#4 worst-case four-creature effects: frame time on Medium (GPU, 22 Oct 2026, midday)

**Criterion (ACCEPTANCE F25 (4)):** "Each effect has a particle budget; a worst-case four-creature fight holds frame rate on the Medium preset capture; nothing depends on an effect the Compatibility preset cannot draw without a fallback."

**Result: steady frame rate holds with a lot of headroom, but every four-ultimate launch costs one long frame.**

- **Steady state, Medium:**
  - Average 8.7–9.9 ms (101–115 fps).
  - p95 9.0–10.6 ms.
  - At most 1 frame over 33.3 ms per volley after launch.
- **Launch frame:** the frame in which the four ultimates fire takes **155–350 ms on Medium**. That is about a 0.2–0.35 s freeze.
  - It repeats on the warm second volley in the same process, so it is not only first-use shader compilation.
  - On Compatibility (Low) the same launch costs 27–82 ms.
- **Spikes:** the starters' presentation has one further 78–114 ms spike per volley.
- **Budget on vs off:** no difference. Four ultimates use at most 168–172 of the 384-slot encounter cap, so the budget never binds in this case.
- **Compatibility:** all four effects arrive and draw on Low (`failures=0`, `arrivals=4`). See the sheet.

The criterion does not set a number. The project's handheld Medium target is ≥30 fps, 40 preferred (TECHNICAL.md, F26#5). Against that line:
- Steady state passes easily.
- The launch frame fails on every volley.

The coordinator decides how to read "holds frame rate". My reading: **not met while the launch frame stalls 155–350 ms**, with steady state met.

## What was run

- **Machine:** NVIDIA GeForce GTX 1060 3GB, Windows 10, Godot 4.7-stable, Forward+ on Vulkan for Medium and Compatibility for Low.
  - 1920x1080, vsync disabled in-process, so the interval is the real frame cost rather than the refresh.
  - Each preset reads its own isolated `user://graphics_override.cfg`.
  - Source: `tb/gpu-pass`. Only reports have been committed since 90283da8a, and its game code equals main 320eb47.
- **Workload:** the existing smoke `tests/smoke_move_effects_library.gd --batch=ultimates --medium --stage=meadows --simultaneous=<four ultimates>`.
  - This is the F35 four-at-once case: four production attacker models in lanes on the Meadows stage, each firing its ultimate at one target on the same frame.
  - The smoke itself labels this scope `synthetic_no_combat`. There is no AI, HUD or HP transaction; it is the effects worst case, not a live four-peer fight.
  - Two sets:
    - **starters:** terrapup, ripplet, galewisp, veridian.
    - **heavy:** solmane, stormursa, abyssal_guardian, fulgocobra.
- **Wrapper (`f25_four.gd.txt`):**
  - Same staging and launch path as the smoke's `_exercise_simultaneous`.
  - Fires **two volleys per process**: volley 1 is cold, volley 2 is the warm repeat, 30 frames apart.
  - Logs every frame's interval, video memory, the encounter's particle slots (`move_effect_budget.used`), draw calls and primitives.
  - `TB_VFX_BUDGET=off` lifts every particle and mesh ceiling in-process: the library caps and the ultimates `budget` caps. Nothing on disk changes.
- **Repeats:** 3 runs per set × budget arm at Medium, plus 1 run per set at Low. That is 14 processes and 28 volleys.
- **First harness superseded:** the first harness (kept locally, not used for numbers) left in the smoke's three mid-flight 1080p PNG beat captures and a node census. Each of those cost about 0.6 s and was measured as a hitch. The numbers below come from the corrected wrapper. The sheet's frames come from the first harness's beat captures.

## Numbers (per volley; launch frame reported apart; full table in `f25_stats.csv`)

| Preset / set / budget | Volley | Launch frame ms | Avg ms (fps) | p95 ms | p99 ms | Max ms | Frames >33 ms | VRAM peak | Particle slots peak (cap 384) |
|---|---|---|---|---|---|---|---|---|---|
| Medium starters on (3 runs) | 1 | 335–340 | 8.9–9.0 (111–113) | 9.9–10.0 | 15.7–16.0 | 102–105 | 1 | 419 MB | 168 |
| Medium starters on (3 runs) | 2 | 334–341 | 8.7–8.8 (113–115) | 9.0–9.1 | 11.2–14.6 | 78–81 | 1 | 419 MB | 168 |
| Medium starters off (3 runs) | 1 | 346–350 | 8.8–9.1 (110–113) | 9.1–10.6 | 15.6–15.8 | 102–114 | 1 | 419 MB | 168 |
| Medium starters off (3 runs) | 2 | 337–344 | 8.7–8.8 (113–115) | 9.1–9.7 | 9.2–13.7 | 78–85 | 1 | 419 MB | 168 |
| Medium heavy on (3 runs) | 1 | 188–196 | 9.8–9.9 (101–102) | 10.2–10.3 | 18.6–18.8 | 53–54 | 1 | 407 MB | 172 |
| Medium heavy on (3 runs) | 2 | 155–181 | 9.6 (104) | 10.2 | 10.3 | 20.5–22.0 | 0 | 407 MB | 172 |
| Medium heavy off (3 runs) | 1 | 190–193 | 9.8 (102) | 10.2–10.3 | 19.2–19.8 | 53–54 | 1 | 407 MB | 172 |
| Medium heavy off (3 runs) | 2 | 156–174 | 9.6–9.7 (103–104) | 10.2–10.3 | 10.3–12.4 | 20–23 | 0 | 407 MB | 172 |
| Low starters on | 1 / 2 | 74 / 27 | 3.8 (260–264) | 4.7–4.8 | 5.1–5.3 | 35 / 21 | 1 / 0 | 243 MB | 168 |
| Low heavy on | 1 / 2 | 82 / 41 | 3.9–4.1 (247–256) | 4.8–5.3 | 5.2–5.8 | 33 / 21 | 0 / 0 | 231 MB | 172 |

Frames per volley: about 315 for Medium starters, about 287 for Medium heavy and 676–735 for Low. Draw calls peak at 131 on Medium and 180 on Low. Every run reports `arrivals=4` and `failures=0`.

## Findings for the VFX lane

1. **The launch frame is the open item.**
   - Firing four ultimates costs 155–350 ms in one frame on Medium, in volley 2 as much as volley 1.
   - On Compatibility the same launch costs 27–82 ms.
   - A Forward+-specific per-launch cost is the likely place to look, for example per-instance materials or pipeline variants created at launch. That is not proven here.
   - Possible fixes: prewarm or cache the effect materials and meshes at encounter start; pool effect nodes; or spread the four launches over a few frames.
2. **Budget:** four simultaneous ultimates request 168–172 particle slots, under half the 384 encounter cap. On/off is therefore indistinguishable here.
   - This shows the budget has headroom.
   - It does not show the budget protecting frame rate. That needs a load that exceeds the cap (more than about 9 simultaneous ultimate leases, or ordinary volleys stacked on top).
3. **Starters spike:** the starters set has one 78–114 ms spike mid-presentation per volley. The heavy set's equivalent is 20–54 ms. It is probably a phase spawn, for example an impact.
4. **Memory:** VRAM peaks at 407–419 MB on Medium and 231–243 MB on Low on this 3 GB card.
5. **Compatibility:** all four effects arrive and draw on Low with no fallback errors. The sheet shows Low and Medium side by side at the smoke's early, middle and late beats.

## Not covered here

- No live four-peer combat fight; the earlier attempts at that were memory-blocked (`ralph/reports/GPU/F21-F25/PROOF.md`).
- No handheld (Ally) device.

## Files

- `_sheet_f25_4.png`: four ultimates at the smoke's early, middle and late beats, Medium and Low, both sets.
- `f25_stats.csv`: per-volley stats for all 28 volleys.
- `f25_four.gd.txt`: the timing wrapper (local tool).
- `f25_queue.ps1.txt`, `f25_stats.ps1.txt`: the run queue and the stats script.
- `commands.txt`: exact command line for every run.
- Per-frame logs and frames stay local.

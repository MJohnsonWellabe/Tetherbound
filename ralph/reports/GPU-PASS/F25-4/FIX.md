# F25#4 launch-stall fix: diagnosis and GPU proof (22 Oct 2026, afternoon)

**Fix branch:** `tb/vfx-launch` at **bb60cdf80**, based on main eabf1a9e0, with one commit and 10 files (+145/−1). It is committed locally on the GPU machine. **It is not pushed yet**: pushing a branch other than tb/gpu-pass waits for the owner's OK on this machine.

**Result:** with the fix and its world-load prewarm, every four-ultimate volley on Medium meets the line:
- Launch frame: **16–30 ms cold, 10–23 ms warm**, down from 155–350 ms.
- **No frame over 33.3 ms** in any of 24 volleys (12 runs: 2 sets × budget on/off × 3 repeats, cold and warm).
- Worst frame anywhere: 25.7 ms.
- Steady state is unchanged: 100–118 fps, p95 9.0–11.4 ms.

## Diagnosis (how the stall was found)

1. **Not rendering:** on the launch frame, the viewport render CPU was 0.4 ms and render GPU about 7 ms.
2. **It was CPU time inside `ultimate_library.launch`:** terrapup 155–161 ms, veridian 129–150 ms, ripplet about 40 ms, galewisp about 21 ms. That sums to about 350 ms and is the same on the warm volley.
3. **Narrowing it down:** all eight tested ultimates draw through the move library's staged effect (`move_effect.gd`). Timing each `_ready` step pinned it to one line in `_mesh_node`, `node.material_override = …`, at about 10 ms per node. Building the mesh and the material was cheap.
4. **Isolated probe (`StandardMaterial3D`, same parameters, Medium):**
   - The first `get_rid()` of a feature variant costs 10 ms unlit/opaque and 43 ms lit/alpha.
   - Further materials of that variant cost 0.01 ms while one is alive.
   - After the last one is released, the next costs 9.7 ms again.
   - On Compatibility every step costs under 1 ms.
   - **Godot frees a BaseMaterial3D shader variant with its last material.** Effects are freed after each volley, so every launch recompiled 3–4 variants.
5. **Remaining cold costs after pinning:**
   - The first authored `ShaderMaterial` with parameters set (for example the trail surface) took about 13 ms.
   - The contact-stage surfaces (flash, ground mark, sparks) caused one 36–56 ms spike at impact on the first volley only.
   - Prewarming those surfaces removed both.

**A measurement note:** turning on viewport render-time measurement, or printing on the launch frame, adds about 300 ms to that frame in this setup. Both are off in every timed run.

## The change (tb/vfx-launch bb60cdf80)

- **`scripts/vfx/material_variant_pin.gd` (new):** `pin(material)` holds one duplicate per BaseMaterial3D feature variant for the process. The variant key is shading, transparency, blend, cull, vertex colour, depth test, emission and billboard. `prewarm()` builds the lit/unlit × opaque/alpha variants plus the emissive ones.
- **`move_effect_geometry.material()`, `ultimate_geometry.material()`:** pin their variant.
- **`move_effect.gd`:**
  - The emissive solid core pins its variant.
  - `_set_opacity` pins when a fade switches an opaque material to alpha. It now sets transparency only when it changes, with the same result as before.
- **`move_effect_library.prewarm()`:** pins the standard variants and builds every authored surface (22 kinds, plus the two trail styles) and the four contact-stage shaders. It is idempotent and takes about 245 ms once.
- **`move_projectile.prewarm()`:** forwards to it.
- **`scripts/combat/encounter_director.gd`, one call in `_ready()`:** `MOVE_PROJECTILE.prewarm()`, so the cost lands while the world loads. This is the only edit outside the effect spawn path; the Fights lane should know about it.
- **`tests/test_material_variant_pin.gd` (new, headless), three tests:**
  - A second launch's materials find their variants still pinned.
  - The variant key ignores colour and alpha but tracks opaque/alpha and emission.
  - The library prewarm is idempotent and builds every authored surface from an empty profile.
- **Tests run:**
  - `test_move_effects.gd` + `test_material_variant_pin.gd`: 12 tests, 2,055 assertions, 0 failed.
  - Full headless suite on this machine: **6,070 tests passed** before the run hit my 55-minute limit; CI's sharded run is the full check.
  - 4 failures, all from this machine's setup: three read report files this sparse checkout does not have (Cloudreach F27 route ledger, Meadows THE-RISE R33 evidence), and `test_gate_f_rig` shells out to `python3`, which is not on this machine's bash PATH. None touches the effect code.

## GPU proof (same harness as VERDICT.md; GTX 1060, 1920x1080, vsync off, two volleys per process)

In the harness, the encounter director's world-load call is stood in for by calling `move_effect_library.prewarm()` before the volleys (`TB_F25_PREWARM=1`). This is the only difference from the baseline harness.

| Medium, 4 ultimates | Volley | Launch frame ms (3 runs) | Avg ms | p95 ms | Max ms | Frames >33 ms |
|---|---|---|---|---|---|---|
| starters, budget on | 1 cold | 16.4 / 16.7 / 19.5 | 8.5–8.6 | 9.0–9.1 | 20.0–20.7 | 0 |
| starters, budget on | 2 warm | 11.1 / 10.3 / 12.2 | 8.5–8.6 | 9.0–9.1 | 20.1–20.3 | 0 |
| starters, budget off | 1 / 2 | 17.3–18.0 / 10.9–12.9 | 8.5–8.6 | 9.0–9.1 | 20.0–20.6 | 0 |
| heavy, budget on | 1 cold | 25.7 / 27.7 / 30.0 | 9.7 | 10.2 | 20.2–20.6 | 0 |
| heavy, budget on | 2 warm | 20.2 / 19.3 / 19.0 | 9.7–10.0 | 10.2–11.4 | 20.4–25.7 | 0 |
| heavy, budget off | 1 / 2 | 26.1–29.8 / 19.7–23.3 | 9.7–9.8 | 10.2–10.3 | 19.9–20.6 | 0 |

Before the fix (VERDICT.md, same harness): launch frame 334–350 ms for starters and 155–196 ms for heavy; one 78–114 ms spike per starters volley.

**Fix without the world-load prewarm** (for example if the director call were missing):
- Starters launch 26.6 / 13.0 ms (cold / warm).
- Heavy launch 60.7 / 21.2 ms.
- One cold contact-stage spike: 35.7 ms (starters) and 56.5 ms (heavy).
- The warm volley is clean.
- So the pins alone fix every repeat launch, and the prewarm removes the once-per-session cold cost.

**Over-cap volley** (budget engaging): each of the four attackers fires 3 ultimates on one frame, 12 effects.

| Medium, 12 ultimates | Particle slots peak | Launch frame ms (v1 / v2) | Avg ms | p95 ms | Max ms | Draw calls peak |
|---|---|---|---|---|---|---|
| starters, budget on | **384 (cap)** | 38.2 / 26.6 | 9.7–9.8 | 13.2–13.3 | 31.8–32.5 | 229 |
| starters, budget off | 504 | 33.8 / 27.5 | 10.0–10.1 | 15.7 | 26.8–32.7 | 249 |
| heavy, budget on | **384 (cap)** | 54.1 / 46.7 | 10.6 | 13.8–14.1 | 26.8–33.7 | 236 |
| heavy, budget off | 516 | 55.5 / 47.6 | 10.9 | 16.5–16.6 | 31.9–35.1 | 251 |

- The cap engages at exactly 384 slots.
- It lowers p95 by 2.4–2.9 ms and cuts 15–20 draw calls.
- `_sheet_f25_4_fix_overcap.png` compares the same 12-heavy-ultimate moment 0.8 s after launch with the budget off and on. I see no visible loss with the cap on. The large staged creatures occlude part of the effects from the smoke's fixed camera.
- Launching 12 ultimates on one frame (three times the four-creature worst case) still costs a 27–55 ms launch frame. That is beyond F25#4's four-creature line and is recorded only for the budget check.

**Compatibility (Low)**, 1 run per set, prewarm on and off:
- Launch frame 64–78 ms cold and 10–16 ms warm, against 74–82 / 27–41 ms before the fix.
- Steady 3.8–4.0 ms (253–265 fps).
- All effects arrive; `failures=0`.
- There is no regression. Compatibility's cold first launch remains above 33 ms; that is a first-draw GL compile, outside this Medium criterion, and not addressed here.

## Files (this round)

- `FIX.md`: this note.
- `f25_fix_stats.csv`: per-volley stats for every fix run, including no-prewarm, over-cap and Low.
- `_sheet_f25_4_fix_overcap.png`: the over-cap budget off/on comparison.
- `f25_four.gd.txt`: the harness, now with `TB_F25_PREWARM`, `TB_F25_MULT`, `TB_F25_SNAP` and diagnostics (`TB_F25_DIAG`, `TB_F25_DIAG_RENDER`) that are off in timed runs.
- `f25_fix_queue.ps1.txt`: the run queue.
- `fix_commands.txt`: exact command lines.
- `tb_vfx_launch_bb60cdf80.patch.txt`: the full fix as a patch, so it can be reviewed before the branch is pushed.

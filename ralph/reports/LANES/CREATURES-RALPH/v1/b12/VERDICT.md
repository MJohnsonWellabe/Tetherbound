# Visual lane v1/b12: Fulgocobra gold-vein charge (F41#13) and HUD lean (F38#19) (3 Nov 2026, ~17:50 UTC)

**Arms:**
- **Fulgocobra:** `creature_coat_flags.json` `creatures_ralph_fulgocobra_goldvein` (an emission mask on the gold bands), captured with `capture_f36_poses.gd --species=fulgocobra --whole-body --context` with the flag OFF and then ON in the same run.
- **HUD lean:** `hud.json` `hud_lean`, captured with `phase2_capture_ui.gd --biome=meadows`. The base is the tex_cand frame (house textiles ON); the candidate is the same launch with hud_lean ON.

CPU llvmpipe, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_gap:C1, craft, f36_0_npc:C2; confirming batch), three fresh code-blind judges. `calibrate.py`: linear, slope 1.26, intercept -1.15, r 0.91, anchor RMSE 0.35, no warnings.

| Row | Item | CPU base (mapped) | Arm ON (mapped) | Decision |
|---|---|---|---|---|
| F41#13 | Fulgocobra charged finish | 6.06 | **6.52 (+0.46)** | **ON**. Both halves of F41#13 are now ON: Stormraven 6.72 (r25), Fulgocobra 6.52 |
| F38#19 | exploration HUD | 5.30 | 5.64 (+0.34) | OFF; the gain is under 0.5 and the row stays under 6.0 |

**Judges:**
- **Fulgocobra:** the pale gold bands "separate from the ground and hood more strongly". The defect is still PARTIAL 3/3: there is no lightning element, and the face and eyes are lost in the black hood.
- **HUD:** the trayless hotbar helps (defect PRESENT on base, PARTIAL on candidate). The room itself drags the row: a dim orange grade, stretched wood grain on the ceiling, and a camera looking down from inside the ceiling. The next lever for F38#19 is the interior grade and ceiling camera, not the HUD.

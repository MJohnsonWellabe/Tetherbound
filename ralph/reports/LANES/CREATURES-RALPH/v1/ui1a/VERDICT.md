# Visual lane v1/ui1a: Meadows UI (F38#4 map, F38#9 menu shell, F38#19 exploration HUD), CPU A/B (3 Nov 2026, ~09:45 UTC)

**Arms (candidate, all ON together):** `hud.json` quiet_empty_slots, hud_lean, catch_card, message_clears_prompt, victory_focus; `menu.json` satchel_focus, shell_board; `catching.json framed_camera.r2`; `camfx.json catch_orb`; `catch_kit.json`. Base: this branch with all of them OFF. Frames: the items' `VISUAL/item-scores/job.json` repro launch (`phase2_capture_ui.gd --biome=meadows --seed=2042`), CPU llvmpipe, Compatibility, 1920x1080; one-frame sets judged at 1280x720.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_npc:C8, f36_0_gap:C3, craft; confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 1.06, intercept -0.12, r 0.69, anchor RMSE 0.63, no warnings.

| Row | Item | CPU base (mapped) | Arms ON (mapped) | Raw base / ON | Decision |
|---|---|---|---|---|---|
| F38#9 | P2-001 menu shell | **6.08** | 6.08 | 5.8 6.2 5.6 / 5.8 6.2 5.6 | **at or above 6.0 on the current branch** (no change needed); `menu.json` arms make no visible change |
| F38#4 | P2-002 map | **5.73** | 5.70 | 5.2 6.0 5.3 / 5.3 6.0 5.3 | arms OFF (no effect) |
| F38#19 | P2-004 exploration HUD | **5.45** | 5.66 | 5.3 5.4 5.1 / 5.6 5.6 5.2 | +0.21, all three judges prefer the lean side; held OFF (inside the fit's noise and under the owner's 0.5 gain rule) |

**What the judges said:**
- **Map:** "a green disc on cloud fog with road lines"; no terrain, water, groves or buildings. Needs painted terrain on the map canvas (scene).
- **Menu shell:** the painted village banner carries it; the body text is small and low-contrast, and headings and body text barely differ. The defect is PARTIAL on two judges.
- **HUD:** the shipped quick bar sits on a large dark backing panel; with `hud_lean` it floats lighter. Many boxes still crowd the corners. Two judges flag the **player's bed blanket as dark maroon/oxblood on a friendly object** in the start bedroom (reserved for Team Tether).

STATUS: parked
BRANCH: tb/item-f38-19  HEAD: the commit that adds this file (READY and verdict only, no game change)

Depends on tb/item-capture-fixes (fix b, job.json `--hud-settle-frames=900`; landed in #848/#849).

- Row: F38#19 P2-004 exploration HUD (Meadows). Live CPU 5.92 (180-frame stand, under the opening fade) / GPU 5.56.
- Settled-stand re-score: CPU mapped **6.58** (raw 5.4/5.7/5.4). Round `ralph/reports/LANES/LANE-KIT/qj/F38-19-6185f839a40e-11072054/` (r 0.78, RMSE 0.72, confirming).
- Arm (overlay only, nothing changed in the tree): lighter plates. `hud.json exploration_hotbar.panel_alpha` 0.55 -> 0.35, `exploration_vitals.idle_alpha` 0.85 -> 0.7, `clarity_pass.daytime_plate_alpha` 0.55 -> 0.35. **Flat (+0.00)**: every judge scored both sides the same and called them identical. Stays OFF (not written to config).
- Flags turned ON: none. Tests flipped: none.
- Judges' remaining asks:
  - The legend strip (Map/Satchel/Build/Call Out) sits mid-frame beside the hotbar. Owner placement OP21-11, not a lane call.
  - Keyboard glyphs instead of controller-first prompts. The capture's last device is keyboard.
  - The gold-framed quest box is off the blue-grey panel family.
  - Hide empty hotbar slots. That breaks the five-visible-bindings rule; quiet_empty_slots was already flat (NEAR6-MS).
  - Over-saturated orange loft and a steep ceiling camera. Stand and scene, not HUD.
- Next idea: put the stand on the gamepad glyph path (the tool already sets `_last_input_was_gamepad` on some paths) so the prompts read controller-first, then re-judge. Quest-box border in the panel family is a hud/ui_tokens change for a later round.

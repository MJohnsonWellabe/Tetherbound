# UI lane close run (tb/ui), 22 Oct 2026

Yardstick: tools/visual_judge (standard prompt, anchors, calibrate.py), merged from tb/judge-yardstick.
Messaging the coordinator from this session fails (`elevated_session_untrusted_device`); status lives here.

## Status for the coordinator
- P2-095/096 craft panel: shipping frames unchanged on tb/ui. New candidates `compact_rows` and `craft_button` (craft_presentation.json) are committed OFF. Always on: glyph hints redraw when the device switches while the panel is open (no static-frame change). For the GPU rejudge, `tools/phase2_capture_build_systems.gd --gamepad` (tb/ui) shows pad glyphs.
- Functional fix (tb/ui, not landed): the world prompt hides while the fight command bar is shown (GPU finding "E Gather Reef Stone" over the command bar); a phase that releases the bar keeps its prompt. New `tests/smoke_fight_world_prompt_yield.gd` PASS; `smoke_hud_presentation_lifecycle` 70 checks PASS; `smoke_craft_panel_controller` exit 0.
- Fight glyphs: combat HUD already follows the last device (seeded to pad when a joypad is connected). The GPU "keyboard-only" frames came from a capture with no pad. `tools/phase2_capture_tidewake_fights.gd --gamepad` now captures what a pad player sees.
- P2-002 map: candidates `fog_veil.painted_chart` + `fog_veil.cloud_fog` (map.json, OFF). Unsurveyed cells stay opaque (OW3).

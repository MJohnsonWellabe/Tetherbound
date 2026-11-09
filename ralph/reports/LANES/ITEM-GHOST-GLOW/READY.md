STATUS: land (GPU-judged arms ship, plus one revert)
BRANCH: tb/item-ghost-glow
HEAD: (this commit)

1. Ghost-glow ships ON (GPU 1108 G-ghost-glow, tb/item-scout-1108 4307f806f;
   coordinator ship decision):
   - Gains: F38#28 +0.91, F38#2 +0.67, F38#14 +0.57, F38#7 +0.53 (2/3) and
     F41#15 +0.29; F38#1 recheck +0.47 (3/3).
   - Mean +0.16 over 11 rows, and the emissive check passes.
   - F38#13 −0.62 and F39#18/#26 −0.33 were judged mostly capture-composition noise.
   - scripts/ui/graphics_prefs.gd apply_environment reads the optional keys
     glow_hdr_threshold, glow_hdr_scale, glow_intensity, glow_bloom and
     glow_blend_mode. An absent key keeps the engine default, so Low is unchanged.
   - data/config/art.json graphics_presets Medium and High: glow_hdr_threshold
     1.6, glow_intensity 0.5, glow_bloom 0.0, with `_why_glow_on`.
   - data/config/creature_rim.json: energy 1.0 -> 0.35 and power 1.8 -> 3.0,
     with `_why_ghost_glow`.
2. F41#13 charged_1105 ships ON (GPU 1108 G-f41-13-charged 5.53 -> 6.14, 3/3):
   - creature_surface_finishes.json charged_1105 is enabled, with `_why_on`.
   - tests/test_stormwood_charged_finish.gd now pins ON and checks for the round.
3. Revert: character_body_flags.json npc_vis_look_captain_a goes back to enabled
   false, with a `_why_off` naming the invalid arm B round and the
   G-f41-15-arm-b-fix re-shoot (c127b3cd7). tests/test_character_body_flags.gd is
   restored as it was before batch 25 (captain_a out of JUDGED_ON, original
   assertion).

Checks:
- Tests test_forward_plus_grade, test_realm_camera_far_floor,
  test_stormwood_charged_finish, test_creature_rim, test_character_body_flags,
  test_texture_import_policy and test_creature_mipmap_experiment_policy give
  27 tests, 2319 assertions, 0 failed.
- smoke_graphics_settings with --graphics-proof and an isolated user dir: 0 failures.
- smoke_graphics_low_persist --low-select then --low-reload: 0 failures each.
- All JSON parses.

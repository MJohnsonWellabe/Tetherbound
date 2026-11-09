# ARM: ghost-white characters and creatures on GPU Medium/High (LANE-MESHY, 9 Nov)

- Rows: Meadows F38#28, F38#2, F38#7, F38#13 (pale translucent fresnel rim on creatures, 6/6 judges); Tidewake F39#26, F39#18, F39#29 (named NPCs and speakers ghost-white and translucent, 6/6); Stormwood F41#15 (Marrow's head blown out). Likely all biomes.
- Branch: tb/item-ghost-glow. Head: see git log. **Needs the branch checked out** (one small script change in scripts/ui/graphics_prefs.gd); the arm itself is a config overlay, no asset import.
- Overlay: ralph/reports/LANES/ITEM-GHOST-GLOW/overlay_glow_threshold.json

## Cause (the common term)
- `art.json graphics_presets` Medium and High set `glow: true` and nothing else, so Godot's defaults apply: HDR threshold 1.0, soft-light blend, intensity 0.8. Low (Compatibility, every CPU capture) has `glow: false`, which is why the defect never shows on CPU.
- The same presets apply `forward_plus_grade.exposure_scale` 1.333 on top of realm exposure 1.35-1.42 (effective about 1.8-1.9) and ambient 1.65-1.9, so pale lit surfaces cross 1.0 easily: white/near-white hair and skin (Marrow's captain_a, Tidewake speakers), speaker-lit faces in dialogue (camera.json speaker_light_candidate key 0.9 / rim 1.5), and the additive unshaded creature fresnel rim (`creature_rim.json`, ON, energy 1.0, power 1.8, #c8d6f2). Everything above 1.0 blooms into a soft white halo, which reads as ghost-white and translucent.
- Character `day_rim` flags (character_body_flags.json npc_vis_look_*) are OFF, so they are not part of it.

## The arm (one global change)
- `graphics_prefs.gd apply_environment` now reads optional preset keys `glow_hdr_threshold`, `glow_hdr_scale`, `glow_intensity`, `glow_bloom`, `glow_blend_mode`; absent keys keep the engine defaults, so main is unchanged until a preset sets them.
- Overlay sets, on Medium and High: `glow_hdr_threshold` 1.6 (only emissive and truly hot pixels bloom: lightning, lanterns, crystals, emissive eyes), `glow_intensity` 0.5, `glow_bloom` 0.0; and tones `creature_rim.json` to energy 0.35, power 3.0 (a thin cool edge instead of a broad translucent halo).
- Frames to capture (High first, Medium if High gains): the F38#28, F38#2, F38#7, F38#13, F39#26, F39#18, F39#29 and F41#15 job frames. Also glance at a lightning/lantern frame (e.g. a Stormwood surge or a Tidewake lantern) to confirm emissive bloom still reads.

## Second lever, not in this arm
- `forward_plus_grade.exposure_scale` 1.333 (Medium/High) is the other amplifier. If the threshold arm helps but faces are still hot, the next arm is 1.333 -> about 1.15. Kept separate so the GPU result says which lever did it.
- The F41#15 Marrow arms (tb/item-f41-15) stay queued; this arm may supersede them.

## Checks
- CPU cannot show it (Low has no glow); no CPU sheet.
- Tests (all non-smoke tests that grep graphics_prefs or glow): 564 tests, 0 failed.

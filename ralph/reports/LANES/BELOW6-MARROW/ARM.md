STATUS: ready for GPU (High first)
ROWS: F41#15 Stormwood foreground obstruction (4.49; cause 1 of 2: Captain Marrow's head) and F41#7 (6.24)
BRANCH: tb/below6 (needs the branch: one new texture, import once)
OVERLAY: ralph/reports/LANES/BELOW6-MARROW/overlay.json (`character_body_flags.json below6_marrow_self_lit_off`, `stormwood_character_presentation.json identity_floor_1112`)
FRAMES: CAPTURE.json (the Marrow dialogue frames, base and arm)

# ARM: Captain Marrow stops lighting himself (LANE-BELOW6, 12 Nov 2026)

## What lights his head (found by building him through the real path and by ten CPU probes of the same dialogue frame)
The white head reproduces on CPU, which has no bloom, so it is not a glow effect.

1. **He emits his own texture.** Built as the game builds him (`stormwood_character_presentation.decorate` -> `trainer_npc.model_config` -> `character_model`), his body material has emission ON, operator ADD, colour 0.18 white, and **the captain_a albedo texture as the emission texture**. `captain_a` is the one cast body in `art.json` without `body_emission_enabled: false`.
2. **His 0.18 white floor comes from `stormwood_character_presentation.json uniform.emission_floor`,** which `trainer_npc.model_config` lays over the rank's own floor. That is why the two earlier rank-floor arms (`npc_ranks.json`) never reached him, and why "emission off" alone looked level: the floor's ADD kept emission on.
3. **Not the cause** (each switched off alone, face unchanged): the Stormwood character rim overlay (it does wash the body: body mean 168 -> 155), the crown spot light, the deck lanterns, the dialogue speaker light.
4. **What is left after 1 and 2 are off:** the deck's own scene light still clips a pale face on CPU. With every extra light off as well, the nose, mouth and eye are faintly readable. That remainder is Stormwood's scene lighting on the top deck (LANE-PLACES' storm-light work), not his material.

Probe numbers (mean 8-bit value of a face box / a chest box; `_sheet_cpu_probes.jpg`): base 221 / 168; emission texture off 215 / 148; plus Stormwood floor off 208 / 119; plus all extra lights off 208 / 102.

## The arm (flags OFF)
- `character_body_flags.json below6_marrow_self_lit_off`: `captain_a` gets `body_emission_enabled: false` (new allowed body-flag key) and a graded albedo `captain_a_lod0_texture_0_floor1.png`, in which only the pale texels (hair, skin, collar; 11% of the atlas above 0.38) are compressed by half. Dark cloth, armour and identity are untouched.
- `stormwood_character_presentation.json identity_floor_1112`: a named identity may state its own emission floor; Marrow's is 0. Other Stormwood uniforms keep 0.18.

## CPU check (`_sheet_cpu_base_fix_fixlightsoff.jpg`: base, arm, arm with all extra lights off)
- Arm: the body reads as dark armour and cloth with real contrast instead of a lilac wash; the face is still very bright, with the mouth and nose just visible.
- CPU clamps at white; Forward+ tonemaps, so the GPU face may recover more than this shows. It may also still clip. **If the head is still a white ball on High, the remaining cause is scene light, and this arm's gain is the body only.**
- Captain_b (Nerissa, Tidewake) has the same missing `body_emission_enabled`; not changed here.

## Expected
More than 0.5 on F41#15 and F41#7 if the face becomes readable on High; about +0.3 if only the body improves. The second F41#15 cause (Officer Nysa hidden by a creature) is LANE-THINGS'.

## Checks
`--only=character_body_flags,texture_import_policy,stormwood_character,npc_ranks,character_model`: 7 tests, 2001 assertions, 0 failed (the selector matched 3 test files). Texture sidecar set to VRAM compression.

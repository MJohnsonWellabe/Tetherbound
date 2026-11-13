# READY: tb/beings-charfix-land (character-model correctness fixes)

STATUS: land (objective bug fixes, proven by a test; no GPU verdict needed, per CRITERION_DELIVERY "Lane progress rules" 2)

- **Branch:** `tb/beings-charfix-land`, cut from `origin/main` 0ba1cfab.
- **Files:** `scripts/characters/character_model.gd`, new `tests/test_body_override_own_atlas.gd`, this READY.

## The two bugs
1. **A body texture override painted over a rig's second atlas.** `_palette_node` passes `body = true` for every surface, and `_shared_variant_material` put `body_albedo_override` (and `body_emission_override`) on all of them. Two installed rigs have a second textured surface with its own atlas: `villager_female` (mesh `shins`, `shins_tex`) and `villager_male` (mesh `trousers`, `trousers_tex`). An override on either painted the body atlas across those UVs, smearing coat cloth onto the legs (seen on CPU while building BEINGS-TAM-COAT). Fix: the rig's body atlas is the albedo of its first textured surface (`_first_albedo`); a surface with a different atlas keeps its own.
2. **The painted-hair cache dropped body overrides.** `_painted_hair_material` cached by model, hair colour and body only. A character built after another on the same model and hair colour (village Tam, then tournament Tam) received the first one's material and silently lost its body override (probe: with an override set, `char1` still wore `texture_0`). Fix: the source material's instance id joins the key.

## Effect on main today
None visible: no body override on `villager_female` or `villager_male` is ON (the five `npc_vis_look_villager_*` flags are OFF). Every single-atlas rig behaves exactly as before (pinned by `test_a_single_atlas_rig_still_takes_the_override_everywhere`). Any future villager coat or look arm needs these fixes to show at all.

## Tests
- `tests/test_body_override_own_atlas.gd`: builds a plain villager_smith, then one with an override (the order that exposed bug 2); the body wears the override, the shins keep `shins_tex`; a single-atlas rig takes the override everywhere. Uses textures already on main.
- Every test file that touches the character model, body overrides or painted hair: **121 tests, 10941 assertions, 0 failed**.
- `tests/smoke_art.gd` (on tb/beings with the same change): `art: OK`.

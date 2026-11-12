STATUS: land
BRANCH: tb/below6-marrow-land (cut from origin/main 2ac7ab843; READY is in the same commit)

# F41#15 / F41#7: Captain Marrow stops lighting himself, ON (LANE-BELOW6, 12 Nov 2026)

## Verdict
`ralph/reports/GPU-PASS/1108/G-below6-marrow.md` on `tb/item-scout-1108` 168422e80 (GPU High, three code-blind judges, confirming batch):

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| Marrow's two dialogue frames | 4.55 | 5.95 | +1.40 | 3/3 |

Base: "blown out to near white". Arm: "the face, eye patch and hair read cleanly", a mild rim glow on the hair is left. **Coverage gap:** F41#15's third frame (Officer Nysa) was not in the batch, so this is 2 of the row's 3 frames, not a row score. High only.

## Cause (found by building him through the real path)
His body material carried emission ON, operator ADD, colour 0.18 white and the captain_a albedo texture as the emission texture: he emitted his whole texture plus a floor. The floor came from `stormwood_character_presentation.json uniform.emission_floor`, which `trainer_npc.model_config` lays over the rank floor, so the earlier `npc_ranks.json` arms never reached him.

## What lands
- `data/config/character_body_flags.json below6_marrow_self_lit_off`: ON with `_why_on`. `captain_a` gets `body_emission_enabled: false` and the graded albedo.
- `data/config/stormwood_character_presentation.json identity_floor_1112`: ON with `_why_on`. Marrow's floor is 0; other Stormwood uniforms keep 0.18.
- `scripts/characters/character_model.gd`: `body_emission_enabled` joins `BODY_FLAG_KEYS` (one key).
- `scripts/world/stormwood_character_presentation.gd`: reads the identity floor.
- `assets/characters/captain_a/captain_a_lod0_texture_0_floor1.png` + sidecar (VRAM compressed; `texture_import_policy.py --check` PASS, 1539 sidecars).
- `tests/test_below6_marrow_landed.gd` (new): both flags ON and citing the verdict; Marrow's config built through `decorate -> model_config` has floor 0, emission rejected and the graded albedo; an officer keeps the uniform floor.
- `tests/test_character_body_flags.gd`: the flag joins `JUDGED_ON`; the "records its judged score" check also accepts a `_why_on` that names a `GPU-PASS/` verdict file (batch-7 flags still pass on their `_why`).

## Scope note
`captain_a` is also used outside Stormwood wherever a site names that body; those bodies lose the imported self-emission and take the graded albedo too (they keep whatever floor their own rank or site gives). `captain_b` (Nerissa) has the same missing opt-out and is not changed here.

## Tests
Run in the lane checkout (main 2ac7ab843 merged) with these files copied over: `--only=below6_marrow_landed,character_body_flags,texture_import_policy,stormwood_rank_marks,trainer_defeat_reaction,named_trainer_wild_clear,water_guardian_reward,stormwood_character,npc_ranks`: 8 test files, 22 tests, 2192 assertions, 0 failed. Older tests that name captain_a (`trainer_defeat_reaction`, `named_trainer_wild_clear`, `water_guardian_reward`, `stormwood_rank_marks`) are in that set and pass. No full suite.

## Still named by the judges on these frames
One flat lavender grade and a cut-out treeline; tiled pink-lilac planks; a saturated orange trunk at the left (one judge: near oxblood) and flat mauve at the right; a blue placeholder slab at the left edge; the dialogue box covers Marrow from the chest down.

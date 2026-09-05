# N04-DIALOGUE-PORTRAITS-0905 — every speaker wears its own face; villagers stop sharing one

Branch `ralph/N04-DIALOGUE-PORTRAITS-0905`, from `origin/main` @ `f8a47ee4`.
Brief: `ralph/briefs/0905-followup/N04-DIALOGUE-PORTRAITS.md` (sources W08-DIALOGUE-CAMERA,
W04-PORTRAITS). Owner directive 2026-09-04 item 8b: *"fix the picture during dialogue always
being the main character."*

## Outcome

All three items done and verified; two ownership notes at the end that the coordinator
should read before landing.

1. **Portrait keyed off a constant (the critical one).** On the tree this lane started
   from it was not: `dialogue_panel.gd` already pulls `portrait` off the runner's current
   line every draw, exactly as it pulls the speaker's name, and W04's data re-point
   (PR #45) had already landed. W08's judge saw the pre-W04 tree. What was still wrong on
   `main` was **Warden Aldis** — three conversations in `data/dialogue/stronghold.json`
   still named the player's `trainer.png`. He now wears `warden.png`. The real panel is
   now under test: opened on Halda then Oskar, and Mira then Tam, it draws two different
   plates each matching the speaker's own field (seen red with the fix reverted).
2. **Generic trainer refusal wore `villager_male.png` labelled "Trainer".**
   `dialogue_panel.start(id, identity)` takes an optional `{"speaker", "portrait"}` overlay
   for a SHARED conversation; `trainer_npc.gd::speaker_identity(spec)` supplies the
   challenged trainer's own name and the plate its own `challenge` line wears. Proven in
   the booted world by a new smoke: Bryn's refusal draws `bryn.png` labelled "Bryn".
3. **Eight female-rig villagers shared one face.** The per-NPC hair colour reached only
   the ponytail at the nape. It is now also mixed over the hair PAINTED into the shared
   body texture — fringe, cap, sides — through a baked mask on the body material's detail
   layer (no new geometry, no new mesh, no whole-body tint, the face untouched). The seven
   female-rig plates were re-rendered through the same dressing call the world uses.

## Files changed

| File | What |
|---|---|
| `scripts/ui/dialogue_panel.gd` | `start(conversation_id, identity := {})`; `_identity` overlay applied in `_draw()` for speaker and plate (a plate not on disk falls through to the line's own); cleared on finish. New `current_portrait()` / `current_speaker()` so a test can ask what the player sees. File comment states the contract: the plate is the speaking line's, never a constant. |
| `scripts/world/trainer_npc.gd` | `speaker_identity(spec)` (static, pure): the trainer's `name` and the `portrait` of its `challenge` (fallback `defeated`) conversation from the runner's table. Passed to `panel.start()` for the two generic refusals only. |
| `data/dialogue/stronghold.json` | Warden Aldis ×3 → `warden.png`. `_comment_portraits` rewritten to say so and to record why the three bodiless narration speakers keep `trainer.png`. **Outside the brief's file list — see ownership note 1.** |
| `scripts/characters/character_model.gd` | `_apply_hair()` now also calls `_recolour_painted_hair()` when a colour is given and `<model>_hair_mask.png` exists beside the model: a cached per-(model, colour, body) variant of the surface's current material with `detail_enabled`, `BLEND_MODE_MIX`, `detail_mask` = the baked mask, `detail_albedo` = a 4×4 solid texture of the colour (cached per colour). Applied to the body mesh and the ponytail so nape and fringe agree. `painted_hair_mask_path()` is public/static. This is the file `grep -rn hair_ponytail scripts/ scenes/` names, i.e. the brief's third owned file. |
| `assets/characters/villager_female/villager_female_lod0_hair_mask.png` (+`.import`) | The baked mask, 2048², L8, 285 KB. 384,189 hair texels in 43 components; value carries the painted shading. |
| `tools/_bake_villager_female_hair_mask.py` | The deterministic bake (numpy/Pillow/scipy): head-bone-skinned UV islands + ponytail islands, colour-keyed to the painted hair (luma < 70, warm brown), components < 1500 texels dropped (pupils, lashes, brows), value `clamp(luma/28,0,1)^0.7`. Documented in its header. |
| `assets/ui/portraits/{villager_female,mira,tam,villager_ranger,halda,rae,doss}.png` | Re-rendered by the unchanged `tools/_capture_portraits.gd` (`-- villager_female mira tam villager_ranger halda rae doss`), 7 plates, 0 failures, all `edge=clear`, `blown=0.0%`, cover 44–45%. `villager_female` is the contract plate with no colour and is visually unchanged. **See ownership note 2.** |
| `tests/test_dialogue_portraits.gd` | Carve-out narrowed from "every stronghold id" to three bodiless speakers by name; the Warden is now held to the rank rule. Six new tests (below), including the real-panel two-villager test CL-G11 asks for. |
| `tests/test_villager_female_painted_hair.gd` (new) | Six tests on the built rig's materials. |
| `tests/smoke_trainer_refusal_portrait.gd` (new) | Booted-world proof of item 2. |
| `docs/decisions/D87-…md` (new) | The three calls. |
| `docs/GATE2_GATE3_CLOSURE_PLAN.md` | CL-G11 row rewritten: wiring closed, per-NPC art honestly partial, every shared plate named. Only that row touched (N10 owns the file's status rows; this row is the one my brief names). |
| `docs/CURRENT_STATE.md` | The §3 portrait row rewritten in place. |
| `ralph/reports/N04-DIALOGUE-PORTRAITS-0905/` | This report, `_sheet_female_plates_before_after.png`, `_sheet_ingame_conversations.png`, `JUDGE_VERDICT.md`. |

Not touched: `scripts/story/dialogue_runner.gd` (stays pure; the overlay lives in the
panel), any dialogue camera code, `tests/smoke_trainer_no_usable_ally.gd` /
`smoke_trainer_no_ally_deployed.gd` (run unchanged as regression), the hair colour values
in `art.json` / `village_npcs.json` / `river_nest_clear.gd`, `docs/owner/*`.

## Player-visible behaviour

- Walk up to any trainer with a fainted or undeployed creature: the box is labelled with
  that trainer's name over that trainer's face (was "Trainer" over a generic villager).
- The Warden's challenge, his concession and the Realm Key handoff show the Warden (was the
  player's own face at the climax of the chapter).
- Mira (chestnut), Tam (silver), Halda (iron grey), Rae (warm auburn), Doss (green) and the
  plain rangers (deep auburn) are now different people from the front, in the world and on
  their plates. Eyebrows, eyes and skin are unchanged.

## Tests and smokes — every command, every count

Godot 4.7-stable headless in this container, two clean import passes before the
first run and a third after the plates were re-rendered.

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_dialogue_portraits.gd,test_villager_female_painted_hair.gd,test_character_hair_split.gd` | **22 tests, 2194 assertions, 0 failed**, no `SCRIPT ERROR`. (A first run had two panel tests crash on `Engine.get_main_loop()` being null under `run_tests.gd` and the harness still printed `ok` for them — the panel is now stood up off-tree the way `test_companion_presence.gd` does it, and the run was repeated clean.) |
| Same selectors with the three fixes reverted at once (panel ignoring the identity, `_recolour_painted_hair` call removed, Warden back to `trainer.png`) | **18 tests, 9 failed**, exactly: `test_a_stale_identity_portrait_falls_back…`, `test_every_trainer_in_the_table_has_a_face…`, `test_no_line_spoken_by_someone_other_than_the_player…`, `test_ranked_and_family_speakers…`, `test_the_generic_refusal_wears…`, `test_the_warden_wears_his_own_plate…`, `test_a_hair_colour_reaches_the_painted_hair…`, `test_the_art_json_villagers_each_get…`, `test_two_colours_are_two_materials…`. Restored; green again. |
| `godot --headless --path . --script tests/smoke_trainer_refusal_portrait.gd` (new) | exit 0. `refusal opened by 'practice_trainer': plate=bryn.png speaker='Bryn' (own=bryn.png neutral=villager_male.png)`; the panel reports no plate/speaker after the refusal closes. `grep -E '^ERROR:\|SCRIPT ERROR'`: 1 line, the known-benign `Parameter "material" is null` at `creature_body.gd:492` (recorded at 0–3 per run by W00, W09, W12, G3-BAND5 before this lane; N03 owns it). |
| `godot --headless --path . --script tests/smoke_trainer_no_usable_ally.gd` (unchanged) | exit 0, `OK`; 0 error lines. |
| `godot --headless --path . --script tests/smoke_trainer_no_ally_deployed.gd` (unchanged) | exit 0, `OK`; 2 error lines, both the known-benign material line. |
| `godot --headless --path . --script tests/smoke_dialogue_clears_the_world_hud.gd` (unchanged) | exit 0, `PASS: nothing the world HUD draws composites through the dialogue box`; 0 error lines. |
| `godot --headless --path . --script tests/smoke_village_trainer.gd` (unchanged) | exit 0, `OK`; 2 error lines, both the known-benign material line. |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_trainers_data.gd,test_dialogue_runner.gd,test_character_model.gd` (neighbours, unchanged) | **116 tests, 2402 assertions, 0 failed**. |

The known-benign set did not grow: the only `ERROR:` line in any run above is the one
`docs/AGENT_WORKFLOW.md` and four earlier reports already record.

### What the new tests actually exercise

`test_dialogue_portraits.gd` (16 tests, was 5):
- the real `dialogue_panel.tscn`, `_ready()` run, opened on `tournament_halda` then
  `village_oskar`, and on `village_mira` then `village_tam`: `current_portrait()` differs
  within each pair, equals the speaker's own authored plate, and is never `trainer.png`;
- the generic refusal with `trainer_npc.speaker_identity(practice_trainer)` draws `bryn.png`
  labelled "Bryn"; the same refusal with no identity draws `villager_male.png` labelled
  "Trainer" (so no caller is worse off);
- the identity is gone once the refusal is advanced off its last line (Oskar's greeting after
  it draws Oskar); a stale plate path in an identity falls through to the line's own plate
  while the name half still applies;
- every one of the 24 trainers in the band tables resolves an identity with a name and a
  plate that exists and is not the player's;
- the Warden's lines (all ≥3 conversations) wear `warden.png`; the three named carve-outs are
  all still spoken somewhere (a carve-out for nobody comes out of the list);
- the five W04 tests are unchanged in intent; the stronghold carve-out is now by speaker
  name, so the not-the-player rule and the rank-family rule cover the Warden.

`test_villager_female_painted_hair.gd` (6 tests): builds the real rig off-tree and reads the
materials it carries — the body material has `detail_enabled`, `BLEND_MODE_MIX`, `detail_mask`
= the baked mask, `detail_albedo` pixel = the hair hex, `albedo_color` still white (the face
is on that material); the ponytail carries the same layer; two colours give two materials
and one colour is shared from the cache; no colour or hidden hair adds nothing; farmer, smith
and ranger from `art.json` land three different colours; Grandpa and the trainer rig (no mask
on disk) gain no layer even when handed a colour.

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

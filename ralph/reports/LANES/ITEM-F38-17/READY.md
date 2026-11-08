STATUS: land
BRANCH: tb/item-f38-17 (carries F38#17 and F41#8 together: tb/item-f41-8 merged in, coordinator 7 Nov)
HEAD: (this commit; merged origin/main just before writing)

# ITEM F38#17: named trainer dialogue (Warder Solene, Keeper Hald) (LANE-KIT)

## Scores
- qj F38-17-f8ab7f3fcf77-11072319 (CPU llvmpipe, three code-blind judges, 3 anchors, slope 1.41, r 0.90, RMSE 0.51):
  base 5.81 -> candidate **7.32** (+1.51). Raw 5.5 5.6 5.2 / 6.6 6.6 6.3. Defect FIXED,PARTIAL -> FIXED (3/3).
- All three judges: Solene and Hald are now distinct people and match their portraits. Just under 7.5 on CPU, and it
  is a GPU candidate under the close-out exception. One round.

## Flags (ON, judged gain)
- data/config/character_appearance_variants.json: `lanekit_f38_17_solene` and `lanekit_f38_17_hald`, `enabled: true`,
  `_why_on` naming the round and 5.81 -> 7.32.
- Bound in data/config/bands/band5_stronghold_approach/trainers.json (stronghold_courtyard, stronghold_elite):
  `base: grunt` (the rank's own default, so OFF changes nothing) + `appearance_variant_id`, mirrored in
  tests/fixtures/band_split_baseline/trainers.json with `_why_appearance_variant_f38_17` (band mirror rule).
- Installed cast only, no Meshy and no new mesh. Each body is a byte copy of the installed officer_b / captain_b rig
  with its installed graded vis1 atlas embedded (embed_atlas_glb.py), plus the installed officer_b.png and captain_b.png
  plates. provenance.json sits beside each GLB (sha256s; height 1.80 from the rank config). The rank palette, badges
  and clips are kept, in Team Tether colours.

## Code
- scripts/world/trainer_npc.gd `with_variant_portrait()`: a trainer whose body is an ENABLED appearance variant wears
  that variant's paired plate on every line. A disabled, unknown or mismatched record returns the identity unchanged.
- tools/phase2_capture_dialogue.gd hands the panel the same identity (the capture opened the panel directly before).

## Tests
- Texture import policy: the four new runtime 3D sidecars set to mode 2 (`texture_import_policy.py --apply`, reimported); `--check` PASS, test_texture_import_policy 2/2.
- test_character_appearance_variants.gd 11/11 (record count `staged.size() + 10`, all four LANE-KIT records).
- test_band_content 6/6, test_dialogue_portraits 13/13, test_trainers_data 51/51, test_vis_meadows_1104_on 20/20,
  test_meadows_earned_hall_segment 16/16, test_named_fight_profiles 8/8, test_beaten_trainer_prompt_yields 3/3.
- JSON parse: character_appearance_variants.json, both trainers.json files.

## Files
- assets/characters/npc_identity/lanekit_f38_17_{solene,hald}/ (glb, extracted atlas, .import, provenance.json)
- ralph/reports/LANES/ITEM-F38-17/embed_atlas_glb.py
- data/config/character_appearance_variants.json, data/config/bands/band5_stronghold_approach/trainers.json,
  tests/fixtures/band_split_baseline/trainers.json, tests/test_character_appearance_variants.gd,
  scripts/world/trainer_npc.gd, tools/phase2_capture_dialogue.gd
- ralph/reports/LANES/LANE-KIT/qj/F38-17-f8ab7f3fcf77-11072319/

## Flags left OFF
- none for this row.

## Caveat
- These bodies are the same installed rigs that Officer Vess (band4, officer_b) and the band3 captain_b trainer wear,
  so a player meets the same face twice in Meadows. The judges did not see this; it is existing practice
  (captain_a is already shared by two band trainers). A hair or trim recolour baked into the copied atlas would separate them.

## Judges' asks (outside this lane's files)
- Flat orange-brown interior light in the stronghold rooms; uniform grass carpet and flat sky behind Bram (scene).
- The player's head is cropped at the left edge of every dialogue frame (camera.json conversation framing).
- One judge flagged the red rose bush beside the player in the Bram frame as red outside Team Tether.

## Next idea
- Run the GPU High pass first (CPU 7.32, and the close-out exception applies). If it lands under 7.5, the cheapest
  further step is the player-head crop in the conversation framing (owner of camera.json).

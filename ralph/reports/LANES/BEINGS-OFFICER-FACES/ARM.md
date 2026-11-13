# BEINGS-OFFICER-FACES: four officers, four looks (F41#8, F41#18)

**Status: CPU-ready, NOT queued.**

**Defect, quoted (3/3 on both 13 Nov verdicts, G-below6-uniform-cloth-c673 and G-below6-staticub-fur-dialogue-c673):** "Lieutenant Sera and Officer Maren share one face, coat and portrait"; "Officer Nysa shows the same male face and portrait as Lieutenant Varga". Ask: separate them, "face or hair and coat colour".

## Cause, and how it was confirmed
`data/config/stormwood_trainers.json`: Sera and Maren both have `humanoid_key` `officer_b`; Varga and Nysa both have `officer_a`. No appearance variant is attached to any of the four, so each pair resolves to the same body, texture and plate (probe with the game's own `appearance_variants.resolve`: identical results per pair).

## Change (flag-off, installed cast only)
Two records in `data/config/character_appearance_variants.json`, both `enabled: false`, attached to the two trainers with `appearance_variant_id` (inert while the records are off; Sera and Varga get nothing):
- `beings_stormwood_maren`: officer_b with chestnut-honey hair (`officer_b_lod0_texture_0_vis1_maren.png`) and a matching plate.
- `beings_stormwood_nysa`: a copy of officer_b (`npc_identity/stormwood_nysa/nysa_lod0.glb`, embedded atlas with ash-silver hair) and a matching plate. She leaves Varga's male face; the silver hair keeps her apart from Sera and Maren.
Made by `derive_officer_hair.py` in this folder: hair is chosen by position on the model (top 16% of height, from the model's own UVs) and the plum hair hue, with the front of the face excluded so lips and eyes keep their pixels; shading kept. Plates get the same recolour of the officer_b plate the game shows, with the face excluded. No new mesh, no Meshy.

**One decision to note:** the game's text never states Nysa's gender (checked dialogue and design docs). The judges read her as a woman ("her Staticubs"); this arm follows them. If the owner sees Nysa otherwise, drop the Nysa record and keep Maren's.

## CPU check
`_sheet_cpu_sera_maren_nysa_varga.jpg`: top, the four bodies under one light (Sera plum, Maren chestnut-honey, Nysa ash-silver, Varga unchanged); bottom, their plates. Probe: off, all four resolve as today; on, Maren gets her texture and plate, Nysa her body and plate, and no officer_a texture is carried onto Nysa's new body.

## By-eye line for the GPU lane
In Maren's and Nysa's dialogue frames the hair is chestnut-honey and ash-silver respectively, and Nysa's face is a woman's face, not Varga's. If either still shows plum hair or Varga's face, hold.

## Risks
- Ash-silver can read "elderly". If judges say so, the next round is near-black hair for Nysa.
- Hair cards at the fringe edge show a few dark texels (the mask is hue-based on a baked atlas).
- Not addressed: the uniform cloth ask and the row of identical figures behind Maud.

## Tests
`tests/test_beings_officer_faces_flag.gd`, plus every test that reads `stormwood_trainers.json` or appearance variants, and the uniform, body-flag and Marrow tests: 100 tests, 0 failed. `test_character_appearance_variants.gd` record count updated (+2).

## Landing notes
Records ON with `_why_on`; turn `test_records_are_off_and_attached_to_the_two_officers` and `test_off_nothing_changes` into ON pins.

# BEINGS-OFFICER-FACES: Maren apart from Sera, Nysa apart from Varga (F41#8, F41#18)

**Status: ready to queue.** One overlay: `beings_stormwood_maren` and `beings_stormwood_nysa_hair` ON.

**Owner, 13 Nov 2026 (via the coordinator):** Nysa keeps her current face and her gender stays unstated; she is told apart from Varga by hair colour and portrait only. The officer_b body swap built earlier was dropped (record, model copy and plate removed).

**Defect (3/3 on both 13 Nov verdicts, G-below6-uniform-cloth-c673 and G-below6-staticub-fur-dialogue-c673):** "Lieutenant Sera and Officer Maren share one face, coat and portrait"; "Officer Nysa shows the same male face and portrait as Lieutenant Varga".

## Cause, and how it was confirmed
`data/config/stormwood_trainers.json`: Sera and Maren both have `humanoid_key` `officer_b`; Varga and Nysa both have `officer_a`; no appearance variant on any of the four. The game's own `appearance_variants.resolve` gives each pair the same body, texture and plate.

## Change (flag-off, installed cast only)
Two records in `data/config/character_appearance_variants.json`, both `enabled: false`, attached with `appearance_variant_id` to the two trainers (Sera and Varga get nothing):
- `beings_stormwood_maren`: officer_b; chestnut-honey hair (`officer_b_lod0_texture_0_vis1_maren.png`) and a matching plate.
- `beings_stormwood_nysa_hair`: officer_a, her current face; ash-silver hair on the judged uniform-cloth texture (`officer_a_lod0_texture_0_vis1_cloth2_nysa.png`) and a matching plate.
Both made by `derive_officer_hair.py` in this folder (hair chosen by position on the model and hair colour, eyes and brows kept; shading kept). No body or face change; a test pins that no record swaps a body.

## CPU check
`_sheet_cpu_sera_maren_nysa_varga.jpg`: top, the four bodies under one light (Sera plum, Maren chestnut-honey, Nysa ash-silver on her own face, Varga black); bottom, their plates. Resolve probe: off, all four resolve as today; on, Maren and Nysa get their textures and plates, and Sera and Varga do not change.

## By-eye line for the GPU lane
Maren has chestnut-honey hair and Nysa ash-silver hair. Both faces are the ones they have today. If either still shows the shared hair (plum for Maren, black for Nysa), hold.

## Risks and known limits
- On Nysa's body the top and back of the hair turn grey-silver, but the forelock over the forehead stays near-black (it lies inside the box that protects the eyes and brows; two other selections were tried and did worse). The plate is fully silver.
- Nysa and Varga keep one face by the owner's choice, so judges may still say "same face". Hair and plate are the whole lever here.
- Ash-silver can read as older.

## Tests
`tests/test_beings_officer_faces_flag.gd` and `tests/test_character_appearance_variants.gd` (record count +2), plus every test that reads `stormwood_trainers.json` or appearance variants.

## Landing notes
Both records ON with `_why_on`; turn the OFF assertions in `test_beings_officer_faces_flag.gd` into ON pins.

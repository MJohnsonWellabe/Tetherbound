# BEINGS-TAM-COAT: Tam in a slate-blue coat, apart from Mira (F38#16)

**Status: ready to queue.** Overlay: `beings_meadows_tam_coat` ON.

**Row:** F38#16 tournament dialogue, GPU High 7.31 (G-rescore-f38-16-c673), 0.19 short of the bar. A close-out item.

**Defect, quoted:** judge a, "Mira and Tam share the same green-hood body and differ only in hair colour"; top ask (all three): "Give Mira and Tam distinct outfits (colour or garment)".

## Cause, and how it was confirmed
`art.json`: `villager_farmer` (Mira) and `villager_smith` (Tam) both use `villager_female_lod0.glb` with the same olive hooded coat; only the hair tint differs. The tournament has no separate Tam body: the player meets village Tam at the ring (captured: the dialogue frame's body is the village NPC).

## Change (flag-off)
- `character_appearance_variants.json beings_meadows_tam_coat` (OFF): Tam's coat recoloured slate blue (hue 212) by the shipped LANE-KIT coat recolour (`../ITEM-F41-8/recolor_coat.py`, olive cloth only; `make_tam_coat.sh` here), with the same recolour of her plate. Hair, face, skin, leather and rig keep their pixels; presented gender unchanged. Attached to village Tam and the tournament trainer entry; Mira and Oskar unchanged.
- So the panel face matches the body: village lines drawn with `tam.png` show the variant plate (`replaces_portrait` in the record; `village_npcs.gd variant_identity()`; `dialogue_panel.gd` honours `portrait_replaces` only on lines drawn with that plate, so other speakers keep theirs). Inert while the record is off.

## Two engine bugs found and fixed on the way (also cut separately as `tb/beings-charfix-land`)
1. A body texture override was painted on every surface, including rigs' second atlas (villager_female's Shins, villager_male's Trousers), smearing cloth onto the legs. Now only surfaces using the body atlas take it.
2. The painted-hair material cache ignored the body override, so a character built after a plain one with the same model and hair colour (tournament Tam after village Tam) silently lost its override. The source material now joins the key.
Pinned by `tests/test_body_override_own_atlas.gd`. No override on these rigs is ON on main, so nothing visible changes today.

## CPU before and after
`_sheet_cpu_dialogue_base_left_arm_right.jpg`: the real `tournament_semi_tam__dialogue` frame. Base: olive hood, olive plate. Arm: slate-blue hood and socks in the world, matching blue plate.

## By-eye line for the GPU lane
In `tournament_semi_tam__dialogue` Tam's hood is slate blue in the world and on the plate; in `tournament_quarter_mira__dialogue` Mira's is still olive. If Tam's world hood is olive, hold.

## Risks
- The judges' other near-bar asks (the pink glowing bush, a three-quarter camera) are LANE-SCENE's; this arm only answers the outfit.
- Village frames with Tam change too (she now wears blue everywhere). That is the point (one identity), but any village row with Tam in frame should be in the no-loss set.

## Tests
`test_beings_tam_coat_flag.gd`, `test_dialogue_portrait_replaces.gd`, `test_body_override_own_atlas.gd`, plus every test touching the village, the dialogue panel, appearance variants or the character model: 688 tests, 0 failed (one of my own new tests needed its search fixed, then passed). `smoke_art.gd`: OK.

## Landing notes
Record ON with `_why_on`; turn the OFF assertions in `test_beings_tam_coat_flag.gd` into ON pins, including `test_village_identity_follows_the_record` (ON: village Tam's identity carries the coat plate and `portrait_replaces` = tam.png).

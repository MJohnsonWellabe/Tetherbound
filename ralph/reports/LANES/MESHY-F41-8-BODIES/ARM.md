# ARM: distinct_bodies_1111 (F41#8, 5.31), LANE-MESHY, 11 Nov 2026

Branch tb/item-f41-8-bodies. Ships OFF; overlay.json turns it ON.

## Defect
Elder Maud, Rodkeeper Hesk and Warden-elect Bryn all stand on the one installed local_historian body (an
elderly cloaked figure with a cane). Across five earlier rounds, retints and accessories could not stop the trio
reading as one person three times.

## Change (no new mesh; installed T1 cast from the owner's Meadows NPC Design Board)
`stormwood_chapter.gd distinct_bodies()` swaps body_profile for the listed actors when ON:
- Rodkeeper Hesk -> alpha_tracker (brimmed hat, field gear: the outdoor keeper of the storm rods);
- Warden-elect Bryn -> lost_traveler (a younger, lighter figure: the newly chosen warden);
- Elder Maud keeps local_historian and her lanekit appearance variant (the elder).
Neither new body is used anywhere else in Stormwood. Bryn's lanekit variant was painted for the historian body,
so it is dropped with the body. Role accessories are bone-attached and carry over (Hesk's rod staff, Bryn's oilskin hat).
Names, dialogue, positions and portraits are unchanged. Presentation only.
Reference: Blender previews of the installed candidate bodies (scratch only, one sheet per round). Scale: the installed cast
model heights are 2.65-2.78 model units, the same family and the same rig.

## CPU proof (tools/phase2_capture_dialogue.gd --biome=stormwood --seed=2042, 1280x720 Low)
`_sheet_trio.jpg`, OFF left and ON right. Maud is unchanged. Hesk reads as a hatted field worker, Bryn as a younger
traveller: three distinct silhouettes and palettes. The figures are still small in these inventory stands (a framing
note for the row, not this arm).

## Note
local_historian is an elderly bearded man, and Elder Maud keeps it. If Maud is meant to read as a woman, no installed
elder-woman body exists, and that would need new art.

## Tests
tests/test_stormwood_distinct_bodies.gd (enabled and disabled copies) plus --only=stormwood_b_rook,stormwood_pims:
19 tests, 0 failed.

## GPU result + round 2 (11 Nov)
G-meshy-f41-8-distinct-bodies (LANE-SCOUT, tb/item-scout-1108 ace829dd4): +0.29, 2/3, no loss (5.43 -> 5.72). That passes the
ship rule but is under 0.5, so it rides in with LANE-FLOOR2's Stormwood storm-light pass, which fixes what holds the row (3/3):
crushed black pools, posterised moss, flat lilac sky, over-bright villagers.
Judge c dissented: at small size Hesk and Bryn share a tan-and-brown palette. Fix on this branch (18976385):
- `meshy_f41_8_bryn_teal` appearance variant on lost_traveler. recolor_bryn.py recolours only the olive scarf and trousers to
  teal-green (hue 165; hair, skin, boots and bedroll untouched), with a matching Blender-rendered portrait
  (assets/ui/portraits/meshy_f41_8_bryn.png).
- `distinct_bodies_1111.variants` applies it to Bryn. The trio now reads tan (Hesk), blue-grey (Maud) and teal (Bryn).
CPU: the Bryn inventory frame with the arm ON shows the cool teal cloth beside the trainer.
Tests: --only=stormwood_distinct_bodies,appearance_variant,stormwood_b_rook,stormwood_pims,portrait gives 45 tests, 0 failed
(test_character_appearance_variants counts one more record).

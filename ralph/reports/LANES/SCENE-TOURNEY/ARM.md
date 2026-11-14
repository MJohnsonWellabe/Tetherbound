# SCENE-TOURNEY: tournament conversations without the pink halo (F38#16 close-out)

Row: F38#16 tournament dialogue subject, GPU High 7.31 on main (`G-rescore-f38-16-c673.md`; recorded defect FIXED 3/3; 0.19 short). Close-out exception applies.

The judges' remaining asks, in order:
1. 3/3: "a pink glowing bush on the left in every frame reads as an odd effect".
2. Judge a: "Mira and Tam share the same green-hood body and differ only in hair colour".
3. Also named: flat mask-like faces (3/3), a smeared foreground (b), a stiff front-on camera (c). Not addressed here.

## Causes, and how they were confirmed

**The pink glow.** A probe at Mira's conversation shot, taken at the moment the frame is saved, cast rays at the bush's pixels and listed every pickup glow in view:
- the ray hits `BerryPlant/Bush_Common_Flowers` (a berry harvest node, `harvest_node.gd`) 11.3 m from the lens;
- the only glow in view is that node's, item berries, tint #f26d8f, 11.8 m away.

Berries are food, so the node carries the pickup glow, and its tint comes from the berry colour. The bush, its berries and its prompt are normal gameplay; the halo is what reads as an effect in a conversation shot.

**The shared body.** `art.json`: Mira is `villager_farmer`, Tam is `villager_smith`. Both use `villager_female_lod0.glb` with the same texture and differ only in hair colour. Tam's portrait (`assets/ui/portraits/tam.png`) shows the same olive hood.

## Split (14 Nov, coordinator)

Tam's outfit colour is removed from this arm's overlay: LANE-BEINGS' BEINGS-TAM-COAT recolours the same coat and is captured first, and two arms on one coat would make both verdicts unreadable. `scene_tam_outfit_1113` stays flag-off in code and is not part of this arm; it comes back only if BEINGS-TAM-COAT loses. **This arm is now the berry-glow fade only.**

## Arm (as first built; item 2 is no longer in the overlay)

Overlay (`overlay.json`) turns on two flag-off changes on `tb/scene`.

1. **`pickup_glow.json conversation_fade_1113`**: every pickup halo fades with the conversation camera's own push-in and returns as it eases out. Nothing can be gathered mid-conversation, so the "take this" cue has nothing to say there. Outside conversations nothing changes. This touches every dialogue row that has a pickup in view, not only F38#16.
2. **`character_body_flags.json scene_tam_outfit_1113`**: Tam's body uses a copy of the installed texture whose olive hood and tunic are slate blue (`assets/characters/villager_female/scene_tam_1113/derive_tam_outfit.py`). The script uses a hue window around the measured olive plus a green-over-red guard, so leather, skin, brass, white cloth and eyes do not move. Tam's dialogue portrait gets the same recolour through a new `portrait_remap` on the flag, read by `dialogue_panel.gd`. No red or oxblood. `villager_smith` is only ever Tam (village smith, band-1 `trainer_tam`, `tournament_semi_tam`), so Tam looks the same everywhere.

## CPU

`phase2_capture_dialogue.gd --biome=meadows --seed=2042`, the three tournament subsets. `_sheet_cpu.jpg`: left column Mira, base on top and arm below; right column (bottom) Tam on the arm. Base Tam is the same frame as on the GPU board: the same olive hood as Mira.

## By-eye line for the GPU lane

`tournament_quarter_mira__dialogue`: no pink halo behind the flowering bush at the left (the bush and its berries are still there). If the halo is still visible, hold the arm. (Tam is not changed by this arm.)

## Risks and no-loss frames

- The glow fade applies to every conversation. No-loss: one dialogue sample per biome (the 9-conversation Meadows and Stormwood samples used for G-things-convtight) and F38#17, F38#37.
- The berries themselves are pink-magenta. If a judge still names "a pink bush" with the halo gone, the next step is the berry tint, which is a gameplay readability call rather than a scene one.
- Tam appears in the village and the band-1 trainer fight with the same new colours: F38#22 (village life) as no-loss.

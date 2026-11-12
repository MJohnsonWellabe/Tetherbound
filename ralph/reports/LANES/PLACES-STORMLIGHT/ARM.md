# ARM: storm_phase_1111 + distinct_bodies_1111 (P1 Stormwood storm light), LANE-PLACES, 11 Nov 2026

Branch `tb/places`. Everything ships OFF; `overlay.json` turns both flags ON.
Rows: F41#2, #4, #5, #12, #19 (storm light), F41#8 (storm light plus distinct bodies), F41#6 and #13 as riders (same sky and light in frame).

## What the judges asked for (STORMWOOD-LIGHT-ASKS) and what this arm does
| Ask | Change (all behind `presentation.storm_phase_1111` in `stormwood_surge.json`) |
|---|---|
| "flat lavender sky card", "blocky, faceted polygons with streak artefacts" | The ceiling dome normalises its view direction per pixel and doubles its tessellation (the faceting came from an interpolated direction). The deck becomes two layers: a billowed high deck with dark undersides and key-lit tops, and a faster dark scud shelf, over a paler band with hanging rain veils above the treeline. |
| "Calm, Building and Break differ only in rain density"; "the sky never darkens at break" | Per phase: underside depth and deck darkening rise Calm < Building < Break; the pale band and the ground keep their value (lift, don't darken). |
| "phase key light with white-violet bolts"; "no lightning" | Break's decorative bolts are wider with a soft halo, held about 0.9 s and mostly inside the view. While a bolt is up, one shadowless white-violet light shines from the bolt toward the camera (trunks, canopy and wet ground take a lit edge), with a low held floor from Break's crawler veins and a small exposure lift. Building gains slow, faint far-horizon bolts. Calm has none. Bolts stay held during a ground warning and inside the flash budget. |
| "no shafts" | Bug fix inside the flag: the shipped light shafts (`storm_sky_1101`) were culled everywhere away from the world origin, because the MultiMesh's bounds were centred on a node that never moved. They drew only round Cinder Verge. With the flag the node follows the camera's cell, so shafts draw on the whole route (strongest in Calm and Fading). |
| "no fog layering between near and far", "single purple treeline card" | New `stormwood_fog_layers.gd`: low mist banks between tree ranks from 30 m out, on the ground under each bank. They are alpha-blended in the storm horizon colour with a luminance cap, so stacked banks cannot glare (the Glass Field "white lens blob" came from additive height fog). Nothing is drawn over the near ground. |
| F41#8 "three roles share one body" | `distinct_bodies_1111` from `tb/item-f41-8-bodies` (GPU +0.29 alone), with Bryn's teal recolour, rides in the same overlay. |

Not in this arm: the dark path and pools. Lighter wet earth lost on GPU (swing-1) and the judged de-pink is live; I left ground albedo alone.
Parked levers are not repeated: no in-cloud sheet glow change, no fight-distance rim, no charge-line accents.

## CPU proof (Compatibility, Low; sheet `_sheet_cpu_base_vs_arm.jpg`, base above or left, arm below or right)
- F41#2 phase stills (struck_sentinel calm, building, break): the arm sky is layered and darkens by phase; Break shows forked bolts.
- F41#8 inventory and dialogue frames: layered sky and a light shaft in frame; Hesk is a hatted field keeper, Bryn a younger figure in teal, Maud unchanged.
- Matrix stands (`capture_stormwood_f10_matrix.gd`, forest, glass, rod_line): in forest Break the bolt light lifts the canopy and puts a sheen on the wet ground; at the Glass Field Break shows bolts with halos and a pale mist bank between the far trees, with no white glare.
- Tests: `--only=places_storm_phase,stormwood_surge_presentation,cause_stormwood_candidates,stormwood_distinct_bodies` pass with the flags off (as committed).

## Risks to check on GPU
- Glass Field (F41#12, #19): confirm no fog glare; banks are capped below the sky's own horizon value.
- Forest Break: a specular sheen on wet pools from the bolt light (specular cut to 0.3 after the first CPU look).
- Break frames vary with bolt timing; a frame between bolts still has the held floor light and crawlers.

## Tunables if the judges want more or less
`storm_phase_1111.overlay`: `fog_layers.max_alpha` (0.6), `sky_lightning.bolt_light_energy` (1.8) and `bolt_light_floor` (0.4), `shafts.intensity` (0.3), per-phase `deck_dark` / `deck_shade_depth`.

## Sheet layout (`_sheet_cpu_base_vs_arm.jpg`, top to bottom)
1. F41#2 calm, building, break: base row, then arm row (captured before the shaft fix and bolt light; sky only).
2. F41#12 lantern_hollow day, glass_field, lantern_hollow night: base row, then arm row.
3. F41#8 three inventory and dialogue pairs: base row, then arm row.
4. Matrix: Glass Field Break base, Glass Field Break arm, forest Break arm.

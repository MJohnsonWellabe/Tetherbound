# F41#1 approach stands: what they show, and a proposal (LANE-BELOW6, 11 Nov 2026). NOT A CHANGE YET.

## What the two approach frames show today
- Both approach stands (`stormwood__dynamo__12__the_stormheart_tree`, `stormwood__landmark__dynamo_core`) seat the player at about tree-local (-23, -46): outside the trunk, 23 m west of the south entrance, facing the bark wall from 5 m. Manifest: player (-123.05, 111.14, 5423.95), camera forward (0.44, -0.21, 0.87); the tree stands at (-100, y, 5470).
- **The orange slab at the left is a real mesh, so it is a game defect, not a stand fault.** It is the entrance ramp (`stormheart_tree.gd add_approach` -> `_ramp("OuterWorksApproach", ...)`, a single 10 m-wide quad rising from the road at z 5350 to the 6 m deck). The stand is beside and below it and sees its underside: one double-sided quad with the bark texture stretched along 120 m, lit orange. From above (frame `s395h0` in the sheet) it is a pale planked ramp.
- The 8 Nov GPU approach frame stood under the deck looking in; today's stand is outside. I did not find which change moved it.

## Screening (CPU, heartwood ON; `_sheet_cpu_screen.jpg`)
`phase2_capture_locations.gd --biome=stormwood --subset=zz_no_match --spot=<id>@-100,<z>@0 --views=approach,close`, on the ramp's line south of the tree. Heading 0 looks north at the tree. Outdoor frames take about 5 minutes each on CPU, so only four were captured; a wandering wild Tanglevolt blocks three of them (random spawn).
- `s300h0 approach` (170 m south): the trunk base, buttress roots and the arched gate fill the upper half of the frame; the storm sky shows either side. This reads as a giant tree.
- `s350h0`, `s395h0` (120 m, 75 m): closer, the gate and the ramp; the trunk is cropped at the top.
- **No stand on the ground shows the crown and the core together.** The crown starts well above 100 m, so the gameplay camera only reaches it from several hundred metres; the core is inside the trunk and the gate is closed from outside.

## Proposal (two separate changes, neither made)
1. **Stand:** move the two approach views to the road at about (-100, 5300), heading 0. Subject in frame: the whole trunk base and gate against the storm sky. The crown needs a stand further out (try 5200 and 5100 on the GPU, seconds a frame there) or a camera pitch the gameplay camera does not use. In-game counterpart required beside it (rule: a stand fix lands with a game fix): item 2.
2. **Game:** give the entrance ramp a body. Side skirts down to the ground in the deck's plank material, or trestle posts from the installed deck-support pieces (`_deck_supports`), so its underside is never an orange sheet. Presentation only; the ramp's collision quad is pinned and stays as it is.

Next step if the coordinator agrees: the GPU lane screens `--spot=a@-100,5300@0 --spot=b@-100,5200@0 --spot=c@-100,5100@0` (approach view) on main with the heartwood landed, and I build item 2.

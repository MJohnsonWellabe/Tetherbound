# F05#7 "the land heals": blind verdict, round 5

**Result: FAIL.** The code-blind judge's answer to "does the land visibly heal, readable without being told?" was **NO**. F05#7 stays **PARTIAL**. The shared world key, relic and gate flags on both peers after reload are already evidenced on main. The missing part is the visible healing payoff.

## Frames

The frames are in this directory, rendered in engine through the production camera rig with the HUD on and the clock pinned to 13:00.
- **Tool:** `tools/capture_f05_heal.gd` at `65388a41`. It uses the same vantages as round 4 (`../heal/capture_heal.gd.txt`) and takes fewer frames of the fall.
- **Build:** main `32bd3307`, rendered locally with `xvfb` + opengl3 at 1280x720 (`capture.log`).
- **Staging (disclosed, as in round 4):** the chain up to the Warden and `legendary_freed` are set directly, and the player is placed at each vantage.
- **Heal report:** regrown 1717, regreened 2082 quads, lights killed 137, pylons toppled 29, herd returned 7, cables hidden 168.

## What the judge saw
- **Quarry (h01→h05) and approach (h03→h04).** The pylon and its cyan cable are removed. Grass, flowers, trees and light are identical, so the change reads as machinery disappearing and not as land healing.
- **Works slope (h08→h09).** A pale, hard-edged polygonal patch becomes a darker olive patch with the same hard polygonal edge. It reads as a texture swap. A thin grey pole remains where the beam stood.
- **Highfield (h02→h06).** No visible change. This vantage looks into the tree line, so the herd is out of frame.
- **Fall (h10–h139).** The judge wrote that the pylon "sinks straight down over about 3.5 s". **The frames do not support that.** In h101–h108 (0.5–4 s) the pylon stands upright and only its cable colour changes, from cyan to dark. By h119 (8 s) it is down and out of view. The staged creak and fall therefore happen between samples, falling away from this vantage behind the trainer. So the fall was **not captured** this round; it was not seen to sink. The next capture needs a side-on vantage (round 4's `capture_pylon_side`) and dense sampling from 3 s to 8 s. A large shelled creature wanders into the frame (h119 onward).
- **Herd close-up (h07).** Deer stand in a row along a fence, evenly spaced and facing the same way. They read as placed props. They are shoulder height or less against the 1.80 m trainer, and wolves in h04 are knee height.
- **Placeholder look.** The judge also flagged untextured white blocks on the left and a flat maroon slab in the pylon frames.

## Judge's ranked defects and whether the scene can fix them
1. **The land itself does not change.** The scene can fix this with ground/grass saturation, density and flower change between the before and after states, and with vantages that actually show the drained ground.
2. **The fall is not readable as an event from the player's vantage.** The judge's "sinks" reading is a sampling artefact, as above. Still, the frames never show the fall itself. Recapture it side-on at 3–8 s before judging the event.
3. **The herd is a lineup and the creatures are undersized.** Placement can be fixed in the scene: scatter them, vary facing, bring them in. Relative scale is a hard-rule issue: creatures must be taller than the trainer, and a fix grows the smaller side.

## Bar questions
- **(A) Key-art world:** not validly answered. The key art (`docs/reference/tetherbound-meadows-keyart.png`) was missing from this checkout, which is a partial clone with the large blobs skipped. The judge compared against other reference images instead. The file has since been restored for the next round.
- **(B) Same kind of game as Palworld:** **Yes.**

## Owner-lane follow-ups (not claimed here)
- **Herd scale:** the relative-scale hard rule belongs with Meadows core/X04.
- **Placeholder props:** the white untextured blocks and the flat maroon "Tether duty board" slab are real scene content in this build. The capture log shows no resource load failures, so this is not a checkout artefact. They belong to Meadows core.

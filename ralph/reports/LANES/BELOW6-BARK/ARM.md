# BELOW6-BARK: Cloudreach bark tone (F40#15)

Row: F40#15 (GPU High 5.54). Recorded defect on the aerie dusk vista: "orange-stick trees".

Cause: `_apply_tree_palette` in `scripts/world/cloudreach_world.gd` tints the tree family's orange bark texture with a pale grey, which leaves the orange at full strength.

Arm: `data/config/cloudreach_visual.json` `tree_bark_tone_1112` (OFF) swaps the three variant tints for darker cool ones (`#6f8088`, `#62747e`, `#74807c`), so trunks read as weathered brown. Overlay: `overlay.json`.

Scope: every Cloudreach tree changes, so judge F40#15 plus any Cloudreach rows with trees close to camera (the overlook frames have one in the arch).

CPU: `_sheet_before_after.jpg` (left base, right arm), aerie `vista_dusk`, seed 2042. Trunks go from saturated orange to brown; nothing else moves. The timber poles keep their orange; they are a different material and not in this arm.

Queue note: this is behind Stormraven r3, wake, overlook pane and overlook stands. Run it after those.

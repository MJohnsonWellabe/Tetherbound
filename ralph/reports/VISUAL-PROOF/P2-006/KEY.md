# P2-006 capture key (not for the judge)

Renderer: gl_compatibility, `--preset=Low --low-resolution=1920x1080` (Low/Compatibility). Forward+ crashes on render.yml (llvmpipe Vulkan, signal 11 after world attach; run 38154142724 on this item's candidate), so no High/Medium sheet exists here.

Command (only checkout_ref and --source-commit/--output differ):
`tools/phase2_capture_locations.gd -- --biome=meadows --subset=meadows__landmark__village --subset=meadows__landmark__grandpa_house --times=day,night --views=approach,close --seed=2042 --preset=Low --low-resolution=1920x1080`

| Sheet | A (left) = BEFORE | B (right) = AFTER |
|---|---|---|
| sheet-1-low-compat.jpg | 9e39d0086ee88998b8295747fc19f6603fe714f7 (main), run 38157814008, 8/8 frames | a7a4927ed93d468ea6b448da2a32faed3249dc48 (candidate), run 38156433591, 8/8 frames |

Not captured: Codex's supplementary 5–8 m stands (Grandpa, Mira, street, foliage targets). `phase2_capture_locations.gd` has no stand/target arguments, and the brief allows no new tools, so only the catalogue landmark views are here.

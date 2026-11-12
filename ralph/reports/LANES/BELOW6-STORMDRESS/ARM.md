STATUS: ready for GPU (High first). Supersedes BELOW6-SPLITWOOD (same flag, sent here with the banners as one arm to stay within two arms)
ROWS: F41#15 / F41#7 (Marrow's dialogue frames, 5.95 with his fix) and F41#1 Stormheart (6.81)
BRANCH: tb/below6 (code and config only, no import)
OVERLAY: ralph/reports/LANES/BELOW6-STORMDRESS/overlay.json (`built_detail.banner_cloth_1112`, `split_bark_finish.aged_heartwood_1112`)
FRAMES: CAPTURE.json (three sets, base and arm)

# ARM: Stormheart dressing the judges named: cloth banners and aged split wood (LANE-BELOW6, 12 Nov 2026)

## What the judges named (3/3 each)
- F41#1 (G-below6-stormheart-approach): "the interior banners are flat blue squares with a bolt glyph that read as UI decals".
- Marrow's dialogue frames (G-below6-marrow): "a placeholder blue slab at the left edge" (an ascent banner beside the deck) and "trunk colours: saturated orange on the left (one judge: near oxblood)".
- The old approach stand: "an orange untextured placeholder slab".
The orange is one surface in all three places: the split trunk's exposed inner wood.

## The arm (both flags OFF by default)
1. `banner_cloth_1112`: every Stormheart banner (eight on the ascent, eight on the deck lip) hangs in folds with its own shading, in a darker storm navy with a darker hem and a bolt half as thick; the lip banners alternate two sizes. Same rods, positions and count; no collider.
2. `aged_heartwood_1112`: the exposed-wood shader greys its orange atlas (weathering 0.75) under a pale heartwood tint. Shader parameter only.

## CPU check
- `_sheet_cpu_banners.jpg` (interior close frame, base above, banners on below): flat royal-blue squares with a thick bolt become folded navy cloth with a fine bolt, in two sizes. Still fairly saturated under the hollow's light.
- `_sheet_cpu_split_wood.jpg` (old approach stand, base left, aged wood right): the orange slab becomes muted grey-brown.
- Not captured on CPU: the two flags together, and Marrow's dialogue frames with either. No CPU judge batch.

## Expected
More than 0.5 on Marrow's two frames (two of the five things all three judges listed sit at the left edge of those frames) and on the split-facing frame; a smaller gain on F41#1's row, where the banners are in the two close frames only.

## Checks
`--only=stormheart`: 37 tests, 5082 assertions, 0 failed (banner code in, flags off).

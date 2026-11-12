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

## After the verdict (12 Nov): RIDE-ALONG, and the wood retuned
G-below6-stormdress (tb/item-scout-1108 4702206a): Marrow frames 5.14 -> 5.62 (+0.48, 3/3); split-facing frame 3.93 -> 4.40 (+0.47, 3/3); F41#1 row 6.57 -> 6.67 (+0.10, 2/3). Nothing loses; every gain is under 0.5, so it rides with the next Stormwood landing.
The judges and the GPU lane both caught the aged wood rendering **rose-mauve (hue about 332)**, not grey-brown. My "muted grey-brown" on CPU was an eyeball call; the CPU pixel hue was 348.
Retune (`aged_heartwood_1112`): weathering 1.0 (no orange atlas left) under a khaki tint #b0a25f that leans against Stormwood's violet light. Measured on the split-facing CPU frame (`_sheet_cpu_split_wood_retuned.jpg`): slab mean hue 35, saturation 0.39, value 0.42: a warm olive-brown. A less saturated tint (#ada273) measured hue 15 and was dropped. The GPU read about 16 degrees lower than CPU on the first setting, so the GPU hue should land near 20-35; **read the pixel hue on the GPU frame before it rides.** The banners are unchanged.

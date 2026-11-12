STATUS: ready for GPU (High first). Contains BELOW6-STORMDRESS (judged ride-along) plus the deck wood; queue this, not STORMDRESS again
ROWS: the Stormwood top-deck dialogue frames (F41#7, #11, #15, #20); Marrow's frames are 5.95 on main
BRANCH: tb/below6 (code and config only, no import)
OVERLAY: ralph/reports/LANES/BELOW6-STORMDECK/overlay.json (`built_detail.deck_wood_warm_1112`, `built_detail.banner_cloth_1112`, `split_bark_finish.aged_heartwood_1112`)
FRAMES: CAPTURE.json

# ARM: the Stormheart top deck in wood colours (LANE-BELOW6, 12 Nov 2026)

## What all three judges list on these frames (G-below6-marrow, G-below6-stormdress)
"Tiled pink-lilac planks"; "a placeholder blue slab at the left edge"; "a saturated orange trunk at the left" (one judge: near oxblood; on the first aged-wood try, "off-family pink").

## The arm (three flags, all OFF by default)
1. **`deck_wood_warm_1112` (new):** the cut-wood tint leans against Stormwood's violet light. Measured on the CPU dialogue frame (mean of two plank boxes): base hue 330, saturation 0.17 (pink-lilac); arm hue 24 and 29, saturation 0.27 and 0.30, value 0.6 (warm oak). It applies to every Stormheart deck, ramp and fascia that share the material; the interior hollow's decks are a different model and do not change (checked on the interior close frame).
2. **`banner_cloth_1112`:** judged in STORMDRESS, renders as intended (folded navy cloth).
3. **`aged_heartwood_1112`, retuned:** on the GPU the first setting rendered rose-mauve (hue 332). Now fully grey grain under a khaki tint; CPU split-facing frame: slab mean hue 35, saturation 0.39.

## CPU check
- `_sheet_cpu_deck_wood.jpg`: Marrow's dialogue frame, main left, deck wood on right. The deck goes from lilac to oak; nothing else changes (the sky differs between the two captures because of the time of the take, not the arm).
- `_sheet_cpu_split_wood_retuned.jpg`, `_sheet_cpu_banners.jpg`: the other two flags, as in STORMDRESS.
- The three flags have not been captured together on CPU. No CPU judge batch.

## Hue check asked of the GPU lane before judging
The CPU and GPU disagreed by about 16 degrees on the aged wood. Please read the mean hue of (a) the deck planks and (b) the trunk face at the left in the arm frames. Wanted: both between about 15 and 50. **If either is in the pink-magenta range (300-350), do not judge; tell me the number.**

## Expected
More than 0.5 on Marrow's two frames: STORMDRESS alone gave +0.48 there, and the planks are the largest surface in those frames.

## Checks
`--only=stormheart` with the banner code: 37 tests, 0 failed. The deck-wood change is one shader parameter behind a flag; the Stormheart set has not been re-run since.

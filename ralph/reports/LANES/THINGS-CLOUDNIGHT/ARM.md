# THINGS-CLOUDNIGHT: Cloudreach night, moonlit fill and a cast that is not self-lit (F40#0, F40#19, F40#21)

**Rows.** `G-rescore-f40-0-sample`: F40#0, F40#19, F40#21 at 5.98. Night, 3/3: "a uniform cobalt wash with a self-lit trainer, where a moon key and warm lamp pools should be".

**Cause.** Two settings. The landed night fill (`night_foreground_fill`) is a strong, saturated cobalt ambient (energy 3.4, #5c74bd), which tints everything one blue. And the night presets give every character an additive emission floor of 0.5 and the playable rim at full weight, so the trainer glows against the ground.

**Change** (flag `cloudreach_visual.json time_override_arms.night_moonlit_cast_1112`, OFF, layered after the fill; Cloudreach only). The fill keeps its energy and moves to a paler moonlit blue-grey (#7385ae), so stone and turf keep some of their own colour; the character emission floor goes 0.5 -> 0.15 and the playable rim 1.0 -> 0.3. Not darker overall: the darker night arms lost on 4 Nov. Config only.

**CPU** (`_sheet_night_off_vs_on_cpu.jpg`; left main, right arm; realm gate, night rain, approach and reverse): the trainer reads in natural tones lit like the ground; boulders and the arch are paler and less blue; the grass is no darker.

**Not in this arm.** A moon key light (earlier lanes found the night sun key does not reach the frame) and lamp pools (scene dressing).

**Ask.** Night pieces d*8+7 (clear) and d*8+8 (rain) at the sample stands, base vs arm, High. Day pieces cannot change (the arm only overrides night).

## Round 2 (13 Nov): cooler, darker, less saturated fill; cast cuts kept

**Round 1** (`G-things-cloudnight-941.md`): night clear on 9 stands +0.43 and F40#21 +0.38 (3/3 each; the emission floor cut stops the campfire trainer blowing out), night rain level, but the no-loss set (Three Bells, Windscar Beacon, Flight Aerie) lost −0.30, 0/3: "the paler fill turns the grass greener and reads as dim daytime". Judges' fix, 3/3: keep the emission and rim cuts, cool-tint the moonlit fill, darken and desaturate the night grass.

**Change** (`overlay_night_moonlit_cast_r2.json`, overlay only, night in Cloudreach only): the same flag ON, with three values replaced in the overlay:
- fill colour `#7385ae` (round 1, pale blue-grey) to `#5f76c6` (a cool blue, slightly lighter than main's `#5c74bd`);
- fill energy 3.4 to 2.8;
- night saturation 1.05 (round 1) to 0.78.
The cast cuts are unchanged from round 1: character emission floor 0.15, playable rim 0.3.

**CPU** (`_sheet_night_r2_cpu.jpg`, realm gate crag, night clear; top row a milder try at energy 3.0 / saturation 0.88, bottom row this arm): the grass is darker and reads blue-green under the sky instead of lit green; the path and stones keep their values. Mean frame colour 62, 77, 65 (milder) to 59, 72, 64 (this arm).

**Risk.** These fill values are close to `night_moon_grade`, which lost on CPU on 4 Nov as too dark. The difference here is the cast cuts and that the GPU judges asked for it.

**This is the approach's second round: if a stand loses again, park it.**

**Ask.** The round-1 pieces, base vs arm, High.

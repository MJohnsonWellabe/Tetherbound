# THINGS-CLOUDNIGHT: Cloudreach night, moonlit fill and a cast that is not self-lit (F40#0, F40#19, F40#21)

**Rows.** `G-rescore-f40-0-sample`: F40#0, F40#19, F40#21 at 5.98. Night, 3/3: "a uniform cobalt wash with a self-lit trainer, where a moon key and warm lamp pools should be".

**Cause.** Two settings. The landed night fill (`night_foreground_fill`) is a strong, saturated cobalt ambient (energy 3.4, #5c74bd), which tints everything one blue. And the night presets give every character an additive emission floor of 0.5 and the playable rim at full weight, so the trainer glows against the ground.

**Change** (flag `cloudreach_visual.json time_override_arms.night_moonlit_cast_1112`, OFF, layered after the fill; Cloudreach only). The fill keeps its energy and moves to a paler moonlit blue-grey (#7385ae), so stone and turf keep some of their own colour; the character emission floor goes 0.5 -> 0.15 and the playable rim 1.0 -> 0.3. Not darker overall: the darker night arms lost on 4 Nov. Config only.

**CPU** (`_sheet_night_off_vs_on_cpu.jpg`; left main, right arm; realm gate, night rain, approach and reverse): the trainer reads in natural tones lit like the ground; boulders and the arch are paler and less blue; the grass is no darker.

**Not in this arm.** A moon key light (earlier lanes found the night sun key does not reach the frame) and lamp pools (scene dressing).

**Ask.** Night pieces d*8+7 (clear) and d*8+8 (rain) at the sample stands, base vs arm, High. Day pieces cannot change (the arm only overrides night).

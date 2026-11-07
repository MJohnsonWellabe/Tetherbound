STATUS: land
BRANCH: tb/item-f38-33  HEAD: the commit that adds this file

Depends on tb/item-capture-fixes (002f4dca; branched from it): the catch tool holds the broke-free card and its step-back to the `06-breakout` shot.

- Row: F38#33 P2-061 catch result hierarchy (Meadows). Live CPU 7.11 (VIS-MEADOWS, old tool where `06-breakout` showed no card) / GPU 5.76.
- Round `ralph/reports/LANES/LANE-KIT/qj/F38-33-91a1dca4cb6b-11072025/`: base (fixed tool) **6.53** -> candidate **7.98** CPU mapped (+1.45). Raw 5.5/5.6/5.8 -> 6.6/6.3/6.6. r 0.91, RMSE 0.49. Above the top anchor (7.35), so extrapolated.
- Flag ON: `data/config/hud.json:catch_card.step_back_on_break` (`_why_on_step_back_on_break`). The broke-free card steps the fight cards back for its own hold; combat_hud.gd restores each one after.
- Caveat for the GPU re-judge: Meadows catches are not pinned to the seed, so the two sides caught at different spots. The base side's 08/09 frames carried a large translucent Terrapup in the foreground, which all three judges marked down. Part of the +1.45 is that scene difference. All three judges also credit the cleared cards on the break frame. A pinned Meadows catch (as VIS-CLOUDREACH/VIS-TIDEWAKE did for theirs) would make this A/B fair.
- Tests flipped: none. No test references `step_back_on_break` (grep tests/ and scripts/).
- Files: hud.json, this READY, the qj verdict dir.
- Left OFF: `catch_card.clear_on_release_1107` (NEAR6-MS, F38#14), not this row.
- Judges' remaining asks:
  - The defect is PARTIAL on all three: the caught individual is not singled out.
    - Frame 2 is a brown dissolve burst behind the banner.
    - Frame 3 has another body half behind the banner.
  - The "Traits:" line starts against the card's left border.
  - Remove the translucent companion ghost during the result.
- Next idea: pin the Meadows catch wild from `--seed` (tool). The translucent companion during the resolve camera is a creature/camera presentation item.
- Earlier attempt (recorded): a first round with a half-hold (card timer only) restored the cards mid-hold, and its candidate failed sequence B 6/6. The focus-hold commit 002f4dca fixed that.

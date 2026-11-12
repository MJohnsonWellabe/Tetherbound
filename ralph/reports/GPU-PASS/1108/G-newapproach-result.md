# G-newapproach-result: exploration HUD stands down under the loss card (F41#16)

Judged from the lane's **CPU** sheet, because the change is HUD-only (coordinator's ruling):
- **Sheet:** `tb/newapproach` `LANES/NEWAPPROACH-RESULT/_sheet_loss_cpu_1080.jpg`, 1920x1080, Compatibility, seed 2042.
- **Frames:** the Meadows south-bridge grunt fight, resolved lost, frames `l05` and `99-after`. They stand in for the Hollows row, which did not lose on CPU.
- **Base:** flag off.
- **Arm:** `overlay_result_focus.json` (`hud.json result_focus` on, loss card at 34 px with a 340 px half width).

## Pre-judge check
I looked at the sheet directly. In the arm frames the card is large and stands alone. The objective card, minimap, quickbar, hint legend and "Challenge Tether Grunt" prompt are gone; the clock, health and food remain. The arm is in frame.

## Judged
Batch `G-res`:
- Three code-blind judges and the standard prompt. Each side is the two frames stacked at 1280x720 each.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.2132, intercept −0.1641, r 0.840, anchor RMSE 0.625. No warnings.

| Row | Base | Arm | Gain | Judges preferring arm | Defect on arm |
|---|---|---|---|---|---|
| F41#16 (loss card, Meadows stand-in, CPU) | 5.34 (raw 4.2, 4.6, 4.8) | **7.44** (raw 5.9, 6.3, 6.6; mapped 6.99, 7.48, 7.84) | **+2.10** | 3/3 | FIXED 1, PARTIAL 2 |

On the base side, the defect is PRESENT for 2 judges and PARTIAL for 1.

## What still separates it from 7.5
All three judges name the same remaining gaps:
1. **The downed creature stands upright and alert in both frames**, so only the text says it lost. A fainted pose would fix this.
2. **The green 100/100 bar still reads as "healthy and ready".** A downed or greyed party or HP state would fix this.
3. Two judges add: **no controller prompt for what to do next**, and in the top frame the card covers the creature's head.

## Verdict
- **SHIP.** +2.10 with 3/3 judges.
- **Does not close.** The arm is at 7.44, below 7.5. These are CPU frames of a stand-in fight, and a criterion closes only on GPU High and Medium frames of the row's own frames.
- **Near the bar.** Under the 25 Oct close-out exception it is a candidate to push over 7.5 with the small fixes above: a downed pose, downed bars and a next-step prompt. After that, re-judge on GPU frames of `hollows_alpha-99-after` with a real loss; per the lane's own note, if no card is on screen, report rather than judge.

# G-newapproach-t2-bars: current strength bars on the swim badge (CARD:T2, F13#5), CPU, HUD-only

Judged from the lane's **CPU** sheets (HUD-only, per the coordinator), at `tb/newapproach` 5f216f16e:
- `NEWAPPROACH-T2B/_sheet_bars_cpu_1080.jpg`: top row base, bottom row arm; across-day, away-day and away-night.
- `_badge_crop_base_vs_bars.jpg`: the badge at full size.

**Change:** `water_current_cue.gd` `strength_marks` (`overlay_bars.json`). Three bars on a plate behind the arrow; one lights at 0, two at 0.6 and three at 1.2 m/s.

**Limit:** every view is on a 0.35 m/s lane, so only the one-bar state was judged.

## Pre-judge check
I looked at the sheet directly. On all three arm views the plate and three bars (one lit) sit beside the arrow, and the base shows the arrow only. Each side was built as the three views plus that side's half of the badge crop at full size, so the bars are judged at both gameplay scale and full size.

## Judged
Batch `G-bars`:
- Three code-blind judges and the standard prompt, with a 7-inch UI brief.
- Recorded defects: direction not readable at a glance; nothing shows how strong the current is.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.0683, intercept 0.3621, r 0.840, anchor RMSE 0.625. No warnings.
- **Harness note:** judge b's hand-back left out its JSON block. Its scores were taken from the final verdict text in its own transcript, which matches the table in its hand-back.

| Side | Mapped | Raw (per judge) | Mapped (per judge) |
|---|---|---|---|
| Base (arrow only) | 6.59 | 5.9, 6.2, 5.4 | not recorded |
| Arm (arrow + strength bars) | **7.16** | 6.4, 6.6, 6.1 | 7.20, 7.41, 6.88 |

**Gain +0.57. All three judges preferred the arm (3/3).**

Defect calls for strength:

| Side | Calls |
|---|---|
| Arm | PARTIAL 3/3 |
| Base | PRESENT 1, PARTIAL 2 |

Two judges counted the cyan arc already on main as a vague strength hint.

## What the judges saw
- **The bars are a real strength cue,** but at gameplay scale they are "tiny", "faint grey on dark navy" and "only read clearly in the full-size crop".
- **All three ask for the same fix:** a larger badge, with a high-contrast cyan or gold fill on the lit bars.
- **Other notes:** the "Current" label adds clutter, the night water is too bright, and the hotbar is close to invisible on bright water.

## Verdict
- **SHIP.** The arm gains +0.57 with 3/3 judges preferring it, which is above the 0.5 standalone line.
- **Does not close.** The arm is at 7.16 on CPU, below 7.5, and a close needs GPU High and Medium frames.
- **Near-bar candidate.** Under the 25 Oct close-out exception, the judges' fix should go next: lit bars in high-contrast cyan or gold and a slightly larger badge.
- **Re-capture:** include a lane of 0.6 m/s or more, so the two-bar and three-bar states are also seen.

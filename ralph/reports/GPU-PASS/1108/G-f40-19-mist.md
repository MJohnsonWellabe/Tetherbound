# G-f40-19-mist: Cloudreach rain, slate sky plus low gate mist (F40#19), with the sky-only arm re-judged

Frames: `tb/gpu-frames-1108`, High, 4 `realm_gate_crag` day-rain views.
- **Live:** main 90886c306, the same frames as G-f40-19-rain.
- **Mist arm (b496c4fef):** live plus `world_look.gd`, `cloudreach_weather.gd` and `cloudreach_visual.json` at tb/item-f40-19-rain b6fc71868 (mist ceiling seated; fog_height_above_ground_m 0.8, fog_height_density 1.1), plus `overlay_rain_storm_sky.json`.
- **Sky-only arm:** the G-f40-19-rain arm frames (563c847c6), re-judged in this batch.

## Pre-judge render check
The mist is in frame, and it is heavy:

| Measure | Change on the mist arm |
|---|---|
| Pixels differing by more than 30 levels | 10–31% |
| Mean luma | +8 to +14 |
| Lower-third contrast (std) | drops on 3 of 4 views (26.7→20.3, 28.1→20.9, 28.8→23.6) |

This matches the GPU lane's flag that the mist is near-opaque at ground level.

## Judged
Batch `G-mist`:
- Three code-blind judges and the standard prompt.
- A **hand-written Cloudreach brief**, which corrects the Stormwood mislabel in G-f40-19-rain.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.0835, intercept 0.1933, r 0.800, anchor RMSE 0.692. No warnings.

| Pair | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F40#19 live vs **sky + mist** | 6.22 (raw 5.6, 6.1, 5.0) | 5.36 (raw 4.6, 5.3, 4.4) | **−0.86** | 0/3 |
| F40#19 live vs **sky only** | 6.22 (raw 5.6, 6.1, 5.0) | 6.66 (raw 6.0, 6.4, 5.5) | **+0.44** | 3/3 |

## What the judges saw
- **Mist:** all three describe a grey-teal veil that covers everything, including the ground at the trainer's feet. Their words: "reads as a fog bug, not rain atmosphere", "the frames look flooded or underwater", "fog eating the world, not depth". Values collapse to one mid-tone and the distant islands dissolve.
- **Sky only:** all three call it a more believable overcast storm that keeps the value range and depth. It is still too brightly lit, with no wet sheen on the stone.
- **Live:** reads as "a sunny day with rain streaks pasted over it".
- **All three, both arms:** the rain streaks are thick, uniform, flat white bars that look like a screen overlay.

## The mist loses; does the sky-only change win on its own?
**Yes, on the ship rule: +0.44, with 3/3 judges preferring it.**

This **reverses G-f40-19-rain** (−0.16, 0/3). That batch's brief wrongly named the biome as Stormwood, and two judges marked both sides "off-biome". With the correct Cloudreach brief, the overcast sky is clearly preferred. This batch supersedes the earlier verdict.

**Owner rule (25 Oct):** a change gaining under 0.5 should not land alone. At +0.44 the sky-only arm is just under that line, so whether it lands alone is the coordinator's call.

## Verdict
- **Sky + mist: DO NOT SHIP** (−0.86, 0/3). The mist floods the foreground.
- **Sky only: passes the ship rule** (+0.44, 3/3). It is just under the 0.5 standalone threshold. All three judges name the bigger swing it could ride with: a rain pass with thinner, varied streaks that fade with depth, a cooler and dimmer storm grade, wet sheen on the stone, and fog limited to the distance.
- **Closes:** none. Best is 6.66.

# G-f40-19-rain: Cloudreach rain storm sky (F40#19), sky only

Frames: `tb/gpu-frames-1108` 563c847c, High, 4 views of `realm_gate_crag` in day rain.
- **Live:** main 90886c306.
- **Arm:** live plus `world_look.gd`, `cloudreach_weather.gd` and `cloudreach_visual.json` at tb/item-f40-19-rain 0b9defd35, plus `ITEM-F40-19/overlay_rain_storm_sky.json` (`weather_arms.rain_storm_sky` on).
- **Gate mist:** did not render (the GPU lane measured ground-level absdiff 1.3–1.7), so this is judged as a sky-only change, as asked.

## Pre-judge render check
- **Approach, detail and gameplay views:** 3–6% of pixels change. The top-fifth luma moves by 2–3 levels.
- **Reverse view:** 14% of pixels change.
- The sky change is in frame. It is small, because the sky fills only about 11% of each frame.

## Judged
Batch `G-fograin` (fit in `G-storm-fog-scoped-r2.md`). This is a confirming batch.

| Row | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F40#19 | 6.30 (raw 5.9, 5.5, 5.4) | 6.14 (raw 5.6, 5.5, 5.3) | **−0.16** | 0/3 (1 tie) |

**Brief error (mine):** the set's brief named the biome as Stormwood. The batch builder fell back to Stormwood because F40#19 is missing from the item job table. Two judges marked both sides down as "off-biome for Stormwood". This affects both sides equally, so the paired result stands. The absolute scores are probably depressed, though, and should not be used as F40#19's baseline. Future Cloudreach sets get a hand-written brief.

## What the judges saw
- **Arm:** one judge says the sky in the reverse view is "flatter and greyer and the fog washes out the depth".
- **Otherwise:** the two sides are nearly identical.
- **Both sides:** the heavy rain streaks and the chunky rubble causeway are what the judges hold against the scene.

## Verdict
**DO NOT SHIP.** The arm scores −0.16 and no judge preferred it. A slate overcast alone doesn't help the scene, and the gate mist, which was the larger half of the idea, never rendered. Fix the mist so it is visible on Forward+ High, then re-capture before judging again.

# G-storm-light-a2: HELD, not judged (the arm may not have applied)

Frames: `tb/gpu-frames-1108` bc21dff4. Live is main 52a633598. The arm is live plus `ITEM-STORM-LIGHT/overlay_storm_key_a2.json` at 17ccc297c: `storm_light` on with `environment.exposure` 1.5, `height_fog` untouched (false). Blank-frame receipts read 0 of 46 on both sides.

## Pre-judge render check (lesson from the void G-glass-sink-lip)

| Row | Frame | Pixels differing by more than 30 levels | Mean luma, live → arm |
|---|---|---|---|
| F41#2 | struck_sentinel ×3 | 1.3%, 0.7%, 4.6% | 80→80, 73→73, 73→66 |
| F41#4 | lantern_pools, crown_overlook, fallen_giant | 2.6%, 5.5%, 3.7% | 73→73, 77→76, 56→56 |
| F41#5 | struck_sentinel, crown_overlook, crown_heartstone | 3.8%, 5.5%, 3.2% | 66→66, 77→76, 84→83 |
| F41#12 | lantern_hollow day, glass_field, lantern_hollow night | 5.1%, 4.0%, 5.7% | 62→61, 70→71, 60→60 |
| F41#15 | captain_marrow dialogue | **0.0%** (bit-identical) | 111→111 |
| F41#15 / #7 | captain_marrow dynamo | 26.1% | 112→112 |
| F41#15 | officer_nysa | 4.9% | 74→74 |
| F41#17 | crown_arch close | 3.8% | 69→69 |

These results are not consistent with the arm having applied:
- **Brightness:** mean luma is unchanged on every frame. Raising `exposure` to 1.5 should brighten every frame; in arm A (`G-storm-light-a`) the judges saw a clear grade change between sides on the same stands.
- **Pixel changes:** they are at the rain and animation noise level (1–6%).
- **The Marrow dialogue frame:** it is bit-identical. With `storm_light` on, its rim light should touch every lit body.
- **The one large change:** the Marrow dynamo frame, at 26% with unchanged luma, looks like staging or animation, not a grade.

Possible causes, not checked:
- `light_pass_1101` already sets `rig.environment.exposure` 1.42 and may win the merge over `storm_light.environment`.
- The overlay path may not have been applied to the imported tree.

**Ask for the GPU lane:** confirm the arm tree's `stormwood_look.json` has `storm_light.enabled = true` and the exposure value, and that the in-game exposure actually changed (the capture log or `graphics_capture` record should show it).

I will judge this section, or a re-capture, once the arm is confirmed in frame.

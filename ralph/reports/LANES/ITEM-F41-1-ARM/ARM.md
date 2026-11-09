# F41#1 Stormheart finale banners: config-only arm

**Overlay:** `overlay_banners_muted.json`, a deep merge into `data/config/stormheart_presentation.json`.
**Capture:** F41#1 frames (`stormwood__dynamo__12__the_stormheart_tree__day__approach`, `__day__close`, `stormwood__landmark__dynamo_core__day__close`), live main vs arm, High.

## Defect (NEXT-LOWEST #8, GPU 5.78)

Four identical royal-blue banners hang at equal spacing. In the GPU frames they read as saturated cobalt flags with a white bolt.

## What config can and cannot do

The banners in view are the OuterWorks **lip banners** (`stormheart_tree.gd` `_lip_banners`).

The code fixes three things:
- **Spacing:** every lip banner is spaced evenly (`angle = TAU * (index + phase) / count`).
- **Size:** every one gets the same `drop_scale`.
- **Ascent banners:** the eight ascent banners (`_hanging_banner` in the built-detail pass) also have fixed positions.

Config can change:
- the colour and trim, through `built_detail.banner_colour` and `banner_trim`, shared by both banner sets;
- the lip banners' `count`, `phase`, `radius_m` and `drop_scale` (one value for all of them).

So this arm does what config allows:

| Key | Live | Arm | Why |
|---|---|---|---|
| `built_detail.banner_colour` | `#183e65` (renders as royal blue) | `#34475c` | Muted slate storm blue: lower saturation, a little more value so the cloth still separates from the dark trunk wall |
| `built_detail.banner_trim` | `#d5b466` | `#b49a62` | Dulled brass, so the trim stops reading as new paint |
| `hero_interior.lip_banners.count` | 8 | 5 | Fewer in any one view (2–3 instead of 4), so the row stops reading as a repeated pattern |
| `hero_interior.lip_banners.phase` | 0.75 | 0.6 | Shifts the five so one does not sit centred behind the ascent path in the approach frame |

No red or oxblood: both colours are blue-grey and brass.

## Not done: needs code (for the build lane, if this arm gains)

- **Two sizes:** a per-index drop scale, for example `lip_banners.drop_scales: [0.5, 0.35]` cycled by index.
- **Uneven spacing:** a per-index angle jitter, for example `lip_banners.angle_jitter_deg: [0, 9, -6, 4, -11]`.

Both would be a few lines in `_lip_banners` behind new keys, defaulting to today's values.

The other F41#1 defects stay out of scope here:
- the flat white polyline lightning (code);
- no crown or core in view (new art, all three judges).

## Check

No CPU capture was run for this arm: Forward+ on lavapipe crashes (`LAVAPIPE.md`), and the Stormheart interior is only judged on GPU. The change is colour and count only, with no geometry or collider change.

# Grass grounding diagnostic — GROUNDING01

Evidence sources: the three diagnostic manifests under shots/diagnostics/grass-grounding-*/manifest.json, their wrapper results under .artifacts/broad-visual-0910/runs/, and the first Meadows parse-failure wrapper result.

## Capture scope

The evidence contains four ordinary production-camera views:

- Meadows — Band 1 Lower Meadows, The South Bridge, day.
- Stormwood — Dynamo, The Glass Field, day.
- Water — First Shore Welcome Beacon, day.
- Water — First Shore Horizon Stones, day.

All successful wrappers exited 0 with no wrapper errors. The captures used the production scene and ordinary gameplay HUD, a real trainer, debug catalogue travel, and an audit-only frozen day/night clock. The manifests explicitly disclose that this is diagnostic evidence and not campaign proof.

The diagnostic’s terrain comparison spacing is 2.0 m for Meadows and Stormwood and 1.0 m for Water. The runtime grass-field logs agree: Meadows/Stormwood use a 2.0 m vertex spacing; Water uses 1.0 m. Samples are placed around the nearest terrain texel and include separate seam_x and seam_z probes at region boundaries.

## Eligible local samples

Signed counts are reported as negative below -5 cm / -20 cm and positive over +5 cm / +20 cm. They apply only to samples that pass the local height/control eligibility mask. They do not count every rendered tuft.

| View | Eligible local | median abs | p90 abs | p99 abs | negative <-5/-20 cm | positive >5/>20 cm |
|---|---:|---:|---:|---:|---:|---:|
| Meadows South Bridge | 461 | 0.0811 m | 0.3355 m | 2.4085 m | 157 / 56 | 151 / 41 |
| Stormwood Glass Field | 507 | 0.0770 m | 0.1714 m | 0.2266 m | 214 / 18 | 126 / 4 |
| Water Welcome Beacon | 381 | 0.0486 m | 0.1882 m | 0.3590 m | 89 / 18 | 101 / 14 |
| Water Horizon Stones | 488 | 0.0814 m | 0.1196 m | 0.2079 m | 158 / 2 | 169 / 3 |

The Meadows South Bridge local p99 is the largest of these ordinary views. That is a measured diagnostic residual, not a visual acceptance verdict.

## Separate seam samples

Seams are reported separately from local samples because they intentionally probe region boundaries. They are not merged into the local statistics.

| View | Seam count | median abs | p90 abs | p99 abs | negative <-5/-20 cm | positive >5/>20 cm |
|---|---:|---:|---:|---:|---:|---:|
| Meadows South Bridge | 24 | 0.0243 m | 0.1440 m | 0.2641 m | 1 / 0 | 9 / 1 |
| Stormwood Glass Field | 24 | 0.0517 m | 0.1804 m | 0.1853 m | 8 / 0 | 5 / 0 |
| Water Welcome Beacon | 24 | 0.0346 m | 0.1608 m | 0.1616 m | 8 / 0 | 4 / 0 |
| Water Horizon Stones | 16 | 0.0404 m | 0.0632 m | 0.0769 m | 2 / 0 | 4 / 0 |

## First Meadows failure and clean rerun

The first Meadows wrapper ran from 07:59:31 to 07:59:39 UTC and failed before capture because the probe script could not infer the types of seam_x and seam_z. The failure was a probe parse error, not a grounding measurement or game-run result.

The probe was corrected by using roundf for the seam coordinate variant, then the second Meadows wrapper completed cleanly from 07:59:53 to 08:01:20 UTC: exit code 0, no wrapper errors, one of one frame captured. Its wrapper logged spacing 2.00, 531 requested samples, 515 ray hits, and maximum absolute differences of 2.6441 m against interpolated terrain and 2.6280 m against collision.

## What this measures

The current grass shader samples the nearest terrain texel height. Terrain3D’s height query interpolates between surrounding terrain data, while the comparison ray uses the runtime terrain collision surface. Those are three related but different height sources. Collision is useful evidence for physical contact, but it is not the renderer’s exact clipmap surface.

Eligibility is limited to valid height samples and the control masks that permit grass at that point. The diagnostic therefore says how the selected eligible samples compare; it does not claim every rendered tuft was sampled, that any suppression policy exists, or that the grass is visually grounded everywhere.

A field existing in the manifest and runtime log proves the diagnostic path and field are present. It does not mean the grass-grounding goal is met, and these captures do not constitute final visual acceptance. A shader candidate is being prepared separately and is outside this report.

# ARM: ground_wet_path_1112 (Cloudreach wet ground in rain, duller frayed trail), LANE-PLACES, 12 Nov 2026

Branch `tb/places`. Ships OFF; `overlay.json` turns it ON. Rows: F40#0 (half its 384 frames are rain; trails are in most stands), F40#19, F40#1.

## Defects (judges b and c, `G-places-gatepaving`, both sides)
"The orange path is too saturated and its edges are not blended into the grass"; "rain has no wet darkening or sheen".

## Cause
Rain wetness (`ground_wetness`) is pushed only to the Meadows terrain material; no Cloudreach ground shader reads it. The trail is a fixed tint over an orange dirt texture with a narrow, smooth shoulder.

## Change (one shader global `cloudreach_ground_1112`, set by `cloudreach_weather.gd`; read by the turf include, trail and worn-ground shaders)
- In rain: turf about a quarter darker, soil about a third darker, both with a sheen (roughness 0.98 → 0.72 turf, 0.4 soil).
- Always: trail soil pulled halfway to a duller earth, shoulder feathered wider with a frayed edge.
- All zero when off. Cloudreach scene only.

## CPU proof (`_sheet_cpu_base_vs_arm.jpg`: realm gate approach; main day clear, arm day clear, arm day rain)
Clear: the trail is a dull earth with a softer edge instead of an orange stripe. Rain: ground and trail are visibly darker and wet. No shader errors in the capture log. The rain base frame was not captured on CPU (the GPU captures both sides).

## Not in this arm
F40#1's own defect (lawn where ledges should be) needs terrain; ground colour variation and layered fog are not built (earlier Cloudreach attempts at both were flat or lost).

## Reject if
The wet ground reads as mud or near-black, the sheen blows out, or the trail disappears into the grass.

## Round 2 (12 Nov): after the split verdict; please re-judge
`G-places-wetpath` (49169c37): clear controls +0.60 and +0.57, gate rain +0.65 (3/3 each), summit day rain +0.08; **summit night rain −0.34** (wet trail "a black, char-like smear"), **overlook rain −0.09** (grey trail lost in wet grass); F40#1 level. Judges' target, 3/3: one mid-value, desaturated earth brown that holds by day, in rain and at night, with soft edges.
Changes, same flag and overlay:
- Wet soil darkens about half as far and keeps its warm hue (multiplied by 0.88, 0.82, 0.72 instead of a flat 0.66).
- The rain darkening on turf and soil fades out as the clock's own sky darkens (`wet_night_band`), so night takes none.
- The clear-weather trail tone and edge, which won, are unchanged.
**Not re-captured on CPU.** The shader edit is two colour multiplies and the unit tests pass, but no frame of round 2 exists yet; treat the GPU pre-check as the first look.
Frames: the four rain pieces (gate 4, summit 84 and 88, overlook 92) plus one clear control (3). Night (88) and overlook (92) are the no-loss checks. Judges also noted a violet blotch under the trainer on clear night (2/3); not addressed here.

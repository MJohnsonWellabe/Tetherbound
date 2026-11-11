# FLOOR2-DAWNRAIN: the dawn horizon band and a storm grade for Tidewake rain (F39#30; also F13#5, F39#31 rain views)

**Ask:** GPU High, base vs arm, `CAPTURE.json`. Config only: one overlay on `tidewake_look.json`, no code, no assets.

## What the GPU judges asked (G-floor2-sand-ripple-relief, F39#30 5.85 → 6.16)
1. Dawn: "a hard black horizon band where water meets sand, and a blown-out sun disc on the ground line" (3/3).
2. Rain: "opaque white streaks under a fully lit noon sky and no storm grade".

## Cause
- **Dawn band.** The band is the opaque deep sea beyond the shallows. At a 9° sun a level surface gets almost no direct light, and dawn's fog is thin (`fog_density` 0.0004), so 300–600 m of near-black water sits unhazed under a bright warm sky. The sun's glare on that black strip is the "blown-out disc on the ground line".
- **Rain.** `rain_grade_candidate` (ON) only darkens the sky gradient and takes the sun to 0.32. In rain the sky is almost all cloud deck, which that grade never touches, so the deck stays white cumulus with blue gaps over bright, saturated sand and sea. VIS-TIDEWAKE's r23 and r24 retuned the gradient and the sun and were flat; r24's note names the cloud colours as the untried lever. The far rain layer draws 0.12 m streaks at 0.6 alpha.

## Change (overlay `overlay_dawn_haze_storm.json`)
| Key | Live | Arm |
|---|---|---|
| `lighting_candidate.times.dawn.environment.fog_density` | 0.0004 | 0.004 |
| `rain_grade_candidate.sun.energy_mult` | 0.32 | 0.18 |
| `rain_grade_candidate.sky.cloud_lit` / `cloud_shade` / `cloud_base` | unset (white cumulus) | `#a2adb4` / `#515d66` / `#3c4750` |
| `rain_grade_candidate.sky.cloud_coverage` / `cloud_sharpness` | unset | 0.88 / 0.5 |
| `rain_grade_candidate.environment.ambient_energy_mult` | 0.75 | 0.62 |
| `rain_grade_candidate.environment.ambient_colour` | unset | `#8494a0` |
| `rain_grade_candidate.environment.adjustment_saturation_mult` | unset | 0.72 |
| `rain_veil_candidate.streak_size_m` / `colour` | [0.12, 5.0] / `#d4dde699` | [0.07, 5.0] / `#c3ced84d` |

Every key is one the look code already reads (`world_look.gd _layer_weather`, `tidewake_world_look.gd set_weather`). Rain keys apply in Tidewake rain only; the dawn key at Tidewake dawn only.

## CPU proof (llvmpipe, Compatibility, 1920×1080)
`_sheet_cpu_base_vs_arm.jpg`: lesson-dawn, shore-rain, lesson-rain, veilfall-vista-rain; base above, arm below. Two looks; this is the second.
- **Dawn:** the black band is gone; the far sea fades into the warm horizon and the sun's glare sits in haze. The far dune becomes a soft silhouette.
- **Rain:** a closed grey deck with cloud structure, a dim cool scene, muted sea, finer streaks. It reads as a storm.
- The first look (fog 0.0022; deck at 0.95 coverage, sharpness 0.35) left a brown smear where the band was and a featureless flat-grey sky; both were adjusted.
- Base in these captures predates the sand ripple landing, so the dawn sand still shows the old stripes on both sides.
- Not judged on CPU.

## Risks
- **Veilfall in rain loses contrast** (right-hand column): the mountain is still readable but flatter. That is the trade VIS-TIDEWAKE's notes warned about; F39#31's rain view is in the capture as a control.
- Dawn haze also softens everything past about 200 m at dawn, including far islands and Veilfall.
- CPU has no glow or Forward+ exposure; the GPU dawn glare and the rain's brightness may differ from these frames.
- The near rain ring's streaks come from the shared weather preset (all biomes) and are not touched; if the judges' "opaque white streaks" are those, this arm only fixes the far layer.

## Tests
- Not run yet for this overlay (the single Godot slot was busy): `test_tidewake_look_profile` on and off. Result goes in NOTE.md. A test that pins `rain_grade_candidate.sun.energy_mult` 0.32 or dawn `fog_density` would need the coordinator's update on landing.

## Expected gain
More than 0.5 on the dawn and rain frames of F39#30 (two of its weakest), about +0.3 on the row.

# Stormwood Surge phase readability (F10 / S2): visual evidence

Work order: ACCEPTANCE §6.1 F10 / S2. Calm, Building, Break and Fading must be nameable **without HUD phase text**, lightning keeps its 1.2 s / 3 m telegraph, and the restored sky must contrast with the storm. Owning specs: WORLD §5.2, ART_DIRECTION §3.3 and §4 (Stormwood row), AUDIO §4.3 (audio not in scope). The blind-judge result for round 1 is in `JUDGE.md`. This README describes the **round-2** state, after the code review (B1, S1–S3) and judge findings J1–J3.

## How these frames were made

- **Tool:** `tools/capture_stormwood_surge_phases.gd` (its header gives the command line and groups).
- **Camera:** the production `CameraRig/Camera3D` following the real Player. There is no survey or free camera. Placement is `Game.debug_teleport_to` plus the Player transform at the stand, and the rig then settles on its own. Every HUD `CanvasLayer` is hidden, including the Surge "⚡ Phase" glyph.
- **Stands:**
  - Strips, night, telegraph, flash and aftermath: Cinder Verge marked clearing `verge_glass_01` at (-604, 772), facing the Verge Rod Station.
  - Views: the lane tool's matrix stands, the rod line from 30 m and Deepwood/Lantern Hollow (-470, 3905).
- **Staged state:** recorded per frame in the `frames_*.json` files.
  - The clock is pinned to `day`, or to art.json `night` (hour 23) for the night frames.
  - The surge clock is pinned to `<phase start> + 2 s` and then runs free.
  - In *after* runs, `settle_presentation()` is called after each pin, which skips the 6 s cross-fade the pin itself triggers.
  - Player health is restored between Break frames.
  - Aftermath and views set `stormwood:long_storm_ended`.
  - `Engine.max_physics_steps_per_frame` is raised (ticks stay 1/60 s), because software GL renders this world at well under 1 fps.
- **Before vs after:**
  - *Before* is `origin/main` at bcf46366c, which has none of this lane's code.
  - The day strips, telegraph and aftermath *before* frames are from round 1. That code is unchanged, so they were not re-rendered.
  - *Before* night frames (`before/night_*.jpg`, `frames_before_night.json`) were rendered in round 2, with main's three lane files restored temporarily.
- **Frame records:**
  - *After* frames are from the round-2 code. The main run is in `after/frames_after.json`.
  - The Break strip, telegraph and flash were re-rendered after the telegraph fill-colour fix; their records are in `after/frames_after_break_r2.json`, and the Break records in `frames_after.json` are superseded.
  - Night frames were re-rendered after the night sun-cut fix; their records are in `after/frames_after_night_r2.json`.

## Round 4 (final): `sheet_round4.jpg`

Ten 640×360 frames. The records are in `after/frames_after_r4.json`, and every frame was looked at. Camera and staging are as described above, and the telegraph and upwind frames are both day Break.

| Frame | What it shows |
|---|---|
| `after/r4_day_calm.jpg` | Flat neutral-grey overcast with drizzle. |
| `after/r4_day_building.jpg` | Dark olive ceiling over dimmed, copper-dulled ground. |
| `after/r4_day_break.jpg` | Violet storm sky, lighter than before, so it reads as a storm afternoon. The ground is darker and the rain slanted and heavy. |
| `after/r4_day_fading.jpg` | Warm tan ceiling breaking up onto blue sky. |
| `after/r4_night_calm.jpg` | Neutral grey ceiling. |
| `after/r4_night_building.jpg` | Near-black olive ceiling. |
| `after/r4_night_break.jpg` | Violet ceiling over a lit lavender horizon. |
| `after/r4_night_fading.jpg` | Warm brown ceiling. The four night frames separate by hue and value at thumbnail size, and the trainer reads in each. |
| `after/r4_telegraph.jpg` | Strike telegraph in the game hazard magenta (combat.json `telegraph.colour`). The rim glows above the grass and the interior darkens the ground. |
| `after/r4_break_upwind.jpg` | Camera upwind of the trainer, looking downwind, in day Break. Rain streaks fall at mid-distance and none crosses near the lens. |

**Round-4 changes**
1. **Telegraph colour:** the rim and glow read combat.json `telegraph.colour` at runtime, with no copied value. Amber had read as reward gold, the same finding as combat.json's `_why_colour_0905`. The dark interior and the white-hot impact are kept.
2. **Depth pull:** 0.28 m, down from 0.7, and applied to the rim/glow rows only (radius ≥ rim − 0.15 m). The dark fill is never pulled.
   - Planar burial check with 16 rim samples: between samples the rim chord falls short of the terrain by up to A·(1 − cos(π/16)), where A = 3·tan(slope). That is 8.9 cm at 57° and 11.8 cm at 64°. Less the 7 cm lift, the burial is 1.9 cm and 4.8 cm.
   - A 0.28 m pull along the view ray clears a 9 cm burial whenever the ray meets the surface at ≥ 19°.
3. **Glow band:** past the rim the glow now extrapolates the centre-to-rim slope. It previously sat at rim height, 0.45 m out, which is 0.45 m off on a 45° slope. `atan` is guarded at the centre.
4. **Prewarm:** the prewarm waits for the active camera and draws a fully faded ring 4 m in front of it for 4 frames, then frees it.
5. **Rain slant:**
   - Slant is now 0.15/0.055, a drift of about 2.9 m over a drop's life.
   - Both emission rings are shifted upwind by half that drift.
   - The near ring now spans 10.6–17 m and the far ring 17–28 m.
   - A unit test keeps every drop ≥ 1.5 m from the camera at the riding arm (6.8 m + 0.6 m margin) and any yaw.
6. **Day Break sky:** sky top #5c5884 and ceiling #6c6898. At 14:00 both are ≥ 2× their night value at 23:00, and ≥ 0.3 luminance.
7. **Night separation:** the ceilings are now Calm #9ca0a0 (neutral), Building #585e3c (olive), Break #6c6898 (violet) and Fading #a88c6c (warm). Every adjacent pair differs by CIELAB ΔE ≥ 10 at 23:00, and a test pins each phase's hue identity.

**Negative controls** (each broken on purpose; the named test fails):
- **Item 1:** rim hard-coded to amber → the contract test fails ("expected ff40e6, got ffb040").
- **Item 5:** round-3 ring settings, no upwind shift → the lens test fails (a drop passes −4.15 m, i.e. it crosses the camera circle).
- **Item 6:** round-3 day Break values → the day/night test fails (lum 0.210 < 0.3).

## Sheets (all no HUD, production camera; each frame was looked at)

Round 3 re-rendered the day strips, the Break telegraph and flash, and the night frame per phase (`after/frames_after_r3.json`). The aftermath, matrix views and motion blocks are still round-2 renders (`after/frames_after.json`), made before the round-3 colour, telegraph and rain changes. They are stale for Break's hue, the telegraph and the rain slant, but still valid for the storm-vs-restored-sky contrast.

| File | What it shows |
|---|---|
| `sheet_strips_before_after.jpg` (round 3) | **Before:** the same blue sky with white cumulus in every phase, and no rain. **After:** <ul><li>**Calm:** a flat pale-grey overcast with drizzle.</li><li>**Building:** a dark olive-slate ceiling over dimmed, copper-dulled ground, with slanted rain.</li><li>**Break:** a violet-indigo ceiling and a paler lavender storm horizon, darker ground and heavy slanted rain. The amber telegraph ring appears in frames 01, 05 and 06.</li><li>**Fading:** a warm beige horizon and a broken ceiling with sky showing through.</li></ul> |
| `sheet_break_and_aftermath_before_after.jpg` | Telegraph and flash are round 3; the aftermath frames are round 2. <ul><li>**Telegraph:** a warning-amber glowing rim at 3 m drawn over the grass, with the interior visibly darker than the surrounding ground.</li><li>**Flash:** the whole ceiling lit lavender-white (flash level 0.52).</li><li>**Aftermath Calm:** open blue sky.</li><li>**Aftermath Break:** storm again.</li></ul> |
| `sheet_night_before_after.jpg` (round 3) | **Before:** the same clear blue night in every phase. **After:** <ul><li>**Calm:** mid-grey ceiling.</li><li>**Building:** dark olive-grey ceiling.</li><li>**Break:** its own violet-indigo ceiling and a lit lavender horizon, with the treeline and distant ground visible.</li><li>**Fading:** warm grey ceiling, no gaps and no flecks.</li></ul> The trainer reads in every phase. The rain is dimmer than the horizon. |
| `sheet_restored_sky_before_after.jpg`, `sheet_matrix_views_after.jpg` | Round 2 (see note above): the grey storm Calm, then open blue sky at the strip/rod-line and Deepwood stands. At the rod-line stand the pylon is hidden behind the trainer. |
| `sheet_motion_<phase>_before_after.jpg`, `motion_after_break_320x180_2fps.gif` | Round 2 (see note above): 31 s at 2 fps per phase. In Break the telegraph pulses every 4–8 s. No flash cell appears, because a flash decays in 0.35 s and each frame covers 0.5 s. |

## Round-3 changes (re-review R2-1, R2-2 and nits; round-2 judge (a)–(e))

- **R2-1 (telegraph cost):** every warning shares one cached, indexed ring mesh (336 vertices). Each strike samples only the centre plus 16 rim heights (17 `ground_height_near` calls, down from 336), and the vertex shader interpolates heights from them. The shader is prewarmed at realm load. A headless build takes about 25 µs (cleanup smoke, which has no terrain fixture). A test pins ≤ 25 calls and the shared mesh.
- **R2-2 (floors):**
  - The storm horizon, and so the fog, stays at ≥ 65% of the native horizon luminance for the hour.
  - The ceiling stays at ≥ 30% of it.
  - Both keep the authored hue, by day and night (`presentation.floors`).
- **(a) Night Break identity:** Break is re-hued violet-indigo (sky top #3a3854, horizon #645e82, ceiling #4e4a70). At night the floors keep that hue at least 60° away from Building's olive-grey, and a test pins this.
- **(b) Day ground follows the storm:** Building sun 0.38, ambient × 0.60, fog +0.0012. Break sun 0.24, ambient × 0.52, fog +0.002. The Break sky is lifted by the horizon floor, so it reads as a storm afternoon rather than night. A day ground-fill floor test (≥ 30% of the clear-day ambient) replaces the old raw sun-energy guard.
- **(c) Telegraph:**
  - Warning-amber rim #ffb040 (hue 35°) and amber glow #ffaa33 for 0.45 m past it.
  - The interior fill #100c10 darkens the ground as the strike nears.
  - Impact turns the rim white-hot.
  - The ring is pulled 0.7 m toward the camera along the view ray, so grass cannot cover the rim.
  - Rim stays at exactly 3 m and 1.2 s; tests unchanged and passing.
- **(d) Rain:**
  - Constant wind slant (0.22, 0.08) with streaks aligned to velocity.
  - The far layer is shorter (0.5 m) and fainter (alpha 0.2).
  - At night the tint drops to a 0.12 floor and alpha to 45%; a test checks night rain stays below the night horizon's luminance.
- **(e) Sky artefacts:**
  - The ceiling is now fully opaque down to the horizon, where it takes the storm horizon colour. Its translucent bottom band had let art.json's horizon haze and sun/moon glow through as the pale "shelf" and ghost disc.
  - Every storm ceiling is opacity 1.0.
  - Fading's gaps close at night (smoothstep on the day factor); they had opened onto the night sky's lit cloud flecks.
- **Nits:**
  - `_final()` is cached per target/base dictionary.
  - Cloud time wraps at 10000.
- **Negative controls:** each of these made its test fail.
  - 320 extra height calls → budget test fails (337 > 25).
  - A new mesh per strike → sharing test fails.
  - Floor removed → floor test fails (day Break horizon 0.384 < 65% of 0.723).

## Round-2 changes

- **B1 (blocking):** a strike impact always draws its bolt (0.18 s) and local light (energy 8, 18 m) at the impact. The whole-sky flash now goes through `stormwood_surge.gd::sky_flash_for_strike`: full strength while the local presentation is Break, otherwise `1 − distance/strike_sky_range_m` (40 m), and 0 beyond that. A guest's glass-sink strike in Calm therefore no longer flashes other peers' skies.
- **S1:** night scaling is applied once, to the authored storm colours (`_final`), before any cross-fade. `_mix` fades through the native base colour and never re-scales it, and `_delta_from` no longer scales anything.
- **S2 and night:**
  - The storm ambient keeps its authored hue but never exceeds the native ambient value for the hour, so a storm never adds fill light.
  - At night, the phase's ambient-energy and sun-energy cuts release toward 1.0 (squared by the day factor), so art.json's night readability is neither lifted nor sunk.
  - Rain tint follows the night factor down to 0.3, so unshaded streaks don't glow.
- **J1:** the telegraph is a ground-sampled flat ring mesh.
  - Rim #f4eeff at intensity 2.4, exactly at `strike.radius_m` = 3 m.
  - Cyan #8fdcff soft falloff over 0.45 m past the rim, plus a lavender #b4a6ff fill that grows over the telegraph.
  - The pulse chirps from 2 to 7 Hz across `strike.telegraph_seconds` = 1.2 s.
  - On impact the rim flares and fades over 0.25 s.
- **J2:** Building sun 0.45, ambient #a8927a × 0.70. Break sun 0.30, ambient #8a90b8 × 0.62.
- **J3:** drop scale is 0.5–1.35, and per-drop alpha is 30–100% via an initial-colour ramp. A second far layer adds 700 drops, ring 13–26 m, 5 cm × 1.3 m streaks at alpha 0.32.
- **Nits:** ceiling radius, flash light angle, echo strength and reapply cadence (0.2 s / 2 s) are now in config, as are the bolt radii and emission. Clouds use an accumulated `cloud_time`, so there is no `mod(TIME)` jump. The bolt mesh/material and the telegraph shader are cached. `storm_sky` is gone. The tool gained a `.uid`.

## Per-phase daytime values (`data/config/stormwood_surge.json` → `presentation.phases`, round 3)

| Phase | Sun × | Ambient × energy | Fog + | Sky top / horizon | Ceiling colour | Rain | Flashes |
|---|---|---|---|---|---|---|---|
| Calm | 0.80 | #b6d5c5 × 0.95 | 0.0004 | #6d7c80 / #a8b4ae | #9aa6a2 | 0.30 | no |
| Building | 0.38 | #a8927a × 0.60 | 0.0012 | #3c464c / #7c7a6c | #5a625e | 0.60 | no |
| Break | 0.24 | #8a90b8 × 0.52 | 0.0020 | #3a3854 / #645e82 | #4e4a70 | 1.00 | yes, 4–8 s |
| Fading | 0.80 | #e0b397 × 0.90 | 0.0005 | #6f8ea4 / #c8b29a | #9a968e (breakup 0.5, day only) | 0.15 | no |
| Aftermath Calm | 1.00 | art.json | 0 | art.json | open (0) | none | no |

All storm ceilings are at opacity 1.0.
- **Horizon and ceiling floors:** the storm horizon stays at ≥ 65% of the native horizon's luminance, the ceiling at ≥ 30% (same hue).
- **Sky, ceiling and ambient:** at dusk and night, sky and ceiling colours are multiplied by the live sky's luminance relative to day (floor 0.12), and then the floors above apply. The ambient colour is capped at the native ambient's value.
- **Energy cuts:** the sun and ambient energy cuts release toward 1.0 at night.

## Still open

- **Round 4 has not been judged blind.** The frames are 640×360 only.
- **Earlier evidence is stale.** The strips, night, aftermath, matrix-view and motion sheets predate the round-4 colours, telegraph and rain.
- **Night storm ground is darker than a clear night.** The ground loses the blue night fill.
- **Day Break foreground grass is still fairly green.** Sun, ambient and fog were the only levers available.
- **The flash has been seen in stills only.**
- **No Ally frame-time profile could be taken** (software GL in a container). The review's CPU figure is 0.40 ms per warning; GPU cost on the device is unmeasured.
- **Outside these files:** copper flicker, wind response, steam/afterglow, audio, and the rod-line stand framing.

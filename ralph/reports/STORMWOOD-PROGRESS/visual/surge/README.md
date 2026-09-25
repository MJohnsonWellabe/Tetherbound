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

## Sheets (all no HUD, production camera; each frame was looked at)

| File | What it shows |
|---|---|
| `sheet_strips_before_after.jpg` | 4 phases × 6 frames 5 s apart, before/after row pairs. **Before:** the same blue sky and white cumulus in every phase, no rain, only a ground tint. **After:** Calm is a flat pale-grey overcast with drizzle. Building is a dark olive-slate ceiling over dimmer, copper-dulled ground, with more rain. Break is a violet-navy ceiling, noticeably darker ground and heavy rain; frames 05 and 06 show the new glowing ground-ring telegraph. Fading has a warm beige horizon and a broken ceiling over light rain. |
| `sheet_break_and_aftermath_before_after.jpg` | Telegraph / flash / aftermath Calm / aftermath Break at the strip stand. **After telegraph (J1):** a flat ring lying on the grass, with a bright white glowing rim at 3 m, a soft glow past it and a faint lavender hazard disc inside. The old version was an opaque lavender tube. **After flash:** the whole ceiling lit pale lavender-grey (flash level 0.62 at capture). **Aftermath Calm:** open blue sky, no rain. **Aftermath Break:** storm again. **Before:** blue sky throughout, no flash hook ("no frame"). |
| `sheet_night_before_after.jpg` | New in round 2: one frame per phase at hour 23. **Before:** all four phases are the same clear blue night. **After:** Calm has a grey ceiling. Building has a darker olive ceiling. Break has a near-black violet ceiling with rain. Fading has a broken grey ceiling with native sky showing through. The trainer and nearby ground stay readable in every phase. The rain is dimmed, not glowing. **After nights are clearly darker than the clear night** (see open items). |
| `sheet_restored_sky_before_after.jpg` | Storm Calm vs aftermath Calm with the camera raised, at the strip/rod-line stand and at Deepwood. **After:** a grey storm Calm, then open blue sky with cumulus in both aftermath frames. **Before:** blue sky everywhere, so there is nothing to contrast. |
| `sheet_matrix_views_after.jpg` | After only: storm Calm, storm Break and aftermath Calm at the rod-line and Deepwood stands. The ceiling/rain and restored-sky contrast holds at both. The rod-station pylon is mostly hidden behind the trainer at this inherited stand. |
| `sheet_motion_<phase>_before_after.jpg` | 62 frames 0.5 s apart (31 s) per phase, 160×90 cells. The before block is from round 1, cropped from the round-1 sheet because the source frames were deleted. The after block was re-rendered in round 2, and its scratch frames have been deleted. In the Break after block the telegraph appears every 4–8 s, and its rim brightness visibly pulses between cells. Rain and cloud drift are not legible at this size. No flash cell appears, because a flash decays in 0.35 s and each rendered frame covers 0.5 s of game time. |
| `motion_after_break_320x180_2fps.gif` | Round-2 Break at 320×180, 62 frames at 2 fps: rain, ceiling drift, telegraph pulses. |

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

## Per-phase daytime values (`data/config/stormwood_surge.json` → `presentation.phases`)

| Phase | Sun × | Ambient × energy | Fog + | Sky top / horizon | Ceiling colour, opacity | Rain | Flashes |
|---|---|---|---|---|---|---|---|
| Calm | 0.80 | #b6d5c5 × 0.95 | 0.0004 | #6d7c80 / #a8b4ae | #9aa6a2, 0.92 | 0.30 | no |
| Building | 0.45 | #a8927a × 0.70 | 0.0009 | #3c464c / #7c7a6c | #5a625e, 0.97 | 0.60 | no |
| Break | 0.30 | #8a90b8 × 0.62 | 0.0013 | #262a3a / #565a6e | #40445a, 1.0 | 1.00 | yes, 4–8 s |
| Fading | 0.80 | #e0b397 × 0.90 | 0.0005 | #6f8ea4 / #c8b29a | #9a968e, 0.88 (breakup 0.5) | 0.15 | no |
| Aftermath Calm | 1.00 | art.json | 0 | art.json | open (0) | none | no |

At dusk and night, the sky and ceiling colours are multiplied by the live sky's luminance relative to day (floor 0.12). The ambient colour is value-capped at the native ambient, and the sun and ambient energy cuts release toward 1.0 as described above.

## Still open

- **Storm nights are darker than a clear night.** Their ground loses the blue night fill, and the ceiling hides the night sky. The trainer and near route stay readable, but no judge has reviewed the night frames.
- **The flash has been seen in stills only;** there is no 60 fps footage (this container renders under 1 fps). Rhythm and duration need a look on device.
- **No Ally frame-time profile could be taken here** (software GL in a container). The cost of the dome, the second rain layer and the per-strike ring mesh on device is unmeasured.
- **ART_DIRECTION §3.3's other cues are outside these files:** copper flicker, canopy and grass wind response, moss/understory value, and post-strike steam/afterglow.
- **Audio (AUDIO §4.3) is untouched.**
- **The rod-line matrix stand hides the pylon** behind the trainer.
- **Round-2 visuals have not been re-judged blind.**

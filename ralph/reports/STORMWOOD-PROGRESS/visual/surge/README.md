# Stormwood Surge phase readability (F10 / S2): visual evidence

Work order: ACCEPTANCE §6.1 F10 / S2. Calm, Building, Break and Fading must be nameable **without HUD phase text**, lightning keeps its 1.2 s / 3 m telegraph, and the restored sky must contrast with the storm. Owning specs: WORLD §5.2, ART_DIRECTION §3.3 and §4 (Stormwood row), AUDIO §4.3 (audio not in scope here).

## How these frames were made

- **Tool:** `tools/capture_stormwood_surge_phases.gd` (see its header for the command line). It is the same staging as `tools/capture_stormwood_lane_evidence.gd`'s Surge strips.
- **Camera:** the production `CameraRig/Camera3D` following the real Player. There is no survey or free camera. Placement is `Game.debug_teleport_to` plus the Player transform at the stand, and the rig then settles on its own. Every HUD `CanvasLayer` is hidden, including the Surge "⚡ Phase" glyph.
- **Stand:** Cinder Verge marked clearing `verge_glass_01` at (-604, 772), facing the Verge Rod Station, pitch 2°. The *views* frames use the lane tool's matrix stands: the rod line from 30 m on the Ash Road side, and Deepwood/Lantern Hollow at (-470, 3905).
- **Staged state:** recorded per frame in `before/frames_before.json`, `after/frames_after.json` and `after/frames_after_views.json`.
  - The day clock is pinned to `day`.
  - The surge clock is pinned to `<phase start> + 2 s` and then runs free.
  - In *after* runs only, `settle_presentation()` is called after each pin, so frame 1 is not caught mid cross-fade. That cross-fade is the 6 s blend the pin itself would trigger. Natural phase changes still cross-fade.
  - Player health is restored between Break frames.
  - Aftermath and views set `stormwood:long_storm_ended`.
  - `Engine.max_physics_steps_per_frame` is raised to 30, because software GL renders this world at well under 1 fps. Ticks stay 1/60 s. The telegraph and flash captures drop back to 8 or 1 ticks per frame.
- **Before vs after:** *before* is `origin/main` at bcf46366c. The lane's `stormwood_surge.gd`, `stormwood_lightning.gd` and `stormwood_surge.json` were stashed, and the same tool was run. *After* is this branch.

## Sheets

| File | What it shows (all no HUD, production camera) |
|---|---|
| `sheet_strips_before_after.jpg` | 4 phases × 6 frames 5 s apart, row pairs before/after. **Before:** every phase has the same blue sky, white cumulus and no rain; only a ground and dead-tree tint differs. **After:** Calm has a flat pale grey-green overcast with drizzle. Building has a dark, higher-contrast olive-slate ceiling, copper-tinted ground and more rain. Break has a violet-navy ceiling, heavy rain and the violet telegraph rings (frames 03, 04). Fading has a warm beige horizon and a broken ceiling with sky showing through, plus light rain. |
| `sheet_break_and_aftermath_before_after.jpg` | Break telegraph, Break flash, aftermath Calm and aftermath Break at the strip stand. **Before:** the telegraph ring sits under a blue sky, there is no flash hook ("no frame"), and aftermath Calm and aftermath Break are identical blue-sky frames. **After:** the telegraph ring appears under a dark storm sky in rain. The flash frame shows the ceiling lit pale lavender-white (flash level 0.55 at capture). Aftermath Calm has an open blue sky with cumulus and no rain. Aftermath Break has the violet storm ceiling and rain. |
| `sheet_restored_sky_before_after.jpg` | Storm Calm vs aftermath Calm with the camera raised at the strip/rod-line stand and at the Deepwood stand. **Before:** all three frames show the same blue sky, so the aftermath cannot contrast with anything. **After:** the grey storm Calm is followed by open blue sky in both aftermath frames. |
| `sheet_matrix_views_after.jpg` | After only: storm Calm, storm Break and aftermath Calm at the rod-line and Deepwood matrix stands. The storm frames show the grey or violet ceiling and rain; aftermath Calm shows the open blue sky. **Caveat:** at this stand the rod-station pylon is almost hidden behind the trainer (only its glowing tip shows above the trainer's head). The "forest" stand is the Lantern Hollow clearing (house, bear-type wild), not dense canopy. |
| `sheet_motion_<phase>_before_after.jpg` | Frames at 0.5 s steps for 31 s per phase (62 frames at 2 fps), 160×90 cells; the before block is above the after block. The source frames were 640×360 JPGs in scratch and have been deleted. At this cell size rain streaks and cloud drift are not legible. What reads is the constant sky state for the whole 31 s, and the Break telegraph rings every 4–8 s. **No flash cell appears:** a flash decays in 0.35 s, and each rendered frame here covers 0.5 s of game time. |
| `motion_after_break_320x180_2fps.gif` | The after Break motion sequence as a 62-frame GIF at 320×180, played at 2 fps. Rain streaks, ceiling drift and the telegraph rhythm are visible. The other three phases were built as GIFs as well, but were deleted because of disk space (about 2 MB each). |

Individual frames are in `before/` and `after/` (strips at 640×360; telegraph, flash, raised-sky and views frames at 1280×720).

## What changed per phase (config: `data/config/stormwood_surge.json` → `presentation`)

| Phase | Sun × | Ambient colour × energy | Fog + | Sky top / horizon / ground-horizon | Ceiling colour, opacity, speed, contrast, breakup | Rain | Flashes |
|---|---|---|---|---|---|---|---|
| Calm | 0.80 | #b6d5c5 × 0.95 | 0.0004 | #6d7c80 / #a8b4ae / #98a49e | #9aa6a2, 0.92, 0.006, 0.18, 0 | visible, 0.30 | no |
| Building | 0.60 | #d7a77b × 0.80 | 0.0009 | #3c464c / #7c7a6c / #6c6c62 | #5a625e, 0.97, 0.028, 0.50, 0 | visible, 0.60 | no |
| Break | 0.42 | #d2ccff × 0.72 | 0.0013 | #262a3a / #565a6e / #4c5062 | #40445a, 1.0, 0.040, 0.55, 0 | visible, 1.00 | yes, 4–8 s |
| Fading | 0.80 | #e0b397 × 0.90 | 0.0005 | #6f8ea4 / #c8b29a / #a89e90 | #9a968e, 0.88, 0.012, 0.35, 0.5 | visible, 0.15 | no |
| Aftermath Calm | 1.00 | art.json (null) × 1.0 | 0 | art.json sky (null) | opacity 0 (open) | hidden | no |

- **Shadow opacity** is unchanged: 0.68 in every phase, 1.0 in Break.
- **Fog colour** always equals the phase's horizon colour, which is art.json's fog/horizon seam rule.
- **Night scaling:** sky and ceiling colours are daylight values. They are scaled by the live sky's luminance relative to day, with a floor of 0.12, so storm colours never light up the night.
- **Aftermath Building/Break/Fading** keep the storm rows with lighter overrides: ceiling 0.85 / 0.95 / 0.6, Break sun 0.55, and Fading breakup 0.6 with rain 0.1.
- **Rain streaks** use `presentation.rain`: 900 drops at amount 1.0, 3.5 cm × 0.9 m, #c8d4e0 at alpha 0.6.
- **Flash** uses `presentation.flash`: colour #e6dcff (white-violet), decay 0.35 s, 50% chance of a double flicker, and a directional-light energy of 2.2 at full flash. On impact, a real strike adds a 45 m bolt for 0.18 s and a local omni light (energy 8, range 18 m), then calls a full-strength sky flash.
- **Cross-fade:** phases cross-fade over `transition_seconds` = 6 s.
- **No red:** copper/amber (hue about 30°) only; a unit test rejects any presentation colour whose hue is within about 16° of red.

## Still missing / not met

- **The white-violet flash is a single sampled frame.** No 60 fps motion capture of it exists, because this container renders under 1 fps. Whether its 0.35 s duration and rhythm read well in real play needs an on-device look.
- **ART_DIRECTION §3.3's other motion cues are not addressed here:** copper flicker on vines, wind response of canopy/grass, moss/understory value shifts, and post-strike steam/afterglow. They live in vegetation, prop and VFX code outside this work order. Phase identity currently comes from sky, ceiling, light, rain and flash.
- **Audio (AUDIO §4.3) is untouched**, so "nameable from sound" is not evidenced.
- **Night and dusk Surge frames were not captured.** Night scaling is unit-tested only.
- **The ground still reads fairly bright green in Break.** This was kept deliberately so telegraph rings and creatures stay readable. A code-blind judge pass has not been run.
- **The rod-line matrix stand hides the pylon behind the trainer**, which is inherited framing. A better rod-line stand is needed for the chapter frame matrix.
- **The ceiling is a realm-local dome**, because WorldLook's weather layer can recolour the sky gradient but not the painted clouds. The shared sky shader was not touched.

# RG21 — Continuous day/night with a short true night

## Goal
Make the Meadows day/night cycle transition continuously through the full visual day instead of snapping between named presets, while keeping the full in-game day at 10 real minutes and limiting genuinely dark night to about 2 real minutes.

## Owner intent
- A full 24-hour game day remains 10 real minutes.
- Day should not abruptly switch to night.
- Lighting/sky/fog/sun/ambient treatment should move progressively through morning, day, golden hour, dusk, night, dawn, and back to day.
- True night should be short: about 2 real minutes out of each 10-minute cycle.
- Dawn and dusk are transition periods, not part of the 2-minute fully dark window.
- The result should feel closer to Valheim-style pacing: long playable daylight, a meaningful but brief night, and visible natural transitions.

## Current state
Relevant live code:
- `scripts/world/day_cycle.gd`
  - `day_length_seconds` defaults to 600 seconds.
  - `hour_at()` maps elapsed real time to 0–24 in-game hours.
  - `preset_at()` currently returns the latest named keyframe at/before the current hour, which is a discrete preset selection model.
  - `is_dark()` currently uses `dark_from_hour` / `dark_to_hour`.
- `data/config/art.json`
  - owns the presentation presets and day-cycle tunables.
  - currently defines `day_length_seconds: 600` and named time presets such as day/golden/etc.
  - presentation values are intentionally tunable/data-driven.

The backlog owner report is that day currently reads as switching rather than progressing, and that night lasts too long.

## Desired behavior
1. Keep `day_length_seconds = 600` unless there is a compelling technical reason not to.
2. Define a short true-dark window equivalent to roughly 120 real seconds per 600-second cycle.
   - 120 / 600 = 20% of the cycle.
   - In a 24-hour clock that is about 4.8 in-game hours of true night.
   - Exact clock boundaries are tunable; preserve the owner-facing requirement rather than hard-coding an arbitrary permanent pair if a cleaner art-directed split is available.
3. Visual state should interpolate continuously between authored keyframes instead of snapping from one named preset to the next.
4. At minimum interpolate the presentation fields that visually cause the transition to read as continuous:
   - sun pitch/yaw/energy/colour as appropriate,
   - sky colours / panorama treatment where supported,
   - environment exposure / ambient energy / ambient colour,
   - fog colour / density,
   - any other existing time-of-day presentation values that visibly jump today.
5. Interpolation must wrap cleanly across midnight from the last keyframe back to the first.
6. Dusk and dawn should be visibly gradual. There must not be a single frame where the whole world suddenly becomes “night” or “day”.
7. `is_dark()` remains a gameplay/presentation semantic for the actual dark-night window; it should not simply return true for the entire dusk/dawn blend.

## Implementation requirements
- Reuse the existing `day_cycle.gd` + `art.json` ownership split.
- Keep values data-driven and tunable.
- Do not create a parallel second time-of-day system.
- Prefer adding a pure interpolation/query layer to `day_cycle.gd` (or an appropriately small sibling pure-data helper) and having the world-look renderer consume that result.
- Do not move visual constants into scenes or hard-code them across multiple scripts.
- Preserve compatibility with tools/tests that still need named keyframe access.
- If `preset_at()` is used elsewhere, do not silently change its semantic in a way that breaks callers; add an interpolated-state API if that is safer.

## Preserve
- 10-minute complete day.
- Existing authored day/golden/night visual direction unless a transition requires small tuning.
- The rule that `art.json` owns presentation tunables.
- Existing camp/rest behavior that snaps time to a named hour, if present.
- Existing night-light work; coordinate rather than overwrite it.
- Torch behavior must be judged after RG21 against the settled night floor, not tuned by making night artificially dark.

## Edge cases
- Midnight wraparound.
- Resting/skipping time directly to morning: the next rendered frame should be the correct morning state with no stale night values.
- Loading a save at any time of day.
- Very low frame rate on the ROG Ally: interpolation must be based on time, not frame count.
- Changing `day_length_seconds` or keyframe hours in data should not require code changes.
- Missing/malformed optional values in one keyframe should inherit/fall back predictably rather than producing zero/black flashes.

## Acceptance criteria
- A full cycle remains approximately 10 real minutes.
- Approximately 2 real minutes are genuinely dark night.
- Dawn/dusk are additional gradual transition periods and do not count as true night.
- No visible hard snap occurs between day, golden hour, dusk, night, dawn, or day.
- Sun/sky/environment/fog evolve smoothly across transitions.
- The dark semantic used by torch/night systems is true only for the intended short-night window.
- A real in-engine capture or timed playthrough demonstrates the transition across at least dusk→night→dawn.
- ROG-target frame behavior remains stable; no per-frame resource rebuild or expensive asset reload is introduced.

## Testing / verification
- Extend/add pure tests for `day_cycle.gd` covering:
  - 600-second cycle mapping,
  - midnight wrap,
  - exact dark-window duration near 20% of the day,
  - interpolation factor around adjacent keyframes,
  - no discontinuity at midnight.
- Run existing world/playground smoke tests.
- Add or update a capture tool that samples several timestamps through dusk/night/dawn and verifies the scene is changing continuously rather than only at discrete keyframes.
- Re-judge night-light/torch captures only after this cycle is settled.

## Definition of done
RG21 is done when a player can stand in the Meadows and watch daylight visibly fade into dusk, then a short ~2-minute true night, then a gradual dawn, all within the existing 10-minute day, with no abrupt preset switch and with all timing/presentation values still tunable from the existing data-driven system.

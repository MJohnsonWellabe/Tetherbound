# Finding: the golden-hour survey frame renders pure black

Recorded 2026-08-28 by the coordinator session, from a survey run on
`main` at 26f0db4f. Not owner-observed — this is a harness finding, and
it is written down because it is reproducible and easy to lose.

## What happens

`tools/survey.sh` writes five frames. Four are good. The fifth fails the
survey's own critic:

    FAIL: 05-spawn-low-sun: frame is almost a single flat colour
    (spread 0.0000); nothing rendered

The PNG is 5,320 bytes of pure black. The survey completed normally and
reported `5 frames -> res://shots` before the check, so this is not a
truncated run or a killed process.

## Why it matters

`05-spawn-low-sun` is the same eye and target as `01-spawn-outward`,
which renders correctly. The ONLY difference between them is
`"time": "golden"` versus `"time": "day"`. So applying the golden preset
at a viewpoint that otherwise works produces nothing at all.

Golden hour is not a corner case. `art.json` calls it "the mood the key
art's own sunset panel is selling", and the day/night mood contrast is
a stated art goal. If evening genuinely renders black in-game this is
severe; if it is capture-only it still blinds the visual-judge loop at
exactly the hour the art board cares most about.

## Hypotheses ruled out

- **Truncated capture.** The survey printed its completion line and its
  critic then ran. The frame was written, not abandoned.
- **A malformed preset.** `art.json`'s `golden` block is fully specified
  and has been tuned by at least three named passes (EV8, VIS-WORLD).
  Sun energy 1.5, ambient_energy 0.85 — nothing near black.
- **A panorama/procedural sky swap forcing a shader recompile.** There
  is no panorama in any preset; all three are procedural, and the run
  logged zero recompiles.

## What has NOT been ruled out

- Insufficient settle frames after `apply_time("golden")` specifically.
  Note `apply_time` is the one place `_elapsed_seconds` is written
  outside `_process`, and it also sets sun, sky, fog and ambient
  together. A capture taken before that settles could be uniform.
- A Compatibility-renderer-specific failure at this sun pitch (-13 deg).
  Remember the survey runs Compatibility, not the Forward+ the game
  ships, so this may not reproduce for a player at all.
- A genuine in-game lighting failure at hour 18.0.

## Resolved 2026-08-29: it is not a lighting bug at all

`tools/_diag_golden_hour.gd` (built by the previous lane, run by
`ralph/T1-LIGHT`) rendered this exact viewpoint at `day`/`golden`/`night`
under four settle regimes (`survey`, `immediate`, `generous`, `frozen`) —
13 trials in one continuous run, camera held fixed the whole time. **Every
single trial rendered correctly**, `05-golden-survey` included (spread
1.6302, the best of the twelve). The hour-drift hypothesis is refuted
outright too: even the `generous` regime, after 275s of real wall clock
under llvmpipe, moved the pinned hour by only 0.08-0.09 — nowhere near
the "hours of drift" `_apply_blended()` theory required. `apply_time()`'s
docstring claim stands; `_process()` is not overwriting the pin.

So the diagnostic could not reproduce the black frame, which meant the
finding needed a different decisive test: run the real
`tools/survey.gd`, not an isolated proxy. It still failed identically —
`05-spawn-low-sun.png`, 5,320 bytes, `spread 0.0000`, same as the
original report.

Two follow-up probes (scratch, not committed) isolated the real cause:

1. A copy of `survey.gd` with shot 5's `"time"` changed from `"golden"` to
   `"day"` — identical preset to shot 1 — **still went black.** Golden
   hour has nothing to do with it.
2. A copy of `survey.gd` stripped down to just shot 1's viewpoint,
   captured twice in a row with no teleport in between (skipping shots
   02-04 entirely) — **both captures rendered fine** (spread 1.477, 1.487).

So the failure needs BOTH conditions: the exact same viewpoint as an
earlier shot, reached only after several large camera teleports through
other regions in between (shot 1 at (-9,-7) -> shot 2 at (-120,130) ->
shot 3 at (172,-88) -> shot 4 at (70,40) -> back to (-9,-7)). Being called
fifth is incidental; what matters is "revisit a position after the camera
has been teleported far away and back several times in one continuous
run." That is `survey.gd`'s own comment made literal: `terrain.set_camera()`
hands Terrain3D a moving camera and the regions stream/unstream around it
as it teleports — this looks like a region re-streaming or capture-timing
defect in that path, most likely Terrain3D itself or the interaction
between it and this harness's fixed 24-frame settle-after-teleport, not
anything time-of-day or lighting owns.

**This is not Track 1 (aesthetics) scope.** No `art.json` value or
`world_look.gd` code was touched to "fix" this, because none of them are
the cause — tuning golden hour further would not have changed anything.
Recorded here so the next session (Track 2/reliability, whoever owns
Terrain3D streaming and `tools/survey.gd`) does not re-derive the four
hypotheses above; start from "reproduce with day-only, no golden
involved" and "isolate whether it's teleport COUNT, teleport DISTANCE, or
specifically returning to a previously-visited region."

The Track 1 lighting/time-of-day work this file used to gate proceeded
using `tools/_diag_golden_hour.gd`'s own frames (single fixed viewpoint,
unaffected by this streaming defect) and fresh single-viewpoint captures,
not `survey.gd`'s multi-teleport sequence.

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

## How to resolve it

Cheapest decisive test: render this one viewpoint at `day`, `golden` and
`night` in a single run with a generous settle, and compare. If only
golden is black, it is the preset path; if golden is fine with more
settle frames, it is the harness.

Do NOT judge the game from this frame until that test has been run.
This file exists so the next session does not re-derive the three
hypotheses above.

# Tidewake close-1024 round rg1: overcast rain grade on top of the Tidewake rain mist, CPU pre-judge (25 Oct 2026, CT): LEVEL, stays OFF

## What was tried (`rain_grade_candidate`, OFF in play)

- **The ask:** rf1 judges x3 said the rain no longer read as rain.
- **The grade, Tidewake rain only:**
  - a darker slate sky (top #3f5260, horizon #6f818b);
  - the sun at 0.32 of its energy (preset 0.5);
  - ambient 0.75.
- **Layering:** on top of t1e, falls f2 and `rain_fog_candidate`.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 11181).
- **Calibration:** `calibrate.py` slope 0.98, r 0.88, anchor RMSE 0.47.

| Set | Rain mist only | + overcast grade | Judges |
|---|---|---|---|
| Rain views (3) | 6.36 | 6.29 | split, -0.2 to +0.1 |

## Why level

- The sky darkened only slightly. Bright cumulus and blue gaps survive.
- **Unchanged x3:**
  - "does not read as rain" (PARTIAL x3);
  - sparse streaks, dry sunlit sand, no wet sheen, splashes or ripples.
- **Stays OFF.**

## What it would take (named x3)

- Denser streaks.
- Wet-darkened sand with sheen.
- Rain ripples on the sea.
- A sky without blue gaps.

Wet sand and ripples are a material and shader change, not a grade change.

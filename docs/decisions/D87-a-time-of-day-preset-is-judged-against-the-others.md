# D87 — A time-of-day preset is judged against the other times of day, not on its own

**Date:** 2026-09-05 · **Decided by:** lane N13-NIGHT-RESUME-0905, under the COMMON
rule that a lane makes the smallest defensible call and records it rather than
stopping to ask. Sources: `docs/owner/OWNER_PLAYTEST_2026-09-04.md` OP-0904-2,
`docs/GATE2_GATE3_CLOSURE_PLAN.md` CL-O2, and `data/config/art.json`'s own
`_comment_night_light` history.

The owner played the shipped build and said **"There is no night time."** The
clock was fine. The night preset was brighter than the day preset. Three blind
judging rounds had looked straight at it and could not see it, because each
round was shown night frames and asked whether they read as night — never night
beside day from the same camera.

This records the rule that stops that recurring, and two consequences of it.

## 1. A time-of-day preset's acceptance test is a comparison, never a single frame

Whatever else is being judged about a time of day — mood, legibility, hue — the
first question is **how it sits against the other times of day at the same
viewpoint**. A night frame alone cannot answer "is this night"; a viewer with no
reference adapts to whatever they are shown and reports on its mood. Two frames
from one tripod answer it immediately.

`tools/gate_f/probe_daynight_contrast.gd` is that instrument: one world, one
camera, several hours of the same day, driving `world_look.gd::_apply_blended()`
so the frames are lit the way the running game lights them. It replaces "render
night and look at it" as the standard evidence for any change to a `times` entry.

**Not** a new mechanic and **not** a change to what the blind-judge process is —
`ralph/briefs/0904/COMMON.md`'s code-blind judging stands exactly as written.
This only fixes what the judge is handed.

## 2. `exposure` is not a brightness dial a preset may spend freely

`world_look.gd::_apply_environment()` installs `exposure` as
`env.tonemap_exposure`, which multiplies the entire linear scene before ACES. So
a preset can halve every light it owns, double its exposure, and come out no
darker at all — while `Sun.light_energy` still reads as a convincing night to
anything that samples it. That is not hypothetical: it is what happened, one
"too dark" verdict at a time, from exposure 0.85 to 2.0 to 1.2 against day's 0.6.

The rule: **a time-of-day preset states how much light it has, and exposure is
part of that statement, not an exemption from it.** The quantity that matters is
`energy × exposure`, and `world_look.gd::light_budget_at()` is the one place it
is computed. Anything asserting about how bright a time of day is reads that
function.

`tests/test_day_cycle_night_contrast.gd` holds the floor: no hour inside
`is_dark()`'s window may ask for more light than midday, the middle of the night
may ask for at most 60% of it, and the darkest moment must land in the middle of
the dark window rather than on its edge. The 60% is a decision, and a TUNABLE
one — it is bounded below by this file's own measured black point (an asked-for
total near 0.221 rendered a flat-black frame) and above by the owner's report.

## 3. What was NOT decided here

- **The night preset's hue, saturation and camp/creature legibility values are
  untouched.** `adjustment_saturation` 0.72 is NIGHT-LIGHT round 3's, and
  `camp_fill_energy` 2.4 / `creature_emission_floor` 0.22 are NIGHT-LEGIBILITY's.
  Only the three brightness numbers moved.
- **The keyframe layout is unchanged.** `night` still sits alone at hour 0, which
  means the fully-arrived night look is still touched for one instant of a
  600-second day and every other dark hour is a lerp toward golden or dawn. That
  is a real, separate finding — recorded in
  `ralph/reports/N13-NIGHT-RESUME-0905/REPORT.md`, not fixed here, because giving
  the night a plateau means adding keyframes and that changes what
  `preset_at()` returns to every caller in the project. It wants its own lane.

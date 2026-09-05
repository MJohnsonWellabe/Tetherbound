# D87 — `is_dark()` is the true-dark window, narrower than the visible night, and a time of day is judged against the other times of day

**Date:** 2026-09-05 · **Decided by:** lane N13-NIGHT-RESUME-0905, under the COMMON
rule that a lane makes the smallest defensible call and records it rather than
stopping to ask. Sources: `docs/owner/OWNER_PLAYTEST_2026-09-04.md` OP-0904-2,
`docs/GATE2_GATE3_CLOSURE_PLAN.md` CL-O2,
`docs/prompts/07-RG21-continuous-day-night-short-night.md`, and the frames
`tools/gate_f/probe_daynight_contrast.gd` shot for this lane.

The owner played the shipped build and said **"There is no night time."** Two
things this lane measured are worth binding as rules, because in both cases the
project already believed the opposite and had passing checks saying so.

## 1. `is_dark()` is the TRUE-DARK window and is deliberately narrower than the visible night

`day_cycle.gd::is_dark()` is not a description of the sky. It is the switch for
every torch, every camp fill light and `creature_body.gd`'s night emission
floor. RG21 says so directly — it "should not simply return true for the entire
dusk/dawn blend" — and asks for about 120 real seconds of it per 600-second day,
"about 4.8 in-game hours", with dawn and dusk as transitions outside it.

It had drifted to hour 20 → 5: nine in-game hours, 225 real seconds, opening at
an hour that renders at 67% of midday and closing after dawn is underway. So for
nearly four minutes of every ten the systems announced night over a
late-afternoon sky.

**The rule:** `dark_from_hour`/`dark_to_hour` bound the hours that are *actually
dark in the frame*, measured, not the hours that are "getting dark". The
visible sweep from golden through night to dawn is longer than the window on
purpose, and that is not a bug to be fixed by widening the window.

Landed as `dark_from_hour: 22.0`, `dark_to_hour: 3.0` — five in-game hours, 125
real seconds. Both endpoints render below half of midday. `TUNABLE`, and
`tests/test_day_cycle_night_contrast.gd` holds the band.

## 2. A time of day is judged against the other times of day, never on its own

Three NIGHT-LIGHT blind-judge rounds each looked at night frames alone and were
each asked whether they read as night. A viewer with no reference adapts to
whatever they are shown, so each round answered on mood and each round's answer
pushed `exposure` up (0.85 → 2.0 → 1.2 against day's 0.6). Nobody ever put a
night frame beside a day frame from the same camera, which is the only framing
in which the question has an answer.

**The rule:** evidence for any change to an `art.json` `times` entry is a
multi-hour sheet from one tripod — `tools/gate_f/probe_daynight_contrast.gd`,
which drives `world_look.gd::_apply_blended()` so the frames are lit the way the
running game lights them, not `apply_time()`'s pinned preset that every other
capture tool in `tools/` uses. Blind judging is unchanged from
`ralph/briefs/0904/COMMON.md`; this only fixes what the judge is handed, and the
sheet should be shuffled and lettered so the judge is not told which frame is
supposed to be the night one.

**Corollary, learned the hard way in this same lane:** any numeric stand-in for
"how bright is this preset" must weight each light by its own colour's
luminance. Night's light is a dark blue and day's is near-white, so
`energy × exposure` alone reports night as the brighter of the two while the
renderer reports 0.26. `world_look.gd::light_budget_at()` is the one place that
arithmetic lives; anything asserting about preset brightness reads it rather
than re-deriving it.

## 3. What was NOT decided here

- **The night preset is untouched.** NIGHT-LIGHT's `exposure`/`ambient_energy`/
  `sun.energy` and `adjustment_saturation`, and NIGHT-LEGIBILITY's
  `camp_fill_energy` 2.4 / `creature_emission_floor` 0.22, are all exactly as
  they were. Measured, the night look is correct: midnight renders at 26% of
  midday and stays legible.
- **The clock still has no memory, and that is the larger half of OP-0904-2.**
  Every world starts at 08:00, nothing saves the hour, and a realm crossing or a
  Continue rebuilds the scene. That fix lives in `save_game.gd` /
  `game_state.gd`, which this lane does not own, and is routed in
  `ralph/reports/N13-NIGHT-RESUME-0905/REPORT.md`. **CL-O2 is not closed.**
- **The keyframe layout is unchanged.** `night` still sits alone at hour 0, so
  the fully-arrived night look is touched for one instant of a 600-second day.
  Giving night a plateau means adding keyframes, which changes what
  `preset_at()` returns to every caller; it wants its own lane.

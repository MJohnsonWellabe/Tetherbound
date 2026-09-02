# OWNER-0902-DAYNIGHT-REGRESSION

Owner-play reopening of `OWNER-0901-DAYNIGHT-CYCLE` (`ralph/OWNER_PLAYTEST_2026-09-02.md`
items 13-15, cross-referencing `ralph/OWNER_PLAYTEST_2026-09-01.md` item 11). Branch:
`ralph/OWNER-0902-DAYNIGHT-REGRESSION` off `main` (`290af7d3`). Not merged.

## What was reported

1. "Dark isn't night time any more — it basically stays dusk."
2. "The day clock often just stays on the same day. Like day 2 counts to 24, then
   starts over day 2 at 0:00" instead of advancing to Day 3.
3. Uncertainty whether either of the above shares a root cause with "creatures never
   get out of bed" and "can't place the tent and campfire."

## What `OWNER-0901-DAYNIGHT-CYCLE` changed (for context)

Landed on `main` via merge commit `bd1e930c` (2026-09-01), touching only
`scripts/world/world_look.gd` plus its own probe:

- Added `_auto_day_accum`, a real-time accumulator separate from the existing
  `_elapsed_seconds`, so `Game.day` advances automatically once `day_length_seconds`
  of real time passes, instead of only ever moving on a manual camp/bed rest.
- Set `WorldLook.process_mode = Node.PROCESS_MODE_ALWAYS` in `_ready()` so the clock
  keeps ticking while the pause menu holds `SceneTree.paused = true`, since it had
  silently been stopping every time any menu tab was open.

## Investigation method

Per the task brief, code-reading alone was explicitly rejected as sufficient (a
prior session on this project was burned by exactly that). `tools/art_pipeline/
setup.sh godot` was used to fetch a real Godot 4.7 headless binary, the project was
imported (`godot --headless --path . --import`), and three separate real
reproductions were built and actually run against the current `meadows_playground.tscn`
scene on `main`:

1. **`tools/gate_f/probe_daynight_auto_advance.gd`** (pre-existing, shipped with the
   0901 fix). Drives `WorldLook._process()` by calling it directly with synthetic
   deltas (1.0 per simulated second) for a simulated 30-minute session, then checks
   the clock keeps moving across 120 real, engine-driven frames while
   `SceneTree.paused = true`.
   **Result: PROBE PASS.** `Game.day` reached 4 (from 1) after 1800 simulated
   seconds, crossing day boundaries at exactly 600/1200/1800s as configured, and the
   clock's hour moved from 8.04 to 8.08 across the 120 paused frames.

2. **`tools/gate_f/probe_daynight_real_frames.gd`** (new). Drives the scene with
   real engine frames only (`await process_frame`, no manual `_process()` calls,
   `SceneTree` never paused), with `day_cycle.gd`'s `day_length_seconds` shrunk from
   600 to 3 real seconds in place after `_ready()` so several real day boundaries
   and a full night window are observable in under 20 real seconds instead of
   requiring the full 30+ real minutes the owner played. This is the one thing the
   pre-existing probe's check 1 never does for the day-advance path: real,
   engine-scheduled frame delivery at real wall-clock speed.
   **Result: PROBE PASS.** `Game.day` advanced 1→7 across six ~3-second real day
   boundaries, landing within ~0.1s of the exact expected wall-clock time each time
   (t=3.06s, 6.06s, 9.09s, 12.05s, 15.09s, 18.06s — a 3.0s cadence configured).
   `is_dark()` went true and stayed true through the configured window; `sun.
   light_energy` bottomed out at 0.55, exactly matching art.json's authored `night`
   preset value (not partway there, not stuck at a "dusk" value).

3. **`tools/gate_f/probe_daynight_after_rest.gd`** (new). Same real-frame drive, but
   partway through calls the actual production rest path,
   `night_rest.gd::pass_the_night()` (not a synthetic stand-in), to check whether a
   genuine rest — which calls both `Game.advance_day()` and
   `WorldLook.reset_to_morning()` together — leaves the automatic accumulator unable
   to fire again afterward. This was the one remaining production code path that
   touches the same state the automatic accumulator does, and it hadn't been
   exercised with real engine execution by either of the probes above.
   **Result: PROBE PASS.** The rest call advanced day 1→2 correctly; the automatic
   accumulator then continued firing normally, advancing day 2→7 over five further
   ~3-second boundaries at the expected cadence.

All three probes are committed on this branch and can be rerun with, e.g.:

```
godot --headless --path . --script tools/gate_f/probe_daynight_real_frames.gd
```

## What was also checked and ruled out along the way

- **Scene wiring.** `scenes/world/meadows_playground.tscn` correctly wires
  `WorldLook.sun_path = ../Sun` and `environment_path = ../WorldEnvironment` to real
  sibling `DirectionalLight3D` / `WorldEnvironment` nodes — `_apply_sun`/
  `_apply_environment` are not silently no-op-ing.
- **Export filters.** `export_presets.cfg`'s Windows preset excludes only `docs/*`
  and `*.md`; `data/config/art.json` ships in the exported PCK, so the shipped
  build is not silently falling back to whatever look is baked into the `.tscn`.
- **No other reset path.** The only callers of `WorldLook.reset_to_morning()` (which
  zeroes the automatic accumulator) in the entire non-tool codebase are
  `scripts/build/camp.gd::_pass_the_night()` and
  `scripts/world/night_rest.gd::pass_the_night()` — both real rest completions, both
  already covered by probe 3 above. No scene reload happens during ordinary play;
  the only `change_scene_to_file()` call in the project is the one-time title
  screen → world transition, so combat, building, and village entry do not tear
  down and recreate `WorldLook`.
- **`day_cycle.gd`'s own math** is separately covered by `tests/test_day_cycle.gd`
  (14 pure-logic assertions, all passing already), including the exact hour-wrap
  and keyframe-interpolation cases this regression describes.
- **`art.json`'s authored values.** The `night` keyframe (hour 0) and `dawn`
  keyframe (hour 5) are deliberately identical (see that file's own `T1-NIGHT`
  comment), so the blended clock holds at night's darkest tuning for the full
  midnight→5am window rather than drifting toward day partway through — this is
  already correct on `main` and was independently confirmed by probe 2's measured
  `sun.light_energy` bottoming exactly at the authored 0.55.

## Conclusion

**The day/night clock mechanism currently on `main` — both `day_cycle.gd`'s pure
math and `world_look.gd`'s real per-frame application of it, including through a
real rest call — is sound.** Three independent, real, engine-executed
reproductions (not code reads) all came back PASS, with no code changes made to
`world_look.gd` or `day_cycle.gd` in the process. This is a materially different
finding from "nothing to fix": it is a specific, reproducible-negative result
against the actual regression as described, obtained by genuinely running the game
logic, per the task's own instruction not to repeat the prior code-read-only
mistake.

This does **not** prove the owner's session didn't experience the described
symptom — it proves the isolated mechanism doesn't reproduce it under the
conditions this headless environment can drive (a fresh session, real frame
timing, real pause interaction, and a real rest call, sustained well past several
day boundaries). What it cannot rule out, for lack of a way to synthesize a full
real ~30-minute interactive session in this environment: cumulative effects of
sustained real player input, build/menu interaction sequences, or anything
specific to the actual Windows-exported binary the owner ran versus this headless
Linux run. If the owner reproduces this again, the next-most-valuable evidence
would be **which specific action immediately preceded the day getting stuck** —
e.g., did it happen right after a menu was closed, after combat, after an attempted
(failed) camp placement — since that would point at exactly the kind of real
interaction this investigation could not synthesize.

## Connection to the rest/camp-bed symptoms (item 15)

**Investigated and NOT the same root cause.** `complete_creature_bed_rests()`
(`autoload/game_state.gd:770`), which is what marks a resting creature `rested =
true` and clears its bed slot, is called from exactly one place in production:
inside the real rest completion (`pass_the_night()` / `camp.gd::_pass_the_night()`)
— the same function probe 3 above exercised directly and confirmed works
correctly. It is **not** gated on `Game.day` advancing or on the automatic
accumulator in any way; a creature never "gets out of bed" on its own as time
passes, only when an actual rest completes.  Separately,
`_tick_creature_bed_recovery()` heals a resting creature's HP continuously off
real elapsed time (a `full_heal_seconds` config, independent of the day/night
clock entirely) but never sets `rested = true` or frees the bed slot on its own.

So "creatures never get out of bed" traces to the **same failure as item 10** (tent
and campfire placement failing) — if no rest ever completes, `resting` never flips
back to `false` and `rested` never becomes `true`, regardless of what the day/night
clock is doing. It is a second, independent defect in the build-placement path, out
of scope for this task, not a symptom of the day/night regression investigated here.

## Files added

- `tools/gate_f/probe_daynight_real_frames.gd`
- `tools/gate_f/probe_daynight_after_rest.gd`

No production code changed.

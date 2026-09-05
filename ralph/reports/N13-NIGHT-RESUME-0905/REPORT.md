# N13-NIGHT-RESUME-0905

**Branch:** `ralph/N13-NIGHT-RESUME-0905` · **Base:** `origin/main` @ `f8a47ee4`

Resuming `ralph/briefs/0904/W15-NIGHT.md`, which pushed one investigative commit
(`45144af3`) and never reached a root cause, a fix or a report. Closing question:
OP-0904-2 / CL-O2, the owner on the shipped ROG build — **"There is no night time."**

---

## Summary

**The repo's stated hypothesis was wrong, and so was my first answer to it.**

The brief (and `CURRENT_STATE` §3, and CL-O2) all say the same thing: *"the shipped
build takes a different path to the clock than the harness does, and that gap is the
defect."* Measured on the exported release binary, that is not true. The clock is
healthy on the shipped path. So is the night look.

What is true, measured:

1. **The clock is fine on the shipped binary.** `art.json` loads from the `.pck`,
   `day_cycle.gd` is live, `day_length_seconds`/`dark_from`/`dark_to`/keyframes are
   identical to the editor's. Hypotheses 1, 2 and 5 of the original brief are dead.
2. **The night look is fine.** Midnight renders at **26% of midday's mean frame
   luma** (29.5 against 114.5), from the same camera, through the blend the running
   game actually uses. It is dark and it stays legible.
3. **`is_dark()` was nearly twice its specified length and covered the wrong hours** —
   hour 20 → 5, nine in-game hours, 225 real seconds of a 600-second day, opening at
   an hour that renders at 67% of midday. **Fixed:** 22 → 3, 125 real seconds.
4. **The `night` keyframe stood alone, so the tuned night look was never held.**
   `_apply_blended()` lerps between bracketing keyframes, so a lone keyframe is
   arrived at for one instant and left. A code-blind critic shown seven hours of one
   day named exactly ONE frame as night. **Fixed:** `night` runs hour 23 → 2 via a
   `same_as` alias keyframe, held 75 real seconds, with not one tuned value changed.
5. **The clock has no memory, and that is the largest half of OP-0904-2.** Every world
   starts at 08:00; nothing saves or restores the hour; a realm crossing, a Continue
   and a rest all put it back. Night sits at the far end of the day. **Routed — not
   fixed here, and CL-O2 is NOT closed.**

I also got this wrong once mid-lane and corrected it in-tree; that is recorded in
full under **A wrong turn, and what it cost** below, because the mistake is the same
one the whole three-round NIGHT-LIGHT history made and is worth not repeating.

---

## 1. Why W15 stalled — and why its probe could never have run

`45144af3` built `tools/gate_f/probe_daynight_exported.gd`, a `SceneTree` script
meant to be run against the exported binary with `--script`, taking the shipped
title → "Start New Game" → `change_scene_to_file()` path. It is a good probe. It
cannot work.

**Measured, both templates, this box, 2026-09-05: an exported Godot 4.7 build
silently ignores `--script`.** It boots `run/main_scene` (the title screen) and sits
there. Release template: no output for 3 minutes, process alive, zero lines from the
script. Debug template: same. No error, no warning — the flag is simply not there.

`playground_world.gd::_report_for_export_check()` already documents three sibling
traps ("a release export strips `print()`", "`--quit-after` is an editor flag and is
ignored by an export", "`--quit` exits before the terrain has finished loading"). This
is the fourth, and it is the most likely reason that lane produced one commit and
stopped: the instrument it had just built returned nothing, with no diagnostic.

I restored the probe unchanged (it documents the shipped path precisely and is the
right shape for a debug-editor run) and built the evidence a different way.

## 2. The instrument that does work on an export

`scripts/world/world_look.gd` gained a `--verify-daynight` flag reporting through
`push_warning`, the one channel that survives a release export — the same mechanism,
for the same reasons, as the `--verify-export` report next door. Run:

```
godot --headless --path . --export-release "Linux Test" build/linux/Tetherbound.x86_64
tools/stage_gdextension_libs.sh build/linux
cd build/linux && xvfb-run -a -s "-screen 0 640x480x24" \
  ./Tetherbound.x86_64 --rendering-driver opengl3 --resolution 640x480 \
  --verify-export --verify-daynight
```

**Output, from the shipped RELEASE binary** (`build/linux/run_daynight.log`, copy at
`shipped-binary-daynight.log` beside this report):

```
DAYNIGHT-CONFIG template=true debug_build=false editor_feature=false renderer=gl_compatibility
DAYNIGHT-CONFIG art.json loaded=true keys=44 cycle=live
DAYNIGHT-CONFIG day_length_seconds=600.0 dark_from=20.0 dark_to=5.0 keyframes=["night", "dawn", "day", "golden"]
EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=384468
```

That is `template=true, debug_build=false, editor_feature=false` — the real shipped
artefact, running out of its own `.pck`. It kills three of the brief's five
hypotheses outright:

- **(1) a harness-only condition gating the clock** — there is none. `grep` over
  `scripts/`, `autoload/`, `tools/` finds exactly one `Engine.is_editor_hint()` in the
  whole project (`creature_viewport.gd`) and no `OS.has_feature("editor")`, no debug
  flag, no `user://` sentinel anywhere near the cycle. The exported binary reports
  `editor_feature=false` and builds the cycle anyway.
- **(2) a resource the export does not pack** — `art.json loaded=true keys=44
  cycle=live`. It is in the pack and it parses. (Note in passing:
  `tools/verify_export.sh`'s own check for this is a false positive by construction —
  it greps the `.pck` for the literal string `data/config/art.json`, which is present
  in `world_look.gd`'s **source text** whether or not the JSON is packed. It happens
  to be packed. The check would not have told us.)
- **(5) release `project.godot` overrides** — none: no feature-tagged keys in
  `project.godot` at all, and the exported binary reports the same
  `day_length_seconds=600.0` and the same four keyframes as the editor.

**Honest limit:** `_report_for_export_check()` calls `get_tree().quit()` at the end of
`playground_world._ready()`, before a single `_process` tick, so under `--verify-export`
zero `DAYNIGHT-SAMPLE` lines are produced (`sample count: 0`). The exported binary
therefore proves the clock is correctly *constructed*, not that it *advances* over
minutes. Advancing over real engine frames is what
`tools/gate_f/probe_daynight_real_frames.gd` already proves, in the editor.

To make the export say as much as it can inside that one window, `--verify-daynight`
now also dumps `DAYNIGHT-CURVE` — the light the clock asks for at all 48 half-hours,
computed from the pack's own `art.json` through the same blend the game uses.

## 3. What the renderer actually says

`tools/gate_f/probe_daynight_contrast.gd` is new and is the measurement this project
had never made: **one world, one tripod, seven hours of the same day**, driving
`world_look.gd::_apply_blended()` under a frozen clock.

That last part matters. Every capture and survey tool in `tools/` pins a preset **by
name** with `apply_time()`. The running game never does — it lerps between the two
keyframes bracketing the current hour. So every night frame ever judged in this
project is a frame the game draws for one instant of a 600-second day.

Command (960×540, software GL, Compatibility — same instrument as every previous
night judgement here, so the numbers are comparable to theirs):

```
xvfb-run -a -s "-screen 0 960x540x24" godot --path . --rendering-driver opengl3 \
  --resolution 960x540 --script tools/gate_f/probe_daynight_contrast.gd -- --out=DIR
```

**Result on unmodified `main`** (`contrast-stats.csv` beside this report):

| hour | blend | asked light | mean luma | p01 | p99 | vs midday |
|---|---|---|---|---|---|---|
| 8.0 | day→golden 0.00 | 1.866 | **114.5** | 23.3 | 193.6 | 1.000 |
| 12.0 | day→golden 0.40 | 1.569 | 104.5 | 23.5 | 191.8 | 0.913 |
| 18.0 | golden→night 0.00 | 1.203 | 90.5 | 19.9 | 181.0 | 0.790 |
| 20.0 | golden→night 0.33 | 1.491 | 77.0 | 14.9 | 163.0 | 0.672 |
| 22.0 | golden→night 0.67 | 1.785 | 54.7 | 6.4 | 124.3 | 0.478 |
| 0.0 | night→dawn 0.00 | 2.100 | **29.5** | 0.0 | 77.9 | **0.258** |
| 3.0 | night→dawn 0.60 | 1.443 | 43.2 | 1.1 | 113.2 | 0.377 |

**Midnight renders at 26% of midday.** Night works. The genuinely dark part of the
sweep — below half of midday — runs from about hour 21.7 to about 2.6, roughly 4.9
in-game hours, **≈122 real seconds**, which is `docs/prompts/07-RG21-continuous-day-night-short-night.md`'s
"about 2 real minutes" almost exactly. The *picture* already met its spec.

## 4. First defect fixed — `is_dark()` covered the wrong hours

`is_dark()` did not.

`day_cycle.gd::is_dark()` is not a description of the sky — it is the switch for
every torch (`torch.gd`), every camp fill light (`camp_fill_light.gd`,
`campfire_glow.gd`) and `creature_body.gd`'s night emission floor. RG21 is explicit
about what it should cover:

> Approximately 2 real minutes are genuinely dark night. … Dawn and dusk are
> transition periods, not part of the 2-minute fully dark window. … `is_dark()`
> remains a gameplay/presentation semantic for the actual dark-night window; it
> should not simply return true for the entire dusk/dawn blend.

Shipped: `dark_from_hour: 20.0`, `dark_to_hour: 5.0` — **nine in-game hours, 225 real
seconds, 3.75 minutes of a 10-minute day**, opening at an hour the table above puts
at 67% of midday and closing after dawn is underway. Nearly twice the specified
length, and covering both transitions it was told not to cover.

The player-facing consequence, and why this belongs to OP-0904-2 rather than being a
tidy-up: for almost four minutes of every ten the *systems* announced night — torches
lit, camp lights on, creatures glowing — over a late-afternoon sky. By the time the
two minutes that genuinely are night arrived, everything that would have marked them
had been on for a minute and a half already. Night stopped being an event.

**Landed:**

```
dark_from_hour  20.0 -> 22.0
dark_to_hour     5.0 ->  3.0      (5 in-game hours = 125 real seconds)
```

Both endpoints render below half of midday; the transitions either side stay
transitions. **The night preset itself is untouched** — NIGHT-LIGHT's
`exposure`/`ambient_energy`/`sun.energy`/`adjustment_saturation` and
NIGHT-LEGIBILITY's `camp_fill_energy` 2.4 / `creature_emission_floor` 0.22 are all
exactly as they were, as the brief requires.

## 4b. Second defect fixed — the night look was never held

This one came from the blind judge (§7, round 1) and no number had found it.

Shown the seven-hour sheet shuffled and lettered, told nothing, the critic ranked all
seven frames by brightness in **exactly** the order the instrument measured — and then
named **exactly one** as night: hour 0. Of hour 22, at 54.7, it said *"a player would
say it has got dark, not it is night."* It matched hour 0's mean of 29.9 against the
key art's own night panel at 32.9 unprompted.

One instant of night per ten minutes. And that is a **shape** problem, not a tuning
one: `_apply_blended()` lerps between the two keyframes bracketing the current hour,
so a keyframe standing **alone** is arrived at for one instant and left again. `night`
stood alone at hour 0. The look NIGHT-LIGHT tuned across three judged rounds, and that
NIGHT-LEGIBILITY measured camp lights and creature emission floors against, was
therefore **never actually held on screen in play**. No value inside the preset can
fix a preset that is never held.

Holding a look needs a second keyframe carrying the same values — and writing those
values twice is how two copies silently disagree later, which `world_look.gd`'s own
`_merged()` comment already warns about for exactly this reason. So a `times` entry
may now say `"same_as": "<other entry>"` and inherit it whole
(`world_look.gd::_preset_over()`, used by both `_apply_blended()` and `apply_time()`).

**Landed:**

```
night.hour   0.0 -> 23.0
+ night_end  hour 2.0, "same_as": "night"
```

Night now **holds for three in-game hours — 75 real seconds** — inside the 125-second
`is_dark()` window, with a 25-second ramp either side. Moving the start earlier also
darkens the approach: hour 22 sat 67% of the way from golden to night and now sits 80%.
**Not one tuned number changed.**

### The round that got it wrong, and the correction

`night_end` first went in at **hour 2.0**. Round 2 of the blind judging (§7) confirmed
both things it was for and then caught a cost I had not measured: hour 3 lost its
sunrise. Hour 3 sits just *outside* the dark window and used to blend night→dawn at
t=0.60; holding night to hour 2 dropped it to t=0.33. **The night was eating the dawn
ramp**, and a blind viewer preferred the unfixed tree because of it. `night_end` moved
to **hour 1.0** — t back to 0.50, night still held 50 real seconds across 23→1.

Measured, same camera, same seven hours, all three trees (mean frame luma):

| hour | base | `night_end`@2 | **landed** (`night_end`@1) |
|---|---|---|---|
| 8.0 | 114.54 | 114.54 | 114.69 |
| 12.0 | 104.54 | 104.56 | 104.51 |
| 18.0 | 90.46 | 90.55 | 90.69 |
| 20.0 | 77.00 | 73.14 | 73.14 |
| 22.0 | 54.70 | 44.87 | **44.91** |
| 0.0 | 29.50 | 29.49 | **29.51** |
| 3.0 | 43.21 | 38.91 | **41.99** |

Day is unchanged to three significant figures across all three; midnight is unchanged;
hour 22 keeps the full 18% it gained; and hour 3 recovers to 97% of its original value.
Only the hours the edit was aimed at moved, which is both the intended result and the
check that nothing leaked.

The residual ±0.15 on hours 8/12/18 is capture-to-capture vegetation sway — round 2's
judge measured the same thing independently and named it: *"every non-zero pixel sits on
a cloud edge or a grass-blade tip… wind and vegetation sway between two captures, not a
lighting change."*

## 5. The largest half — routed, not fixed

**The in-game clock has no memory of any kind.**

- `world_look.gd::_ready()` ends in `apply_time("day")`, which pins
  `_elapsed_seconds` to hour 8. Every world, every time.
- `scripts/save/save_game.gd` has **no clock key at all** — no elapsed, no hour, no
  time-of-day. `grep -in "elapsed\|hour\|clock\|day_cycle\|time_of_day"` over its 1013
  lines returns three comments about unrelated respawn timers and nothing else.
- `game_state.gd::enter_realm()` autosaves and calls `change_scene_to_file()`; the
  title screen's Load does the same. Both build a fresh `WorldLook` → 08:00.
- `night_rest.gd` and `player_bed.gd` call `reset_to_morning()` → 08:00. That one is
  by design.

Night begins 350 real seconds into an unbroken run in one scene. **Anything that
rebuilds the scene, and anything the player does to rest, puts the clock back to
morning and restarts that 350-second walk.** The harness always instantiates the world
once and lets it run, which is exactly why every probe passes. A player crossing a
realm boundary, sleeping when hurt, or continuing a save does not — and can play for
hours without the clock ever reaching hour 22.

That is the shape the brief predicted ("the shipped build reaches the clock by a
different path than the harness does"). It just is not the clock that is broken —
it is that the shipped path keeps restarting it.

**Routed, not fixed.** RG21's own edge-case list already asks for it ("Loading a save
at any time of day"). The fix is one persisted float:

- `scripts/save/save_game.gd` — save and restore the elapsed clock (**not this lane's
  file**).
- `autoload/game_state.gd` — carry it across `enter_realm()`'s
  `change_scene_to_file()`, and clear it on New Game so a fresh game still starts at
  morning (**not this lane's file**).
- `scripts/world/world_look.gd` — read it in `_ready()` instead of unconditionally
  applying `DEFAULT_TIME` (this lane's file; the one-line half, waiting on the other
  two).

I considered doing the session half alone from `world_look.gd` with a `static var`
(the same static-carry pattern this file already uses for the emission-floor setters).
I did not, and the reason is specific: a static would also survive **New Game**, so a
player who reached 23:00, quit to the title and started a fresh game would begin it at
23:00. Distinguishing that needs a reset hook on `game_state.gd`, which this lane does
not own. Half a fix that introduces a new defect is worse than a routed one.

## 6. A wrong turn, and what it cost

Recorded because it is the same mistake NIGHT-LIGHT made three times.

My first instrument, `light_budget_at()`, multiplied each light's `energy` by
`tonemap_exposure` — correct, and the thing no previous probe did — but ignored each
light's **colour**. Night's light is a dark blue (`ambient_colour` #3d50a3, Rec.709
luma 0.32); day's is near-white (#9db3c6, 0.69). Colour-blind, the arithmetic said
midnight asked for 2.100 against midday's 1.866 and I concluded night was 12.5%
*brighter* than noon — "there is no night time", apparently proven. I wrote the fix,
made the test go red then green, and committed it (`55fd5ae4`).

The renderer disagreed by a factor of four. **The frames are what caught it**, and
only because the contrast probe shoots day and night from the same tripod — which is
the entire point of §7's rule and precisely what no previous night pass ever did.
`55fd5ae4` is reverted in `5fa4a81b`; `light_budget_at()` and
`tools/_daynight_curve.py` now weight both terms by colour luma and land at
night/day 0.647, on the same side of 1.0 as the picture.

The general form: **a number that disagrees with the render is not a stricter
measurement, it is a broken one.** The instrument gets checked against pixels before
anything is concluded from it, let alone changed.

## 7. Blind judge

Code-blind sub-agent (`opus`), given only the contact sheet, `docs/reference/` and
`.claude/skills/visual-judge/SKILL.md`, told nothing about what changed or what I
hoped it would say. The sheet is **shuffled and lettered A–G**, not labelled by hour —
an hour label tells the judge which frame is supposed to be the night one, which is
the question. Key withheld from the judge, in
`_sheet_blind.png.key.txt` beside this report.

Sheet: `_sheet_blind.png`. Verdict: `blind-judge-verdict.md`.

Two rounds. Full excerpts, with the quotes verbatim, in
`blind-judge-verdicts.md` beside this report. In short:

**Round 1** (base tree, seven hours shuffled A–G) ranked the frames by brightness in
*exactly* the order the instrument measured, having never seen it — then named **one**
frame of seven as night (hour 0, matching its mean of 29.9 against the key art's own
night panel at 32.9) and said of hour 22 *"a player would say it's got dark, not it is
night."* **That verdict is what produced the second fix in §4b**; no number I had
found it.

**Round 2** (base vs fixed, two unlabelled rows) confirmed midnight is *pixel-identical*
between them (*"mean abs diff 0.51/255, ground-band diff 0.05"*) and that hours 8, 12
and 18 differ only by *"wind and vegetation sway between two captures, not a lighting
change"* — the tuned night and the whole day preserved exactly, as the brief requires.
It found no crushing, no new artifact and no regression in legibility.

It also **caught a real regression I had not measured**: holding night to hour 2 ate the
dawn ramp, and it called the base's hour 3 *"the only frame in the whole sheet with an
actual sunset in it"* against mine, *"the same scene with the colour drained out"* — and
marked the **base** as the better progression for that reason. Fixed by pulling
`night_end` from hour 2.0 to 1.0 (`e88a4f35`); hour 3 returns to a 0.50 blend toward
dawn and night still holds 50 real seconds.

Round 2 additionally named, in **both** rows equally and therefore not from this lane:
no moon, no stars, day-lit cloud tops, and *"no moonlight colour anywhere — the build's
darkest state is the day palette multiplied down; the reference's is the day palette
shifted cool"* (night ground RGB 17.3/22.4/**6.6** against the reference's
17/28/**31**). Real, numbered, and **routed** — it lives in the night `sky` block and
`ambient_colour`, which this lane's brief forbids touching.

## 8. Files changed

| File | What |
|---|---|
| `data/config/art.json` | `dark_from_hour` 20→22, `dark_to_hour` 5→3; `night.hour` 0→23 plus a `night_end` alias keyframe at hour 2. Every tuned value untouched. Each change carries its measurement in its own comment. |
| `scripts/world/world_look.gd` | `blended_config_at()` / `light_budget_at()` extracted static and config-in (same numbers, `_apply_blended()` now calls them); colour-weighted light budget; `_preset_over()` `same_as` inheritance; `--verify-daynight` export report. |
| `tests/test_day_cycle_night_contrast.gd` | New. RG21's acceptance criteria as unit tests. |
| `tools/gate_f/probe_daynight_contrast.gd` | New. Day-vs-night from one tripod through the real blend. |
| `tools/gate_f/probe_daynight_exported.gd` | Restored from `45144af3` unchanged. |
| `tools/_daynight_curve.py` | New. The blend's asked-for light, hour by hour, off the real `art.json`. |
| `tools/_daynight_contact_sheet.py` | New. Contact sheet, with a shuffled blind mode. |
| `docs/decisions/D87-...md` | New. |
| `docs/CURRENT_STATE.md` | Night row rewritten. |
| `docs/GAMEPLAY_SYSTEMS.md` | Day/night section: the two facts above. |

**Not touched, deliberately:** `camp_fill_light.gd`, `creature_body.gd`, the
`art.json` night values NIGHT-LEGIBILITY tuned, `export_presets.cfg` and
`tools/verify_export.sh` (hypothesis 2 was disproved, so the brief's condition for
touching them was not met — though `verify_export.sh`'s art.json check is noted above
as unable to do its job), `save_game.gd`, `game_state.gd`.

## 9. Verification

All commands run from the repo root with `export PATH=$HOME/godot-bin:$PATH`, Godot
4.7.stable (installed per `ralph/briefs/0904/COMMON.md`).

**Unit tests**

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_day_cycle
  16 tests, 58 assertions, 0 failed
```

`test_day_cycle_night_contrast.gd`, run against `data/config/art.json` as it is on
`origin/main` (checked out over the fixed one, then restored), **red for the right
reasons** — the discipline `COMMON.md` asks for, seen fail before it was trusted green:

```
  FAIL  test_true_dark_is_about_two_real_minutes_of_the_ten_minute_day
        expected 90.000000..160.000000, got 225.000000
  FAIL  test_the_night_look_is_held_across_the_middle_of_the_night_not_merely_touched
        expected true, got false  (the night look holds still for 0.0 in-game hours
        = 0 real seconds; a keyframe with no second hour is reached for an instant
        and left, so the tuned night is never actually on screen)
  4 tests, 23 assertions, 2 failed
```

An earlier draft of the plateau test used a 1% tolerance for "held" and **passed on the
very data it exists to fail** — sun, ambient and exposure move in opposite directions
across a lone keyframe and cancel to under 1% for a step either side. It measures exact
equality now, which is what a genuinely held look produces (the blend lerps between two
identical dicts). That is recorded in the test's own comment.

**Adjacent unit tests** — everything that reads `world_look.gd`, `art.json`'s day
cycle, the HUD clock readout, weather or the audio day/night table:

```
godot --headless --path . --script tests/run_tests.gd -- \
  --only=test_gate_f_instrumentation.gd,test_spawns_data.gd,test_hud_widgets.gd,\
         test_world_weather.gd,test_audio.gd
  107 tests, 43853 assertions, 0 failed
```

**Smoke tests**

```
godot --headless --path . --script tests/smoke_night_ecology.gd
  night ecology smoke test passed          (rc 0)
godot --headless --path . --script tests/smoke_gate_f_probe.gd
  gate-f probe: OK -- every accessor agreed with the live game it reads   (rc 0)
```

`smoke_night_ecology` is the one that could have been broken by narrowing `is_dark()`,
since it is entirely about night-gated spawns. Its every reported figure is identical
before and after: `night-gated clusters in bands 0/1: 5 (12 individuals)`, `night bodies
standing in the world: 12`, `by day: 12/12 hidden`, `at night: 12/12 present`, and the
same duskhush offering the same engage prompt after dark.

**The `ERROR:` count, honestly.** Baseline (`origin/main`'s `art.json`) produced **1**
`ERROR:` line; the fixed tree produced **2** in one run. The distinct-signature SET did
not grow — both are the same `material_get_instance_shader_parameters` message from the
dummy renderer under `--headless`. The first is on `playground_world.gd::_build_terrain`
and appears in both. The second is on
`encounter_director.gd::_make_alpha -> _stand_on_ground`, an alpha-creature spawn path
with no dependence on `is_dark()`, the dark window, or any value this lane touched, and
one that plausibly varies with spawn RNG. I did not prove the variance across enough
runs to call it noise outright, so it is stated as what it is: **one extra instance of
an existing signature, on a code path unrelated to this change, not chased.**

**Exported release binary** — see §2. `EXPORT-CHECK terrain=yes ground_at_spawn=0.90
player_y=2.90 props=384468`, and the day/night report before and after in
`shipped-binary-daynight.log`. The `after` run reports
`keyframes=["night_end", "dawn", "day", "golden", "night"]` and
`dark_from=22.0 dark_to=3.0`, so both fixes are demonstrably live **in the shipped
artefact**, out of its own `.pck`, not just in the editor.

**Rendered frames** — `tools/gate_f/probe_daynight_contrast.gd`, 960×540, software GL,
Compatibility (D06/D01), three full runs: base tree, plateau-at-hour-2, and the landed
tree. Numbers in `contrast-stats-before.csv` / `contrast-stats-after.csv`.

## 10. Known limitations, and what I deliberately did not do

- **CL-O2 is not closed.** §5 is the larger half and it is routed, not fixed.
- **No `--time-scale` setting was added.** The original brief asks for one *"if the
  cause is genuinely hardware-only after all five hypotheses are eliminated"*. It is
  not hardware-only — the causes are in the repo and named above — so that fallback
  clause does not apply, and adding a player-facing setting on top of a real diagnosis
  would be noise.
- **`preset_at()`/`time_of_day()` can now return `"night_end"`.** Checked before
  landing: nothing in the project branches on the preset NAME for gameplay —
  `encounter_director.gd::_gate_active` and `world_audio.gd` both go through
  `is_dark()`, `playground_hud.gd` prints `Day N · HH:MM` and never the preset name,
  and `camp_fill_light.gd` reads `times.night` by name, which still exists and is
  unchanged. Every tool that pins a preset by name (`tools/survey.gd`, the capture
  scripts, `smoke_playground`, `smoke_gate_a_rest_torch`, `smoke_night_ecology`) asks
  for `"night"`, which is still there and still means the same thing. A future caller
  that wants "is it the night look" should ask `is_dark()`, not compare the name.
- **The night plateau is 75 seconds, not the full 125.** The 25-second ramps either
  side are deliberate (RG21 forbids a hard snap) but it does mean the fully-arrived
  night is still a minority of the dark window. Whether 3 in-game hours is the right
  hold is the dial, and it is TUNABLE in `art.json` with no code change.
- **No exported-binary run observes the clock over minutes** — see §2's honest limit.
- **`--verify-daynight`'s sample path is effectively untested**, for the same reason:
  under `--verify-export` the process quits before `_process` runs. It is exercised in
  the editor only.
- **Software GL, Compatibility renderer** (D06/D01) for every rendered number here —
  the same instrument as all prior night work in this project, but not the owner's
  hardware.
- **One error-count wobble** in `smoke_night_ecology`, detailed in §9.

## 11. Routed findings — for other lanes, not touched here

1. **The clock is never persisted.** `save_game.gd` (no clock key at all) and
   `game_state.gd` (`enter_realm()` rebuilds the scene). One float. **This is the
   largest remaining half of OP-0904-2 / CL-O2** — see §5 for the full mechanism and
   why doing the session half alone from `world_look.gd` would have introduced a New
   Game defect.
2. **Night has no moon, no stars, and no moonlight colour.** Round 2's blind judge,
   measuring both trees equally: night ground RGB(17.3, 22.4, **6.6**) against the key
   art night panel's RGB(17, 28, **31**) — *"the build's darkest state is the day
   palette multiplied down; the reference's is the day palette shifted cool"* — plus
   *"no moon, no stars, day-lit cloud tops"* and cloud-to-sky contrast identical across
   all seven hours, so clouds stay brighter than the sky at night. Lives in `art.json`'s
   night `sky` block and `ambient_colour`, which this lane's brief explicitly forbids
   touching. **For the next night-art lane.**
3. **A bush renders as a featureless black hole at every hour, midday included.**
   Round 1: RGB(0.1, 1.3, 9.4) at night and still RGB(18, 23, 13) at midday while
   everything around it is at 90–110. *"That is not a night problem; it is a shading
   problem on that asset."* Vegetation/material owner.
4. **`tools/verify_export.sh`'s "data loaded by string path is in the pack" check cannot
   fail for a path a script mentions.** It greps the `.pck` for the literal path, which
   is present in the referencing script's own source text whether or not the data file
   was packed. `data/config/art.json` happens to be packed — the check would not have
   told us either way. The brief scoped that file to this lane *only if* hypothesis 2
   was confirmed; it was disproved, so it is left alone and routed.
5. **`--verify-export` quits before any `_process` tick**, so no exported-binary harness
   in this project can observe anything that changes over time. `playground_world.gd`.

## 12. Final state

COMMIT_PLACEHOLDER

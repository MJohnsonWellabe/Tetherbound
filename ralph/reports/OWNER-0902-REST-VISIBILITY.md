# OWNER-0902-REST-VISIBILITY

Branch: `ralph/OWNER-0902-REST-VISIBILITY` off `main` (`38147fca`). Not merged.

Two halves of one system, per the task brief, in order.

## Half 1: does a creature rest actually complete end to end?

Owner playtest 2026-09-02, finding 15, verbatim: *"Creatures never get out of
bed / never appear rested."* `OWNER-0902-DAYNIGHT-REGRESSION` cleared the
day/night clock and traced the symptom to the build-placement path instead.
`OWNER-0902-TENT-CAMPFIRE-PLACEMENT` and `OWNER-0902-CAMP-SPLIT` then landed
real fixes to that path, but nobody had run an actual rest cycle since.

### What existed already

`tools/_probe_camp_split.gd` (landed with `OWNER-0902-CAMP-SPLIT`) places all
four camp pieces through the real catalogue+placer path and proves the
bedroll's own "Rest until morning" interaction heals the trainer and advances
the day. It never assigns a creature to the `creature_bed` at all — the exact
half of the owner's complaint about a creature going into a bed was never
exercised by any existing test or probe.

### What this task added and ran

`tools/gate_f/probe_rest_cycle_e2e.gd`, a new real-execution probe. It boots
`meadows_playground.tscn` for real, places a `creature_bed` and a `bedroll`
through the real catalogue+placer path (same mechanism `_probe_camp_split.gd`
already validated), seeds a starter creature, faints it (`hp = 0`,
`fainted = true` — the worst-case version of "never gets out of bed"), then
drives the full loop through the real production interaction path:

1. Walks to the `creature_bed`, fires its real `Interactable.activated`
   signal (the same signal a controller `interact` press fires) — confirms
   `creature_bed_panel.gd` actually opens.
2. Calls `assign_creature(0)` (what pressing the panel's own row button does)
   — confirms the creature is marked `resting`.
3. Walks to the `bedroll`, fires its real `Interactable.activated` signal,
   waits out the real fade/`_pass_the_night()` sequence.
4. Reads the creature's real state afterward, and separately reads the exact
   string `tab_creatures.gd`'s own team-menu row would display for it
   (`creature_condition.gd::label()`), so the check is against what a player
   actually sees, not just internal flags.

**Result: PROBE PASS**, run twice for real on current `main` (first run
failed only because the fresh boot's party was empty — a probe setup gap,
fixed by seeding a starter the same way other Gate F probes do). Full output:

```
creature before rest: Terrapup fainted=true hp=0.0/120.0
creature_bed's Rest prompt opened the real rest panel
assign_creature(0) returned: true
[player_bed] rested; day 2

creature after rest: Terrapup fainted=false resting=false rested=true hp=120.0/120.0 rest_bed_index=-1
tab_creatures.gd condition line would read: "Rested · Fed · Happy"

REST CYCLE E2E PROBE: PASS
```

### Conclusion

**The rest cycle works correctly end to end on current `main`**, through the
real production interaction path, for the harshest case (a fainted creature).
The bed/bedroll fixes that landed since the original report
(`OWNER-0902-TENT-CAMPFIRE-PLACEMENT`, `OWNER-0902-CAMP-SPLIT`) do carry
through: a creature assigned to a `creature_bed` and then slept past at a
`bedroll` genuinely wakes — un-fainted, full HP, `resting = false`,
`rested = true` — and reads "Rested" on the real menu the player would check.
This is a reproducible-negative result obtained by actually running the game
logic (per `conventions.md`'s standing rule against a code-read-only
conclusion), not an inference from the earlier fixes' own commit messages.

This does not prove the owner's specific session never hit the symptom (a
build-placement failure upstream of this loop — never actually reaching a
placed `creature_bed`/`bedroll` at all — remains a separate possibility this
probe does not exercise, since it plants both pieces directly rather than
replaying a full build sequence). But the rest MECHANISM itself, once a
creature is actually assigned and the player actually sleeps, is sound.

### Related item checked, not fixed (per the task brief: observe only)

09-01 finding 9, *"Creatures don't lie down in bed except galecrest"* —
`OWNER-0901-CREATURE-BED-POSE` landed `play_rest()` (`creature_bed.gd`),
which reuses every species' existing `faint` clip and rolls the model onto
its side by `species.json`'s `rest_roll_deg` (or a default). Bramblebun and
veridian were named in that task's own header as knowingly left imperfect.
Not independently re-rendered this session — the visual-affecting budget here
went to Half 2's own render (below) — so this is unchanged from the prior
report, not a new finding.

## Half 2: rest-progress indicator

Owner playtest 2026-09-02, finding 7, verbatim: *"No way to tell when a
creature finishes resting."* Wants an indicator, "in the menu or elsewhere,"
showing rest progress or time remaining. Not started before this task.

### What actually drives "how much longer"

A creature in a `creature_bed` heals continuously off real elapsed time
(`game_state.gd::_tick_creature_bed_recovery`, `data/config/progression.json`'s
`creature_bed.full_heal_seconds`, default 120s) — that is the bed's own real
clock, independent of anything else. Sleeping at a `bedroll` always completes
an occupied bed's rest instantly regardless of that clock. So "time
remaining" has an honest, truthful answer (time until the HP-recovery clock
reaches full) and an honest edge case (a creature already at full HP is not
"done resting" until the player actually sleeps).

### What was added

- `scripts/creatures/progression.gd`: two new pure functions —
  `creature_bed_full_heal_seconds(cfg)` (centralizes the config lookup
  `game_state.gd` used to inline) and `rest_seconds_remaining(creature, cfg)`
  (the exact inverse of `_tick_creature_bed_recovery`'s own per-second heal
  rate, `max_hp / full_heal_seconds`). `game_state.gd`'s tick loop now calls
  the same helper instead of carrying its own copy of the `120.0` default, so
  a UI reading this number can never drift from what the tick loop actually
  does — retuning `full_heal_seconds` in data moves both automatically.
  `tests/test_progression.gd` covers the new functions, including a test that
  ticks the reported remaining seconds forward through the real heal-rate
  formula and asserts it lands exactly at full HP.
- `scripts/ui/creature_bed_panel.gd`: the per-row status text for the
  occupant of the bed a player is standing at now reads
  `"Resting — HP 40 / 120 · 1:20 left"` (or `"...ready — sleep to complete
  the rest"` once the HP clock has finished but the player has not yet
  slept). This is the moment a player is most likely to ask the question —
  standing at the bed — so the answer lives here first.
- `scripts/ui/tab_creatures.gd`: the team roster's existing per-creature
  condition line (previously "Tired"/"Rested"/"KO", `creature_condition.gd`'s
  own `label()`) now shows `"Resting — 1:20 left"` for a currently-resting
  creature, ahead of the KO branch (a creature can be fainted AND resting at
  once — a bed heals a fainted pal in place — and the resting readout is the
  more actionable one while that's true). **This is "the menu" the owner
  explicitly named as an acceptable home** — reachable from anywhere via the
  pause menu, not just standing at the bed, and it already existed rather
  than being a new widget.

### Why not a third, always-on-screen widget

`party_strip.gd` (the always-visible exploration HUD roster) already carries
a `resting` state — a "REST" tag plus the creature's own live HP bar, which
doubles as an at-a-glance recovery-progress bar since the tick loop drives
both this widget's number and the creature's real HP. Adding a THIRD
countdown display there was considered and dropped: `party_strip.gd`'s own
header is explicit that its five rows are a fixed, tightly-measured contract
(`ROW_SIZE`, `TOTAL_HEIGHT`) that a recent task (`OWNER-0902-HUD-TEAM-MENU`)
already had to re-fit once this same day. A third number crammed into an
already-tight one-line row risks exactly the kind of layout regression that
task fixed, for a question the two new surfaces above already answer
precisely. The player has an existing coarse always-on signal (the strip's
HP bar + REST tag) and two new precise on-demand answers (at the bed; in the
menu) — that split matches "the smallest thing that genuinely answers 'how
much longer' at the moment a player asks it" without touching HUD layout
already fixed once today.

### Controller-first

Both surfaces are existing menu text, unchanged in layout or focus behaviour
— `creature_bed_panel.gd`'s row buttons and `tab_creatures.gd`'s roster rows
keep their existing `grab_focus()`/stick-navigation wiring untouched; only
the string and colour of an existing `Label` changed on each.

### Verification

- `tests/test_progression.gd` — 44 tests, 113 assertions, 0 failed
  (`--only=test_progression.gd`), including the new rest-seconds-remaining
  coverage.
- Regression pass on touched systems — `test_fainting.gd`, `test_hud_widgets.gd`,
  `test_camp_supply_reaches_every_band.gd` — 51 tests, 1207 assertions,
  0 failed.
- A load/parse check confirmed all four edited scripts (`progression.gd`,
  `tab_creatures.gd`, `creature_bed_panel.gd`, `game_state.gd`) still parse
  clean.
- Real headless render: `tools/gate_f/capture_rest_progress_indicator.gd`,
  run at the real ROG Ally handheld resolution (1280x800), boots the real
  Meadows world, places a real `creature_bed` through the real
  catalogue+placer path, puts a real creature at 40/120 HP mid-rest in it,
  and photographs both new surfaces: standing at the bed with the rest panel
  open, and the pause menu's Creatures tab. See `shots/_diag/rest_bed_panel.png`
  and `shots/_diag/rest_team_menu.png` (not committed — diagnostic capture
  output, same convention every other `tools/capture_*.gd`/`tools/_capture_*.gd`
  script in this repo already follows).

## Commands to reproduce

```
godot --headless --path . --script tools/gate_f/probe_rest_cycle_e2e.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_progression.gd
xvfb-run -a -s "-screen 0 1280x800x24" \
  godot --path . --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/gate_f/capture_rest_progress_indicator.gd
```

## Files changed

- `tools/gate_f/probe_rest_cycle_e2e.gd` (new)
- `tools/gate_f/capture_rest_progress_indicator.gd` (new)
- `scripts/creatures/progression.gd`
- `autoload/game_state.gd`
- `scripts/ui/creature_bed_panel.gd`
- `scripts/ui/tab_creatures.gd`
- `tests/test_progression.gd`

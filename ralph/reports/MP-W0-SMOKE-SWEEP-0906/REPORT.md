# MP-W0-SMOKE-SWEEP-0906 — report

**Lane:** Stage B Wave 0 full smoke sweep + jump-in-bed diagnosis (measurement lane, no fixes) ·
**Branch:** `ralph/MP-W0-SMOKE-SWEEP-0906` from `claude/tetherbound-roadmap-next-jrcjs8` at `64cd87f7`
(the Wave 0 head) · **Base for "also fails on main" checks:** `main` at `55c64aaa`, in a separate
worktree · **Kind:** measurement (one sweep, one probe, this report) · **Godot:** 4.7-stable
official (`5b4e0cb0f`), headless, fresh import ×2 with zero `SCRIPT ERROR`/`Parse Error` lines on
both trees · **Box:** own container, 4 cores, 15 GB.

## One line per item, up front

| Item | Verdict |
|---|---|
| 1 Full sweep of every `tests/smoke_*.gd` (149, `smoke_net_*` excluded by the runner) on `64cd87f7` | SWEEP_VERDICT_PLACEHOLDER |
| 1a Non-zero exits, each re-run on `main` `55c64aaa` | NONZERO_PLACEHOLDER |
| 1b Distinct `^ERROR:` lines that appear only on the wave head | NEWERR_PLACEHOLDER |
| 2 Why `jump` "never fires" in the wake-in-bed beat | **not a game bug and not a gate** — the jump fires on the physics tick after the injected edge; the earlier lane sampled too late. Probe committed as `tools/_probe_jump_in_bed.gd`. |

## Commands

```
~/godot-bin/godot --headless --path . --import || true ; ~/godot-bin/godot --headless --path . --import   (both trees: 0 script/parse errors)
GODOT_BIN=~/godot-bin/godot tools/run_all_smokes.sh --outdir=/tmp/sweep                               (SUMMARY.md committed beside this file)
XDG_DATA_HOME=$(mktemp -d) ~/godot-bin/godot --headless --path . --script tools/_probe_jump_in_bed.gd  (exit 0, three scenarios, log excerpts below)
```

## Task 1 — the sweep

SWEEP_NARRATIVE_PLACEHOLDER

## Task 2 — jump in bed

**Verdict.** No line in `player_controller.gd` refuses the jump. On a fresh New Game, lying in
the bed on the `wake` beat, an injected `jump` edge makes `_try_jump()` fire on the **next**
physics tick: stamina drops by the configured 8, `velocity.y` reads +8.379 (the derived launch
velocity for a 1.35 m jump under 26 m/s² gravity), `is_on_floor()` goes false, and the trainer
rises about 0.5 m, meets the loft ceiling (velocity zeroed on the fifth airborne frame), falls,
and lands back on the mattress 16 physics frames after launch. A real player on a controller is
**not affected**: their button reaches the controller through exactly the path the probe's
flushed event takes, one tick after the hardware edge, which is the engine's normal latency for
every action in the game.

**What the earlier lane saw, and why.** Lane 0.F's smoke checked "position moved" after a
`press jump` whose only effect is a vertical hop that lands on the same spot, with a TCP round
trip between the press and each `probe`; its later note that `_try_jump` "never sets
`velocity.y`" was read the same way, after the 16-frame flight had already ended. Its other
observation, that `Input.is_action_just_pressed("jump")` read true "immediately after
`_press_edge`" and false one frame later, is the process-frame half of Godot's just-pressed
bookkeeping and says nothing about the physics-frame half the controller polls (see the engine
note below). The lane was measuring in the wrong frame, not looking at a broken gate.

**The engine fact that explains every row.** Godot 4.7 `core/input/input.cpp`:

- `Input::action_press` stamps `pressed_physics_frame = get_physics_frames() + 1`, with the
  in-source comment "As input may come in part way through a physics tick, the earliest we can
  react to it is the next physics tick", while `pressed_process_frame` is stamped with the
  *current* process frame. So right after injection `is_action_just_pressed` is true from a
  process-frame context and false from a physics-frame one, and becomes true for
  `_physics_process` pollers on the following tick.
- `Input::parse_input_event` queues the `InputEventJoypadButton` under `use_accumulated_input`
  (default on) and `flush_buffered_events` delivers it at the top of the next main-loop
  iteration, before that iteration's physics steps, which stamps the same next tick.

`player_controller.gd::_track_airborne` (line 680) polls `is_action_just_pressed("jump")` from
`_physics_process`, so it sees the press one tick after the injecting callback; on that tick it
zeroes `_jump_buffered_for`, and `_try_jump` (lines 768–779) passes all three gates —
`_locomotion_enabled and not input_owned` (769), `grounded_enough and asked_recently` (771–773),
`vitals.try_spend_jump()` (775) — and launches at line 777.

**Probe rows** (`tools/_probe_jump_in_bed.gd`; boots `meadows_playground.tscn` like
`smoke_playground.gd`, settles 240 physics frames, injects `JOY_BUTTON_A` via
`Input.parse_input_event` paired with `Input.action_press` exactly as `peer_runner.gd::_press_edge`
does, holds 4 ticks, prints one row per physics tick; `jp` is `is_action_just_pressed("jump")`
read at the top of that tick; `jbuf`/`airborne` are the controller's privates read with `get()`).
Scenario A, lying in bed, edge injected from the `physics_frame` signal:

```
settled after 240 physics frames. beat=wake fading=false jump_velocity=8.379 buffer_time=0.120 coyote_time=0.120 jump_cost=8.0
player at (-25.4, 4.950128, -15.7)
frame | on_floor | vel.y   | loco | carried | lying | lift  | fading | beat | owner | stamina | jbuf | airborne | jp    | try_jump
settled 0 | true  |  +0.000 | true | false | true | 0.080 | false | wake | none | 100.00 | INF |  0.000 | false | -
  [press jump on physics frame 0/engine 240] is_action_pressed=true is_action_just_pressed=false in_physics_frame=true
frame 1 | true  |  +0.000 | true | false | true | 0.080 | false | wake | none | 100.00 | INF |  0.000 | true  | not yet: press stamped for the next physics tick
frame 2 | false |  +8.379 | true | false | true | 0.080 | false | wake | none |  92.00 | INF |  1.120 | false | FIRED (stamina -8, airborne consumed)
frame 3 | false |  +7.945 | ...
frame 5 | false |  +7.079 | ...
frame 6 | false |  +0.000 | ...   <- loft ceiling: move_and_slide zeroes the upward component
frame 7 | false |  -0.433 | ...
frame 16| false |  -5.698 | ...
frame 17| true  |  +0.000 | ... | 92.00 | INF | 1.370   <- landed on the mattress
```

Scenario B (stood up via the director's own `_set_player_lying(false)`, same spot) and
Scenario C (edge injected from a **process** frame, which is where `peer_runner.gd`'s socket
loop actually calls `_press_edge`) produce the identical trajectory: `is_action_just_pressed`
reads true at injection in C (process-frame stamp), the controller still fires on the next
physics tick, stamina 98.40 → 90.40, `velocity.y` +8.379 → ceiling → landing at frame 17. Every
row of all three scenarios reads `locomotion_enabled=true`, `is_carried=false`, `fading=false`,
`beat=wake`, input owner `none`, lying lift 0.080 m, exactly as lane 0.F reported; those values
were correct and irrelevant.

**One observation, not a finding.** Because `trainer_model.gd` only clears the lying pose on
ground speed above 0.4 m/s or on leaving the bed's anchor radius, a player who presses A while
still in bed sees the flat lying body hop half a metre and bump the roof without standing up.
It is harmless, ends the instant they push the stick, and is recorded here only so nobody
rediscovers it as "the jump bug".

**What would make the harness see it.** `peer_runner.gd` already has the right instrument:
`press` with `confirm: {check: "left_floor", within_frames: N}` watches `is_on_floor()` one
physics frame at a time in-process. Against this beat it would report "left the floor 2 physics
frames after the press". Nothing in production needs to change for `jump` to be usable in a
step script.

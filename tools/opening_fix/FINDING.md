# The S02 opening blocker: the game is not broken, the step-script is

**Branch:** `ralph/OPENING-STARTER-FOCUS`. **Investigated against** `a3f61b60`.
**Outcome: no game change is required.** No file under `scripts/`, `scenes/`,
`data/` or `project.godot` is modified by this branch. It carries two probes and
this note.

## What the coordinator plan expected, and why both readings were wrong

The plan asked to separate "the picker opens with no focused control" from "the
picker fails to take focus when input arrives late." Neither is the case.
`scripts/ui/starter_picker.gd:377-381` reads input by **polling**
(`Input.is_action_just_pressed` on `menu_confirm` / `ui_right` / `ui_left`). It
has no focused control by design, and `ui_down` — the verb the harness probed it
with — is not one of its inputs. The picker was open and waiting correctly for
input nobody sent it.

## Hypothesis raised and killed by measurement

`interaction_arbiter.gd:271-275` polls `interact` from `_physics_process`, while
the harness injects presses during idle (`_inject` awaits `process_frame` with the
control held, deliberately, because the game's menus poll from `_process`). Since
`is_action_just_pressed` is frame-stamped, an idle-stamped press might never be
"just pressed" during a later physics frame — which would have invalidated every
`interact` step in the entire protocol.

`tools/opening_fix/probe_interact_edge.gd` tests exactly that shape:

```
A  parse_input_event, idle frame held, then physics frames:
   physics-context just_pressed hits: 1
```

**The hypothesis is false.** The harness's injection reaches `_physics_process`
pollers. Recorded because it is worth knowing it was checked.

## The actual cause

`tools/opening_fix/probe_opening_state.gd` boots the real Meadows and reports the
arbiter's winning provider once a second.

```
t00..t11 beat=wake  winner=BedPrompt/MeadowsPlayground  pos=-25.40,-15.60
--- one interact press ---
t90      beat=house winner=none                         pos=-25.40,-15.60
--- six seconds standing still, to rule out timing ---
t900..905 beat=house winner=none                        pos=-25.40,-15.60
--- player moved 2.2 m ---
t91      beat=house winner=Interactable/Grandpa         pos=-23.40,-14.80
t92      beat=house winner=none      (the press activated him)
```

The interact press works — it advances `wake` → `house`. Grandpa's prompt is
enabled for that beat. He simply does not offer from where the player is standing,
and six seconds of waiting does not change it, so this is positional, not timing.

**The player is upstairs.** From the failed S02 run's own `route.csv`, the player's
y during all 31 `interact` presses:

| t (s) | x | **y** | z |
|---|---|---|---|
| 236.11 | -25.40 | **4.93** | -15.60 |
| 237.76 | -24.50 | **4.65** | -15.68 |
| 238.28 | -24.50 | **4.65** | -15.68 |

Grandpa's marker is at **y = 1.32**. `grandpa_house.gd` builds a loft over the west
half (`LOFT_W = 4.6`, `FLOOR_H = 3.2`); the bed marker sits at `FLOOR_H + 0.55`.
The player wakes **on the loft** and pressed `interact` 31 times through the floor
at a man standing 3.3 m below them. Refusing that offer is correct behaviour.

## Why the step-script cannot be fixed by moving its target

`S02-15 "walk down to Grandpa"` walks to `[-22, -16]` with `close_enough: 3.0`.
That is the house *origin*. `move_to` is a **2D** walk — it compares x/z only — and
the bed is **0.89 m from Grandpa in x/z**. So the step's target is already
satisfied on the loft, and no tightening of the tolerance and no change of
coordinates can distinguish the two floors. The step passed honestly and left the
player one storey above the man it was supposed to reach.

The house already publishes the fix:

```
grandpa_house.gd:146  _markers["stairs_top"]    -> world (-21.5, 3.20, -18.1)
grandpa_house.gd:147  _markers["stairs_bottom"] -> world (-18.0, 0.12, -18.1)
                      "The stair line, for anything that has to NAVIGATE the
                       house rather than ..."
```

So the walk has to be routed `stairs_top → stairs_bottom → Grandpa`, which is a
change to `tools/gate_f/segments/S02.json` on the operator branch — instrument, not
game.

## What this means for the run

- **No new candidate SHA is needed.** The build under test does not change, so the
  S01, X07 and X08 evidence already committed stays attached to `a3f61b60` and
  there is no pre-fix/post-fix seam to declare under §1.6.
- The original S02 evidence is preserved as a superseded attempt, not deleted.
- The corroborating detail: in the failed run the player reached
  `(-17.74, -18.26)` at t=252.9 — essentially `stairs_bottom` `(-18.0, -18.1)` —
  and the modal opened 0.5 s later. They did eventually get downstairs, long after
  the steps that would have answered the conversation had run.

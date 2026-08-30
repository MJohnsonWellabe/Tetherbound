# T2-FLAKE — the opening segment's flake, found and fixed

`branch: ralph/T2-FLAKE` · `area: tests/helpers/gate_a_opening_drive.gd, tools/`
· `tests: smoke_gate_a_opening_segment.gd x36, smoke_gate_e_finale.gd x18,
run_tests.gd`

**Measured pass rate: 10/12 before, 23/23 after.** The failure had one cause,
it is a harness defect rather than a game one, and it is fixed rather than
retried, quarantined or waited out.

---

## 1. The number, before anything else

T5-STORY-2 filed the flake as *"3 passes in 4 runs on a job that is IN CI"*.
Two things needed establishing before any fix: whether the rate is real, and
which job actually carries it.

**Which job.** The finding names `ci.yml:985`, which is
`verify-continuous-core-known-red` running
`smoke_gate_a_opening_segment.gd -- --gate-a-continuous-core`. On current
`main` that job is **not** in every round: it is
`if: github.event_name == 'workflow_dispatch'` and `continue-on-error: true`,
with a comment saying so. It cannot redden a consolidation round.

The job that *is* in every round is the `gate_a_opening_segment` entry of
`verify-gate-evidence-shard` (`ci.yml:889`), which runs the same file in its
short form with `retries: 2`. That is the one measured below. The premise was
half stale; **the flake underneath it was entirely real.**

**The rate.** `tools/flake_rate.sh` (new, in this branch) runs one smoke N
times and counts, with each run given its own empty `user://` — CI gives every
job a fresh runner, and a local re-run that inherits the previous run's save
takes the returning-player branch instead, which is a different path.

Measured on this container, 12 runs, three at a time so frame times resemble a
loaded runner:

| | runs | passed | failed |
|---|---|---|---|
| `main` (baseline) | 12 | **10** | 2 |

Both failures were the same line, and nothing else failed:

```
gate A opening segment FAIL: right-stick aim could not line up the real throw reticle
```

## 2. The cause, which is derivable rather than guessed

Each failure was preceded by four copies of the harness's own diagnostic:

```
aim convergence stopped 4.44° off the body (camera pitch -11.4°, target 6.23m away ...)
aim convergence stopped 4.51° off the body ...
aim convergence stopped 4.44° off the body ...
aim convergence stopped 4.21° off the body ...
```

Four separate calls stopping at the same number is not noise. It is a limit
cycle, and the number it settles at is calculable.

`camera_rig.gd::_apply_look()` turns the camera in `_process`, by

```
f(|stick|) * gamepad_sensitivity * sensitivity_scale * delta   degrees
```

— **real seconds**, deliberately, so that sensitivity is frame-rate
independent for the player.

`gate_a_opening_drive.gd::_aim_camera_at()` is a control loop steering that
plant. It read the angular error, pushed the stick by a fixed response curve
(full deflection above 6°, proportional below it, floored at 0.18) and waited
**one physics frame**. So its step at error `e` was

```
190 * 0.55 * (e/6)^2 * delta   ≈  104.5 * (e/6)^2 * delta
```

which shrinks the error only while `e < 0.689 / delta`.

`tests/helpers/frame_granularity_probe.gd` (new) measures `delta` in the real
production world:

```
FRAME GRANULARITY: physics_frame 16.6 ms, process_frame 6.9 ms   (idle)
```

and the failing runs' own transcripts measure it under load — the opening's
300-frame settle took 90 s, i.e. **~300 ms per physics frame**.

- At 16.6 ms the convergence bound is **41°**. Everything converges. This is
  why the loop looks fine on an idle machine and why every local check passed.
- At 157 ms it is **4.4°** — the loop amplifies any error above that and parks
  there for its whole budget. That is the printed number, to two decimals.

Then `_aim_at_wild()` re-runs the same loop for each of its three back-off
attempts, each fails identically, and the run reports that the right stick
could not line up the reticle. The reticle was 4.4° off a body whose angular
radius at 6.2 m is about 3.0°, so `launch_assist_diagnostics()` also refused
the assist, and the fallback path had nothing to fall back to.

**The game is not at fault here.** A player holds the stick and watches
continuously; they do not sample once every 300 ms. This is the harness
steering a real-time plant with a frame-count controller — the exact shape
`ralph/BACKLOG.md`'s `CI-BOSS` entry asks future lanes to look for, one level
further in.

Worth stating precisely because it was checked: **everything else the opening
drive waits on is in the right domain.** `player_controller.gd`,
`creature_body.gd` and `wild_creature.gd` all move in `_physics_process`, so
the walk budgets are fixed sim-time and load-independent; `_tick_respawn()`
and `_tick_trainer_battle()` run on real-time `_process` deltas, so the
frame-count budgets waiting on them err generously as load rises. The camera
rig was the one thing that fails in the dangerous direction.

## 3. The fix

`_aim_camera_at()` now measures the plant instead of assuming it.

- **`_calibrated_deflection()`** records how far the camera actually turned for
  the deflection commanded last sample, and corrects by the **square root** of
  (error left / turn bought). The root is exact for the aim profile's squared
  response (`catching.json`'s `response_exponent: 2.0`) and under-corrective
  for anything gentler, so it converges from above rather than ringing. For a
  quadratic plant it lands the next turn exactly on the remaining error, which
  is why convergence takes one calibrated sample after the slew.
  Nothing in it knows the rig's sensitivity, response exponent, assist curve or
  deadzones: it observes their product, which is also the only form in which
  they can change underneath it.
- **It samples on `process_frame`** — the frame the camera actually turns on.
  Sampling on `physics_frame` meant every idle frame in between applied the
  same stale stick and the loop only ever saw the sum.
- **`_smallest_live_deflection()`** reads the two deadzones in force (the
  `look_*` InputMap actions' 0.2, which also rescales what survives, and
  `camera_rig.gd`'s own `stick_deadzone`) rather than copying them. The old
  floor of 0.18 was, after that rescale, a stick the rig discarded outright.
- **The ceiling is now generous real seconds** (`AIM_CONVERGE_SECONDS = 12.0`,
  `AIM_REAIM_SECONDS = 8.0`) rather than 360/240 frames. A frame count is a
  budget that silently shrinks 18x on the machine that needs it most.
- The failure print now carries what one sample bought, in degrees and
  milliseconds, so a future occurrence names the granularity instead of
  leaving it to be inferred.

Deleted: `_aim_strength()` and its `AIM_FINE_DEGREES` / `AIM_FINE_FLOOR`
constants. Leaving a dead tuning curve in place is how it gets re-adopted.

## 4. Proof

Same instrument, same 3-at-a-time load, plus a harder 4-at-a-time batch.

| | runs | passed | failed | `aim convergence stopped` lines |
|---|---|---|---|---|
| **before**, `main` | 12 | 10 | **2** | **14**, in 7 of the 12 runs |
| **after**, sanity | 3 | 3 | 0 | 0 |
| **after**, full | 12 | 12 | 0 | 0 |
| **after**, 4-at-a-time | 8 | 8 | 0 | 0 |
| **after**, total | **23** | **23** | **0** | **0** |

The pass counts alone (10/12 vs 23/23) are suggestive; the convergence-line
count is the sharp measure, because the defect fired in *passing* baseline
runs too — five of the ten baseline passes recovered from it via an extra
launch or the game's own eligibility verdict. **14 occurrences to 0** is the
mechanism, not a sample.

## 4b. The `--gate-a-continuous-core` form, since the finding named it

One run of the longer form the finding pointed at. The **whole opening now
passes inside it** — title, wake, stairs, Grandpa, starter, naming, the orb
gift, the doorway, the natural engage, the weakening fight and the catch on
launch 3 — and the run then fails in the continuation segment, on something
this lane did not touch and does not own:

```
FAIL: NPC/gather continuation: Mira's required opening visit left
'recipe_orb_basic' unset; the gift branch is what the Foreman's hammer and
the orb recipe wait on
```

So that job's known-red is a **different** failure living past the opening,
in `gate_a_npc_gather_segment.gd`. It is `continue-on-error` and
`workflow_dispatch`-only, so it reddens nothing; recorded here so the next
reader does not re-attribute it to the aim loop.

## 5. `smoke_gate_e_finale` — a different cause, and a real game defect

It does **not** share the opening's cause, so under this lane's brief it is
recorded rather than fixed. What the reproduction adds is worth having.

**Reproduced, at the previous lane's exact rate.** Nine runs on unmodified
`main`: **7 passed, 2 failed**, both the same assertion with the same numbers
`handover-T1-HALL-REBUILD-2026-08-30.md` §10 recorded — 2 failures in 9 runs,
`5.7m BELOW`, `y=0.52`, floor `6.17`. That lane could not tell whether the
failure was its own branch's; it is not. It reproduces on `main`.

**The harness was measuring the wrong body, and that is why it looked rarer
than it is.** `_fight_to_the_end()` found the opponent with
`_world.find_child("TrainerCreature_%s_*")`. `find_child` returns the OLDEST
match in tree order, and `encounter_director._on_trainer_round_ended()` leaves
each beaten creature standing in the world for a beat before clearing it. The
Warden fields **five** creatures. So from round two on, the check — along with
the closing-distance gap and the stall report's "opponent at x,y,z" — was
reading a corpse while the live creature fought unmeasured.

Fixed here by adding `encounter_director.trainer_body()` beside the existing
`ally_body()` and asking for the body in the fight. With that, the same nine
runs give **5 passed, 4 failed** — the defect's real rate is roughly double
what the wildcard was reporting.

**What it is.** The corrected message names it directly:

```
'warden_aldis''s creature ('TrainerCreature_warden_aldis_13') is fighting
'warden_aldis' 5.6m BELOW 'warden_arena''s floor (y=0.52 against a floor at
y=6.17) ... creature bodies in the world: TrainerCreature_warden_aldis_13 y=0.52 (live)
```

Every failing run names the same body at the same height, and it is the LIVE
one -- the creature the player is fighting, not a corpse. The chain, most of
which `stronghold.gd:3096` already describes:

1. `combat_manager.gd::_place_fighters()` anchors both fighters off
   `_player.global_position`, and `_stand_the_trainer_aside()` then moves the
   player. A multi-creature battle calls `enter()` once per creature, so each
   round re-anchors from where the last one left the trainer and the fight
   walks several metres per round. Five rounds of that leaves the Warden's
   arena.
2. Out there `built_floor_height_at()` still answers 6.17, because its claim
   carries a deliberate `FLOOR_CLAIM_MARGIN_M` of 10 m past the wall. So
   `place_on_ground()` puts the body at floor height — in mid-air, past the
   edge of the actual slab.
3. `creature_body.gd::_physics_process()` grounds by `is_on_floor()` and
   `move_and_slide()`, not by the built-floor claim, so with no collider under
   it the body falls the 5.6 m to the terrain.

**Note for anyone reading the coordinates:** "the building's floor claim there
is 6.17" does **not** mean the fighter is inside the room. The claim is 10 m
generous by design. This lane initially misread that as disproving the drift
theory; it does not. The drift theory in `handover-T1-HALL-2026-08-30.md` §4
is consistent with every measurement here.

**This needs someone who owns `scripts/combat/**`.** The fix is where round
two onward stages its fighters — a gameplay-behaviour change affecting every
fight in the game, not a harness edit, and not something a reliability lane
should guess at at the end of its budget. The margin must **not** be widened a
third time: 10 m is already wide enough to hand a body a floor that is not
there, which is step 2 above.

## 6. A sibling, recorded not fixed

`tests/smoke_controller_catching.gd`'s aim loop (line ~296) is bang-bang at
**full** deflection against the game's `eligible` verdict, sampled on
`physics_frame`. At a 157 ms frame a full-deflection step is ~16°, against an
acceptance window of roughly one body radius (~3°) — the same limit cycle,
with a wider window. It is **not in `ci.yml`**, so it was left alone. Anyone
adding it to CI should port `_calibrated_deflection()` first.

## 6b. LANDING ORDER — read this before merging

The branch has two independent halves, and the second one is **not ready to
land**:

| commits | files | land? |
|---|---|---|
| the opening fix + instruments | `tests/helpers/gate_a_opening_drive.gd`, `tests/helpers/frame_granularity_probe.gd`, `tools/flake_rate.sh` | **yes** — 23/23, fixes a job in every round |
| the finale correction | `scripts/combat/encounter_director.gd`, `tests/smoke_gate_e_finale.gd` | **not yet** |

The finale commit is *correct* and it is what found the defect in §5 — but it
makes `smoke_gate_e_finale` fail **4 runs in 9 instead of 2**, because it
starts measuring the creature that is actually fighting. `ci.yml` gives that
job a single attempt. Landing it before the combat-placement defect is fixed
turns an intermittent red into a worse intermittent red and blocks other
lanes, which is not a trade this lane gets to make on their behalf.

It is deliberately the **last commit on the branch and touches no file the
opening fix touches**, so it can be dropped or held without disturbing the
half that is ready. Land it together with the `scripts/combat/**` fix.

## 7. What was not changed, and why

- **`ci.yml` is untouched.** The `gate_a_opening_segment` entry keeps
  `retries: 2`. It was already there and this lane did not add it. The
  recommendation, for a coordinator with a few clean rounds in hand: drop it
  to `retries: 1`, because with the cause fixed the retry's only remaining
  effect is to hide a regression of it. That is a judgement call with a real
  cost tonight if it is wrong, and it is not this lane's to spend on other
  lanes' landings. `tools/flake_rate.sh` is how to check before deciding.
- **Nothing was skipped, disabled, quarantined or retry-wrapped**, and no
  timeout was raised. The one budget that changed became *smaller* in frames
  and correct in units.
- **The opening fix touches no game code.** Its defect was in the harness.
- **One game file is touched**, and only additively: `encounter_director.gd`
  gains a `trainer_body()` accessor beside `ally_body()`. No behaviour changes.
  The finale's actual defect is in `combat_manager.gd::_place_fighters()` and
  is written up in §5 rather than patched by a reliability lane at the end of
  its budget.

## 7b. Regression check

`tests/run_tests.gd` on this tree: **0 failed** (1586 `ok` lines at the point
the run was read; a full run of the same tree exited 0). The one game file
this branch touches gains a method and changes no behaviour.

Pre-existing and untouched: every boot of a smoke through `--script` prints
five `SCRIPT ERROR: Cannot call method 'call' on a null value` from
`game_state.gd:1046` via `title_screen.gd::_refresh_load_button`. It is on
`main` at the same count and is not this branch's.

## 8. Files

- `tests/helpers/gate_a_opening_drive.gd` — the opening fix.
- `tests/helpers/frame_granularity_probe.gd` — new; prints what a process and a
  physics frame actually cost in the production world on this machine.
- `tools/flake_rate.sh` — new; runs a smoke N times and counts, N at a time,
  with a fresh `user://` per run.
- `ralph/reports/handover-T2-FLAKE-2026-08-30.md` — this file.
- `scripts/combat/encounter_director.gd`, `tests/smoke_gate_e_finale.gd` — the
  finale correction. **Hold; see §6b.**

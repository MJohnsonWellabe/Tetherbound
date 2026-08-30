# T2-FLAKE — the opening segment's flake, found and fixed

`branch: ralph/T2-FLAKE` · `area: tests/helpers/gate_a_opening_drive.gd, tools/`
· `tests: smoke_gate_a_opening_segment.gd x35, smoke_gate_e_finale.gd x9`

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

## 5. `smoke_gate_e_finale` — different cause, not fixed here

Measured separately: see §7 for the run counts.

It does **not** share the opening's cause. The failure recorded by
`handover-T1-HALL-REBUILD-2026-08-30.md` §10 — two failures in nine runs, at
the same assertion with the same numbers each time — is:

```
FAIL: 'warden_aldis''s creature is fighting 'warden_aldis' 5.7m BELOW
'warden_arena''s floor (y=0.52 against a floor at y=6.17)
```

**That is very likely a real game defect, and it is worth saying loudly.**
`combat_manager.gd::_place_fighters()` (line 482) places both fighters from
`_player.global_position + forward * deploy_offset`, and
`_stand_the_trainer_aside()` then teleports the player to
`arena.centre + side * radius * 0.55 - forward * 1.2`. It is called once per
`enter()`, and a trainer battle calls `enter()` once per creature — so each
round re-anchors from where the previous round left the trainer, and the pair
walks several metres per round. In a stronghold chamber, a few rounds of that
puts the fight through a wall or under the floor. A player meets this as their
creature fighting inside geometry; the harness meets it as an intermittent
assertion, intermittent because whether the drift clears
`built_floor_height_at()`'s claim margin depends on how many rounds the fight
ran and which way the trainer was facing.

`handover-T1-HALL-2026-08-30.md` §4 documents the same class and treated the
symptom by widening that margin to 10 m. It should not be widened a third
time. **This needs someone who owns `scripts/combat/**`**, and it is a
gameplay-behaviour change (where fighters stand for round 2 onward), not a
harness edit — which is why this lane recorded it rather than guessed at it.

## 6. A sibling, recorded not fixed

`tests/smoke_controller_catching.gd`'s aim loop (line ~296) is bang-bang at
**full** deflection against the game's `eligible` verdict, sampled on
`physics_frame`. At a 157 ms frame a full-deflection step is ~16°, against an
acceptance window of roughly one body radius (~3°) — the same limit cycle,
with a wider window. It is **not in `ci.yml`**, so it was left alone. Anyone
adding it to CI should port `_calibrated_deflection()` first.

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
- **No game code was touched.** The opening's defect was in the harness. The
  finale's is not, which is exactly why it is written up above rather than
  patched by a reliability lane.

## 8. Files

- `tests/helpers/gate_a_opening_drive.gd` — the fix.
- `tests/helpers/frame_granularity_probe.gd` — new; prints what a process and a
  physics frame actually cost in the production world on this machine.
- `tools/flake_rate.sh` — new; runs a smoke N times and counts, N at a time,
  with a fresh `user://` per run.
- `ralph/reports/handover-T2-FLAKE-2026-08-30.md` — this file.

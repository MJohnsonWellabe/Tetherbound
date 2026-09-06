# `smoke_combat_camera` — measured, on both trees

Lane 4.C, 2026-09-06. Written because the smoke went red once during this lane's solo
regression, and "did this lane break it" is not a question to answer by reasoning about the
diff when it can be answered by running the base.

Godot 4.7.stable.official.5b4e0cb0f, one container, sequential runs, nothing else running.
Exit code captured directly from the engine (not through a pipe — the first attempt at this
measurement read `tail`'s status instead, which is why every run below is reported with its
own `godot exit=`).

## The runs

| Tree | Run | Exit | Failure |
|---|---|---|---|
| base `61518f6b`, untouched | 1 | 0 | — |
| base `61518f6b`, untouched | 2 | 1 | `the second production encounter would not start` |
| base `61518f6b`, untouched | 3 | 0 | — |
| base `61518f6b`, untouched | 4 | 1 | `the second production encounter would not start` |
| base `61518f6b`, untouched | 5 | 0 | — |
| branch `claude/mp-4c-encounter` | 1 | 1 | `the second production encounter would not start` |
| branch `claude/mp-4c-encounter` | 2 | 0 | — |
| branch `claude/mp-4c-encounter` | 3 | 0 | — |
| branch `claude/mp-4c-encounter` | 4 | 0 | — |

**Base: 2 failures in 5. Branch: 1 failure in 4.** The same assertion, the same message, on
both trees.

(Two further branch runs reached the second cycle and printed its `look vector` line, so they
did not fail at this assertion, but their exit codes were read through a pipe and are not
counted above.)

## The verdict

Pre-existing, and not this lane's. The branch's rate is if anything lower than the base's,
which is a sample-size artefact rather than an improvement — 4 and 5 runs cannot separate 25%
from 40%.

## What the failure is

`_prove_a_second_entry_exit_cycle()` flees the first fight, teleports the trainer 3 m from the
same wild, and presses X again. Sometimes the second `is_fighting()` is false.

The smoke's own printed diagnostics already show the run is not deterministic: the
`exploration baseline look vector` it records before anything happens is `(0.0, 0.0)` in some
runs and `(0.705312, -0.568168)` in others, on both trees, at the same step. That is the orbit
being sampled at a different point in its settle, which means the frames this smoke lands on
vary run to run — and the second engage depends on the wild being visible, alive, and inside
`flow.engage_range` (6.0 m) at the frame the press happens, after a fled fight has just
released it.

## Why it is not this lane's, as reasoning rather than assertion

Everything 4.C adds to a path solo can reach is gated on one of two things:

* `_encounter_link != null` in `combat_manager.gd`. It is set only by
  `bind_encounter()`, called only from `encounter_director.gd::_open_encounter_if_networked()`
  and `join_encounter()`, both of which return immediately unless `_is_multi_peer()` — which
  asks the session and is false with no session.
* `_is_host()` in `encounter_director.gd`, which is
  `Session.is_active() and Session.is_host()` — deliberately not `multiplayer.is_server()`,
  which is **true** under Godot's default `OfflineMultiplayerPeer` and would have taken the
  host branch in exactly this smoke.

The two solo-reachable lines that are not gated are refactors with the same arithmetic:
`_perform_player_strike()` is the old `_resolve_player_strike()` body with the connect test
hoisted into its caller, and `floor_reach_for_bodies()` is the old three lines of
`_with_reach_for_the_bodies()` moved to a static that the old call site now delegates to.

## Handover

Not fixed here and this lane does not own it. It belongs with whoever owns
`tests/smoke_combat_camera.gd`'s second entry/exit cycle. What would settle the mechanism is a
`tools/flake_rate.sh` run of the smoke on `main` and a print of the wild's distance,
visibility and alive state at the frame of the second press — the smoke currently reports only
that the fight did not start, not why it could not.

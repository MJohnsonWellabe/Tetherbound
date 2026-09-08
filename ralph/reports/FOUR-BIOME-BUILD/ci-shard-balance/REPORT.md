# Multiplayer CI shard balance and orphan cleanup

Date: 2026-09-07
Base: `296f7aa1d2ab48990ecdfb3ced7c2a69e4699545`

## Measured source

The cost table in `.github/workflows/ci.yml` comes from completed CI run
[`34158919494`](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34158919494),
head `c359c1c15f3aa08cebb98da109118a40e6d5918f`. All seven multiplayer jobs were
green. Each duration is the difference between a smoke artifact's UTC start in
its `net-<name>-YYYYMMDDTHHMMSSZ` directory and the next smoke's start; for the
last smoke in a shard it is the `NET_RUN.json` completion timestamp. This measures
the runner invocation, including peer boot and harness teardown, rather than an
in-code frame estimate.

Shard 5's completed job was
[`101857118184`](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34158919494/job/101857118184).
Its `Run net smokes` step ran 20:25:42–20:32:49 UTC (427 seconds). Every smoke
assigned to that shard measured:

| Smoke | Start | Next start / completion | Measured seconds |
|---|---:|---:|---:|
| `farm_race` | 20:25:42 | 20:27:11 | 89 |
| `join_by_address` | 20:27:11 | 20:28:31 | 80 |
| `reconnect_keeps_character` | 20:28:31 | 20:29:54 | 83 |
| `split_realms` | 20:29:54 | 20:31:50 | 116 |
| `water_mounted_swimming` | 20:31:50 | 20:32:48 | 58 |

The 34-smoke measurement set from the same completed run is encoded directly in
the workflow so assignment has one reviewable source. The 35th smoke on the merge
base, `water_swim_stone_late_join`, landed afterward; its completed local harness
run `net-run-local-1517565` measured 17:16:03–17:17:06 (63 seconds). A future newly
discovered smoke receives the slowest completed measurement (168 seconds) until a
green artifact supplies its own number, and CI prints a warning naming it.

## Failure that exposed the split

Run [`34163799085`](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34163799085)
kept the same alphabetical shard-5 grouping. Its artifact shows the first three
smokes completed in 84, 75 and 77 seconds, then `split_realms` started at 21:46:56
UTC. The job was cancelled at its unchanged 30-minute ceiling, 22:11:38 UTC, before
that smoke wrote `NET_RUN.json`; `water_mounted_swimming` never started. The
24-minute-42-second incomplete interval is failure evidence, not substituted into
the completed-cost table.

## Assignment contract

The workflow now uses deterministic longest-processing-time-first assignment with
the smoke path as the tie-break. Shards 1–6 carry the measured-cost balance and
shard 7 is reserved for `split_realms` alone:

| Shard | Measured seconds | Smoke count |
|---:|---:|---:|
| 1 | 504 | 5 |
| 2 | 555 | 6 |
| 3 | 552 | 6 |
| 4 | 556 | 6 |
| 5 | 551 | 6 |
| 6 | 493 | 5 |
| 7 | 116 | 1 (`split_realms`) |

Selection itself is the deterministic regression test. Before a shard runs, it
recomputes the whole plan and fails unless every discovered file appears exactly
once, `split_realms` is the only file in its shard, and every measured smoke load
is at most 1,200 seconds. The job ceiling remains 30 minutes; the smoke-load cap
leaves ten minutes for checkout, Godot setup, upload and runner drift.

## Child-process cleanup

The previous workflow invoked `run_net_smoke.sh` in the foreground. Its own `EXIT`
trap handled normal exits, and `net_harness.gd::finish()` killed tracked PIDs, but
neither seam covered a coordinator that never reached `finish()` plus an external
job cancellation reliably.

Each workflow invocation now starts under a dedicated `setsid` process group. An
`EXIT`, `INT`, `TERM` or `HUP` path terminates that group, waits up to two seconds,
then kills remaining members. This covers the runner, coordinator, and every Godot
peer created beneath it. The harness also implements MainLoop `_finalize()` and an
idempotent `_terminate_child_processes()` for direct/local runs where Godot gets a
normal teardown callback. CI process-group containment is the hard-cancellation
backstop and does not depend on that callback firing.

## Static verification

- Embedded selection code executed against all 35 tracked `# peers: 2` smokes:
  exact one-time cover, singleton `split_realms`, loads `504/555/552/556/551/493/116`.
- The exact embedded Python block compiled and executed for every shard index.
- `.github/workflows/ci.yml` parsed with PyYAML.
- `git diff --check` passed for the owned files.
- No Godot, full-world smoke, import, render, push, timeout increase, or assertion
  weakening was used in this lane.

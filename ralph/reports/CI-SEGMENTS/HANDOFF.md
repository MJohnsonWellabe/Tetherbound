# CI-SEGMENTS handoff (lane wound down 2026-10-05)

Branch `tb/ci-segments`. Its head is the commit that adds this file; the
commit before it is `4b47ce55`. The branch contains main up to `e2fa5e4e`
(#542). Evidence lives in this folder: `RESULTS.md` (§5–7),
`PACKED_AUDIT.md` and `COVERAGE_MAP.md`.

## Done

**Already on main**
- Segmented chains and checkpoint handoffs.
- Affected-only selection.
- The `drop_link` clean-close fix.
- Option 3 (`72471a5d`): net shards are planned longest-first from measured
  times; queue order runs the long jobs first.

**On this branch, not yet landed**

- **A: net lanes.** `tools/ci/run_net_lanes.sh` and `tools/ci/net_shards.py`
  (`BIN_COUNT=22`, `LANES=2`, `SHARD_COUNT=11`; the ci.yml matrix is 1..11).
  - Each `verify-multiplayer-shard` job runs two plan bins side by side, each
    lane on its own ENet base: 27801 for lane a, 27821 for lane b.
  - Each smoke is cut at `NET_SMOKE_TIMEOUT_S=1200`.
  - Verdicts, with their seconds, print as each smoke ends. Every failure, or
    a planned smoke with no result, is an `::error::` that names the smoke and
    the lane.
- **C: packed solo suites.** Fourteen solo jobs, plus the Stormwood and
  Tidewake groups of regions-shard, moved verbatim into `.github/ci/suites.yml`.
  - `verify-packed` (8 runners × 2 lanes) runs them through
    `tools/ci/packed.py`, with step times from `tools/ci/packed_durations.json`.
  - Each suite's own `if:` still decides whether it runs.
  - Each `!cancelled()` step is one unit; a dependent step stays with its
    prefix, so it runs after the steps it depends on.
  - Every unit gets fresh `XDG_*`, `TMPDIR` and `RUNNER_TEMP`.
  - The 9 units that can host a session (they bind udp/27015 and the LAN
    beacon) only ever go to lane a of a runner. A bind failure fails its step.
  - Each unit keeps its suite's `timeout-minutes`.
  - Every step gets its own verdict and an `::error::` naming suite, step and
    lane. Steps planned but never run are reported as NO RESULT.
- **`run_net_smoke.sh` follower fix** (`cac073a8`): its SUMMARY.md `tail -f`
  can no longer outlive the run.

**Checks**
- `tests/test_ci_packed.py` (22), `tests/test_ci_net_shards.py` and
  `tests/test_ci_select_jobs.py` pass. All three run in the `changes` job.
- `python3 tools/ci/packed.py check` covers 101 units and 105 steps.
- Local proof of every packed unit (all 8 runners): 105/105 PASS.
- Drills: packed lane with real Godot (named fail, dependent skip, the
  independent step still runs); two real cancellations; net-lane missing
  smoke and timeout. Details are in `PACKED_AUDIT.md`.
- Independent review: FAIL, then all findings fixed; the re-review returned
  PASS WITH ISSUES, and both of its remaining items are fixed too.

## The one remaining task: the A+C proof dispatch

The coordinator decides when to run it; F18's CI had priority. First merge
origin/main (see the traps below). Then dispatch on the lane branch itself.
Do not make a scratch branch.

    gh workflow run ci.yml --ref tb/ci-segments -f tier=full

### Pass bar

1. `ci-gate` is green.
2. Every `verify-packed (N)` and `verify-multiplayer-shard (N)` job is green.
   The two known-red jobs may be red; they are excluded by design.
3. **No net smoke is slower than 1.3× its unpaired time** in run 37300900137.
   - Paired time: the seconds in its `smoke_net_<name>.gd lane x: PASS (N s)`
     line, or column 5 of `results.tsv` in the `net-smoke-runs-*` artifact.
   - Unpaired time: the gap between that run's
     `##[group]smoke_net_<name>.gd attempt` lines.
   - If a smoke exceeds 1.3×, or a net smoke shows a host step overrun (the
     CI-only 1 fps guest problem F18 hit), don't pair two net smokes. The
     fallback is net + solo on a runner, which needs C's lane runner.
4. **Report** wall time and runner-minutes, per job and in total. Compare
   them like for like:
   - Exclude the schedule-only jobs, `verify-unbroken-chains` and the two
     known-red jobs (about 38 runner-minutes). A dispatch runs them; a PR's
     full CI does not.
   - Expected: about 503 runner-minutes and 36–37 min before; about 326
     runner-minutes and ~23 min simulated after (~25–27 min with the replay's
     correction).
   - Also note how many concurrent runners the run actually got. When other
     branches' CI shares the account's ~20-runner cap, the wall time is
     invalid.

## Known traps

- **Main's shard count.** Main runs 20 single-lane shards, or 21 if F18
  lands with another bump.
  - On merge, keep this branch's lane layout. Take main's new
    `MEASURED_SECONDS` entries.
  - Raise `BIN_COUNT` until `python3 tools/ci/net_shards.py --check` prints
    no "over the 580 s budget" warning. Keep it even, with
    `SHARD_COUNT = BIN_COUNT // LANES`, and set the matrix to `1..SHARD_COUNT`.
  - `tests/test_ci_net_shards.py` fails if any of these disagree.
- **Moved jobs.** If main edits a job that now lives in
  `.github/ci/suites.yml`, apply the edit there.
  - git may report a clean merge, because the block was deleted from ci.yml.
    Diff main's ci.yml since the merge base for those job names.
  - A new `uses:` step, or a job-level `env`, `services` or similar key,
    cannot be packed (`packed.py` refuses it). Keep such a job in ci.yml.
- **`.uid`/`.import` sidecars.** Godot creates hundreds of untracked ones
  during local runs. They are not committed.
- **`pgrep -f` / `pkill -f` match their own shell.** A pattern that appears in
  the command line also matches the shell running it; anchor it, e.g.
  `'^python3 tools/ci/packed\.py run'`.
- **Local machine speed.** This container runs about 1.3× slower than a
  runner, and a full local packed proof takes about 2 h. Background tasks stop
  at 2 h, so run the 8 runners in two batches.
- **`shared_wild_fight` is flaky locally,** with or without pairing. It has
  been routed to its owner; it passes on CI.
- **New smokes and packed steps start with provisional times.** Main's 330 s
  net entries are provisional, and a new packed step is planned at 300 s
  until it is measured. Refresh both from green full runs:
  - net smokes: the `MEASURED_SECONDS` table in `tools/ci/net_shards.py`;
  - packed steps: rebuild `packed_durations.json` from the per-step timings in
    the jobs API.

# Smoke sweep plan — replacing "all 149, sequentially, once per wave"

**Status:** proposal, written 2026-09-06 during lane MP-W0-SMOKE-SWEEP-0906 while the first
full sequential sweep was running. Supersedes the "run `run_all_smokes.sh` once on the wave
head" clause in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` rows 0.E, 1.B, 7.B and §325
if adopted. Nothing here changes a test; it changes when and where tests run.

## 1. What the current plan costs, measured

The first sequential sweep on the Wave 0 head (`64cd87f7`, 4-core box, Godot 4.7 headless):

| Measured on 30 of 149 smokes | Value |
|---|---|
| Wall clock | 76 min |
| Mean per smoke | 152 s |
| Median per smoke | 119 s |
| Under 15 s | 8 smokes (unit-shaped tests that happen to live in `smoke_*`) |
| Over 10 min | 2 (`cloudreach_continuous` timed out at 900 s; `cloudreach_deployed_cadence` 783 s) |
| Projected full sweep | ~6.3 h sequential, plus ~15 min per base re-run of each failure |
| Cores busy during it | 1 of 4 |

Three-quarters of that time is world boot, repeated 149 times, and two chapter-length walks
that are not smokes at all. CI already runs 46 of these smokes on every PR, in eight parallel
shard jobs with retries, so a per-wave sequential sweep re-measures those 46 a second time,
slower, on a box a lane needs.

What the sweep is actually for, per the plan: a once-per-wave answer to "did anything across
the whole game regress that no shard runs", with the distinct `^ERROR:` set compared against
`main`. That question does not need 6 hours of one core.

## 2. The plan

### 2.1 Tier the smokes by what they are, not by their filename

| Tier | What | Count (approx.) | Budget each | Runs |
|---|---|---|---|---|
| **T0 spine** | Boot + the ten paths every change can break: `playground`, `opening`, `title_new_game`, `title_load_game`, `save_persistence`, `combat`, `catching`, `input`, `menu`, `hud_no_sixth_slot`, `wake_softlock`, `settings` | 12 | 5 min | every lane head, locally, before push (~15 min at 3 workers) |
| **T1 shards** | The 46 CI smokes, as already sharded | 46 | as CI sets | every PR, in CI, unchanged |
| **T2 chapter walks** | `gate_b_continuous`, `cloudreach_continuous`, `cloudreach_deployed_cadence`, `gate_e_finale`, `gate_a_opening_segment`, `stronghold*`, `finale_persistence`, `meadows_realm_handoff` | ~10 | 40 min | once per wave, in a CI matrix, one walk per runner |
| **T3 long tail** | everything else | ~80 | 10 min | once per wave, in a CI matrix, 4–5 shards |

A smoke's tier is a line in a small manifest, `tests/smoke_tiers.json`, so the tier is data
and the runner reads it. Untiered smokes default to T3, which keeps the manifest from becoming
a gate on adding tests.

### 2.2 Run the wave sweep in CI, not on a lane's box

Add one `workflow_dispatch` (and weekly `schedule`) job, `full-sweep`, with a matrix of about
six shards: T2 walks one per runner, T3 split by the recorded durations so shards are even.
GitHub-hosted runners give one VM per matrix entry, so the whole sweep lands in the time of its
longest shard, about an hour, and the lane box is never involved. The summary format stays the
one `run_all_smokes.sh` writes today; each shard uploads its `SUMMARY.md` and the job
concatenates them into the artifact a wave report links.

Numbers this changes:

| | Today | Proposed |
|---|---|---|
| Wave sweep wall clock | ~6.3 h | ~1 h (longest shard) |
| Lane-box hours consumed | ~6.5 | 0 |
| Base comparison for failures | manual worktree + re-run per failure, ~15 min each | automatic (see 2.4) |

### 2.3 If it has to run locally, run three at once

`run_all_smokes.sh` already gives every smoke a private `XDG_DATA_HOME`, and its header says the
isolation exists "so smokes could in principle run in parallel later". Add `JOBS=N` (default 1,
recommended 3 on a 4-core, 15 GB box: a Meadows boot is ~3 GiB RSS and one core), schedule
longest-recorded-first, and the 6.3 h sweep becomes about 2.2 h with no change to any smoke.
`tools/flake_rate.sh` already does exactly this with `FLAKE_JOBS`; reuse its loop.

### 2.4 Diff against a recorded baseline instead of re-running `main`

Commit the sweep summary from `main` once per landing as `tests/smoke_baseline.md` (the file
this lane is already producing for `55c64aaa` is the first one). The runner then reports, per
smoke, three things against that baseline rather than three raw numbers:

- **exit changed** (0 → non-zero is a regression; non-zero → 0 is a fix to record);
- **distinct `^ERROR:` set grew** — printed as the set difference, so the finding is the line,
  not a count (the workflow's own rule: the set, never the count);
- **duration grew past 1.5× baseline** — the early warning for a walk drifting toward its budget,
  which is what `cloudreach_continuous` did silently before it started timing out.

Base re-runs then happen only for a smoke whose result *changed*, which on this sweep so far is
zero of thirty, instead of a worktree and 15 minutes per non-zero exit.

### 2.5 Budgets from data, not one flat number

The 900 s flat budget is right for a smoke and wrong for a chapter walk; `cloudreach_continuous`
was still advancing at 842 s of wall clock with half its stages left when killed. Record each
smoke's baseline duration and set its budget to 3× baseline, clamped to [120 s, 45 min]. A walk
that has never been measured gets the T2 default. A timeout then means "3× slower than it has
ever been", which is a finding, rather than "longer than an arbitrary number", which was not.

### 2.6 Stop paying for the world boot 149 times

Eight of the first thirty smokes finish in 1–13 s: they are unit tests with a `smoke_` prefix.
Move them under `tests/test_*.gd` where `run_tests.gd` runs them in one process. Not a sweep
change, but it takes those out of every future sweep and shard for free.

## 3. What a wave delivers under this plan

- Each lane: T0 spine green locally (15 min) before push; the PR's CI shards green.
- Each wave head: one `full-sweep` dispatch, about an hour, whose artifact is the diffed
  summary (2.4). The wave report links it and lists the set difference, if any.
- `main` landing: the sweep summary becomes the next baseline.
- Stage B exit (7.B): the same dispatch, plus the perf stands that row already names.

No smoke is dropped. Every one still runs once per wave; the change is that the wave sweep
runs in parallel where the machines are free, compares to a recorded baseline instead of a
second live run, and budgets each smoke from its own history.

## 4. Order of adoption

1. `tests/smoke_baseline.md` from this lane's `main` run, and the 2.4 diff in
   `run_all_smokes.sh` (S, one lane).
2. `JOBS=N` in the runner (S, same lane).
3. `tests/smoke_tiers.json` and the `full-sweep` CI matrix (M).
4. Per-smoke budgets from the baseline (S, once 1 exists).
5. Move the unit-shaped smokes (S, mechanical).

Items 1–2 alone take the next wave's sweep from ~6.3 h on a lane box to ~2.2 h with automatic
base comparison; item 3 takes it off the lane box entirely.

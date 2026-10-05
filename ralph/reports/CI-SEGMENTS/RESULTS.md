# CI-SEGMENTS results (branch `tb/ci-segments`)

Evidence for the lane. The old-assertion → segment mapping is in
`COVERAGE_MAP.md`. All local runs were on the 4-core / 15 GB evidence
container, one Godot run at a time unless noted.

## 1. Segments, per job (CI run 37256861064, b44338f0, green)

| Chain | Before | After (each job; legs run in parallel) |
|---|---|---|
| midride (F06 mid-ride rejoin, two-peer) | 1 job, 19 min (17 min of scenario) | s0 host 5.2, s0 guest 6.1, s1 A 10.3, s2 B 7.7, s3 control 5.1 min. Folded since: s0 pair + s3 on one runner, ~11 min |
| bracket (tournament) | 6.6 min of smoke inside a 13 min job | to-semi 7.0, final 5.1 min (the final now shares a runner with gate_e_finale) |
| handoffs | — | 2.4 min (one job, both chains) |

Checkpoint determinism: three `regen.sh` runs, plus every producer job,
reproduced identical state digests:

- bracket `1a922c6d9097`;
- setup guest `1aeb8480f898`, setup host `edaff325803b`;
- after_a and after_b guest `b2aa76cc0791`.

## 2. drop_link: a deterministic clean close

Before the fix, the guest's `drop_link` (`peer.close()`) sometimes never
reached the host. The host then kept the guest until ENet's peer timeout
(MULTIPLAYER: 135–180 s), past the 30 s drop step:

- the unmodified original scenario missed it in 1 of 2 valid runs;
- segmented B missed it in 1 of 3.

The first attempted fix, `peer_disconnect` plus `flush()`, still missed (B
run 1: "flushed to 1 peer(s)", host never saw it). A graceful ENet
disconnect queues behind the ride's outstanding reliable traffic, and
`close()` then destroyed the host before the disconnect left.

The landed fix waits, for at most 300 frames, until ENet reports the server
peer DISCONNECTED (the host's acknowledgement), then calls `close()`. No game
timeout or step budget changed.

| Run (after fix) | Result | Host saw the drop | Ack |
|---|---|---|---|
| segmented B ×3 | 3/3 PASS (555, 551, 560 s; each reproduced checkpoint after_b) | after 0 frames | 51, 53, 89 frames |
| original unsegmented f06 midride ×3 | 3/3 PASS (1258, 1244, 1268 s) | after 0 frames (both drops) | 2–5 frames |
| smoke_net_realm_owner_disconnect_mid_fight | PASS (391 s) | — | — |

## 3. Whole-run wall time and runner-minutes

The account runs at most ~20 jobs at once. A full run is throughput-bound:
the wall floor is about runner-minutes / 20, and the multiplayer shards
(16–26 min each) queue last and set the tail.

| Run | Jobs | Wall | Runner-min | Of which setup |
|---|---|---|---|---|
| Before: full 37246987633 | 41 | 58 min | 445 | 76 |
| Segmented v1: full 37256861064 (b44338f0; other branches' CI shared the cap) | 60 | 53 min | 550 | 122 |
| Head e5e5df10: full dispatch | ~49 incl. 2 unbroken-chain legs | not yet measured: dispatch needed | est. ~555 (~515 without the schedule-only unbroken/known-red jobs) | est. ~95 |

Changes since v1 that reduce runner-minutes:

- 13 legs folded back, each saving ~2 min of setup;
- the editor-only Godot cache (the old cache held 1.27 GB of export
  templates) saves ~10–15 s per job.

The schedule/dispatch-only `verify-unbroken-chains` adds ~40.

### A typical PR with the `full-ci` label, under affected-only selection

The rule is conservative, as the owner ruled.

| PR kind | Jobs | Expected wall | Runner-min |
|---|---|---|---|
| docs/report-only | none (`code=false`) | ~1 min | ~1 |
| test-only / tool-only / unit-test-only (334 of 440 smokes, 781 of 993 tools, 708 of 781 unit tests are bounded) | ~6: unit shards ×3, bake freshness, export, handoffs, plus the jobs that run the file | ~9–13 min (longest of those jobs) | ~40–55 |
| combat-only, creatures/ui/homestead/training/save/Meadows, any realm file (nearly every realm file reaches shared code transitively), shared or core | everything except the schedule-only jobs | ~50 min | ~515 |

The selection was checked by three independent reviews:

1. FAIL: one-hop walk, unit-test shortcut, narrow scan, ripplet, core order,
   renames, fail-open, net override.
2. FAIL: sparse checkout missing scan roots, seen-before-skip, `.uid`
   sidecars.
3. PASS WITH ISSUES: four soft spots, all fixed in e5e5df10.

Every finding is a regression case in `tests/test_ci_select_jobs.py` (32
tests). Over all 24,255 classifiable tracked paths, classification on the
exact CI sparse tree is identical to the full repository.

## 4. Structural options to reach a 15–20 min full run without new spend

Not chosen here. 15–20 min needs runner-minutes ≤ ~350, while the head is at
~515.

| # | Option | Expected full-run wall | Coverage risk |
|---|---|---|---|
| 1 | **Boot once, run several net smokes per peer-process pair.** `smoke_net_two_peers_boot` (launch + two world boots only) takes 83 s against a ~120 s average net smoke, so about 2/3 of the net group's 182 runner-min is launch and boot. Keep the two processes and reset state between smokes. | Saves ~80–110 runner-min (~430 total), so ~22–30 min on its own; combined with 2 or 3, ~15–20 | Medium-high: gives up the per-smoke isolated homes (harness contract §2). A missed reset leaks state, which can mask or fake failures. Each smoke needs a proven reset, plus a scheduled run that still uses fresh processes. |
| 2 | **Two independent smoke groups side by side per runner** (the runners have 4 vCPU and 16 GB; `s0_setup` already does this). Halves the job count and setup, and roughly doubles throughput per runner for the mostly single-threaded smokes. | Effective ~300–350 runner-min, so ~16–20 min if the net shards are paired and rebalanced | Medium: CPU contention stretches frame-budget steps (seen locally: a cold Cloudreach `load_save` overran its 10000-frame default), and memory pressure (seen locally: one OOM with three Godot runs). Needs a pairing table measured per group and memory headroom, and turns real timing slack into flakes if mis-paired. |
| 3 | **Rebalance on measured durations and start the long jobs first.** Bin-pack the net shards on recorded per-file times to ≤12 min each (now 5.7–26 min against a 1200 s plan). Drop the `discover-net-smokes` dependency so the shards queue with everything else rather than last. Trim setup further (~2 min per job: 60 s checkout, a 1.7 GB `.godot` cache restore). | ~30–35 min (bounded by ~500 runner-min / 20). It cannot reach 15–20 alone. | Low: same tests, same processes. The only risk is a stale duration table (the existing scheduler already warns on unmeasured smokes). |

# MP-0F-NET-HARNESS — report

**Lane:** 0.F Net harness (Sonnet from the contract; Opus review follows) · **Branch:**
`worktree-agent-aa6b1e8d71d0c4365` from `claude/tetherbound-roadmap-next-jrcjs8` at `37f7e15e`
(carries lane 0.E's `ad6dede5`), merged as `16a3aa12` · **Kind:** tooling + two smokes + one CI
job · **Brief:** `docs/specs/MP_NET_HARNESS_CONTRACT.md` §12 · **Commit:** `16f7fafc`. The lane
could not write this file itself; Fable wrote it from the lane's completion report after
reproducing the two-peer run on the merged tree (see the wave landing note for that run's numbers).

Base note: the worktree was provisioned on `main` (`55c64aaa`); the lane reset it to `37f7e15e`
(zero commits of its own, so safe) and verified `ad6dede5` was an ancestor before starting.

## One line per item, up front

| Item | Verdict |
|---|---|
| 1 `tools/net/peer_runner.gd` | **done** — `boot/wait/press/hold/release/stick/move_to/assert/probe/quit`, heartbeat every 60 physics frames with `state_hash` |
| 2 `tests/helpers/net_harness.gd` | **done** — `launch/step/steps/race/probe/assert_all_hashes_equal/expect_desync_free/check/finish`, heartbeat reader, desync detector, budgets from `multiplayer.json` `test_budgets` with contract defaults as fallback (file does not exist yet; 2.A owns it) |
| 3 `tools/net/run_net_smoke.sh` | **done** — per-peer isolation, `SUMMARY.md`, orphan kill by `TB_NET_RUN_ID` on every exit path |
| 4 `tests/smoke_net_two_peers_boot.gd` + negative control | **done** — real two-peer Meadows run, nine checks PASS, exit 0, 95–104 s wall clock, ~3.09 GiB RSS per peer; `tests/smoke_net_peer_death.gd` kills a peer mid-run and asserts the coordinator's exit 2 `ERROR: peer exited (peer 1, pid …)` |
| 5 CI `verify-multiplayer-shard` | **done** — 72 pure insertions, YAML valid, no other job touched |
| 6 `tools/net/udp_proxy.gd` | **done, not yet live-tested** — delay/jitter/loss relay verified against a synthetic UDP pair (`--role=selftest`, 3/3), not against an ENet handshake (no `Session` exists yet; 7.A) |

## Commands and output

```
godot --headless --path . --import                                   (×2, clean)
godot --headless --path . --script tests/smoke_playground.gd         tree and base: exit 0, distinct ^ERROR: set identical ({Parameter "material" is null})
GODOT_BIN=/root/godot-bin/godot tools/net/run_net_smoke.sh two_peers_boot --out=<dir>
  → hello from both peers (main_sha 37f7e15e), PASS ×9, ALL CHECKS PASSED; re-run 3× after the fixes below, 3/3 clean, zero ^ERROR: in peer logs
GODOT_BIN=/root/godot-bin/godot tools/net/run_net_smoke.sh peer_death --out=<dir>
  → coordinator exit 2, fatal_reason 'ERROR: peer exited (peer 1, pid 15768)'; the smoke itself exits 0 as a standing regression check
```

## Reused from Gate F vs written

`preload`ed unchanged: `scripts/debug/gate_f_probe.gd` (every accessor), `tests/helpers/stick_navigator.gd`,
`operator_harness.gd::_physical_binding` (pure static). Ported: `_edge`/`_inject` (physical
`InputEvent` plus paired `Input.action_press/release`), `_press_axis`/`_drive_sticks`, and the five
`assert` case bodies, verbatim comparisons and messages. Not ported (no live target in Wave 0):
`interact_with`, `advance_dialogue_until_closed`, `fight_until_resolved`, and every §4
net-specific action; `probe session` returns an honest stub.

## Three findings

1. **`world_seed` diverges between peers.** `spawn_tables.json` `roll_new_worlds` is `true`
   (D-0830-1), so two independent boots roll different seeds — the only differing key in an
   otherwise identical save. The harness pins every peer to one `TB_WORLD_SEED` (default `"0"`)
   and normalizes the saved field for hashing only. **Contract §7 amended by Fable** to say so.
2. **`satiety` drains with wall time**, like `clock_elapsed_seconds`, and two unlocked processes
   read it at different instants. Excluded from the hash under a separately printed
   `state_hash_excluded_keys_wave0_provisional`. **Contract §7 amended by Fable**: `satiety` is a
   player key and belongs on the exclusion list by the contract's own rule.
3. **`OS.kill(pid)` killed the shell, not Godot.** Peers launched as `/bin/sh -c '<godot> …'`
   reparented the real process to init on kill; the orphan sweep hid it. Fixed with `exec` so the
   shell replaces itself; `hello.pid` now equals the pid `OS.create_process` returned.

## Limitations recorded

`udp_proxy.gd` untested against a live handshake; `race()` shares one deadline sized to the
largest budget; real peer exit codes are not recoverable through `OS.create_process`
(`ERROR: peer exited (peer <i>, pid <pid>)` instead of `<code>`); `multiplayer.json` absent
until 2.A. All to be re-judged by the Opus review and closed in Wave 2 where non-blocking.

# F11#3 on main: Long Storm aftermath, Spark/shrine and the Waterward gate persist (two peers, host restart, rejoin, guest drop)

Scenario: `tools/net/proof_scenarios/stormwood_f11_aftermath_shrine_two_peer_reload_rejoin.json`, run with `tools/net/run_two_peer_proof.sh` (headless, loopback ENet, Godot 4.7-stable, full asset checkout).

| Run | Tree | Verdict | Rows | Expected-vs-verdict mismatches | SCRIPT ERROR (host/guest) |
|---|---|---|---|---|---|
| `PROOF-main-32bd330-FAIL-row37.md` | main 32bd33079 | FAIL | 53 (stopped) | row 37 | — |
| `PROOF-main-0e2a3b6-rerun-FAIL-row37.md` | main 0e2a3b60c (confirming rerun) | FAIL | 53 (stopped) | row 37 | — |
| `PROOF-diag-instrumented-FAIL-row37.md` | main + temporary DIAG prints | FAIL | 53 | row 37 | — |
| `PROOF-press-fix-only-PASS.md` | main + `_inject` patch only | PASS | 97 | 0 | 0 / 1 (`conversation_camera.gd:178`) |
| `main-0e2a3b6-with-patch/PROOF.md` | main 0e2a3b60c + `SHARED-FILE-REQUEST-press-and-speaker.patch` | **PASS** | **97** | **0** | **0 / 0** |

Expected-FAIL rows (negative controls): 11, 28, 43, 57, 58, 67, 72. Rows 50 and 63 are `any` (a rejoin may already stand in Stormwood).

## Root cause of row 37 (the host's Spark activation press)

The fault is in the harness, not the game. `tools/net/peer_runner.gd::_press_edge` does two things for one press:
- it queues the physical joypad event with `Input.parse_input_event`, which is buffered until the next **process** frame;
- it calls `Input.action_press`.

`_inject` waits one **physics** frame and then releases. On a slow host frame, several physics ticks run in one process frame, so the release lands before the buffered press is flushed. That late joypad press becomes a second `just_pressed` edge. The Spark prompt is a toggle (activate/release), so its state returned to `placed_inactive`. `DIAG-double-edge.txt` shows two edges for one press on the failing run, and one edge per press with the patch.

The prior lane saw the same misroute once (`STORMWOOD-PROGRESS/f11_3/rerun_shared_fixes/PROOF-first-rerun-spark-press-misrouted.md`) and passed on a retry. The failure depends on timing, and main's heavier Meadows now trips it on every run.

## Patch (shared files; not committed here; see the PR comment)

1. `tools/net/peer_runner.gd::_inject`: `await process_frame` after the down edge, so the buffered physical event lands while `action_press` still holds.
2. `scripts/player/conversation_camera.gd:178`: `is_instance_valid(winner) and winner is Node3D`. In Godot 4.7, `is` on a freed instance is itself a SCRIPT ERROR, so the validity check has to come first. X05 flagged this in its review of d69b46bf5, and it landed unfixed.

## Disclosed fixture seams (unchanged from the scenario)

- Marrow's defeat is committed through the ledger; the fight is not played.
- Players are teleported beside the view, gate and socket prompts. Every press is an ordinary interact.

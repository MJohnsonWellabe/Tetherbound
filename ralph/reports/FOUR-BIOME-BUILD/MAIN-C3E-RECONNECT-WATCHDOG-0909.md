# Main c3e reconnect watchdog diagnosis — 2026-09-09

## Preserved failure

Main `c3e198b81cd6`, Actions run `34401138071`, job `102640724640` failed
`smoke_net_reconnect_keeps_character.gd`. The raw job log remains at
`.artifacts/main-c3e198b81-ci/job-102640724640.log`; artifact `10124665430`
is preserved under `.artifacts/main-c3e-reconnect-failure/`.

The first causal failure was not a character restore assertion. Peer 1 completed
its production rejoin at `20:57:39.022`, including building the returning title
entry and joining as ENet peer `1382134166`. At `20:57:39.029`, seven milliseconds
later, the coordinator reported that peer 1 had been heartbeat-silent for more
than 15 seconds. Character, registry, and snapshot probes then returned empty
because harness waits abort once `_fatal_reason` is set; those empty values do
not establish data loss.

## Cause and bounded correction

`tests/helpers/net_harness.gd::step()` gave the named `production_join` action a
90-second world-build allowance. On receipt of the matching PASS verdict it
cleared the allowance, but retained the heartbeat timestamp from before the
23-second build. The next pump immediately applied the ordinary 15-second rule
to that stale reference.

The correction treats the received successful production-join verdict as fresh
control-loop liveness: it rebases `last_heartbeat_t` at completion and then clears
the allowance. FAIL/ERROR verdicts, unrelated actions, and timeout paths do not
receive that credit. The stored `last_heartbeat` payload remains unchanged.

The preserved artifact independently shows that the peer resumed: peer 1's final
heartbeat reports physics frame 420, session peers `[1, 1382134166]`, and state
hash `2881227384`, matching the host.

## Focused regression

The isolated unit command was run once with Godot 4.7 stable:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run_tests.gd -- --only=test_net_harness_heartbeat_allowance.gd
```

Result: **2 tests, 11 assertions, 0 failed; exit 0**. It covers completion before
the next heartbeat, ordinary silence more than 15 seconds after completion,
heartbeat-payload preservation, production FAIL/ERROR, and unrelated join PASS.
This is focused harness validation; the original failed smoke is preserved and
has not been retried.

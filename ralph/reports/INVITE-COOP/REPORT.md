# INVITE-COOP evidence report

Status: partial implementation evidence on `ralph/invite-coop`. Final focused evidence below matches source commit `71f82814d20d82a526b8df39969c56abe3ef75d4`; it does not claim release acceptance. Draft PR: [#136](https://github.com/MJohnsonWellabe/Tetherbound/pull/136).

## Verified evidence

| Area | Result | Artifact |
| --- | --- | --- |
| Focused invite/session units | 42 tests, 238 assertions, 0 failed, exit 0; no `SCRIPT ERROR` lines. The only diagnostic is the expected capacity-5 refusal warning in `test_session_transport.gd`. | `tetherbound-invite-final-units.log` |
| Two actual ENet processes (pre-final save/retry fixes) | Host/join storage and authority checks passed; exit 0 | `tetherbound-invite-host-join.log` |
| Title CLI join driver (pre-final save/retry fixes) | 17 checks passed, including world snapshot and assigned peer identity; exit 0 | `tetherbound-invite-join-driver.log` |
| Native Steam isolation probe | Native initialization, host socket and private lobby creation passed; exit 0 | `tetherbound-steam-native-probe.log` |
| Production native session path (pre-final save/retry fixes) | 13 checks passed across title → Meadows → Steam host → leave/cleanup, including native host identity to current-lobby membership and wrong-lobby claim refusal; exit 0 | `tetherbound-steam-session-final.log` |
| Title visual capture | 1280×800 capture reviewed as legible for all six actions; capture and error logs exit 0 | `_sheet-title.png`, `tetherbound-invite-title-capture*.log` |
| Runtime provenance | GodotSteam 4.20 / Godot 4.7 / Steamworks 1.64; archive SHA256 `b5bd13a3c1d6c2087b54607aad43865fa29d070d8992ef114ce17d955413149a`, source commit `e702a38efd8256ea2295f182f3fb3afecb096931` | `tetherbound-steam-install.log` |

The native probes used explicitly selected development AppID 480. This is testing configuration only: it is not the product default and no invitation was sent.

The production probe reports a fresh-world snapshot Variant payload of 15,312 bytes, excluding RPC framing. That measurement does not establish a bound for a grown world or prove the 512 KiB Steam packet ceiling. `server_relay=true` is game-host forwarding and is not proof of Valve SDR relay delivery.

## Pending or failed checks

Command used: stock `Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run_tests.gd -- --only=steam_lobby,steam_invite_ui,session_transport,session_physical_timeout,peer_registry_admission,join_driver_admission,title_new_game,autosave_fallback`, with isolated `%TEMP%/tetherbound-invite-appdata-final` APPDATA. The full unit run remained live separately and is intentionally not claimed or copied as complete. The separately rerun receipt fixture shard passed: 2 tests, 27 assertions, 0 failed; its log is not used to imply that the full suite is green.

An additional post-fix `smoke_net_host_join_leave` attempt was started with isolated APPDATA and two real peer processes. It produced no `SUMMARY.md` or protocol verdict before manual termination at about 2m09s; peer/world-build logs were still advancing through 22:08:53, so this is an incomplete, prematurely terminated observation rather than proof of a startup stall. The committed host/join evidence in `tetherbound-invite-host-join.log` predates the final save/retry fixes; this smoke is therefore pending rather than claimed as final post-fix evidence.

The existing gate-F predicate regression reports three threshold failures: S02 (450 asserted rows versus shortest 368), S04 (420 versus 362), and S05 (970 versus 491). Read-only inspection found the predicate function unchanged from HEAD and scanning `ralph/reports/` recursively; its `_shortest_healthy_route` input therefore includes historical and untracked report telemetry, while `tools/gate_f/segments/S02.json`, `S04.json`, and `S05.json` are unchanged. This is recorded as existing telemetry/fixture provenance, not as a threshold change or a clean campaign result. The working diff has only unrelated additions in `tests/smoke_warrens.gd` and `tests/test_autosave_fallback.gd` among the inspected test paths.

## Acceptance gaps

Evidence remains open for two accounts on different networks, relay delivery, four peers, export templates, Ally overlay/device behavior, exact build/content fingerprint compatibility, and a grown-world packet-size bound. The implementation now binds native Steam identity to claimed lobby membership and protocol, but this unit proof is not remote-peer proof. `GodotSteam` native identity and local lobby creation are established; release co-op is not accepted.

Baseline shutdown allocator/resource errors remain in the production probe log after the passing checks; no script error was reported by the focused invite unit run.

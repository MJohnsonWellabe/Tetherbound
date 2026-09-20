# INVITE-COOP evidence report

Status: partial implementation evidence on `ralph/invite-coop`. Final focused and two-peer evidence below matches source commit `89f486c652ab`; it does not claim release acceptance. Draft PR: [#136](https://github.com/MJohnsonWellabe/Tetherbound/pull/136).

## Verified evidence

| Area | Result | Artifact |
| --- | --- | --- |
| Focused snapshot/session/invite/ledger units | 78 tests, 477 assertions, 0 failed, exit 0; no script or plain errors. Expected warnings cover snapshot timeout cleanup and capacity-5 refusal. | `tetherbound-invite-final-snapshot-units.log` |
| Two actual ENet processes at source SHA `89f486c652ab` | Default harness: host/join/snapshot/registry/leave/host-exit passed; both peers exited normally with `unexpected_exit=false`; `failures=[]`, empty fatal | `tetherbound-invite-host-join-final.log`, harness `SUMMARY.md`/`NET_RUN.json` retained outside the report because they are run metadata |
| Title CLI join driver (pre-final save/retry fixes) | 17 checks passed, including world snapshot and assigned peer identity; exit 0 | `tetherbound-invite-join-driver.log` |
| Native Steam isolation probe | Native initialization, host socket and private lobby creation passed; exit 0 | `tetherbound-steam-native-probe.log` |
| Production native session path (pre-final save/retry fixes) | 13 checks passed across title → Meadows → Steam host → leave/cleanup, including native host identity to current-lobby membership and wrong-lobby claim refusal; exit 0 | `tetherbound-steam-session-final.log` |
| Title visual capture | 1280×800 capture reviewed as legible for all six actions; capture and error logs exit 0 | `_sheet-title.png`, `tetherbound-invite-title-capture*.log` |
| Runtime provenance | GodotSteam 4.20 / Godot 4.7 / Steamworks 1.64; editor archive SHA256 `b5bd13a3c1d6c2087b54607aad43865fa29d070d8992ef114ce17d955413149a`, source commit `e702a38efd8256ea2295f182f3fb3afecb096931`; template source `https://codeberg.org/godotsteam/godotsteam/releases/download/v4.20/godotsteam-g47-s164-gs420-templates.tar.xz`, archive `godotsteam-g47-s164-gs420-templates.tar.xz` local SHA256 `06216a20f39d64dfe6aa29ce7add91f5eb2f36b38ce13ca0dcac36c869ffa0f1`; extracted `win64/godotsteam.47.debug.template.win64.exe` SHA256 `19f7b2621becaccc8c0984127e2989d016ddd5c73a54447c71d2f1f363bf5996`, `win64/godotsteam.47.template.win64.exe` SHA256 `a648caa7e30047827ed6b675b64d005aa7785aceb8400c0e116af4e439be6fc9`, `win64/steam_api64.dll` SHA256 `eb17909a76668cf9ae0b92a618a34a50f6c73d3a6787cb4dd8ce36a8b10bfb75`; hashes are local only, with no publisher checksum certification | `tetherbound-steam-install.log`; local cache `C:\Users\mattj\.cache\tetherbound-tools\godotsteam-4.20-godot-4.7-export` |

The native probes used explicitly selected development AppID 480. This is testing configuration only: it is not the product default and no invitation was sent.

The production probe reports a fresh-world snapshot Variant payload of 15,312 bytes, excluding RPC framing. The final snapshot transfer tests cover 192 KiB chunks, a 64 MiB total transfer cap, a 60-second handshake/snapshot deadline, out-of-order chunk assembly, and boundary delta replay after the baseline. These contracts do not prove a grown production world stays below the 512 KiB Steam packet ceiling; chunking is the intended transport path. `server_relay=true` is game-host forwarding and is not proof of Valve SDR relay delivery.

## Pending or failed checks

Command used: stock `Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run_tests.gd -- --only=snapshot_transfer,session_snapshot,session_transport,steam_lobby,steam_invite_ui,autosave_fallback,world_ledger_races,death_satchel_ledger,stormwood_arch_ledger,stormwood_harvest_ledger,stormwood_rod_ledger`, with isolated APPDATA. The full unit run was a separate mixed-working-tree run and is not claimed as final-commit verification. Its terminal result was 3,721 tests / 3,854,523 assertions / 2 assertion failures plus stale script errors from tests edited after that run began; it must not be read as the final source result. The separately rerun receipt fixture shard passed: 2 tests, 27 assertions, 0 failed.

The earlier manually terminated smoke observation is superseded. The final default-harness smoke reached its own completion: two real peers, clean conditions, host world and autosave, client character-only save, empty client world directory, snapshot application, registry agreement, client leave, and host cleanup all passed. Both peers exited normally; no protocol error was reported.

The existing gate-F predicate regression reports three threshold failures: S02 (450 asserted rows versus shortest 368), S04 (420 versus 362), and S05 (970 versus 491). Read-only inspection found the predicate function unchanged from HEAD and scanning `ralph/reports/` recursively; its `_shortest_healthy_route` input therefore includes historical and untracked report telemetry, while `tools/gate_f/segments/S02.json`, `S04.json`, and `S05.json` are unchanged. This is recorded as existing telemetry/fixture provenance, not as a threshold change or a clean campaign result. The working diff has only unrelated additions in `tests/smoke_warrens.gd` and `tests/test_autosave_fallback.gd` among the inspected test paths.

## Acceptance gaps

Evidence remains open for two accounts on different networks, real Steam invitation and relay delivery, four peers, export/release acceptance, Ally overlay/device behavior, exact build/content fingerprint compatibility, and a grown-world packet-size bound. Matching Windows x86_64 export templates are present in a separate local cache with local hashes only; stock global templates remain untouched and the Windows preset custom-template overrides remain blank. The implementation now binds native Steam identity to claimed lobby membership and protocol, but this unit proof and local ENet smoke are not remote-peer proof. `GodotSteam` native identity and local lobby creation are established; release co-op is not accepted.

Baseline shutdown allocator/resource errors remain in the production probe log after the passing checks; no script error was reported by the focused invite unit run.


## Shared wild encounter presentation defect

Source inspected at parent PR144/d313c9817 while preparing
`ralph/regional-homecoming`. PR143 CI35497191759/job106042696113 failed
`smoke_net_shared_wild_fight.gd` action9003: both opponent and teammate
connected, at2.544m and8.122m; the host correctly hit the nearer opponent.
`encounter_host.gd::_friendly_body_struck` explicitly implements that rule.
The fixture did not establish opponent exclusion before expecting a friendly
refusal. This was not a demonstrated revive or target-selection defect.

One bounded fixture experiment changed guest placement to exact/one-frame
settling. Host receipt then correctly refused9003 with `friendly_target`
(opponent connects=false, teammate connects=true), but an independent live
opponent strike changed victim HP109.502→97.097 and strike count2→3 during
the observation window. The smoke remained red. Root restored that experiment
fully; no shortened-timing test change is committed. OS-temp captured stdout:
`shared_wild_fight_fixture_fix.log`. No further timing tuning was attempted.

The source investigation exposed an actual product defect beneath the fixture:
`encounter_director.gd::join_encounter` picks `nearest_live_wild()` locally,
then calls `CombatManager.begin` against that ambient body before binding the
host record. `_rpc_encounter_opened` stores the host announcement only;
`_rpc_encounter_record` feeds `apply_encounter_record`, which reconciles HP,
poise and participant wind without updating opponent species or pose. The
local arena and AI can remain centred on another creature. Root verified the
join, record and manager source after the lower-tier report. The existing
peer-runner `place_stand_in` workaround documents the same discrepancy; it
cannot count as production synchronization.

Required next multiplayer scope: a guest presentation body tied to the host
encounter's species/identity, pose, telegraphs/attacks and retirement. The
existing `realm_owned_opponent` begin path supplies a seam for avoiding a
second AI, but merely moving a proxy without host attack cues is incomplete.
Preserve current host damage/catch/receipt authority and local ambient ecology.
This remains unimplemented; remote wild motion is not accepted as cosmetic.
PR142 CI35497151016 finished26success/3skipped. PR143 finished25success/
1failure/3skipped; the failure above remains. PR144 CI is still in progress.

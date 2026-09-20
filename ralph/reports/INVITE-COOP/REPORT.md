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
At that baseline this was unimplemented; the repair below supersedes this status.
PR142 CI35497151016 finished26success/3skipped. PR143 finished25success/
1failure/3skipped; the failure above remains. PR144 CI35498358430 subsequently
finished26success/3skipped.

## Shared wild guest presentation repair

Branch `ralph/shared-opponent-presentation`, based on PR145/63914dafd.
Source commit `5c2bf2a7046a4a9d75a9c27a235b8f448970bcef` is pushed as draft
[PR146](https://github.com/MJohnsonWellabe/Tetherbound/pull/146); CI is pending.
`encounter_director.gd::join_encounter` now requests admission before starting
a shared wild fight. The admitted record supplies the canonical creature card
through `water_capture_codec.gd`, host body scale and alpha appearance.
`shared_opponent_proxy.gd` uses the ordinary rig and animation with no local AI
or collision. It cannot start AI when a failed catch calls `set_engaged(true)`.
The host publishes foot position/facing at10Hz; guest smoothing half-life is
0.05s. Telegraph and strike cues use reliable channel1 and distinct serials;
pose uses unreliable-ordered channel0. Identity includes encounter, realm and
body generation. Host damage, friendly-target arbitration and catch rolls retain
their previous owners and formulas.

The5s join timeout sends disengage and records a canceled identity. Late
admissions cannot create a proxy. Cleanup keeps authoritative caught-card
delivery and bypasses guest ambient faint/respawn/once-only mutation. Steam
protocolv4 marks the new wire contract. ENet still lacks a matching-build gate.

Validation findings retained: direct script loading caught an inherited
`configure(Dictionary)` signature collision, then four inferred-Variant parse
errors; these were corrected before world execution. Editor startup alone had
not loaded those scripts and was insufficient evidence. Early unit output
also printed zero failed while aborted methods emitted script errors; those
runs are rejected. The fixture was reduced to pure protocol/lifecycle checks
because this runner executes before a usable SceneTree exists.

The first rendered two-peer attempt reached host/join/deploy/engage but the
new test probe cast absent proxy fields on the host's ordinary wild with
`int(null)`. The probe aborted and later checks cascaded; no synchronization
verdict or capture was earned. The probe now limits those fields to the actual
proxy script, and the smoke stops before using a missing encounter position.
Initial evidence: `%TEMP%/tetherbound-shared-opponent-net-render-first.log`, run
`net-run-local-3020431`. This is a diagnosed test failure, not a claimed flake.

Focused stock-Godot4.7 run:
`--headless --path . --script tests/run_tests.gd -- --only=test_shared_opponent_presentation.gd,test_encounter_host_rejects_friendly_strike.gd,test_water_capture_codec.gd,test_steam_lobby.gd`
passes44tests/281assertions/0failures with no script/engine errors. Log:
`%TEMP%/tetherbound-shared-opponent-focused-final.log`. Required
`--headless --path . --script tests/smoke_playground.gd` exits0 with `smoke: OK`;
its distinct `ERROR:` lines exactly match the preceding homecoming smoke:
dummy-renderer allocator/RID/resource shutdown errors and null material.
Log: `%TEMP%/tetherbound-shared-opponent-playground.log`.
Parent PR145 CI35499458818 finished26success/3skipped; this is parent evidence,
not verification of the current branch.

Corrected live run `net-run-local-3026249` passes72checks, exits0 and reports
both peers exited normally. Host is headless; guest renders Compatibility at
1280×720. The OS-temp witness subclasses the existing shared-wild smoke and
peer runner only to render/capture the guest; gameplay steps and assertions
are the committed smoke. Exact entry:
`--headless --path . --script C:/Users/mattj/AppData/Local/Temp/shared_wild_render_smoke.gd`.
Logs: `%TEMP%/tetherbound-shared-opponent-net-render.log` and
`%APPDATA%/Godot/app_userdata/Tetherbound/net-runs/net-run-local-3026249/`.
Neither peer log contains `SCRIPT ERROR:` or `ERROR:`.

The guest's actual body script is the new proxy; both report `mudsnout`.
At the observed pose its centre equals its last host target
(30.14921,0.973814,-37.02414), with a1.5m predeclared interpolation tolerance.
Generation/pose sequence are positive, guest `engaged=false`, and normal host
AI produces both a telegraph and a strike cue. The smoke no longer invokes
`place_stand_in`. Both peers land damage and converge on one HP value; rapid
action/replay refusal remains intact. Friendly action9003 excludes the enemy
(6.212m, connects=false), includes the host's creature (2.932m, connects=true)
and is refused. Victim HP109.506 and opponent HP57.916 stay unchanged; enemy
strike count stays2. No friendly fixture timing or host targeting rule changed.

Root inspected `_sheet_shared_opponent.png`, captured only after the real guest
proxy received both cues. It shows the ordinary rendered combat scene and HUD;
the large companions crowd the foreground and obscure the enemy. This is
runtime presentation evidence, **not camera/readability or visual-bar acceptance**.
This clean-loopback result does not prove latency/jitter or four-player behavior.
Render lock is released and no Godot process remains.

Scope still open: guest-originated local wild authority, ambient ecology,
legacy trainer/boss opponent presentation, continuation after host-character
withdrawal, full catch/save/reconnect proof, network impairment and four-player
device/remote-invite acceptance. The host manager/body lifetime still depends
on its local fight; an encounter record surviving alone does not solve that.

## Shared wild lifetime (`ralph/shared-wild-lifetime`)

The next repair separates host simulation from the host player's local combat
manager. `shared_wild_host_fight.gd` extends the existing Stormwood authority
engine, with one body, RNG, arena, catch claim and presentation counter set per
encounter ID. The adapter reports local peer0 so host peer1 receives the same
host-rolled damage delivery as a guest. The director routes strikes and catches
by ID; its local manager owns presentation/input only. Host withdrawal can leave
the old fight running while the host rejoins it or starts a different wild.
Normal trainer/boss strikes retain their prior manager path and resolving phase.

Review corrections retained: local callbacks must detach without disengaging
the authority body; active shared bodies must remain exempt from ambient spawn
gate/residency suppression; last-leave disposal must wait through the local
manager's INACTIVE-before-disengage ordering; terminal ecology is latched once.
Catch authority physics pauses during the claim and resumes on failure, expiry
or claimant withdrawal. Completion uses the stored host result and validates
membership, claimant, phase and expiry. Host catches still enter the existing
personal-party path; non-catchers receive the correct local or remote notice.
Final attackers finish through their verdict rather than an earlier terminal
record. Other participants receive terminal records and a locally guarded
once-per-presentation victory XP award. This is not durable XP receipt work.

Parent PR146 CI35501023744 exposed a stale source-slicing assertion in
`test_wild_once.gd`: an earlier shared-guest `if outcome == CAUGHT:` was mistaken
for the ordinary ecology branch. Anchoring after executable `match outcome:`
preserves the existing once-only and ordinary-respawn checks.
Focused validation in `%TEMP%/tetherbound-shared-wild-lifetime-final.log` passes
64tests/271assertions/0failures with no `SCRIPT ERROR:` or `ERROR:`. Four new
runtime tests cover the local-zero adapter and forwarding, terminal latch, and
catch physics suspend/resume; the run also includes existing encounter,
presentation, encounter rewards and once-only coverage. Exact selector:
`test_shared_wild_host_fight.gd,test_wild_once.gd::test_combat_exit_fires_the_flag_and_skips_the_respawn_timer_for_once_only_wilds,test_shared_opponent_presentation.gd,test_encounter_host_rejects_friendly_strike.gd,test_encounter_rewards.gd`.
Direct check-only of the
four changed runtime scripts is clean; exit status alone was not used as proof.
Required `tests/smoke_playground.gd` exits0 with `smoke: OK`, no script errors,
and the exact same distinct `ERROR:` lines as the preceding presentation run:
headless dummy-renderer material/RID/allocator/resource shutdown errors. Log:
`%TEMP%/tetherbound-shared-wild-lifetime-playground.log`.

The first two-peer attempt, `net-run-local-3115997`, passed the existing72checks
and observed continued guest cues after host withdrawal, a distinct second
opponent and same-ID host rejoin. Its added lifetime assertions are rejected as
acceptance evidence: the helper discarded top-level ambient-body telemetry,
participant IDs crossed JSON numeric conversion, and the added guest strike
used a position captured before waiting for later AI cues. The run was stopped
without a final pass summary. Neither peer log had script/engine errors. Log:
`%TEMP%/tetherbound-shared-wild-lifetime-net-first.log`. Corrections must preserve
real bodies and host geometry, expose correlated receipts, and rerun the same
existing smoke; they do not justify changing hit rules or inventing stand-ins.

Same-realm runtime acceptance is pending the corrected live run. World-scene
transfer still destroys ordinary engines rather than migrating them to a realm
shell. Guest-originated wild authority, complete catch/save/reconnect delivery,
legacy trainer presentation, remote Steam invitations, impairment/four-player
coverage and camera readability remain open. No release or chapter acceptance.

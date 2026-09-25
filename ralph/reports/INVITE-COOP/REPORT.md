# INVITE-COOP evidence report

## Lane restarted on main 47774c350

X05 (invitation co-op and authority) restarted from `origin/main`
`47774c35069fef965448f1dd898ae08abb0a58c8`, under ROADMAP Phase 5 step 28,
MULTIPLAYER §1.1/§5/§9 and ACCEPTANCE M1–M2 and §7. The work continues the
existing GodotSteam lobby, admission and chunked-snapshot foundation. ENet
authority stays in place and gameplay scope does not grow. Open items at
restart: a build/content compatibility gate, full/mismatch/cancel refusals,
invites accepted with the game open and closed, the 120 s reconnect
reservation, host exit and rehost, the four-peer run, proof that a refusal
survives a lossy link, and the Windows export runtime. Real two-network relay,
four Steam accounts, the Ally overlay and a non-development AppID still depend
on the owner. Earlier sections below are historical and are re-verified on
current main before any claim is made.

## Integration regression: friendly-strike fixture

CI35520003064 is terminal failure, with this smoke and an independent Livewire
sampling-window failure; all other active jobs passed. Current action9003
produced a fresh host `missed` receipt, while the client's last-refusal field
still held the deliberate previous `replayed_action`. This is not action-ID
reuse. The old phase2 placed the victim at opponent+X and the striker at a
global-Z offset, putting a moving opponent near the cone boundary. Earlier
receipts below already document invalid geometry in this same phase. No
host refusal, damage, movement or networking behavior changes in this slice.

At main0021ae3b6 plus this test-only diff, phase2 rereads the settled victim
and live opponent, then places the striker between them facing outward. It
fails closed if positions are unavailable. Existing action/HP/authority
assertions remain, and the correlated receipt must additionally show the
opponent eligible but nonconnecting while the teammate connects.

Root ran stock Windows Godot4.7 headless with isolated `TB_NET_RUN_ID` and
`TB_NET_OUT_DIR`: `--path D:/tetherbound/expedition-current --script
tests/smoke_net_shared_wild_fight.gd`. Result:95 passing checks, no failures,
both peers expected exit and empty fatal state. Action9003 received
`friendly_target` after one poll; the new opponent exclusion assertion passed.
Logs and `NET_RUN.json` remain at `D:/tetherbound/expedition-friendly-radial*`.
This is bounded regression evidence, not invitation/remote/four-peer or
campaign acceptance. No additional networking scope follows.

The unchanged Livewire failure sampled152ms before deadline against a required
180–350ms window, with286ms maximum scheduling gap. Parent35518525531 sampled
336ms with46ms maximum gap. The actual Livewire-enabled deadline and released
baseline refusal checks passed. Preserve this measurement failure honestly;
do not alter production cooldowns or silently widen the acceptance window.

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

The corrected raw-intent attempt `net-run-local-3079850` completed with98PASS
checks and one failed assertion, printed again in the failure summary. It proved
continued host AI/cues, active guest-only membership, distinct simultaneous
opponents, exact same-body/generation/HP rejoin, and ambient body/HP retention
after both last-leave cases. Its remaining failure was the positive guest strike:
action9006 was accepted for A but honestly missed. Host origin
(36.481,0.478,-35.379), opponent (35.134,-0.291,-34.618), distance1.728m and
fixed +X aim place the opponent behind the attack. A stayed49.959HP; B was
unchanged. No script/engine errors. Log:
`%TEMP%/tetherbound-shared-wild-lifetime-net-final.log`.
After two failed measurements, the approach changes: the positive lifetime
strike now uses ordinary `combat_quick` input and production targeting; hostile
raw-intent checks remain unchanged. No hit geometry, cooldown or authority rule
is loosened. The host's existing `play_attack()` call is also restored at the
authority cue, because detaching its old local manager callback otherwise lost
that animation. Parent PR146 CI ended25success/1failure/3skipped; its sole stale
source-slicer failure is the correction described above.

Changed-input run `net-run-local-3029712` passes96checks/0failures, prints
`ALL CHECKS PASSED` and exits0. Coordinator and both peer logs have no script or
engine errors. The guest's ordinary `combat_quick` input lands on its first
press while the host fights B: A54.494→45.142HP, action9004 accepted/hit for
encounter1:1 at5.470m. B HP stays unchanged. Host withdrawal leaves A active for
the guest with continued telegraph/strike cues; B uses a distinct body. Host
rejoin preserves A body456357060880, generation1 and exact45.1419496241492HP.
Both last-leave cases retain the real ambient body and HP. Root inspected the
run log and both peer error scans. Log:
`%TEMP%/tetherbound-shared-wild-lifetime-net-input.log`; peer logs are under
`%APPDATA%/Godot/app_userdata/Tetherbound/net-runs/net-run-local-3029712/`.

Initial PR147 CI35502260985 found compatibility defects beyond the focused set:
Water Alpha's override lacked the new optional argument; the victory guard
needed resetting on a new hosted encounter ID; callback cleanup queried absent
signals on a bare test body. These are corrected in `water_alpha.gd` and
`combat_manager.gd`. Existing `test_stormwood_hosted_combat.gd,test_combat_burst.gd`
now pass13tests/81assertions/0failures with no script/engine errors, including
new-round XP and both hosted award orderings. Log:
`%TEMP%/tetherbound-shared-wild-compatibility.log`. No additional world run was
needed for these signature/round-binding corrections; the wild continuation
run already includes the restored host attack animation call. No new visual
quality acceptance follows from this headless run.

Draft PR147: https://github.com/MJohnsonWellabe/Tetherbound/pull/147, initial
source49da3e6ba stacked on PR146/0d7a1da3c. Same-realm flee/rejoin/concurrent
continuation now has clean-loopback evidence. Downed/disconnected variations,
terminal catch/save delivery, latency and four-player behavior are not proved by
that run. World-scene
transfer still destroys ordinary engines rather than migrating them to a realm
shell. Guest-originated wild authority, complete catch/save/reconnect delivery,
legacy trainer presentation, remote Steam invitations, impairment/four-player
coverage and camera readability remain open. No release or chapter acceptance.

## Ordinary catch confirmation

Work branch `ralph/shared-catch-confirmation` starts at PR147/24f68769f.
The observed defect is in `CombatManager::_finish_catch`: ordinary encounters
submitted `catch_finished` and then granted their earlier catch decision without
waiting for the host's response. An expired or refused claim could therefore
become a locally owned creature. Water Alpha already has a separate confirmed,
journaled handover; this work must preserve it.

Scope is exact host confirmation and canonical creature delivery during a live
ordinary encounter. Claim identity, claimant, membership and expiry must agree;
stale replies cannot finish another throw. The manager must grant nothing while
confirmation is pending or refused. Bounded session-local reply retention is
retry support, **not a durable capture journal**. Ordinary character-save
failure and reconnect between host retirement and party persistence remain open.
No hidden sixth, storage, changed catch odds, new save field or autoload follows
from this repair.

Parent CI35502664854 exposed one further signature regression in
`test_stormwood_realm_transition.gd`: its test subclass omitted the parent's
third optional `_host_after_encounter_change` argument. The exact test-only
correction passes6tests/27assertions with no script/engine errors in
`%TEMP%/tetherbound-shared-catch-transition.log`. The failed shard reached
937tests/334,486assertions/1failure; this is a parent regression, not a reason
to weaken the test.

Source validation: stock Godot4.7 selector
`-- --only=test_catch_arbitration.gd,test_shared_opponent_presentation.gd,test_steam_lobby.gd`
passes37tests/166assertions/0failures, with no script/engine errors. This includes
manager pending/refused/canonical-success behavior, stale reply isolation,
terminal timeout, exact cached retry and correlated synchronous offline refusal.
Log: `%TEMP%/tetherbound-shared-catch-focused-final3.log`.
The required Playground boot exits0 with `smoke: OK`; its distinct engine error
set exactly matches the prior PR147 baseline (dummy-renderer null material and
shutdown resources), with no script errors. Log:
`%TEMP%/tetherbound-shared-catch-playground.log`. That boot precedes the final
stale-router and local-refusal guards; those narrow corrections have the focused
unit evidence above. No visual quality claim follows from the headless checks.

The first extended two-peer run (`net-run-local-3063718`,
`%TEMP%/tetherbound-shared-catch-net.log`) failed3of61assertions. It admitted a
guest catch, carried an exact claim and granted nothing during the wobble, but
the host refused completion as `not_claimant`; the old race also passed its
assertions despite that finish refusal. That old green race is insufficient
confirmation evidence. One additional failed assertion was a fixture reading
step-envelope fields at the wrong level; canonical comparison also needed to
exclude legitimate ownership/care changes after delivery.

Timing review found two problems. The host lease uses monotonic milliseconds,
while catch presentation used simulation delta and discarded phase overshoot.
Separately, `_play_catch_decision` used an absorb-plus2.5s fallback when no orb
was resting. With three shakes this is7.2s, exceeding the6s lease even with a
correct clock. The fixture has no physical orb, so it necessarily exercises
that fallback; a real orb failing to rest could hit the same defect. Ordinary
shared presentation now uses unscaled monotonic elapsed time, carries phase
overshoot and limits that fallback to the authored0.45s absorb, yielding4.7s
for three shakes. The host lease remains6s. Solo and Water timing stay unchanged.
A truly stalled client can still expire; no grant is invented after expiry.
The next run was stopped during startup when the fallback problem was found;
it is not counted as a completed measurement.

The complete ABSORB/no-orb/three-shake regression advances4.8s of monotonic
time with only1ms of simulation delta and observes all three shakes and exactly
one finish request. The same focused selector passes38tests/170assertions with
no script/engine errors (`%TEMP%/tetherbound-shared-catch-focused-final5.log`).
Final review also preserved negative timer remainder when an orb had already
rested; that one-line correction passes the affected presentation selector,
14tests/72assertions, with no errors (`...-focused-final6.log`).

Draft PR148: https://github.com/MJohnsonWellabe/Tetherbound/pull/148,
initial source4bc632bb2 stacked on PR147/24f68769f. Parent CI35502664854 ended
25success/1failure/3skipped; its sole failed signature fixture is corrected in148.
The expanded catch smoke still uses explicit fixture setup and the production
catch-intent/manager/party path; it is not physical orb-input, full-party release,
durable save/reconnect, remote Steam, impairment or four-player acceptance.

Clock-corrected run `net-run-local-3062428`
(`%TEMP%/tetherbound-shared-catch-net-final.log`) exits1 with48passing checks
and one unique failure, repeated in the summary. The original race now receives
`catch_finished` with `ok:true,caught:false`; it no longer expires. The next
setup fails: after the host's flee, the guest's `combat_run` press leaves its
manager fighting for480observed frames. The cause and actual-input reproduction
remain open; this fixture observation is not a diagnosis of the entire leave
system. Coordinator and both peer logs have no script/engine errors.

After two unsuccessful measurements the test approach changes. Force the first
simultaneous race to break out, then have the guest catch successfully in the
same live fight. This retains two-peer arbitration and exercises a fresh claim
for a repeated throw, while removing the unrelated teardown/new-fight setup.
The fixture chooses a seeded RNG state on the required side of the actual catch
chance; neither shipping probability nor the host lease is widened.

The same-fight run `net-run-local-3042293` reached59checks with2failures:
ownership did not increase and no canonical card was delivered. Both finish
responses were accepted; the guest's second outcome was honestly a breakout.
The fixture had selected0.062118 against the manager's0.079750 preview, which
does not include the host's actual throw geometry. This is a fixture error,
not evidence of a lost successful capture. The correction selects a real seeded
RNG roll below `catching.json::chance.min` (0.02) for success, or at/above
`chance.max` (0.95) for breakout. `catch_math.gd::catch_chance` clamps the host's
calculation to those bounds. Probabilities and host decisions remain unchanged.
Log: `%TEMP%/tetherbound-shared-catch-net-same-fight.log`.

Initial confirmation commit4bc632bb2 passes CI35503716233:
26successful jobs/3skipped, including all four unit shards. This CI run does not
contain the subsequent clock correction or expanded deterministic network smoke.

Final changed-approach run `net-run-local-3061916` on the source committed as
348cc8d92 exits0 with60checks and `ALL CHECKS PASSED`. The simultaneous race
breaks out with runtime roll0.996490 (at/above0.95). A fresh guest claim in the
same encounter catches with roll0.012550 (below0.02). Host state says
`caught:true` during the wobble; guest ownership stays0, then becomes1 only
after the accepted finish. The delivered identity, IVs, stats, moves and traits
match the host card, with caught_on_day1; the host receives no creature. Root
inspected the coordinator verdict and both peer error scans. Coordinator log:
`%TEMP%/tetherbound-shared-catch-net-bounded-roll.log`; peer logs:
`%APPDATA%/Godot/app_userdata/Tetherbound/net-runs/net-run-local-3061916/`.

**This run is not error-clean.** Before catching, host peer-0 lines148–155 show
remote deployment replacement building `AllyCreature_563550239`, then the node
standing up as `AllyCreature_563550240` while retaining owner563550239. Three
engine errors follow: node563550239 not found, cached node6 unavailable, and an
invalid RPC packet for that missing node. Guest/coordinator have no script or
engine errors. The name mismatch is an unresolved replication finding; it is
not classified as harmless teardown or assumed pre-existing without a baseline
reproduction. The successful capture assertions remain bounded evidence, not
release acceptance. Remote replacement and the earlier post-catch guest-leave
observation require separate repair/diagnosis; durable ordinary capture remains
open as described above.

## Remote companion replacement retirement

Branch `ralph/remote-creature-replacement` follows PR148/50d0f8cc9. The host
previously called `queue_free()` and immediately spawned the next companion
under the old node's still-occupied `AllyCreature_<peer>` name. Godot renamed
the new node, leaving incoming replication pointed at the missing stable path.
This is the concrete cause supported by the preceding run's name mismatch.

`scripts/combat/encounter_director.gd` now records the retiring instance ID per
peer. Every spawn/reconcile path waits until a deferred callback after
`tree_exited`; detached nodes are also queued for deletion. Completion reads
the latest desired deployment, so rapid switches coalesce. Recall/disconnect
remove that desired row; teardown clears the barrier; stale instance callbacks
cannot clear a newer barrier. Same-body card updates retain the current proxy.
No save, autoload, wire format or protocol-version change is introduced.

Focused validation: `test_shared_opponent_presentation.gd` passes15tests and
81assertions with no script/engine errors in
`%TEMP%/tetherbound-remote-replacement-focused-final2.log`. The added unit spy
checks desired-row completion, stale callback rejection and recall cancellation;
it does not copy the production spawn barrier or claim to prove node lifetime.

The existing `smoke_net_deploy_two_creatures.gd` adds a PartySeam grant that
drives the production active-creature replacement path. Run
`net-run-local-3052917` exits0 with43passing checks and `ALL CHECKS PASSED` in
`%TEMP%/tetherbound-remote-replacement-deploy.log`. Both peers retain exactly one
stable guest proxy, with replacement Mudsnout species and guest authority; the
old Terrapup proxy is absent. Root inspected coordinator and both peer logs:
zero `ERROR:`/`SCRIPT ERROR` entries. Peer evidence lives in
`%APPDATA%/Godot/app_userdata/Tetherbound/net-runs/net-run-local-3052917/`.

An orchestration mistake also launched `net-run-local-3167019` on the same
fixed ports while the original process tree was present. Root stopped that
duplicate; its partial log (`%TEMP%/tetherbound-remote-replacement-net.log`) is
not a second pass. The original completed independently with its own peer IDs
and the above clean logs. Subsequent world checks have one explicit owner.

This closes the observed stable-name replacement defect at the tested scope.
It does not certify impairment, four players, realm transfer, remote Steam,
durable ordinary catch delivery or the separate guest-leave observation.

Source is committed as `dbc7c1b75` in draft
https://github.com/MJohnsonWellabe/Tetherbound/pull/149, stacked on148.
Required Playground boot exits0 with `smoke: OK` in
`%TEMP%/tetherbound-remote-replacement-playground.log`. Root verified no
`SCRIPT ERROR`, `Parse Error` or `FAIL`; its eight distinct `ERROR:` lines
exactly match `%TEMP%/tetherbound-shared-catch-playground.log` (null material
and known dummy-renderer shutdown diagnostics). This is baseline-equivalent
boot evidence, not an error-free renderer claim. PR149 CI is pending;
PR148 final-head run35505054852 was still running at this checkpoint.

Weekly allowance last verified46% remaining. The owner guard remains: below20%
start no new work, checkpoint and push; stop safely above10%, without a reset
or automatic restart. This checkpoint does not declare the broader goal done.

## Follow-up triage after PR149

PR148 final-head CI35505054852 is terminal:24success,2failure,3skipped.
Multiplayer shard6/job106063719595 fails
`smoke_net_water_mounted_swimming.gd` at the post-dismount HUMAN swimmer check;
the preceding mount-drowning and rider-detach checks pass. Shard3/job106063719580
also fails and requires its own log diagnosis. PR149 CI35505767057 is separate
and was still running when these parent results were inspected.

The earlier guest-flee observation remains unproven as a product defect.
`peer_runner.gd::_step_press` confirms only an injected input edge.
`combat_manager.gd::_tick_active` can skip input during hitstop/catch resolution,
and `_read_player_input` can defer to throwing, burst confirmation or the input
guard. The failed run did not record those gates at the press. The existing
shared-wild smoke already exercises guest withdrawal through last-participant
runtime disposal. No flee behavior change is justified by that log alone.

Ordinary capture durability needs a complete transaction, not an autosave added
after `_resolve_catch`. Current `_host_catch_finished` publishes completion and
`_finalize_shared_host_fight` retires the source before the recipient saves.
The existing Water journal demonstrates the necessary order: save the host
claim and once-only source flag together, publish, save character ownership and
receipt atomically, then ACK and durably remove the host claim. Failed writes
must roll back before publication; lost ACK must replay without duplication.
The codec and local rollback transaction can be reused, but Water delivery is
realm-specific and uses locator identity. Ordinary delivery needs the persisted
world-instance namespace, authenticated character routing, older-reader save
barriers and one delivery path instead of both direct grant and claim service.
One unresolved claim per origin world is insufficient to enforce the no-reserve
rule across world changes. Pending ownership, departure and the five-slot
ceremony must be settled together before implementation; this audit does not
claim ordinary durable capture is built.

Shard3's only failed smoke is `smoke_net_catch_race.gd`: the seeded race breaks
out and receives `ok:true,caught:false`, but the later same-encounter assertion
finds no record/runtime. The test then cannot seed its second throw. Source
waits900frames on each peer sequentially after the breakout; its own older
comment acknowledges that the resumed opponent may finish the fight in that
window. This does not prove an early cleanup bug. The fixture correction polls
the existing winner-resolution/loser-refusal signals, requires the live active
breakout boundary, and immediately uses the existing AI-pause/RNG fixture for
the second throw. It never recreates the fight or changes a catch probability.
Runtime verification of that correction is recorded below when complete.

### Water dismount diagnostic boundary

Local reproduction `water-net-local-3080927` exits1 with29passing checks and
one unique failure, printed again in the summary. The client is HUMAN mode1,
revision562, at y=-0.7 with96.05human stamina. The host's raw and applied aquatic
state remain MOUNTED mode2, revision453, with the old y2.145mount-seat pose,
although `net_riding=false` arrived. Coordinator/peer logs have no script or
engine errors. Log: `%TEMP%/tetherbound-water-dismount-net.log`; peer logs:
`%TEMP%/water-net-local-3080927/`.

Second run `water-net-local-3126845` passes30checks without any gameplay edit.
Outbound owner state is HUMAN revision585; host raw state is HUMAN582 and
applied state HUMAN574, with matching swimmer position. Both peer error scans
are empty. Log: `%TEMP%/tetherbound-water-dismount-net-second.log`; peer logs:
`%TEMP%/water-net-local-3126845/`. The second run adds only sender-proxy fields
to the existing Water probe and failure detail. The explicit visibility getter
reported false even when delivery succeeded; that misleading diagnostic was
removed rather than treated as a cause.

**Unresolved:** the first sample is a stale continuous snapshot, not failed
local dismount or rejection by the aquatic-state decoder. Producer/transport
pacing remains undiagnosed. A subsequent pass is not a fix. No swimmer state,
transport reliability, MTU, threshold or wait was changed to force acceptance.
The retained test/probe details make the next CI failure useful; no further
local Water reruns are justified without a new source hypothesis.

### Catch fixture correction verified

Run `net-run-local-3031250` exits0 with61passing checks and no failures in
`%TEMP%/tetherbound-catch-race-boundary.log`. The race breaks out, the same live
encounter is reseeded, and the guest catches its canonical individual only
after host confirmation. Root scanned coordinator and both peer logs: no
`ERROR:` or `SCRIPT ERROR`. Peer evidence is under
`%APPDATA%/Godot/app_userdata/Tetherbound/net-runs/net-run-local-3031250/`.
This repairs the observation boundary without relaxing any catch invariant.

Required Playground exits0 with `smoke: OK` in
`%TEMP%/tetherbound-ci-boundary-playground.log`. Root verified zero script/parse
failures and the same eight distinct null-material/dummy-renderer cleanup error
lines as the preceding replacement baseline. The final diagnostic-only removal
of the misleading visibility getter also passes `peer_runner.gd --check-only`.
No gameplay, schema, save or transport changes are included in this batch.

PR149 run35505767057 subsequently reports two failed multiplayer jobs while
other jobs remain live. Shard3/job106065566274 repeats the same two catch-race
boundary failures repaired here. Shard1/job106065566328 fails the pre-existing
friendly-fire fixture in `smoke_net_shared_wild_fight.gd`: host action9003 is a
miss, followed by the replay refusal. Host geometry has the teammate2.93m away
but approximately22degrees off the submitted fixed facing, outside the move's
13degree half-cone; both friendly and opponent candidates have `connects:false`.
Root inspected the correlated receipt and source assertion. All later shared
wild lifetime checks pass. This is not a regression diagnosis against PR149's
node-retirement change. Fixing that fixture's actual aimed geometry is the next
bounded verification repair; changing damage or widening gameplay hit cones is
not justified. Full log: `%TEMP%/tetherbound-pr149-shard1.log`.

Weekly allowance was last verified45% remaining. The20% wind-down and safe stop
above10% remain unchanged; no reset was used.

## Guest-originated ordinary wild entry: deferred after owner priority correction

Read-only audit against PR153/43d727ffa confirms that
`encounter_director.gd::_start_fight` calls the guest's local manager before
`_open_encounter_if_networked` returns for non-hosts. This still permits an
unbound local fight. Terra traced identity/admission; Sol inspected the
construction paths. No production file changed and no runtime test was run
for this audit. The owner then challenged the multiplayer concentration;
root stopped the attempt and returned execution priority to the expedition.

A future correction must request an exact authored wild identity before
manager begin. Seeded order/member identities and authored names exist;
dynamic fallback names cannot be trusted as cross-peer identities. The host
must validate its own body, admitted realm, deployed creature, range and
gate/cooldown, then target its independent runtime at the requester without
binding the host's local manager. Request correlation, idempotency, timeout/
late-admission cleanup and suppression/restoration of the exact guest ambient
body are required together. Existing proxy presentation alone does not solve
this. Cloudreach ground/air and Water ground/surface construction all need
coverage. This is deferred implementation, not an accepted multiplayer path.

Latest allowance check:42% remaining; guard unchanged. No additional engine
run or guest-entry branch code was produced after the priority correction.

## X05 lane: compatibility, lossy refusal, reconnect seat and export runtime

Baseline `origin/main` 47774c350. Linux container, 4 cores, stock
Godot 4.7.stable.official.5b4e0cb0f, headless. All net runs used
`tools/net/run_net_smoke.sh` with isolated `TB_NET_RUN_ID`/`--out`, one
at a time. The one parallel attempt starved a 4-core machine and is
discarded. Loopback and the harness loss proxy (`tools/net/udp_proxy.gd`)
are not internet or relay proof.

**Build/content compatibility gate** (`ralph/x05-compat-gate`).
- The hello carries `build_fingerprint.gd::current()`: wire protocol, engine
  major.minor.patch.status, and SHA-256 over sorted `res://data/**/*.json`.
- The host refuses a mismatch with `incompatible_version` before the Steam
  membership result is used, and before identity, capacity, realm
  preparation or snapshot. The reason names which part differs.
- The Steam lobby publishes the short token. A joiner refuses a mismatched
  lobby before dialling, and a Steam protocol refusal now uses the same code.
- Two-process smoke `smoke_net_join_version_mismatch.gd`: 12/0. The refusal
  arrived in 193–207 ms, and the host registry and world hash were
  unchanged (`x05-compat-mismatch-smoke.log`, `x05-stack1-mismatch.log`).
- Units: `test_session_build_compat.gd` plus Steam lobby cases.
- Open: nothing yet proves an exported PCK hashes identically to the editor
  run. JSON ships as-is under `all_resources`, but no export was compared.

**A refusal lost on a lossy link** (`ralph/x05-refusal-linger`).
- Measured on main's six-frame flush at 30% loss and 150±30 ms delay. In
  both valid baseline runs the host logged the `incompatible_version`
  refusal and the client never received it. The client waited out the
  36 s join budget (`x05-refusal-loss30-before-*.log`). The third baseline
  run failed to launch peers and is excluded.
- Cause: ENet's disconnect discards unacknowledged reliable packets, and
  the 135 s realm-loading peer timeout hides the drop.
- Fix: refusal, kick, snapshot abort and host exit keep the link until the
  other side closes it (10 s per peer, 5 s for a host close).
- After the fix, at 30% loss, four of four valid runs received the specific
  reason in 3.1, 3.3, 5.1 and 6.4 s (`x05-refusal-loss30-after-*.log`).
  One run was a proxy-start infrastructure failure under CPU contention
  and was stopped.
- These are small samples on a synthetic proxy, not a delivery guarantee.
- A host-exit run at 30% loss could not test exit at all: the joiner never
  finished the snapshot (`x05-stack1-hostexit_loss.log`). At 10% loss,
  host/join/leave passed 27/0 (`x05-stack2-hjl_loss10.log`).

**120 s reconnect seat** (`ralph/x05-reconnect-reservation`, stacked on
both branches above).
- When an admitted joiner's link drops, the host holds a seat for that
  character for `session.reconnect_window_s`. Other characters get a
  readable `session_full` reason. The same character takes the seat back
  under a new transport peer.
- A deliberate leave sends a goodbye and waits up to 1.5 s for the host to
  close the link, so no seat is held.
- Kick, refusal and snapshot abort never reserve. Hellos are refused while
  the host is closing. Ledger intents from peers outside the registry are
  dropped.
- Smoke `smoke_net_reconnect_reservation.gd` (three processes) first
  failed on the deliberate-leave step: the goodbye was discarded by the
  client's own disconnect (`x05-stack1-reservation.log`). After the
  host-side close it passes 18/0 (`x05-stack2-reservation.log`).
- Units: `test_session_reconnect_reservation.gd`, which also lapses the
  seat at exactly 120 s with an explicit clock.
- Limitation: a seat is held only once the host detects the drop. A clean
  close is detected immediately. A crash or cable pull is detected only
  after ENet's 135–180 s timeout, and until then the returning character is
  refused as `character_in_use`. That behaviour is unchanged from main and
  is not fixed here.

**Final runs on the stacked branch** (`x05-final-*.log`, after both review
rounds):
- `reconnect_reservation` 18/0
- `join_version_mismatch` 12/0 clean and 12/0 at 30% loss
- `identity_admission` 23/0
- `host_join_leave` 27/0
- `four_peer_session` 31/0 (host + 3 on loopback)
- `reconnect_keeps_character` 84/0
- `join_by_address` 17/0
- focused units 108/0

**Invites accepted with the game open, closed or hosting.** Coordinator
tests in `test_steam_lobby.gd` check that:
- a running `join_requested` and a cold `getLaunchCommandLine`
  `+connect_lobby` produce the same single pending invite and signal;
- nothing is joined before character selection;
- an invite that arrives while hosting stays pending with a reason.

This is mock-native coverage. Real Steam accept paths need the owner
dependencies in PR #233.

**Export runtime** (`ralph/x05-steam-templates`).
- The current release export is stock Godot. Its Windows preset
  `custom_template/*` is blank and `release.yml` installs stock templates,
  so invitations are unavailable in a release build.
- `setup_steam_runtime.py --templates` now installs the pinned GodotSteam
  4.20 templates. The archive `06216a20…` and all three win64 file hashes
  were re-derived here and match the values recorded earlier.
- A PCK exported by stock 4.7 runs under the GodotSteam linux64 template
  with the `Steam` singleton and `SteamMultiplayerPeer` present.
- Without the Steam API library beside the executable, the game does not
  launch (exit 127).
- The template accepts neither `--path` nor `--main-pack`
  (`x05-godotsteam-linux-template-probe.log`).
- Windows was not run here. The preset, release workflow and packaging
  changes belong to X07 and need a coordinator grant.

**Refusal capture.** `x05-refusal-mismatch-title-1280x720.png` was
produced by `tools/net/capture_join_refusal.gd`:
- A headless `--mp-host 27150` host and a rendered 1280×720 opengl3 client,
  launched with `--mp-join` and a mismatched content override. Nothing is
  staged.
- The client builds the world, dials, receives the host's
  `incompatible_version` verdict (host log line in
  `x05-refusal-capture-host.log`) and returns to Join a Game.
- The reason is shown in the status line, with controller focus on Enter an
  Address.
- This is evidence that the text reaches the player. It is not a visual or
  UX verdict. The reason uses the existing small amber status style, and
  720p readability belongs to X03.
- Not captured: the held-seat reason and the Steam lobby mismatch reason.
  The Steam reason needs a native Steam client.

**Opt-in Steam release packaging** (`ralph/x05-steam-release`, under a
coordinator SHARED-FILE GRANT for `.github/workflows/release.yml`).
- A new `ship_steam_runtime` dispatch input and a repository variable,
  `TETHERBOUND_SHIP_STEAM_RUNTIME`, both default off. When on, the release
  job:
  - installs the pinned win64 templates;
  - points only that run's Windows preset at them
    (`setup_steam_runtime.py --configure-preset`);
  - copies `steam_api64.dll` beside the exe.
- Switching templates and shipping the DLL are one switch on purpose: the
  exported exe imports `steam_api64.dll` and cannot start without it.
- Off, the release is the unchanged stock path. `export_presets.cfg` is not
  modified in git.
- Dry run of the opt-in steps: `x05-windows-steam-export-dryrun.log`.
- Open, and the owner's call: Steamworks redistribution sign-off before
  anyone turns it on. Not run: the exe on Windows, and the CI release job
  itself.

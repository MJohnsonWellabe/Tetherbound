# Varga focused actual-world diagnosis — 2026-09-09

## Prelaunch written brief

Authorized by root: one synthetic focused actual-world attempt, maximum ten
minutes, with a resource guard stopping above 90% system commit or 400 processes.
No copied save, full opening/chapter replay or repeated attempt is authorized.

Fixture: fresh isolated APPDATA/LOCALAPPDATA; production router enters Stormwood
using only its `realm_key_stormwood` prerequisite. Varga's production normalized
spec has no `requires_flags`, so **zero Stormwood prerequisite flags** are seeded.
Party uses the existing continuous entry species Sparkit, Mudsnout, Bramblebun,
Terrapup and Brooktail, each level44. No tools or other items needed. After shell,
population and arrival settle, place only the human once at Varga's authored
x/z minus2m in z, y=production ground+0.3m, before ordinary recall/challenge.
Thereafter no setup HP/pose/progression mutation. Production progression resulting
from ordinary combat is observed, not credited as campaign continuity.

Driver: derived `smoke_stormwood_continuous.gd::Segment`, binding the real world,
controller navigator and production signals. Inherited `_defeat_trainer` and
`_fight_current_encounter` keep 180-second duel bound, five-minute roster bound,
900ms wall quick cadence, 0.8 quick-reach approach and 8x/480Hz simulation. Input
overrides only count then delegate to the original parser. A read-only sampler
captures each new impact plus one-second state. Final quick-release interception
records terminal state before inherited cleanup; outer exit also records terminal.

Collector captures replica/host/ally positions, HP, actual host impact geometry
and verdicts, manager action/cooldown/aim and input counts. Incremental JSONL
payload is flushed under ignored `.artifacts`; report records verdict only.

Expected limits: fresh synthetic health cannot disprove historical attrition;
minimal admission prerequisites do not reproduce the historical chapter state.
One actual-world attempt only. Any startup, sampler, combat or engine failure is
retained and reported before root chooses further work.

## Result: reproduced active third-duel stall with actionable geometry

The one actual-world attempt won the first two production Varga duels, then
timed out in her third at the unchanged 180 seconds. Terminal state was retained
**before** inherited input cleanup at JSONL line505. This is failed combat with
useful diagnostic evidence, not a pass or historical-campaign completion.

All200 captured third-round host strikes were **accepted misses**: no refusals,
no hits, Stormraven remained311.6/311.6HP. At terminal the authoritative opponent
and replica agreed at(-630,56.45764,2386). The ally was at
(-411.60208,34.56906,1442.69177), approximately968m away, versus5.9725m quick
reach. Manager remained ACTIVE, quick_ready=true, cooldown0, input_guard0,
aiming=false. Stick request remained nonzero toward the opponent and velocity
was nearzero. The immediate stall mechanism in this run is therefore a remotely
staged player/ally unable to reach an opponent retained at Varga, not missing
quick input, host cooldown refusal, HP exhaustion of the enemy, vertical hit
geometry or a disagreeing enemy replica.

### First displacement and supported source explanation

- JSONL121, wall114647ms, still round1: human(-629.48370,54.96621,2379.49634),
  ally still beside Varga; enemy17.16388HP.
- JSONL122, wall115391ms, still round1: human jumps to exactly
  (-408,34.80231,1427), while ally remains by Varga and enemy7.40819HP.
- JSONL124, wall116330ms: the second opponent reaches0HP while human remains
  at the remote position.
- JSONL125, wall116823ms, round2 entry: human(-414.77371,35.16506,1429.43506)
  and ally(-408.58636,34.86918,1429.53296). Enemy remains at Varga.
- Subsequent ordinary approach moves ally toward the opponent until near
  z1442.69, where it remains for the rest of the duel.

The first human destination matches **Lantern Pools recovery** exactly:
`stormwood_camps.json` authors(-410,1425), and
`player_death.gd::resolve_safe_camp` offsets(+2,+2). This fixture has no
`stormwood:rodline_linked`, so the nearer Rodline recovery camp is gated.
`PlayerDeath._die_now` chooses camp recovery and `_respawn` moves the human
without notifying the hosted encounter. On the next roster round,
`stormwood_encounter_director.gd:133` calls manager.begin around the human's new
location, then restores only the enemy replica to host truth at:139. The inherited
manager stages the ally and bounded arena near that human; creature_body:1643
holds the ally inside that local arena. Host retains the participant and opponent.

**Inference boundary:** player death signal, vitals and lightning events were not
sampled. The exact camp match strongly supports finalized death/respawn, but the
initiating damage source was not directly observed. `stormwood_lightning.gd:159–163`
can reduce human health and emit died during creature combat; it has no combat
guard. Lightning is the leading source explanation, not a directly captured death
cause. The original chapter run had different earned flags and health; these
results do not establish its exact recovery camp or damage sequence.

### Observer failures and limits

The observer produced five script errors at probe:155 when a finished round's
`manager.enemy_body()` returned a previously freed replica. Typed assignment
failed before collector validation. Successful-round terminal captures are thus
missing. Active third-duel capture remained functional and retained all200 actual
host action ids plus unconditional terminal-before-release and outer terminal.
There were six engine errors total: these five sampler errors and the expected
production-encounter timeout. Thirteen preexisting interpolation/terrain-mipmap
warnings were present. No error-free or clean runtime claim is made.

The director ally body had no `instance` at sampling time, so body-based ally
species/health fields were absent. Future telemetry must read manager.active_creature
and human vitals independently, and validate raw Variant body references before
typed assignment. Do not turn absent ally health into a healthy/exhausted claim.
No code changed during the world run and no second world attempt was launched.

## Verification and retained payloads

Artifact root `.artifacts/varga-focused-20260909T0500/` has508 JSONL rows,
`console.log`, `engine.log`, `stderr.log`, `resources.csv`, wrapper `run.ps1` and
`result.json`. The directory basename is a unique identifier, not the actual start
clock. Actual start2026-09-09T04:37:10.8995311Z, end04:42:11.3996391Z.
Owned chain launcher21200, conhost19564, engine11804 was absent after completion.
The wrapper exit_code is null after its descendant chain disappeared; explicit
terminal false result and source quit(1) path establish failure, not numeric
wrapper exit-code evidence. No resource stop:118 samples, peak57.56% system
commit,266 processes,1,325,260,800 owned private bytes and1,005,924,352 working set.

The initial wrapper invocation hit Windows script execution policy before any
Godot launched. Running that same wrapper with process-local ExecutionPolicy
Bypass launched the **one** actual-world attempt. It created unused runtime-profile
for both APPDATA and LOCALAPPDATA and set TETHERBOUND_TELEMETRY_OUTPUT to the
JSONL artifact. The command executed was:

```text
Godot_v4.7-stable_win64_console.exe --headless --path C:/Projects/Tetherbound --script res://tools/probe_varga_focused.gd --log-file C:/Projects/Tetherbound/.artifacts/varga-focused-20260909T0500/engine.log
```

`--check-only` on the focused probe passed before launch. Revised minimal host
collector proof passed13 checks, zero engine errors,920ms script elapsed in
helper-proof.log; it verifies record level39 and entirely missing fight/bodies.
It did not cover a stale freed-reference return at the caller boundary, the gap
the actual-world run exposed. Ten-minute external guard and590-second internal
watchdog remained intact.

| Executed file / artifact | SHA-256 |
|---|---|
| tools/probe_varga_focused.gd | `5A2EC423FE0CC24F314662D6AB7E94020CFAB86262C2D5B9F616EC9580821A7C` |
| tests/helpers/stormwood_combat_telemetry.gd | `568143F3DD8E5C03F7285A3D6F20F9796268A46DDDEB206187F620069A9C50EF` |
| unchanged continuous driver | `D3A0AF00F4B8F10242C8FF2054797067DF0D6671B26C38364525E9961E5CA13E` |
| telemetry.jsonl | `59A84C774A4698FB522135DA2B1963B2C9EAED5EF66B88B423416F8D0C9B8772` |
| engine.log | `4F4F3BA519E7945AACAB48B631E6373A541E3A654CFD2B38E7ABBADB1BD45B31` |

## Proposed bounded repair and native regression, not implemented

Do not grant blanket lightning immunity. Preserve transient downed/revive,
final-death satchels, recovery camp choice and the five-creature party.

1. Emit a finalized-death signal from PlayerDeath._die_now after Game exists but
   before fade/respawn. Never emit from the transient _on_died/request_down branch.
2. Stormwood runtime wires this signal to a hub handler. Locally latch withdrawal
   for that trainer, clear queued state, and release active combat/deployment/camera
   through explicit loss cleanup before recovery can relocate the human. Ensure
   an already-RESOLVING won round cannot cause a fresh roster round to start after
   final death. Do not remove previously earned individual-round XP.
3. Send self-withdrawal over the existing reliable Session encounter channel. Host
   determines peer from sender, never a payload target. Unlike ordinary disengage,
   finalized-death withdrawal must apply during the done-record/between-roster gap.
   Host removes only that peer with fight.leave; others continue at existing HP,
   while the final participant's departure ends the trainer sequence unwon.
4. Target a withdrawal acknowledgement to the departing peer even when others
   remain. A shared finished=false event would wrongly terminate other peers.
   Retire the departing local identity/pending state and suppress stale queued
   participant snapshots until an explicit fresh challenge. Ordinary done-round
   disengage retains its current meaning. No death-triggered victory/reward event.
   Existing contributors payout policy after another peer's eventual legitimate
   victory should not be silently redesigned by this fix.

Native regression should instantiate actual PlayerDeath and hosted hub/fight with
small synthetic rig/transport adapters, authored roster and ground callback; no
terrain or chapter route. Drive actual finalized death and recovery rather than
calling only a new helper. Cases: solo active round; solo done/between-round gap;
one of two participants dies; transient downed accepted (no withdrawal); replayed
old state after withdrawal; duplicate final-death notification; self-only sender
authority. Assert local manager/deployed-control released before relocation,
dead peer absent from authority, no next roster for sole departed player, other
peer still active at same HP/round, no false win or reward, and original
satchel/camp/party behavior retained. Include targeted client acknowledgement and
pending-state handling, not merely host-side participant-array assertions.

## Authorized lifecycle repair and focused validation

Root subsequently authorized the bounded production repair. It is implemented in:

- `scripts/world/player_death.gd`: signal `finalized_death` emitted from actual
  `_die_now` before fade/recovery, after the Game existence check. No transient
  downed/revive path change.
- `scripts/world/stormwood_combat_runtime.gd`: wires the realm hub after death.build.
- `scripts/world/stormwood_encounter_hub.gd`: immediately retires local control,
  clears pending roster state and latches this trainer against in-flight snapshots.
  A reliable `finalized_death_withdrawal` uses the authenticated sender, handles
  the done/between-round gap and calls existing fight.leave. Targeted `withdrawn`
  acknowledgement cannot retire an unrelated later fight; explicit challenge
  clears the latch. Existing contributor accounting remains unchanged.
- `scripts/combat/stormwood_combat_manager.gd`: `abort_for_finalized_death`
  unbinds ordinary disengage and finishes with loss, including an already-resolving
  won round. It neither faints/heals party members nor awards a victory.

Before production edits, `smoke_stormwood_finalized_death.gd -- --negative-control`
drove actual PlayerDeath death and tweened respawn. Both negative-control checks
passed: manager remained ACTIVE, participant remained admitted, and the human
actually relocated while fighting. This confirms the finalized-death lifecycle
defect independently of the inferred original lightning trigger.

The first fixed native run passed26/27 checks but had a fixture assertion error:
the fresh-challenge test replayed a *done* old record in its between-round case,
which production correctly does not start. Fixture corrected to use a fresh real
authority.open record; no acceptance rule was weakened. Added actual inventory
drop assertions. Corrected final native run: **29 checks, zero failures**,7.340s
tool wall time, zero engine errors/warnings. Covers solo active and resolving-won
gap, immediate control release before movement, actual camp/vitals recovery and
persistent satchel drop, unchanged party, idempotence, stale-state suppression,
fresh challenge, delayed client request, authenticated sender-only removal with
another participant surviving at unchanged HP/round, targeted acknowledgement,
preserved contributors and transient downed with no request.

Updated collector proof: **15 checks passed**, zero engine errors/warnings,
926ms script elapsed. It now reads manager.active_creature independently of body
instance, verifies HP/species despite a null body instance, and validates a real
freed Variant through `live_body` before typed assignment. Focused probe now uses
that guard and records human vitals. These fixes were made after the retained
actual-world failure; **no corrected actual-world rerun** is claimed.

Adjacent `test_player_death.gd,test_stormwood_hosted_combat.gd`:12 tests,
25 assertions,0 failed, zero engine errors/warnings. Production scoped diff check
passed. All these focused runs used new isolated profile under
`.artifacts/varga-finalized-death-20260909/`; logs are negative.log, fixed1.log,
fixed2.log, final.log, collector-final.log, adjacent.log. The final native command:

```text
Godot_v4.7-stable_win64_console.exe --headless --path C:/Projects/Tetherbound --script res://tests/smoke_stormwood_finalized_death.gd --log-file C:/Projects/Tetherbound/.artifacts/varga-finalized-death-20260909/final.log
```

The negative control preceded production changes; it is not expected to pass on
the repaired tree. All shared-death and multiplayer CI requirements remain for
root integration. Root separately owns the actual two-peer regression and its
evidence; none is asserted here. No additional fullworld/chapter run was launched
by this lane, and production lightning, Session, Game and base CombatManager
remain untouched.

Final focused production/test SHA-256 identities (29-check run includes the
guard preventing a withdrawal acknowledgement from touching another fight):

| File | SHA-256 |
|---|---|
| player_death.gd | `4888F42642B7B98132377E6555C4D0021F7BA5D6789F2B9FB1128139C7889945` |
| stormwood_combat_runtime.gd | `93C43450C4D9716F2894AF6B267F60DEDCBD5B9749220B1F7FB4818B29306713` |
| stormwood_encounter_hub.gd | `3FB3ED98AD83939C98493129ACA201850B4F03465207A14B24A97051BE807762` |
| stormwood_combat_manager.gd | `38FA93D6DCE24056B42B3441128CF60BF5EB9DF36B4509B82DBF13F88A850FA2` |
| smoke_stormwood_finalized_death.gd | `84500C8E9C4D66075C2E76EA2EAAA2B69DDD0B7584EB33DA53F58938058400BA` |

## Review corrections: observation and in-flight admission

Independent review found two concrete lifecycle gaps in the initial repair:
the withdrawal latch hid nonparticipant snapshots needed to observe a surviving
peer; and final death before the first accepted start snapshot had no local or
pending-state trainer id to withdraw. Both were corrected after root's actual
two-peer run ended and source freeze was explicitly lifted.

The hub now routes nonparticipant states to the observer before consulting the
withdrawal latch. Stale participant snapshots remain suppressed. It also records
the explicit pending challenge id; final death uses that id when admission is
still in flight, latches locally, then sends self-withdrawal behind the original
start on the existing reliable channel. Matching refusal, successful admission
and withdrawal clear that pending identity; unrelated refusal does not.

Expanded native proof passed **37 checks**, zero failures/errors/warnings,
9.523s tool wall time, first attempt after these corrections. Added observation
counter verifies that the recovered participant sees the surviving fight without
resuming control. Delayed-admission test verifies start-before-withdrawal request
order, blocks the first late accepted snapshot, removes the late host membership,
and tests pending-identity cleanup and fresh admission. Evidence:
`.artifacts/varga-finalized-death-20260909/review-fixes.log`.

No additional actual-world or two-peer run was performed by this lane. The older
29-check hashes above describe that exact earlier test, not this later revision.

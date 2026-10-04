# Preserve observations from the peer's nominal command window

The original-budget Warden run at ROOT `83d9dada76b6127c26456767ec3b20c9c74fa8fd`
failed with no verdict: native exit 1 after 256.578 seconds, one failed check
and an empty fatal reason. Both peers reached the actual host challenge/guest
join; victory, reward, reload and rejoin assertions did not run. The 3,250
source hashes before and after match. All four raw log hashes match the
receipt; its error census is empty and all engine handles ended.
The exact failed NET_RUN bytes are committed as `failed-net-run-83d9.json`.
The larger receipt and all logs are copied unchanged into Foundation's ignored
scratch and SHA-pinned in `failed-attempt-summary.json`. The original `31e280`
source packet and failed ROOT artifacts are untouched.

## What the returned evidence establishes

The four retained host samples are all later than the peer's nominal 95-second
window, measured from their own `started_ms`. The actual coordinator send,
receive, expiry and quit times are not recorded. Cross-process monotonic
clocks cannot supply those missing times. Zero enemy HP and cleared authority
in the final samples therefore do not prove a pre-deadline combat stall.
The host's final heartbeat has only itself in `session_peers`, while the guest
has exited normally; cleanup is a live confounder, not a proven fight cause.

| Peer elapsed seconds | Native physics since driver start | Driver's manual frames | Difference | Completed taps | Enemy HP | Accepted action |
|---:|---:|---:|---:|---:|---:|---:|
| 96.301 | 3743 | 3064 | 679 | 76 | 6 | 64 |
| 97.361 | 3803 | 3104 | 699 | 78 | 6 | 66 |
| 98.324 | 3863 | 3150 | 713 | 81 | 0 | 0 |
| 99.316 | 3923 | 3204 | 719 | 83 | 0 | 0 |

These late samples establish different native and manual counts, well beyond
a one-callback resume ordering difference. They show native service averaging
about 39.5 physics callbacks per second since driver start by the last sample,
with 702 process frames, rather than proving nominal 60-Hz service. They do
not establish which pre-deadline interval was slow or why the battle did not
finish. The driver retains a fixed +3 after each completed tap; the unchanged
`press_inject.tap` awaits two process frames and at least two explicit physics
frames. More physics callbacks can run while a process-frame await is pending.
The precise completed/in-flight tap contribution is missing from this attempt.

All samples encountered four opponents with one queued; missing-body checks
are zero, not-fighting checks 285 and quick-not-ready checks 62. These are
cumulative values sampled after the nominal window, not time-resolved proof
of the failing interval. Empty retained refusal is not proof every input was
admitted. Submitted and accepted action counters have different semantics.
The host raw log also retains a JSON NaN-to-null warning on the existing probe
value reply, and a refused fly landing followed by a grant. Neither has exact
fight timing or establishes the Warden failure. No raw error is suppressed.

## Minimal TEST-only proposal

The two allocated test files change: peer_runner.gd has 70 additions and two
replacements; net_harness.gd has 14 additions. No production file changes.
The existing step message's actual `budget_frames` is copied for diagnostics;
its original 60-Hz-plus-five-second formula defines a retention window.
For this 5,400-frame command that window is 95,000 milliseconds. The original
5,160-frame driver budget remains separate and untouched.

The sampler records its peer timestamp at entry and keeps the latest four
samples with peer elapsed time strictly below that nominal allowance. At or
after the allowance, it stops appending and stops live combat getter work,
while the original heartbeat and game/driver continue normally. Cleanup thus
cannot overwrite the preserved ring with later fight state. The metadata
exposes the current peer elapsed time, nominal allowance, `retention_closed`,
`timing_basis=peer_driver_start` and `coordinator_deadline_known=false`.
This is observation retention, not a new timeout, cancellation or execution
gate. It does not know the coordinator's actual deadline: delivery delay,
process clock origins and coordinator polling latency remain uncertain.
Even a retained sample cannot automatically be called pre-coordinator-cutoff.
A first heartbeat after the window yields an explicitly empty retained ring.

Three lightweight counter writes around the existing tap copy the already
maintained `_physics_count`: start, cumulative completed-tap ticks, and clear
of the in-flight marker. The sampler derives current in-flight ticks from
that marker. There is no new await, input, clock/production query in the driver
loop or physics count/budget adjustment. Successful completed taps still add
exactly the original +3 to the driver's manual counter. The diagnostics let
ROOT separate actual tap tick consumption from that manual accounting and
from other frame service, without assuming tap duration or changing it.

The sampler also reads actual manager state, resolve timer/outcome, enemy
fainted state and the rendered encounter's phase/sequence. These distinguish
ACTIVE from the normal RESOLVING pause; is_fighting includes both, and quick
readiness alone is not that distinction. An existing read-only encounter
record getter returns its current dictionary; only phase/sequence scalars are
selected, never the full record or participant arrays.

For killing-action evidence the observer connects to the already-exposed
host_strike_finished signal, the same observation surface existing test tools
use. It keeps one bounded row only when the intent matches the actual encounter
bound at step start and the original verdict's delta says killed=true. The row
carries the actual signal author, intent/action/target identity and selected
verdict scalars. Missing binding, killing signal or field remains unknown/null;
no author or verdict is reconstructed from HP. Unrelated encounters and
non-killing completions are ignored. The connection is detached when the step
returns. Each heartbeat sample deep-copies this small row, so a later kill or
cleanup cannot mutate the preserved sample. This only observes existing
notifications; it submits no strike and rewrites no production verdict.

The sampler remains bounded to four samples, one killing row, nine capped
sample string sites and five capped killing-signal string sites.
No new protocol message, heartbeat tick, log line, save, payout, party, HP,
stride, placement, settle, readiness, physics or wall allowance is introduced.
All production/director files, the original Warden smoke and press injection
are unchanged. The coordinator change is observation/report metadata only, as
described below; its runtime control flow and original fields are preserved. The staged party/arena/HP fixtures still test
network reward wiring; no naturally earned gameplay is claimed.

## Coordinator observation at the actual timeout branch

The existing no-verdict timeout branch now takes one detached copy of that
peer's then-current last_heartbeat and records command id/action, coordinator
observation ticks and original deadline. This occurs after the existing pump,
verdict/fatal/exit checks, before the unchanged timeout return and finish()
teardown. A clearly named command_timeout_observation field in NET_RUN exposes
it. The ordinary latest heartbeat continues to update normally during cleanup;
this separate copy cannot be overwritten by those later packets.

The snapshot is bounded by the inspected owned producer: fixed heartbeat
fields, at most four bounded fight samples and their bounded killing rows.
Only one timeout observation is retained per peer. Missing heartbeat is null
with heartbeat_known=false; receive time/age is reported when available.
Receive age is measured on the coordinator clock and is not the peer sample's
age. Staleness is visible; no freshness or causal claim is manufactured.

This establishes what the coordinator had received at timeout detection before
teardown, rather than equating the peer's nominal window with the actual
coordinator deadline. Polling may detect expiration later than the stored
deadline; that delay is visible in observed_ms versus deadline_ms. It still
cannot prove the production time of an absent or stale sample. There is no
change to pumping/send order, normal heartbeat, command args, protocol/cadence,
timeout/verdict, actor lifecycle or cleanup. No broader report rewrite is needed.

## Source checks and remaining boundary

Removing the observational additions restores the whole `31e280` peer runner
byte-for-byte. Driver and dispatch reverse independently to their originals;
all 177 other existing peer functions, constants and driver awaits are
unchanged. The coordinator step and JSON writer independently reverse to their
originals, and the full harness restores byte-for-byte after removing the two
metadata additions. Its other functions, pumping, send, deadlines and cleanup
are unchanged.
Whitespace and read-only patch application to frozen ROOT pass. Nineteen pure
Python controls exercise ring freezing, rejection of the four actual late
timestamps, strict/fractional boundaries, command-budget distinction, bounded
memory, no reads when stopped, per-step clearing and scalar tick accounting. Additional controls cover exact
signal scope, non-killing/unbound/returned events, detached killing rows and
coordinator snapshots, unknown heartbeat and explicit old receive age.
They use synthetic timestamps/counters and are not Godot or native tests;
no missing pre-deadline combat state is fabricated.

The source cut pins ROOT/parent/preimage/candidate, minimal patch, raw failed
receipt and controls. No engine, parser, import, render, export, CI, push,
new branch/chat/agent or ROOT write occurred here. ROOT/F29 review and a ROOT
original-budget affected witness remain necessary. Warden's actual unfinished
fight cause and acceptance remain open, with no timeout or success waiver.

# Bounded trainer-driver observations before the verdict deadline

This TEST-ONLY source proposal changes only `tools/net/peer_runner.gd`.
The original Warden failure is still unexplained. Its final driver FAIL detail
was not reached before the coordinator's 95-second command deadline, so the
retained artifact has no driver-local frame, swing or readiness evidence.
The proposal carries four bounded samples in optional `trainer_fight` metadata
on the already-existing heartbeat. It changes no verdict or success condition.

## Existing mechanism

The peer connects `_on_physics_frame` independently of the serial control
command loop. It sends a heartbeat every 60 physics frames even while that
loop awaits a long fight step. The coordinator stores the whole heartbeat in
`last_heartbeat` and writes it unchanged into `NET_RUN.json`; it only consults
existing `state_hash` for the three-entry hash history and desync logic.
There is no allowlist rejecting harmless heartbeat metadata in this path.
The historical header's `docs/specs/MP_NET_HARNESS_CONTRACT.md` is absent from
the current checkout. The present source and owning MULTIPLAYER contract were
inspected; no new message type or coordinator/protocol mutation is required.

Every existing heartbeat field is built with its original expression and
order, then the optional metadata is attached and the same `_send` runs once.
The hash computation, liveness detector, default 60-frame cadence and native
raw logs are unchanged. No extra message, tick, timer, polling loop, log line,
query per driver frame or awaited operation is introduced. The driver's added
writes copy its locals or increment counts at branches it already took.
Additional live getters run only once per existing heartbeat while the driver
is running. They are existing read-only getters; no scene traversal or full
party, encounter, strike receipt or save snapshot is copied for diagnostics.

## Evidence carried

Each sample includes step-start and sample monotonic times, process/physics
counts, the driver's last completed local frame count, its unchanged budget
and stride, completed injected swings, distinct opponent names encountered,
not-fighting check/streak counts, missing-body checks and quick-not-ready
checks. Phase names identify ordinary physics waiting, body settling, input
injection and payout settling. These names are observations, never decisions.

Live samples include trainer activity, queued opponents (excluding the one on
the field), fighting/readiness, valid enemy/ally bodies, enemy identity and
HP/max HP, active HP/faint state, manager action/timer/cooldown/buffered attack,
current encounter identity and submitted action counter. The existing
`strike_authority_state` supplies a detached four-integer host authority row:
last accepted action, accepted time, deadline and cooldown. Availability is
explicit when the host arbiter is absent. The manager's retained refusal is
limited to kind, code and reason; it may predate this step and is not a
per-swing correlated refusal. Submitted actions are not assumed accepted.

Four samples allow adjacent frame/time/HP/queue comparisons after the deadline
without retaining a growing history. Seven strings are capped (32 to 160
characters); no body references or unbounded arrays/payloads enter the wire.
The sample ring is capped after each append. Observation state is cleared at
the next step, marked no longer running when this step returns, and its node
handles are released. It cannot hide a missing verdict or turn FAIL into PASS.

Slow service can be investigated using adjacent monotonic, process, physics
and driver-frame changes, including a stalled input-injection phase. Admission
can be investigated by comparing completed taps, submitted/accepted actions,
manager readiness/cooldown and retained refusal. Missing-body counters and
validity expose skipped attempts. Opponent count, identity and queue expose
round advancement. Not-fighting counts/streaks expose repeated checks between
rounds. Counts describe the actual original branch checks, not elapsed physics
time spent inside every nested wait. Driver frames retain the original manual
accounting (including +3 after injection), and can lag a heartbeat callback
that runs before the awaiting coroutine resumes. Sampling may miss short-lived
states; neither diagnosis nor observation overhead is proven by source review.

## Preservation and validation boundary

The party grant, arena placement, active-creature HP top-up, optional enemy HP
ceiling, four-frame body settle, quick-ready gate, physical `combat_quick` tap,
stride, 5,400-minus-240 driver ceiling, +3 injection accounting, original stop
and success/failure/settle paths remain intact. The coordinator's original
5,400-frame plus five-second wall deadline and all heartbeat/watchdog budgets
remain intact. This remains disclosed synthetic network staging for reward
wiring, not naturally earned gameplay or balance evidence. No production,
director, Game/save, input injection, smoke or coordinator file changed.

Source-only checks removed the observational additions and restored the
complete original peer runner byte-for-byte. The driver, heartbeat base and
step dispatch also reverse independently to their exact originals; all 176
other existing functions, all constants and the driver's await sequence are
unchanged. `git diff --check` and read-only ROOT `git apply --check` passed.
The immutable source cut pins current inspected ROOT preimages, candidate,
patch and protected source hashes. Full peer-runner preimage and minimal patch
are in Foundation's ignored scratch at the receipt paths.

No engine, parser, import, render, export or CI ran here; no push, new branch,
chat, agent or ROOT write occurred. ROOT/F29 review remains required, followed
by ROOT's original-budget affected test to verify parser acceptance, heartbeat
retention and actual driver observations. No timeout waiver, combat repair,
causal finding, criterion MET or self-credit follows from this proposal.

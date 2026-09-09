# Realm transition design review — 2026-09-09

Verdict: the transport mechanism and shared scope are justified, but the current
brief needs the concrete corrections below before a large implementation starts.
This is a bounded source review, not a rejection of host-coordinated transitions.
No production files were edited and no Godot invocation was performed.

Reviewed `REALM-TRANSITION-INTEGRATION-BRIEF.md`,
`REALM-DESPAWN-PROTOCOL-PROOF.md`, the native candidate, its retained successful
role logs, and the relevant Game, Session, realm-shell, trainer, deployed-creature,
encounter transport and overlay paths. The retained logs report host9,
departing12, staying8 with no ERROR/SCRIPT ERROR/WARNING match. Those29 checks
demonstrate the disclosed happy path; they do not establish production rollback,
host replacement, authentication negatives or every scene-bound traffic producer.

## Required corrections

### 1. Fence all body RPC producers, not just synchronizer output

`scripts/net/remote_trainer.gd::broadcast_presentation` sends `rpc()` directly
(line411). `request_landing_anchor` and `_rpc_request_landing_anchor` send the
request and reply directly on reliable channel0 (lines706 and722). A
MultiplayerSynchronizer recipient filter controls replication, not these ordinary
RPC calls. A post-gate fence orders earlier traffic but cannot prevent a later
presentation or landing reply from targeting a retired body path.

The brief correctly anticipates a possible precise hook here; source inspection
has now established that it is required. Include narrow outgoing recipient checks
for these paths, using the same coordinator scope as State Sync. Broadcasts need
an admitted-recipient loop or an equivalent proven send filter. Preserve outgoing
traffic for unaffected recipients. Define pending landing-request completion or
cancellation so suppression does not leave an unresolved request. Do not stop
the entire trainer physics callback to achieve this.

### 2. Close the full scene ledger traffic set

Deployment and recall are only two director RPC producers. The same scene-owned
`encounter_director.gd` sends intents/verdicts, encounter records, enemy hits,
capture results, encounter-open broadcasts and trainer rewards on channel1
(lines1607–1657,1837,1892,1919,3077,4081). `_can_encounter_rpc()` currently checks
only that multiplayer exists. Its host responses can also be emitted as a
consequence of a previously received request.

Inventory the concrete RPC producers in every subtree being retired; apply the
channel1 sender gates to all affected scene-bound producers and their responses,
not only deployment. `night_rest.gd` is another scene-owned channel1 producer
(sleep/night messages). Persistent Session/ledger traffic whose receiving node
survives must continue normally; avoid an indiscriminate global channel1 pause.
Specify whether a gated operation is rejected before commitment, retained until
the matching generation is admitted, or explicitly completed before the fence.
Committed rewards must not be dropped. A reliable fence is sufficient only after
the relevant producer set is closed. Add a native test with a body presentation
and a scene request/reply at quiescence, not just synchronizer deltas.

### 3. Host rebuilding needs state recovery for retained occupants

The host destroys both its old director and any occupied destination-shell
director. Their `_deployed_by` dictionaries and `_encounter_host` are owned by
those instances (`encounter_director.gd:181,197`). Existing reconciliation only
reconstructs the host's local deployment; remote deployments are populated by
client announcements. Clients whose scenes stay open do not repeat scene entry
or peer join simply because the host rebuilt its authority subtree.

Require a generation-ready refresh for **every retained affected owner**, not
only the moving player's destination deployment. Reconcile the announced current
deployment/card without changing the party, clearing an owned creature, or
inventing a reward. Cover this explicitly in the occupied-destination and
old-host-world tests.

Deployment replay alone does not reconstruct an in-progress hosted encounter.
`_encounter_host` and client `_encounter`/joinable records are transient; the four
world-save sync seams do not establish a live encounter handoff. The proposed
claim that affected occupants merely see proxies disappear and reappear is too
strong while their fight can lose its authoritative record.

The initial review suggested a bounded host refusal while affected fights were
active. The follow-up owner/spec review below retracts that as a shipping
recommendation: independent travel is already required. Full host replacement
needs actual transient state preservation; a smaller client-only repair must
leave the existing host defect explicitly open. Do not silently cancel another
player's fight or introduce a general scene-adoption framework for this repair.

### 4. Make host replacement permits and cancellation points explicit

The destination shell has the same root path as the host's incoming live scene.
It must remain pinned through drain, then be removed before the scene swap; it
cannot remain pinned until destination readiness without blocking or renaming
the incoming root. Likewise the vacated host scene must drain before removal,
and its replacement shell may build only after the destination build permits it.
Specify separate drain-complete teardown permission and post-readiness reservation
release. Assert the authored root paths after both swaps; do not rely on automatic
node-name collision renaming.

Retain the brief's session-epoch cancellation rule at **every awaited Game
boundary**, including queued reservation, overlay presentation, destination
readiness and rollback readiness. Current `enter_realm` can resume after several
awaits; the old `_await_realm_scene_ready` has no session-cancel predicate. A host
loss must resolve that call without a delayed rollback replacing the title.
Take or refresh the transition snapshot after a queued reservation is actually
granted and the source is revalidated, before changing save-facing state. The
gate issues fire-and-forget calls, so also enforce one live transition per mover.

## What is already the coherent minimum

- A persistent Session child is the right stable RPC target across scene swaps.
  Host-issued session/token/phase authentication and duplicate handling are
  necessary; the toy constant-token proof is not that implementation.
- Host-owned empty-property AdmissionSync plus owner-owned State Sync follows
  the proven authority behavior. For host-owned state, both host-authoritative
  visibility filters must deny the recipient because engine visibility is OR.
- Trainer-only cleanup is insufficient. CreatureSpawner is active in the shared
  director; its owner-authority wiring and missing realm filter confirm that
  the helper must cover both body kinds. Watch all actual authored spawners,
  including empty ItemSpawner, and fail closed on an unsupported active kind.
  Do not build speculative item replication.
- Per-sender reliable0 fencing, host-despawn fencing and actual spawner inventory
  drain are needed. Channel1 acknowledgments cannot substitute for channel0 or
  another sender. Continuous unreliable traffic is not ordered by these fences;
  retain native error inspection and the stated proof limit.
- Explicit receiver readiness and visibility refresh replace the unsafe
  unknown-registry-row-visible shortcut. Include late join and shell generation
  replacement, not only initial client departure.
- Save refusal before detach, compensating-save failure after detach, actual
  disconnect versus connected timeout, and solo no-op behavior are necessary
  parts of the same lifecycle. They should not be separate best-effort patches.

Keep the implementation to a coordinator, a small replication adapter and the
identified producer hooks. At four peers, explicit finite maps and an affected
realm set are enough; no generic distributed transaction framework, persistence
schema, transport replacement, arbitrary successful waits, or new queue service
is justified. Reserve overlapping source/destination subtrees atomically with
one mover token; nonoverlapping work can proceed without a generalized scheduler.

With these corrections made explicit, the design is suitable for a bounded
implementation and focused proof wave. Landing remains contingent on production
adapter multi-observer/client-and-host tests, the real default Water transition,
rollback/disconnect/late-join coverage and full exact-head CI. The29-check
candidate must remain labeled mechanism evidence.

## Follow-up: owner contract and smallest honest first phase

Read `docs/MULTIPLAYER_DIRECTIVE.md` (owner decisions, §5 rule16, §15 and minimum
experience item18), D97, the Stage B execution plan Wave6, and
`docs/specs/MP_ENCOUNTER_PROTOCOL.md` §9. The directive requires independent
transitions and simultaneous different-biome play. It permits an intermediate
same-realm development limitation, explicitly not a final pass. It does not
authorize imposing a host travel lock whenever another player fights. Encounter
§9 additionally requires a remaining participant's fight to survive another
participant leaving without reset. My earlier refusal suggestion was a possible
development containment, not an established owner-approved gameplay rule; it
must not be shipped as the completed host repair.

There is no presently demonstrated small active-encounter snapshot seam.
`scripts/net/encounter_host.gd` holds encounter records, `seq`, `_minted` and
`_strike_authority`; preserving only the public records would lose identity and
strike validation history. The director also holds `_catch_arbiter`, deployment
cards, live opponent/body links, and a manager whose RNG/action state participates
in resolution. A new director requires these references rebound to its actual
bodies, with correct pending catch/reward completion and surviving clients still
addressing the same encounter. Host scene replacement cannot honestly be called
fixed by copying `_encounter_host.encounters` or asking clients to deploy again.
An eventual in-memory authority handoff or preserving the live simulation root
could solve it, but neither is the minimal reviewable response to this single
receive-map CI failure.

**Recommended Phase1: client-only departure/admission repair, with explicit
compatibility outside that transaction.** Supersede the original brief's
all-crossings implementation scope for this phase:

1. Branch the awaited network transaction in `Game.enter_realm` only for a live
   non-host mover. Solo and the existing host replacement route retain their
   existing save/scene behavior. Session's persistent coordinator owns the token,
   source/target pin, sender fences, drain and destination-ready sequence for
   that client. Do not rebuild either host authority subtree merely to complete
   a client crossing. An empty source shell can follow its existing teardown
   only after the departing observer has drained.
2. Add the common trainer/deployed-creature admission adapter, but make its new
   deny/readiness overrides conditional on a concrete controlled client token.
   Outside those scopes it preserves existing behavior; do not simultaneously
   replace all unknown-peer/late-join/host-generation policies. In particular,
   a new host-owned AdmissionSync must not become a global default-deny gate
   whose readiness is never signaled by the unchanged host path. Ensure the
   host State Sync and AdmissionSync both honor a scoped denial. Admission and
   outgoing-state gates are separate; retained recipients keep receiving.
   Compatibility is not a blanket `true`: on host-owned trainers the new
   AdmissionSync must agree with the existing host State Sync's realm predicate
   outside transactions, or engine OR visibility would widen existing spawning.
   For peer-owned state, characterize and preserve the existing host-spawner
   fallback separately. Test both authorities before claiming neutral behavior.
3. Close the mover's old receiver and retiring owned proxies through actual
   spawner drain. Gate destination spawns to that mover until its authored
   receiver and the host's destination authority adapter are ready. Install the
   narrow trainer reliable0 and relevant scene reliable1 producer hooks already
   identified. Gate affected recipients only, and distinguish ephemeral
   presentation from committed encounter/reward results. Do not swallow results
   or clear any retained player's party/fight state to finish a transition.
4. Add only the host-entry interlock needed to protect an already-active client
   transaction's pinned source/target from concurrent legacy host destruction.
   An overlapping host request may await that finite transaction's completion
   or cancellation before its own mutation; it must not wait on another player's
   combat. This is protocol serialization, not a new travel eligibility rule.
   If safe completion cannot be established within the existing bound, fail the
   affected client transaction explicitly while its rollback receiver remains
   protected. Never silently fall back to unsafe client detach.
5. Keep initial/rejoin compatibility tests and the existing host-crossing tests.
   Add a three-peer client departure with another player fighting/moving in the
   unchanged source authority world, both actual spawner kinds, destination
   admission, cancellation, host-loss cancellation, and an overlapping host
   request. Require the real default Water route and exact-head CI. An existing
   host failure cannot be omitted or relabeled green; retain its complete error
   set and report it separately. A newly introduced host regression blocks this
   phase. If unchanged host defects prevent the required CI from passing, the
   phase remains unlanded until that obstacle is resolved or scope is explicitly
   changed; do not weaken CI to manufacture a client-only pass.

Phase1's claim is limited to safe connected-client scene replacement. It leaves
host old-world/occupied-destination rebuild ordering and active encounter
preservation open, and earns no full realm-transition, multiplayer-completion or
campaign credit. This is a smaller honest implementation than a generalized
state handoff plus new travel restrictions. Broader default-ready admission,
host generation replacement and transient encounter preservation belong to a
separately reviewed next phase based on its actual failures.

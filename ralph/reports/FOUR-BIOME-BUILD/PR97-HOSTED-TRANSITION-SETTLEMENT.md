# Hosted trainer transition settlement integration

Read-only audit against corrected protocol tree `5fae4e981` found an uncovered hosted transport path. Session's Stormwood request and event methods used persistent ledger-channel RPCs without the director's scene gate. Meanwhile `realm_transition_departing` removed authority-record membership only, leaving the separate hosted trainer roster populated, including between rounds. The hosted process eventually notices changed realm membership, but that happens after the required pre-response-fence withdrawal. Persistent Session routing does not itself imply a missing-node native error; the concrete defect is unclosed hosted intent production and roster state.

PR94 finalized-death withdrawal calls actual `fight.leave`, which removes both kinds of membership. When that request arrives before the fence it is compatible and helpful. It does not close the separate new-start/strike path, and it cannot substitute for transition roster retirement. The correction below does not depend on PR94's methods or fields.

## Bounded correction

- `scripts/net/session.gd`: gate outgoing Stormwood intents using existing coordinator policy. Only `disengage` and prospective `finalized_death_withdrawal` are completion intents allowed during request closure. Inbound host dispatch uses receiver/completion semantics: previously queued requests remain executable during `requests_closed`, because host installation alone does not prove the sender's fence was consumed. Closed/draining/retired receivers cannot start later activity. Outgoing hosted results use that same receiver gate, permitting synchronous final roster replies before response closure.
- `scripts/combat/encounter_director.gd`: before generic record cleanup, invoke the actual sibling hub's roster withdrawal. This runs inside the existing callback between request and response fence rounds.
- `scripts/world/stormwood_encounter_hub.gd`: **only the appended eight-line `withdraw_peer_for_realm_transition` method belongs to this change**. It iterates actual live fights and calls `fight.leave` only for existing members. The shared file also contains held PR94 code; do not copy its entire current contents into protocol PR97. Apply this independent appended delta to the main-based hub.
- `tests/test_stormwood_realm_transition.gd`: five focused tests using actual hub, hosted fight, authority, director callback and Session request/result methods. A recording publisher replaces delivery only; active and done-between-round authority records retain a staying participant. Coordinator policy is real; role identities are deterministic local test seams, not native network proof.

No coordinator drain logic, fence ordering, native assertion count, ordinary initial policy, or visual source changed. Session/director full files remain protocol-owned; root owns shipping-tree isolation.

## Evidence

Artifacts: `.artifacts/stormwood-transition-focused-v1/`.

First negative control (`negative.log`) ran the three initial tests against unchanged production and failed all three: active and between-round hosted rosters retained the mover with no final roster response, and new hosted intents kept dispatching after closure. This is retained as the expected defect reproduction, not a pass.

After the minimal correction, the original three passed (`corrected.log`). Expanded phase and real local response coverage then passed **five tests / 26 assertions** (`final.log`): outgoing start/strike closure, allowed pre-fence completion names, closed completion refusal, staying sender baseline, host pre-fence inbound permission, recipient closure/drain/history/reset, actual final result emission, both roster phases and idempotent withdrawal.

Existing hosted combat suite: **5 tests, 0 failed** (`hosted-existing.log`). Existing coordinator suite: **16 tests, 0 failed** (`transition-existing.log`). All five logs contain no ERROR, SCRIPT ERROR or WARNING. Each engine invocation was terminal; Godot count returned zero and the exclusive tiny lease is released. No full-world or native multiplayer run was added. Existing PR97 CI runs remain historical exact-head evidence; the corrected shipping tree still requires its own CI.

Limits: the new tests establish the production seams and synchronous callback ordering, not a new real-transport hosted travel proof. The previous 81/77/82 native proofs did not exercise the Stormwood hosted route. Held PR94's finalized-death lifecycle remains separately scoped; only its completion intent name is recognized here.

## Follow-up wiring check and equivalent routes

Root requested actual inbound wiring coverage in addition to policy predicates. Added a Session subclass that preserves inherited dispatch, supplies Stormwood membership and records/refuses the gate; dispatch must call it before looking up a world hub. `inbound-final.log`: **6 tests / 27 assertions, zero failures**, raw clear. Earlier results remain retained; broad suites were not repeated.

Targeted equivalent-route source audit found **the same unclosed persistent transport in WaterAlphaTransport**, inherited by WaterVeilfallTransport. Alpha submits directly to it and keeps an independent authority; only the primary director owns the registered creature-spawner scope, so its existing departure callback does not retire Alpha participants or capture state. Alpha's later absent-player pruning is not pre-fence settlement. A bounded base-transport gate plus primary-to-Alpha settlement/withdrawal hooks is proposed to root; it is not yet implemented at this checkpoint. Veilfall control commits are synchronous and have no separate combat roster. Cloudreach uses the ordinary director submit/battle path and does not expose an equivalent independent hosted Session route in the targeted search. No full-world acceptance is inferred.

## Approved Water extension — prepared checkpoint

After that audit checkpoint root authorized the same bounded correction in `scripts/net/water_alpha_transport.gd`, `scripts/combat/water_alpha.gd` and the already owned primary director, plus `tests/test_water_realm_transition.gd`. Source is prepared; focused engine validation is pending the visual lane's lease release at this checkpoint.

Water's base transport now applies outgoing policy before submit, a receiver-policy wrapper before virtual host service commit, and receiver policy before reply/snapshot delivery. Veilfall inherits the wrapper without changing its service. Only `catch_finished` and `disengage` are completion requests. Rejected requests preserve their kind and return `pending=false`; existing Alpha request callers immediately route these refusals through their normal pending-state cleanup.

The primary scope producer forwards its mover-only results check to sibling Alpha's local engage/attunement/catch-finish pending flags, then retains the existing manager catch/RESOLVING check. ACTIVE combat alone is not a wait condition. The host departure callback invokes Alpha's existing `_leave_alpha` followed by its final snapshot; this releases catch ownership while retaining reward eligibility and durable resolution. Neither coordinator registration nor fence phases change.

Prepared tests cover denied outgoing request classification, actual virtual commit wrapper, denied response wiring, inherited Veilfall routes, real primary-to-Alpha authority removal, staying participant, catch ownership release, retained resolution/eligibility and local pending versus ACTIVE/RESOLVING manager behavior. They are ordinary headless component tests, not a claim of real-transport Water travel.

## Final combined focused validation

After explicit lease grant, the first Water attempt passed **4 tests / 36 assertions** (`water-first.log`). Relevant existing suites each ran once: Alpha state **9 tests / zero failures** (`water-state.log`), Alpha rewards **6 / zero failures** (`water-rewards.log`). Because the shared primary callback changed, the final combined Stormwood suite ran once again: **6 tests / 27 assertions, zero failures** (`combined-stormwood.log`). All four logs are clear of ERROR, SCRIPT ERROR and WARNING. Every process is terminal, Godot count zero, and root was notified immediately of lease release. No native/world test was added. Corrected exact-head CI remains required.

Final integration manifest (eight paths):

1. `scripts/net/session.gd`
2. `scripts/combat/encounter_director.gd`
3. `scripts/world/stormwood_encounter_hub.gd` — appended withdrawal method only; preserve main-based contents, exclude held PR94 delta.
4. `scripts/net/water_alpha_transport.gd`
5. `scripts/combat/water_alpha.gd`
6. `tests/test_stormwood_realm_transition.gd`
7. `tests/test_water_realm_transition.gd`
8. This report, `ralph/reports/FOUR-BIOME-BUILD/PR97-HOSTED-TRANSITION-SETTLEMENT.md`.

No source outside these paths belongs to the hosted-settlement correction. Previous fixture teardown and its report are an earlier independently reviewed delta.

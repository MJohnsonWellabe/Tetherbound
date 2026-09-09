# Begin-client failure audit and next bounded validation

2026-09-09. Static source audit after the first default Water production pass. No additional native run, source behavior change or retry. This is a remaining shipping blocker, not a reinterpretation of that successful route.

## Current behavior and evidence

`scripts/net/realm_transition.gd:131` refuses inactive/host/occupied-local state or unsupported inventory before sending a request. These pre-request refusals do not install gates or drain bodies. Host invalid-realm/inventory refusals at lines 190–218 likewise precede a grant. When their refusal reaches the awaiting caller, phase becomes cancelled, and Game's wrapper clears it. Those are traffic-free refusals with the source scene intact.

By contrast, `begin_client` lines 141–148 sends `_cancel_request` and returns false immediately on its local deadline or error. It does not await the host cancellation outcome. `autoload/game_state.gd:1561` then returns before creating the overlay or taking the existing rollback path. The wrapper at line 1479 invokes `clear_local`, which only clears done/cancelled/waiting (coordinator line 185).

Two concrete source-level races follow:

1. A granted request times out locally while its phase remains requests_closed, closed or draining. The wrapper does not clear that phase. A later host abort changes it to cancelled, but there is no remaining wrapper to clear it. The next begin refuses the nonempty local dictionary. Before loading, host abort removes the transaction and refreshes native visibility, so source admission can resume; there is no explicit acknowledgement that all source bodies have returned before the caller resumes. This is not equivalent to a traffic-free refusal.
2. The mover has sent actual inventory-empty `_drained`; host processes it at line 397, retires the source receiver, changes membership to the target and broadcasts loading. Before that broadcast is locally applied, the mover can hit its original deadline and return false. Its cancellation then reaches a loading transaction. `_fail_transaction` at line 658 deliberately retains its token, deny and realm pins and sends only `_transition_failed`; it expects Game to rebuild a rollback receiver. Game has already returned before its overlay/rollback branch. The local source scene remains, but its replicated bodies can be empty and denied with no recovery action presented. A delayed loading install cannot restart the completed Game awaiter.

These are feasible event orderings inferred directly from code, not newly reproduced runtime failures. The normal 81-check native component, 73-check Game fixture and 28-check production route do not inject this race. Session reset clears the local dictionary and invalidates old awaiters; that protects a new session but does not recover a still-connected stranded player.

## Proposed bounded correction for review

Keep failure classification in the existing coordinator/Game boundary. A granted begin must not report an ordinary refusal until its host cancellation outcome is acknowledged. Preserve the token when host reports loading; return an explicit recovery-required outcome to Game rather than losing it behind false. Game should retain/revalidate the original source scene and use the existing guarded source rollback/readiness/admission path before releasing ownership. If cancellation settlement or recovery itself expires, present the existing bounded exit-without-save recovery action; do not silently reopen admission or delete an un-drained receiver. A truly pre-grant refusal retains its cheap return path. Every awaited outcome must use the captured epoch/request/token so a late reply cannot alter a newer crossing.

Exact bounded ownership: existing `realm_transition.gd`, Game entry boundary in `autoload/game_state.gd`, coordinator unit tests and the tiny actual Game fixture. No global scheduler, new world architecture, host travel rewrite or visual changes. Review is required before editing this newly identified path.

Focused cases before a new world lease: pre-grant refusal permits a subsequent request; abort acknowledgement after local timeout clears only the matching request; loading wins cancellation and requires source readiness before admission; cancellation acknowledgement timeout leaves usable recovery; late response after reset cannot poison a new session. Native connected cancellation with actual source inventory is necessary to compose the coordinator and Game proof; a stub-only success is insufficient.

## Remaining acceptance versus scope

Priority 1 is the failure above. Next bounded native compatibility scenario should establish a fresh peer joining after a completed controlled departure: real scoped policy applied ACK before its body/state producers, absent old-realm path remains absent, existing peers continue moving, and ordinary initial join/reconnect remains functional. The default Water pass covers ordinary initial join, not this scoped latejoin branch. One corrected-source candidate with raw logs and first-error stop; no broad replay campaign.

Native rollback/return readiness and disconnect during installation/fence quorum remain unproven together with Game. Three-peer production retained-fight continuity and exact-head full CI also remain open. Legacy host/solo control flow has focused Game coverage, but the pre-existing host occupied-world rebuild defect remains explicitly outside this client-only repair. None of these receipts establishes whole-biome completion, performance acceptance, or campaign progression.

# Independent review: commit 90bebc8d (owner-passive discovery identity)

Reviewer: independent agent, code-read only (Godot not run). Scope: `git show 90bebc8d` only.

**Verdict: BLOCK**

The identity idea is right, and most paths are now consistent. The new Cloudreach portal-arrival merge in `owner_settled` brings back the map-versus-replay divergence on an ordinary path: going back into Cloudreach by portal after any earlier Cloudreach visit. On that path the rebase is still silently dropped, which is the failure this commit set out to fix.

## Consistency audit (question 1)

| Site | Owner seed | Host seed | Consistent? |
|---|---|---|---|
| hello `arm_owner` (session.gd:2471-2472) | map (`admission_landmarks`) | first admission: same summary (`seed_discovered_landmarks`). Rejoin: held set, and a mismatch triggers a readmit | yes (the readmit adopts held) |
| `record_input` (owner_passive_sync.gd:102-106) | identity plus `new_landmarks`, deduplicated, in packet order | replay `_discovery` appends `claimed` in packet order and creates the realm key even when empty (owner_passive_replay.gd:171-194) | yes. The fingerprint sorts dictionary keys and keeps array order |
| `_queue_rebase` (1266-1270) | `_discoveries()` read after `arm_owner`, so it is the new identity | `previous.cursor.discovered` (1291) | yes, except for the arrival branch (finding 1) |
| `_readmit_owner` (1163-1184) | adopts `held` into identity, then `REPLAY.begin(baseline, held)` | `hosts[c].readmit.discovered` equals the cursor seed | yes |
| research no-progress / no-effect rebase (1111) | identity at freeze. `record_input` is gated by `pending`, so identity equals the inputs up to `final_sequence` | `previous.cursor.discovered` | yes |
| `owner_plan` save check (1136, owner_passive_preparation.gd:244) | identity | `prepared.discoveries = cursor.discovered` | yes. This is now correct where the parent compared against the map |
| `portal_recovered` rebase (1021) | identity, seeded at hello from the map plus the recovery inputs | recovery `stream.cursor.discovered`, seeded from the summary map | yes |
| `_recovery_admitted` candidate (288-297) | summary map | host-replayed `prepared.discoveries` | **no** (finding 2, already present before this commit) |
| groom passive `discoveries` (groom_passive_sync.gd:361-371, 527-531) | installed on the map with no input, so never in identity | goes into authority held (character_authority.gd:126-130), never into the live cursor | yes while a host stream exists. See finding 4 |

## Findings

1. **HIGH: `owner_settled` merges the whole Cloudreach map on every Cloudreach `portal_arrival`, but the host substitutes `arrival_discoveries` only for a proven first entry.**
   - **Where:** scripts/net/owner_passive_sync.gd:1254-1260 (owner) against 1291-1299 and 687-711 (host).
   - **What the host does:** it sets `checkpoint.arrival_discoveries` only when `_cloud_initial_navigation_bound` holds: cursor `cloudreach` is empty, no `last_waystones.cloudreach`, the entry is `meadows_entry`, and the arrival region matches. Otherwise it rebases on `previous.cursor.discovered`.
   - **What the owner does:** it replaces `discoveries.cloudreach` with the live map set whenever `row.intent.realm == "cloudreach"`.
   - **Why the map is already ahead:** `cloudreach_atmosphere._process` calls `sync_progression() → sync_navigation()` every frame (cloudreach_atmosphere.gd:157-158). Walking into any of the 6 `region_entered` regions, or setting any of the 3 `unlock_events` flags (cloudreach_chapter.json `map_navigation`), reveals landmarks with no input. So after any earlier Cloudreach play, the owner's Cloudreach map is almost always a strict superset of its identity.
   - **Failure scenario:** a guest plays Cloudreach and enters `broken_causeways`, which reveals `three_bells_bridge` with no input. They portal home to Meadows, then portal back to Cloudreach.
     - The host's first-entry predicate is false (cursor `cloudreach` is non-empty), so the host keeps `previous.cursor.discovered`.
     - The owner merges a map set that includes `three_bells_bridge`.
     - `discoveries_hash` differs, so `_rebase_host` returns silently. The owner resends the rebase forever (`_flush` 1205-1214), never flushes inputs, and fills to `owner_passive_buffer_full`. Every later held reward and checkpoint stalls.
   - **The same divergence also occurs:**
     - (a) on a first entry the host cannot prove: a different entry, a seated Cloudreach waystone, or a region mismatch;
     - (b) on a proven first entry, when the owner walks into a second region (the atmosphere is not blocked by `_owner_training_mutation_blocked`) or a flag changes between grounding and settlement, because the owner reads its map at settlement while the host computed at `initial_position` at grounding;
     - (c) whenever owner and host flag views differ.
   - **Safest rule:** the owner must never derive the arrival set from its own map. Make it host-authoritative, the same way readmit works:
     - Put the proven `arrival_discoveries` (or an explicit `null` meaning "no reveal proven") into the `portal_arrival` result or `portal_travel`/grounded reply the owner already validates, bound by the checkpoint hash.
     - At settlement, the owner adopts exactly that set into `local.discovered`, and only when it is present. With no proof, it merges nothing.
     - Minimum stopgap: merge only when identity `cloudreach` is empty **and** the owner reproduces `_cloud_initial_navigation_bound` with the same static helper. Even then (b) and (c) remain, so prefer the host-supplied set.
   - **Tests:** this branch has no test. Add one where the owner's Cloudreach map already holds a navigation-revealed landmark on a non-first arrival, and assert that the rebase hash equals the host's.

2. **MEDIUM (already present before this commit; the commit's claim does not cover it): a portal-recovery reconnect still seeds from the map.**
   - **Where:** session.gd:2471-2472 sends `admission_landmarks()` (the map). `_recovery_admitted` (owner_passive_sync.gd:288-297) requires `PREP.exact(discoveries, known.prepared.discoveries)`, and both candidates are host-replayed sets.
   - **Why readmit does not help:** recovery has no adopt step equivalent to readmit.
   - **Failure scenario:** after any no-input landmark (the Meadowhart herd, a dialogue `map_reveal`, a Cloudreach navigation reveal, a groom install), a guest disconnects mid-portal and reconnects. No candidate matches, recovery never starts, and the departed checkpoint stays held.
   - **Suggested fix:** let the host carry its candidate's discoveries in `portal_recover`. The owner adopts them into identity (as in readmit), and the host matches candidates on the baseline only.

3. **LOW: trade-offs of keeping the map on a G1 readmit.**
   - (a) Lost bond credit. An unreplayed landmark X stays on the owner's map while the readmit overwrites `landmarks_visited_together` with the host's value. Its bond credit is lost for good, because walking past X no longer produces an input. Before, a87c09b0 removed X from the map, so the player could earn it again.
   - (b) Duplicate-landmark refusal. If held ever contains a landmark Y that the owner's map lacks, walking to Y sends `new_landmarks:[Y]`. `record_input` deduplicates it locally, but replay refuses `known.has(Y)` as `invalid_landmark` (owner_passive_replay.gd:175-176), so the host stream errors. This needs an owner save older than the host's committed record, so it is unlikely: held stays a subset of the owner's saved map in the normal flow.
   - **Suggested fix for (b):** in game_state.gd:1196-1198, filter `new_landmarks` against `local.discovered` (via a session accessor), so a landmark already in identity is never resent.

4. **LOW: the no-stream rebase fallback.** owner_passive_sync.gd:1284 seeds the host from `authority.discovered_landmarks`, which includes groom-committed discoveries (character_authority.gd:126-130). Those never enter the owner identity. If `hosts[character]` is absent when a rebase arrives, the hashes differ and the rebase is silently dropped. Before this commit, the owner's map contained the groom installs, so it matched in this particular case and failed in others. This path is rare and needs a host stream dropped while the owner stays connected. Note it for the same host-supplied-set follow-up.

5. **INFO, question 3 (discovery producer, game_state.gd:1154-1201):**
   - The `discovered_before` to `_discovered` diff window contains only `mark_visited` and `update_region`, run synchronously in `Game._process`.
   - Cloudreach `update_region` reveals no landmarks, and `sync_navigation` runs from the atmosphere's own `_process` or from `bind_realm_map`, never inside this window. So `new_landmarks` cannot contain a navigation-revealed landmark.
   - Base `_discover_landmarks_near` skips `manual_discovery` (map_state.gd:1067). Cloudreach's override filters by `_allowed`, and the host's geometry context accepts every authored landmark, so the owner's set is a subset of what the host accepts.
   - A landmark that is walked first and story-revealed later, or the reverse, ends up the same on both sides: the second event is a no-op on the map and produces no input.
   - Conclusion: identity and host agree on the per-tick path.

6. **INFO, question 4 (G1 rejoin):**
   - tests/smoke_net_gather_departure.gd makes no landmark assertions. Its rejoin readmit path now adopts into identity, and the prefix check still holds (`REPLAY.begin(baseline, held)`).
   - Removing `adopt_landmarks`, `set_discovered_landmarks` and their real-map test is coherent: nothing else references them (grep is clean outside `ralph/reports`).
   - I see no regression to the G1 smoke beyond 3a.

7. **INFO, question 5 (do the tests fail on the parent?):**
   - `test_a_landmark_revealed_without_an_input_never_changes_the_owner_passive_identity`: on the parent, `_discoveries()` returned the map, so the first assertion fails (`{walked, story}` is not `start`). So does the second.
   - `test_rejoin_with_unreplayed_landmarks…`: on the parent, the map was adopted, so `session.maps.value == held`, which is not `owner_seen`. The new map-kept assertion fails; the identity assertion would also have passed on the parent.
   - Both pass under the new code as far as I can trace.
   - Neither test covers the `owner_settled` Cloudreach merge (finding 1).

## Required before approval
- Fix finding 1 with a host-supplied arrival set, or at minimum the gated stopgap, and add a test for a non-first Cloudreach arrival whose map holds a navigation-revealed landmark.
- Findings 2-4 can be follow-ups if they are recorded in STATE.

## Re-review bfef391d

**Verdict: APPROVE-WITH-NITS**

This commit fixes finding 1 by having the owner adopt the host's proven arrival set instead of its own map. Its finding 3b fix (filtering known landmarks out of discovery inputs) replaces an immediate host refusal with a rarer, later conflict; see R3. I reviewed by reading the code; Godot was not run.

**(a) Do the `journaled` and `_rebase_host` conditions agree?** Yes, for every live path.
- **Host send (owner_passive_sync.gd `_completion`).** The proof goes in the packet when the checkpoint has `source_kind == "portal_arrival"`, `grounded`, a `Dictionary` `arrival_discoveries` and `result.durable`.
- **Host rebase (`_rebase_host`, ~1302-1310).** It additionally checks:
  - that the packet has no `checkpoint_id` (a settlement rebase never has one);
  - `result.receipt == row.receipt`;
  - `row.action == "portal_arrival"`;
  - that the row intent matches the checkpoint permit exactly.
- **Owner adopt (`owner_settled`).** It requires `row.action == "portal_arrival"` and `proof.receipt == row.receipt`, where `proof.receipt` is the `result.receipt` the host sent.
- **Why the owner's missing intent check is harmless.** The row is the host's own journal entry for this checkpoint's request, so binding on the receipt is equivalent.
- **The checkpoint cannot change before the rebase.** `stream.checkpoint` is only created when it is empty (`_checkpoint` and `action_gate` at 604/645) and only replaced by `_add_host`. `grounded` is never cleared. So the checkpoint seen at `_completion` is the one `_rebase_host` reads.
- **Every send goes through `_completion`.** Sends and resends all use it, both from `_saved_host` with a result and from `portal_grounded` → `_commit_saved`. A resend just overwrites the same proof.
- **No cursor drift between grounding and settlement.** `arrival_discoveries` is computed from the cursor at grounding, which is frozen at `final_sequence`. The owner records no input while `pending` is set, so both sides seed from the same base.

**(b) Can `owner_settled` run before `journaled` arrives?** Not in a live session.
- The host sends `journaled` synchronously inside the commit (`_commit_saved` → `_completion`).
- The owner settles on one of two triggers: `_rpc_training_decision`, or `_process_creature_training` seeing the accepted row from `publish_journaled_delta`.
- Both are sent only after `_accept_creature_training` handles the owner's own ACK of the pending row, which is a full round trip later.
- `journaled` (`_rpc_owner_passive_reply`), the decision RPC and the accepted delta all go out on `CHANNEL_LEDGER`, reliable. Reliable traffic on one channel arrives in order, so `journaled` always arrives first.
- **Residual LOW.** On a disconnect between `journaled` and settlement, the rejoined owner re-arms at hello: `local`, and the proof with it, are lost, while the host's departed stream still holds `arrival_discoveries`. That falls in the portal-recovery path already recorded as finding 2, not a new gap.
- **Suggested hardening.** If ordering ever stops being guaranteed (for example a future transport that maps channels differently), the host's `_rebase_host` could also accept a hash equal to `previous.cursor.discovered` in the arrival branch. The owner, finding no proof, would then rebase on its identity and both sides would converge on the unproven set.

**(c) Tests.**
- **`test_cloud_reentry_without_a_host_proof_keeps_the_identity_whatever_the_map_reveals`.**
  - On 90bebc8d it fails: the map merge sets `cloudreach` to `[realm_gate_crag, three_bells_bridge]`, so the rebase hash differs from the identity.
  - It passes now, because no proof means the identity is unchanged.
  - This is a correct regression test for finding 1.
- **Updated `test_cloud_portal_navigation_bind_…`.** It now asserts that the host's `journaled` packet carries `arrival_discoveries == discoveries` and delivers that packet to the owner. That covers the host-send half.
  - **NIT:** the test still sets `session.maps.value = discoveries` before `owner_settled`. That is the same set as the proof, so it would also pass if the owner read its map.
  - **Fix:** give the map an extra landmark (for example add `three_bells_bridge`) so that only adopting the proof yields the hash the host accepts.

**New nits.**
- **R1 (NIT): `local.arrival_proof` is stored without a scope check.** The owner stores it on any `journaled` packet whose `result.receipt` is a String, without checking `pending.id == packet.id`. It is only used for the exact receipt and is cleared at the next `arm_owner`, so this is harmless. Gating it on `pending.id` would be tidier.
- **R2 (NIT): the adopted proof is not shape-checked.** A malformed `discovered` makes `REPLAY.begin` return `{}`, and `owner_settled` then returns silently. The source is the trusted host, so this is acceptable.
- **R3 (LOW): the finding 3b filter can still cause a later conflict.** Game (game_state.gd:1177-1180) credits `landmarks_visited_together` locally when the map gains a landmark. That happens before `record_input` filters the landmark out because the identity already has it. The host then replays an empty `claimed` and gives no credit, so the next checkpoint ends `owner_passive_exact_projection_conflict` rather than the old immediate `invalid_landmark`.
  - **Precondition:** the identity holds a landmark the owner's map lacks. That happens after a readmit adopts a held set the map does not have, or after an arrival proof from host flags the owner had not yet seen. Both are rare.
  - **Fix:** have Game skip the landmark-visit credit when every gained landmark is already in the owner-passive identity, for example via a session accessor.

Findings 2 and 4 remain open as recorded follow-ups.

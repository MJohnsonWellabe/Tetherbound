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

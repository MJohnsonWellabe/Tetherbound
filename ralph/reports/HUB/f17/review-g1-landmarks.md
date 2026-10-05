# Independent review: commit 53556884 (G1 rejoin readmits on the host's held landmarks)

Reviewer: independent code-review agent (read-only; no source edited). Scope: `git show 53556884` only.
Files: `scripts/net/owner_passive_sync.gd`, `scripts/net/groom_passive_sync.gd`, `tests/test_owner_passive_sync.gd`.
Tests were not re-run for this review. The commit reports test_owner_passive_sync at 30/527 and test_guest_groom_passive_sync at 6/72.

## Verdict: APPROVE-WITH-NITS

The fix is correct for the failure it targets. Host admission now admits directly only when the declared landmarks hash the same as the held landmarks. That is exactly the condition under which both `REPLAY.begin` prefix seeds agree, because `prefix_hash = fingerprint({base, discovered})` and both checks use the same order-sensitive fingerprint. If the landmarks differ while the baseline core matches, the host takes the existing readmit path, and the owner adopts the held set before it reseeds. The commit adds no new refusal and no new deterministic readmit loop in production. The findings below are follow-ups and nits, not blockers.

## Answers to the review questions

1. **Host condition.** The condition is correct.
   - `summary.discovered_landmarks` has already been validated with `admission_valid(..., complete=true)` at `session.gd:2801`, so it has all four realm keys and no duplicates.
   - The held set is seeded from that same shape (`seed_discovered_landmarks`). It only grows through `commit_groom_preparation`, which appends without duplicates. Seeding happens at `session.gd:2819`, before `owner_passive.admitted` at `:2829`.
   - When the baseline is equal but the landmarks differ, `core_matches` is true: the declared fingerprint equals `baseline_hash` and the core is equal. The readmit is therefore reached. This is the case the new test covers.
   - A baseline that differs outside the core is still refused, the same as before, whatever the landmarks are.
   - The `stream.has("readmit")` resend at `owner_passive_sync.gd:330-336` behaves as before. It loops only while the owner keeps ignoring the readmit, and every ignore condition already existed except the adopt-failure branch. That branch is unreachable in production, because the host validated the same ids against the same authored definitions.
   - The readmit packet carries `discovered`. Before this fix, a passive-drift readmit with differing landmarks was ignored forever with "readmit whose core no longer matches". It now converges, which is a side improvement.

2. **Owner `_readmit_owner`.** The adopt is gated: the packet's own hash must match `discoveries_hash`, owner-passive `pending` must be empty, and `REPLAY._core` must match. `adopt_landmarks` validates realms and ids against the owner's own `_landmark_defs` through `admission_valid`.
   - A forged host packet can only come from the authenticated host, which is already the authority. The new capability is that the host can replace the guest's per-realm landmark sets with any valid subset, and the guest then saves that in its file. This follows the owner ruling ("the host world's held record wins inside that world"). See Finding 3 for the persistence consequence.
   - Realms missing from the packet are emptied. In production this is harmless, because a held set always has all four keys.
   - Load/save round trip, checked for each map class:
     - `autoload/map_state.gd` (meadows, water) restores fog (with a geometry check), landmarks (insertion order equals the adopted array order, so the hash reproduces), regions, dynamic markers and alpha pins.
     - `realm_map_state.gd` (stormwood) keeps `realm_id` because `save_data` writes it.
     - `cloudreach_map_state.gd` restores fog, landmarks, regions and pins, but drops the dynamic markers' `display_name` (Finding 5).

3. **Other landmark users.**
   - Double pay: a discovery input grants `landmarks_visited_together +1` and walking distance (`owner_passive_replay.gd:146-200`). Both are `PASSIVE_FIELDS`. The readmit overwrites the owner's passive values with the host baseline, so the credit for a landmark the host never replayed is rolled back. Re-discovering it by walking pays once against the host record. There is no double pay through replay.
   - Groom: the host groom `admitted(character, held)` already used the held set as `committed`, which stays consistent.
   - Rebase: after the readmit, the host's `cursor.discovered` equals the owner's `_discoveries()`, so `_queue_rebase` and `_rebase_host` discoveries_hash checks agree. There is one exception (Finding 1).

4. **Ordering.** Dropping inputs recorded before the readmit is still correct. A dropped discovery input's landmark is removed by the adopt and its passive credit is rolled back by the baseline. Re-walking produces a fresh input on the new cursor, and `_discovery_elapsed` and `_travel_pos_valid` reset as before.

5. **Tests.** The new test would fail on the old code: the baseline is equal, so the old code admits directly and the `readmits.size() == 1` assertion fails. The prefix-equality assertion is the right end-to-end proof. The direct-admit test guards against regressing the exact rejoin. The test has gaps (Finding 4).

## Findings

1. **Medium (follow-up, not a regression).** Discoveries outside replay are not carried by the protocol, so adopting can churn them.
   - Where: `groom_passive_sync.gd:175-184`, `cloudreach_map_state.gd:199-216`, `meadowhart_herd_visit.gd:118-130`.
   - Problem: the host's held set only grows through replay or groom observations. Replay refuses `manual_discovery` landmarks, and flag-driven reveals never produce a discovery input. A guest that, during a session in world W, does the Meadowhart herd visit (`meadowhart_grazing_ground`, manual) or gets a Cloudreach flag reveal (`sync_navigation`) has a landmark the host never holds.
   - Failure scenario:
     - On rejoin, the adopt wipes that landmark.
     - (a) For Meadowhart, `visit_pending` becomes true again. The visit can be redone, the "discovered, bond progress" toast repeats, and `BOND.credit_landmark_visit` runs locally outside replay. The item reward stays guarded by `COMPLETE_FLAG`.
     - (b) For Cloudreach, `sync_navigation` re-adds the landmark on the next frame without an input. The owner's `_discoveries()` then differs from the host's `cursor.discovered` again. The next `_queue_rebase` is silently dropped by `_rebase_host`'s `discoveries_hash` check, and the next rejoin readmits again.
   - Context: the same divergence already happens for in-session manual or flag reveals without a rejoin, so this is pre-existing. The commit converts the rejoin stall into this narrower case; it does not cause it.
   - Recommendation: track it as the next G1 item. Either let the host accept manual or flag landmarks through an authorized path, or exclude them from the prefix and admission set.

2. **Low.** The adopt is not atomic with the rest of the readmit.
   - Where: `owner_passive_sync.gd:1110-1135`.
   - Problem: `adopt_landmarks` mutates the owner's maps before the party-member lookup (`if member == null: return`) and before the `owner_passive_readmit_mismatch` check.
   - Failure scenario: if either check fails, the owner has lost its landmarks but has not readmitted (silent return, or a stream error). The core equivalence makes this unlikely.
   - Fix: snapshot the maps first, or move the adopt after the member resolution and passive check, just before `REPLAY.begin`.

3. **Low (design note within the ruling).** The host's landmark set becomes durable in the guest's file.
   - Where: `groom_passive_sync.gd:175`.
   - Problem: the adopted set is written to the guest's portable file at the next save. A guest that discovered landmarks in its own or another world loses them from its file when it rejoins a world whose held record predates them.
   - Impact: walkable landmarks can be re-earned, and fog, regions and pins are untouched. This matches how passive fields already roll back on readmit, and the owner ruling covers it inside W. Whether the guest file should be overwritten for use outside W is not stated in the ruling. Record it in STATE if that matters.

4. **Low (test quality).** The tests use a mock and never touch the real adopt or the real map shape.
   - Where: `tests/test_owner_passive_sync.gd:51-56, 1189-1240`.
   - Problem: the `Discoveries` mock's `adopt_landmarks` copies the dictionary, and the fixture holds `{}` rather than the production shape of four realm keys.
   - Untested: the real `groom_passive_sync.adopt_landmarks`, the `load_data` round trip, the emptying of missing realms, and the shape rule that the adopted maps must hash back to `discoveries_hash`. If held and admission shapes ever diverge (for example a three-key held set), the owner would ignore the readmit and the host would resend it forever. No test would catch that.
   - Recommendation: add one test in test_guest_groom_passive_sync with real maps that asserts `admission_landmarks()` equals `adopted` after `adopt_landmarks` and that fog, regions and pins are preserved.

5. **Nit.** The runtime `load_data` round trip has two small side effects.
   - Where: `cloudreach_map_state.gd:254-257`, `map_state.gd:885-886`.
   - Problem: the Cloudreach `load_data` drops dynamic markers' `display_name`. This is a pre-existing lossy round trip, now hit at runtime. The base `load_data` clears `_current_region_id` and `_pending_region_announcement`, so the current region's announcement may repeat after a readmit.
   - Fix: adding a dedicated `set_discovered_landmarks(ids)` on MapState and its subclasses would avoid both and would not touch fog.

6. **Nit (version skew).** A new host paired with an old guest loops.
   - Where: `owner_passive_sync.gd:177-200`.
   - Problem: an old guest does not understand the readmit and ignores it, so the host resends on every packet indefinitely. Before the fix, the same pair failed at the first checkpoint instead.
   - Impact: acceptable for rolling development builds; noted only for package-identity checks.

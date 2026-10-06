# G1 — guest departs right after its gather rows are pruned, rejoins, crafts

Smoke: `tests/smoke_net_gather_departure.gd` (peers: 2, real ENet, auto-discovered).

## Reproduced (before the fix)
G1's own criteria passed: no `unproved_delivery_input` and no admission conflict, and the host's authority matched the rejoined guest. But the post-rejoin craft at the host's Kitchen stalled at `owner_passive_checkpoint_pending`.

The failure was intermittent: 3 of 7 runs failed.

| Run | Commit | Result |
|---|---|---|
| r2 37300850914 | e4657956 | fail |
| r3 37303234729 | faeccb73 | fail |
| r4 | 4acd2188 | pass |
| r5 | 4acd2188 | pass |
| r6 37305857025 | 4acd2188 | fail |
| r7 | 4acd2188 | pass |

The control with no gathering (`smoke_net_rejoin_craft_control.gd`, 37299622795) passed.

## Diagnosis
- **Probe:** the host ended the stream with `owner_passive_exact_projection_conflict`.
- **r3:** both projected states were identical at the same sequence, but `prefix_match` was false.
- **r6 trail:** every input digest from 36 to 99 was identical on both sides, while the prefixes differed from the first input. So the chain seeds differed: `REPLAY.begin(baseline, landmarks)`.
- **Cause:**
  - A rejoin keeps the host's held landmarks (`seed_discovered_landmarks`: the world's record wins).
  - Direct admission compared only the baseline.
  - Gathering walks the guest between nodes. A landmark it discovered there that the host never replayed before the leave made the two seeds differ.

## Fix
- 53556884, plus review nits in a87c09b0.
- Admission now also requires the declared landmarks to equal the host's held set. Otherwise it readmits and carries that set.
- The owner adopts it with `groom_passive_sync.adopt_landmarks`, which uses `map_state.set_discovered_landmarks` and changes landmarks only. If the adopt fails it rolls back. The owner then restarts its cursor.

## Proof
- `test_owner_passive_sync` 30/527: the new rejoin test fails on the old code and passes now.
- `test_guest_groom_passive_sync` 7/86: real maps hash back to the host's set, and fog, regions and pins are untouched.
- At 53556884:
  - G1 r8, r9, r10 and r11: all pass (37309906686, 37309910131, 37309913810, 37309917634).
  - `smoke_net_owner_passive_rejoin`: pass (37309920959).
  - `smoke_net_homestead_station_craft`: pass (37309924891).
- Independent review: `../review-g1-landmarks.md`, APPROVE-WITH-NITS. Nits 2, 4 and 5 are fixed in a87c09b0. Nit 6 is not fixed (see Open).

## Open (review finding 1, predates this change)
- Manual (Meadowhart) and story-revealed (Cloudreach `sync_navigation`) landmarks never reach the host's held set.
- They diverge in-session too, and a later rebase is silently dropped.
- This is a separate follow-up.

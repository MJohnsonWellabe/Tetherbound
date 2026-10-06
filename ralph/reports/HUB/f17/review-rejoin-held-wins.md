# Independent review: rejoin keeps the host's held record (5705101d, 8cc98068) and F34 camp clearance (986c76ab)

**Rule under review.** Owner ruling, STATE §0: "the host world's held record wins inside it (anti-rollback); the guest file counts only where the world has no record." The coordinator's correction replaced the earlier re-admission of an offline change: the guest now adopts the host's held record.

**First review** (independent agent; it did not edit anything):
- 5705101d: **BLOCK**.
- 986c76ab: **APPROVE-WITH-NITS**.

## Findings and fixes (8cc98068)

| # | Severity | Finding | Fix |
|---|---|---|---|
| M1 | Medium | A payout row that only partly fit left a partial stack in the held record, so it was paid again on the next rejoin | Each row is tried on a copy of the bag and lands whole or not at all. Test: `test_a_row_lands_whole_or_not_at_all_and_pending_rows_fold_too` |
| M2 | Medium | With a saved companion decision settling, adoption half-applied (receipts and gear switched, party and satchel did not), and a failed attempt stayed mixed | Adoption waits while the party or inventory owner-mutation guard blocks. A record that cannot apply restores the owner exactly, keeping the same creature instances. Tests: `test_waits_without_change_while_a_companion_decision_settles`, `test_a_record_that_cannot_apply_restores_the_owner_exactly` |
| M3 | Medium | A delivery the guest saved, whose ACK was lost to the disconnect (host row still pending), was lost after adoption | Pending owner-applied rows fold too, since they are host-authored. The readmit carries the folded rows, and the guest marks them settled, so their redelivery acknowledges without paying. Test: `test_folded_payouts_are_marked_settled_and_never_paid_twice` |
| L1 | Low | A stale ally reference with no body blocked adoption forever | Directors whose body is gone are skipped. While adoption waits, the player hears why, once. Test: `test_a_companion_fighting_waits_and_changes_nothing` |
| L2 | Low | The active and best slots were wiped | Both follow their creature by uid |
| L3 | Low | Runtime-only fields (tonic buffs) were wiped | `active_buffs` and `combat_override` stay on the instance |
| L4 | Low | Offline progress was rolled back silently | The player is told: "This world keeps your character as it was here; changes made elsewhere are not used in it." Personal flags keep their existing rule (the host's held flags win in the host world, and the guest's own flags stay local). This is recorded as a boundary, not changed here |
| L5 | Low | Stale comments | Rewritten |
| L6 | Tests | Adoption itself was untested | New `tests/test_owner_passive_adopt.gd` (5 tests) |
| M4 / L7 | Medium | Camp clearance lifted 0.40 m in every realm, which let any low collider pass | Two bands. Below the allowed rise, only the bodies the footprint support rays hit (the ground) are ignored, so every other low collider still blocks. Both bands are anchored at the higher of the sampled base and the placement |
| L8 | Low | The water_world hook comment promised tents and campfires | Narrowed to forward camps |

**Checked correct by the first review:**
- A refused hello restores the record, including `absorbed_deliveries`.
- A hostile declaration can only make the host send that peer its own held record.
- The passive-drift readmit and the landmark (G1) readmit are intact.
- The escrow merge reuses the projection's own classification.
- Energy carries over.
- The hook mirrors Stormwood's setup exactly.

## Re-review of 8cc98068: BLOCK. Fixed in 21389fbc

| # | Severity | Finding | Fix |
|---|---|---|---|
| H1 | High | The per-hello folded list was wiped by `recover_durable_vitals`' record rewrite before the readmit read it. A second rejoin also folded nothing new. Either way, a pending payout the guest never applied was paid twice, and the stream ended | The rows to settle ride every readmit, and any such row forces one. Guest deliveries wait for admission, so the readmit always comes first |
| M1 | Medium | On an exact rejoin the folded rows never reached the guest | The same forced readmit |
| L1 | Low | Folded gather batches were never marked replayed | Marked after a good hello |
| L3, L4 | Low | A freed body blocked adoption, and bodies were put away before the record applied | Validity is checked first. Bodies are put away only after the record applies |
| L5 | Low | Low clearance excluded whole bodies | Only the exact support shapes are excluded |

## Third review of 21389fbc: BLOCK. Fixed in ffdbcb7d

After two failed fixes the approach changed. Instead of deriving the rows from the world row's status, every folded row is now recorded on the host's record until the guest confirms it saved them settled.

| # | Severity | Finding | Fix |
|---|---|---|---|
| H-1 | High | An accepted payout held as `grant_due` escrow (a full bag) was folded but never handed to the guest, so it was paid twice | `unconfirmed_folds` holds every folded row, accepted or pending. It is carried by `_replace_record`, rides every readmit, and is cleared by the guest's `readmitted`. Tests: `test_an_accepted_row_held_grant_due_is_handed_to_the_owner_to_settle`, `test_a_grant_due_escrow_row_the_held_record_holds_is_settled` |
| M-1 | Medium | The settlement and adoption were acknowledged before being saved | The guest saves before `readmitted`. A failed save puts it back exactly and the host resends. Test: `test_the_readmit_is_confirmed_only_after_its_settlement_is_saved` |
| M-2 | Medium | Rebases also held deliveries, so they could stall silently | Deliveries wait only for this join's first admission (`hello_pending`). A join that never lands tells the player once |
| L-1, L-2, L-4 | Low | Terrain region seams, the pre-check before putting companions away, and a stale `status_ms` | All fixed |

## Fourth review of ffdbcb7d: APPROVE-WITH-NITS

- **Payout orderings:** no double or lost payout in any ordering. The reviewer traced redelivery and the `grant_due` loop before and after the readmit, a reconnect after the save, a second rejoin, a host restart and the vitals-deferred path.
- **Other areas checked correct:** the `readmitted_hash` short-circuit, undo, `hello_pending` clearing on every path, the save call, and the terrain exemption.
- **Nits:**
  - the "rewards wait" timer started at dial, not after the snapshot;
  - a failing save repeated the adoption message.
  
  Both are fixed in the landing commit, which also flushes fallback before saving.

## Checks on the landing head

**Unit tests:**

| Suite | Tests | Assertions |
|---|---|---|
| `test_rejoin_admission` | 8 | 51 |
| `test_owner_passive_adopt` (new) | 7 | 41 |
| `test_owner_passive_sync` | 35 | 568 |
| `test_owner_passive_replay` | 11 | 381 |
| `test_forward_camp` | 9 | 186 |

**F34 placement smoke:**

| Realm | Checks | Failures |
|---|---|---|
| Meadows | 21 | 0 |
| Tidewake | 23 | 0 |
| Cloudreach | 21 | 0 |
| Stormwood | 21 | 0 |

**Two-peer smokes:** all report ALL CHECKS PASSED.
- `owner_passive_rejoin`, re-run after the nits;
- `forward_camp`;
- `rejoin_craft_control`;
- `gather_departure`.

# The rebuild under the owner ruling "guest wins unless behind" (2026-10-05)

The held-wins design above was reverted in 83cb8cb1. CI (#544) showed it lost guest-side progress the held record never carried; the evidence is in `rejoin_audit.md`. This section covers the rebuild under the owner ruling.

| Round | Commit | Verdict | Findings and fixes |
|---|---|---|---|
| 1 | 82c1635b | BLOCK | **H1:** an open host transaction read as "behind" (progress lost, or a lockout). **H2:** owed (grant_due) payouts were absorbed, so their later settle killed the stream (first joins too). Also M1, M2 and L1–L5. Fixed in 40df9738 |
| 2 | 40df9738 | BLOCK | Parking an admission behind an open host duty never re-decided after a training or Altar ACK, and the re-decide judged a stale hello declaration. After two attempts the approach changed: an open duty at the hello now refuses the stream as main does (nothing lost; the next rejoin decides on a fresh declaration). Fixed in 8ca5ca73 |
| 3 | 8ca5ca73 | BLOCK | **H1:** a guest adopted after 1024 wild defeats elsewhere lost the accepted training row's receipt to compaction, and recovery refused every hello, a permanent lockout. Fixed in 8b331f75 by tolerating a receipt the record's own full window compacted. **L1:** an unconfirmed fold kept in the hello's list (fixed). **M1** (a missing personal flag counts as behind): sent to the coordinator and owner, because the ruling lists flags. **L2** (a non-fitting accepted row while behind): follow-up |
| 4 | 8b331f75 | APPROVE-WITH-NITS | **M:** anchor the compaction age on the training row's own receipts, so a stale full-window backup is still refused. **L-a:** windows below 2 are never compacted. Both fixed in 66b2f539 |

## Checks on 66b2f539

**Unit tests:**

| Suite | Tests | Assertions |
|---|---|---|
| `test_rejoin_admission` (one test per ruling case) | 15 | 81 |
| `test_owner_passive_sync` | 36 | 577 |
| `test_owner_passive_adopt` | 7 | 41 |
| `test_owner_passive_replay` | 11 | 381 |
| `test_forward_camp` | 9 | 186 |
| `test_altar_building_recovery` | 5 | 156 |

**Two-peer smokes:** all report ALL CHECKS PASSED.
- `owner_passive_rejoin`:
  - deliver-then-leave and an offline change are adopted;
  - a rolled-back backup is behind and adopts the held record, with the find back once and never paid twice;
  - an invalid record is refused.
- `veridian_choices`, `home_creature_bed`, `rejoin_craft_control`, `gather_departure`, `harness_max_hp`, `forward_camp` and `shared_boss`.

Text evidence: `rejoin-admission/guest-wins-*-2peer.txt`.

## Landing round after #545 (merge, R1, two owner-passive fixes)

**What changed:**
- `origin/main` was merged after #545. The `_readmit_owner` conflict kept F18's note line and this lane's undo; F18's early-readmit hold is intact.
- R1's tournament round fix: `cherry-pick -x 93487a4e58`.
- **3a7677b5:** an owner-passive input window dropped before the join snapshot is no longer marked in flight. Before this, the first send waited the full 1.5 s stall. Review: APPROVE-WITH-NITS; the comment nit is fixed in fc4986d8.
- **22dbc94c + 2466ab7f:** a stream's first discovery is now judged against the host's own observed poses over INITIAL_POSE_LAG_S, not only the current one. The ring is bounded, per realm, sampled per physics tick, and cleared on realm change, departure and reset. The 80 m limit is unchanged, and no pose the host didn't observe can count. Review: APPROVE-WITH-NITS; nits 1, 2, 4 and 5 are fixed in 2466ab7f.

**Root cause** (station_craft, `owner_passive_initial_pose_unconfirmed`):
1. The guest lands at the Home Key point (96.2, 14).
2. The stream rebases.
3. The smoke flies the guest 101 m to the kitchen (-4.4, 21.6).
4. The host judges the new stream's first discovery, recorded at the landing, only after that flight, so it is 101 m from the current body and refused.

This was not caused by this lane: `origin/main` failed the same way in 2 of 4 runs alone on the same box.

**Units on 2466ab7f:** owner_passive_sync, rejoin_admission, adopt, replay and director_join_snapshot: 88 tests, 1218 assertions, 0 failed. The new teleport test fails with the old comparison.

**Two-peer smokes on 2466ab7f, each run alone:**

| Smoke | Runs | Result |
|---|---|---|
| `homestead_station_craft` (portals on) | 3 | ALL CHECKS PASSED in all 3 |
| `owner_passive_rejoin` | 1 | ALL CHECKS PASSED |
| `veridian_choices` | 1 | ALL CHECKS PASSED |

The same five also passed on 22dbc94c.

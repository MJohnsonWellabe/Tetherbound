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

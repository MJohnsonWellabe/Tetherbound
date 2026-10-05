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

**Re-review:** pending.

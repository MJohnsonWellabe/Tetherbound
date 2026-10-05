# Review blockers: reproductions (review-gather-batching.md)

Fix commit: 99886a5e. Each blocker has a test on the fixed code and a reproduction against the code before the fix.

| Finding | Test on 99886a5e (passes) | Reproduction before the fix |
|---|---|---|
| B3 forged `pickup:`/`tm:` flag mints into the host record (81e045f0) | `test_guest_pickup_delivery.gd::test_a_forged_key_or_tm_flag_never_mints_into_the_authority` | Same test with the old prefix inference restored in `pickup_spec_registry.lookup`: FAIL, "expected item_grant, got reward_delivery" for both `pickup:rare_candy` and `tm:tm_anything` (a durable delivery into the host record). |
| B1 later batch sweeps an unsettled earlier one; replay loses its row | `test_gather_batches.gd::test_an_unsettled_earlier_batch_is_never_swept_by_a_later_one`, `::test_a_row_prunes_only_once_it_is_both_accepted_and_replayed` | Scratch test against the 48813e94 batching files (gather_batches, world_state, world_ledger, ledger_rpc, registry, harvest_node, schema): two batches flushed, both ACKed, batch 2 marked replayed. FAIL, "batch 1 (never replayed) must survive": the old monotonic marks pruned it. |
| B2 guest escrow prune by seq floor alone pays twice | `test_gather_batches.gd::test_the_guest_prunes_escrow_only_for_this_worlds_gone_rows` (pending host row, foreign namespace, grant_due and non-batch rows are all kept) | The old rule (48813e94 `ledger_rpc._gather_guest_view`) erased every settled `gather_batch:<seq>` escrow row with `seq <= min(acked, replayed)` with no namespace or host-row check; inline scene code, so shown by inspection rather than a runnable pure test. |

Exactly-once end to end: two-peer smoke `tests/smoke_net_homestead_station_craft.gd` (gather → craft → reconnect; host authority equals the guest satchel; no re-grant; rows pruned).

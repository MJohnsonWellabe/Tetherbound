# Independent review: F34 forward camps (3ba2c5f5, 9974f0e8, d81ffb74, 2b0ab3ac)

**Verdict:** APPROVE-WITH-NITS. The reviewer was an independent agent; it did not edit anything.

**Authority holds:**
- **Who and what kit:** the character comes from `_authority_character`, and the kit is debited from the admitted inventory.
- **Realm:** taken from the host-stamped `net_realm`.
- **Packing:** packing someone else's camp is refused with `camp_owner`. A double refund is impossible, because the camp becomes a tombstone and its receipt is deduplicated.
- **Not covered by this change:** the guest's position is client-driven, as for every remote action.

## Findings and fixes

| # | Severity | Finding | Fix |
|---|---|---|---|
| 1 | Medium | Guest camp refusals were silent, and the host's showed raw codes | The placer listens to `homestead_action_completed` for `camp_build` and says `CAMP_RULES.deny(code).reason`. Reasons were added for `source_or_revision_changed`, `camp_kit_missing` and `satchel_full` |
| 2 | Medium | The guest's pack-then-place was fragile: armed without a pack actually sent, and the timeout message was untrue | It is armed only when the pack was sent (settled or awaiting its saved decision). The pack is matched by `action_id`, and a refusal of it clears the repack with its reason. The timeout message re-checks whether the old camp is gone. The two-peer smoke now covers the guest's repack |
| 3 | Medium (gap) | A co-op guest can place only in the host's loaded realm | Recorded in STATE and the F34 receipt. A guest in a different realm now hears the refusal |
| 4 | Low | Excluding all teammates' bodies was too broad (stations or camps could be placed on a teammate) | Reverted. `validate_forward_camp_ground` takes `placer_body` (the requesting trainer only); `forward_camp_host.placement_context` passes it |
| 5 | Low | `registry_revision = -1` made an empty cache look present | The key is erased instead |
| 6 | Low | A packed camp's collider lingered until the frame ended | Its node leaves the tree immediately, then is freed |
| 7 | Low | Packing from anywhere also widens dismantle-pack | Accepted; it is limited by the dismantle ray |
| 8 | Tests | Several gaps | Unit tests added: no kit, and a realm mismatch. The guest repack is in the two-peer smoke. Tidewake (no BuildPlacer) is pending the coordinator's ownership answer. Kit crafting at the Workbench is still a fixture (the station-craft path is shared with F31) |
| 9 | — | `_tabs.assign` fix | Confirmed correct |

## Checks after the fixes

- `test_forward_camp`: 9 tests, 186 assertions, all pass.
- `test_build_placer_preview` 16/43 and `test_build_catalogue` 14/246 pass.
- `smoke_f34_forward_camp` (Meadows): 19/19.
- Two-peer `smoke_net_forward_camp`: ALL CHECKS PASSED (`f34/forward-camp-2peer.txt`).

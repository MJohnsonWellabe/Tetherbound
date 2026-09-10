# Water optional reward delivery audit

Date: 2026-09-10  
Scope: read-only source/data audit; no Godot run and no production edits

## Verdict

The five named encounters are now production-spawned and clear their authored once flags, despite the stale `status: authored_optional_encounter_not_runtime_instantiated` text in `water_encounters.json`. Their `reward_role` is copied only into body metadata. Catch or defeat marks the encounter complete; no encounter-resolution path grants an item, activates a pickup, or unlocks a route.

The eight `reward_pockets` are planning reservations, not broken spawned pickups. This is explicit both in each row's comment (item IDs, placement, ownership, and evidence belong to content runtime) and in `ralph/reports/WATER-PROGRESS/foundation.md` ("Reserved pockets are not pickups"). `reward_pockets` has no code reader anywhere in the repository. None of the eight pocket centers has a pickup or harvest node within its authored 5 m radius.

Actual Water inventory delivery is healthy but independent: `water_world.gd` builds `WaterPickups` from `water_pickups.json`; ordinary finds submit `claim_pickup`, while the twelve personal Skill Candies submit `water_personal_pickup`. Both ledger routes issue `item_grant` to the owning player and retain durable world or character receipts. No pickup row names a reward pocket, named encounter, or encounter completion flag, and the pickup streamer does not evaluate encounter prerequisites.

Therefore:

- The encounters themselves are reachable content and may yield the normal catch outcome. Their advertised item reward roles are not delivered by encounter resolution.
- The pockets are unimplemented content reservations relative to the Water exit criterion that optional islands must pay. They are not runtime pickups that happen to be unreachable.
- Separate dock actions and route changes are the intended environmental-access reward system. They do not satisfy these item-like roles, and none of the five named completion flags is consumed by an access system.

## Named encounter trace

| Encounter | Authored role | Closest same-role authored pickup | Runtime conclusion |
|---|---|---|---|
| Lantern Shell Sentinel, `[-431.554, 12.2334, 111.412]` | `skill_candy_i` | `water:lantern_cove:pickup:002`, quantity 1, `character_once`, 115.38 m away; a second tier-I row is 173.92 m away | Two candidates and no identity link. Completion only clears `water_named_lantern_shell_sentinel_resolved`. |
| Basalt Claw, `[-75.328, 12.283, 777.86]` | `great_candy` | `water:gull_rest:pickup:003`, quantity 1, world-once, 63.16 m away | Same-island item exists but can be collected independently before or without the encounter. |
| Root Watcher, `[326.835, 12.3126, 816.738]` | `revive` | No revive on Brine Steps; closest is `water:shellwatch:pickup:004`, quantity 1, world-once, 260.25 m away on another island | No defensible existing placement to bind. |
| Garden Songweaver, `[1064.267, -0.5076, 2152.577]` | `skill_candy_ii` | `water:drowned_garden:pickup:002`, quantity 1, `character_once`, 150.25 m away | Same-island item exists but has no encounter dependency or identity link. |
| Tidecoil, `[1483.196, -0.5075, 3427.917]` | `skill_candy_iii` | `water:deep_watch:pickup:002`, quantity 1, `character_once`, 142.38 m away | The singleton tier-III pickup is much closer to the separate Deep Watch pocket than to Tidecoil and cannot safely be claimed as both rewards. |

The source contract says `deduplicated_personal_reward_placement_reserved_in_pickup_data_no_direct_grant`. A direct encounter grant would contradict it. The existing rows establish item identities and quantity 1, but proximity alone does not establish which physical find belongs to which encounter.

## Reward pocket trace

| Pocket (center; radius 5 m) | Role | Closest exact-role runtime content | Classification |
|---|---|---|---|
| `lantern_hidden_cache` `[-407.668, 15.829, 210.38]` | `skill_candy_i` | Tier I quantity 1 at 97.02 m (another at 163.58 m) | Ambiguous between two existing placements. |
| `reed_root_hollow` `[-101.041, 18.048, 457.816]` | `recipe_and_reed_fiber` | Nearest reed-fiber harvest is 81.28 m; no item ID represents the combined recipe role | Requires an explicit recipe/unlock decision and resource quantity. |
| `brine_upper_shelf` `[516.431, 46.318, 615.033]` | `skill_candy_i` | Same-island tier I quantity 1 at 157.59 m | Exact item precedent exists, but the intended position is materially different. |
| `gull_research_satchel` `[-17.84, 22.677, 883.976]` | `skill_candy_ii` | Same-island tier II quantity 1 at 86.97 m | Exact item precedent exists, but the intended position is materially different. |
| `cradle_shell_nest` `[815.824, 55.199, 1645.824]` | `reefstone_and_mount_care` | Nearest reef-stone harvest is 253.26 m; no item ID represents `mount_care` | Requires item/quantity semantics and likely more than one transaction. |
| `salt_bell_terrace` `[30.731, 56.08, 2393.513]` | `skill_candy_i` | Same-island tier I quantity 1 at 81.36 m | Exact item precedent exists, but the intended position is materially different. |
| `garden_exposed_vault` `[1200, 27.864, 2337.6]` | `skill_candy_ii` | Same-island tier II quantity 1 at 79.58 m | Exact item precedent exists, but the intended position is materially different. |
| `deep_watch_tidecoil_cache` `[1409.751, 36.123, 3550.137]` | `skill_candy_iii` | `water:deep_watch:pickup:002`, quantity 1, `character_once`, 14.29 m away | Strongest existing-authored pairing; still outside the pocket radius. |

The simplest future physical-pocket repair is the Deep Watch pair. The only tier-III Candy already has the correct island, item, quantity, personal claim policy, and a production pickup position only 14.29 m from the pocket. Repositioning that existing row to the pocket center, or explicitly reconciling the pocket center to the existing row, would not change item identity, quantity, ownership, or the global 7/4/1 Candy census. Its current row has generated dry-ground/slope data and the analytic all-pickup smoke exercises construction, but ordinary Terrain3D traversal to either exact point has not been proven; that footing check remains required before a production move.

The other single-tier pocket pairings could use the same existing producer after authored placement review. Lantern Cove is ambiguous because it has two tier-I candidates. The Reedhaven and Tidal Cradle composite roles cannot be repaired without choosing recipe/care delivery and quantities.

## Environmental access reward finding

Two current-reduction shortcuts already have fully authored producer and consumer inputs:

- `shellwatch_pump_return_channel`: flag `water_dock_shellwatch_residents_freed_and_pump_disabled`, route `brine_steps_to_shellwatch_direct`, post-unlock strength `0.08` m/s.
- `deep_watch_current_cut`: flag `water_dock_deep_watch_current_charted`, route `sluice_isle_to_deep_watch_direct`, post-unlock strength `0.1` m/s. The production `deep_watch_chart` dock action already writes that flag.

`water_world.gd` currently annotates current rows only from dock departure gates, and `water_current_field.gd` reads only `required_unlock_flag`, `closed_strength_m_s`, and base `strength_m_s`. It never consumes `return_shortcuts` or `strength_after_unlock_m_s`. Thus these two intended access rewards currently produce durable flags but no current reduction. A bounded future repair can bind each authored `current_reduction` row onto its matching route and have the field select the already-authored reduced strength when its flag is set. This requires no invented flag, route, or tuning value. The third shortcut, `reedhaven_maintenance_ramp`, requires physical geometry/visibility behavior and is not the same low-cost data binding.

These access gaps are separate from the five named item roles. None of the named completion flags appears outside `water_encounters.json`, so resolving a named encounter cannot currently open either shortcut.

## Evidence limits and disposition

This audit used static source/data tracing and coordinate comparison only. It did not run Godot, prove Terrain3D reachability, collect a pocket in ordinary play, defeat a named encounter, or validate multiplayer delivery live. Existing focused tests prove the independent pickup and named-spawn mechanisms, not their association.

Preserve the no-direct-grant contract. A subsequent authorized candidate binds the two already-authored current-reduction shortcuts in `water_current_field.gd`; focused unit coverage reads the production configuration, and the production dock smoke exercises both real flag producers, exact current strengths, route isolation, and pre/post-reward save reloads. Godot execution remains a root-owned follow-up, so this report does not claim those checks passed yet. The Water surface currently has no current-field-driven visible-flow consumer; this candidate does not invent one or claim visual-flow proof.

The next physical-pocket candidate remains: prove the Deep Watch tier-III pickup footing, then reconcile that singleton pickup with its 5 m pocket. The remaining encounter and composite-pocket mappings need an explicit authored association rather than a proximity guess.

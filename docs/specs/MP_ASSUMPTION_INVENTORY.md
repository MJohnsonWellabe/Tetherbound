# MP assumption inventory — 2026-09-05 — main at b7999827
## Overview
This inventory catalogs single-player assumptions in the Tetherbound codebaseas they exist on main at b7999827. Each section records the exact ripgrep command(s)used, the total count of matches, and a per-file table sorted by match count,with up to 3 representative line:snippet pairs per file.
The data is the raw material for a conversion map: another agent can reproduceevery result by re-running the exact commands recorded.

## 1. `Game.<field>` reads and writes

### Game.party

**Total: 56 matches**

**Command:**
```
rg 'Game\.party|game\.get\("party"\)|game\.set\("party"|_game\.get\("party"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/combat/encounter_director.gd | 8 | 139:## `CO1`. The last `Game.party.revision` `_sync_active_creature()` acted on, so a | 1218:## `CO1`. `Game.party`, the same autoload `tab_creatures.gd` reads and writes. | 1225:return game.get("party") if game != null else null |
| scripts/story/party_seam.gd | 6 | 20:##      API is `Game.party.add()` / `.members()` / `.is_full()`. | 25:## opening never reached `Game.party`, and nothing said so: the party screen | 36:##   - **Bind to the real party all-or-nothing.** If `Game.party` is there but |
| scripts/story/sequence_director.gd | 6 | 356:var party: RefCounted = game.get("party") if game != null else null | 696:var party: RefCounted = game.get("party") | 1345:var party: RefCounted = game.get("party") |
| scripts/build/creature_bed.gd | 4 | 438:var party: RefCounted = game.get("party") if game != null else null | 453:var party: RefCounted = game.get("party") if game != null else null | 468:var party: RefCounted = game.get("party") if game != null else null |
| scripts/save/save_game.gd | 3 | 304:"party": _party_to_array(game.get("party")), | 362:_array_to_party(data.get("party", []), game.get("party")) | 434:var party: Variant = game.get("party") |
| scripts/ui/playground_hud.gd | 3 | 1679:## the one place that reads `Game.party` and hands it entries as plain data. | 1910:## Wired to `Game.party.active_index()` + `.revision`: rebuild entries and | 3719:_party = _game.get("party") as RefCounted |
| scripts/ui/swap_panel.gd | 3 | 324:var party: RefCounted = game.get("party") if game != null else null | 360:var party: RefCounted = game.get("party") if game != null else null | 430:var party: RefCounted = game.get("party") if game != null else null |
| scripts/player/fly_controller.gd | 2 | 98:var party: Variant = _game.get("party") if is_instance_valid(_game) else null | 348:var party: Variant = _game.get("party") if _game != null else null |
| scripts/vfx/combat_vfx.gd | 2 | 31:##     lane must not; until it lands the watcher polls `Game.party` -- the | 278:var party: Variant = game.get("party") |
| scripts/ui/creature_bed_panel.gd | 2 | 198:var party: RefCounted = game.get("party") | 296:var party: RefCounted = game.get("party") if game != null else null |
| scripts/ui/tab_creatures.gd | 2 | 1601:## and no sixth creature in `Game.party` at any point in any beat. | 1880:return game.get("party") if game != null else null |
| scripts/ui/combat_hud.gd | 2 | 996:## convention, not enforced privacy. Falls back to `Game.party` if the manager | 1007:var party_auto: Variant = game.get("party") |
| scripts/world/stronghold_climax.gd | 2 | 919:var party: RefCounted = game.get("party") | 939:var party: RefCounted = game.get("party") |
| scripts/creatures/companion_presence.gd | 2 | 122:## `Game.party.active()` -- the deployed body IS the active party member. | 404:var party: Variant = _game.get("party") |
| tests/helpers/gate_a_opening_drive.gd | 1 | 525:var party: RefCounted = _game.get("party") |
| tests/helpers/gate_a_npc_gather_segment.gd | 1 | 78:if int((_game.get("party") as RefCounted).call("size")) < 2: |
| tests/helpers/gate_b_tail_segment.gd | 1 | 154:_party = _game.get("party") |
| scripts/build/build_placer.gd | 1 | 880:var party: RefCounted = game.get("party") |
| scripts/ui/party_strip.gd | 1 | 18:## reaches into `Game.party` and hands the result in. |
| scripts/ui/tab_backpack.gd | 1 | 2381:return game.get("party") if game != null else null |
| scripts/world/tournament.gd | 1 | 582:return game.get("party") if game != null else null |
| scripts/world/cloudreach_physical_runtime.gd | 1 | 263:var party: RefCounted = _game.get("party") if _game != null else null |
| scripts/world/burrow_warrens.gd | 1 | 3378:var party: RefCounted = game.get("party") |

### Game.inventory

**Total: 52 matches**

**Command:**
```
rg 'Game\.inventory|game\.get\("inventory"\)|game\.set\("inventory"|_game\.get\("inventory"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| tests/helpers/gate_b_tail_segment.gd | 5 | 246:var inventory: RefCounted = _game.get("inventory") | 400:var inventory: RefCounted = _game.get("inventory") | 604:var inventory: RefCounted = _game.get("inventory") |
| tests/helpers/gate_a_npc_gather_segment.gd | 5 | 107:if int((_game.get("inventory") as RefCounted).call("count", tool_id)) != 1: | 118:if int((_game.get("inventory") as RefCounted).call("count", tool_id)) != 1: | 140:if int((_game.get("inventory") as RefCounted).call("count", "hammer")) < 1: |
| scripts/ui/playground_hud.gd | 3 | 3725:var inventory: RefCounted = _game.get("inventory") | 4008:var inventory: RefCounted = _game.get("inventory") | 4493:var inventory: RefCounted = _game.get("inventory") |
| scripts/world/farm_plot.gd | 3 | 167:var inventory: RefCounted = game.get("inventory") | 177:var inventory: RefCounted = game.get("inventory") | 320:var inventory: RefCounted = game.get("inventory") |
| tests/helpers/gate_a_material_route.gd | 2 | 249:if int((_game.get("inventory") as RefCounted).call("find_slot", item_id)) < 0: | 1072:return int((_game.get("inventory") as RefCounted).call("count", item_id)) |
| tests/helpers/gate_a_build_segment.gd | 2 | 658:var inventory: RefCounted = _game.get("inventory") | 1167:return int(_game.get("inventory").call("count", id)) |
| scripts/save/save_game.gd | 2 | 305:"inventory": _inventory_to_array(game.get("inventory")), | 363:_array_to_inventory(data.get("inventory", []), game.get("inventory")) |
| scripts/build/build_placer.gd | 2 | 679:var inventory: RefCounted = game.get("inventory") | 829:var inventory: RefCounted = game.get("inventory") |
| scripts/story/sequence_director.gd | 2 | 730:var inventory: RefCounted = game.get("inventory") | 1419:var inventory: RefCounted = game.get("inventory") |
| scripts/ui/build_menu.gd | 2 | 657:var inventory: RefCounted = game.get("inventory") if game != null else null | 768:var inventory: RefCounted = game.get("inventory") |
| scripts/world/burrow_warrens.gd | 2 | 2931:var inventory: RefCounted = game.get("inventory") | 3353:var inventory: RefCounted = game.get("inventory") |
| scripts/world/key_pickup.gd | 2 | 89:var inventory: RefCounted = game.get("inventory") | 231:var inventory: RefCounted = game.get("inventory") |
| scripts/build/home_progress.gd | 1 | 203:var inventory: RefCounted = game.get("inventory") |
| scripts/ui/shop_panel.gd | 1 | 251:return game.get("inventory") if game != null else null |
| scripts/ui/tab_creatures.gd | 1 | 1875:return game.get("inventory") if game != null else null |
| scripts/world/vegetation_harvest_point.gd | 1 | 147:var inventory: RefCounted = game.get("inventory") |
| scripts/ui/tab_backpack.gd | 1 | 2371:return game.get("inventory") if game != null else null |
| scripts/world/tm_pickup.gd | 1 | 284:var inventory: RefCounted = game.get("inventory") |
| scripts/world/item_cache_pickup.gd | 1 | 165:var inventory: RefCounted = game.get("inventory") |
| scripts/ui/storage_panel.gd | 1 | 201:var player_inventory: RefCounted = game.get("inventory") |
| scripts/world/player_death.gd | 1 | 71:var bag: RefCounted = game.get("inventory") |
| scripts/ui/craft_panel.gd | 1 | 570:return game.get("inventory") if game != null else null |
| scripts/world/felled_resource.gd | 1 | 261:var inventory: RefCounted = game.get("inventory") |
| scripts/world/road_gate.gd | 1 | 473:var inventory: RefCounted = game.get("inventory") if game != null else null |
| scripts/combat/throw_aim.gd | 1 | 238:return game.get("inventory") |
| scripts/combat/encounter_director.gd | 1 | 2387:var inventory: RefCounted = game.get("inventory") |
| scripts/world/gated_crossing.gd | 1 | 381:var inventory: RefCounted = game.get("inventory") if game != null else null |
| scripts/world/cloudreach_physical_runtime.gd | 1 | 190:var inventory: RefCounted = _game.get("inventory") |
| scripts/world/river_nest_clear.gd | 1 | 85:var inventory: RefCounted = game.get("inventory") if game != null else null |
| scripts/world/harvest_node.gd | 1 | 369:var inventory: RefCounted = game.get("inventory") |
| scripts/world/riding_controller.gd | 1 | 269:var bag: RefCounted = game.get("inventory") |
| scripts/world/cart_repair.gd | 1 | 97:var inventory: RefCounted = game.get("inventory") if game != null else null |

### Game.progression

**Total: 84 matches**

**Command:**
```
rg 'Game\.progression|game\.get\("progression"\)|game\.set\("progression"|_game\.get\("progression"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/story/sequence_director.gd | 6 | 351:var progression: RefCounted = game.get("progression") if game != null else null | 430:var progression: RefCounted = game.get("progression") if game != null else null | 480:var progression: RefCounted = game.get("progression") |
| scripts/world/realm_heart_shrine.gd | 6 | 5:## State belongs to `Game.realm_hearts` and `Game.progression`, never to this | 12:##   Game.realm_hearts.is_earned(heart_id, Game.progression) -> bool | 13:##   Game.realm_hearts.is_placed(heart_id, Game.progression) -> bool |
| scripts/world/realm_chapter_events.gd | 5 | 3:## Small scene adapter for production Game.progression. Add under a realm scene, | 24:var progression: RefCounted = game.get("progression") | 33:var result := LOGIC.dispatch(game.get("progression"), chapter, event) |
| scripts/world/cloudreach_chapter.gd | 4 | 91:var progression: RefCounted = game.get("progression") | 121:CHAPTER_LOGIC.reconcile(_game.get("progression"), _chapter) | 199:var progression: RefCounted = game.get("progression") |
| scripts/world/trainer_npc.gd | 4 | 92:## CL-W5(a). The last `Game.progression.revision` `_process()` relabelled for. | 98:## `Game.progression`, looked up once. Null until the first frame that finds | 294:## `Game.progression`, SB9's flat flag store -- same null-tolerant `/root/Game` |
| scripts/build/home_progress.gd | 3 | 133:var progression: RefCounted = game.get("progression") | 188:var progression: RefCounted = game.get("progression") | 200:var progression: RefCounted = game.get("progression") |
| scripts/world/river_nest_clear.gd | 3 | 70:var progression: RefCounted = game.get("progression") if game != null else null | 77:var progression: RefCounted = game.get("progression") if game != null else null | 86:var progression: RefCounted = game.get("progression") if game != null else null |
| scripts/world/cart_repair.gd | 3 | 82:var progression: RefCounted = game.get("progression") if game != null else null | 89:var progression: RefCounted = game.get("progression") if game != null else null | 98:var progression: RefCounted = game.get("progression") if game != null else null |
| scripts/save/save_game.gd | 2 | 299:var progression_obj: Variant = game.get("progression") | 389:var progression_obj: Variant = game.get("progression") |
| scripts/ui/tab_quest_log.gd | 2 | 5:## Reads `Game.progression`'s flags through `scripts/world/quest_log.gd`, the | 104:var progression: RefCounted = game.get("progression") if game != null else null |
| scripts/world/tm_pickup.gd | 2 | 63:var progression: RefCounted = game.get("progression") | 296:var progression: RefCounted = game.get("progression") |
| scripts/world/item_cache_pickup.gd | 2 | 86:var progression: RefCounted = game.get("progression") | 176:var progression: RefCounted = game.get("progression") |
| scripts/world/cloudreach_world.gd | 2 | 178:var progression: Variant = game.get("progression") if game != null else null | 1394:var progression: Variant = game.get("progression") if game != null else null |
| scripts/world/road_gate.gd | 2 | 273:var progression: RefCounted = game.get("progression") if game != null else null | 474:var progression: RefCounted = game.get("progression") if game != null else null |
| scripts/world/cloudreach_world_runtime.gd | 2 | 74:finale.call("setup", game.get("progression"), Callable(chapter.call("events_adapter"), "em | 101:atmosphere.call("configure", game.get("progression"), navigation, player, presentation.cal |
| scripts/combat/encounter_director.gd | 2 | 2439:## `Game.progression`, SB9's flat flag store. Same null-tolerant `/root/Game` | 2443:return game.get("progression") if game != null else null |
| scripts/world/village_npcs.gd | 2 | 117:return game.get("progression") if game != null else null | 254:var progression: RefCounted = game.get("progression") if game != null else null |
| scripts/world/key_pickup.gd | 2 | 83:var progression: RefCounted = game.get("progression") | 242:var progression: RefCounted = game.get("progression") |
| scripts/world/gated_crossing.gd | 2 | 172:var progression: RefCounted = game.get("progression") if game != null else null | 382:var progression: RefCounted = game.get("progression") if game != null else null |
| scripts/world/cloudreach_physical_runtime.gd | 2 | 60:_flags = _game.get("progression") if _game != null else null | 348:_flags = game.get("progression") |
| scripts/world/harvest_node.gd | 2 | 115:var progression: RefCounted = game.get("progression") | 429:var progression: RefCounted = game.get("progression") |
| scripts/player/fly_controller.gd | 1 | 81:var progression: Variant = _game.get("progression") if is_instance_valid(_game) else null |
| scripts/build/player_bed.gd | 1 | 137:var progression: RefCounted = game.get("progression") |
| scripts/build/creature_bed.gd | 1 | 407:var progression: RefCounted = game.get("progression") if game != null else null |
| scripts/vfx/combat_vfx.gd | 1 | 327:## The seam for `Game.progression_feed` (prompt 73 §2.1): an event of kind |
| scripts/ui/swap_panel.gd | 1 | 180:return game.get("progression") if game != null else null |
| scripts/world/meadow_healing.gd | 1 | 65:_progression = game.get("progression") as RefCounted if game != null else null |
| scripts/world/cloudreach_resource_patch.gd | 1 | 87:var progression: RefCounted = game.get("progression") |
| scripts/world/cloudreach_atmosphere.gd | 1 | 91:progression = game.get("progression") |
| scripts/world/night_rest.gd | 1 | 75:var progression: RefCounted = game.get("progression") |
| scripts/world/tether_relay.gd | 1 | 1774:return game.get("progression") as RefCounted |
| scripts/world/rift_collapse.gd | 1 | 352:_progression = game.get("progression") as RefCounted |
| scripts/world/player_death.gd | 1 | 85:fallback = resolve_safe_camp(_recovery_camps, game.get("progression"), from, |
| scripts/world/cloudreach_finale_controller.gd | 1 | 82:_progression = game.get("progression") |
| scripts/world/burrow_warrens.gd | 1 | 3556:return game.get("progression") if game != null else null |
| scripts/world/alpha_pins.gd | 1 | 258:return game.get("progression") if game != null else null |
| scripts/world/stronghold_occupation.gd | 1 | 587:_withdraw_progression = game.get("progression") as RefCounted if game != null else null |
| scripts/world/stronghold_climax.gd | 1 | 1015:return game.get("progression") as RefCounted if game != null else null |
| scripts/world/stronghold.gd | 1 | 5037:return game.get("progression") if game != null else null |
| scripts/world/realm_gate.gd | 1 | 283:var value: Variant = game.get("progression") |
| scripts/world/cloudreach_world_payoffs.gd | 1 | 73:var flags: RefCounted = game.get("progression") |
| scripts/world/tournament.gd | 1 | 577:return game.get("progression") if game != null else null |
| scripts/world/riding_controller.gd | 1 | 614:return game.get("progression") if game != null else null |
| tests/helpers/gate_b_tail_segment.gd | 1 | 153:_progression = _game.get("progression") |
| tests/helpers/gate_a_npc_gather_segment.gd | 1 | 174:var progression: RefCounted = _game.get("progression") |

### Game.map

**Total: 14 matches**

**Command:**
```
rg 'Game\.map|game\.get\("map"\)|game\.set\("map"|_game\.get\("map"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/ui/minimap.gd | 4 | 4:## player-up-rotated read of `Game.map` (`autoload/map_state.gd`, D33's one | 9:## `Game.map` itself exposes. | 44:## FOG TEXTURE. Rebuilt only when `Game.map`'s `revision` changes |
| scripts/save/save_game.gd | 3 | 298:var map_obj: Variant = game.get("map") | 384:var map_obj: Variant = game.get("map") | 416:var live_map: Variant = game.get("map") |
| scripts/ui/playground_hud.gd | 3 | 2482:var game_map: RefCounted = _game.get("map") | 2901:## Polls `Game.map`'s one-shot queue (`take_pending_region_announcement()`) | 2909:var map: RefCounted = _game.get("map") |
| scripts/ui/tab_map.gd | 2 | 5:## (`assets/ui/icons/map/`). This tab reads the same `Game.map` the minimap | 1130:return game.get("map") if game != null else null |
| scripts/world/player_death.gd | 1 | 140:var map: RefCounted = game.get("map") |
| scripts/world/alpha_pins.gd | 1 | 253:return game.get("map") if game != null else null |

### Game.hotbar

**Total: 16 matches**

**Command:**
```
rg 'Game\.hotbar|game\.get\("hotbar"\)|game\.set\("hotbar"|_game\.get\("hotbar"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 5 | 1217:if game == null or typeof(game.get("hotbar")) != TYPE_ARRAY: | 1219:var slots: int = (game.get("hotbar") as Array).size() | 1226:game.set("hotbar", rebuilt) |
| scripts/ui/playground_hud.gd | 4 | 3734:## The hotbar draws `Game.hotbar` — five item ids the player assigned, NOT | 3757:var assignments: Array = _game.get("hotbar") as Array | 3767:assignments = _game.get("hotbar") as Array |
| scripts/ui/tab_backpack.gd | 4 | 987:var bar: Array = game.get("hotbar") as Array | 1048:var bar: Array = game.get("hotbar") as Array | 1160:var bar: Array = game.get("hotbar") as Array |
| tests/helpers/gate_a_npc_gather_segment.gd | 2 | 290:if str((_game.get("hotbar") as Array)[destination]) != item_id: | 356:var hotbar: Array = _game.get("hotbar") as Array |
| tests/helpers/gate_a_material_route.gd | 1 | 244:var hotbar: Array = _game.get("hotbar") as Array |

### Game.equipped_tool

**Total: 33 matches**

**Command:**
```
rg 'Game\.equipped_tool|game\.get\("equipped_tool"\)|game\.set\("equipped_tool"|_game\.get\("equipped_tool"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/ui/playground_hud.gd | 9 | 4036:if str(_game.get("equipped_tool")) == id: | 4037:_game.set("equipped_tool", "") | 4045:_game.set("equipped_tool", id) |
| tests/helpers/gate_a_npc_gather_segment.gd | 7 | 349:if str(_game.get("equipped_tool")) != tool_id: | 352:if str(_game.get("equipped_tool")) == tool_id and hold != null and hold.call("prop_node")  | 355:if str(_game.get("equipped_tool")) != tool_id or hold == null or hold.call("prop_node") == |
| tests/helpers/gate_b_tail_segment.gd | 5 | 952:if str(_game.get("equipped_tool")) != "hammer": | 960:if str(_game.get("equipped_tool")) == "hammer": | 992:+ "(equipped '%s', arbiter offering '%s')" % [str(_game.get("equipped_tool")), |
| tests/helpers/gate_a_material_route.gd | 4 | 502:str(_game.get("equipped_tool")), | 524:str(_game.get("equipped_tool")), | 647:if str(_game.get("equipped_tool")) != expected_tool: |
| tests/helpers/gate_a_build_segment.gd | 3 | 635:% [str(_game.get("equipped_tool")), | 656:if str(_game.get("equipped_tool")) == "hammer": | 671:if str(_game.get("equipped_tool")) != "hammer": |
| scripts/player/tool_hold.gd | 1 | 243:var wanted := str(game.get("equipped_tool")) if game != null else "" |
| scripts/build/build_hold.gd | 1 | 38:return game != null and str(game.get("equipped_tool")) == BUILD_TOOL |
| scripts/world/harvest_node.gd | 1 | 377:var held_tool := str(game.get("equipped_tool")) if equipped_tool == null else str(equipped |
| scripts/world/vegetation_harvest_point.gd | 1 | 151:var held_tool := str(game.get("equipped_tool")) if equipped_tool == null else str(equipped |
| scripts/world/harvest_logic.gd | 1 | 98:if str(game.get("equipped_tool")).is_empty(): |

### Game.pending_build

**Total: 24 matches**

**Command:**
```
rg 'Game\.pending_build|game\.get\("pending_build"\)|game\.set\("pending_build"|_game\.get\("pending_build"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| tests/helpers/gate_a_build_segment.gd | 7 | 216:if str(_game.get("pending_build")) != "": | 517:if str(_game.get("pending_build")) != id: | 518:_fail("controller selected %s but live pending selection is '%s'" % [id, str(_game.get("pe |
| scripts/debug/gate_f_probe.gd | 4 | 477:##   `build_placement` — nothing owns input, no fight, and `Game.pending_build` | 564:##   `pending_build`    — `Game.pending_build`, the armed-ghost string. | 477:##   `build_placement` — nothing owns input, no fight, and `Game.pending_build` |
| tests/helpers/gate_b_tail_segment.gd | 4 | 1014:if str(_game.get("pending_build")) != id: | 1016:% [id, str(_game.get("pending_build"))]) | 1112:if str(_game.get("pending_build")) == "": |
| scripts/build/build_placer.gd | 2 | 219:var armed := str(game.get("pending_build")) | 261:game.set("pending_build", "") |
| scripts/ui/playground_hud.gd | 2 | 3646:if _game != null and str(_game.get("pending_build")) != "": | 4260:and str(_game.get("pending_build")) != "" |
| scripts/story/sequence_director.gd | 1 | 776:var building: bool = game != null and str(game.get("pending_build")) != "" |
| scripts/ui/game_menu.gd | 1 | 679:if game != null and str(game.get("pending_build")) != "": |
| scripts/ui/build_menu.gd | 1 | 756:game.set("pending_build", id) |
| scripts/combat/combat_manager.gd | 1 | 753:if str(game.get("pending_build")) != "": |
| scripts/creatures/companion_presence.gd | 1 | 357:if _game != null and is_instance_valid(_game) and not str(_game.get("pending_build")).is_e |

### Game.pending_catch

**Total: 12 matches**

**Command:**
```
rg 'Game\.pending_catch|game\.get\("pending_catch"\)|game\.set\("pending_catch"|_game\.get\("pending_catch"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/ui/tab_creatures.gd | 5 | 303:# `Game.pending_catch` is still set, so nothing is lost — and stale stage | 1597:## Entered from poll() whenever `Game.pending_catch` is set — the Game | 1632:game.set("pending_catch", null) |
| scripts/world/stronghold_climax.gd | 4 | 16:##     one way it is reachable: `Game.pending_catch`. Not reimplemented. | 896:## `Game.pending_catch` is R4.10's ONE seam and this hands the creature to it | 927:game.set("pending_catch", creature) |
| scripts/combat/encounter_director.gd | 3 | 1988:## on `Game.pending_catch` — exactly one, never saved, not storage — and the | 2016:if game.get("pending_catch") != null: | 2025:game.set("pending_catch", kept) |

### Game.placed_buildings

**Total: 20 matches**

**Command:**
```
rg 'Game\.placed_buildings|game\.get\("placed_buildings"\)|game\.set\("placed_buildings"|_game\.get\("placed_buildings"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| tests/helpers/gate_a_build_segment.gd | 6 | 91:var before_records := (_game.get("placed_buildings") as Array).size() | 184:var built_records := (_game.get("placed_buildings") as Array).size() - before_records | 687:var before := (_game.get("placed_buildings") as Array).size() |
| scripts/build/build_placer.gd | 6 | 435:var buildings: Array = WORLD_RECORDS.for_realm(game.get("placed_buildings"), WORLD_RECORDS | 486:var placed: Variant = game.get("placed_buildings") | 689:var index := int((game.get("placed_buildings") as Array).size()) |
| scripts/save/save_game.gd | 2 | 307:"placed_buildings": WORLD_RECORDS.normalized(game.get("placed_buildings")), | 365:game.set("placed_buildings", WORLD_RECORDS.normalized(data.get("placed_buildings", []))) |
| scripts/build/home_progress.gd | 2 | 136:var buildings: Array = game.get("placed_buildings") as Array | 191:var standing := creature_beds_built(game.get("placed_buildings") as Array) |
| tests/helpers/gate_b_tail_segment.gd | 1 | 413:var index := int((_game.get("placed_buildings") as Array).size()) |
| scripts/build/creature_bed.gd | 1 | 350:##   >= 0  a slot in `Game.placed_buildings` -- a bed the PLAYER placed. These |
| scripts/creatures/creature_instance.gd | 1 | 88:## Index into Game.placed_buildings for the creature_bed this instance occupies. |
| scripts/world/player_death.gd | 1 | 87:return resolve_home(game.get("placed_buildings"), fallback, realm) |

### Game.death_satchels

**Total: 5 matches**

**Command:**
```
rg 'Game\.death_satchels|game\.get\("death_satchels"\)|game\.set\("death_satchels"|_game\.get\("death_satchels"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/world/player_death.gd | 3 | 138:(game.get("death_satchels") as Array)[index]["state"] = satchel.get("state").call("save_da | 154:var satchels: Array = game.get("death_satchels") as Array | 185:var satchels: Array = game.get("death_satchels") as Array |
| scripts/save/save_game.gd | 2 | 309:"death_satchels": WORLD_RECORDS.normalized(game.get("death_satchels")), | 367:game.set("death_satchels", WORLD_RECORDS.normalized(data.get("death_satchels", []))) |

### Game.day

**Total: 20 matches**

**Command:**
```
rg 'Game\.day|game\.get\("day"\)|game\.set\("day"|_game\.get\("day"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/world/world_look.gd | 5 | 45:## time against `day_length_seconds`, but nothing ever told `Game.day` about | 146:## `_auto_day_accum` stops advancing (no automatic Game.day roll under a | 202:# OWNER-0901-DAYNIGHT-CYCLE: advance Game.day automatically as real time |
| tests/helpers/gate_b_tail_segment.gd | 3 | 458:var day_before := int(_game.get("day")) | 461:if int(_game.get("day")) != day_before + 1: | 463:% [day_before, int(_game.get("day"))]) |
| scripts/save/save_game.gd | 2 | 303:"day": int(game.get("day")), | 361:game.set("day", int(data.get("day", 1))) |
| scripts/world/cloudreach_resource_patch.gd | 2 | 68:if game != null and int(game.get("day")) != _day: | 79:_day = int(game.get("day")) |
| scripts/ui/playground_hud.gd | 2 | 3288:## `Game.day` and `WorldLook`'s own clock, it does not touch either. Naked | 3322:_daytime_label.text = daytime_readout_text(int(_game.get("day")), hour) |
| scripts/build/player_bed.gd | 1 | 11:## Resting fades the world out, advances `Game.day`, heals the party and the |
| scripts/ui/game_menu.gd | 1 | 543:_day.text = "Day %d" % int(game.get("day")) if game != null else "" |
| scripts/ui/swap_panel.gd | 1 | 147:return int(game.get("day")) if game != null else 1 |
| scripts/combat/encounter_director.gd | 1 | 2009:kept.set("caught_on_day", int(game.get("day"))) |
| scripts/world/farm_logic.gd | 1 | 27:## ## Why the clock is `Game.day` and not seconds |
| scripts/world/farm_plot.gd | 1 | 160:return int(game.get("day")) if game != null else 1 |

### Game.clock_elapsed_seconds

**Total: 6 matches**

**Command:**
```
rg 'Game\.clock_elapsed_seconds|game\.get\("clock_elapsed_seconds"\)|game\.set\("clock_elapsed_seconds"|_game\.get\("clock_elapsed_seconds"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 3 | 380:if game.get("clock_elapsed_seconds") != null: | 381:game.set("clock_elapsed_seconds", _finite_clock(data.get("clock_elapsed_seconds"))) | 460:return _finite_clock(game.get("clock_elapsed_seconds")) |
| scripts/world/world_look.gd | 3 | 428:var carried: Variant = game.get("clock_elapsed_seconds") | 434:if game != null and game.get("clock_elapsed_seconds") != null: | 435:game.set("clock_elapsed_seconds", seconds) |

### Game.current_realm

**Total: 10 matches**

**Command:**
```
rg 'Game\.current_realm|game\.get\("current_realm"\)|game\.set\("current_realm"|_game\.get\("current_realm"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 3 | 315:"current_realm": str(game.get("current_realm")) if game.get("current_realm") != null else  | 376:if game.get("current_realm") != null: | 377:game.set("current_realm", str(data.get("current_realm", "meadows"))) |
| scripts/player/fly_controller.gd | 1 | 90:return str(_game.get("current_realm")) if is_instance_valid(_game) else "" |
| scripts/world/cloudreach_world_payoffs.gd | 1 | 70:if str(game.get("current_realm")) != "cloudreach": |
| scripts/world/realm_chapter_events.gd | 1 | 45:return game != null and str(game.get("current_realm")) == realm_id |
| scripts/world/cloudreach_arrival_beats.gd | 1 | 40:if str(game.get("current_realm"))=="cloudreach": |
| scripts/world/realm_world_records.gd | 1 | 9:return str(game.get("current_realm")) |
| scripts/world/cloudreach_physical_runtime.gd | 1 | 85:return _game != null and str(_game.get("current_realm")) == "cloudreach" and _flags != nul |
| scripts/ui/tab_quest_log.gd | 1 | 108:var realm_changed := bool(_log.call("set_realm", str(game.get("current_realm")))) |

### Game.satiety

**Total: 2 matches**

**Command:**
```
rg 'Game\.satiety|game\.get\("satiety"\)|game\.set\("satiety"|_game\.get\("satiety"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 2 | 1008:var fallback: Variant = game.get("satiety") | 1018:game.set("satiety", value) |

### Game.player_equipment

**Total: 1 matches**

**Command:**
```
rg 'Game\.player_equipment|game\.get\("player_equipment"\)|game\.set\("player_equipment"|_game\.get\("player_equipment"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/player/player_controller.gd | 1 | 815:var equipment: Variant = game.get("player_equipment") |

### Game.realm_hearts

**Total: 11 matches**

**Command:**
```
rg 'Game\.realm_hearts|game\.get\("realm_hearts"\)|game\.set\("realm_hearts"|_game\.get\("realm_hearts"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/world/realm_heart_shrine.gd | 8 | 5:## State belongs to `Game.realm_hearts` and `Game.progression`, never to this | 12:##   Game.realm_hearts.is_earned(heart_id, Game.progression) -> bool | 13:##   Game.realm_hearts.is_placed(heart_id, Game.progression) -> bool |
| scripts/save/save_game.gd | 2 | 300:var realm_hearts_obj: Variant = game.get("realm_hearts") | 423:var realm_hearts_obj: Variant = game.get("realm_hearts") |
| scripts/player/player_controller.gd | 1 | 306:var hearts: Variant = game.get("realm_hearts") |

### Game.harvested_vegetation

**Total: 5 matches**

**Command:**
```
rg 'Game\.harvested_vegetation|game\.get\("harvested_vegetation"\)|game\.set\("harvested_vegetation"|_game\.get\("harvested_vegetation"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 2 | 317:"harvested_vegetation": (game.get("harvested_vegetation") as Dictionary).duplicate(true), | 370:game.set("harvested_vegetation", (harvested_raw as Dictionary).duplicate(true) if typeof(h |
| scripts/world/vegetation.gd | 2 | 1866:var saved: Variant = game.get("harvested_vegetation") | 1914:game.set("harvested_vegetation", out) |
| scripts/world/playground_world.gd | 1 | 1079:# this reconciles it against whatever `Game.harvested_vegetation` already |

### Game.felled_vegetation

**Total: 4 matches**

**Command:**
```
rg 'Game\.felled_vegetation|game\.get\("felled_vegetation"\)|game\.set\("felled_vegetation"|_game\.get\("felled_vegetation"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 2 | 319:"felled_vegetation": (game.get("felled_vegetation") as Dictionary).duplicate(true), | 372:game.set("felled_vegetation", (felled_raw as Dictionary).duplicate(true) if typeof(felled_ |
| scripts/world/vegetation.gd | 2 | 1876:var felled_saved: Variant = game.get("felled_vegetation") | 1915:game.set("felled_vegetation", _felled.duplicate(true)) |

### Game.world_seed

**Total: 4 matches**

**Command:**
```
rg 'Game\.world_seed|game\.get\("world_seed"\)|game\.set\("world_seed"|_game\.get\("world_seed"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 2 | 318:"world_seed": int(game.get("world_seed")) if game.get("world_seed") != null else 0, | 368:game.set("world_seed", int(data.get("world_seed", 0))) |
| scripts/combat/encounter_director.gd | 2 | 616:## `Game.world_seed` is save state (save_game.gd VERSION 15), so a loaded save | 629:var saved := int(game.get("world_seed")) if game != null and game.get("world_seed") != nul |

### Game.farm_plots

**Total: 2 matches**

**Command:**
```
rg 'Game\.farm_plots|game\.get\("farm_plots"\)|game\.set\("farm_plots"|_game\.get\("farm_plots"' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 2 | 308:"farm_plots": (game.get("farm_plots") as Array).duplicate(true), | 366:game.set("farm_plots", (data.get("farm_plots", []) as Array).duplicate(true)) |

### Game.<method>() calls

#### Game.save_game()

**Total: 2 matches**

| file | count | representative lines |
|---|---:|---|
| tools/gate_f/operator_harness.gd | 2 | 5311:## must not call `Game.save_game()` -- §7's whole point is that the operator | 5387:## `Game.save_game()` here would prove the serializer works and nothing about |

#### Game.load_game()

**Total: 1 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/world/realm_heart_shrine.gd | 1 | 99:## `Game.load_game()` calls this on every member of `progression_restore` after |

#### Game.enter_realm()

**Total: 1 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/world/realm_gate.gd | 1 | 10:## `Game.enter_realm(destination_realm, destination_entry_id)` owns scene |

#### Game.push_world_message()

**Total: 5 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/world/tournament.gd | 2 | 44:## `Game.push_world_message()` the instant a round's flag flips true. | 417:## message rather than two: `Game.push_world_message()` holds a single pending |
| scripts/combat/encounter_director.gd | 1 | 2374:## (`Game.push_world_message()`, polled by `playground_hud.gd`), because a |
| scripts/combat/combat_manager.gd | 1 | 723:## Answered through `Game.push_world_message()`, the one-shot toast |
| scripts/creatures/progression_feed.gd | 1 | 11:## log with a revision counter, exactly what `Game.push_world_message()` / |


## 2. Player lookups by node name

**Command:**
```
rg '\$Player|get_node\(["\']Player["\']\)|name\s*==\s*["\']Player["\']|"Player"|find_player|_find_player' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 47 matches**

| file | count | representative lines |
|---|---:|---|
| autoload/game_state.gd | 13 | 355:## OF26 debug scaffolding. The public door onto `_find_player()` above — | 360:func find_player() -> Node3D: | 361:return _find_player() |
| scripts/world/night_rest.gd | 6 | 31:## the world: `_find_player()` walks up. | 83:var player := _find_player(host) | 104:## `camp.gd` could read `get_parent().get_node_or_null(^"Player")` because a |
| scripts/player/tool_hold.gd | 3 | 319:var skeleton := _find_player_skeleton() | 334:## identical lookup `torch.gd::_find_player_skeleton()` does, and null for | 336:func _find_player_skeleton() -> Skeleton3D: |
| scenes/world/boot.tscn | 3 | 53:[node name="Player" type="CharacterBody3D" parent="."] | 56:[node name="Mesh" type="MeshInstance3D" parent="Player"] | 59:[node name="Collision" type="CollisionShape3D" parent="Player"] |
| scripts/debug/gate_f_probe.gd | 2 | 97:return w.get_node_or_null(^"Player") as Node3D | 97:return w.get_node_or_null(^"Player") as Node3D |
| scripts/save/save_game.gd | 2 | 511:if game.has_method("_find_player"): | 512:var player: Node = game.call("_find_player") |
| scripts/ui/tab_map.gd | 2 | 1135:## `smoke_menu.gd`'s own lookup (`world.get_node_or_null(^"Player")`). | 1142:return world.get_node_or_null(^"Player") as Node3D |
| scripts/build/player_bed.gd | 1 | 146:var player := world.get_node_or_null(^"Player") |
| scripts/audio/world_audio.gd | 1 | 37:const PLAYER_NAME := ^"Player" |
| scripts/ui/playground_hud.gd | 1 | 4473:var player := _game.call("find_player") as Node3D |
| scripts/ui/game_menu.gd | 1 | 108:## convention `game_state.gd::_find_player()` and `playground_hud.gd`'s own |
| scripts/ui/tab_backpack.gd | 1 | 2393:return world.get_node_or_null(^"Player") as Node3D |
| tests/helpers/gate_a_opening_drive.gd | 1 | 305:_player = _world.get_node_or_null(^"Player") as CharacterBody3D |
| scenes/player/player.tscn | 1 | 15:[node name="Player" type="CharacterBody3D"] |
| scenes/world/cloudreach_cliffs.tscn | 1 | 71:[node name="Player" parent="." instance=ExtResource("1_player")] |
| scenes/world/meadows_playground.tscn | 1 | 68:[node name="Player" parent="." instance=ExtResource("1_player")] |
| scripts/world/cloudreach_world_payoffs.gd | 1 | 47:player = world.get_node("Player") |
| scripts/world/cloudreach_chapter.gd | 1 | 65:_player = _world.get_node(^"Player") as CharacterBody3D |
| scripts/world/south_bridge.gd | 1 | 752:var player: Node3D = world.get_node_or_null(^"Player") as Node3D |
| scripts/world/severed_spokes.gd | 1 | 465:if not body is CharacterBody3D or body.name != "Player": |
| scripts/world/cloudreach_world_runtime.gd | 1 | 54:player = world.get_node("Player") |
| scripts/world/harvest_logic.gd | 1 | 100:var player := game.call("find_player") as Node3D |
| scripts/world/water.gd | 1 | 300:_player = sibling.get_node_or_null(^"Player") as CharacterBody3D |

## 3. Scene-tree pause

**Command (pause reads/writes):**
```
rg 'get_tree\(\)\.paused' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 20 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/ui/shop_panel.gd | 3 | 96:_paused_before = get_tree().paused | 97:get_tree().paused = true | 126:get_tree().paused = false |
| scripts/ui/storage_panel.gd | 3 | 61:_paused_before = get_tree().paused | 62:get_tree().paused = true | 87:get_tree().paused = false |
| scripts/ui/craft_panel.gd | 3 | 127:_paused_before = get_tree().paused | 128:get_tree().paused = true | 156:get_tree().paused = false |
| scripts/ui/creature_bed_panel.gd | 3 | 70:_paused_before = get_tree().paused | 71:get_tree().paused = true | 98:get_tree().paused = false |
| scripts/ui/game_menu.gd | 3 | 348:_paused_before = get_tree().paused | 349:get_tree().paused = true | 390:get_tree().paused = false |
| scripts/ui/swap_panel.gd | 3 | 89:_paused_before = get_tree().paused | 90:get_tree().paused = true | 120:get_tree().paused = false |
| scripts/ui/title_screen.gd | 1 | 143:get_tree().paused = false |
| scripts/ui/tab_build.gd | 1 | 106:get_tree().paused = false |

**Command (process_mode):**
```
rg 'process_mode\s*=|PROCESS_MODE_' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 16 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/ui/game_menu.gd | 2 | 311:## starter orbs: the picker kept drawing (it is not `PROCESS_MODE_ALWAYS`, so | 687:# tree, and a paused, non-`PROCESS_MODE_ALWAYS` build menu would never |
| autoload/game_state.gd | 2 | 545:## PROCESS_MODE_ALWAYS because opening it pauses the tree, and a paused menu | 553:_menu.process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/build/build_placer.gd | 1 | 231:# UI-PAD2: this node is `PROCESS_MODE_PAUSABLE` (the default), which stops |
| scripts/ui/shop_panel.gd | 1 | 104:process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/ui/title_screen.gd | 1 | 142:process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/ui/creature_bed_panel.gd | 1 | 78:process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/ui/swap_panel.gd | 1 | 97:process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/ui/storage_panel.gd | 1 | 69:process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/ui/input_owner.gd | 1 | 11:## `PROCESS_MODE_PAUSABLE`, so `_read_hotbar_input` does not run at all while it |
| scripts/ui/craft_panel.gd | 1 | 135:process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/world/world_look.gd | 1 | 70:process_mode = Node.PROCESS_MODE_ALWAYS |
| scripts/combat/encounter_director.gd | 1 | 1343:# is PROCESS_MODE_PAUSABLE like the rest of the world, so it has already |
| scripts/world/stronghold.gd | 1 | 4389:body.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT |
| scripts/world/burrow_warrens.gd | 1 | 3408:_vault_door.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHER |

## 4. Direct input polling

**Command:**
```
rg 'Input\.' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 239 matches**

| file | count | representative lines |
|---|---:|---|
| tools/gate_f/operator_harness.gd | 26 | 30:## **`Input.action_press` alone cannot move UI focus.** A Control's focus | 32:## the viewport; `Input.action_press` writes the action's polled state and | 33:## reaches `Input.is_action_pressed` only. The reverse is also true and is the |
| scripts/ui/playground_hud.gd | 16 | 3872:if Input.is_action_just_pressed(HOTBAR_ACTIONS[i]): | 4182:if Input.is_action_just_pressed(&"build_open"): | 4209:if Input.is_action_just_pressed(&"build_shortcut") and not _build_menu_is_open(): |
| tests/helpers/gate_a_build_segment.gd | 15 | 835:Input.action_press(&"look_right" if turn_right else &"look_left", 1.0) | 1060:Input.parse_input_event(press) | 1064:Input.parse_input_event(release) |
| tests/helpers/gate_b_tail_segment.gd | 14 | 826:Input.action_press("move_forward") | 828:Input.action_release("move_forward") | 834:Input.action_press("move_forward") |
| scripts/ui/game_menu.gd | 13 | 84:var _mouse_before: int = Input.MOUSE_MODE_VISIBLE | 346:_mouse_before = Input.mouse_mode | 347:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/boot/boot_probe.gd | 12 | 30:for device_id in Input.get_connected_joypads(): | 31:print("[boot] joypad %d: %s" % [device_id, Input.get_joy_name(device_id)]) | 32:if Input.get_connected_joypads().is_empty(): |
| scripts/build/build_placer.gd | 11 | 171:## `Input.is_action_just_pressed` is GLOBAL polling: it knows nothing about the | 243:_dismantle_pressed_last = Input.is_action_pressed(DISMANTLE_ACTION) | 252:if Input.is_action_just_pressed(PLACE_ACTION): |
| scripts/combat/combat_manager.gd | 9 | 735:var attacking := Input.is_action_just_pressed("combat_quick") \ | 736:or Input.is_action_just_pressed("combat_charged") | 972:var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") |
| scripts/ui/name_prompt.gd | 9 | 22:##     game that polls `Input.is_action_just_pressed()` still saw it — | 99:var _restore_mouse: int = Input.MOUSE_MODE_CAPTURED | 227:_restore_mouse = Input.mouse_mode |
| scripts/ui/tab_backpack.gd | 8 | 874:if _ignore_drop_until_release and not Input.is_action_pressed(DROP_ACTION): | 1220:if Input.is_action_just_pressed("menu_cancel"): | 1290:if not Input.is_action_just_pressed(USE_ACTION): |
| scripts/ui/build_menu.gd | 7 | 164:var _mouse_before: int = Input.MOUSE_MODE_VISIBLE | 198:_mouse_before = Input.mouse_mode | 199:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/ui/starter_picker.gd | 7 | 97:var _restore_mouse: int = Input.MOUSE_MODE_CAPTURED | 149:_restore_mouse = Input.mouse_mode | 150:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/ui/tab_creatures.gd | 6 | 1391:if not Input.is_action_just_pressed(ACTIVATE_ACTION): | 1419:if not Input.is_action_just_pressed(BEST_ACTION): | 1452:if not Input.is_action_just_pressed(RENAME_ACTION): |
| scripts/combat/throw_aim.gd | 5 | 270:if _guard <= 0.0 and (Input.is_action_just_pressed("combat_run") | 271:or Input.is_action_just_pressed("menu_cancel")): | 287:if Input.is_action_just_pressed("combat_throw") \ |
| scripts/ui/storage_panel.gd | 5 | 32:var _mouse_before: int = Input.MOUSE_MODE_VISIBLE | 59:_mouse_before = Input.mouse_mode | 60:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/ui/craft_panel.gd | 5 | 73:var _mouse_before: int = Input.MOUSE_MODE_VISIBLE | 125:_mouse_before = Input.mouse_mode | 126:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/ui/shop_panel.gd | 5 | 54:var _mouse_before: int = Input.MOUSE_MODE_VISIBLE | 94:_mouse_before = Input.mouse_mode | 95:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/ui/creature_bed_panel.gd | 5 | 40:var _mouse_before: int = Input.MOUSE_MODE_VISIBLE | 68:_mouse_before = Input.mouse_mode | 69:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/ui/swap_panel.gd | 5 | 49:var _mouse_before: int = Input.MOUSE_MODE_VISIBLE | 87:_mouse_before = Input.mouse_mode | 88:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE |
| scripts/player/fly_controller.gd | 4 | 148:if not input_owned and Input.is_action_just_pressed("jump") and not _player.is_on_floor(): | 161:var stick := Vector2.ZERO if input_owned else Input.get_vector("move_left", "move_right",  | 171:elif not input_owned and Input.is_action_pressed("fly_descend"): |
... (44 total files)


## 5. Camera assumptions

**Command:**
```
rg 'get_viewport\(\)\.get_camera_3d\(\)|\$CameraRig|camera_rig_path|set_camera\(|set_target\(' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 23 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/combat/orb.gd | 3 | 231:var camera := get_viewport().get_camera_3d() | 284:var camera := get_viewport().get_camera_3d() | 513:var camera := get_viewport().get_camera_3d() |
| scripts/debug/gate_f_probe.gd | 2 | 701:var camera := _tree.root.get_viewport().get_camera_3d() | 701:var camera := _tree.root.get_viewport().get_camera_3d() |
| autoload/game_state.gd | 2 | 1304:# GATE-F-LEG-S09. `camera_rig.gd::set_target()` only snaps its own | 1317:# is the same one-time snap `set_target()` already does for a target |
| scripts/build/build_placer.gd | 2 | 910:var camera := get_viewport().get_camera_3d() | 1164:var camera := get_viewport().get_camera_3d() |
| scripts/combat/impact_flash.gd | 2 | 188:var camera := get_viewport().get_camera_3d() | 212:var camera := get_viewport().get_camera_3d() |
| scripts/player/camera_rig.gd | 1 | 231:func set_target(target: Node3D, profile: Dictionary = {}) -> void: |
| scripts/vfx/level_up_flourish.gd | 1 | 140:var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null |
| scripts/vfx/vfx_burst.gd | 1 | 194:var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null |
| scripts/world/riding_controller.gd | 1 | 16:##   camera -> camera_rig.set_target(mount)               (the rig follows it) |
| scripts/world/shop_interior.gd | 1 | 27:## playthrough the fix is the same `set_target(target, profile)` seam that |
| scripts/world/grass_field.gd | 1 | 1669:var rendering := get_viewport().get_camera_3d() if get_viewport() != null else null |
| scripts/combat/throw_preview.gd | 1 | 323:var camera := get_viewport().get_camera_3d() |
| scripts/combat/target_marker.gd | 1 | 85:var camera := get_viewport().get_camera_3d() |
| scripts/world/grandpa_house.gd | 1 | 38:## on exit, through the same `set_target(target, profile)` seam the aim |
| scripts/creatures/vfx/aspect_vfx.gd | 1 | 201:var camera := get_viewport().get_camera_3d() |
| scripts/creatures/alpha_aura.gd | 1 | 103:var camera := get_viewport().get_camera_3d() |
| scripts/ui/combat_hud.gd | 1 | 870:var camera: Camera3D = get_viewport().get_camera_3d() |

## 6. Singleton lookups by group or path

**Command (groups):**
```
rg 'get_first_node_in_group\(|get_nodes_in_group\(|call_group\(' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 79 matches**

| file | count | representative lines |
|---|---:|---|
| autoload/game_state.gd | 9 | 1135:for node in tree.get_nodes_in_group("build_placer"): | 1151:for node in tree.get_nodes_in_group("player_death"): | 1165:for node in tree.get_nodes_in_group("harvest_state"): |
| tests/helpers/gate_a_build_segment.gd | 8 | 285:var placer := _tree.get_first_node_in_group(&"build_placer") | 540:var arbiter := _tree.get_first_node_in_group(&"interaction_arbiter") | 553:var arbiter := _tree.get_first_node_in_group(&"interaction_arbiter") |
| tests/helpers/gate_b_tail_segment.gd | 6 | 185:_arbiter = _tree.get_first_node_in_group(&"interaction_arbiter") | 234:var placer := _tree.get_first_node_in_group(&"build_placer") | 347:var placer := _tree.get_first_node_in_group(&"build_placer") |
| tests/helpers/gate_a_material_route.gd | 6 | 95:_arbiter = _tree.get_first_node_in_group(&"interaction_arbiter") | 219:var panel := _tree.get_first_node_in_group("dialogue_panel") | 478:for candidate: Node in _tree.get_nodes_in_group("harvestable"): |
| scripts/build/build_placer.gd | 4 | 451:for node: Node in get_tree().get_nodes_in_group(PLACED_GROUP): | 727:for node in get_tree().get_nodes_in_group(PLACED_GROUP): | 777:for node in get_tree().get_nodes_in_group(PLACED_GROUP): |
| scripts/ui/tab_backpack.gd | 3 | 1998:get_tree().call_group(&"companion_presence", "on_care", creature, "feed")  # W12-COMPANION | 2099:get_tree().call_group(&"companion_presence", "on_care", creature, "revive")  # W12-COMPANI | 2125:get_tree().call_group(&"companion_presence", "on_care", creature, "heal")  # W12-COMPANION |
| scripts/combat/encounter_director.gd | 3 | 1633:var look: Node = get_tree().get_first_node_in_group(&"day_cycle") | 1640:var weather: Node = get_tree().get_first_node_in_group(&"weather") | 2333:var panel := get_tree().get_first_node_in_group("dialogue_panel") |
| scripts/player/torch.gd | 2 | 131:_arbiter = get_tree().get_first_node_in_group(ARBITER_NODE.GROUP) | 226:_world_look = get_tree().get_first_node_in_group(&"day_cycle") |
| scripts/build/player_bed.gd | 2 | 84:for node: Node in get_tree().get_nodes_in_group(PLACED_GROUP): | 154:for look: Node in get_tree().get_nodes_in_group("day_cycle"): |
| tests/helpers/gate_a_npc_gather_segment.gd | 2 | 469:for node: Node in _tree.get_nodes_in_group("harvestable"): | 778:for node: Node in _tree.get_nodes_in_group(INPUT_OWNER.GROUP): |
| scripts/audio/world_audio.gd | 2 | 171:for node in get_tree().get_nodes_in_group(&"creature_voice"): | 222:for node in get_tree().get_nodes_in_group(&"creature_voice"): |
| scripts/ui/playground_hud.gd | 2 | 3239:for node: Node in get_tree().get_nodes_in_group(GAME_MENU_HUD.STORY_MODAL_GROUP): | 4355:for node: Node in get_tree().get_nodes_in_group(BUILD_MENU.GROUP): |
| scripts/ui/game_menu.gd | 2 | 488:for node in get_tree().get_nodes_in_group(STORY_MODAL_GROUP): | 692:var open_build_menu: Node = get_tree().get_first_node_in_group(&"build_menu") |
| scripts/world/grass_field.gd | 2 | 1873:for node: Node in get_tree().get_nodes_in_group(CLEAR_GROUP): | 1886:for node: Node in get_tree().get_nodes_in_group(PLACED_GROUP): |
| scripts/world/player_death.gd | 2 | 155:for node in get_tree().get_nodes_in_group(DEATH_SATCHEL.GROUP): | 179:for node in get_tree().get_nodes_in_group(DEATH_SATCHEL.GROUP): |
... (36 total files)

**Command (paths):**
```
rg 'get_node_or_null\(\s*"/root/Game|get_node_or_null\(\s*"CombatManager|...' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 2 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/ui/playground_hud.gd | 1 | 3114:var director := world.get_node_or_null("EncounterDirector") if world != null else null |
| scripts/world/stronghold.gd | 1 | 4308:# finds the fight through `get_parent().get_node_or_null("EncounterDirector")`, |

## 7. Process-global state (static vars)

**Command:**
```
rg 'static\s+var\s+' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 84 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/audio/audio_manager.gd | 14 | 44:static var _bus_cache: Dictionary = {} | 46:static var _config: Dictionary = {} | 47:static var _config_loaded: bool = false |
| scripts/creatures/creature_body.gd | 7 | 898:static var _night_floor_scale := 0.0 | 899:static var _night_floor_materials: Dictionary = {} | 988:static var _field_scale := 1.0 |
| scripts/world/grass_field.gd | 5 | 43:static var _config: Dictionary = {} | 1598:static var _terrain_cfg: Dictionary = {} | 1599:static var _terrain_cfg_read := false |
| scripts/creatures/progression_feed.gd | 5 | 39:static var _config: Dictionary = {} | 40:static var _events: Array = [] | 41:static var _seq: int = 0 |
| autoload/map_state.gd | 3 | 57:static var _grid_x := -1 | 58:static var _grid_z := -1 | 59:static var _origin := Vector2.ZERO |
| scripts/characters/character_model.gd | 3 | 44:static var _variant_materials: Dictionary = {} | 47:static var _solid_textures: Dictionary = {} | 72:static var _emission_floor_scale := 1.0 |
| scripts/boot/boot_log.gd | 3 | 21:static var _marked_launch := false | 25:static var _phase_started_ms: int = -1 | 52:static var _phases: Array = [] |
| scripts/vfx/combat_vfx.gd | 3 | 54:static var _config: Dictionary = {} | 57:static var _enabled_override: Variant = null | 61:static var _watcher: Node = null |
| scripts/ui/audio_cues.gd | 3 | 51:static var _player: AudioStreamPlayer = null | 52:static var _stream_cache: Dictionary = {} | 53:static var _last_played: Dictionary = {} |
| scripts/world/perf_trace.gd | 3 | 35:static var enabled: bool = false | 39:static var _costs: Dictionary = {} | 40:static var _last_seen: Dictionary = {} |
| scripts/story/party_seam.gd | 2 | 66:static var _fallback: Array[RefCounted] = [] | 82:static var _root_override: Node = null |
| scripts/creatures/creature_species.gd | 2 | 12:static var _table: Dictionary = {} | 13:static var _fly_capabilities: Dictionary = {} |
| scripts/world/scatter_rules.gd | 2 | 44:static var _config: Dictionary = {} | 968:static var _water_cache: Dictionary = {} |
| scripts/player/conversation_camera.gd | 1 | 417:static var _cached_config: Dictionary = {} |
| scripts/build/home_progress.gd | 1 | 35:static var _config: Dictionary = {} |
| scripts/build/build_door.gd | 1 | 181:static var _state_materials: Dictionary = {} |
| scripts/build/creature_bed.gd | 1 | 366:static var _panel: CanvasLayer = null |
| scripts/build/build_placer.gd | 1 | 201:static var _dismantle_material: StandardMaterial3D = null |
| scripts/build/build_piece.gd | 1 | 187:static var _state_materials: Dictionary = {} |
| scripts/build/storage_container.gd | 1 | 20:static var _panel: CanvasLayer = null |
... (42 total files)


## 8. Story-flag writers

**Command (set_flag):**
```
rg 'set_flag\(' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 17 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/world/stronghold_climax.gd | 5 | 742:_set_flag(_flag("legendary_freed")) | 922:_set_flag(_flag("legendary_joined")) | 941:_set_flag(_flag("legendary_joined")) |
| autoload/progression_state.gd | 4 | 23:## `set_flag()` call that redundantly sets an already-set flag or clears an | 33:## True once `set_flag(id)` has been called and not since cleared. | 45:## Sets or clears `id`. Defaults to setting (`set_flag("bridge_unlocked")` |
| scripts/world/realm_chapter_progression.gd | 4 | 34:_set_flag(progression, event.trim_prefix("count:"), result) | 76:if _set_flag(progression, reward, result): | 78:if _set_flag(progression, str(objective["flag_id"]), result): |
| scripts/world/tournament.gd | 1 | 544:## un-happened. `progression_state.set_flag()` is idempotent, so re-writing a |
| scripts/world/item_gate.gd | 1 | 69:progression.set_flag(flag_id) |
| scripts/world/burrow_warrens.gd | 1 | 3049:# two sets the flag first, the other's `set_flag()` call is a no-op. |
| scripts/combat/encounter_director.gd | 1 | 1244:## set_flag()` already gives every other caller in the game. |

**Command (flag checks: .has() / .completed()):**
```
rg '\.has\(|completed\(' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 505 matches**

| file | count | representative lines |
|---|---:|---|
| tools/gate_f/operator_harness.gd | 43 | 561:if raw.has(key): | 565:if parts.size() != 2 or not _cfg.has(parts[0]): | 1234:if lanes.has(_evidence_lane): |
| scripts/world/stronghold.gd | 34 | 278:if not _markers.has("entrance"): | 564:if _materials.has(key): | 640:if weathering.has(param): |
| scripts/world/burrow_warrens.gd | 31 | 307:if _materials.has(key): | 387:if site.has("apron_colour"): | 426:if _materials.has(key): |
| scripts/world/vegetation.gd | 28 | 339:if cfg.has("collision_stream_radius_m"): | 341:if cfg.has("collision_stream_cell_m"): | 453:if by_layer.has(layer_name): |
| scripts/world/world_look.gd | 20 | 92:_verify = OS.get_cmdline_args().has(VERIFY_FLAG) | 442:return float(over["hour"]) if over.has("hour") else 8.0 | 472:if not times.has(name): |
| scripts/combat/encounter_director.gd | 19 | 365:if not SPECIES.has(species): | 485:if not block.has("combat"): | 567:if spawn.has("wander_radius"): |
| autoload/map_state.gd | 17 | 284:if new_id.is_empty() or _discovered_regions.has(new_id): | 330:"discovered": _discovered_regions.has(id), | 422:"discovered": _discovered.has(id), |
| scripts/world/grass_field.gd | 16 | 540:if not per_tile.has(key): | 765:if tier.has("reach_m"): | 803:if tier.has(key): |
| scripts/world/cloudreach_physical_runtime.gd | 13 | 5:signal interaction_completed(id: String) | 105:if spec.has("approach_position") and RULES.holds(_flags, spec.get("requires_flags", [])) \ | 139:if _registered_flight_ids.has(str(entries[i].get("id", ""))): |
| scripts/world/band_pickups.gd | 11 | 318:if seen.has(id): | 330:"y": float(spec["y"]) if spec.has("y") else NAN, | 378:if spec.has("y") and not (spec["y"] is float or spec["y"] is int): |
| scripts/combat/cloudreach_encounter_director.gd | 11 | 198:if id.is_empty() or trainer_specs.has(id) or not trainer_specs.has(base_id): | 236:return trainer_specs.has(str(spec.get("id", ""))) \ | 265:if not trainer_specs.has(id): |
| scripts/ui/key_bindings.gd | 8 | 117:return _defaults.has(action) | 162:if not _current.has(action) or event == null: | 173:if not _defaults.has(action): |
| scripts/creatures/companion_presence.gd | 8 | 215:if not _pending.has(VICTORY): | 229:if not (_cfg.get(CARE, {}) as Dictionary).has(kind): | 232:if not _pending_care.has(kind): |
| scripts/world/build_playground_terrain.gd | 8 | 435:if ids.has("damp") and not is_nan(water_level): | 489:if ids.has("damp") and damp > 0.004 and damp > threshold * float(macro_cfg.get("damp_max", | 492:elif ids.has("soil"): |
| scripts/world/scatter_rules.gd | 7 | 114:if not layers.has(layer_name): | 801:if segments.has("reach_a"): | 807:if segments.has("outward_from"): |
| scripts/combat/spawn_tables.gd | 7 | 214:var too_many := caps.has(tier) and spent >= int(caps[tier]) | 239:if not spawn.has("alpha") and not spawn.has("elder"): | 270:if spawn.has("alpha") or spawn.has("elder"): |
| scripts/world/scatter_bake.gd | 7 | 327:if skip_layers.has(layer_name): | 331:if not by_layer.has(layer_name): | 337:if not drained_out.has(layer_name): |
| autoload/game_state.gd | 7 | 478:if OS.get_cmdline_args().has(DEMO_FLAG): | 803:if creature != null and (party == null or not (party.call("members") as Array).has(creatur | 880:CREATURE_CONDITION.note_rest_completed(creature, CREATURE_CONDITION.config()) |
| scripts/characters/character_model.gd | 6 | 492:if _variant_materials.has(key): | 505:if finish.has("metallic"): | 542:if finish.has("roughness"): |
| scripts/ui/playground_hud.gd | 6 | 2251:if buffs is Dictionary and (buffs as Dictionary).has("max_visible_icons"): | 3184:if not award.is_empty() and not used_awards.has(id): | 3195:if used_awards.has(id): |
... (110 total files)


## 9. World-record writers

### register_building / placed_buildings

**Command:**
```
rg 'register_building|placed_buildings' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 70 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/build/build_placer.gd | 17 | 74:## R3.1-remainder. This node's own index into `GameState.placed_buildings` — | 435:var buildings: Array = WORLD_RECORDS.for_realm(game.get("placed_buildings"), WORLD_RECORDS | 486:var placed: Variant = game.get("placed_buildings") |
| scripts/build/home_progress.gd | 11 | 13:## placed_buildings` -- so a save/load or an out-of-order build (structure | 62:## `GameState.placed_buildings` (the save-format registry every placed piece | 65:static func pieces_built(placed_buildings: Array) -> Dictionary: |
| autoload/game_state.gd | 9 | 213:var placed_buildings: Array = [] | 219:## `placed_buildings` draws above, and for a sharper reason: a crop is the | 292:## node, is what a save persists" split `placed_buildings` draws above. |
| tools/gate_f/operator_harness.gd | 8 | 5252:"placed_buildings": | 5258:return {"ok": false, "actual": "no live Game to read placed_buildings from"} | 5259:var raw: Variant = g.get("placed_buildings") |
| tests/helpers/gate_a_build_segment.gd | 7 | 9:## placed_buildings. Every change to play state comes from a physical joypad | 91:var before_records := (_game.get("placed_buildings") as Array).size() | 184:var built_records := (_game.get("placed_buildings") as Array).size() - before_records |
| scripts/save/save_game.gd | 6 | 222:## `inventory`, `placed_buildings`, `map` and `satiety` as properties (plus, | 307:"placed_buildings": WORLD_RECORDS.normalized(game.get("placed_buildings")), | 365:game.set("placed_buildings", WORLD_RECORDS.normalized(data.get("placed_buildings", []))) |
| tests/helpers/gate_b_tail_segment.gd | 5 | 229:## `register_building` bookkeeping a real placement performs, read back by | 243:_game.call("register_building", id, Vector3( | 393:## function's caller stays true) and `register_building` (so a save written |
| scripts/world/player_death.gd | 2 | 28:## building's index into `placed_buildings`. | 87:return resolve_home(game.get("placed_buildings"), fallback, realm) |
| scripts/build/camp_tent.gd | 1 | 110:## placed tent's own world position and yaw (`placed_buildings`' own |
| scripts/build/player_bed.gd | 1 | 79:## position. Reads the live scene tree rather than `GameState.placed_buildings` |
| scripts/build/creature_bed.gd | 1 | 350:##   >= 0  a slot in `Game.placed_buildings` -- a bed the PLAYER placed. These |
| scripts/world/farm_logic.gd | 1 | 23:## writes to disk, and R3.1's `placed_buildings` already set the rule that |
| scripts/creatures/creature_instance.gd | 1 | 88:## Index into Game.placed_buildings for the creature_bed this instance occupies. |

### register_death_satchel / death_satchels

**Command:**
```
rg 'register_death_satchel|death_satchels' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 19 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/world/player_death.gd | 7 | 26:## Which entry in `GameState.death_satchels` a given live satchel node is — | 124:# its own index into `GameState.death_satchels` from the moment it | 127:var index := int(game.call("register_death_satchel", at)) |
| scripts/save/save_game.gd | 6 | 45:## `GameState.death_satchels` did not exist before this either, so the same | 309:"death_satchels": WORLD_RECORDS.normalized(game.get("death_satchels")), | 367:game.set("death_satchels", WORLD_RECORDS.normalized(data.get("death_satchels", []))) |
| autoload/game_state.gd | 6 | 301:var death_satchels: Array = [] | 308:## `death_satchels` draw above. `vegetation.gd::sync_state_to_game` fills it | 525:death_satchels = [] |

### harvested_vegetation

**Command:**
```
rg 'harvested_vegetation' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 12 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 5 | 106:## `game_state.gd::harvested_vegetation` did not exist before this. Same | 317:"harvested_vegetation": (game.get("harvested_vegetation") as Dictionary).duplicate(true), | 369:var harvested_raw: Variant = data.get("harvested_vegetation", {}) |
| autoload/game_state.gd | 4 | 314:var harvested_vegetation: Dictionary = {} | 334:## [x,y,z]}}`. A tree/rock present in `harvested_vegetation` but ABSENT here | 339:## write, the same split `harvested_vegetation` above uses. Joined the save |
| scripts/world/vegetation.gd | 2 | 1866:var saved: Variant = game.get("harvested_vegetation") | 1914:game.set("harvested_vegetation", out) |
| scripts/world/playground_world.gd | 1 | 1079:# this reconciles it against whatever `Game.harvested_vegetation` already |

### felled_vegetation

**Command:**
```
rg 'felled_vegetation' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 9 matches**

| file | count | representative lines |
|---|---:|---|
| scripts/save/save_game.gd | 5 | 114:## `game_state.gd::felled_vegetation` did not exist before this. A VERSION 10 | 319:"felled_vegetation": (game.get("felled_vegetation") as Dictionary).duplicate(true), | 371:var felled_raw: Variant = data.get("felled_vegetation", {}) |
| autoload/game_state.gd | 2 | 342:var felled_vegetation: Dictionary = {} | 527:felled_vegetation = {} |
| scripts/world/vegetation.gd | 2 | 1876:var felled_saved: Variant = game.get("felled_vegetation") | 1915:game.set("felled_vegetation", _felled.duplicate(true)) |

### farm_plots

**Command:**
```
rg 'farm_plots' \\
  --no-heading -n -g'!tests/smoke_*.gd' -g'!tests/test_*.gd' -g'!archive' -g'!addons' \\
  scripts autoload scenes tests/helpers tools/gate_f/operator_harness.gd scripts/debug/gate_f_probe.gd
```

**Total: 18 matches**

| file | count | representative lines |
|---|---:|---|
| autoload/game_state.gd | 8 | 237:var farm_plots: Array = [] | 522:farm_plots = [] | 587:## Grows `farm_plots` on demand rather than requiring anyone to size it up |
| scripts/save/save_game.gd | 4 | 90:## `game_state.gd::farm_plots` did not exist before this, so `_migrate_v8` | 308:"farm_plots": (game.get("farm_plots") as Array).duplicate(true), | 366:game.set("farm_plots", (data.get("farm_plots", []) as Array).duplicate(true)) |
| scripts/world/playground_world.gd | 3 | 1271:_place_farm_plots() | 1670:## its saved state is stored under (`game_state.gd::farm_plots`). | 1671:func _place_farm_plots() -> void: |
| scripts/world/farm_plot.gd | 2 | 38:## bush -- and why the state has to be saved (`game_state.gd::farm_plots`) | 88:## Which entry of `game_state.gd::farm_plots` this bed is. Assigned by |
| scripts/world/farm_logic.gd | 1 | 22:## `autoload/game_state.gd::farm_plots` saves and `scripts/save/save_game.gd` |

## 10. Summary: Per-file totals (top 40 files)

Collision list files (marked with ★) are defined as: `game_state.gd`, `save_game.gd`,`combat_manager.gd`, `encounter_director.gd`, `playground_world.gd`, `cloudreach_world.gd`,`playground_hud.gd`, `sequence_director.gd`.

| file | count | collision list |
|---|---:|---|
| tools/gate_f/operator_harness.gd | 79 |  |
| scripts/save/save_game.gd | 72 | ★ |
| autoload/game_state.gd | 64 | ★ |
| scripts/ui/playground_hud.gd | 52 | ★ |
| scripts/build/build_placer.gd | 51 |  |
| tests/helpers/gate_b_tail_segment.gd | 48 |  |
| tests/helpers/gate_a_build_segment.gd | 48 |  |
| scripts/combat/encounter_director.gd | 46 | ★ |
| scripts/world/burrow_warrens.gd | 37 |  |
| scripts/world/stronghold.gd | 37 |  |
| scripts/world/vegetation.gd | 36 |  |
| scripts/world/world_look.gd | 29 |  |
| scripts/world/grass_field.gd | 24 |  |
| tests/helpers/gate_a_npc_gather_segment.gd | 23 |  |
| scripts/ui/game_menu.gd | 23 |  |
| scripts/ui/tab_backpack.gd | 22 |  |
| scripts/world/cloudreach_physical_runtime.gd | 20 |  |
| autoload/map_state.gd | 20 |  |
| tests/helpers/gate_a_material_route.gd | 19 |  |
| scripts/story/sequence_director.gd | 18 | ★ |
| scripts/build/home_progress.gd | 18 |  |
| scripts/world/player_death.gd | 18 |  |
| scripts/audio/audio_manager.gd | 17 |  |
| scripts/world/realm_heart_shrine.gd | 15 |  |
| scripts/combat/combat_manager.gd | 15 | ★ |
| scripts/world/playground_world.gd | 15 | ★ |
| scripts/ui/tab_creatures.gd | 14 |  |
| scripts/ui/swap_panel.gd | 14 |  |
| scripts/world/stronghold_climax.gd | 14 |  |
| scripts/ui/build_menu.gd | 14 |  |
| scripts/creatures/companion_presence.gd | 13 |  |
| scripts/boot/boot_probe.gd | 12 |  |
| scripts/creatures/creature_body.gd | 12 |  |
| scripts/ui/creature_bed_panel.gd | 11 |  |
| scripts/world/band_pickups.gd | 11 |  |
| scripts/combat/cloudreach_encounter_director.gd | 11 |  |
| scripts/vfx/combat_vfx.gd | 10 |  |
| scripts/ui/shop_panel.gd | 10 |  |
| scripts/ui/storage_panel.gd | 10 |  |
| scripts/ui/craft_panel.gd | 10 |  |

## Notes

1. `static var` matches (section 7) include all declarations, not just state variables.2. `.has()` / `.completed()` matches (section 8b) are broad and include dictionary method callsthat may not be flag checks. Manual review required for scope classification.3. The `Input.*` pattern (section 4) captures all Input class usage, including constantsand method references. Not all are direct input polling.4. Some regex patterns may have false positives (e.g., comments, strings), but therepresentative lines in each table can be used to verify actual usage.

### 8b. `call("set_flag", …)` writers — orchestrator addendum

The `set_flag\(` regex above misses the dynamic-call form most world scripts use. Command:

```
rg -n 'call\("set_flag"' scripts autoload
```

Total: 38 matches.

| file | line | as written |
|---|---|---|
| scripts/save/save_game.gd | 449 | `progression.call("set_flag", "realm_key_cloudreach")` |
| scripts/save/save_game.gd | 450 | `progression.call("set_flag", "realm_heart_meadows_earned")` |
| autoload/realm_heart_state.gd | 60 | `progression.call("set_flag", flag)` |
| scripts/story/sequence_director.gd | 432 | `progression.call("set_flag", flag_id)` |
| scripts/story/sequence_director.gd | 665 | `progression.call("set_flag", flag_id)` |
| scripts/build/home_progress.gd | 138 | `progression.call("set_flag", "home_built")` |
| scripts/build/home_progress.gd | 193 | `progression.call("set_flag", CREATURE_BED_FLAGS[i])` |
| scripts/build/home_progress.gd | 208 | `progression.call("set_flag", "home_materials_gathered")` |
| scripts/build/creature_bed.gd | 409 | `progression.call("set_flag", CREATURE_BED_FLAG)` |
| scripts/build/player_bed.gd | 139 | `progression.call("set_flag", "player_slept_at_home")` |
| scripts/combat/encounter_director.gd | 1250 | `progression.call("set_flag", id)` |
| scripts/combat/encounter_director.gd | 2358 | `progression.call("set_flag", flag)` |
| scripts/combat/encounter_director.gd | 2364 | `progression.call("set_flag", extra)` |
| scripts/ui/swap_panel.gd | 451 | `progression.call("set_flag",` |
| scripts/world/meadow_healing.gd | 441 | `_progression.call("set_flag", flag)` |
| scripts/world/tm_pickup.gd | 298 | `progression.call("set_flag", FLAG_PREFIX + _tm_id)` |
| scripts/world/night_rest.gd | 77 | `progression.call("set_flag", "player_slept_at_home")` |
| scripts/world/item_cache_pickup.gd | 178 | `progression.call("set_flag", flag_id(_item_id, _placement_id, _realm_id))` |
| scripts/world/tether_relay.gd | 909 | `progression.call("set_flag", console_flag())` |
| scripts/world/realm_chapter_progression.gd | 85 | `progression.call("set_flag", flag)` |
| scripts/world/cloudreach_finale_controller.gd | 244 | `_progression.call("set_flag", str(relay["flag_id"]))` |
| scripts/world/river_nest_clear.gd | 88 | `progression.call("set_flag", MET_FLAG)` |
| scripts/world/realm_gate.gd | 108 | `progression.call("set_flag", unlock_flag)` |
| scripts/world/harvest_node.gd | 431 | `progression.call("set_flag", flag_id(_node_id))` |
| scripts/world/key_pickup.gd | 244 | `progression.call("set_flag", flag_id(_item_id))` |
| scripts/world/tournament.gd | 550 | `progression.call("set_flag", "tournament_team_ready")` |
| scripts/world/tournament.gd | 552 | `progression.call("set_flag", "tournament_training_ready")` |
| scripts/world/tournament.gd | 559 | `progression.call("set_flag", "tournament_condition_ready", condition_ready(party))` |
| scripts/world/tournament.gd | 572 | `progression.call("set_flag", "tournament_team_fed", team_fed(party))` |
| scripts/world/cloudreach_physical_runtime.gd | 199 | `_flags.call("set_flag", flag)` |
| scripts/world/cloudreach_physical_runtime.gd | 316 | `_flags.call("set_flag", defeat_flag)` |
| scripts/world/cloudreach_physical_runtime.gd | 319 | `_flags.call("set_flag", payout_flag)` |
| scripts/world/burrow_warrens.gd | 2943 | `progression.call("set_flag", str(prize.get("flag", "")))` |
| scripts/world/burrow_warrens.gd | 3345 | `progression.call("set_flag", _clear_flag())` |
| scripts/world/riding_controller.gd | 635 | `store.call("set_flag", saddle_fitted_flag(species_id))` |
| scripts/world/alpha_pins.gd | 232 | `progression.call("set_flag", INTRO_FLAG)` |
| scripts/world/cart_repair.gd | 100 | `progression.call("set_flag", MET_FLAG)` |
| scripts/world/stronghold_climax.gd | 1036 | `progression.call("set_flag", flag)` |

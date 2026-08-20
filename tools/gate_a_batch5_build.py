#!/usr/bin/env python3
"""Gate A batch 5: structural floor/wall/door/roof snapping and safe dismantle."""
from pathlib import Path


def rep(root: Path, rel: str, old: str, new: str) -> bool:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if new in text:
        return False
    n = text.count(old)
    if n != 1:
        raise RuntimeError(f"{rel}: batch5 expected one anchor, got {n}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"batch5 patched {rel}")
    return True


def apply(root: Path) -> bool:
    changed = False

    # Stable save identity + refund ledger. removed=true is a tombstone: never
    # delete array entries because creature-bed assignments use these indices.
    changed |= rep(
        root, "autoload/game_state.gd",
        '''func register_building(id: String, position: Vector3, yaw_deg: float = 0.0) -> void:\n\tplaced_buildings.append({\n\t\t"id": id,\n\t\t"position": [position.x, position.y, position.z],\n\t\t"yaw_deg": yaw_deg,\n\t})''',
        '''func register_building(id: String, position: Vector3, yaw_deg: float = 0.0, refund_cost: Array = []) -> void:\n\tplaced_buildings.append({\n\t\t"id": id,\n\t\t"position": [position.x, position.y, position.z],\n\t\t"yaw_deg": yaw_deg,\n\t\t"refund_cost": refund_cost.duplicate(true),\n\t\t"removed": false,\n\t})\n\n\n## Mark a player-built record removed without shifting any later indices. Returns\n## its recorded actual paid cost (empty for historical/free-build pieces).\nfunc tombstone_building(index: int) -> Array:\n\tif index < 0 or index >= placed_buildings.size():\n\t\treturn []\n\tvar entry: Dictionary = placed_buildings[index]\n\tif bool(entry.get("removed", false)):\n\t\treturn []\n\tentry["removed"] = true\n\tplaced_buildings[index] = entry\n\tvar raw: Variant = entry.get("refund_cost", [])\n\treturn (raw as Array).duplicate(true) if raw is Array else []''',
    )

    # Placer dependencies / dismantle action.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''const BUILD_GRID := preload("res://scripts/build/build_grid.gd")\nconst INTERACTABLE''',
        '''const BUILD_GRID := preload("res://scripts/build/build_grid.gd")\nconst BUILD_SNAP := preload("res://scripts/build/build_snap_contract.gd")\nconst INVENTORY := preload("res://autoload/inventory.gd")\nconst INTERACTABLE''',
    )
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''const PLACE_ACTION := "build_place"\nconst CANCEL_ACTION := "build_cancel"''',
        '''const PLACE_ACTION := "build_place"\nconst CANCEL_ACTION := "build_cancel"\nconst DISMANTLE_ACTION := "build_dismantle"''',
    )

    # Dismantle input while a build piece is armed; target nearest player-built
    # piece to the ghost, not arbitrary authored scenery.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\tif Input.is_action_just_pressed(CANCEL_ACTION):\n\t\tgame.set("pending_build", "")\n\t\t_drop_ghost()\n\t\treturn\n\n\tif Input.is_action_just_pressed(ROTATE_ACTION):''',
        '''\tif Input.is_action_just_pressed(CANCEL_ACTION):\n\t\tgame.set("pending_build", "")\n\t\t_drop_ghost()\n\t\treturn\n\n\tif Input.is_action_just_pressed(DISMANTLE_ACTION):\n\t\t_dismantle_nearest(game)\n\t\treturn\n\n\tif Input.is_action_just_pressed(ROTATE_ACTION):''',
    )

    # Replace center-only same-id resolution with explicit structural anchors.
    old_resolve = '''\tvar resolved := BUILD_GRID.resolve_position(raw_spot, ground, _neighbour_positions(armed))\n\tvar spot: Vector3 = resolved.position\n\tvar snapped_to_neighbour: bool = resolved.snapped_to_neighbour'''
    new_resolve = '''\tvar resolved := BUILD_SNAP.resolve(raw_spot, ground, armed, game.get("placed_buildings") as Array)\n\tvar spot: Vector3 = resolved.position\n\tvar snapped_to_neighbour: bool = bool(resolved.snapped_to_neighbour)\n\tif bool(resolved.get("structural", false)):\n\t\t_yaw_deg = float(resolved.get("yaw_deg", _yaw_deg))'''
    changed |= rep(root, "scripts/build/build_placer.gd", old_resolve, new_resolve)

    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\tvar occupied := _cell_occupied(armed, spot)''',
        '''\tvar occupied := BUILD_SNAP.occupied(armed, spot, game.get("placed_buildings") as Array)''',
    )

    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\t_snap_candidates = BUILD_GRID.neighbours_in_range(raw_spot, _neighbour_positions(armed))\n\t_update_overlay(spot)''',
        '''\tvar structural_candidates := BUILD_SNAP.candidate_positions(armed, game.get("placed_buildings") as Array)\n\t_snap_candidates = BUILD_GRID.neighbours_in_range(raw_spot, structural_candidates)\n\tif _snap_candidates.is_empty():\n\t\t_snap_candidates = BUILD_GRID.neighbours_in_range(raw_spot, _neighbour_positions(armed))\n\t_update_overlay(spot)''',
    )

    # Same-id helper ignores tombstones.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\tfor node: Node in get_tree().get_nodes_in_group(PLACED_GROUP):\n\t\tif node == _ghost:\n\t\t\tcontinue\n\t\tif str(node.get_meta(BUILDING_ID_META, "")) == armed:''',
        '''\tfor node: Node in get_tree().get_nodes_in_group(PLACED_GROUP):\n\t\tif node == _ghost:\n\t\t\tcontinue\n\t\tvar index := int(node.get_meta(PLACED_INDEX_META, -1))\n\t\tvar game := _game()\n\t\tif game != null and index >= 0 and index < (game.get("placed_buildings") as Array).size():\n\t\t\tif bool((game.get("placed_buildings") as Array)[index].get("removed", false)):\n\t\t\t\tcontinue\n\t\tif str(node.get_meta(BUILDING_ID_META, "")) == armed:''',
    )

    # Paid cost is captured before spending; free build naturally records [] and
    # therefore cannot become a resource-printing dismantle exploit.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\tvar inventory: RefCounted = game.get("inventory")\n\tfor requirement: Variant in (game.call("build_cost_for", armed) as Array):''',
        '''\tvar inventory: RefCounted = game.get("inventory")\n\tvar paid_cost: Array = (game.call("build_cost_for", armed) as Array).duplicate(true)\n\tfor requirement: Variant in paid_cost:''',
    )
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\tgame.call("register_building", armed, placed.global_position, yaw_deg)''',
        '''\tgame.call("register_building", armed, placed.global_position, yaw_deg, paid_cost)''',
    )

    # Skip removed records on restore, preserving their index positions.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\t\tvar entry: Dictionary = placed_buildings[index]\n\t\tvar id := str(entry.get("id", ""))''',
        '''\t\tvar entry: Dictionary = placed_buildings[index]\n\t\tif bool(entry.get("removed", false)):\n\t\t\tcontinue\n\t\tvar id := str(entry.get("id", ""))''',
    )

    # Hint advertises the new verb.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''\tvar controls := "%s Rotate    %s Snap step    %s Place    %s Cancel" % [\n\t\t"%s/%s" % [INPUT_GLYPH.icon(ROTATE_LEFT_ACTION, 28), INPUT_GLYPH.icon(ROTATE_RIGHT_ACTION, 28)],\n\t\tINPUT_GLYPH.icon(SNAP_CYCLE_ACTION, 28),\n\t\tINPUT_GLYPH.icon(PLACE_ACTION, 28),\n\t\tINPUT_GLYPH.icon(CANCEL_ACTION, 28),\n\t]''',
        '''\tvar controls := "%s Rotate    %s Snap step    %s Place    %s Dismantle    %s Cancel" % [\n\t\t"%s/%s" % [INPUT_GLYPH.icon(ROTATE_LEFT_ACTION, 28), INPUT_GLYPH.icon(ROTATE_RIGHT_ACTION, 28)],\n\t\tINPUT_GLYPH.icon(SNAP_CYCLE_ACTION, 28),\n\t\tINPUT_GLYPH.icon(PLACE_ACTION, 28),\n\t\tINPUT_GLYPH.icon(DISMANTLE_ACTION, 28),\n\t\tINPUT_GLYPH.icon(CANCEL_ACTION, 28),\n\t]''',
    )

    # Add dismantle implementation before crafting-panel section.
    changed |= rep(
        root, "scripts/build/build_placer.gd",
        '''## The workbench's half of R2.4's "at the campfire or workbench". One panel''',
        '''## Gate A dismantle: target the nearest player-built node to the current\n## ghost/aim point. Stateful pieces refuse when removing them would destroy\n## unresolved state (occupied creature bed or nonempty storage). Refund capacity\n## is simulated first so dismantle is atomic: structure + full refund, or neither.\nfunc _dismantle_nearest(game: Node) -> bool:\n\tif game == null or _ghost == null or not is_instance_valid(_ghost):\n\t\treturn false\n\tvar target: Node3D = null\n\tvar best := 3.2\n\tfor node: Node in get_tree().get_nodes_in_group(PLACED_GROUP):\n\t\tif not (node is Node3D) or node == _ghost:\n\t\t\tcontinue\n\t\tvar d := (node as Node3D).global_position.distance_to(_ghost.global_position)\n\t\tif d < best:\n\t\t\tbest = d\n\t\t\ttarget = node as Node3D\n\tif target == null:\n\t\tgame.call("push_world_message", "Aim at a structure you built")\n\t\tAUDIO_CUES.play(&"ui_error")\n\t\treturn false\n\n\tvar index := int(target.get_meta(PLACED_INDEX_META, -1))\n\tif index < 0 or index >= (game.get("placed_buildings") as Array).size():\n\t\treturn false\n\tvar id := str(target.get_meta(BUILDING_ID_META, ""))\n\tif id == "creature_bed" and target.has_method("is_occupied") and bool(target.call("is_occupied")):\n\t\tgame.call("push_world_message", "Wake the resting Pal before dismantling this bed")\n\t\tAUDIO_CUES.play(&"ui_error")\n\t\treturn false\n\tif id == "storage":\n\t\tvar state: RefCounted = target.get("state")\n\t\tif state != null:\n\t\t\tfor stack: Variant in (state.call("save_data") as Array):\n\t\t\t\tif stack != null:\n\t\t\t\t\tgame.call("push_world_message", "Empty storage before dismantling it")\n\t\t\t\t\tAUDIO_CUES.play(&"ui_error")\n\t\t\t\t\treturn false\n\n\tvar record: Dictionary = (game.get("placed_buildings") as Array)[index]\n\tvar raw_cost: Variant = record.get("refund_cost", [])\n\tvar refund: Array = raw_cost as Array if raw_cost is Array else []\n\tvar inventory: RefCounted = game.get("inventory")\n\tif inventory == null or not _refund_fits(inventory, game.get("items"), refund):\n\t\tgame.call("push_world_message", "Make room in your satchel for the full refund")\n\t\tAUDIO_CUES.play(&"ui_error")\n\t\treturn false\n\n\tfor raw_need: Variant in refund:\n\t\tvar need: Dictionary = raw_need\n\t\tinventory.call("add", str(need.get("id", "")), int(need.get("n", 0)))\n\tgame.call("tombstone_building", index)\n\ttarget.queue_free()\n\tgame.call("push_world_message", "Dismantled %s — full materials refunded" % id.capitalize())\n\tAUDIO_CUES.play(&"build_place")\n\treturn true\n\n\nfunc _refund_fits(inventory: RefCounted, db: RefCounted, refund: Array) -> bool:\n\tif inventory == null or db == null:\n\t\treturn refund.is_empty()\n\tvar trial: RefCounted = INVENTORY.new(db)\n\tfor slot in inventory.call("slot_count"):\n\t\ttrial.call("set_slot", slot, inventory.call("stack_at", slot))\n\tfor raw_need: Variant in refund:\n\t\tvar need: Dictionary = raw_need\n\t\tif int(trial.call("add", str(need.get("id", "")), int(need.get("n", 0)))) > 0:\n\t\t\treturn false\n\treturn true\n\n\n## The workbench's half of R2.4's "at the campfire or workbench". One panel''',
    )

    # InputMap: keyboard X / gamepad Y, build-context only.
    project = root / "project.godot"
    text = project.read_text(encoding="utf-8")
    if "build_dismantle={" not in text:
        anchor = '''build_cancel={\n"deadzone": 0.5,\n"events": [Object(InputEventMouseButton,"device":-1,"button_index":2,"pressed":false,"script":null)\n, Object(InputEventJoypadButton,"device":-1,"button_index":1,"pressed":false,"script":null)\n]\n}\n'''
        addition = anchor + '''build_dismantle={\n"deadzone": 0.5,\n"events": [Object(InputEventKey,"device":-1,"physical_keycode":88,"pressed":false,"script":null)\n, Object(InputEventJoypadButton,"device":-1,"button_index":3,"pressed":false,"script":null)\n]\n}\n'''
        if anchor not in text:
            raise RuntimeError("project.godot dismantle anchor missing")
        project.write_text(text.replace(anchor, addition, 1), encoding="utf-8")
        changed = True

    # Dynamic glyph + Settings label/group.
    changed |= rep(
        root, "scripts/ui/input_glyph.gd",
        '''\t"build_cancel": {"keyboard": "mouse_right.png", "gamepad": "xbox_button_b.png"},''',
        '''\t"build_cancel": {"keyboard": "mouse_right.png", "gamepad": "xbox_button_b.png"},\n\t"build_dismantle": {"gamepad": "xbox_button_y.png"},''',
    )
    changed |= rep(
        root, "data/config/menu.json",
        '''          "actions": ["build_place", "build_cancel", "build_rotate_left", "build_rotate_right", "build_snap_cycle"]''',
        '''          "actions": ["build_place", "build_cancel", "build_dismantle", "build_rotate_left", "build_rotate_right", "build_snap_cycle"]''',
    )
    changed |= rep(
        root, "data/config/menu.json",
        '''        "build_rotate": "Rotate the build ghost",''',
        '''        "build_rotate": "Rotate the build ghost",\n        "build_dismantle": "Dismantle targeted structure (full refund)",''',
    )

    # Y normally opens inventory; while a build ghost is active, Build owns Y.
    changed |= rep(
        root, "scripts/ui/game_menu.gd",
        '''\tif not _open:\n\t\t# OF23: `menu_cancel` and `build_cancel` share gamepad B''',
        '''\tif not _open:\n\t\tvar live_game := get_node_or_null(^"/root/Game")\n\t\tif live_game != null and not str(live_game.get("pending_build")).is_empty() \\\n\t\t\t\tand Input.is_action_just_pressed("build_dismantle"):\n\t\t\treturn\n\t\t# OF23: `menu_cancel` and `build_cancel` share gamepad B''',
    )

    return changed

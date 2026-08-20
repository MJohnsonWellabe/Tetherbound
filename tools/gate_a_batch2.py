#!/usr/bin/env python3
"""Gate A batch 2: persistence, party cycling, gathering feedback, torch/tool feel.

Applied by tools/gate_a_apply.py on the integrated branch. Every edit is anchored
against inspected current source and is idempotent.
"""
from pathlib import Path


def _replace_once(root: Path, rel: str, old: str, new: str) -> bool:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if new in text:
        return False
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{rel}: expected exactly one batch2 anchor, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"batch2 patched {rel}")
    return True


def apply(root: Path) -> bool:
    changed = False

    # --- RG7: persist the real player pose, not merely progression data. ---
    changed |= _replace_once(
        root,
        "autoload/game_state.gd",
        'var felled_vegetation: Dictionary = {}\n\n## R3.1. Save/load logic',
        '''var felled_vegetation: Dictionary = {}\n\n## RG7. The last captured player/world pose. Transform data stays OUT of the\n## ordinary long-lived gameplay state; this dictionary is only the save/load\n## seam so a slot can return the trainer to the exact place and view it wrote.\n## Shape: {position:[x,y,z], model_yaw, camera_yaw, camera_pitch}.\nvar saved_player_pose: Dictionary = {}\n\n## R3.1. Save/load logic''',
    )

    changed |= _replace_once(
        root,
        "autoload/game_state.gd",
        '''func save_game(slot: int) -> bool:\n\t_sync_placed_building_state()\n\t_sync_death_satchel_state()\n\t_sync_harvest_state()\n\treturn bool(save_system.call("save", self, slot))''',
        '''func save_game(slot: int) -> bool:\n\t_capture_player_pose()\n\t_sync_placed_building_state()\n\t_sync_death_satchel_state()\n\t_sync_harvest_state()\n\treturn bool(save_system.call("save", self, slot))''',
    )

    changed |= _replace_once(
        root,
        "autoload/game_state.gd",
        '''\tfor node in get_tree().get_nodes_in_group("harvest_state"):\n\t\tif node.has_method("restore_from_game"):\n\t\t\tnode.call("restore_from_game", self)\n\treturn true\n\n\n## The slot `camp.gd` writes to on every rest.''',
        '''\tfor node in get_tree().get_nodes_in_group("harvest_state"):\n\t\tif node.has_method("restore_from_game"):\n\t\t\tnode.call("restore_from_game", self)\n\t# Mid-session loads can apply immediately. A title-screen load has no Player\n\t# yet; player_controller.gd calls apply_loaded_player_pose() from _ready(), so\n\t# the same saved dictionary is applied once the world exists.\n\tapply_loaded_player_pose()\n\treturn true\n\n\n## RG7. Capture exact trainer position/facing and camera view before each save.\nfunc _capture_player_pose() -> void:\n\tvar player := _find_player()\n\tif player == null:\n\t\treturn\n\tvar model := player.get_node_or_null(^"Model") as Node3D\n\tvar rig: Node = null\n\tvar scene := get_tree().get_current_scene()\n\tif scene != null:\n\t\trig = scene.get_node_or_null(^"CameraRig")\n\tvar facing := model.global_rotation.y if model != null else player.global_rotation.y\n\tsaved_player_pose = {\n\t\t"position": [player.global_position.x, player.global_position.y, player.global_position.z],\n\t\t"model_yaw": facing,\n\t\t"camera_yaw": float(rig.get("yaw")) if rig != null else facing,\n\t\t"camera_pitch": float(rig.get("pitch")) if rig != null else 0.0,\n\t}\n\n\n## Apply a loaded pose if both the data and Player exist. False is the normal\n## pre-world/title-screen case, not an error; Player._ready retries it.\nfunc apply_loaded_player_pose() -> bool:\n\tif saved_player_pose.is_empty():\n\t\treturn false\n\tvar player := _find_player()\n\tif player == null:\n\t\treturn false\n\tvar raw: Variant = saved_player_pose.get("position", [])\n\tif raw is Array and (raw as Array).size() >= 3:\n\t\tplayer.global_position = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))\n\t\tif player is CharacterBody3D:\n\t\t\t(player as CharacterBody3D).velocity = Vector3.ZERO\n\tvar model := player.get_node_or_null(^"Model") as Node3D\n\tif model != null:\n\t\tmodel.global_rotation.y = float(saved_player_pose.get("model_yaw", model.global_rotation.y))\n\tvar scene := get_tree().get_current_scene()\n\tvar rig: Node3D = scene.get_node_or_null(^"CameraRig") as Node3D if scene != null else null\n\tif rig != null:\n\t\tvar yaw := float(saved_player_pose.get("camera_yaw", rig.get("yaw")))\n\t\tvar pitch := float(saved_player_pose.get("camera_pitch", rig.get("pitch")))\n\t\trig.set("yaw", yaw)\n\t\trig.set("pitch", pitch)\n\t\trig.rotation = Vector3(pitch, yaw, 0.0)\n\treturn true\n\n\n## The slot `camp.gd` writes to on every rest.''',
    )

    changed |= _replace_once(
        root,
        "scripts/player/player_controller.gd",
        '''\ttool_hold = TOOL_HOLD.new()\n\ttool_hold.name = "ToolHold"\n\tadd_child(tool_hold)''',
        '''\ttool_hold = TOOL_HOLD.new()\n\ttool_hold.name = "ToolHold"\n\tadd_child(tool_hold)\n\tif tool_hold.has_signal("swing_started"):\n\t\ttool_hold.connect("swing_started", _on_tool_swing_started)\n\n\t# RG7: if a slot was loaded before this scene existed (title -> Load), Game\n\t# retained the pose and can finally apply it now that Player/CameraRig exist.\n\tvar game := get_node_or_null(^"/root/Game")\n\tif game != null and game.has_method("apply_loaded_player_pose"):\n\t\tgame.call_deferred("apply_loaded_player_pose")''',
    )

    # Save format 12: player pose + resting flag. Old slots migrate safely.
    changed |= _replace_once(root, "scripts/save/save_game.gd", "const VERSION := 11", "const VERSION := 12")
    changed |= _replace_once(
        root,
        "scripts/save/save_game.gd",
        '''\t\t"felled_vegetation": (game.get("felled_vegetation") as Dictionary).duplicate(true),\n\t}''',
        '''\t\t"felled_vegetation": (game.get("felled_vegetation") as Dictionary).duplicate(true),\n\t\t"player_pose": (game.get("saved_player_pose") as Dictionary).duplicate(true)\n\t\t\tif typeof(game.get("saved_player_pose")) == TYPE_DICTIONARY else {},\n\t}''',
    )
    changed |= _replace_once(
        root,
        "scripts/save/save_game.gd",
        '''\tvar felled_raw: Variant = data.get("felled_vegetation", {})\n\tgame.set("felled_vegetation", (felled_raw as Dictionary).duplicate(true) if typeof(felled_raw) == TYPE_DICTIONARY else {})\n\t_write_satiety(game, float(data.get("satiety", _default_satiety())))''',
        '''\tvar felled_raw: Variant = data.get("felled_vegetation", {})\n\tgame.set("felled_vegetation", (felled_raw as Dictionary).duplicate(true) if typeof(felled_raw) == TYPE_DICTIONARY else {})\n\tif game.get("saved_player_pose") != null:\n\t\tvar pose_raw: Variant = data.get("player_pose", {})\n\t\tgame.set("saved_player_pose", (pose_raw as Dictionary).duplicate(true) if typeof(pose_raw) == TYPE_DICTIONARY else {})\n\t_write_satiety(game, float(data.get("satiety", _default_satiety())))''',
    )
    changed |= _replace_once(
        root,
        "scripts/save/save_game.gd",
        '''func _migrate_v10(data: Dictionary) -> Dictionary:\n\tvar migrated := data.duplicate(true)\n\tmigrated["version"] = 11\n\tmigrated["felled_vegetation"] = {}\n\treturn migrated\n\n\nfunc _species_moves''',
        '''func _migrate_v10(data: Dictionary) -> Dictionary:\n\tvar migrated := data.duplicate(true)\n\tmigrated["version"] = 11\n\tmigrated["felled_vegetation"] = {}\n\treturn migrated\n\n\n## VERSION 11 -> 12: exact player pose and creature-bed resting state. A v11\n## slot has neither; no pose means use the scene's authored spawn, and every\n## creature starts available rather than being stranded in a bed that was not\n## persisted by that format.\nfunc _migrate_v11(data: Dictionary) -> Dictionary:\n\tvar migrated := data.duplicate(true)\n\tmigrated["version"] = 12\n\tmigrated["player_pose"] = {}\n\tvar party: Array = migrated.get("party", [])\n\tfor raw: Variant in party:\n\t\tif typeof(raw) == TYPE_DICTIONARY:\n\t\t\t(raw as Dictionary)["resting"] = false\n\tmigrated["party"] = party\n\treturn migrated\n\n\nfunc _species_moves''',
    )
    changed |= _replace_once(
        root,
        "scripts/save/save_game.gd",
        '''\t\t\t"fainted": bool(instance.get("fainted")),\n\t\t\t"level": int(instance.get("level")),''',
        '''\t\t\t"fainted": bool(instance.get("fainted")),\n\t\t\t"resting": bool(instance.get("resting")),\n\t\t\t"level": int(instance.get("level")),''',
    )
    changed |= _replace_once(
        root,
        "scripts/save/save_game.gd",
        '''\t\tcreature.fainted = bool(d.get("fainted", false))\n\t\tcreature.level = int(d.get("level", 1))''',
        '''\t\tcreature.fainted = bool(d.get("fainted", false))\n\t\tcreature.resting = bool(d.get("resting", false))\n\t\tcreature.level = int(d.get("level", 1))''',
    )

    changed |= _replace_once(
        root,
        "scripts/creatures/creature_instance.gd",
        '''var fainted: bool = false\n\n## --- progression (D30)''',
        '''var fainted: bool = false\n\n## Gate A creature-bed contract. While true this party member physically belongs\n## to a bed and cannot be selected/summoned for combat or exploration. The bed\n## system owns when the flag is set/cleared; party.gd only respects it.\nvar resting: bool = false\n\n## --- progression (D30)''',
    )

    # --- Party cycle: reuse combat shoulder grammar outside combat. ---
    changed |= _replace_once(
        root,
        "autoload/party.gd",
        '''func set_active(index: int) -> bool:\n\tvar creature: RefCounted = at(index)\n\tif creature == null:\n\t\treturn false\n\tif bool(creature.get("fainted")):\n\t\treturn false\n\t_active = index\n\trevision += 1\n\treturn true''',
        '''func set_active(index: int) -> bool:\n\tvar creature: RefCounted = at(index)\n\tif creature == null:\n\t\treturn false\n\tif bool(creature.get("fainted")) or bool(creature.get("resting")):\n\t\treturn false\n\t_active = index\n\trevision += 1\n\treturn true\n\n\n## Gate A / owner: one-second previous/next party selection in exploration.\n## Direction is -1 or +1; wraps and skips anything that cannot take the field.\nfunc cycle_active(direction: int) -> bool:\n\tif _creatures.is_empty() or direction == 0:\n\t\treturn false\n\tvar step := -1 if direction < 0 else 1\n\tfor offset in range(1, _creatures.size() + 1):\n\t\tvar index := posmod(_active + step * offset, _creatures.size())\n\t\tvar creature: RefCounted = at(index)\n\t\tif creature == null:\n\t\t\tcontinue\n\t\tif bool(creature.get("fainted")) or bool(creature.get("resting")):\n\t\t\tcontinue\n\t\tif index == _active:\n\t\t\treturn false\n\t\t_active = index\n\t\trevision += 1\n\t\treturn true\n\treturn false''',
    )

    changed |= _replace_once(
        root,
        "scripts/combat/encounter_director.gd",
        '''\tif _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled")):\n\t\treturn\n\tif not Input.is_action_just_pressed("creature_recall"):\n\t\treturn\n\tif _ally_body != null and is_instance_valid(_ally_body):''',
        '''\tif _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled")):\n\t\treturn\n\n\t# PARTY-CYCLE: the same shoulder/d-pad grammar used to switch in combat now\n\t# changes the selected companion in exploration. Party.revision drives the\n\t# existing _sync_active_creature() path, so a visible follower is recalled\n\t# and replaced cleanly rather than a second body being spawned.\n\tvar cycle := 0\n\tif Input.is_action_just_pressed("combat_switch_left"):\n\t\tcycle = -1\n\telif Input.is_action_just_pressed("combat_switch_right"):\n\t\tcycle = 1\n\tif cycle != 0:\n\t\tvar party := _party()\n\t\tvar game := get_node_or_null(^"/root/Game")\n\t\tif party != null and bool(party.call("cycle_active", cycle)):\n\t\t\tvar active: RefCounted = party.call("active")\n\t\t\tif game != null and active != null:\n\t\t\t\tgame.call("push_world_message", "Active Pal: %s" % str(active.call("label")))\n\t\telif game != null:\n\t\t\tgame.call("push_world_message", "No other available Pal")\n\t\treturn\n\n\tif not Input.is_action_just_pressed("creature_recall"):\n\t\treturn\n\tif _ally_body != null and is_instance_valid(_ally_body):''',
    )

    # Party strip communicates bed availability too.
    changed |= _replace_once(
        root,
        "scripts/ui/playground_hud.gd",
        '''\t\t\t"fainted": bool(creature.get("fainted")),\n\t\t})''',
        '''\t\t\t"fainted": bool(creature.get("fainted")),\n\t\t\t"resting": bool(creature.get("resting")),\n\t\t})''',
    )

    # --- Gathering/tool feel. ---
    changed |= _replace_once(
        root,
        "scripts/world/felled_resource.gd",
        '''\tinventory.call("add", _item_id, _amount)\n\n\tvar vegetation := get_parent()''',
        '''\tinventory.call("add", _item_id, _amount)\n\t# Owner feedback: the pickup must visibly say what entered the satchel. Use\n\t# Game's existing one-shot world-message seam so gathering does not reach\n\t# into a HUD node directly.\n\tvar items: RefCounted = game.get("items")\n\tvar item_name := str(items.call("item_name", _item_id)) if items != null else _item_id.capitalize()\n\tgame.call("push_world_message", "+%d %s" % [_amount, item_name])\n\n\tvar vegetation := get_parent()''',
    )

    changed |= _replace_once(
        root,
        "scripts/player/trainer_model.gd",
        '''var _throwing_for: float = 0.0\n## movement.json's `gait_feel` block''',
        '''var _throwing_for: float = 0.0\n## Gate A gathering: a held axe/pick/knife must visibly move when used. The\n## current trainer asset has no dedicated chop clip; its authored throw one-shot\n## is the closest real arm/torso motion and, with the tool bone-attached, reads\n## as a swing instead of an invisible arithmetic event. A future authored swing\n## clip can replace the fallback without changing this contract.\nvar _tool_swing_for: float = 0.0\n## movement.json's `gait_feel` block''',
    )
    changed |= _replace_once(
        root,
        "scripts/player/trainer_model.gd",
        '''\t_throwing_for = maxf(0.0, _throwing_for - delta)\n\t# OF8's other exit from the bed:''',
        '''\t_throwing_for = maxf(0.0, _throwing_for - delta)\n\t_tool_swing_for = maxf(0.0, _tool_swing_for - delta)\n\t# OF8's other exit from the bed:''',
    )
    changed |= _replace_once(
        root,
        "scripts/player/trainer_model.gd",
        '''func _role_for_state() -> String:\n\tif _throwing_for > 0.0:\n\t\treturn "throw"''',
        '''func _role_for_state() -> String:\n\tif _throwing_for > 0.0 or _tool_swing_for > 0.0:\n\t\treturn "throw"''',
    )
    changed |= _replace_once(
        root,
        "scripts/player/trainer_model.gd",
        '''func play_throw(seconds: float = 0.6) -> void:\n\t_throwing_for = seconds''',
        '''func play_throw(seconds: float = 0.6) -> void:\n\t_throwing_for = seconds\n\n\nfunc play_tool_swing(seconds: float = 0.45) -> void:\n\t_tool_swing_for = maxf(_tool_swing_for, seconds)''',
    )
    changed |= _replace_once(
        root,
        "scripts/player/player_controller.gd",
        '''func _resolve_landing(falling_speed: float) -> void:''',
        '''func _on_tool_swing_started() -> void:\n\tif _model != null and _model.has_method("play_tool_swing"):\n\t\t_model.call("play_tool_swing", 0.45)\n\n\nfunc _resolve_landing(falling_speed: float) -> void:''',
    )

    # Torch local +Y is its shaft/flame axis. Keep it close to upright at the
    # generic hand socket instead of rolling it almost horizontal (-65 deg).
    changed |= _replace_once(
        root,
        "data/items/items.json",
        '''      "held_rotation_deg": [\n        0.0,\n        15.0,\n        -65.0\n      ]''',
        '''      "held_rotation_deg": [\n        0.0,\n        8.0,\n        -8.0\n      ]''',
    )

    # --- Unit regressions. ---
    changed |= _replace_once(
        root,
        "tests/test_save_format.gd",
        '''\tvar felled_vegetation: Dictionary = {}\n\tvar map: RefCounted = null''',
        '''\tvar felled_vegetation: Dictionary = {}\n\tvar saved_player_pose: Dictionary = {}\n\tvar map: RefCounted = null''',
    )
    changed |= _replace_once(
        root,
        "tests/test_save_format.gd",
        '''func test_save_then_load_round_trips_the_day_counter() -> void:\n''',
        '''func test_save_then_load_round_trips_player_pose() -> void:\n\tvar written := _game()\n\twritten.saved_player_pose = {\n\t\t"position": [123.25, 7.5, -88.0],\n\t\t"model_yaw": 1.25,\n\t\t"camera_yaw": -0.75,\n\t\t"camera_pitch": -0.2,\n\t}\n\tassert_true(saver.save(written, 1))\n\tvar read := _game(false)\n\tassert_true(saver.load_slot(read, 1))\n\tassert_eq(read.saved_player_pose.get("position"), [123.25, 7.5, -88.0])\n\tassert_almost_eq(float(read.saved_player_pose.get("model_yaw")), 1.25)\n\tassert_almost_eq(float(read.saved_player_pose.get("camera_yaw")), -0.75)\n\tassert_almost_eq(float(read.saved_player_pose.get("camera_pitch")), -0.2)\n\n\nfunc test_save_then_load_round_trips_the_day_counter() -> void:\n''',
    )

    changed |= _replace_once(
        root,
        "tests/test_party.gd",
        '''func test_a_fainted_creature_refuses_to_take_the_field() -> void:\n''',
        '''func test_cycle_active_wraps_both_directions_and_skips_unavailable() -> void:\n\t_fill(5)\n\tassert_true(party.cycle_active(1))\n\tassert_eq(party.active_index(), 1)\n\tparty.at(2).resting = true\n\tparty.at(3).take_damage(party.at(3).max_hp)\n\tassert_true(party.cycle_active(1))\n\tassert_eq(party.active_index(), 4, "resting and fainted slots must be skipped")\n\tassert_true(party.cycle_active(1))\n\tassert_eq(party.active_index(), 0, "forward cycle wraps")\n\tassert_true(party.cycle_active(-1))\n\tassert_eq(party.active_index(), 4, "reverse cycle wraps")\n\n\nfunc test_resting_creature_refuses_to_take_the_field() -> void:\n\t_fill(2)\n\tparty.at(1).resting = true\n\tassert_false(party.set_active(1))\n\tassert_ne(party.active_index(), 1)\n\n\nfunc test_a_fainted_creature_refuses_to_take_the_field() -> void:\n''',
    )

    return changed

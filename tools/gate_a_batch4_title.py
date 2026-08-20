#!/usr/bin/env python3
"""Gate A batch 4: lightweight title/front door and clean session transitions."""
from pathlib import Path


def rep(root: Path, rel: str, old: str, new: str) -> bool:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if new in text:
        return False
    n = text.count(old)
    if n != 1:
        raise RuntimeError(f"{rel}: batch4 expected one anchor, got {n}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"batch4 patched {rel}")
    return True


def apply(root: Path) -> bool:
    changed = False

    changed |= rep(
        root, "project.godot",
        'run/main_scene="res://scenes/world/meadows_playground.tscn"',
        'run/main_scene="res://scenes/ui/title_screen.tscn"',
    )

    # One reset path for Start New Game and Return to Title. It clears every
    # runtime-owned gameplay state but deliberately leaves save files and player
    # preferences alone.
    changed |= rep(
        root, "autoload/game_state.gd",
        '''func menu() -> CanvasLayer:\n\treturn _menu\n\n\n## Read by `input_glyph.gd`''',
        '''func menu() -> CanvasLayer:\n\treturn _menu\n\n\n## Gate A session boundary. Recreate long-lived gameplay state exactly the same\n## way boot does, while preserving settings/free-build/debug preferences and\n## save files. Title->New and world->Title both use this so Save A cannot leak\n## transient nodes/state into a later Save B.\nfunc reset_for_new_game() -> void:\n\titems = ITEM_DB.new()\n\tinventory = INVENTORY.new(items)\n\tparty = PARTY.new()\n\tplayer_equipment = PLAYER_EQUIPMENT.new()\n\tplayer_equipment.call("configure", items)\n\tmap = MAP_STATE.new()\n\tmap.configure(_map_landmarks_config())\n\tprogression = PROGRESSION_STATE.new()\n\tquest_log = QUEST_LOG.new()\n\tobjective_text = quest_log.call("tracked_text", progression)\n\t_last_progression_revision = int(progression.get("revision"))\n\tday = 1\n\tpending_build = ""\n\tpending_catch = null\n\tplaced_buildings.clear()\n\tfarm_plots.clear()\n\tdeath_satchels.clear()\n\tharvested_vegetation.clear()\n\tfelled_vegetation.clear()\n\tif get("saved_player_pose") != null:\n\t\tsaved_player_pose = {}\n\thotbar = ["", "", "", "", ""]\n\tequipped_tool = ""\n\tsatiety = 100.0\n\t_pending_world_message = ""\n\t_autosave_elapsed = 0.0\n\t_discovery_elapsed = 0.0\n\n\n## Read by `input_glyph.gd`''',
    )

    # The autoload pause shell exists on title too, but must not steal B/Start
    # from the front-door UI or appear over it.
    changed |= rep(
        root, "scripts/ui/game_menu.gd",
        '''func _read_actions() -> void:\n\tif _tabs.is_empty() or _deaf:\n\t\treturn''',
        '''func _read_actions() -> void:\n\tvar scene := get_tree().get_current_scene()\n\tif scene != null and scene.is_in_group(&"title_screen"):\n\t\treturn\n\tif _tabs.is_empty() or _deaf:\n\t\treturn''',
    )

    # Save tab becomes the in-world session exit surface, controller-accessible
    # like the existing save/load buttons. Save first so Return/Quit are safe.
    changed |= rep(
        root, "scripts/ui/tab_save.gd",
        '''\tfor i in SLOT_COUNT:\n\t\tvar row := HBoxContainer.new()''',
        '''\tfor i in SLOT_COUNT:\n\t\tvar row := HBoxContainer.new()''',
    )  # idempotence marker only; structural insert below

    insert = '''\t\tlist.add_child(_panel(row, 12))\n\t\t_rows.append({"save": save_button, "load": load_button})\n\n\tpoll()'''
    replacement = '''\t\tlist.add_child(_panel(row, 12))\n\t\t_rows.append({"save": save_button, "load": load_button})\n\n\tvar session_rule := HSeparator.new()\n\tlist.add_child(session_rule)\n\tvar session_row := HBoxContainer.new()\n\tsession_row.add_theme_constant_override("separation", 16)\n\tvar return_button := Button.new()\n\treturn_button.text = "Save & Return to Title"\n\treturn_button.custom_minimum_size = Vector2(300, 56)\n\treturn_button.focus_mode = Control.FOCUS_ALL\n\treturn_button.pressed.connect(_on_return_title)\n\tsession_row.add_child(return_button)\n\tvar quit_button := Button.new()\n\tquit_button.text = "Save & Quit Game"\n\tquit_button.custom_minimum_size = Vector2(260, 56)\n\tquit_button.focus_mode = Control.FOCUS_ALL\n\tquit_button.pressed.connect(_on_quit_game)\n\tsession_row.add_child(quit_button)\n\tlist.add_child(_panel(session_row, 12))\n\n\tpoll()'''
    changed |= rep(root, "scripts/ui/tab_save.gd", insert, replacement)

    changed |= rep(
        root, "scripts/ui/tab_save.gd",
        '''func _on_load(slot: int) -> void:\n\tvar game := state()''',
        '''func _on_return_title() -> void:\n\tvar game := state()\n\tif game == null:\n\t\treturn\n\tif not bool(game.call("save_game", int(game.call("autosave_slot")))):\n\t\tsay("Could not autosave; staying in the Meadows.")\n\t\treturn\n\tmenu.call("close")\n\tgame.call("reset_for_new_game")\n\tget_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")\n\n\nfunc _on_quit_game() -> void:\n\tvar game := state()\n\tif game != null and not bool(game.call("save_game", int(game.call("autosave_slot")))):\n\t\tsay("Could not autosave; quit cancelled.")\n\t\treturn\n\tget_tree().quit()\n\n\nfunc _on_load(slot: int) -> void:\n\tvar game := state()''',
    )

    return changed

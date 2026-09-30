extends "res://tests/helpers/net_harness.gd"
func _initialize() -> void:
    _run_probe()
func _run_probe() -> void:
    await process_frame
    _run_dir = "D:/tetherbound/foundations-coordinator-probe"
    _isolate_coordinator()
    var game := root.get_node("Game")
    if bool(game.call("world_save_owned")):
        push_error("Coordinator ownership was reclaimed")
        quit(1)
        return
    game.call("_tick_autosave", 181.0)
    var slot: String = game.save_system.slot_path(0)
    if FileAccess.file_exists(slot):
        push_error("Unused coordinator wrote an owned-world save")
        quit(1)
        return
    print("Coordinator readiness before isolation: world_save_owned=false; fallback refuses unused world; no save file")
    quit(0)
extends SceneTree
func _initialize() -> void:
    await process_frame
    var game := root.get_node("Game")
    var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_system.slot_path(0)))
    if not game.save_system.load_slot(game, 0):
        push_error("Production saved carrier load refused")
        quit(1)
        return
    var actual_world: Dictionary = game.world.redesign_world
    var actual_personal: Dictionary = game.local.redesign_character
    var preserved := JSON.stringify(actual_world) == JSON.stringify(raw.redesign_world) and JSON.stringify(actual_personal) == JSON.stringify(raw.redesign_character)
    var numeric_fixture: Dictionary = actual_personal.duplicate(true)
    numeric_fixture.pouch_tier = int(numeric_fixture.pouch_tier)
    var uid: String = numeric_fixture.creatures.keys()[0]
    numeric_fixture.creatures[uid].cap_level = int(numeric_fixture.creatures[uid].cap_level)
    var json_equal: bool = JSON.parse_string(JSON.stringify(numeric_fixture)) == JSON.parse_string(JSON.stringify(actual_personal))
    print("Production-load full carrier preserved=", preserved, "; numeric representation Variant equal=", numeric_fixture == actual_personal, "; canonical JSON equal=", json_equal)
    print("Personal: ", JSON.stringify(actual_personal))
    print("World: ", JSON.stringify(actual_world))
    quit(0 if preserved and json_equal else 1)
extends SceneTree
func _init() -> void:
    var valid := ClassDB.class_exists("Terrain3D") and ClassDB.class_exists("Terrain3DMaterial")
    var queue := int(ProjectSettings.get_setting("network/limits/debugger/max_queued_messages", 2048))
    var route: Resource = load("res://tools/capture_lookdev_route.gd")
    valid = valid and queue == 16384 and route != null and route.can_instantiate()
    print("D_NATIVE_PREFLIGHT ", JSON.stringify({"terrain3d": ClassDB.class_exists("Terrain3D"), "terrain_material": ClassDB.class_exists("Terrain3DMaterial"), "debugger_queue": queue, "route_compiles": route != null and route.can_instantiate(), "complete": valid}))
    quit(0 if valid else 1)
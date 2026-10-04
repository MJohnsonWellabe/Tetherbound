extends "res://tests/test_case.gd"

## F26: the draw-distance preset (Low 320 m .. High 900 m) must never cut a
## realm's gameplay camera below the far plane its scene authors. Each realm
## declares that floor in its own visual config; graphics_prefs keeps it.

const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const REALMS := {
	"meadows": {"scene": "res://scenes/world/meadows_playground.tscn",
		"config": "res://data/config/meadows_horizon.json", "key": ["camera_vista_far_floor_m"]},
	"water": {"scene": "res://scenes/world/water_archipelago.tscn",
		"config": "res://data/config/water_visual.json", "key": ["view", "camera_far_m"]},
	"cloudreach": {"scene": "res://scenes/world/cloudreach_cliffs.tscn",
		"config": "res://data/config/cloudreach_visual.json", "key": ["camera", "vista_far_floor_m"]},
	"stormwood": {"scene": "res://scenes/world/stormwood.tscn",
		"config": "res://data/config/stormwood_camera.json", "key": ["vista_far_floor_m"]},
}
var _saved := {}


func before_each() -> void:
	GRAPHICS.load_preferences()
	_saved = {"choice": GRAPHICS._choice, "base": GRAPHICS._base, "custom": GRAPHICS._custom}


func after_each() -> void:
	GRAPHICS._choice = _saved.choice
	GRAPHICS._base = _saved.base
	GRAPHICS._custom = _saved.custom


func _authored_far(scene_path: String) -> float:
	# Instantiated but never added to the tree: no _ready, no world build.
	var world := (load(scene_path) as PackedScene).instantiate()
	var camera := world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var far := camera.far if camera != null else -1.0
	world.free()
	return far


func _declared_floor(realm: Dictionary) -> float:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(realm.config)))
	for key: String in realm.key:
		value = (value as Dictionary).get(key, null) if value is Dictionary else null
	return float(value) if value != null else -1.0


func test_every_realm_declares_its_authored_far_as_the_floor() -> void:
	for id: String in REALMS:
		var authored := _authored_far(str(REALMS[id].scene))
		assert_true(authored > 1000.0, "%s scene authors a gameplay camera far plane" % id)
		assert_almost_eq(_declared_floor(REALMS[id]), authored, 0.01,
			"%s config floor matches its scene's authored far" % id)


func test_no_preset_cuts_a_realm_camera_below_its_floor() -> void:
	for id: String in REALMS:
		var floor_m := _declared_floor(REALMS[id])
		for preset: String in GRAPHICS.PRESETS:
			GRAPHICS._choice = preset
			GRAPHICS._base = preset
			var camera := Camera3D.new()
			camera.far = floor_m
			camera.set_meta(&"vista_far_floor_m", floor_m)
			GRAPHICS.apply_camera(camera)
			assert_true(camera.far >= floor_m, "%s on %s keeps far %.0f >= %.0f" % [id, preset, camera.far, floor_m])
			camera.free()


func test_a_camera_without_a_floor_still_takes_the_preset() -> void:
	GRAPHICS._choice = "Low"
	GRAPHICS._base = "Low"
	var camera := Camera3D.new()
	camera.far = 4000.0
	GRAPHICS.apply_camera(camera)
	var near: Dictionary = GRAPHICS._config.get("draw_distance_options", {}).get("Near", {})
	assert_almost_eq(camera.far, float(near.get("far", 0.0)), 0.01, "undeclared cameras keep preset draw distance")
	camera.free()

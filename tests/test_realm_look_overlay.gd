extends "res://tests/test_case.gd"

## MEADOWS-VISUAL-PASS round 5: a realm's own look is deep-merged over the
## shared art.json presets (world_look.gd::merged_look), so a Meadows-only
## value never leaks into another chapter's sky.

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const MEADOWS_LOOK := preload("res://scripts/world/meadows_look.gd")
const MEADOWS_FINISH := preload("res://scripts/world/meadows_surface_finish.gd")


func test_the_overlay_merges_key_by_key_and_leaves_both_inputs_alone() -> void:
	var base := {"environment": {"fog_colour": "#a6bccb", "exposure": 0.6}, "times": {"day": {"hour": 8.0}}}
	var overlay := {"environment": {"fog_colour": "#98b2cb"}, "horizon_mountains": {"strength": 1.0}}
	var merged: Dictionary = WORLD_LOOK.merged_look(base, overlay)
	assert_eq(str((merged["environment"] as Dictionary)["fog_colour"]), "#98b2cb")
	assert_almost_eq(float((merged["environment"] as Dictionary)["exposure"]), 0.6, 0.0001,
		"a key the overlay does not name keeps the shared value")
	assert_true(merged.has("horizon_mountains"))
	assert_eq(str((base["environment"] as Dictionary)["fog_colour"]), "#a6bccb", "base untouched")


func test_only_the_meadows_scene_carries_the_meadows_look() -> void:
	var meadows := FileAccess.get_file_as_string("res://scenes/world/meadows_playground.tscn")
	assert_true(meadows.contains('realm_look_path = "res://data/config/meadows_look.json"'))
	for other: String in ["res://scenes/world/cloudreach_cliffs.tscn", "res://scenes/world/stormwood.tscn",
			"res://scenes/world/water_archipelago.tscn"]:
		assert_false(FileAccess.get_file_as_string(other).contains("meadows_look.json"),
			"%s must keep its own horizon" % other)


func test_the_meadows_haze_lives_in_the_meadows_overlay() -> void:
	var meadows: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_look.json"))
	var env: Dictionary = (meadows as Dictionary).get("environment", {})
	assert_true(env.has("fog_colour"), "the Meadows distance haze is the overlay's to set")
	var art: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	assert_ne(str(((art as Dictionary).get("environment", {}) as Dictionary).get("fog_colour", "")),
		str(env.get("fog_colour", "")), "art.json keeps the shared haze for the other realms")


func test_disabled_meadows_candidate_keeps_the_shipping_look() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_look.json"))
	assert_false(bool(overlay.look_candidate.enabled), "unjudged candidate must ship OFF")
	var look := MEADOWS_LOOK.new()
	look.realm_look_path = "res://data/config/meadows_look.json"
	var resolved: Dictionary = look.call("_load")
	var expected := WORLD_LOOK.merged_look(base, overlay)
	assert_eq(resolved, expected, "disabled subclass must retain exact shipping lighting")
	look.free()


func test_candidate_preserves_the_clock_and_held_night() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var candidate: Dictionary = MEADOWS_FINISH.settings().lighting
	var merged := WORLD_LOOK.merged_look(base, candidate)
	for time: String in ["dawn", "day", "golden", "night", "night_end"]:
		assert_eq(merged.times[time].hour, base.times[time].hour, "art must not move gameplay clock boundaries")
	var night := WORLD_LOOK._preset_over(merged, "night")
	var held := WORLD_LOOK._preset_over(merged, "night_end")
	for section: String in ["sun", "sky", "environment"]:
		assert_eq(held[section], night[section], "held night must inherit the whole Meadows rig")


func test_surface_candidate_preserves_imported_material_and_is_idempotent() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var source := StandardMaterial3D.new()
	source.albedo_color = Color("#76894e")
	source.roughness = 0.87
	source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	source.cull_mode = BaseMaterial3D.CULL_DISABLED
	var finished := MEADOWS_FINISH.finish_standard(source)
	assert_ne(finished, source, "never mutate a shared imported material")
	assert_false(source.detail_enabled)
	assert_eq(finished.albedo_color, source.albedo_color)
	assert_eq(finished.roughness, source.roughness)
	assert_eq(finished.transparency, source.transparency)
	assert_eq(finished.cull_mode, source.cull_mode)
	assert_true(finished.detail_enabled)
	assert_eq(MEADOWS_FINISH.finish_standard(finished), finished, "streaming revisit must not stack treatment")
	settings.enabled = was_enabled
	assert_eq(MEADOWS_FINISH.finish_standard(source), source, "OFF does not even duplicate a source")


func test_runtime_shader_keeps_its_streaming_writer_reference() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var source := ShaderMaterial.new()
	source.shader = Shader.new()
	source.shader.code = "shader_type spatial;\n#include \"res://shaders/meadows_surface.gdshaderinc\"\nuniform float terrain_offset = 0.0; void fragment() { ALBEDO = vec3(terrain_offset); }"
	var finish := MEADOWS_FINISH.new()
	var active: ShaderMaterial = finish.call("_finish", source)
	assert_eq(active, source, "runtime grass still owns the material the surface renders")
	source.set_shader_parameter("terrain_offset", 128.0)
	assert_eq(active.get_shader_parameter("terrain_offset"), 128.0, "streaming updates must remain visible")
	finish.free()
	settings.enabled = was_enabled


func test_runtime_instance_buffer_keeps_its_streaming_writer_reference() -> void:
	var settings := MEADOWS_FINISH.settings()
	var was_enabled := bool(settings.enabled)
	settings.enabled = true
	var source := MultiMesh.new()
	source.transform_format = MultiMesh.TRANSFORM_3D
	source.instance_count = 1
	var mesh := BoxMesh.new()
	mesh.material = StandardMaterial3D.new()
	source.mesh = mesh
	var finish := MEADOWS_FINISH.new()
	var active: MultiMesh = finish.call("_finish_multimesh", source)
	assert_eq(active, source, "runtime instancer retains the rendered transform buffer")
	assert_ne(active.mesh, mesh, "material slots must not mutate an imported/shared source mesh")
	var moved := Transform3D(Basis.IDENTITY, Vector3(128.0, 3.0, -64.0))
	source.set_instance_transform(0, moved)
	assert_eq(active.get_instance_transform(0), moved, "later streaming placement reaches the rendered instance")
	assert_eq(finish.call("_finish_multimesh", active), active, "revisits do not copy the instance buffer")
	finish.free()
	settings.enabled = was_enabled

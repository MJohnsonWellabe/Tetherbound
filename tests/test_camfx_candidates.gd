extends "res://tests/test_case.gd"

## Cameras-and-effects cause lane (owner 1 Nov): data/config/camfx.json. Every
## block ships OFF and is inert; ON applies only its own keys. Presentation
## only, so these pin the switch and the shape of what is built, not the look.

const CAMFX := preload("res://scripts/vfx/camfx.gd")
const CAMPFIRE_GLOW := preload("res://scripts/world/campfire_glow.gd")
const OCCLUSION := preload("res://scripts/player/camera_occlusion.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _with(block: String) -> Dictionary:
	var cfg := _json(CAMFX.CONFIG_PATH).duplicate(true)
	var on: Dictionary = (cfg[block] as Dictionary).duplicate(true)
	on["enabled"] = true
	cfg[block] = on
	return cfg


func after_each() -> void:
	CAMFX.set_config_for_tests({})


## A log pile with a cone named "Fire", like Bonfire_Fire.obj imports.
func _bonfire() -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var logs := PackedVector3Array([Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(0, 0.4, 1)])
	var cone := PackedVector3Array([Vector3(-0.4, 0.3, -0.4), Vector3(0.4, 0.3, -0.4), Vector3(0.0, 1.9, 0.4)])
	for verts: PackedVector3Array in [logs, cone]:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_name(0, "Wood")
	mesh.surface_set_name(1, "Fire")
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance


func test_every_camfx_block_ships_off() -> void:
	var cfg := _json(CAMFX.CONFIG_PATH)
	for block: String in ["catch_orb", "flame", "fight_fade"]:
		assert_true(cfg.has(block), "camfx.json must declare %s" % block)
		assert_false(bool((cfg[block] as Dictionary).get("enabled", true)), "%s ships OFF" % block)
		assert_eq((cfg[block] as Dictionary).get("scope"), "client_presentation", "%s declares its scope" % block)
		assert_true(CAMFX.block(block).is_empty(), "OFF reads as empty: %s" % block)


func test_flame_off_keeps_the_lit_cone() -> void:
	var fire := _bonfire()
	assert_eq(CAMPFIRE_GLOW.ignite(fire), 1, "OFF still lights the Fire surface")
	var material := fire.get_surface_override_material(1) as StandardMaterial3D
	assert_true(material != null and material.emission_enabled, "OFF keeps the emissive cone")
	assert_true(fire.get_node_or_null(^"CamfxFlame") == null, "OFF adds no flame")
	assert_false(CAMPFIRE_GLOW.camfx_flame_drops_halo(), "OFF keeps the halo card")
	fire.free()


func test_flame_on_replaces_the_cone_in_its_footprint() -> void:
	CAMFX.set_config_for_tests(_with("flame"))
	var fire := _bonfire()
	var box := CAMPFIRE_GLOW.surface_aabb(fire.mesh, 1)
	assert_true(box.size.y > 1.5, "the Fire surface's own bounds are read (got %s)" % str(box))
	assert_eq(CAMPFIRE_GLOW.ignite(fire), 1, "ON still reports the fire as lit (no missing-surface warning)")
	var hidden := fire.get_surface_override_material(1) as StandardMaterial3D
	assert_true(hidden != null and is_zero_approx(hidden.albedo_color.a), "ON hides the flat cone")
	var flame := fire.get_node_or_null(^"CamfxFlame") as Node3D
	assert_true(flame != null, "ON stands a flame in the cone's place")
	if flame != null:
		assert_eq(flame.get_child_count(), 2, "two flame cards")
		assert_true(absf(flame.position.y - box.position.y) < 0.001, "the flame stands on the cone's base")
		var outer := (flame.get_child(0) as MeshInstance3D).mesh as QuadMesh
		assert_true(absf(outer.size.y - box.size.y) < 0.001, "the outer card is as tall as the cone")
		assert_true(((flame.get_child(0) as MeshInstance3D).material_override as ShaderMaterial).shader
			== CAMFX.FLAME_SHADER, "the cards use the procedural flame shader")
	assert_eq(fire.get_surface_override_material(0), null, "the logs are untouched")
	assert_true(CAMPFIRE_GLOW.camfx_flame_drops_halo(), "a replaced cone drops the halo card")
	fire.free()


func test_catch_orb_block_names_an_installed_model_and_hides_the_rest_disc() -> void:
	var orb: Dictionary = _json(CAMFX.CONFIG_PATH)["catch_orb"]
	assert_true(ResourceLoader.exists(str(orb["model"])), "the authored capture orb is in the repo")
	assert_false(bool(orb.get("rest_halo", true)), "no disc at rest")
	assert_true(float(orb["flight_halo_scale"]) < 5.5, "a smaller flight glow than the shipped 5.5x")
	assert_true(float(orb["verdict_flash_scale"]) < 1.0, "the verdict flashes shrink")
	assert_true(CAMFX.block("catch_orb").is_empty(), "OFF reads as empty")
	CAMFX.set_config_for_tests(_with("catch_orb"))
	assert_false(CAMFX.block("catch_orb").is_empty(), "ON reads its keys")


func test_orb_off_paths_are_the_shipped_ones() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/combat/orb.gd")
	assert_true(source.contains("_r2 = CAMFX.block(\"catch_orb\")"), "the orb reads its own camfx block")
	assert_true(source.contains("if _r2.is_empty() or _r2.get(\"shake_flash\", false) == true:"),
		"OFF keeps the shake flash")
	var manager := FileAccess.get_file_as_string("res://scripts/combat/combat_manager.gd")
	assert_true(manager.contains("else 1.0"), "OFF keeps the verdict flash at full size")


func test_fight_fade_off_is_inert_and_options_keep_the_base_filters() -> void:
	assert_true(CAMFX.block("fight_fade").is_empty(), "OFF reads as empty")
	assert_true(OCCLUSION.occluders(null, Vector3.ZERO, Vector3.ONE * 3.0, [],
		{"include_shadowless": true}).is_empty(), "no world, no occluders, with or without options")
	CAMFX.set_config_for_tests(_with("fight_fade"))
	var on := CAMFX.block("fight_fade")
	assert_true(bool(on["include_shadowless"]), "ON fades shadowless canopy cards")
	assert_true(float(on["shadowless_min_height_m"]) >= 2.0, "grass and effect cards stay under the shadowless floor")


func _impact(element: String, charged: bool) -> Node3D:
	var node := (load("res://scripts/vfx/camfx_impact.gd") as Script).new() as Node3D
	node.set("_cfg", _with("impact_fx")["impact_fx"])
	node.set("_element", element)
	node.set("_charged", charged)
	node.set("_height", 2.0)
	node.call("_ready")
	return node


func test_impact_fx_ships_off_and_spawns_nothing() -> void:
	var cfg := _json(CAMFX.CONFIG_PATH)
	assert_false(bool((cfg["impact_fx"] as Dictionary).get("enabled", true)), "impact_fx ships OFF")
	var impact := load("res://scripts/vfx/camfx_impact.gd")
	assert_true(impact.spawn(null, null, null, true) == null, "OFF (and no host) spawns nothing")
	var manager := FileAccess.get_file_as_string("res://scripts/combat/combat_manager.gd")
	assert_true(manager.contains("if not impact_fx.is_empty():\n\t\tCAMFX_IMPACT.spawn("),
		"the combat path spawns only when the block is on")


func test_impact_fx_reads_the_element_from_the_move_tint() -> void:
	var impact := load("res://scripts/vfx/camfx_impact.gd")
	var vfx := _json("res://data/config/vfx.json")
	for type: String in ["electric", "ground", "water", "fire"]:
		assert_eq(impact.element_for_tint(Color(str(vfx["type_colours"][type]))), type, "tint names %s" % type)
	assert_eq(impact.element_for_tint(null), "", "no tint, no element")
	assert_eq(impact.element_for_tint(Color(0.1, 0.9, 0.1)), "", "an unknown colour names nothing")


func test_impact_fx_builds_chips_crack_and_arcs_by_element() -> void:
	var cfg: Dictionary = _with("impact_fx")["impact_fx"]
	var heavy_ground := _impact("ground", true)
	assert_eq((heavy_ground.get("_chips") as Array).size(), int(cfg["chips_charged"]), "a heavy ground blow throws chips")
	assert_true(heavy_ground.get("_crack") != null, "a heavy ground blow cracks the ground")
	assert_true(heavy_ground.get("_arcs") == null, "no arcs without electric")
	heavy_ground.free()
	var quick_electric := _impact("electric", false)
	assert_eq((quick_electric.get("_chips") as Array).size(), int(cfg["chips_quick"]), "a quick blow throws fewer chips")
	assert_true(quick_electric.get("_crack") == null, "a quick blow leaves no crack")
	assert_true(quick_electric.get("_arcs") != null, "an electric blow arcs")
	quick_electric.free()
	var water := _impact("water", true)
	assert_eq((water.get("_chips") as Array).size(), 0, "water throws no stone")
	assert_true(water.get("_crack") == null, "water leaves no crack")
	water.free()


## --- dialogue_open: rig driven by hand, as test_conversation_camera.gd does --

const RIG := preload("res://scripts/player/camera_rig.gd")
const CONVERSATION := preload("res://scripts/player/conversation_camera.gd")
const TRAINER_AT := Vector3(10.0, 0.0, 10.0)
const SPEAKER_AT := Vector3(10.0, 0.0, 7.4)


func _rig() -> SpringArm3D:
	var rig := SpringArm3D.new()
	rig.set_script(RIG)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 70.0
	rig.add_child(camera)
	rig.notification(Node.NOTIFICATION_READY)
	rig.call("set_occlusion_probe_for_tests", func(_pivot: Vector3, _dir: Vector3, limit: float) -> float: return limit)
	return rig


func test_dialogue_open_ships_off() -> void:
	var cfg := _json(CAMFX.CONFIG_PATH)
	assert_false(bool((cfg["dialogue_open"] as Dictionary).get("enabled", true)), "dialogue_open ships OFF")
	var rig := FileAccess.get_file_as_string("res://scripts/player/camera_rig.gd")
	assert_true(rig.contains("var open_cfg := CAMFX.block(\"dialogue_open\")\n\tif not open_cfg.is_empty():"),
		"the push-in only searches when the block is on")


func test_dialogue_open_swings_away_from_a_wall_filling_the_frame() -> void:
	var rig := _rig()
	var open_cfg: Dictionary = _with("dialogue_open")["dialogue_open"]
	var cfg := CONVERSATION.config()
	var trainer_anchor := TRAINER_AT + Vector3.UP * 1.45
	var speaker_anchor := SPEAKER_AT + Vector3.UP * 1.9 * 0.78
	var shot := CONVERSATION.solve(trainer_anchor, speaker_anchor, Vector3.FORWARD, cfg)
	# A rock face standing beside the pair: anything reaching past x = 10.4 hits it.
	rig.call("set_view_probe_for_tests", func(_lens: Vector3, end: Vector3) -> bool: return end.x > 10.4)
	var before := float(rig.call("_view_blocked", shot, speaker_anchor, open_cfg))
	assert_true(before > float(open_cfg["blocked_threshold"]), "the fixture wall fills the frame (%.2f)" % before)
	var opened: Dictionary = rig.call("_open_view_shot", shot, cfg, INF, trainer_anchor, speaker_anchor,
		Vector3.FORWARD, open_cfg)
	var after := float(rig.call("_view_blocked", opened, speaker_anchor, open_cfg))
	assert_true(after <= before - float(open_cfg["min_gain"]), "the swing opens the frame (%.2f -> %.2f)" % [before, after])
	assert_true(bool(rig.call("_speaker_in_frame", opened, speaker_anchor)), "the speaker stays in frame")
	# The same solve again keeps the same angle (no flicking between frames).
	var again: Dictionary = rig.call("_open_view_shot", shot, cfg, INF, trainer_anchor, speaker_anchor,
		Vector3.FORWARD, open_cfg)
	assert_true(Vector3(again["dir"]).distance_to(Vector3(opened["dir"])) < 0.001, "the chosen angle holds")
	# An open frame is left exactly as solved.
	rig.call("set_view_probe_for_tests", func(_lens: Vector3, _end: Vector3) -> bool: return false)
	var clear: Dictionary = rig.call("_open_view_shot", shot, cfg, INF, trainer_anchor, speaker_anchor,
		Vector3.FORWARD, open_cfg)
	assert_true(Vector3(clear["dir"]).distance_to(Vector3(shot["dir"])) < 0.0001, "an open frame is untouched")
	rig.free()

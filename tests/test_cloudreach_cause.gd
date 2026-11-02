extends "res://tests/test_case.gd"

## Cause lane tb/cause-cloudreach: every part of data/config/cloudreach_cause.json
## is OFF by default and changes nothing while off; ON applies its keys.

const CAUSE := preload("res://scripts/world/cloudreach_cause.gd")
const MEADOW := preload("res://scripts/world/cloudreach_meadow_groves.gd")
var NO_ARGS := PackedStringArray()


func _cfg(on: bool) -> Dictionary:
	var cfg: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CAUSE.PATH)) as Dictionary).duplicate(true)
	for part: String in CAUSE.PARTS:
		(cfg[part] as Dictionary)["enabled"] = on
	return cfg


func test_every_part_defaults_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CAUSE.PATH))
	assert_false(bool(cfg.get("enabled", true)), "master switch ships OFF")
	for part: String in CAUSE.PARTS:
		assert_true(cfg.has(part), part + " is declared")
		assert_false(bool((cfg[part] as Dictionary).get("enabled", true)), part + " ships OFF")
		assert_false(CAUSE.part_on(part, cfg, NO_ARGS, false), part + " is off without a preview arg")


func test_master_switch_turns_on_every_part() -> void:
	var cfg := _cfg(false)
	cfg["enabled"] = true
	for part: String in CAUSE.PARTS:
		assert_true(CAUSE.part_on(part, cfg, NO_ARGS, false), part + " on under the master switch")


func test_preview_args_switch_parts() -> void:
	var cfg := _cfg(false)
	assert_true(CAUSE.part_on("cloud_sea", cfg, PackedStringArray(["--cloudreach-cause-candidate"])))
	assert_true(CAUSE.part_on("pale_strata", cfg, PackedStringArray(["--cloudreach-cause-pale_strata"])))
	assert_false(CAUSE.part_on("cloud_sea", cfg, PackedStringArray(["--cloudreach-cause-pale_strata"])),
		"one part's arg leaves the others off")


func test_visual_overlay_off_changes_nothing_on_applies_keys() -> void:
	var base := {"geology": {"stone_light": "#8a8f82", "rock_sections": {"enabled": true,
		"limestone_buttress_tint": "#6b5e4f"}}, "cloud_sea": {"enabled": true, "drop_below_tier_m": 190.0,
		"seed": 7}, "surface": {"keep": 1}}
	assert_eq(CAUSE.apply_visual(base, _cfg(false), NO_ARGS, false), base, "off: identical")
	var on := CAUSE.apply_visual(base, _cfg(true), NO_ARGS, false)
	var spec: Dictionary = _cfg(true)
	assert_eq(on.geology.stone_light, spec.pale_strata.visual.geology.stone_light, "pale stone light")
	assert_eq(on.geology.rock_sections.limestone_buttress_tint,
		spec.pale_strata.visual.geology.rock_sections.limestone_buttress_tint, "pale buttress")
	assert_true(bool(on.geology.rock_sections.enabled), "unrelated rock-section keys kept")
	assert_eq(on.cloud_sea.drop_below_tier_m, spec.cloud_sea.visual.cloud_sea.drop_below_tier_m, "deck rises")
	assert_eq(int(on.cloud_sea.seed), 7, "unrelated deck keys kept")
	assert_eq(on.surface, {"keep": 1}, "other sections untouched")
	assert_false(on.geology.has("_why"), "comment keys never merge")


func test_light_overrides_only_when_on() -> void:
	assert_eq(CAUSE.light_overrides(_cfg(false), NO_ARGS, false), {}, "off: no overrides")
	var on := CAUSE.light_overrides(_cfg(true), NO_ARGS, false)
	assert_true(on.has("day"), "day graded")
	assert_false(on.has("night"), "night untouched")
	var times := {"day": {"sun": {"energy": 1.4, "yaw_deg": 140.0}}, "night": {"sun": {"energy": 0.3}}}
	preload("res://scripts/world/cloudreach_world.gd").apply_time_overrides(times, on)
	assert_almost_eq(float(times.day.sun.energy), float(on.day.sun.energy), 0.0001, "day key applied")
	assert_almost_eq(float(times.night.sun.energy), 0.3, 0.0001, "night unchanged")


func test_stone_materials_retint_only_when_on() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("#906955")
	var cliff := ShaderMaterial.new()
	var materials := {"stone": stone, "cliff": cliff}
	assert_eq(CAUSE.apply_materials(materials, _cfg(false), NO_ARGS, false), 0)
	assert_true(stone.albedo_color.is_equal_approx(Color("#906955")), "off: rusty stone unchanged")
	assert_eq(CAUSE.apply_materials(materials, _cfg(true), NO_ARGS, false), 1, "only present materials")
	assert_true(stone.albedo_color.is_equal_approx(Color(str(_cfg(true).pale_strata.materials.stone))), "paled")


func test_rock_surface_follows_preset_when_off() -> void:
	var base := {"texture_scale": 0.36}
	var off := CAUSE.rock_surface(base, false)
	assert_false(bool(off.enabled), "shipped: course surface stays off")
	assert_almost_eq(float(off.texture_scale), 0.36, 0.0001, "art.json knobs kept")
	assert_true(bool(CAUSE.rock_surface(base, true).enabled), "the graphics preset still turns it on")


func _card(world: Node3D, at: Vector3, width: float) -> MeshInstance3D:
	var card := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, width * 0.5)
	card.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(CAUSE.CLOUD_CARD_TEXTURE) as Texture2D
	card.material_override = material
	card.position = at
	card.set_meta(&"cloud_ring_centre", Vector3.ZERO)
	world.add_child(card)
	return card


func test_grounded_cloud_card_moves_out_over_open_air_and_below_the_rim() -> void:
	var world := Node3D.new()
	# A 300 m-radius plateau at y=100; open sky beyond it.
	var ground := func(x: float, z: float) -> float:
		return 100.0 if Vector2(x, z).length() < 300.0 else NAN
	var grounded := _card(world, Vector3(120.0, 110.0, 0.0), 200.0)
	var open_air := _card(world, Vector3(0.0, 40.0, 700.0), 200.0)
	assert_eq(CAUSE.reseat_cloud_cards(world, ground, _cfg(false), NO_ARGS, false), {"moved": 0, "hidden": 0})
	assert_eq(grounded.position, Vector3(120.0, 110.0, 0.0), "off: card untouched")
	var result := CAUSE.reseat_cloud_cards(world, ground, _cfg(true), NO_ARGS, false)
	assert_eq(int(result.moved), 1, "one grounded card moved")
	assert_eq(int(result.hidden), 0)
	assert_true(grounded.visible, "kept, not hidden")
	assert_true(grounded.position.x >= 300.0 + 100.0, "out past the rim with its whole footprint")
	assert_true(grounded.position.y + 50.0 < 100.0, "its top sits below the rim")
	assert_almost_eq(grounded.position.z, 0.0, 0.01, "pushed straight out from its ring centre")
	assert_eq(open_air.position, Vector3(0.0, 40.0, 700.0), "cards already over open air stay")
	world.free()


func test_card_with_no_open_air_in_reach_hides() -> void:
	var world := Node3D.new()
	var ground := func(_x: float, _z: float) -> float: return 100.0
	var card := _card(world, Vector3(50.0, 110.0, 0.0), 200.0)
	var result := CAUSE.reseat_cloud_cards(world, ground, _cfg(true), NO_ARGS, false)
	assert_eq(int(result.hidden), 1)
	assert_false(card.visible, "no cloud card left standing on the meadow")
	world.free()


func _buffer(points: Array[Vector3]) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	for p: Vector3 in points:
		buffer.append_array([1.0, 0.0, 0.0, p.x, 0.0, 0.6, 0.0, p.y, 0.0, 0.0, 1.0, p.z])
	return buffer


func test_meadow_zones() -> void:
	var spec: Dictionary = _cfg(true).meadow_groves
	assert_almost_eq(MEADOW.height_factor(0.0, spec), 1.0, 0.0001, "plain meadow unchanged")
	assert_almost_eq(MEADOW.height_factor(-1.0, spec), float(spec.clearing_height), 0.0001, "clearing short")
	assert_almost_eq(MEADOW.height_factor(1.0, spec), float(spec.fringe_height), 0.0001, "grove fringe long")
	for i in 50:
		assert_false(MEADOW.thinned(float(i) * 7.3, float(i) * 3.1, 0.0, spec), "meadow never thinned")


func test_meadow_buffer_edit_clears_and_scales() -> void:
	var spec: Dictionary = (_cfg(true).meadow_groves as Dictionary).duplicate()
	# Everything is clearing, nothing thins: every tuft halves in height.
	spec["clearing_below"] = 10.0
	spec["grove_above"] = 10.0
	spec["clearing_keep"] = 1.0
	spec["clearing_height"] = 0.5
	var meadow = MEADOW.new(spec)
	var cleared := {}
	MEADOW.add_clear(cleared, Vector3(100.0, 0.0, 100.0), 3.0)
	var buffer := _buffer([Vector3(100.5, 0.0, 100.5), Vector3(40.0, 0.0, 40.0)])
	var result: Dictionary = meadow.edit_buffer(buffer, Transform3D.IDENTITY, cleared)
	assert_eq(int(result.collapsed), 1, "tuft under the outcrop cleared")
	assert_eq(int(result.scaled), 1)
	assert_almost_eq(buffer[5], 0.0, 0.0001, "collapsed to zero scale")
	assert_almost_eq(buffer[3], 100.5, 0.0001, "origin kept")
	assert_almost_eq(buffer[12 + 5], 0.3, 0.0001, "clearing tuft at half height")
	assert_almost_eq(buffer[12 + 0], 1.0, 0.0001, "width unchanged")
	# Neutral field: nothing changes.
	spec["clearing_below"] = -10.0
	var neutral = MEADOW.new(spec)
	var untouched := _buffer([Vector3(40.0, 0.0, 40.0)])
	var before := untouched.duplicate()
	var none: Dictionary = neutral.edit_buffer(untouched, Transform3D.IDENTITY, {})
	assert_eq(none, {"scaled": 0, "collapsed": 0})
	assert_eq(untouched, before, "meadow tufts untouched")

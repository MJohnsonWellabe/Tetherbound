extends "res://tests/test_case.gd"

# Owner touch pass (24 Oct 2026): "adding some energy, some elemental effects
# ... Don't go overboard." A species may name its own small elemental touch
# (`touch_vfx` in species.json) without being an Aspect variant. It must attach
# on the ordinary body, leave species without one bare, stay light (no eye glow,
# no paw group) and never use Team Tether's red.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY_SCRIPT := preload("res://scripts/creatures/creature_body.gd")
const ASPECT_VFX := preload("res://scripts/creatures/vfx/aspect_vfx.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RUNS_IN_INITIALIZED_TREE := true

var _root: Node3D = null


func before_each() -> void:
	super.before_each()
	_root = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_root)


func after_each() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null
	super.after_each()


func test_every_touch_vfx_names_a_light_non_red_preset() -> void:
	var named := 0
	for id: String in SPECIES.table().keys():
		var touch := str(SPECIES.definition(id).get("touch_vfx", ""))
		if touch == "":
			continue
		named += 1
		assert_true(ASPECT_VFX.PRESETS.has(touch), "%s touch_vfx '%s' has a preset" % [id, touch])
		if not ASPECT_VFX.PRESETS.has(touch):
			continue
		var preset: Dictionary = ASPECT_VFX.PRESETS[touch]
		assert_false(preset.has("eye_colour"), "%s touch keeps its own eyes" % id)
		assert_eq(int(preset.get("paw_count", 0)), 0, "%s touch has no paw group" % id)
		assert_true(int(preset.get("primary_count", 0)) <= 6, "%s touch stays a few motes" % id)
		var colour: Color = preset.get("primary_colour", Color.WHITE)
		var red := colour.h < 0.05 or colour.h > 0.93
		assert_false(red and colour.s > 0.5, "%s touch is not Team Tether red" % id)
	assert_true(named >= 1, "at least one species carries a touch_vfx")


func test_touch_vfx_attaches_to_the_ordinary_body_only_where_named() -> void:
	var touched := _body("cindercub")
	await _frames(2)
	assert_true(touched.get_node_or_null("AspectVfx_cindercub_embers") != null,
		"Cindercub carries its ember touch")
	var bare := _body("sparkit")
	await _frames(2)
	for child in bare.get_children():
		assert_false(str(child.name).begins_with("AspectVfx_"), "Sparkit carries no touch")


func _body(id: String) -> Node3D:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY_SCRIPT)
	body.set("species_id", id)
	_root.add_child(body)
	return body


func _frames(count: int) -> void:
	for _i in count:
		await (Engine.get_main_loop() as SceneTree).process_frame

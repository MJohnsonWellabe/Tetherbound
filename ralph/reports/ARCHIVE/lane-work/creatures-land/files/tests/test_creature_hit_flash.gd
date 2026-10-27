extends "res://tests/test_case.gd"

# P2-016 (coordinator GO, 25 Oct): a struck creature's own surface pulses
# warm-white (combat.json `impact.hit_flash`), so the hit reads on the body at
# any camera distance. The pulse is an additive overlay that fades out and is
# removed; the body, its collider and its own materials are untouched.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
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


func test_a_hit_pulses_the_body_and_clears() -> void:
	var cfg: Dictionary = MATH.config().get("impact", {}).get("hit_flash", {})
	assert_true(cfg.get("enabled") == true, "the shipped config turns the hit flash on")
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY)
	body.set("species_id", "mudsnout")
	_root.add_child(body)
	await _frames(3)
	body.call("play_combat_flinch", -body.call("facing"))
	var meshes: Array = body.get("_hit_flash_meshes")
	assert_true(meshes.size() > 0, "every visible mesh of the art carries the flash")
	var material: StandardMaterial3D = body.get("_hit_flash_material")
	assert_almost_eq(material.albedo_color.a, float(cfg.get("strength", 0.55)), 0.01, "the pulse starts at full strength")
	assert_eq(material.blend_mode, BaseMaterial3D.BLEND_MODE_ADD, "it adds light, never paints over the body")
	await _frames(int(ceil(float(cfg.get("seconds", 0.12)) * Engine.physics_ticks_per_second)) + 3)
	for node in (body.get("_model") as Node3D).find_children("*", "MeshInstance3D", true, false):
		assert_true((node as MeshInstance3D).material_overlay == null, "the overlay is removed after the pulse")


func _frames(count: int) -> void:
	for _i in count:
		await (Engine.get_main_loop() as SceneTree).physics_frame

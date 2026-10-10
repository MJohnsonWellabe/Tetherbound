extends Node3D

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const GUARDIAN_CLEAR_FLAG := "stormwood:named:crown_guardian:cleared"
const ENGINE_TRUTH_FLAG := "stormwood:engine_truth_learned"
const FINISH_SHADER := preload("res://shaders/stormwood_heartstone.gdshader")
const FINISH_CONFIG := "res://data/config/stormwood_heartstone_visual.json"
var world: Node3D
var game: Node
var prompt: Node3D
var _revision := -1
var _finish: Dictionary = {}
var _veins: Array[ShaderMaterial] = []
var _stone_light: OmniLight3D

func mount(owner_world: Node3D) -> void:
	world = owner_world
	game = get_node("/root/Game")
	position = Vector3(700, world.ground_height_at(700, 2712), 2712)
	add_to_group("progression_restore")
	var solid := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.2
	collision.shape = sphere
	collision.position.y = 1.2
	solid.add_child(collision)
	add_child(solid)
	if not bool(world.get("simulation_only")):
		_finish = JSON.parse_string(FileAccess.get_file_as_string(FINISH_CONFIG))
		var stone := (load("res://assets/environment/stylized_nature/Rock_Medium_3.gltf") as PackedScene).instantiate() as Node3D
		var bounds := BOUNDS.measure(stone)
		var factor := 2.4 / maxf(0.1, bounds.size.y)
		stone.scale = Vector3.ONE * factor
		stone.position.y = -bounds.position.y * factor
		add_child(stone)
		_finish_stone(stone)
		var light := OmniLight3D.new()
		_stone_light = light
		light.position.y = 2
		light.light_color = Color(str(_finish.get("charge_colour", "#9adecd")))
		light.omni_range = float(_finish.get("light_range_m", 14.0))
		light.light_energy = float(_finish.get("light_energy", 1.5))
		add_child(light)
		prompt = INTERACTABLE.new()
		prompt.name = "HeartstoneInteractable"
		prompt.position = Vector3(0, 0.8, -2)
		add_child(prompt)
		prompt.activated.connect(_touch)
	restore_progression_from_game(game)


func _finish_stone(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh != null:
			for surface in mesh.mesh.get_surface_count():
				var source := mesh.get_active_material(surface) as BaseMaterial3D
				if source == null:
					continue
				var material := source.duplicate() as BaseMaterial3D
				var veins := ShaderMaterial.new()
				veins.shader = FINISH_SHADER
				var bounds := mesh.mesh.get_aabb()
				veins.set_shader_parameter("bound_min", bounds.position)
				veins.set_shader_parameter("bound_size", bounds.size)
				for key: String in ["vein_scale", "vein_width", "pulse_depth", "pulse_speed"]:
					veins.set_shader_parameter(key, float(_finish[key]))
				material.next_pass = veins
				mesh.set_surface_override_material(surface, material)
				_veins.append(veins)
	for child in node.get_children():
		_finish_stone(child)

func _process(_delta: float) -> void:
	if game != null and int(game.get("progression").get("revision")) != _revision:
		restore_progression_from_game(game)

func restore_progression_from_game(_game: Node) -> void:
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	var released := bool(flags.has("stormwood:rootgate_released"))
	var tint := Color(str(_finish.get("released_colour" if released else "charge_colour", "#9adecd")))
	for veins: ShaderMaterial in _veins:
		veins.set_shader_parameter("charge_colour", tint)
		veins.set_shader_parameter("charge_energy", float(_finish.get("released_energy" if released else "charge_energy", 1.1)))
	if is_instance_valid(_stone_light):
		_stone_light.light_color = tint
		_stone_light.light_energy = float(_finish.get("released_light_energy" if released else "light_energy", 1.5))
	if prompt != null:
		var opened := bool(flags.has("stormwood:rootgate_released"))
		var guardian_clear := bool(flags.has(GUARDIAN_CLEAR_FLAG))
		var truth_learned := bool(flags.has(ENGINE_TRUTH_FLAG))
		var ready := guardian_clear and truth_learned and not opened
		var label := "Touch the Crown heartstone"
		if opened:
			label = "The Rootgate is open"
		elif not guardian_clear:
			label = "The Crown guardian bars the heartstone"
		elif not truth_learned:
			label = "Hear what Wen learned from the Crown"
		prompt.configure(label, 3.2, not opened)
		prompt.set("actionable", ready)

func _touch() -> void:
	if not game.get("progression").has(GUARDIAN_CLEAR_FLAG):
		game.push_world_message("The Crown guardian still bars the heartstone.")
		return
	if not game.get("progression").has(ENGINE_TRUTH_FLAG):
		game.push_world_message("Wen can read what the heartstone remembers. Hear the truth first.")
		return
	world.get_node("StormwoodChapter").emit_event("heartstone:rootgate")
	restore_progression_from_game(game)

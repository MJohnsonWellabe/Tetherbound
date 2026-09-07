extends Node3D

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
var world: Node3D
var game: Node
var prompt: Node3D
var _revision := -1

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
		var stone := (load("res://assets/environment/stylized_nature/Rock_Medium_3.gltf") as PackedScene).instantiate() as Node3D
		var bounds := BOUNDS.measure(stone)
		var factor := 2.4 / maxf(0.1, bounds.size.y)
		stone.scale = Vector3.ONE * factor
		stone.position.y = -bounds.position.y * factor
		add_child(stone)
		var light := OmniLight3D.new()
		light.position.y = 2
		light.light_color = Color("9deaf2")
		light.omni_range = 14
		light.light_energy = 2
		add_child(light)
		prompt = INTERACTABLE.new()
		prompt.name = "HeartstoneInteractable"
		prompt.position = Vector3(0, 0.8, -2)
		add_child(prompt)
		prompt.activated.connect(_touch)
	restore_progression_from_game(game)

func _process(_delta: float) -> void:
	if game != null and int(game.get("progression").get("revision")) != _revision:
		restore_progression_from_game(game)

func restore_progression_from_game(_game: Node) -> void:
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	if prompt != null:
		var opened := bool(flags.has("stormwood:rootgate_released"))
		prompt.configure("The Rootgate is open" if opened else "Touch the Crown heartstone", 3.2, not opened)

func _touch() -> void:
	if not game.get("progression").has("stormwood:engine_truth_learned"):
		game.push_world_message("Wen can read what the heartstone remembers. Hear the truth first.")
		return
	world.get_node("StormwoodChapter").emit_event("heartstone:rootgate")
	restore_progression_from_game(game)

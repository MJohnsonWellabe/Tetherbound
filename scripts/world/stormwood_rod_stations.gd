extends Node3D

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
var world: Node3D
var game: Node
var stations: Array = []
var _rows: Array[Dictionary] = []
var _revision := -1
var _event_left := 0.0

func mount(owner_world: Node3D) -> void:
	world = owner_world
	game = get_node("/root/Game")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_rod_stations.json"))
	stations = data.stations
	add_to_group("progression_restore")
	for spec: Dictionary in stations:
		var station := Node3D.new()
		station.name = str(spec.id)
		add_child(station)
		station.position = Vector3(float(spec.position[0]), world.ground_height_at(float(spec.position[0]), float(spec.position[1])), float(spec.position[1]))
		if bool(world.get("simulation_only")):
			continue
		var scene := load(str(spec.prop_model)) as PackedScene
		var model := scene.instantiate() as Node3D
		var bounds := BOUNDS.measure(model)
		var scale_factor := 9.0 / maxf(0.1, bounds.size.y)
		model.scale = Vector3.ONE * scale_factor
		model.position.y = -bounds.position.y * scale_factor
		station.add_child(model)
		var prompt := INTERACTABLE.new()
		prompt.name = "RodSwitch"
		prompt.position = Vector3(3, 1, 0)
		station.add_child(prompt)
		prompt.configure("Open rod-line switch", 3.2, true)
		prompt.activated.connect(func() -> void:
			CLAIM.submit(self, {"kind":"stormwood_disable_rod", "realm":"stormwood", "id":str(spec.id)}))
		var light := OmniLight3D.new()
		light.position.y = 6.0
		light.omni_range = 16.0
		station.add_child(light)
		_rows.append({"spec":spec, "prompt":prompt, "light":light})
	restore_progression_from_game(game)

func restore_progression_from_game(_game: Node) -> void:
	if game == null:
		return
	var flags: RefCounted = game.get("progression")
	_revision = int(flags.get("revision"))
	for row: Dictionary in _rows:
		var disabled: bool = flags.has(str(row.spec.disabled_flag))
		row.prompt.enabled = not disabled
		row.light.light_color = Color("78be9a") if disabled else Color("987bff")
		row.light.light_energy = 0.3 if disabled else 1.2

func _process(delta: float) -> void:
	if game == null:
		return
	var flags: RefCounted = game.get("progression")
	if int(flags.get("revision")) != _revision:
		restore_progression_from_game(game)
	_event_left -= delta
	if _event_left <= 0.0 and not bool(world.get("simulation_only")):
		_event_left = 0.5
		var chapter := world.get_node("StormwoodChapter")
		for spec: Dictionary in stations:
			if flags.has(str(spec.disabled_flag)):
				chapter.emit_event(str(spec.completion_event))

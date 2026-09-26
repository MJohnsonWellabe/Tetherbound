extends Node3D

## A fixed physical notice beside the open beach approach. The water is the
## boundary; this board reports its existing shared state without enforcing it.
const CONFIG := "res://data/config/water_first_shore_current_notice.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const DOCK_DRESSING := preload("res://scripts/world/water_dock_dressing.gd")
var _game: Node
var _cfg: Dictionary
var _label: Label3D
var _open := false
var _poll := 0.0

func build(world: Node3D, game: Node) -> void:
	_game = game
	_cfg = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var at: Array = _cfg.position_xz
	position = Vector3(float(at[0]), float(world.call("ground_height_at", float(at[0]), float(at[1]))), float(at[1]))
	rotation.y = deg_to_rad(float(_cfg.facing_yaw_deg))
	var width := float(_cfg.width_m)
	var height := float(_cfg.height_m)
	var board_height := float(_cfg.board_height_m)
	for side in [-1.0, 1.0]:
		_wood("Post", Vector3(side * (width * 0.5 - 0.13), 0, 0), Vector3(0.16, height, 0.18))
		_wood("PostCap", Vector3(side * (width * 0.5 - 0.13), height, 0), Vector3(0.23, 0.08, 0.24))
	for row in 3:
		_wood("Board", Vector3(0, height - board_height + float(row) * board_height / 3.0, -0.10),
			Vector3(width, board_height / 3.0 - 0.012, 0.10))
	_label = Label3D.new()
	_label.name = "PaintedRouteNotice"
	_label.position = Vector3(0, height - board_height * 0.5, -0.158)
	_label.rotation.y = PI
	_label.font_size = 96
	_label.pixel_size = 0.00165
	_label.outline_size = 0
	_label.modulate = Color("e7d7b2")
	_label.shaded = true
	_label.double_sided = false
	add_child(_label)
	# Use the same installed lantern and glass/housing treatment as the pier.
	# The practical illuminates the painted face; lettering stays shaded.
	var dressing := DOCK_DRESSING.new()
	dressing._lantern(self, _cfg.lantern, Vector3(-width * 0.5 + 0.12, height - 0.2, -0.28), PI)
	dressing.free()
	add_to_group("progression_restore")
	_refresh()

func _wood(label: String, at: Vector3, size: Vector3) -> void:
	var model := (load(str(_cfg.wood_model)) as PackedScene).instantiate() as Node3D
	model.name = label
	var bounds := BOUNDS.measure(model)
	model.scale = size / bounds.size
	model.position = at - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * model.scale
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var material := mesh.get_active_material(0).duplicate() as BaseMaterial3D
		material.albedo_color = Color(0.38, 0.32, 0.24)
		if label == "Board":
			material.albedo_texture = null
			material.albedo_color = Color("294d4a")
		material.normal_enabled = false
		material.roughness_texture = null
		material.roughness = 1.0
		material.metallic_specular = 0.1
		mesh.material_override = material
	add_child(model)

func _process(delta: float) -> void:
	_poll -= delta
	if _poll <= 0:
		_poll = 0.2
		_refresh()

func restore_progression_from_game(game: Node) -> void:
	_game = game
	_refresh()

func _refresh() -> void:
	if _label == null or not is_instance_valid(_game):
		return
	var flags: RefCounted = _game.get("world").get("flags")
	_open = bool(flags.has(str(_cfg.unlock_flag)))
	_label.text = str(_cfg.open_text if _open else _cfg.closed_text)

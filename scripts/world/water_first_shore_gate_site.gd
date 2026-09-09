extends Node3D

## Visual-only place-making around First Shore's existing return gate. The
## RealmGate remains the sole owner of interaction, barrier collision, state
## and travel. These installed pavers and framing stones only connect its fixed
## threshold to the fixed arrival/Pell route in the landscape.

const CONFIG_PATH := "res://data/config/water_first_shore_gate_site.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _built := false


func build(water_world: Node3D, fallback_ground: float) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("First Shore gate site config is invalid")
		return
	for raw: Variant in (parsed as Dictionary).get("pieces", []):
		if raw is Dictionary:
			_add_piece(water_world, raw as Dictionary, fallback_ground)


func _add_piece(water_world: Node3D, spec: Dictionary, fallback_ground: float) -> void:
	var path := str(spec.get("model", ""))
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("First Shore gate site model missing: %s" % path)
		return
	var piece := packed.instantiate() as Node3D
	if piece == null:
		push_warning("First Shore gate site model has no Node3D root: %s" % path)
		return
	piece.name = str(spec.get("id", "SitePiece"))
	var at: Array = spec.get("at", [0.0, 0.0])
	var scale_raw: Array = spec.get("scale", [1.0, 1.0, 1.0])
	piece.scale = Vector3(float(scale_raw[0]), float(scale_raw[1]), float(scale_raw[2]))
	piece.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	var ground := fallback_ground
	if water_world != null and water_world.has_method("ground_height_at"):
		var sampled := float(water_world.call("ground_height_at", float(at[0]), float(at[1])))
		if is_finite(sampled):
			ground = sampled
	var bounds := RENDER_BOUNDS.measure(piece)
	piece.position = Vector3(float(at[0]),
			ground - bounds.position.y * piece.scale.y + float(spec.get("sink_y", 0.0)),
			float(at[1]))
	piece.set_meta("first_shore_site_role", str(spec.get("role", "dressing")))
	add_child(piece)

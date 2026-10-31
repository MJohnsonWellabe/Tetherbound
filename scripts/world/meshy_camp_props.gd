extends RefCounted

## World dressing, coordinator Meshy batch 31 Oct (assets/props/meshy-1031,
## provenance in each folder; OFF until GPU judged). P2-115: the forward-camp
## creature bed read as "a flat sand-filled oval curb ... no bedding, straw or
## raised nest form"; P2-116: the camp workbench "a small, unreadable prop
## behind the trainer". The Meshy log-ringed straw nest and the long workbench
## with its lantern post replace only the VISIBLE meshes. The bed's rest body,
## interactable, build index and collider and the bench's BuildPiece collider
## and craft offer are untouched; the old meshes are hidden, not freed, so the
## collider bounds they produced stay exactly as built.
## Config: data/config/meshy_camp_props.json.
const CONFIG := "res://data/config/meshy_camp_props.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const BED_NODE := "MeshyCampBed"
const BENCH_NODE := "MeshyCampWorkbench"


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


static func apply_bed(bed: Node3D) -> Node3D:
	var cfg: Dictionary = settings().get("bed", {})
	if not bool(cfg.get("enabled", false)) or not is_instance_valid(bed) or bed.has_node(BED_NODE):
		return null
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	if model == null:
		return null
	# Hide the old pad, rim and any regional bolster; keep everything else.
	var piece := bed.get("_piece") as Node3D
	if piece != null:
		piece.visible = false
	var rims: Variant = bed.get("_rim_instances")
	if rims is Array:
		for rim: Variant in rims:
			if rim is Node3D and is_instance_valid(rim):
				(rim as Node3D).visible = false
	for name: String in cfg.get("hide_children", ["WaterPaddedBolster"]):
		var extra := bed.get_node_or_null(NodePath(name)) as Node3D
		if extra != null:
			extra.visible = false
	var seat := Node3D.new()
	seat.name = BED_NODE
	bed.add_child(seat)
	seat.add_child(model)
	_fit_across(model, float(cfg.get("across_m", 4.6)), float(cfg.get("sink_m", 0.04)))
	seat.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	return seat


static func apply_workbench(bench: Node3D) -> Node3D:
	var cfg: Dictionary = settings().get("workbench", {})
	if not bool(cfg.get("enabled", false)) or not is_instance_valid(bench) or bench.has_node(BENCH_NODE):
		return null
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	if model == null:
		return null
	var old := bench.get("_model") as Node3D
	if old != null:
		old.visible = false
	var tools := bench.get_node_or_null(^"WorkbenchTools") as Node3D
	if tools != null:
		tools.visible = false
	var seat := Node3D.new()
	seat.name = BENCH_NODE
	bench.add_child(seat)
	seat.add_child(model)
	HERO_PROP.fit_height(model, float(cfg.get("height_m", 2.5)), float(cfg.get("sink_m", 0.03)))
	var bounds: AABB = model.transform * BOUNDS.measure(model)
	model.position.x -= bounds.get_center().x
	model.position.z -= bounds.get_center().z
	seat.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	return seat


## Uniform scale so the model's wider ground axis spans `across_m`, lowest point
## at y = -sink, centred in X/Z.
static func _fit_across(model: Node3D, across_m: float, sink_m: float) -> void:
	var bounds := BOUNDS.measure(model)
	var factor := across_m / maxf(0.01, maxf(bounds.size.x, bounds.size.z))
	model.scale = Vector3.ONE * factor
	model.position = Vector3(-bounds.get_center().x * factor, -bounds.position.y * factor - sink_m,
		-bounds.get_center().z * factor)

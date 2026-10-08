extends Node3D

## F38 local, deterministic presentation. No RPC, receipt, save field or body.
## Reconstructed from installed families on every peer/reconnect. The explicit
## capture override is process-local; unjudged content stays off in production.
const CONFIG := "res://data/config/meadows_catalog_presentation.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const MATERIALS := preload("res://scripts/world/imported_materials.gd")
const PREFABS := preload("res://scripts/world/building_prefabs.gd")
static var _settings: Dictionary = {}
static var _active := -1


static func settings() -> Dictionary:
	if _settings.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if parsed is Dictionary:
			_settings = parsed
	return _settings


static func enabled() -> bool:
	if _active < 0:
		var args := OS.get_cmdline_user_args()
		_active = 1 if not args.has("--f38-baseline") and \
				(bool(settings().get("enabled", false)) or args.has("--f38-candidate")) else 0
	return _active == 1


## Filter only decorative draw instances AFTER harvest identity assignment.
## The stored bake, layer arrays, collision streams and harvest ledger survive.
static func suppress_cover(layer: String, placement: Dictionary) -> bool:
	if not enabled() or not settings().get("cover_layers", []).has(layer):
		return false
	if placement.has("harvest_item") or bool(placement.get("collide", false)):
		return false
	var at: Vector3 = placement.get("position", Vector3.ZERO)
	for zone: Dictionary in settings().get("cover_clearances", []):
		var centre := Vector2(float(zone.at[0]), float(zone.at[1]))
		if Vector2(at.x, at.z).distance_to(centre) < float(zone.radius_m):
			return true
	return false


func build(anchor: String, ground: Callable = Callable()) -> void:
	var active := enabled()
	if anchor == "hall_endwall":
		# Independent, bounded candidate: do not enable the old village/cover
		# catalogue merely to inspect two hanging nave decorations.
		var args := OS.get_cmdline_user_args()
		active = not args.has("--hall-endwall-baseline") and \
				(bool(settings().get("hall_endwall_enabled", false)) or args.has("--hall-endwall-candidate"))
	if not active or has_node("CatalogDressing"):
		return
	var dressing := Node3D.new()
	dressing.name = "CatalogDressing"
	add_child(dressing)
	var tint := PREFABS.new()
	for row: Dictionary in settings().get("placements", []):
		if str(row.anchor) != anchor:
			continue
		var packed := load(str(row.path)) as PackedScene
		if packed == null:
			push_error("F38 installed asset unavailable: " + str(row.path))
			continue
		var model := packed.instantiate() as Node3D
		if model == null:
			continue
		_strip_physics(model)
		MATERIALS.make_dielectric(model)
		if row.get("retint") is Dictionary:
			tint.apply_retint(model, row.retint)
		var holder := Node3D.new()
		holder.name = str(row.id)
		holder.rotation.y = deg_to_rad(float(row.get("yaw_deg", 0)))
		holder.scale = Vector3.ONE * float(row.get("scale", 1))
		holder.add_child(model)
		dressing.add_child(holder)
		var at := Vector3(float(row.at[0]), float(row.at[1]), float(row.at[2]))
		if bool(row.get("grounded", false)):
			if not ground.is_valid():
				holder.free()
				continue
			var height := float(ground.call(at.x, at.z))
			if not is_finite(height):
				push_error("F38 unsupported dressing stand: " + str(row.id))
				holder.free()
				continue
			var box := BOUNDS.measure(model)
			at.y += height - box.position.y * holder.scale.y
		holder.position = at


static func _strip_physics(node: Node) -> void:
	for child: Node in node.get_children():
		if child is CollisionObject3D or child is CollisionShape3D or child is CollisionPolygon3D:
			child.free()
		else:
			_strip_physics(child)

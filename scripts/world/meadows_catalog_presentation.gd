extends Node3D

## F38 local, deterministic presentation. No RPC, receipt, save field or body.
## Reconstructed from installed families on every peer/reconnect. The explicit
## capture override is process-local; shipping enablement comes from config.
const CONFIG := "res://data/config/meadows_catalog_presentation.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const MATERIALS := preload("res://scripts/world/imported_materials.gd")
const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const POTION_PRESENTATION := preload("res://scripts/world/meadows_potion_presentation.gd")
const DOORSTEP_SEAT := preload("res://scripts/world/meadows_doorstep_seat.gd")
const POTION_SIGHTLINE := preload("res://scripts/world/meadows_potion_sightline.gd")
static var _settings: Dictionary = {}
static var _active := -1


static func settings() -> Dictionary:
	if _settings.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if parsed is Dictionary:
			_settings = DOORSTEP_SEAT.apply(parsed)
	return _settings


static func enabled() -> bool:
	if _active < 0:
		_active = 1 if resolve_active(bool(settings().get("enabled", false)), OS.get_cmdline_user_args()) else 0
	return _active == 1


## `--f38-baseline` withholds an OFF candidate; it must never strip shipped
## dressing. This layer ships ON, and under the old gate every F38 matrix frame
## lost it -- including the Hall's two end banners, whose absence made the
## shipped Hall waymark fail and the Hall skip `set_process` (no day/night
## interior response in matrix captures). close-1024 F38 L3 finding.
static func resolve_active(config_enabled: bool, args: PackedStringArray) -> bool:
	if config_enabled:
		return true
	return args.has("--f38-candidate") and not args.has("--f38-baseline")


## Filter only decorative draw instances AFTER harvest identity assignment.
## The stored bake, layer arrays, collision streams and harvest ledger survive.
static func suppress_cover(layer: String, placement: Dictionary) -> bool:
	if POTION_PRESENTATION.suppress_cover(layer, placement):
		return true
	if POTION_SIGHTLINE.suppress_cover(layer, placement):
		return true
	if not (enabled() and settings().get("cover_layers", []).has(layer)):
		return false
	if placement.has("harvest_item") or bool(placement.get("collide", false)):
		return false
	var at: Vector3 = placement.get("position", Vector3.ZERO)
	return in_cover_clearance(Vector2(at.x, at.z))


## Whether this layer's cover can be suppressed at all; a caller filtering a
## whole layer asks once, not once per placement.
static func cover_layer(layer: String) -> bool:
	# The P2-033 potion clearings (Codex and sight-line) filter through suppress_cover() too, so a
	# layer it covers must not be skipped by the caller's per-layer gate.
	return (enabled() and settings().get("cover_layers", []).has(layer)) \
			or (POTION_PRESENTATION.enabled() and POTION_PRESENTATION.settings().get("decorative_cover_layers", []).has(layer)) \
			or (POTION_SIGHTLINE.enabled() and POTION_SIGHTLINE.settings().get("decorative_cover_layers", []).has(layer))


## Realm load (2026-10-12 profile): the clearance zones are read once into flat
## arrays. suppress_cover() runs for every scatter placement (~388k in the
## Meadows), and rebuilding each zone from the config dictionaries per call
## cost ~11 s of every build. Same strict `<` radius test as before.
static var _zone_centres := PackedVector2Array()
static var _zone_radii := PackedFloat32Array()
static var _zone_bounds := Rect2()
static var _zones_ready := false


static func in_cover_clearance(at: Vector2) -> bool:
	if not _zones_ready:
		_zones_ready = true
		var first := true
		for zone: Dictionary in settings().get("cover_clearances", []):
			var centre := Vector2(float(zone.at[0]), float(zone.at[1]))
			var radius := float(zone.radius_m)
			_zone_centres.append(centre)
			_zone_radii.append(radius)
			var box := Rect2(centre - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
			_zone_bounds = box if first else _zone_bounds.merge(box)
			first = false
	if _zone_centres.is_empty() or not _zone_bounds.grow(0.001).has_point(at):
		return false
	for i in _zone_centres.size():
		if at.distance_to(_zone_centres[i]) < _zone_radii[i]:
			return true
	return false


func build(anchor: String, ground: Callable = Callable()) -> void:
	if not enabled() or has_node("CatalogDressing"):
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
		# Only the small prop footprint clears procedural grass. This is the
		# village builder's presentation API; it adds no body or harvest change.
		var clear_radius := float(row.get("grass_clear_radius_m", 0.0))
		if clear_radius > 0.0:
			holder.set_meta(GRASS_FIELD.CLEAR_RADIUS_META, clear_radius)
			holder.add_to_group(GRASS_FIELD.CLEAR_GROUP)


static func _strip_physics(node: Node) -> void:
	for child: Node in node.get_children():
		if child is CollisionObject3D or child is CollisionShape3D or child is CollisionPolygon3D:
			child.free()
		else:
			_strip_physics(child)

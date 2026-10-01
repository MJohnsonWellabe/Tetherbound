extends Node3D

## F32 reusable presentation mount, explicitly called by a world owner only
## after the foundation's typed site registry/atomic receipt carrier lands.
## Existing worlds do not call this helper yet. Body clearance is a physics
## query with the real trainer shape; it is not an ordinary-player-path proof.

const CATALOGUE := preload("res://scripts/world/essence_node_catalog.gd")
const RENEWABLE_SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const PRESENTATION_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const HARVEST := preload("res://scripts/world/harvest_node.gd")

var _mounted: Dictionary = {}
var _refusals: Dictionary = {}


## Scene-local results for the later census witness; not durable world state.
func census() -> Dictionary:
	var living: Array[String] = []
	for id: String in _mounted:
		if is_instance_valid(_mounted[id]):
			living.append(id)
	return {"mounted_ids": living, "refusals": _refusals.duplicate(true),
		"ordinary_player_path_proven": false}


func mount(world: Node3D, realm: String, trainer: CharacterBody3D) -> Dictionary:
	# Stock, baked terrain and the actual body must belong to one live realm.
	if world == null or not world.is_inside_tree() or not world.has_method("world_realm") \
			or world.call("world_realm") != realm or trainer == null or not trainer.is_inside_tree() \
			or not is_inside_tree() or not world.is_ancestor_of(self) or not world.is_ancestor_of(trainer) \
			or world.get_world_3d() == null or get_world_3d() != world.get_world_3d() \
			or trainer.get_world_3d() != world.get_world_3d():
		return {"mounted_ids": [], "reason": "Actual world, mount and trainer residency must agree."}
	var game := world.get_node_or_null(^"/root/Game")
	var state: Variant = game.get("world") if game != null else null
	if not state is Object or not state.has_method("renewable_stock_state"):
		return {"mounted_ids": [], "reason": "Host renewable registry is not ready."}
	var source := CATALOGUE.read()
	var errors := CATALOGUE.validation_errors(source)
	if not errors.is_empty():
		return {"mounted_ids": [], "errors": errors}
	var items: RefCounted = game.get("items")
	var tuning: Dictionary = source.get("placement_validation", {})
	for authored: Dictionary in CATALOGUE.nodes_for(realm, source):
		var id := str(authored["id"])
		if _mounted.has(id) and is_instance_valid(_mounted[id]):
			continue
		var spec := RENEWABLE_SITES.by_id(realm, id)
		if spec.is_empty():
			_refusals[id] = "Canonical renewable definition is unavailable."
			continue
		var stock: Variant = state.call("renewable_stock_state", realm, id)
		if not stock is Dictionary or stock.is_empty():
			_refusals[id] = "Host site is not registered."
			continue
		if not _items_registered(spec, items):
			_refusals[id] = "Canonical inventory items are not registered."
			continue
		var model := str(spec.get("model", ""))
		if model.is_empty() or not ResourceLoader.exists(model):
			_refusals[id] = "Installed resource model is unavailable."
			continue
		var verdict := placement_verdict(world, spec, trainer, tuning)
		if not bool(verdict.get("ok", false)):
			_refusals[id] = str(verdict.get("reason", "Placement unavailable."))
			continue
		var node := HARVEST.new()
		node.name = id
		add_child(node)
		node.global_position = verdict["position"]
		node.call("setup", CATALOGUE.harvest_spec(spec, stock))
		_apply_presentation_candidate(node, spec, source)
		_mounted[id] = node
		_refusals.erase(id)
	return census()


static func _items_registered(spec: Dictionary, items: RefCounted) -> bool:
	if items == null:
		return false
	for item: String in spec.get("outputs", {}):
		if not bool(items.call("has", item)):
			return false
	var seed: Dictionary = spec.get("seed_drop", {})
	return seed.is_empty() or bool(items.call("has", str(seed.get("item", ""))))


static func placement_verdict(world: Node3D, spec: Dictionary,
		trainer: CharacterBody3D, tuning: Dictionary) -> Dictionary:
	if world == null or not world.has_method("ground_height_at") \
			or not world.is_inside_tree() or trainer == null or not trainer.is_inside_tree():
		return {"ok": false, "reason": "Actual terrain and trainer body are required."}
	var at: Variant = spec.get("at")
	if not at is Array or at.size() != 2:
		return {"ok": false, "reason": "Node coordinates are invalid."}
	var x := float(at[0])
	var z := float(at[1])
	var preferred_y := float(spec.get("authored_height", NAN))
	if str(spec.get("realm", "meadows")) == "cloudreach" and is_finite(preferred_y):
		if not world.has_method("_resource_position") or not world.has_method("ground_height_near"):
			return {"ok": false, "reason": "Intended Cloudreach surface resolver is unavailable."}
		var resolved: Variant = world.call("_resource_position", Vector3(x, preferred_y, z))
		if not resolved is Vector3 or not resolved.is_finite() \
				or absf(resolved.y - preferred_y) > float(tuning.get("maximum_elevation_resolution_m", 45.0)):
			return {"ok": false, "reason": "No real route surface at the intended elevation."}
		x = resolved.x
		z = resolved.z
		preferred_y = resolved.y
	var ground := _ground(world, x, z, preferred_y)
	if not is_finite(x) or not is_finite(z) or not is_finite(ground):
		return {"ok": false, "reason": "No finite baked terrain at this candidate."}
	var step := maxf(0.1, float(tuning.get("slope_sample_m", 0.75)))
	var maximum := float(tuning.get("maximum_slope_degrees", 35.0))
	for offset: Vector2 in [Vector2(step, 0), Vector2(-step, 0), Vector2(0, step), Vector2(0, -step)]:
		var neighbour := _ground(world, x + offset.x, z + offset.y, preferred_y)
		if not is_finite(neighbour) or rad_to_deg(atan(absf(neighbour - ground) / step)) > maximum:
			return {"ok": false, "reason": "Candidate slope is not walkable."}
	var collision: CollisionShape3D
	for child: Node in trainer.find_children("*", "CollisionShape3D", true, false):
		var candidate := child as CollisionShape3D
		if candidate != null and not candidate.disabled and candidate.shape != null:
			collision = candidate
			break
	if collision == null or trainer.collision_mask == 0:
		return {"ok": false, "reason": "Actual trainer collision shape is unavailable."}
	var site_position := Vector3(x, ground, z)
	var shape_transform := collision.global_transform
	shape_transform.origin = site_position + collision.global_position - trainer.global_position \
		+ Vector3.UP * maxf(0.0, float(tuning.get("body_ground_clearance_m", 0.06)))
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = shape_transform
	query.collision_mask = trainer.collision_mask
	query.exclude = [trainer.get_rid()]
	query.collide_with_areas = false
	if not world.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return {"ok": false, "reason": "Trainer capsule overlaps a terrain or prop collider."}
	return {"ok": true, "position": site_position, "body_clearance_proven": true,
		"ordinary_player_path_proven": false}


static func _ground(world: Node3D, x: float, z: float, preferred_y: float) -> float:
	if is_finite(preferred_y) and world.has_method("ground_height_near"):
		return float(world.call("ground_height_near", Vector3(x, preferred_y, z)))
	return float(world.call("ground_height_at", x, z))


## F32 candidate hook: keep the HarvestNode wrapper identity, authority and glow
## lifecycle. Nothing runs unless the whole authored candidate is true.
func _apply_presentation_candidate(node: Node3D, spec: Dictionary, source: Dictionary) -> bool:
	var candidate_config: Variant = source.get("presentation_candidate")
	if not candidate_config is Dictionary or typeof(candidate_config.get("enabled")) != TYPE_BOOL \
			or candidate_config["enabled"] != true:
		return false
	var profiles: Variant = candidate_config.get("profiles")
	var limit: Variant = candidate_config.get("maximum_parts_per_node")
	if not profiles is Dictionary or not _candidate_integer(limit):
		return false
	var profile: Variant = profiles.get(spec.get("type"))
	if not profile is Dictionary or not profile.get("parts") is Array \
			or profile["parts"].is_empty() or profile["parts"].size() > int(limit):
		return false
	var visual: Variant = node.get("_visual")
	if not visual is Node3D or not is_instance_valid(visual) \
			or not _candidate_scale(visual.scale.x) or not _candidate_scale(visual.scale.y) \
			or not _candidate_scale(visual.scale.z):
		return false
	var staged := Node3D.new()
	staged.name = "EssencePresentationCandidate"
	for raw: Variant in profile["parts"]:
		if not raw is Dictionary or not raw.get("model") is String \
				or not _candidate_point(raw.get("at")) or not _candidate_scale(raw.get("scale")) \
				or not _candidate_number(raw.get("yaw_deg")) \
				or not raw.get("surface_accents") is Dictionary:
			staged.free()
			return false
		var model := str(raw["model"])
		if not ResourceLoader.exists(model):
			staged.free()
			return false
		var packed: Resource = load(model)
		if not packed is PackedScene:
			staged.free()
			return false
		var instance: Node = (packed as PackedScene).instantiate()
		if not instance is Node3D:
			if instance != null:
				instance.free()
			staged.free()
			return false
		var part := instance as Node3D
		staged.add_child(part)
		if not _candidate_render_only(part):
			staged.free()
			return false
		part.position = Vector3(float(raw["at"][0]), float(raw["at"][1]), float(raw["at"][2]))
		part.rotation_degrees.y = float(raw["yaw_deg"])
		part.scale = Vector3.ONE * float(raw["scale"])
		# Reuse the existing nature-family texture/finish path before accents;
		# all overrides below are detached per-instance materials.
		node.call("_apply_material_fixups", part, model)
		if not _candidate_accents(part, raw["surface_accents"]):
			staged.free()
			return false
	# Imported cutout foliage keeps its alpha/normals/roughness/textures.
	# This existing helper applies the same dielectric/backlight fix as the
	# normal HarvestNode path. No lights, particles, shaders or new imports.
	PRESENTATION_MATERIALS.make_dielectric(staged)
	staged.scale = Vector3.ONE / visual.scale
	for child: Node in visual.get_children():
		if child is Node3D:
			(child as Node3D).visible = false
	visual.add_child(staged)
	node.set_meta("essence_presentation_candidate", true)
	return true


static func _candidate_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func _candidate_render_only(node: Node) -> bool:
	# Fail closed if a selected imported scene ever gains collision, a light,
	# particles, animation, scripts or another actor-bearing node. The candidate
	# is static Node3D/MeshInstance3D presentation only.
	if node.get_script() != null or not node.get_class() in ["Node3D", "MeshInstance3D"]:
		return false
	for child: Node in node.get_children():
		if not _candidate_render_only(child):
			return false
	return true


static func _candidate_scale(value: Variant) -> bool:
	return _candidate_number(value) and float(value) > 0.0


static func _candidate_integer(value: Variant) -> bool:
	return _candidate_scale(value) and float(value) == float(int(value))


static func _candidate_point(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for coordinate: Variant in value:
		if not _candidate_number(coordinate):
			return false
	return true


static func _candidate_accents(part: Node3D, accents: Dictionary) -> bool:
	for key: Variant in accents:
		var settings: Variant = accents[key]
		if not key is String or not settings is Dictionary \
				or not settings.get("tint") is String or not Color.html_is_valid(settings["tint"]) \
				or not _candidate_number(settings.get("emission_energy")) \
				or float(settings["emission_energy"]) < 0.0:
			return false
	var found := {}
	var meshes: Array[MeshInstance3D] = []
	if part is MeshInstance3D:
		meshes.append(part as MeshInstance3D)
	for descendant: Node in part.find_children("*", "MeshInstance3D", true, false):
		meshes.append(descendant as MeshInstance3D)
	for mesh_instance: MeshInstance3D in meshes:
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var authored := mesh_instance.mesh.surface_get_material(surface)
			if authored == null or not accents.has(authored.resource_name):
				continue
			var existing := mesh_instance.get_surface_override_material(surface)
			var standard := (existing if existing != null else authored) as StandardMaterial3D
			if standard == null:
				return false
			var settings: Dictionary = accents[authored.resource_name]
			# Duplicate the material while sharing immutable source textures;
			# avoid a texture copy per rare-node instance on the shared GPU.
			var material := standard.duplicate() as StandardMaterial3D
			material.albedo_color = material.albedo_color * Color(settings["tint"])
			material.emission_enabled = float(settings["emission_energy"]) > 0.0
			material.emission = Color(settings["tint"])
			material.emission_energy_multiplier = float(settings["emission_energy"])
			mesh_instance.set_surface_override_material(surface, material)
			found[authored.resource_name] = true
	for key: String in accents:
		if not found.has(key):
			return false
	return true


## F32 extra-material mount seam for the world owner. The default-OFF source
## block and required terrain/path evidence keep all six candidates unknown.
## This uses the SAME canonical site and host stock as ordinary/essence nodes;
## it never registers a site from presentation or creates a stock fallback.
func mount_additional_materials(world: Node3D, realm: String,
		trainer: CharacterBody3D) -> Dictionary:
	# Resolve residency from the actual owning shell before stock or terrain.
	# A separate caller realm string cannot place Meadows stock in Water.
	if world == null or not world.is_inside_tree() or not world.has_method("world_realm") \
			or world.call("world_realm") != realm or trainer == null or not trainer.is_inside_tree() \
			or not is_inside_tree() or not world.is_ancestor_of(self) or not world.is_ancestor_of(trainer) \
			or world.get_world_3d() == null or get_world_3d() != world.get_world_3d() \
			or trainer.get_world_3d() != world.get_world_3d():
		return {"mounted_ids": [], "reason": "Actual world, mount and trainer residency must agree."}
	var game := world.get_node_or_null(^"/root/Game")
	var state: Variant = game.get("world") if game != null else null
	if not state is Object or not state.has_method("renewable_stock_state"):
		return {"mounted_ids": [], "reason": "Host renewable registry is not ready."}
	var items: RefCounted = game.get("items")
	var tuning: Dictionary = CATALOGUE.read().get("placement_validation", {})
	for spec: Dictionary in RENEWABLE_SITES.additional_materials_for(realm):
		var id := str(spec["id"])
		if _mounted.has(id) and is_instance_valid(_mounted[id]):
			continue
		var stock: Variant = state.call("renewable_stock_state", realm, id)
		if not stock is Dictionary or stock.is_empty():
			_refusals[id] = "Host site is not registered."
			continue
		if not _items_registered(spec, items):
			_refusals[id] = "Canonical inventory items are not registered."
			continue
		var model := str(spec["model"])
		if not ResourceLoader.exists(model) or not load(model) is PackedScene:
			_refusals[id] = "Installed resource model is unavailable."
			continue
		var verdict := placement_verdict(world, spec, trainer, tuning)
		if not bool(verdict.get("ok", false)):
			_refusals[id] = str(verdict.get("reason", "Placement unavailable."))
			continue
		if realm == "water" and not _additional_water_dry(world, verdict["position"], tuning):
			_refusals[id] = "Actual baked terrain and live water surface do not establish a dry Pearl bed."
			continue
		# Declared proof and this body query do not substitute for the earned
		# player route or actual Water depth/approach witness before enablement.
		var node := HARVEST.new()
		node.name = id.replace(":", "_")
		add_child(node)
		node.global_position = verdict["position"]
		node.call("setup", CATALOGUE.harvest_spec(spec, stock))
		_mounted[id] = node
		_refusals.erase(id)
	return census()


## Conservative dry-only Pearl beds: use the actual live WaterSurface plane
## and actual ground_height_at (baked Terrain3D), never WaterHeightfield's
## analytic height_at or an anchor's historical sampled height. Missing sea,
## transformed/non-planar surface, submerged/slope-neighbour ground refuses.
## This bounds the local placement only; it does not prove an approach route.
static func _additional_water_dry(world: Node3D, at: Vector3, tuning: Dictionary) -> bool:
	var surface := world.get_node_or_null(^"WaterSurface") as MeshInstance3D
	if surface == null or not surface.is_inside_tree() or not surface.mesh is PlaneMesh \
			or not surface.global_transform.basis.is_equal_approx(Basis.IDENTITY):
		return false
	var plane := surface.mesh as PlaneMesh
	# Geometry orientation/offset can differ even with identity node basis.
	# Existing WaterSurface builds the default FACE_Y, zero-offset plane.
	if plane.orientation != PlaneMesh.FACE_Y or plane.center_offset != Vector3.ZERO \
			or not plane.size.is_finite() or plane.size.x <= 0.0 or plane.size.y <= 0.0 \
			or not surface.global_position.is_finite() or not at.is_finite():
		return false
	var local := surface.to_local(at)
	if absf(local.x) > plane.size.x * 0.5 or absf(local.z) > plane.size.y * 0.5:
		return false
	var sea := surface.global_position.y
	if not is_finite(sea) or at.y < sea:
		return false
	var step := maxf(0.1, float(tuning.get("slope_sample_m", 0.75)))
	for offset: Vector2 in [Vector2(step, 0), Vector2(-step, 0), Vector2(0, step), Vector2(0, -step)]:
		var ground := float(world.call("ground_height_at", at.x + offset.x, at.z + offset.y))
		if not is_finite(ground) or ground < sea:
			return false
	return true

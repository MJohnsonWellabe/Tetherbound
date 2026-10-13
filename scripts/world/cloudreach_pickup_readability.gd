extends RefCounted

## Named Cloudreach presentations only. Cache ownership, placement and collision
## remain with the physical runtime. No camera-dependent dressing or new marks.
const CONFIG := "res://data/config/cloudreach_pickup_readability.json"
const REGIONAL_CONFIG := "res://data/config/candy_pickup_presentation.json"
const GLOW := preload("res://scripts/world/pickup_glow.gd")
const TIERS := preload("res://scripts/world/band_pickups.gd")
const APPLIED := &"cloudreach_pickup_readability_applied"


static func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary:
		return {}
	var cfg := parsed as Dictionary
	if bool(cfg.get("enabled", false)) or _f40_candidate_preview():
		return cfg
	return {}


static func _f40_candidate_preview() -> bool:
	if not OS.get_cmdline_user_args().has("--f40-candidate"):
		return false
	for argument: String in OS.get_cmdline_args():
		if argument in ["res://tools/capture_cloudreach_f40_matrix.gd",
				"tools/capture_cloudreach_f40_matrix.gd",
				"res://tools/capture_cloudreach_f40_fight.gd",
				"tools/capture_cloudreach_f40_fight.gd"]:
			return true
	return false


static func apply(pickup: Node3D, item_id: String, definition: Dictionary, id: String) -> void:
	var cfg := _config()
	if cfg.is_empty():
		return
	var spec: Dictionary = cfg.get("pickups", {}).get(id, {})
	if spec.is_empty() or bool(spec.get("preserve", false)) or pickup.has_meta(APPLIED):
		return
	if str(spec.get("item_id", "")) != item_id:
		push_error("Cloudreach pickup presentation identity mismatch: " + id)
		return
	var body := TIERS._first_mesh(pickup)
	if body == null or body.mesh == null:
		return
	if bool(spec.get("remove_regional_lift", false)):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGIONAL_CONFIG))
		if parsed is Dictionary and bool(parsed.get("enabled", false)):
			var lift := float(parsed.get("regional_tiers", {}).get(item_id, {}).get("lift_m", 0.0))
			# Invert the regional adapter's body-only lift. Keep the existing
			# ring at its current world position; never use it as a body bound.
			var parent_scale := 1.0
			var parent := body.get_parent()
			while parent is Node3D and parent != pickup:
				parent_scale *= absf((parent as Node3D).scale.y)
				parent = parent.get_parent()
			var local_lift := lift / maxf(parent_scale, 0.001)
			body.position.y -= local_lift
			var ring := body.get_node_or_null(^"TierRing") as Node3D
			if ring != null:
				ring.position.y += local_lift / maxf(absf(body.scale.y), 0.001)
	if spec.has("body_emission"):
		_emission(body, float(spec.body_emission))
		for child in body.get_children():
			if child is MeshInstance3D:
				if child.name == &"TierRing":
					_emission(child, float(spec.get("ring_emission", 0.0)))
				elif child.name == &"TierMedallion" or str(child.name).begins_with("Sparkle"):
					_emission(child, float(spec.get("detail_emission", 0.35)))
	if spec.has("glow_scale"):
		# The shared API re-registers one existing highlight. Its positive
		# radius preserves discovery light but confines wash to the object.
		# This is the regional candy adapter's exact badge colour source,
		# also used by the item DB for potion/mushroom discovery highlights.
		GLOW.attach(pickup, Color(str(definition.get("colour", "#ffffff"))),
			-1.0, float(spec.glow_scale))
	pickup.set_meta(APPLIED, id)


static func _emission(mesh: MeshInstance3D, energy: float) -> void:
	var material := mesh.material_override as StandardMaterial3D
	if material == null:
		return
	material = material.duplicate() as StandardMaterial3D
	material.emission_energy_multiplier = energy
	material.emission_enabled = energy > 0.0
	mesh.material_override = material


## Post-filter decorative instances after the normal generator finishes. Adding
## exclusions before sampling would consume RNG differently and move retained
## grass elsewhere. Copy retained buffer runs verbatim, in their original order.
static func clear_cover(cover: Node3D, build_budget: RefCounted = null) -> void:
	var cfg := _config()
	if cfg.is_empty():
		return
	var zones: Array[Dictionary] = []
	for id: String in cfg.get("pickups", {}):
		var spec: Dictionary = cfg.pickups[id]
		if float(spec.get("cover_radius_m", 0.0)) > 0.0:
			zones.append(spec)
	var removed := 0
	for node in cover.find_children("*", "MultiMeshInstance3D", true, false):
		var field := node as MultiMeshInstance3D
		var original := field.multimesh
		if original == null or original.mesh == null or original.instance_count == 0:
			continue
		var nearby: Array[Dictionary] = []
		# Current production cover's maximum shader displacement is below
		# this broad-phase margin. The per-instance check uses its own basis.
		var bounds: AABB = (field.global_transform * original.get_aabb()).grow(
			float(cfg.get("cover_broadphase_margin_m", 4.0)))
		for zone in zones:
			if _overlaps(bounds, zone, float(cfg.get("cover_vertical_reach_m", 2.0))):
				nearby.append(zone)
		if nearby.is_empty():
			continue
		var buffer := original.buffer
		var stride := int(buffer.size() / float(original.instance_count))
		var retained := PackedFloat32Array()
		var run_start := 0
		var kept := 0
		var visible_kept := 0
		var mesh_bounds := original.mesh.get_aabb().grow(float(cfg.get("cover_shader_padding_local_m", 0.42)))
		for index in original.instance_count:
			var at: Transform3D = field.global_transform * original.get_instance_transform(index)
			var occupied: AABB = at * mesh_bounds
			var discard := false
			for zone in nearby:
				if _overlaps(occupied, zone, float(cfg.get("cover_vertical_reach_m", 2.0))):
					discard = true
					break
			if discard:
				retained.append_array(buffer.slice(run_start * stride, index * stride))
				run_start = index + 1
			else:
				kept += 1
				if index < original.visible_instance_count:
					visible_kept += 1
			if index % 2048 == 2047 and build_budget != null:
				await build_budget.call("breathe")
		if kept == original.instance_count:
			continue
		retained.append_array(buffer.slice(run_start * stride))
		var filtered := MultiMesh.new()
		filtered.transform_format = original.transform_format
		filtered.use_colors = original.use_colors
		filtered.use_custom_data = original.use_custom_data
		filtered.mesh = original.mesh
		filtered.instance_count = kept
		if kept > 0:
			filtered.buffer = retained
		filtered.visible_instance_count = -1 if original.visible_instance_count < 0 else visible_kept
		field.multimesh = filtered
		field.set_meta("cloudreach_pickup_cover_removed", original.instance_count - kept)
		removed += original.instance_count - kept
		if build_budget != null:
			await build_budget.call("breathe")
	cover.set_meta("cloudreach_pickup_cover_removed", removed)


static func _overlaps(bounds: AABB, zone: Dictionary, vertical_reach: float) -> bool:
	var p: Array = zone["position"]
	var centre := Vector3(float(p[0]), float(p[1]), float(p[2]))
	if bounds.end.y < centre.y - vertical_reach or bounds.position.y > centre.y + vertical_reach:
		return false
	var nearest := Vector2(clampf(centre.x, bounds.position.x, bounds.end.x),
		clampf(centre.z, bounds.position.z, bounds.end.z))
	return nearest.distance_squared_to(Vector2(centre.x, centre.z)) <= pow(float(zone.cover_radius_m), 2.0)

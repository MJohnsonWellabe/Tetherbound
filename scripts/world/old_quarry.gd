extends Node3D

## SD16 — the Old Quarry, spec §3 Band 2 and §32 rung 2.
##
## Reachable past the South Bridge (`SC14`), the first place the player works
## Rootstone out of the ground, and the first physical evidence that Team
## Tether is routing something out from under the region.
##
## HARD RULE, from §32's reveal ladder and the backlog item: this is EVIDENCE,
## not explanation. Nothing here talks. There is no interactable on the
## hardware, no note, no villager standing by to say what it is. The player
## gets a working face somebody walked away from, foundations older than the
## village, ground that is visibly dying around the machinery, and a line of
## lit pylons leaving on the stronghold's own bearing — and draws their own
## conclusion, which is the one thing the relay (`SE23`) and the stronghold
## cannot do for them later if it is spent here.
##
## This file places the authored built elements that belong to the quarry itself:
##
##   * the old foundations, from the `quarry_foundation` prefab — the same
##     Medieval kit the village is built from (D24), sunk so only the bottom
##     course stands.
##   * the conduit run, by calling `severed_spokes.gd`'s own pylon builder.
##   * one modeled shift lantern and a visual-only supported end treatment for
##     the retained foundation slab. Neither adds gameplay collision.
##
## Everything else about the quarry is owned by the file that already owns
## that kind of thing, and is listed in `data/config/old_quarry.json`'s header:
## the terrain and the drain radii are `terrain_playground.json`, the thinned
## and dying vegetation is `vegetation.json`, the Rootstone deposits are
## `harvest.json` (placed by `playground_world.gd` like every other harvest
## node), the abandoned gear is `props.json`'s `quarry_station` cluster, and
## the named region on the map is `map_landmarks.json`.
##
## WHY THE PYLONS ARE NOT REBUILT HERE. `severed_spokes.gd::_build_pylons`
## already does mesh fitting, per-pylon lit/dead materials, aim-along-the-line
## orientation, box colliders and the sampled-parabola conduit spans between
## consecutive pylons — roughly a hundred lines that took a render pass and a
## material bug (`gl_compatibility` turning an emissive pylon into a white
## ghost) to get right. A second implementation would be a second set of those
## bugs. So an instance of that script is parented here as the holder and
## handed this quarry's own `pylons` block in the shape it already reads. The
## grammar is identical on purpose (D41: one drain network, one visual
## language); only the STATE differs, and that difference is the story —
## severed and dead at the seven spokes, whole and lit here.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const CONFIG_PATH := "res://data/config/old_quarry.json"

var _foundations := 0
var _pylons := 0
var _work_lights := 0
var _foundation_finishes := 0
var _worked_cut_pieces := 0
var _arrival_scatter_removed := 0


## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb `village.gd`, `road_gate.gd` and `severed_spokes.gd` use (D09: never
## a raycast for ground).
func build(world: Node3D) -> void:
	var config := _load_config()
	if config.is_empty():
		push_warning("old_quarry.json missing or unreadable; the quarry has no foundations or hardware")
		return

	_clear_arrival_sightline(world, config.get("arrival_scatter_clear", {}))
	_build_foundations(world, config.get("foundations", []))
	_build_worked_cut(world, config.get("worked_cut", {}))
	_build_foundation_finish(world, config.get("foundation_finish", []))
	_build_work_lights(world, config.get("work_lights", []))
	_build_conduit_run(world, config.get("pylons", {}))
	print("[quarry] %d foundations, %d pylons, %d finish treatment standing" % [
		_foundations, _pylons, _foundation_finishes])


## For tests and capture tools: what actually stood, so neither has to count
## nodes by name.
func stats() -> Dictionary:
	return {
		"foundations": _foundations,
		"pylons": _pylons,
		"work_lights": _work_lights,
		"foundation_finishes": _foundation_finishes,
		"worked_cut_pieces": _worked_cut_pieces,
		"arrival_scatter_removed": _arrival_scatter_removed,
	}


## R22's continuous exposed skin follows the measured south-front envelope of
## the retained imported-rock OBBs, not their misleading placement anchors.
## Those installed rocks remain visible around the crown and keep
## all production collision; this visual-only face adds no second route authority.
## Overlapping bays, courses and projecting benches read as repeated carved passes
## and physically hand down to the wagon apron instead of forming another mound.
func _build_worked_cut(world: Node, raw: Variant) -> void:
	if not raw is Dictionary:
		return
	var spec := raw as Dictionary
	var pieces := spec.get("pieces", []) as Array
	if pieces.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "OldQuarryWorkedCut"
	add_child(holder)
	var texture_path := str(spec.get("albedo_texture", ""))
	var normal_path := str(spec.get("normal_texture", ""))
	for raw_piece: Variant in pieces:
		if not raw_piece is Dictionary:
			continue
		var piece := raw_piece as Dictionary
		var at_raw := piece.get("at", []) as Array
		var size_raw := piece.get("size", []) as Array
		if at_raw.size() != 2 or size_raw.size() != 3:
			continue
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground) or is_inf(ground):
			continue
		var size := Vector3(float(size_raw[0]), float(size_raw[1]), float(size_raw[2]))
		var centre := Vector3(at.x, ground + float(piece.get("lift_m", size.y * 0.5)), at.y)
		var instance := _textured_box(str(piece.get("name", "WorkedCutPiece")), size,
			Color(str(piece.get("colour", "#a49a82"))), texture_path, normal_path)
		instance.position = centre
		instance.rotation.y = deg_to_rad(float(piece.get("yaw_deg", 0.0)))
		holder.add_child(instance)
		_worked_cut_pieces += 1


func _textured_box(node_name: String, size: Vector3, colour: Color,
		texture_path: String, normal_path: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.94
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.uv1_triplanar = true
	material.uv1_world_triplanar = false
	material.uv1_scale = Vector3.ONE * 0.42
	if ResourceLoader.exists(texture_path):
		material.albedo_texture = load(texture_path)
	if ResourceLoader.exists(normal_path):
		material.normal_enabled = true
		material.normal_texture = load(normal_path)
		material.normal_scale = 0.55
	mesh.material = material
	instance.mesh = mesh
	return instance


## The band clearing is still the offline authority, but the inherited bake
## fingerprint does not include band-local clearings. Remove only the stale
## final-threshold scatter at runtime, using Vegetation's existing exact-instance
## path, so the ordinary approach cannot be bisected by a mature tree again.
func _clear_arrival_sightline(world: Node, spec: Variant) -> void:
	if not spec is Dictionary:
		return
	var at_raw := (spec as Dictionary).get("at", []) as Array
	var radius := float((spec as Dictionary).get("radius_m", 0.0))
	if at_raw.size() != 2 or radius <= 0.0:
		return
	var vegetation := world.get_node_or_null(^"Vegetation")
	if vegetation == null or not vegetation.has_method("clear_area"):
		return
	var at := Vector2(float(at_raw[0]), float(at_raw[1]))
	_arrival_scatter_removed = int(vegetation.call("clear_area",
		Vector3(at.x, float(world.call("ground_height_at", at.x, at.y)), at.y), radius))


## Complete the exposed end of the retained foundation with a shallow stone cap
## and two timber crib rails. These are visual finish pieces inside the prefab's
## existing footprint: the prefab remains the sole collision/route authority.
func _build_foundation_finish(world: Node, list: Array) -> void:
	var holder := Node3D.new()
	holder.name = "OldQuarryFoundationFinish"
	add_child(holder)
	for raw: Variant in list:
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at_raw := spec.get("at", []) as Array
		if at_raw.size() != 2:
			continue
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground) or is_inf(ground):
			continue
		var finish := Node3D.new()
		finish.name = "SupportedSlabEnd%02d" % (_foundation_finishes + 1)
		finish.position = Vector3(at.x, ground, at.y)
		finish.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		holder.add_child(finish)
		var width := clampf(float(spec.get("width_m", 5.8)), 4.0, 6.5)
		_visual_box(finish, "StoneEndCap", Vector3(width, 0.42, 0.62),
			Vector3(0.0, 0.22, 2.25), Color("#777568"), 0.96)
		for side in [-1.0, 1.0]:
			_visual_box(finish, "TimberCribPost", Vector3(0.24, 1.15, 0.24),
				Vector3(side * (width * 0.42), 0.57, 2.0), Color("#5f4028"), 0.88)
		_visual_box(finish, "TimberCribRail", Vector3(width * 0.9, 0.20, 0.26),
			Vector3(0.0, 0.76, 2.0), Color("#765034"), 0.86)
		_foundation_finishes += 1


## One presentation-only shift lantern restores a warm work hierarchy at night.
## It is intentionally not a camp or interaction and owns no StaticBody; the
## quarry's existing foundations, props and pylon builder remain authoritative.
func _build_work_lights(world: Node, list: Array) -> void:
	var holder := Node3D.new()
	holder.name = "OldQuarryWorkLights"
	add_child(holder)
	for raw: Variant in list:
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at_raw := spec.get("at", []) as Array
		if at_raw.size() != 2:
			continue
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground) or is_inf(ground):
			continue
		var height := clampf(float(spec.get("height_m", 2.8)), 2.2, 3.2)
		var fixture := Node3D.new()
		fixture.name = "WorkLantern%02d" % (_work_lights + 1)
		fixture.position = Vector3(at.x, ground, at.y)
		holder.add_child(fixture)
		_visual_box(fixture, "TimberPost", Vector3(0.16, height, 0.16),
			Vector3(0.0, height * 0.5, 0.0), Color("#493528"), 0.9)
		_visual_box(fixture, "IronArm", Vector3(0.82, 0.09, 0.09),
			Vector3(0.32, height - 0.12, 0.0), Color("#282522"), 0.72)
		var cage := WALL_LANTERN.instantiate() as Node3D
		if cage != null:
			cage.name = "LanternCage"
			cage.position = Vector3(0.62, height - 0.52, 0.0)
			cage.scale = Vector3.ONE * 0.44
			IMPORTED_MATERIALS.make_dielectric(cage)
			fixture.add_child(cage)
		var colour := Color(str(spec.get("colour", "#ffb867")))
		var lens := MeshInstance3D.new()
		lens.name = "VisibleAmberSource"
		var lens_mesh := SphereMesh.new()
		lens_mesh.radius = 0.075
		lens_mesh.height = 0.15
		var lens_material := StandardMaterial3D.new()
		lens_material.albedo_color = colour
		lens_material.emission_enabled = true
		lens_material.emission = colour
		lens_material.emission_energy_multiplier = clampf(
			float(spec.get("source_emission", 1.35)), 1.0, 1.8)
		lens_mesh.material = lens_material
		lens.mesh = lens_mesh
		lens.position = Vector3(0.62, height - 0.42, 0.10)
		fixture.add_child(lens)
		var light := OmniLight3D.new()
		light.name = "WarmWorkPool"
		light.position = lens.position
		light.light_color = colour
		light.light_energy = clampf(float(spec.get("energy", 2.0)), 0.5, 2.4)
		light.omni_range = clampf(float(spec.get("range_m", 10.5)), 4.0, 11.0)
		light.omni_attenuation = clampf(float(spec.get("attenuation", 1.45)), 1.0, 1.45)
		light.shadow_enabled = false
		fixture.add_child(light)
		_work_lights += 1


func _visual_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color, roughness: float) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	mesh.material = material
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)


func _build_foundations(world: Node3D, list: Array) -> void:
	if list.is_empty():
		return
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the quarry has no foundations")
		return
	# See building_prefabs.gd's header on `_holder`: an un-parented template
	# tree leaks RenderingServer resources at engine shutdown, which reached an
	# exported build once as a heap-corrupting SIGABRT.
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)

	for entry: Variant in list:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var at: Array = spec.get("at", [])
		if at.size() < 2:
			push_warning("a quarry foundation has no `at` — skipped")
			continue
		var x := float(at[0])
		var z := float(at[1])
		var ground: float = float(world.call("ground_height_at", x, z))
		if is_nan(ground):
			push_error("no ground under a quarry foundation at %.0f, %.0f" % [x, z])
			continue
		var prefab_name := str(spec.get("prefab", "quarry_foundation"))
		var ruin: Node3D = prefabs.call("instantiate", prefab_name)
		if ruin == null:
			push_error("quarry foundation prefab missing: %s" % prefab_name)
			continue
		ruin.name = "Foundation_%d" % _foundations
		# Sunk the same 0.05m village.gd sinks its own structures: a building
		# seated exactly on a sampled height hovers on any residual slope.
		ruin.position = Vector3(x, ground - 0.05, z)
		ruin.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		add_child(ruin)
		_collide(prefabs, ruin, prefab_name)
		_foundations += 1


## The prefab's own authored collider boxes, in its local frame — the same
## walk `village.gd::_collide` does, and for its reason: a wall you can walk
## through is a hologram. No AABB fallback here on purpose. A ruin's combined
## AABB is a solid box the height of its tallest standing course and the full
## width of its floor slab, so falling back to one would seal the quarry's own
## floor behind an invisible crate; a prefab that authors no colliders should
## say so instead.
func _collide(prefabs: RefCounted, ruin: Node3D, prefab_name: String) -> void:
	var boxes: Array = prefabs.call("colliders", prefab_name)
	if boxes.is_empty():
		push_warning("prefab '%s' authors no colliders; its walls can be walked through" % prefab_name)
		return
	var body := StaticBody3D.new()
	body.name = "Collision"
	for entry: Variant in boxes:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var at: Array = spec.get("at", [0.0, 0.0, 0.0])
		var size: Array = spec.get("size", [1.0, 1.0, 1.0])
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
		shape.shape = box
		shape.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		body.add_child(shape)
	# A child of the ruin, so every box inherits its position and yaw.
	ruin.add_child(body)


## SF33's pylon run, borrowed rather than rewritten — see this file's header.
func _build_conduit_run(world: Node3D, pylons: Dictionary) -> void:
	var list: Array = pylons.get("list", [])
	if list.is_empty():
		return
	var builder: Node3D = SEVERED_SPOKES.new()
	builder.name = "TetherConduits"
	add_child(builder)
	# `_build_pylons` takes a spoke dictionary and reads only its `pylons`
	# key, so this quarry's own block goes in unchanged. Passing the builder
	# as its own holder keeps every pylon, collider and cable under one named
	# node in the scene tree.
	builder.call("_build_pylons", world, builder, {"pylons": pylons})
	_pylons = list.size()


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

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
## This file places two things and nothing else:
##
##   * the old foundations, from the `quarry_foundation` prefab — the same
##     Medieval kit the village is built from (D24), sunk so only the bottom
##     course stands.
##   * the conduit run, by calling `severed_spokes.gd`'s own pylon builder.
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
const CONFIG_PATH := "res://data/config/old_quarry.json"

var _foundations := 0
var _pylons := 0


## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb `village.gd`, `road_gate.gd` and `severed_spokes.gd` use (D09: never
## a raycast for ground).
func build(world: Node3D) -> void:
	var config := _load_config()
	if config.is_empty():
		push_warning("old_quarry.json missing or unreadable; the quarry has no foundations or hardware")
		return

	_build_foundations(world, config.get("foundations", []))
	_build_conduit_run(world, config.get("pylons", {}))
	print("[quarry] %d foundations, %d pylons standing" % [_foundations, _pylons])


## For tests and capture tools: what actually stood, so neither has to count
## nodes by name.
func stats() -> Dictionary:
	return {"foundations": _foundations, "pylons": _pylons}


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

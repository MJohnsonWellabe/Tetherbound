extends RefCounted

## F38 tier-1 new art (close-1024, OFF until judged): authored Meshy hero pieces
## placed in Meadows world coordinates -- the stratified cliffs that replace the
## read of the Burrow bank's faceted planes (P2-014, band2_stone_and_root_1)
## and the Ironwood hero trees (band4), plus any later group with `pieces`
## (the dominant-object assets). Each GLB is scaled uniformly to its
## `width_m`, stood on the terrain at its `at` (x, z) and buried by `sink_m`.
## Visual only: no collision, walkability, vegetation-placement or bake change.

const CONFIG := "res://data/config/meadows_hero_pieces.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


static func build(world: Node3D) -> int:
	var cfg := settings()
	var built := 0
	# Every block with `pieces` is a group under its own flag (cliffs, ironwood,
	# and each later dominant-object asset), so a new one is config only.
	for group: String in cfg.keys():
		if not (cfg[group] is Dictionary) or not (cfg[group] as Dictionary).has("pieces"):
			continue
		var block: Dictionary = cfg[group]
		if not bool(block.get("enabled", false)):
			continue
		for row: Dictionary in block.get("pieces", []):
			if _place(world, row, group):
				built += 1
	if built > 0:
		print("[hero_pieces] %d placed" % built)
	return built


## `clearings` (OFF until judged): authored glades cut out of the baked tree
## and rock scatter at run time through `vegetation.gd::clear_area`, the call
## the Warrens use to clear their own ground. A stand framed by a wall of
## trunks becomes a sunlit clearing with a grove edge. Runs inside the world's
## bulk-clear window, after the settlement has built. Every block with `spots`
## is a clearing group under its own flag (the Ridgeline glades, the stronghold
## sightline), like the `pieces` groups above.
static func clear(world: Node3D) -> int:
	var cfg := settings()
	var vegetation: Node = world.get_node_or_null(^"Vegetation")
	if vegetation == null or not vegetation.has_method("clear_area"):
		return 0
	var removed := 0
	for group: String in cfg.keys():
		if not (cfg[group] is Dictionary) or not (cfg[group] as Dictionary).has("spots"):
			continue
		var block: Dictionary = cfg[group]
		if not bool(block.get("enabled", false)):
			continue
		for spot: Dictionary in block.get("spots", []):
			var at: Array = spot.get("at", [0.0, 0.0])
			removed += int(vegetation.call("clear_area", Vector3(float(at[0]), 0.0, float(at[1])),
				float(spot.get("radius_m", 10.0))))
	if removed > 0:
		print("[hero_pieces] clearings removed %d scattered trees/rocks" % removed)
	return removed


static func _place(world: Node3D, row: Dictionary, group: String) -> bool:
	var scene := load(str(row.get("path", ""))) as PackedScene
	if scene == null:
		push_warning("hero piece: %s did not load" % row.get("path", ""))
		return false
	var model := scene.instantiate() as Node3D
	var holder := Node3D.new()
	holder.name = "HeroPiece_%s_%s" % [group, str(row.get("id", "piece"))]
	world.add_child(holder)
	# `pitch_deg` lays a piece modelled upright (the paving tile) flat; the fit
	# and the ground seat are measured after it, in the holder's frame.
	var pivot := Node3D.new()
	holder.add_child(pivot)
	pivot.add_child(model)
	pivot.rotation.x = deg_to_rad(float(row.get("pitch_deg", 0.0)))
	var bounds := RENDER_BOUNDS.measure(holder)
	if bounds.size.x <= 0.001:
		holder.queue_free()
		return false
	var fit := float(row.get("width_m", 10.0)) / bounds.size.x
	pivot.scale = Vector3.ONE * fit
	pivot.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * fit
	# `height_m` flattens a piece vertically (the paving tile is about a quarter
	# as thick as it is wide); the holder only yaws, so its y stays world-up.
	var flatten := 1.0
	if row.has("height_m") and bounds.size.y > 0.001:
		flatten = float(row["height_m"]) / (bounds.size.y * fit)
	var at: Array = row.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var ground := _ground(world, x, z)
	var basis := Basis(Vector3.UP, deg_to_rad(float(row.get("yaw_deg", 0.0))))
	# `conform` tilts a flat piece (a paving tile) to the ground under it, from
	# four samples at its half-width, so tiles follow a sloped yard instead of
	# stepping into floating slabs.
	if bool(row.get("conform", false)):
		var half := float(row.get("width_m", 10.0)) * 0.5
		var dx := (_ground(world, x + half, z) - _ground(world, x - half, z)) / (2.0 * half)
		var dz := (_ground(world, x, z + half) - _ground(world, x, z - half)) / (2.0 * half)
		var normal := Vector3(-dx, 1.0, -dz).normalized()
		basis = Basis(Quaternion(Vector3.UP, normal)) * basis
		ground = (_ground(world, x + half, z) + _ground(world, x - half, z)
			+ _ground(world, x, z + half) + _ground(world, x, z - half)) * 0.25
	holder.transform = Transform3D(basis * Basis.from_scale(Vector3(1.0, flatten, 1.0)),
		Vector3(x, ground - float(row.get("sink_m", 0.0)), z))
	return true


static func _ground(world: Node3D, x: float, z: float) -> float:
	return float(world.call("ground_height_at", x, z)) if world.has_method("ground_height_at") else 0.0

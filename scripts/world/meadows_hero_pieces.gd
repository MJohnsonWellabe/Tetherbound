extends RefCounted

## F38 tier-1 new art (close-1024, OFF until judged): authored Meshy hero pieces
## placed in Meadows world coordinates -- the stratified cliffs that replace the
## read of the Burrow bank's faceted planes (P2-014, band2_stone_and_root_1)
## and the Ironwood hero trees (band4). Each GLB is scaled uniformly to its
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
	for group: String in ["cliffs", "ironwood"]:
		var block: Dictionary = cfg.get(group, {})
		if not bool(block.get("enabled", false)):
			continue
		for row: Dictionary in block.get("pieces", []):
			if _place(world, row, group):
				built += 1
	if built > 0:
		print("[hero_pieces] %d placed" % built)
	return built


static func _place(world: Node3D, row: Dictionary, group: String) -> bool:
	var scene := load(str(row.get("path", ""))) as PackedScene
	if scene == null:
		push_warning("hero piece: %s did not load" % row.get("path", ""))
		return false
	var model := scene.instantiate() as Node3D
	var holder := Node3D.new()
	holder.name = "HeroPiece_%s_%s" % [group, str(row.get("id", "piece"))]
	world.add_child(holder)
	holder.add_child(model)
	var bounds := RENDER_BOUNDS.measure(model)
	if bounds.size.x <= 0.001:
		holder.queue_free()
		return false
	var fit := float(row.get("width_m", 10.0)) / bounds.size.x
	model.scale = Vector3.ONE * fit
	model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * fit
	var at: Array = row.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var ground := float(world.call("ground_height_at", x, z)) if world.has_method("ground_height_at") else 0.0
	holder.position = Vector3(x, ground - float(row.get("sink_m", 0.0)), z)
	holder.rotation.y = deg_to_rad(float(row.get("yaw_deg", 0.0)))
	return true

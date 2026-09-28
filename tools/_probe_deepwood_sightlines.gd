extends SceneTree
## F10#4: eye-level sight lines through the Deepwood dense stands, from the
## committed scatter placement pass. Each trunk is a circle of its collider
## radius x scale (the trunk's own footprint). For each stand, a fan of rays at
## eye level reports the distance to the first trunk (capped at 400 m).
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const STANDS := [
	["heart_north_r5", Vector2(-350, 4330), Vector2(-300, 4420)],
	["heart_west_r6", Vector2(-330, 4200), Vector2(-500, 4230)],
	["road_r6", Vector2(-600, 4140), Vector2(-780, 4360)],
	["heart_centre_east", Vector2(-330, 4260), Vector2(-100, 4260)],
	["west_centre_south", Vector2(-900, 4300), Vector2(-900, 4000)],
]
func _init() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json"))
	var cfg: Dictionary = SCATTER.config()
	var placed: Dictionary = SCATTER.placements(FIELD.new(), world)
	var trunks: Array = []
	for layer: String in placed:
		var spec: Dictionary = cfg.layers.get(layer, {})
		if not (layer.contains("canopy") or layer == "storm_deadwood"):
			continue
		for p: Variant in placed[layer]:
			var at: Vector2
			var sc := 1.0
			if p is Dictionary:
				var pos: Vector3 = p.position
				at = Vector2(pos.x, pos.z)
				sc = float(p.get("scale", 1.0))
			elif p is Transform3D:
				at = Vector2(p.origin.x, p.origin.z)
				sc = p.basis.get_scale().x
			else:
				continue
			trunks.append([at, float(spec.get("collision_radius", 0.6)) * sc])
	print("DEEPWOOD trunks ", trunks.size())
	for stand: Array in STANDS:
		var from: Vector2 = stand[1]
		var ahead: Vector2 = (stand[2] - from).normalized()
		var near := trunks.filter(func(t: Array) -> bool: return (t[0] as Vector2).distance_to(from) < 420.0)
		var hits: Array[float] = []
		for deg in range(-30, 31, 3):
			var dir := ahead.rotated(deg_to_rad(deg))
			var best := 400.0
			for t: Array in near:
				var rel: Vector2 = (t[0] as Vector2) - from
				var along := rel.dot(dir)
				if along <= 0.0 or along > best:
					continue
				if absf(rel.cross(dir)) <= float(t[1]):
					best = along
			hits.append(best)
		var sorted := hits.duplicate()
		sorted.sort()
		var open := hits.filter(func(d: float) -> bool: return d >= 120.0).size()
		print("STAND %s trunks_within_420m=%d first-hit median=%.0f m, rays_open_past_120m=%d/%d, per-ray=%s" % [
			stand[0], near.size(), sorted[sorted.size() / 2], open, hits.size(), str(hits.map(func(d: float) -> int: return int(d)))])
	quit()

extends RefCounted

const LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")

## An occupied upper street, interpreting the Sky Aviary board's inhabited
## stone ledges with the installed village masonry/timber family.
## Existing services and the northeast route stay on the original lower court.
static func build(world: Node3D, root: Node3D, cfg: Dictionary, materials: Dictionary) -> void:
	var height := float(cfg.get("height_m", 4.2))
	var front := float(cfg.get("front_z", 16.0))
	var back := float(cfg.get("back_z", 28.0))
	var west := float(cfg.get("west_x", -13.4))
	var east := float(cfg.get("east_x", 15.0))
	var depth := back - front
	var width := east - west
	var middle := Vector3((west + east) * 0.5, 0, (front + back) * 0.5)
	var stone: Material = materials["masonry"].duplicate()
	if stone is ShaderMaterial:
		stone.set_shader_parameter("tile", float(cfg.get("masonry_tile", 0.62)))
	var trim: Material = materials["stone_light"]
	var wood: Material = materials["weathered_timber"]
	# Closed support reaches into the existing cliff; its roof is a real floor.
	world.call("_box", root, "OccupiedUpperStreet", middle + Vector3(0, (height - 12.0) * 0.5, 0),
		Vector3(width, height + 12.0, depth), stone, true)
	world.call("_box", root, "UpperStreetCoping", middle + Vector3(0, height - 0.12, 0),
		Vector3(width + 0.24, 0.24, depth + 0.24), trim, false)
	# Projecting stone piers make the retaining face structural at court range.
	for t: float in [0.0, 0.33, 0.66, 1.0]:
		var x := lerpf(west + 0.45, east - 0.45, t)
		world.call("_box", root, "StreetRetainingPier", Vector3(x, height * 0.5 - 0.35, front - 0.28),
			Vector3(0.85, height + 0.7, 0.9), trim, false)
		world.call("_box", root, "StreetPierCap", Vector3(x, height + 0.1, front - 0.3),
			Vector3(1.12, 0.24, 1.12), trim, false)
	for z: float in [front + 0.5, (front + back) * 0.5, back - 0.5]:
		world.call("_box", root, "EastStreetPier", Vector3(east + 0.2, height * 0.5 - 0.35, z),
			Vector3(0.8, height + 0.7, 0.85), trim, false)
	# A clear crossing beneath the raised stair preserves the watch path at z14.
	var stair_x := float(cfg.get("stair_x", -11.0))
	var stair_start := float(cfg.get("stair_start_z", 6.0))
	var stair_width := float(cfg.get("stair_width_m", 3.2))
	var count := 28
	var run := (front - stair_start) / count
	for i in count:
		var top := height * float(i + 1) / count
		world.call("_box", root, "UpperStreetTread%02d" % i,
			Vector3(stair_x, top - 0.12, stair_start + run * (i + 0.5)),
			Vector3(stair_width, 0.24, run + 0.025), stone, false)
	# Continuous inclined collision permits controller walking without jumping
	# every riser. The visible stair differs by at most one 15cm riser.
	world.call("_segment_box", root, "UpperStreetStairSupport",
		Vector3(stair_x, 0.0, stair_start), Vector3(stair_x, height, front),
		stair_width, 0.20, stone, true)
	(world.get("_surfaces") as Array).append({"kind":"segment",
		"a":root.to_global(Vector3(stair_x, 0.0, stair_start)),
		"b":root.to_global(Vector3(stair_x, height, front)), "half_width":stair_width * 0.5})
	for side: float in [-1.0, 1.0]:
		for i in 6:
			var t := float(i) / 5.0
			var foot := Vector3(stair_x + side * (stair_width * 0.5 - 0.1), height * t,
				lerpf(stair_start, front, t))
			world.call("_box", root, "StairBaluster", foot + Vector3.UP * 0.55,
				Vector3(0.14, 1.1, 0.14), wood, false)
		world.call("_segment_box", root, "StairHandrail",
			Vector3(stair_x + side * 1.5, 1.1, stair_start),
			Vector3(stair_x + side * 1.5, height + 1.1, front), 0.17, 0.16, wood, true)
	# Contiguous front rail with a single deliberate stair opening.
	for interval: Vector2 in [Vector2(west, stair_x - stair_width * 0.5),
		Vector2(stair_x + stair_width * 0.5, east)]:
		if interval.y - interval.x < 0.2:
			continue
		for y: float in [0.45, 1.0]:
			world.call("_box", root, "StreetGuardrail", Vector3((interval.x + interval.y) * 0.5,
				height + y, front + 0.1), Vector3(interval.y - interval.x, 0.15, 0.17), wood, true)
		var posts := maxi(1, ceili((interval.y - interval.x) / 2.8))
		for i in posts + 1:
			world.call("_box", root, "StreetGuardPost", Vector3(lerpf(interval.x, interval.y, float(i) / posts),
				height + 0.57, front + 0.1), Vector3(0.18, 1.14, 0.18), wood, false)
	# Warm pools have visible installed sources and serve actual gathering areas.
	for at: Vector3 in [Vector3(-3.0, height, front + 0.9), Vector3(east - 1.0, height, front + 1.0),
		Vector3(stair_x - 2.2, 0.14, stair_start - 0.8)]:
		world.call("_box", root, "StreetLampPost", at + Vector3.UP * 1.5,
			Vector3(0.20, 3.0, 0.20), wood, true)
		world.call("_install_prop_scene", root, LANTERN, "StreetLantern", at + Vector3(0, 2.05, -0.28), 0.75, 0.0)
		var light := OmniLight3D.new()
		light.name = "StreetLanternLight"
		light.position = at + Vector3(0, 2.38, -0.4)
		light.light_color = Color("#ffb478")
		light.light_energy = 3.0
		light.omni_range = 13.0
		root.add_child(light)
	# Register the upper floor for height-aware service/terrain queries.
	(world.get("_surfaces") as Array).append({"kind":"rect", "centre":Vector2(
		root.global_position.x + middle.x, root.global_position.z + middle.z),
		"half":Vector2(width,depth)*0.5, "height":root.global_position.y + height})
	(world.get("_cover_exclusions") as Array).append({"centre":root.global_position + middle,
		"half":Vector2(width,depth)*0.5 + Vector2.ONE*0.4, "rotation":0.0})

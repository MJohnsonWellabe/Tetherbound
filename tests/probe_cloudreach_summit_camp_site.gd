extends SceneTree

## F07#3 (option a, #356): find flat, grounded camp ground near the summit
## threshold (100, 1160, 5350) for the moved summit bivouac. Casts real
## physics rays over a grid and reports candidates whose 9 m x 9 m footprint
## is grounded within a small height spread, clear of the arena approach, and
## on the world's analytic ground (`ground_height_near`, which camp placement uses).
##
##   godot --headless --path . --script tests/probe_cloudreach_summit_camp_site.gd

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const CENTRE := Vector3(100.0, 1160.0, 5350.0)
const FLAGS: Array[String] = ["cloudreach_chapter_started", "fly_traversal_unlocked", "sky_shrine_reached",
	"cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled"]


func _init() -> void:
	_run.call_deferred()


func _ray(space: PhysicsDirectSpaceState3D, x: float, z: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, CENTRE.y + 60.0, z), Vector3(x, CENTRE.y - 80.0, z))
	return space.intersect_ray(query)


func _run() -> void:
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 30:
		await physics_frame
	var player: CharacterBody3D = world.get_node("Player")
	player.global_position = CENTRE + Vector3(0, 2, 0)
	for _frame in 60:
		await physics_frame
	var space := player.get_world_3d().direct_space_state
	var found: Array = []
	for dx in range(-120, 121, 4):
		for dz in range(-120, 41, 4):
			var cx := CENTRE.x + dx
			var cz := CENTRE.z + dz
			# Keep the arena approach (x 88..112, z > 5340) and the arena disc clear.
			if absf(cx - 100.0) < 14.0 and cz > 5338.0:
				continue
			if Vector2(cx - 100.0, cz - 5450.0).length() < 60.0:
				continue
			var heights: Array[float] = []
			var colliders: Dictionary = {}
			var ok := true
			for ox in [-4.5, 0.0, 4.5]:
				for oz in [-4.5, 0.0, 4.5]:
					var hit := _ray(space, cx + ox, cz + oz)
					if hit.is_empty():
						ok = false
						break
					heights.append(float((hit.position as Vector3).y))
					colliders[str((hit.collider as Node).name)] = true
				if not ok:
					break
			if not ok:
				continue
			var spread: float = heights.max() - heights.min()
			if spread > 1.2:
				continue
			var analytic := float(world.call("ground_height_near", Vector3(cx, heights[4], cz)))
			if is_nan(analytic) or absf(analytic - heights[4]) > 1.0:
				continue
			found.append({"at": [cx, snappedf(heights[4], 0.01), cz], "spread": snappedf(spread, 0.01), "analytic": snappedf(analytic, 0.01),
				"from_threshold_m": snappedf(Vector2(dx, dz).length(), 0.1), "colliders": colliders.keys()})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.from_threshold_m) < float(b.from_threshold_m))
	print("SUMMIT CAMP CANDIDATES " + JSON.stringify(found.slice(0, 40)))
	quit(0)

extends SceneTree

## Fast diagnostic, no camera/render: list every baked `bushes`-layer
## placement within `RANGE` of the known-occupied test site (0,700), with
## its distance, so the real clearance radius can be picked from real
## geometry instead of guessed. Quits as soon as the world is up -- no
## POSE_FRAMES, no screenshot.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_diag_bush_positions.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const SITE := Vector3(0.0, 0.0, 700.0)
const RANGE := 8.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var vegetation: Node = world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		print("FAIL: no Vegetation node")
		quit(1)
		return

	var bush_positions: PackedVector3Array = vegetation.get("_bush_positions")
	print("total bush placements in world: %d" % bush_positions.size())
	var nearby: Array = []
	for spot: Vector3 in bush_positions:
		var d := Vector2(spot.x - SITE.x, spot.z - SITE.z).length()
		if d <= RANGE:
			nearby.append([d, spot])
	nearby.sort_custom(func(a, b): return a[0] < b[0])
	print("bushes within %.1fm of (%.1f, %.1f):" % [RANGE, SITE.x, SITE.z])
	for entry: Array in nearby:
		print("  distance %.2fm at %s" % [entry[0], entry[1]])

	# Simulate the real retry algorithm at several candidate radii AND cluster
	# sizes, same rng draw shape encounter_director.gd uses. Real spawns.json
	# cluster radii range 0.0-22.0m, average ~13.7m (band1_lower_meadows) --
	# this probe's own earlier 2.0m stand-in was much tighter than a typical
	# real cluster, so also check a size nearer the real average.
	for cluster_radius: float in [2.0, 8.0]:
		for test_radius: float in [0.8, 1.2, 1.5]:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("spawn_siting_probe")
			var spot := SITE
			var attempts := 0
			for attempt in 6:
				attempts = attempt + 1
				if attempt == 0:
					spot = SITE
				else:
					var angle := rng.randf_range(0.0, TAU)
					var distance := cluster_radius * sqrt(rng.randf())
					spot = SITE + Vector3(sin(angle), 0.0, cos(angle)) * distance
				var clear := true
				for b: Vector3 in bush_positions:
					if Vector2(b.x - spot.x, b.z - spot.z).length() <= test_radius:
						clear = false
						break
				if clear:
					break
			var nearest := 999.0
			for b: Vector3 in bush_positions:
				nearest = minf(nearest, Vector2(b.x - spot.x, b.z - spot.z).length())
			print("cluster %.1f radius %.1f: picked after %d attempt(s) at %s, nearest bush %.2fm away" % [
				cluster_radius, test_radius, attempts, spot, nearest])

	quit(0)

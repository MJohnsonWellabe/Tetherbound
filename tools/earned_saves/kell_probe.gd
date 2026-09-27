extends SceneTree

## Read-only terrain probe for BLOCKERS.md B13: maps the ground between the
## village road start (8,90) and Kell (184.2,52.6). For each 4 m cell it prints
## one character: '~' ground below the Meadows water level, '#' a physics hit
## more than 1.2 m above the terrain (prop, wall, rock), '^' local slope over
## 40 degrees, '.' walkable. No save, no gameplay, nothing written.
##   godot --headless --path . --script tools/earned_saves/kell_probe.gd
const SCENE := "res://scenes/world/meadows_playground.tscn"
const STEP := 4.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null("Game")
	if game != null:
		game.call("reset_for_new_game")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _i in 120:
		await physics_frame
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var water := float((terrain.get("water", {}) as Dictionary).get("level", -1000.0))
	var space := world.get_world_3d().direct_space_state
	var player := world.get_node_or_null("Player") as CollisionObject3D
	var exclude: Array[RID] = []
	if player != null:
		exclude.append(player.get_rid())
	print("KELL PROBE water=%.1f rows z from -80 to 140, cols x from -20 to 240 step %.0f" % [water, STEP])
	var z := -80.0
	while z <= 140.0:
		var line := ""
		var x := -20.0
		while x <= 240.0:
			var h := float(world.call("ground_height_at", x, z))
			var hx := float(world.call("ground_height_at", x + 1.0, z))
			var hz := float(world.call("ground_height_at", x, z + 1.0))
			var slope := rad_to_deg(atan(Vector2(hx - h, hz - h).length()))
			var query := PhysicsRayQueryParameters3D.create(Vector3(x, h + 40.0, z), Vector3(x, h - 2.0, z))
			query.exclude = exclude
			var hit := space.intersect_ray(query)
			var c := "."
			if h < water:
				c = "~"
			elif not hit.is_empty() and (hit.position as Vector3).y > h + 1.2:
				c = "#"
			elif slope > 40.0:
				c = "^"
			if Vector2(x, z).distance_to(Vector2(184.2, 52.6)) < 3.0:
				c = "K"
			elif Vector2(x, z).distance_to(Vector2(8, 90)) < 3.0:
				c = "S"
			elif Vector2(x, z).distance_to(Vector2(74, -41)) < 3.0:
				c = "R"
			line += c
			x += STEP
		print("KELL PROBE z=%6.1f %s" % [z, line])
		z += STEP
	quit(0)

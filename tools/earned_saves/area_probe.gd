extends SceneTree

## Read-only terrain probe (area variant of kell_probe.gd, BLOCKERS.md B14):
## maps the ground in --x0/--x1/--z0/--z1 at --step metres. For each 4 m cell it prints
## one character: '~' ground below the Meadows water level, '#' a physics hit
## more than 1.2 m above the terrain (prop, wall, rock), '^' local slope over
## 40 degrees, '.' walkable. No save, no gameplay, nothing written.
##   godot --headless --path . --script tools/earned_saves/kell_probe.gd
const SCENE := "res://scenes/world/meadows_playground.tscn"
var STEP := 4.0
var X0 := -20.0
var X1 := 240.0
var Z0 := -80.0
var Z1 := 140.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() != 2: continue
		match kv[0]:
			"x0": X0 = float(kv[1])
			"x1": X1 = float(kv[1])
			"z0": Z0 = float(kv[1])
			"z1": Z1 = float(kv[1])
			"step": STEP = float(kv[1])
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
	print("AREA PROBE water=%.1f rows z %.0f..%.0f, cols x %.0f..%.0f step %.1f" % [water, Z0, Z1, X0, X1, STEP])
	var z := Z0
	while z <= Z1:
		var line := ""
		var x := X0
		while x <= X1:
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
			line += c
			x += STEP
		print("AREA PROBE z=%7.1f %s" % [z, line])
		z += STEP
	quit(0)

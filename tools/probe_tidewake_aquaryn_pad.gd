extends SceneTree

## F14#0 C3 (Aquaryn): COMBAT §5 wants a fight admitted on ground its arena
## fits. Samples the shipped Water heightfield around Aquaryn's spawn and
## prints the flattest 11 m discs within reach of it, with their height and
## distance from the Tidal Cradle arrival landing. Read-only.
##   godot --headless --path . --script tools/probe_tidewake_aquaryn_pad.gd

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const ARENA_R := 11.0
const SEARCH_R := 40.0
const STEP := 2.0
const LANDING := Vector2(535.497, 1352.51)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	var world: Node3D = WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1500:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var alpha: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_alpha.json"))
	var spawn := Vector2(float(alpha.placement.spawn[0]), float(alpha.placement.spawn[1]))
	var rows: Array = []
	var x := -SEARCH_R
	while x <= SEARCH_R:
		var z := -SEARCH_R
		while z <= SEARCH_R:
			var centre := spawn + Vector2(x, z)
			if Vector2(x, z).length() <= SEARCH_R:
				var h0 := float(world.call("ground_height_at", centre.x, centre.y))
				var worst := 0.0
				var lo := h0
				var hi := h0
				for ring: float in [4.0, 8.0, ARENA_R]:
					for k in 16:
						var a := TAU * float(k) / 16.0
						var p := centre + Vector2(cos(a), sin(a)) * ring
						var h := float(world.call("ground_height_at", p.x, p.y))
						worst = maxf(worst, absf(h - h0))
						lo = minf(lo, h)
						hi = maxf(hi, h)
				rows.append({"at": centre, "h": h0, "dev": worst, "span": hi - lo,
					"from_spawn": Vector2(x, z).length(), "from_landing": centre.distance_to(LANDING)})
			z += STEP
		x += STEP
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.span) < float(b.span))
	print("spawn %s h=%.2f" % [spawn, float(world.call("ground_height_at", spawn.x, spawn.y))])
	for row: Dictionary in rows.slice(0, 25):
		print("PAD at=(%.1f, %.1f) h=%.2f span=%.2f dev=%.2f from_spawn=%.1f from_landing=%.1f" % [
			row.at.x, row.at.y, row.h, row.span, row.dev, row.from_spawn, row.from_landing])
	quit(0)

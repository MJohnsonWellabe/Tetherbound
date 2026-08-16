extends SceneTree

## Throwaway probe (R8.2): what the ground actually does on the shoulder the
## stronghold route is built on, and where the terrain simply stops. Sampled,
## not guessed — the interior floor has to sit above every square metre of its
## own footprint or the hillside pokes up through a chamber floor, and a
## chamber sited off the edge of the heightfield has no ground at all.
##
##   godot --headless --path . --script tools/_probe_stronghold.gd

const SITE := Vector2(229.8, -144.4)  # landmark.gd's RISE_CENTRE + OFFSET


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load("res://scenes/world/meadows_playground.tscn") as PackedScene).instantiate()
	root.add_child(world)
	for i in 120:
		await physics_frame

	print("grid: rows are z, columns are x (124..252 step 8); '  --' means no ground")
	var header := "  z\\x "
	for ix in 17:
		header += "%6.0f" % (124.0 + float(ix) * 8.0)
	print(header)
	for iz in 10:
		var z := -166.0 - float(iz) * 8.0
		var line := "%6.0f" % z
		for ix in 17:
			var x := 124.0 + float(ix) * 8.0
			var h: float = float(world.call("ground_height_at", x, z))
			line += "    --" if is_nan(h) else "%6.1f" % h
		print(line)
	quit(0)

extends SceneTree

## Throwaway probe (T1-HALL-DESIGN, 2026-08-30): ground truth for the merged
## Meadows Hall site. Same 8m-grid method as tools/_probe_stronghold.gd (R8.2)
## and the GATE-E2 castle re-site, pointed at the corridor's own terminus --
## the ground the merged castle+works has to stand on, and the approach the
## player actually arrives along.
##
##   godot --headless --path . --script tools/_probe_hall_site.gd

func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load("res://scenes/world/meadows_playground.tscn") as PackedScene).instantiate()
	root.add_child(world)
	for i in 120:
		await physics_frame

	print("== grid: rows are z, columns are x (-72..40 step 8); ' --' means no ground ==")
	var header := "   z\\x "
	for ix in 15:
		header += "%7.0f" % (-72.0 + float(ix) * 8.0)
	print(header)
	for iz in 25:
		var z := 7490.0 + float(iz) * 8.0
		var line := "%7.0f" % z
		for ix in 15:
			var x := -72.0 + float(ix) * 8.0
			var h: float = float(world.call("ground_height_at", x, z))
			line += "     --" if is_nan(h) else "%7.1f" % h
		print(line)

	print("")
	print("== approach spine: ground along the trail's last 600m ==")
	var spine := [
		[0.0, 7000.0], [-80.0, 7120.0], [-20.0, 7250.0], [80.0, 7370.0],
		[63.6, 7400.0], [20.0, 7480.0], [0.0, 7520.0], [0.0, 7560.0],
	]
	for p: Variant in spine:
		var h: float = float(world.call("ground_height_at", float(p[0]), float(p[1])))
		print("  (%7.1f, %7.1f) -> %s" % [float(p[0]), float(p[1]),
			("no ground" if is_nan(h) else "%.2f" % h)])

	print("")
	print("== reference points ==")
	for p: Variant in [[150.0, 7595.0], [-8.0, 7505.0], [-25.0, 7460.0]]:
		var h: float = float(world.call("ground_height_at", float(p[0]), float(p[1])))
		print("  (%7.1f, %7.1f) -> %s" % [float(p[0]), float(p[1]),
			("no ground" if is_nan(h) else "%.2f" % h)])
	quit(0)

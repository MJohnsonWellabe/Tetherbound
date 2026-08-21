extends SceneTree

## Gate A: prove the relocated pond produces real render geometry. This stays
## below the full world composer so a broken pond cannot hide behind the
## several-minute vegetation build or pass merely because the river exists.

const WATER := preload("res://scripts/world/water.gd")


func _init() -> void:
	var water := WATER.new()
	root.add_child(water)
	water.build()
	var stats: Dictionary = water.stats()
	var pond: Node = water.get_node_or_null("PondSurface")
	if int(stats.get("pond_quads", 0)) <= 0 or pond == null:
		push_error("relocated Meadows pond produced no rendered surface: %s" % stats)
		quit(1)
		return
	# Gate A judges this as a representative lush pocket, not merely as water
	# geometry. Keep the layered banks honest when terrain/water levels move:
	# every authored family must resolve at least one real placement against
	# the current shoreline rather than existing only as inert config.
	for key: String in ["reeds", "marginals", "bank_flowers", "rocks", "lilypads"]:
		if int(stats.get(key, 0)) <= 0:
			push_error("relocated pond produced no %s shoreline dressing: %s" % [key, stats])
			quit(1)
			return
	print("pond water smoke passed: %d rendered quads, layered shore %s" % [
		int(stats["pond_quads"]), stats
	])
	quit()

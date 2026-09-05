extends SceneTree

## N14-ROUTED-FOLLOWUPS item 3. Where IS the clear ground around a stuck pickup?
##
## N02-VEGETATION §7 routed three authored sites that
## `band_pickups.gd::_clear_spot()` could not un-bury, because `NUDGE_RADII_M`
## stopped at 5 m. Widening it to 8 m solves two of the three. The third,
## `b4_candy_wind_ridge_crest`, is enclosed past 8 m as well, and its brief's own
## fallback is to re-author the coordinate rather than keep growing a "nudge"
## until it stops being one.
##
## Re-authoring needs a number, and guessing one off a heightmap is how a find
## ends up inside a different boulder. This boots the real world with the real
## baked scatter and asks `vegetation.gd::has_solid_scatter_near()` -- the same
## query the placer uses -- over a grid around each site, then prints the
## clear spots nearest the authored coordinate.
##
##   godot --headless --path . --script tools/_probe_n14_pickup_ground.gd
##
## Headless and query-only: no rendering, minutes not tens of minutes.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BAND_PICKUPS := preload("res://scripts/world/band_pickups.gd")
const SETTLE_FRAMES := 240

## Scan out to this radius, on this grid, and report the nearest clear cells.
const SCAN_RADIUS_M := 18.0
const SCAN_STEP_M := 0.5
const REPORT_COUNT := 8

const SITES := [
	{"id": "b4_candy_wind_ridge_crest", "at": Vector2(463.0, 5896.7)},
	{"id": "b4_candy_herd_bull_highfield", "at": Vector2(442.0, 5829.7)},
	{"id": "b5_candy_alpha_galecrest_pack", "at": Vector2(-50.0, 7268.0)},
]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var vegetation: Node3D = world.get_node_or_null(^"Vegetation") as Node3D
	if vegetation == null:
		for child in world.get_children():
			if child.has_method("has_solid_scatter_near"):
				vegetation = child as Node3D
				break
	if vegetation == null:
		print("FAIL: no node answering has_solid_scatter_near")
		quit(1)
		return

	var clearance := float(BAND_PICKUPS.SCATTER_CLEARANCE_M)
	print("clearance %.2fm, scan %.0fm radius on a %.1fm grid" % [clearance, SCAN_RADIUS_M, SCAN_STEP_M])

	for entry: Variant in SITES:
		var site: Dictionary = entry
		var at: Vector2 = site["at"]
		print("")
		print("%s  authored (%.1f, %.1f)" % [site["id"], at.x, at.y])

		var found: Array[Dictionary] = []
		var steps := int(SCAN_RADIUS_M / SCAN_STEP_M)
		for ix in range(-steps, steps + 1):
			for iz in range(-steps, steps + 1):
				var offset := Vector2(float(ix) * SCAN_STEP_M, float(iz) * SCAN_STEP_M)
				if offset.length() > SCAN_RADIUS_M:
					continue
				var candidate := at + offset
				var ground := float(world.call("ground_height_at", candidate.x, candidate.y))
				if is_nan(ground):
					continue
				if bool(vegetation.call("has_solid_scatter_near",
						Vector3(candidate.x, ground, candidate.y), clearance)):
					continue
				found.append({"at": candidate, "d": offset.length(), "y": ground})

		found.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
		if found.is_empty():
			print("  NO clear ground anywhere within %.0fm -- this site needs a different place, not a nudge" % SCAN_RADIUS_M)
			continue
		print("  %d clear cells; nearest:" % found.size())
		for i in mini(REPORT_COUNT, found.size()):
			var hit: Dictionary = found[i]
			var spot: Vector2 = hit["at"]
			print("    %.1fm  ->  [%.1f, %.1f]  ground y %.2f" % [hit["d"], spot.x, spot.y, hit["y"]])

	quit(0)

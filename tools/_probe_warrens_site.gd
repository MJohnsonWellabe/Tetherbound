extends SceneTree

## BAND2-63-WARRENS: is the Burrow Warrens actually underground?
##
##   godot --headless --path . --script tools/_probe_warrens_site.gd
##   godot --headless --path . --script tools/_probe_warrens_site.gd -- --plan
##   godot --headless --path . --script tools/_probe_warrens_site.gd -- --map
##   godot --headless --path . --script tools/_probe_warrens_site.gd -- --sites [--origin=x,z]
##
## `burrow_warrens.json`'s own `_comment_ow5d_relocation` flagged this exact
## risk in writing and then left it open: OW5D translated the cave from its
## measured original flank at (70,-140) to (-420,2470), left `yaw_deg` at the
## 54.5 that had been probed for the OLD hillside, and said outright that
## ground truth at the new site was NOT probed. `tools/_probe_warrens_run.gd`
## then walked the cave and the player wedged solid at local z=27.5 against a
## collider named `Terrain`: the ground comes up through the floor inside the
## hall, and the den -- the guardian, the clear flag, the whole required
## dungeon -- could not be reached on foot at all.
##
## What this probe measures is COVER: for every chamber it samples the world
## heightfield across that chamber's own footprint and reports the worst point,
## because the worst point is where the ground surfaces inside the room. A
## chamber is covered when the lowest terrain over it clears the top of its
## ceiling slab by `COVER_M`.
##
## The modes exist because the first two answers were both no:
##
##   (default) the shipped site and bearing, chamber by chamber.
##   `--map`   a coarse height field, so a reader can see the site sits on
##             gently rolling ground rather than on a flank.
##   `--sites` every origin on a 25 m grid out to 300 m, best bearing each.
##             Nothing within 300 m of the site clears, and nothing within
##             300 m of the Old Quarry clears either (`--origin=400,1800`) --
##             the best in either sweep is still 2.6 m short. This part of the
##             Meadows has no flank steep enough to bury a 47 m cave with 6 m
##             ceilings, so relocating it cannot be the fix.
##   `--plan`  what depth each chamber needs instead. This is the mode that
##             produced the shipped `depth` values: a cave that DESCENDS makes
##             its own cover and stops depending on a hillside that is not
##             there.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 120
const CONFIG_PATH := "res://data/config/burrow_warrens.json"
## Rock over the ceiling slab. Below this the chamber is a thin lid rather than
## a buried room, even when nothing quite pokes through.
const COVER_M := 1.0
## Ceiling slab thickness (0.8) plus the gap above the chamber height (0.4),
## from `burrow_warrens.gd::_build_chambers`.
const CEILING_M := 1.2
## Sample spacing across a chamber footprint, metres.
const SAMPLE_M := 2.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var config := _config()
	var site: Dictionary = config.get("site", {})
	var at: Array = site.get("at", [0.0, 0.0])
	var origin := Vector2(float(at[0]), float(at[1]))
	var args := OS.get_cmdline_user_args()
	for arg: String in args:
		if arg.begins_with("--origin="):
			var parts := arg.substr(9).split(",")
			if parts.size() == 2:
				origin = Vector2(float(parts[0]), float(parts[1]))
	var floor_clearance := float(site.get("floor_clearance", 0.35))
	var ground := float(world.call("ground_height_at", origin.x, origin.y))
	var mouth_floor := ground + floor_clearance
	var yaw := float(site.get("yaw_deg", 0.0))

	print("")
	print("=== Burrow Warrens site cover =========================================")
	print("site (%.0f, %.0f) bearing %.1f deg, ground y=%.2f, mouth floor y=%.2f" % [
		origin.x, origin.y, yaw, ground, mouth_floor])
	_report(world, config, origin, mouth_floor, yaw, true)

	if "--map" in args:
		_height_map(world, origin)
	elif "--sites" in args:
		_site_sweep(world, config, origin, floor_clearance)
	elif "--mound" in args:
		_mound(world, config, origin, floor_clearance)
	elif "--slide" in args:
		_slide(world, config, origin, floor_clearance, yaw)
	elif "--plan" in args:
		_plan(world, config, origin, mouth_floor)
	quit(0)


## Worst deficit over every chamber but the mouth, in metres: how far a
## chamber's ceiling stands ABOVE the lowest terrain over its own footprint.
## Zero or less means the whole cave is genuinely underground.
func _report(world: Node, config: Dictionary, origin: Vector2, mouth_floor: float,
		yaw_deg: float, verbose: bool) -> float:
	var worst := -999.0
	if verbose:
		print("")
		print("  chamber   floor  ceiling   lowest terrain    cover")
	for entry: Variant in config.get("chambers", []):
		var chamber: Dictionary = entry as Dictionary
		var id := str(chamber.get("id", ""))
		var floor_y := mouth_floor - float(chamber.get("depth", 0.0))
		var top := floor_y + float(chamber.get("height", 4.0)) + CEILING_M
		var lowest := _lowest_terrain(world, config, origin, yaw_deg, chamber)
		var deficit := top + COVER_M - lowest
		if id != "mouth":
			worst = maxf(worst, deficit)
		if verbose:
			var verdict := "buried"
			if deficit > 0.0:
				verdict = "SURFACES INSIDE THE ROOM" if lowest < floor_y + 0.2 else "thin lid"
			print("  %-7s %7.2f %8.2f %16.2f %8.2f  [%s]" % [
				id, floor_y, top, lowest, lowest - top, verdict])
	if verbose:
		print("  worst chamber is %+.2f m %s" % [
			absf(worst), "short of cover  [NOT underground]" if worst > 0.0 \
				else "clear  [the cave is underground]"])
	return worst


func _lowest_terrain(world: Node, config: Dictionary, origin: Vector2, yaw_deg: float,
		chamber: Dictionary) -> float:
	var yaw := deg_to_rad(yaw_deg)
	var centre: Array = chamber.get("at", [0.0, 0.0])
	var size: Array = chamber.get("size", [4.0, 4.0])
	var half_x := float(size[0]) * 0.5
	var half_z := float(size[1]) * 0.5
	var steps_x := maxi(int(float(size[0]) / SAMPLE_M), 1)
	var steps_z := maxi(int(float(size[1]) / SAMPLE_M), 1)
	var lowest := 999.0
	for ix in steps_x + 1:
		for iz in steps_z + 1:
			var local := Vector2(
				-half_x + 2.0 * half_x * float(ix) / float(steps_x) + float(centre[0]),
				-half_z + 2.0 * half_z * float(iz) / float(steps_z) + float(centre[1]))
			# The same rotation the cave node's own `rotation.y` applies.
			var world_at := origin + Vector2(
				local.x * cos(yaw) + local.y * sin(yaw),
				-local.x * sin(yaw) + local.y * cos(yaw))
			var ground := float(world.call("ground_height_at", world_at.x, world_at.y))
			if not is_nan(ground):
				lowest = minf(lowest, ground)
	return lowest


## For every bearing: how deep the deepest chamber would have to sit to be
## covered, and how steep the walk down to it is. The winner is not the
## best-cover bearing but the one needing the LEAST descent -- every metre of
## depth is a metre the player walks back up carrying the heartstone.
func _plan(world: Node, config: Dictionary, origin: Vector2, mouth_floor: float) -> void:
	print("")
	print("--- descent needed, by bearing ----------------------------------------")
	var rows: Array = []
	for step in 72:
		var yaw := float(step) * 5.0
		var deepest := 0.0
		var run := 1.0
		for entry: Variant in config.get("chambers", []):
			var chamber: Dictionary = entry as Dictionary
			if str(chamber.get("id", "")) == "mouth":
				continue
			var lowest := _lowest_terrain(world, config, origin, yaw, chamber)
			var need: float = mouth_floor + float(chamber.get("height", 4.0)) \
				+ CEILING_M + COVER_M - lowest
			if need > deepest:
				deepest = need
				var at: Array = chamber.get("at", [0.0, 0.0])
				run = maxf(float(at[1]), 1.0)
		rows.append({"yaw": yaw, "depth": deepest, "run": run})
	rows.sort_custom(func(a, b): return float(a["depth"]) < float(b["depth"]))
	for row: Dictionary in rows.slice(0, 12):
		var depth: float = float(row["depth"])
		var run: float = float(row["run"])
		print("  bearing %5.1f deg: %5.2f m of descent, %4.1f deg down over the %.0f m to it" % [
			float(row["yaw"]), depth, rad_to_deg(atan2(depth, run)), run])
	print("  (each row is the DEEPEST chamber on that bearing; shallower is better)")


## The other way to have a cave in gentle country: stop pretending there is a
## hillside and let the warren BE the hill. If the terrain never rises above
## the floor anywhere under the cave's footprint, nothing intrudes, every
## chamber is walkable, and what stands above ground is a rock knoll with a
## mouth in it -- which is what `burrow_warrens.json`'s own site comment always
## claimed the entrance was ("the mouth chamber's roof breaks the surface as a
## rocky outcrop"), and what the `skirt` was built to hide the underside of.
##
## This looks for the flattest ground: for every origin and bearing, how far
## the HIGHEST terrain under the whole footprint sits above the mouth floor.
## Negative is what we want, and the more negative the better.
func _mound(world: Node, config: Dictionary, origin: Vector2, floor_clearance: float) -> void:
	print("")
	print("--- flattest sites (terrain never rises above the cave floor) ----------")
	var found: Array = []
	var reach := 10
	for ix in range(-reach, reach + 1):
		for iz in range(-reach, reach + 1):
			var candidate := origin + Vector2(float(ix) * 20.0, float(iz) * 20.0)
			var ground := float(world.call("ground_height_at", candidate.x, candidate.y))
			if is_nan(ground):
				continue
			var mouth_floor := ground + floor_clearance
			var best := 999.0
			var best_yaw := 0.0
			for step in 24:
				var yaw := float(step) * 15.0
				var highest := -999.0
				for entry: Variant in config.get("chambers", []):
					highest = maxf(highest, _highest_terrain(world, config, candidate, yaw,
						entry as Dictionary))
				var intrusion := highest - mouth_floor
				if intrusion < best:
					best = intrusion
					best_yaw = yaw
			found.append({"at": candidate, "intrusion": best, "yaw": best_yaw,
				"move": origin.distance_to(candidate)})
	found.sort_custom(func(a, b): return float(a["intrusion"]) < float(b["intrusion"]))
	for entry: Dictionary in found.slice(0, 15):
		var at: Vector2 = entry["at"]
		print("  (%6.0f, %6.0f)  yaw %5.1f deg  highest terrain %+5.2f m vs the floor  %4.0f m away" % [
			at.x, at.y, float(entry["yaw"]), float(entry["intrusion"]), float(entry["move"])])
	print("  (negative means nothing pokes through the floor anywhere)")


## The mouth is the one chamber that is NOT supposed to be buried, and it has
## its own failure mode: at a bearing that climbs, the ground can already be
## ABOVE the mouth floor inside the mouth chamber itself, which is what the
## first descent attempt hit -- the player walked up the terrain surface inside
## the entrance and jammed against the cave's own ceiling. So the mouth needs
## terrain no higher than its floor across its whole footprint, while every
## chamber behind it needs terrain above its ceiling. This slides the site back
## and forth along its own bearing looking for the offset that satisfies both.
func _slide(world: Node, config: Dictionary, origin: Vector2, floor_clearance: float,
		yaw_deg: float) -> void:
	print("")
	print("--- sliding the site along bearing %.1f deg ----------------------------" % yaw_deg)
	print("  offset   mouth sits   worst chamber cover")
	var yaw := deg_to_rad(yaw_deg)
	var forward := Vector2(sin(yaw), cos(yaw))
	var mouth: Dictionary = {}
	for entry: Variant in config.get("chambers", []):
		if str((entry as Dictionary).get("id", "")) == "mouth":
			mouth = entry as Dictionary
	for step in range(-12, 13):
		var offset := float(step) * 5.0
		var candidate := origin + forward * offset
		var ground := float(world.call("ground_height_at", candidate.x, candidate.y))
		if is_nan(ground):
			continue
		var mouth_floor := ground + floor_clearance
		var highest := _highest_terrain(world, config, candidate, yaw_deg, mouth)
		var intrusion := highest - mouth_floor
		var worst := _report(world, config, candidate, mouth_floor, yaw_deg, false)
		var verdict := ""
		if intrusion <= 0.0 and worst <= 0.0:
			verdict = "  [WORKS]"
		print("  %+6.0f m  %+6.2f m %s   %+6.2f m%s" % [
			offset, intrusion,
			"above the mouth floor" if intrusion > 0.0 else "below the mouth floor ",
			-worst, verdict])


func _highest_terrain(world: Node, config: Dictionary, origin: Vector2, yaw_deg: float,
		chamber: Dictionary) -> float:
	var yaw := deg_to_rad(yaw_deg)
	var centre: Array = chamber.get("at", [0.0, 0.0])
	var size: Array = chamber.get("size", [4.0, 4.0])
	var half_x := float(size[0]) * 0.5
	var half_z := float(size[1]) * 0.5
	var highest := -999.0
	for ix in 6:
		for iz in 6:
			var local := Vector2(
				-half_x + 2.0 * half_x * float(ix) / 5.0 + float(centre[0]),
				-half_z + 2.0 * half_z * float(iz) / 5.0 + float(centre[1]))
			var world_at := origin + Vector2(
				local.x * cos(yaw) + local.y * sin(yaw),
				-local.x * sin(yaw) + local.y * cos(yaw))
			var ground := float(world.call("ground_height_at", world_at.x, world_at.y))
			if not is_nan(ground):
				highest = maxf(highest, ground)
	return highest


## A coarse height field around the site, so a reader can see whether there is
## a hill near it at all.
func _height_map(world: Node, origin: Vector2) -> void:
	print("")
	print("--- terrain height, 40 m grid, offsets in metres from the site ---------")
	var header := "        "
	for ix in range(-4, 5):
		header += "%7d" % (ix * 40)
	print(header)
	for iz in range(-4, 5):
		var line := "%6d  " % (iz * 40)
		for ix in range(-4, 5):
			var h := float(world.call("ground_height_at",
				origin.x + float(ix) * 40.0, origin.y + float(iz) * 40.0))
			line += "%7.1f" % h
		print(line)


## Candidate origins on a grid: for each, the bearing that covers most of the
## cave. Kept because its answer is the reason the cave descends rather than
## moves -- nothing on either sweep clears.
func _site_sweep(world: Node, config: Dictionary, origin: Vector2, floor_clearance: float) -> void:
	print("")
	print("--- candidate sites, best bearing each ---------------------------------")
	var found: Array = []
	var reach := 12
	for ix in range(-reach, reach + 1):
		for iz in range(-reach, reach + 1):
			var candidate := origin + Vector2(float(ix) * 25.0, float(iz) * 25.0)
			var ground := float(world.call("ground_height_at", candidate.x, candidate.y))
			if is_nan(ground):
				continue
			var best := 999.0
			var best_yaw := 0.0
			# 15-degree steps: this loop runs once per grid square, and the
			# question here is "is there a hillside at all", not the bearing.
			for step in 24:
				var yaw := float(step) * 15.0
				var worst := _report(world, config, candidate, ground + floor_clearance, yaw, false)
				if worst < best:
					best = worst
					best_yaw = yaw
			found.append({"at": candidate, "deficit": best, "yaw": best_yaw,
				"move": origin.distance_to(candidate)})
	found.sort_custom(func(a, b): return float(a["deficit"]) < float(b["deficit"]))
	for entry: Dictionary in found.slice(0, 15):
		var at: Vector2 = entry["at"]
		print("  (%6.0f, %6.0f)  yaw %5.1f deg  deficit %+5.2f m  %5.0f m away" % [
			at.x, at.y, float(entry["yaw"]), float(entry["deficit"]), float(entry["move"])])
	print("  (best 15 by deficit; a NEGATIVE deficit is a site that works)")


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

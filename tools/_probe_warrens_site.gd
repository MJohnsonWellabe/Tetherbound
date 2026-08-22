extends SceneTree

## BAND2-63-WARRENS: does the hill the Burrow Warrens is dug into actually
## cover it?
##
##   godot --headless --path . --script tools/_probe_warrens_site.gd
##   godot --headless --path . --script tools/_probe_warrens_site.gd -- --scan
##
## `burrow_warrens.json`'s own `_comment_ow5d_relocation` flagged this exact
## risk in writing and left it open: the cave was translated from its measured
## original flank at (70,-140) to (-420,2470) by OW5D, `yaw_deg` was left at the
## 54.5 that was probed for the OLD hillside, and the note says outright that
## ground truth at the new site was NOT probed. `tools/_probe_warrens_run.gd`
## then walked the cave and the player wedged solid at local z=27.5 against a
## collider named `Terrain`: the hillside comes up through the floor inside the
## hall, and the den -- the guardian, the clear flag, the whole required
## dungeon -- cannot be reached on foot.
##
## This probe measures the cover the cave actually has. For every chamber it
## samples the world heightfield across that chamber's own footprint and
## reports the WORST point: how far the terrain sits above (good, buried) or
## below (bad, the ground surfaces inside the room) that chamber's ceiling.
##
## With `--scan` it does the same sweep for every bearing at 5-degree steps and
## prints the ones that clear, which is the same five-candidate probe the
## original site's comment describes -- just run over the whole circle, because
## a relocation gets to choose its approach freely.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 120
const CONFIG_PATH := "res://data/config/burrow_warrens.json"
## Rock over the ceiling slab. Below this the chamber is a thin lid rather than
## a buried room, even when nothing pokes through.
const COVER_M := 1.0
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
	# `--origin x,z` re-centres every sweep below on somewhere else in the band,
	# so "is there a hillside anywhere in Band 2 that fits this cave" can be
	# asked of the quarry rise (which `old_quarry.json` measures at 45-67
	# degrees) without editing the shipped site to find out.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--origin="):
			var parts := arg.substr(9).split(",")
			if parts.size() == 2:
				origin = Vector2(float(parts[0]), float(parts[1]))
	var floor_clearance := float(site.get("floor_clearance", 0.35))
	var mouth_ground := float(world.call("ground_height_at", origin.x, origin.y))

	print("")
	print("=== Burrow Warrens site cover =========================================")
	print("site (%.0f, %.0f), ground there y=%.2f, cave floor y=%.2f" % [
		origin.x, origin.y, mouth_ground, mouth_ground + floor_clearance])

	var current := float(site.get("yaw_deg", 0.0))
	_report(world, config, origin, mouth_ground + floor_clearance, current, true)

	if "--map" in OS.get_cmdline_user_args():
		_height_map(world, origin)
		quit(0)
		return

	if "--sites" in OS.get_cmdline_user_args():
		_site_sweep(world, config, origin, floor_clearance)
		quit(0)
		return

	if not ("--scan" in OS.get_cmdline_user_args()):
		quit(0)
		return

	print("")
	print("--- bearing sweep (worst cover over all chambers but the mouth) --------")
	var best := -999.0
	var best_yaw := current
	for step in 72:
		var yaw := float(step) * 5.0
		var worst := _report(world, config, origin, mouth_ground + floor_clearance, yaw, false)
		if worst > best:
			best = worst
			best_yaw = yaw
		if worst > 0.0:
			print("  yaw %5.1f deg: worst cover %+6.2f m  [clears]" % [yaw, worst])
	print("  best bearing: %.1f deg at %+.2f m worst cover" % [best_yaw, best])
	quit(0)


## Worst (terrain - required top) over every non-mouth chamber, in metres.
## Positive means every room is genuinely under the hill.
func _report(world: Node, config: Dictionary, origin: Vector2, floor_y: float,
		yaw_deg: float, verbose: bool) -> float:
	var yaw := deg_to_rad(yaw_deg)
	var worst := 999.0
	if verbose:
		print("")
		print("--- chambers at the shipped bearing %.1f deg --------------------------" % yaw_deg)
	for entry: Variant in config.get("chambers", []):
		var chamber: Dictionary = entry as Dictionary
		var id := str(chamber.get("id", ""))
		var centre: Array = chamber.get("at", [0.0, 0.0])
		var size: Array = chamber.get("size", [4.0, 4.0])
		var height := float(chamber.get("height", 4.0))
		var need := floor_y + height + 1.2 + COVER_M  # ceiling slab is 0.8 thick, +0.4 gap
		var lowest := 999.0
		var lowest_at := Vector2.ZERO
		var half_x := float(size[0]) * 0.5
		var half_z := float(size[1]) * 0.5
		var steps_x := maxi(int(float(size[0]) / SAMPLE_M), 1)
		var steps_z := maxi(int(float(size[1]) / SAMPLE_M), 1)
		for ix in steps_x + 1:
			for iz in steps_z + 1:
				var local := Vector2(
					-half_x + 2.0 * half_x * float(ix) / float(steps_x) + float(centre[0]),
					-half_z + 2.0 * half_z * float(iz) / float(steps_z) + float(centre[1]))
				# Same rotation the cave node's own `rotation.y` applies.
				var world_at := origin + Vector2(
					local.x * cos(yaw) + local.y * sin(yaw),
					-local.x * sin(yaw) + local.y * cos(yaw))
				var ground := float(world.call("ground_height_at", world_at.x, world_at.y))
				if is_nan(ground):
					continue
				if ground < lowest:
					lowest = ground
					lowest_at = world_at
		var cover := lowest - need
		if id != "mouth":
			worst = minf(worst, cover)
		if verbose:
			var verdict := "buried" if cover >= 0.0 else ("SURFACES INSIDE THE ROOM" \
				if lowest < floor_y + 0.2 else "thin lid")
			print("  %-6s ceiling needs y>=%6.2f, worst terrain y=%6.2f at (%.0f, %.0f)  %+6.2f m  [%s]" % [
				id, need, lowest, lowest_at.x, lowest_at.y, cover, verdict])
	return worst


## A coarse height field around the site, so a human reading the report can
## see whether there is a hill anywhere near it at all.
func _height_map(world: Node, origin: Vector2) -> void:
	print("")
	print("--- terrain height, 20 m grid, metres relative to the site -------------")
	var header := "        "
	for ix in range(-8, 9, 2):
		header += "%7d" % (ix * 20)
	print(header)
	for iz in range(-8, 9, 2):
		var line := "%6d  " % (iz * 20)
		for ix in range(-8, 9, 2):
			var h := float(world.call("ground_height_at",
				origin.x + float(ix) * 20.0, origin.y + float(iz) * 20.0))
			line += "%7.1f" % h
		print(line)


## Candidate origins on a grid around the shipped one: for each, the best
## bearing's worst cover. A site only qualifies if the whole cave clears, and
## the ones that do are ranked by how little they move the mouth -- the cave is
## sited on a spine vertex on purpose (it is how the player finds it), so the
## nearest working hillside beats the best one.
func _site_sweep(world: Node, config: Dictionary, origin: Vector2, floor_clearance: float) -> void:
	print("")
	print("--- candidate sites (cover > 0 at some bearing) ------------------------")
	var found: Array = []
	var reach := 12
	for ix in range(-reach, reach + 1):
		for iz in range(-reach, reach + 1):
			var candidate := origin + Vector2(float(ix) * 25.0, float(iz) * 25.0)
			var ground := float(world.call("ground_height_at", candidate.x, candidate.y))
			if is_nan(ground):
				continue
			var floor_y := ground + floor_clearance
			var best := -999.0
			var best_yaw := 0.0
			# 15-degree steps here, not the 5 the single-site sweep uses: this
			# loop runs it once per grid square and the question at this stage
			# is "is there a hillside here at all", not the final bearing.
			for step in 24:
				var yaw := float(step) * 15.0
				var worst := _report(world, config, candidate, floor_y, yaw, false)
				if worst > best:
					best = worst
					best_yaw = yaw
			found.append({"at": candidate, "cover": best, "yaw": best_yaw,
				"move": origin.distance_to(candidate)})
	# Ranked by cover, not by distance: the sweep's first run found NOTHING on
	# this grid that clears, so what the report has to answer is no longer
	# "which is the nearest working hillside" but "how much hillside does this
	# region have at all, anywhere near the spine".
	found.sort_custom(func(a, b): return float(a["cover"]) > float(b["cover"]))
	found = found.slice(0, 15)
	for entry: Dictionary in found:
		var at: Vector2 = entry["at"]
		print("  (%6.0f, %6.0f)  yaw %5.1f deg  worst cover %+5.2f m  %5.0f m from the shipped site" % [
			at.x, at.y, float(entry["yaw"]), float(entry["cover"]), float(entry["move"])])
	print("  (best 15 of the grid, ranked by cover; positive means the whole cave is buried)")


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

extends SceneTree

## Bakes the M1 playground's scatter placements to disk (SCAT1).
##
##   godot --headless --path . --script scripts/world/bake_playground_scatter.gd
##
## `scatter_rules.gd::all_placements` is pure, seeded and a function of the
## heightfield alone — this runs that same pass once, offline, and writes the
## result through `scatter_bake.gd` instead of leaving it to run again on
## every load. Nothing at run time computes placements differently; this is a
## second output of the same recipe `build_playground_terrain.gd` already
## bakes the height/colour/control maps from, not a new system with its own
## staleness rules.
##
## Re-run after editing `data/config/vegetation.json` OR
## `data/config/terrain_playground.json` — `scatter_bake.gd`'s config
## fingerprint covers both, and `vegetation.gd` falls back to computing at
## load time (correct, just slow) rather than serving a stale bake silently.
##
## World name is fixed at "playground" for now, matching `data/terrain/playground`.
## A multi-region world (`docs/specs/MEADOWS_MACRO_LAYOUT.md`) reruns this unchanged --
## the region partitioning already exists, it has just never had more than
## four regions to split across.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")

const WORLD_NAME := "playground"


func _init() -> void:
	var config := HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config; nothing baked")
		quit(1)
		return

	var world_size := float(config.get("world_size", 512))
	var region_size := float(config.get("region_size", 256))
	var base_seed := int(RULES.config().get("seed", 1))
	var selection: Array = []
	var regional := false
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--regions="):
			continue
		regional = true
		for pair: String in arg.substr("--regions=".length()).split(",", false):
			var parts := pair.split(":")
			if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
				push_error("Invalid scatter region selection: " + pair)
				quit(1)
				return
			selection.append([parts[0].to_int(), parts[1].to_int()])
	if regional and not BAKE.valid_world_selection(selection, config.world_bounds, region_size):
		push_error("Scatter selection is empty, duplicated or outside the authored world")
		quit(1)
		return

	var scope_file := ""
	if regional:
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--scope-proof="):
				scope_file = arg.substr("--scope-proof=".length())
		if BAKE.TERRAIN_BAKE.read_village_scope(scope_file, selection).is_empty():
			push_error("Regional scatter writer needs matching independently reviewed village scope proof")
			quit(1)
			return
	var field: RefCounted = HEIGHTFIELD.new(config)
	var drained: Dictionary = {}
	var t0 := Time.get_ticks_msec()
	var by_layer: Dictionary = RULES.all_placements(field, world_size, base_seed, drained)
	var elapsed := Time.get_ticks_msec() - t0

	var kept_total := 0
	for layer_name: String in by_layer.keys():
		kept_total += (by_layer[layer_name] as Array).size()
	var drained_total := 0
	for layer_name: String in drained.keys():
		drained_total += (drained[layer_name] as Array).size()

	print("computed %d placements (%d drained) across %d layers in %d ms" % [
		kept_total, drained_total, by_layer.size(), elapsed])

	if regional:
		var patched := BAKE.write_regions(WORLD_NAME, by_layer, drained, region_size, base_seed, selection, "", scope_file)
		print("regional scatter update: " + JSON.stringify(patched))
		quit(0 if bool(patched.get("ok", false)) else 1)
		return
	var result := BAKE.write_all(WORLD_NAME, by_layer, drained, region_size, base_seed)
	if result.get("ok", true) == false:
		push_error("Scatter region write failed; no new manifest published")
		quit(1)
		return
	print("baked -> data/scatter/%s (%d regions, %d bytes, %.1f bytes/placement)" % [
		WORLD_NAME, result["regions"], result["bytes"],
		float(result["bytes"]) / maxf(1.0, float(result["kept"] + result["drained"]))])

	quit(0)

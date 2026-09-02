extends SceneTree

## ROUND 7 (JUDGE-round6.md): "07 IDENTICAL to round 5 -- your 07 copse never
## reached the rendered frame (most likely the render ran against a bake that
## did not include the new band2 anchor; verify the bake manifest fingerprint
## matches the config BEFORE rendering, and print the placement count for
## that anchor from the bake)". This is that verification, run against
## whatever is actually on disk at `data/scatter/playground/` -- the same
## thing `vegetation.gd` serves at runtime and the capture tool renders from.
##
##   godot --headless --path . --script tools/_probe_station07_bake.gd
##
## Station 07's own round-3-addendum copse anchor: band2's `trees` layer,
## `at`=[1.0, 2151.0], `radius`=13.0 (data/config/bands/band2_stone_and_root/
## vegetation.json line 66). A placement counts as "from this anchor" if it
## falls inside that disc -- ordinary corridor_fill/clump placements landing
## inside a 13m disc by chance are rare enough that a nonzero count here is
## real evidence, not a coincidence, especially at the count this anchor asks
## for (8).

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

const WORLD_NAME := "playground"
const ANCHOR_CENTRE := Vector2(1.0, 2151.0)
const ANCHOR_RADIUS := 13.0


func _init() -> void:
	var live_fingerprint := BAKE.config_fingerprint()
	var manifest_path := "res://data/scatter/%s/manifest.json" % WORLD_NAME
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		print("NO BAKE on disk at %s -- nothing to verify, run the bake first" % manifest_path)
		quit(1)
		return
	var manifest: Variant = JSON.parse_string(file.get_as_text())
	var manifest_fingerprint := int((manifest as Dictionary).get("config_fingerprint", 0)) \
		if manifest is Dictionary else -1
	var base_seed := int(RULES.config().get("seed", 1))
	var fresh := BAKE.is_fresh(WORLD_NAME, base_seed)

	print("config_fingerprint (live, from current config files) = %d" % live_fingerprint)
	print("config_fingerprint (stored in manifest.json)          = %d" % manifest_fingerprint)
	print("BAKE.is_fresh(\"%s\", base_seed=%d) = %s" % [WORLD_NAME, base_seed, fresh])
	if not fresh:
		print("STALE: the on-disk bake does NOT match the current config. " +
			"Re-run tools/../scripts/world/bake_playground_scatter.gd before rendering.")
		quit(1)
		return

	var drained: Dictionary = {}
	var by_layer: Dictionary = BAKE.load_all(WORLD_NAME, drained)
	var trees: Array = by_layer.get("trees", [])
	var in_anchor := 0
	for placement: Variant in trees:
		var p: Dictionary = placement
		var pos: Vector3 = p["position"]
		if Vector2(pos.x, pos.z).distance_to(ANCHOR_CENTRE) <= ANCHOR_RADIUS:
			in_anchor += 1

	print("trees layer total placements in bake: %d" % trees.size())
	print("placements within %.1fm of station-07 copse anchor at %s: %d" % [
		ANCHOR_RADIUS, ANCHOR_CENTRE, in_anchor])
	if in_anchor > 0:
		print("PROOF: the station-07 copse anchor IS present in the on-disk bake " +
			"this render will read from.")
	else:
		print("PROOF FAILED: zero placements found in the anchor's own disc -- " +
			"the bake does not contain this anchor's trees.")
	quit(0 if in_anchor > 0 else 1)

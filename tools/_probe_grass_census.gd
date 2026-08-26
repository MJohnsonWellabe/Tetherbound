extends SceneTree

## WORLD-GRASS. What the committed bake actually holds, per layer, and how much
## of it lands where the player stands.
##
##   godot --headless --path . --script tools/_probe_grass_census.gd
##
## `--headless` is correct here: this reads baked placement data and renders
## nothing (ralph/conventions.md's hang trap is `--headless` plus a real
## rendering driver, which this never asks for).
##
## Written because the ground-cover argument on this project keeps being made
## in whole-chapter placement totals, and a whole-chapter total is the wrong
## unit: 466,922 placements spread over a 16.8 km2 corridor is 0.028 per square
## metre, and what a frame shows is the local figure at one viewpoint. This
## reports both, and the local figure for the same eyes
## `tools/_probe_grass_pass.gd` photographs, so a density edit can be checked
## against the number the camera will see rather than against the ledger.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

const WORLD_NAME := "playground"

## The eyes `_probe_grass_pass.gd` shoots from, so the two tools answer the
## same question about the same ground.
const SITES := {
	"band1-open-meadow": Vector2(8.0, 90.0),
	"band2-forest-floor": Vector2(310.0, 1660.0),
	"band3-crossing": Vector2(-152.0, 4170.0),
	"band4-high-pasture": Vector2(-280.0, 6460.0),
	"band1-mounted": Vector2(-60.0, 220.0),
}

## Two radii, because they answer different complaints. 20m is the near field a
## `-near` frame fills; 55m is the grass layer's own shipped `lod_range`, so
## everything beyond it is not drawn at all and cannot help any frame.
const NEAR_RADIUS := 20.0
const FAR_RADIUS := 55.0


func _init() -> void:
	var base_seed := int(RULES.config().get("seed", 1))
	print("bake fresh: %s" % str(BAKE.is_fresh(WORLD_NAME, base_seed)))
	var drained: Dictionary = {}
	var by_layer: Dictionary = BAKE.load_all(WORLD_NAME, drained)

	var total := 0
	var names: Array[String] = []
	for layer_name: String in by_layer.keys():
		names.append(layer_name)
	names.sort()
	print("")
	print("%-14s %10s" % ["layer", "placements"])
	for layer_name in names:
		var n: int = (by_layer[layer_name] as Array).size()
		total += n
		print("%-14s %10d" % [layer_name, n])
	print("%-14s %10d" % ["TOTAL", total])

	print("")
	print("grass instances near each eye (density per m2 in brackets)")
	print("%-20s %18s %18s" % ["site", "within 20m", "within 55m"])
	for site_name: String in SITES.keys():
		var at: Vector2 = SITES[site_name]
		var near := 0
		var far := 0
		for entry: Variant in (by_layer.get("grass", []) as Array):
			var p: Vector3 = (entry as Dictionary)["position"]
			var d := Vector2(p.x, p.z).distance_to(at)
			if d <= NEAR_RADIUS:
				near += 1
			if d <= FAR_RADIUS:
				far += 1
		print("%-20s %8d (%6.3f/m2) %8d (%6.3f/m2)" % [
			site_name,
			near, float(near) / (PI * NEAR_RADIUS * NEAR_RADIUS),
			far, float(far) / (PI * FAR_RADIUS * FAR_RADIUS)])

	# Mean instance scale, printed per layer, because "the grass is too short"
	# is a claim about this number and it has been asserted twice on this
	# project without anyone reading it off the bake.
	print("")
	print("%-14s %10s %10s %10s" % ["layer", "scale min", "scale mean", "scale max"])
	for layer_name in names:
		var lo := INF
		var hi := -INF
		var sum := 0.0
		var n := 0
		for entry: Variant in (by_layer[layer_name] as Array):
			var s := float((entry as Dictionary).get("scale", 0.0))
			lo = minf(lo, s)
			hi = maxf(hi, s)
			sum += s
			n += 1
		if n == 0:
			continue
		print("%-14s %10.3f %10.3f %10.3f" % [layer_name, lo, sum / float(n), hi])
	quit(0)

extends SceneTree

## OF15 scratch probe: what is actually at the wedge spot?
##
##   godot --headless --path . --script tools/_probe_wedge.gd
##
## `smoke_traversal.gd` reports a sustained wedge at (-43,-53) -- "held an
## input, stayed grounded, moved under 0.5m for 1.0s+". Two explanations were
## proposed and BOTH were wrong before this probe was written: that the terrain
## rebuild sank a cliff in there, and that scatter density put a bush in the
## way. This measures instead of arguing.
##
## What it found: the terrain is a smooth 6-degree slope (0.11 m/m, no cliff),
## and the bake sites Rock_Medium_3 1.29m away and Rock_Medium_1 1.92m away.
## The player pins against a rock on a slope rather than sliding off it -- which
## is OF15's original owner report word for word, not a terrain defect.
##
## Note the real lesson for whoever reads this next: main passes the same
## traversal test, and that is LUCK, not health. The scatter bake is a function
## of the terrain config, so any terrain edit re-sites every rock; a bake that
## drops one on a walked leg fails, and a bake that does not, passes. The defect
## is in how the body slides, and it is bake-independent.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const HF := preload("res://scripts/world/playground_heightfield.gd")

const SPOT := Vector2(-43.0, -53.0)
const RADIUS := 3.0


func _init() -> void:
	_heights()
	_placements()
	quit(0)


func _heights() -> void:
	var f: RefCounted = HF.new()
	print("--- height_at, 1m grid around (%.0f,%.0f) ---" % [SPOT.x, SPOT.y])
	var head := "      "
	for dx in range(-4, 5):
		head += "%7d" % (int(SPOT.x) + dx)
	print(head)
	for dz in range(-4, 5):
		var row := "z%+4d " % (int(SPOT.y) + dz)
		for dx in range(-4, 5):
			row += "%7.2f" % float(f.call("height_at", SPOT.x + float(dx), SPOT.y + float(dz)))
		print(row)


func _placements() -> void:
	var drained: Dictionary = {}
	var by_layer: Dictionary = BAKE.load_all("playground", drained)
	print("--- baked scatter within %.0fm ---" % RADIUS)
	var found := 0
	for layer_name: String in by_layer.keys():
		for entry: Variant in (by_layer[layer_name] as Array):
			var d: Dictionary = entry
			var raw: Variant = d.get("pos", d.get("position", null))
			var xz := Vector2.ZERO
			if raw is Vector3:
				xz = Vector2((raw as Vector3).x, (raw as Vector3).z)
			elif raw is Vector2:
				xz = raw
			else:
				continue
			if xz.distance_to(SPOT) <= RADIUS:
				found += 1
				print("  %-10s %-52s (%.2f, %.2f) dist %.2f" % [
					layer_name, str(d.get("model", "?")).get_file(), xz.x, xz.y, xz.distance_to(SPOT)])
	print("total within %.0fm: %d" % [RADIUS, found])

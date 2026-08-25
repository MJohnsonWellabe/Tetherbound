extends SceneTree

## OF15 scratch probe, same pattern as `_probe_wedge.gd`: what is actually at
## the wedge spot `smoke_traversal.gd` now reports at (53,-65) -- "player got
## wedged (held an input, stayed grounded, moved under 0.5m for 1.0s+) at 1
## spot(s): move_back at (53, -65)" -- reproduced on CI run 2417 and again on
## 2419 (with the retry, both attempts), never locally so far. Measuring
## before diagnosing, same discipline `_probe_wedge.gd`'s own header used.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const HF := preload("res://scripts/world/playground_heightfield.gd")

const SPOT := Vector2(53.0, -65.0)
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

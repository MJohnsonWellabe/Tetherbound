extends SceneTree

## THROWAWAY VERIFICATION, not part of the shipped tool set. Proves the
## anchors-get-their-own-rng fix in scatter_rules.gd: with anchors present vs
## a copy of the same layer with `anchors` stripped, every corridor_fill /
## clump / stray placement OUTSIDE any anchor's own radius must be byte
## identical. If it is not, anchors are still perturbing the shared stream.
##
##   godot --headless --path . --script tools/_probe_anchor_isolation.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

func _init() -> void:
	var config := HEIGHTFIELD.load_config()
	var world_size := float(config.get("world_size", 512))
	var field: RefCounted = HEIGHTFIELD.new(config)
	var base_seed := int(RULES.config().get("seed", 1))
	var layers: Dictionary = RULES.config().get("layers", {})

	var offset := 0
	var total_checked := 0
	var total_mismatched := 0
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		var layer: Dictionary = layers[name]
		var seed_value := base_seed + offset * 7919 + int(layer.get("seed_offset", 0))
		offset += 1
		var anchors: Array = layer.get("anchors", [])
		if anchors.is_empty():
			continue

		var with_anchors: Array[Dictionary] = RULES.placements_for(layer, field, world_size, seed_value)
		var stripped: Dictionary = layer.duplicate(true)
		stripped.erase("anchors")
		var without_anchors: Array[Dictionary] = RULES.placements_for(stripped, field, world_size, seed_value)

		# Build a lookup of anchor discs (centre, radius) to exclude.
		var discs: Array = []
		for a: Variant in anchors:
			var ad: Dictionary = a as Dictionary
			var at: Array = ad.get("at", [])
			if at.size() < 2:
				continue
			discs.append([Vector2(float(at[0]), float(at[1])), maxf(float(ad.get("radius", 8.0)), 0.0) + 0.5])

		# Every WITHOUT-anchors placement not inside any disc must appear,
		# position-identical, in the WITH-anchors list too.
		var with_positions: Array[Vector3] = []
		for p: Dictionary in with_anchors:
			with_positions.append(p["position"])

		var mismatched := 0
		var checked := 0
		for p: Dictionary in without_anchors:
			var pos: Vector3 = p["position"]
			var inside_anchor := false
			for disc: Array in discs:
				var centre: Vector2 = disc[0]
				var radius: float = disc[1]
				if Vector2(pos.x, pos.z).distance_to(centre) <= radius:
					inside_anchor = true
					break
			if inside_anchor:
				continue
			checked += 1
			var found := false
			for wp: Vector3 in with_positions:
				if wp.is_equal_approx(pos):
					found = true
					break
			if not found:
				mismatched += 1

		total_checked += checked
		total_mismatched += mismatched
		print("%-12s anchors=%d  without=%d  with=%d  checked(outside-anchor)=%d  mismatched=%d" % [
			name, anchors.size(), without_anchors.size(), with_anchors.size(), checked, mismatched])

	print("")
	print("TOTAL checked=%d mismatched=%d -- %s" % [
		total_checked, total_mismatched,
		"PASS: anchors do not perturb any placement outside their own radius" if total_mismatched == 0
		else "FAIL: anchors are still perturbing the shared stream"])
	quit(0 if total_mismatched == 0 else 1)

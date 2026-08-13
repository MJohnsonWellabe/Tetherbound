extends SceneTree

## Throwaway probe for OF4-remainder-mound: what is actually placed on the
## faces of the rise that the village square and the Rise road can see?
##
##   godot --headless --path . --script tools/_probe_mound.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

const CENTRE := Vector2(140.0, -90.0)
## The two vantages OF4-remainder-mound is judged from.
const SQUARE_EYE := Vector2(-2.0, -4.0)
const ROAD_EYE := Vector2(26.0, -14.0)


func _init() -> void:
	var cfg := HEIGHTFIELD.load_config()
	var field: RefCounted = HEIGHTFIELD.new(cfg)
	var world_size := float(cfg.get("world_size", 512.0))
	var base_seed := int(RULES.config().get("seed", 1))
	var all: Dictionary = RULES.all_placements(field, world_size, base_seed)

	# The visible limb: within the rise's own footprint plus a 20m apron, and
	# on the half of it facing the village.
	print("--- props on the rise (<=98m of centre, village-facing half) ---")
	for name: String in all.keys():
		var hits: Array[Dictionary] = []
		for placement: Dictionary in all[name]:
			var pos: Vector3 = placement["position"]
			var flat := Vector2(pos.x, pos.z)
			if flat.distance_to(CENTRE) > 98.0:
				continue
			if (flat - CENTRE).dot((SQUARE_EYE - CENTRE).normalized()) < -10.0:
				continue
			hits.append(placement)
		if hits.is_empty():
			continue
		var biggest := 0.0
		var highest := -1000.0
		for placement: Dictionary in hits:
			biggest = maxf(biggest, float(placement["scale"]))
			highest = maxf(highest, float((placement["position"] as Vector3).y))
		print("  %-12s %3d  biggest scale %.2f  highest %.1fm" % [
			name, hits.size(), biggest, highest])

	print("--- every rock/tree/grove instance on the village-facing flank ---")
	for name: String in ["rocks", "trees", "grove", "deadfall"]:
		for placement: Dictionary in all[name]:
			var pos: Vector3 = placement["position"]
			var flat := Vector2(pos.x, pos.z)
			if flat.distance_to(CENTRE) > 98.0:
				continue
			if (flat - CENTRE).dot((SQUARE_EYE - CENTRE).normalized()) < -10.0:
				continue
			print("  %-7s (%6.1f,%7.1f) d=%5.1f h=%6.1f s=%.2f %s" % [
				name, pos.x, pos.z, flat.distance_to(CENTRE), pos.y,
				float(placement["scale"]), str(placement["model"]).get_file()])

	# Does the eye actually see them? A rock 8m up a slope is useless if the
	# rise's own shoulder occludes it from both vantages.
	print("--- line of sight from the two judged eyes ---")
	for label: String in ["square", "road"]:
		var eye: Vector2 = SQUARE_EYE if label == "square" else ROAD_EYE
		var eye_h: float = field.height_at(eye.x, eye.y) + 2.0
		for name: String in ["rocks", "trees", "grove"]:
			var seen := 0
			var total := 0
			for placement: Dictionary in all[name]:
				var pos: Vector3 = placement["position"]
				var flat := Vector2(pos.x, pos.z)
				if flat.distance_to(CENTRE) > 98.0:
					continue
				if (flat - CENTRE).dot((SQUARE_EYE - CENTRE).normalized()) < -10.0:
					continue
				total += 1
				if _visible(field, eye, eye_h, flat, pos.y + 1.5):
					seen += 1
			if total > 0:
				print("  %-6s %-6s %d/%d visible" % [label, name, seen, total])
	quit(0)


func _visible(field: RefCounted, eye: Vector2, eye_h: float, target: Vector2, target_h: float) -> bool:
	var steps := 90
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var p: Vector2 = eye.lerp(target, t)
		var ray := lerpf(eye_h, target_h, t)
		if field.height_at(p.x, p.y) > ray:
			return false
	return true

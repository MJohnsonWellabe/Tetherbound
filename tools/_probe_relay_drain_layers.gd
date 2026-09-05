extends SceneTree

## CL-E12 follow-up: WHAT does the drain actually take out of the relay's own
## three stations, layer by layer?
##
##   godot --headless --path . --script tools/_probe_relay_drain_layers.gd
##
## Asked because a code-blind judge, given the before/after pair from the
## `06-relay-standing` stand and told nothing, pixel-matched the ground and
## reported that the soil and its planting are IDENTICAL across the heal --
## the same bellflower clumps in the same places, the same bare-earth
## coverage -- and that what actually arrives is a canopy of trees. That is a
## claim about the mechanism, not about the frames, and it is worth a number.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const RELAY_CONFIG := "res://data/config/tether_relay.json"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 180:
		await physics_frame
	var vegetation := world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		print("[drain-layers] no Vegetation node")
		quit(1)
		return
	var discs := _relay_discs()
	var held: Dictionary = vegetation.get("_drained")
	var inside: Dictionary = {}
	var outside := 0
	var models: Dictionary = {}
	for layer_name: String in held.keys():
		for entry: Variant in (held[layer_name] as Array):
			var placement: Dictionary = entry
			var at: Vector3 = placement.get("position", Vector3.ZERO)
			var spot := Vector2(at.x, at.z)
			var is_in := false
			for raw: Variant in discs:
				var disc: Dictionary = raw
				if spot.distance_to(disc["centre"] as Vector2) <= float(disc["radius"]):
					is_in = true
					break
			if not is_in:
				outside += 1
				continue
			inside[layer_name] = int(inside.get(layer_name, 0)) + 1
			var model := str(placement.get("model", "?")).get_file()
			models[model] = int(models.get(model, 0)) + 1
	var total := 0
	for layer_name: String in inside.keys():
		total += int(inside[layer_name])
	print("[drain-layers] inside the relay's own %d stations: %d placements held by the drain"
		% [discs.size(), total])
	for layer_name: String in inside.keys():
		print("[drain-layers]   layer %-14s %d" % [layer_name, int(inside[layer_name])])
	print("[drain-layers] by model:")
	for model: String in models.keys():
		print("[drain-layers]   %-40s %d" % [model, int(models[model])])
	print("[drain-layers] elsewhere on the map: %d" % outside)
	# The other half of the question: what the grass field took OFF the table
	# before the healing could ever see it.
	const GRASS := preload("res://scripts/world/grass_field.gd")
	print("[drain-layers] grass field enabled: %s, suppressing: %s"
		% [str(GRASS.is_enabled()), str(GRASS.suppressed_layers().keys())])
	quit(0)


func _relay_discs() -> Array:
	var relay_config := _json(RELAY_CONFIG)
	var wanted: Dictionary = {}
	for raw: Variant in ((relay_config.get("dead_ground", {}) as Dictionary).get("heal_stations", []) as Array):
		wanted[str(raw)] = true
	var discs: Array = []
	for raw: Variant in ((_json(TERRAIN_CONFIG).get("drains", {}) as Dictionary).get("stations", []) as Array):
		var station: Dictionary = raw
		if not wanted.has(str(station.get("id", ""))):
			continue
		var centre: Array = station.get("centre", [])
		if centre.size() < 2:
			continue
		discs.append({"centre": Vector2(float(centre[0]), float(centre[1])),
			"radius": float(station.get("radius", 0.0))})
	return discs


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

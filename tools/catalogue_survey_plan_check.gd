extends SceneTree

## Pure catalogue-schema and canonical-coordinate check. Loads no world scene.

const PATH := "res://data/config/debug_teleport_spots.json"
const EXPECTED_DESTINATIONS := {"meadows": 10, "cloudreach": 12, "stormwood": 12, "water": 24}


func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("catalogue root is not a dictionary")
		return
	var seen := {}
	var total := 0
	for raw_biome: Variant in (parsed as Dictionary).get("biomes", []):
		if typeof(raw_biome) != TYPE_DICTIONARY:
			_fail("biome row is not a dictionary")
			return
		var biome := raw_biome as Dictionary
		var biome_id := str(biome.get("id", ""))
		if not EXPECTED_DESTINATIONS.has(biome_id):
			_fail("unexpected biome id %s" % biome_id)
			return
		var count := 0
		for raw_band: Variant in biome.get("bands", []):
			if typeof(raw_band) != TYPE_DICTIONARY:
				_fail("%s has a non-dictionary band" % biome_id)
				return
			for raw_spot: Variant in (raw_band as Dictionary).get("spots", []):
				if typeof(raw_spot) != TYPE_DICTIONARY:
					_fail("%s has a non-dictionary spot" % biome_id)
					return
				var spot := raw_spot as Dictionary
				var value: Variant = spot.get("position", null)
				if typeof(value) != TYPE_ARRAY or (value as Array).size() != 2:
					_fail("%s/%s position must be Array[x,z]" % [biome_id, str(spot.get("display_name", ""))])
					return
				var pair := value as Array
				if typeof(pair[0]) not in [TYPE_INT, TYPE_FLOAT] or typeof(pair[1]) not in [TYPE_INT, TYPE_FLOAT]:
					_fail("%s/%s position elements must be numeric" % [biome_id, str(spot.get("display_name", ""))])
					return
				var x := float(pair[0])
				var z := float(pair[1])
				if not is_finite(x) or not is_finite(z):
					_fail("%s/%s position must be finite" % [biome_id, str(spot.get("display_name", ""))])
					return
				var key := "%s|%.6f|%.6f" % [biome_id, x, z]
				if seen.has(key):
					_fail("duplicate canonical coordinate %s" % key)
					return
				seen[key] = true
				count += 1
				total += 1
		if count != int(EXPECTED_DESTINATIONS[biome_id]):
			_fail("%s expected %d destinations, found %d" % [biome_id, int(EXPECTED_DESTINATIONS[biome_id]), count])
			return
		print("CATALOGUE PLAN %s OK: %d destinations / %d day-night frames" % [biome_id, count, count * 2])
	if total != 58:
		_fail("expected 58 total destinations, found %d" % total)
		return
	print("CATALOGUE PLAN OK: 58 canonical coordinates / 116 required day-night frames")
	quit(0)


func _fail(message: String) -> void:
	push_error("CATALOGUE PLAN FAILED: %s" % message)
	quit(1)

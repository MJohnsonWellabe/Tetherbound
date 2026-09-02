extends SceneTree

## OWNER-0902-VILLAGE-POPULATION-REGRESSION, 2026-09-02. Actually count the
## village's population instead of reading a diff and hoping.
##
## Both 2026-09-01 and 2026-09-02 owner playtests reported "too many people
## in the village". The first fix (OWNER-0901-VILLAGE-POPULATION, 8edfcf58)
## repositioned three NPCs but never checked whether the ENCLOSED HEADCOUNT
## actually changed -- it hadn't: same 15 always-present bodies inside
## data/config/village_boundary.json's fence before and after. This probe is
## the check that should have caught that the first time: it point-in-polygon
## tests every village_npcs.json entry against the real boundary outline and
## reports how many bodies a player walking the settlement actually meets,
## split into always-present vs flag-gated and in-fence vs out.
##
##   godot --headless --path . --script tools/_probe_village_population_count.gd
##
## Re-run this after ANY village_npcs.json change that claims to affect
## crowding -- a position edit that keeps everyone inside the same fence is
## not a population fix, and this is what proves it either way.

const VILLAGE_NPCS_CONFIG := "res://data/config/village_npcs.json"
const VILLAGE_BOUNDARY_CONFIG := "res://data/config/village_boundary.json"
const WELL := Vector2(10.0, -10.0)
const SQUARE_RADIUS := 18.0


func _init() -> void:
	var npcs: Variant = _load_json(VILLAGE_NPCS_CONFIG)
	var boundary: Variant = _load_json(VILLAGE_BOUNDARY_CONFIG)
	if not (npcs is Dictionary) or not (boundary is Dictionary):
		push_error("could not load village_npcs.json or village_boundary.json")
		quit(1)
		return

	var poly: Array = ((boundary as Dictionary).get("outline", {}) as Dictionary).get("points", []) as Array
	if poly.is_empty():
		push_error("village_boundary.json has no outline.points")
		quit(1)
		return

	var villagers: Array = (npcs as Dictionary).get("villagers", []) as Array
	var always_in_fence := 0
	var always_total := 0
	var gated_in_fence := 0
	var square_core := 0

	print("%-16s %8s %8s %12s %10s %8s" % ["name", "x", "z", "in_boundary", "dist_well", "gated"])
	for entry: Variant in villagers:
		var v: Dictionary = entry
		var pos: Variant = v.get("position")
		if not (pos is Array) or (pos as Array).size() < 2:
			continue
		var x: float = (pos as Array)[0]
		var z: float = (pos as Array)[1]
		var gated: bool = v.has("place_when")
		var in_fence := _point_in_polygon(x, z, poly)
		var d: float = Vector2(x, z).distance_to(WELL)

		print("%-16s %8.1f %8.1f %12s %10.1f %8s" % [
			str(v.get("name", "?")), x, z, str(in_fence), d, str(gated)])

		if not gated:
			always_total += 1
			if in_fence:
				always_in_fence += 1
				if d <= SQUARE_RADIUS:
					square_core += 1
		elif in_fence:
			gated_in_fence += 1

	print("")
	print("always-present civilians: %d" % always_total)
	print("always-present civilians inside village_boundary.json's fence: %d" % always_in_fence)
	print("  of those, inside the %.0fm well-radius square: %d" % [SQUARE_RADIUS, square_core])
	print("flag-gated civilians (place_when) that land inside the fence once their flag is set: %d" % gated_in_fence)
	quit(0)


func _point_in_polygon(x: float, z: float, poly: Array) -> bool:
	var inside := false
	var j: int = poly.size() - 1
	for i in poly.size():
		var pi: Array = poly[i]
		var pj: Array = poly[j]
		var xi: float = pi[0]
		var zi: float = pi[1]
		var xj: float = pj[0]
		var zj: float = pj[1]
		if ((zi > z) != (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi) + xi):
			inside = not inside
		j = i
	return inside


func _load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())

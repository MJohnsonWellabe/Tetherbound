extends RefCounted

## Closed mandatory docks seal the land behind them (WORLD §6.1: currents and
## cliffs explain every gate; adjacent beaches may not bypass a dock).
##
## Each island and rest shoal inherits the ordered unlock flags of the
## mandatory docks between it and the realm arrival. While any of those shared
## world facts is missing, a visible tide race pushes every swimmer and swim
## mount radially away from that landform, faster than any of them can swim,
## and Fly treats the same volume as a sealed route. Once the dock opens, the
## race disappears and the authored crossing current is untouched.
##
## Pure data: no nodes, flags or randomness. The current field, the foam view,
## flight restrictions and tests all compile the same seal list from config.

const SWIMMING_PATH := "res://data/config/water_swimming.json"


static func load_rules(path: String = SWIMMING_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	var docks: Variant = (parsed as Dictionary).get("docks", {})
	var seal: Variant = (docks as Dictionary).get("seal_race", {}) if docks is Dictionary else {}
	return seal if seal is Dictionary else {}


## One entry per sealed landform: {id, kind, island_id, name, label, centre
## (Vector2 X/Z), shore_radius_m, required_flags, dock_ids}. Landforms reached
## without any unlock flag (the arrival island, open optional landings) are
## not returned.
static func compile(config: Dictionary) -> Array[Dictionary]:
	var anchor_island: Dictionary = {}
	for anchor: Dictionary in config.get("anchors", []):
		anchor_island[str(anchor.get("id", ""))] = str(anchor.get("island_id", ""))
	var names: Dictionary = {}
	var islands: Dictionary = {}
	for island: Dictionary in config.get("islands", []):
		names[str(island.get("id", ""))] = str(island.get("name", island.get("id", "")))
		islands[str(island.get("id", ""))] = island
	var entry: Variant = config.get("entry_anchors", {}).get("from_stormwood", {})
	var start := str((entry as Dictionary).get("island_id", "")) if entry is Dictionary else ""
	# Breadth-first over authored docks from the realm arrival. A landform keeps
	# the chain of the first path that reaches it; the authored graph is a tree.
	var required: Dictionary = {start: []}
	var dock_path: Dictionary = {start: []}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var from: String = queue.pop_front()
		for dock: Dictionary in config.get("docks", []):
			if str(dock.get("island_id", "")) != from:
				continue
			var to := str(anchor_island.get(str(dock.get("arrival_anchor", "")), ""))
			if to.is_empty() or required.has(to):
				continue
			required[to] = _extend(required[from], str(dock.get("unlock_flag", "")))
			dock_path[to] = _extend(dock_path[from], str(dock.get("id", "")) if not str(dock.get("unlock_flag", "")).is_empty() else "")
			queue.append(to)
	for id: String in islands:
		if not required.has(id):
			push_error("Water gate seals: no dock reaches island " + id)
	var seals: Array[Dictionary] = []
	for id: String in islands:
		var flags: Array = required.get(id, [])
		if flags.is_empty():
			continue
		var island: Dictionary = islands[id]
		seals.append(_seal(id, "island", id, str(names[id]), "the tide race around " + str(names[id]),
				island.get("center_xz_m", []), float(island.get("shore_radius_m", 0.0)), flags, dock_path.get(id, [])))
	for shoal: Dictionary in config.get("rest_shoals", []):
		var route := str(shoal.get("route_id", ""))
		for dock: Dictionary in config.get("docks", []):
			if not route.begins_with(str(dock.get("outbound_edge", "")) + "_"):
				continue
			var from := str(dock.get("island_id", ""))
			if not required.has(from):
				break
			var flags := _extend(required[from], str(dock.get("unlock_flag", "")))
			if flags.is_empty():
				break
			var to := str(anchor_island.get(str(dock.get("arrival_anchor", "")), ""))
			var docks := _extend(dock_path[from], str(dock.get("id", "")) if not str(dock.get("unlock_flag", "")).is_empty() else "")
			seals.append(_seal(str(shoal.get("id", "")), "rest_shoal", str(shoal.get("parent_island_id", "")),
					str(names.get(to, to)), "the tide race on the %s crossing" % str(names.get(to, to)),
					shoal.get("center_xz_m", []), float(shoal.get("shore_radius_m", 0.0)), flags, docks))
			break
	# A landform opens with its own final fact or any later fact on a chain
	# through it: a world holding a later fact has already come past it.
	for seal: Dictionary in seals:
		var chain: Array = seal.required_flags
		var opening: Array = [chain[-1]]
		for other: Dictionary in seals:
			var longer: Array = other.required_flags
			var at := longer.find(chain[-1])
			if at < 0:
				continue
			for index in range(at + 1, longer.size()):
				if not opening.has(longer[index]):
					opening.append(longer[index])
		seal["opening_flags"] = opening
	return seals


static func _extend(chain: Array, value: String) -> Array:
	var next := chain.duplicate()
	if not value.is_empty():
		next.append(value)
	return next


static func _seal(id: String, kind: String, island_id: String, name: String, label: String,
		centre: Variant, radius: float, flags: Array, docks: Array) -> Dictionary:
	var xz := Vector2(float(centre[0]), float(centre[1])) if centre is Array and centre.size() == 2 else Vector2.INF
	return {"id": id, "kind": kind, "island_id": island_id, "name": name, "label": label, "centre": xz,
		"shore_radius_m": radius, "required_flags": flags.duplicate(), "dock_ids": docks.duplicate()}


## Sealed until the landform's own final fact, or any fact further down a
## chain through it, is present. Earned worlds gain facts in chain order; a
## legacy or fixture world holding a later fact has already reached this
## landform and keeps its return (every dock's authored return_policy).
## A missing flag store means an analytical caller with every gate open.
static func is_sealed(seal: Dictionary, flags: Object) -> bool:
	if flags == null:
		return false
	for flag: String in seal.get("opening_flags", seal.get("required_flags", []).slice(-1)):
		if bool(flags.call("has", flag)):
			return false
	return not seal.get("required_flags", []).is_empty()


## The first missing dock on the chain: what the player has to clear next.
static func first_closed_dock(seal: Dictionary, flags: Object) -> String:
	var required: Array = seal.get("required_flags", [])
	var docks: Array = seal.get("dock_ids", [])
	for index in required.size():
		if flags == null or not bool(flags.call("has", str(required[index]))):
			return str(docks[index]) if index < docks.size() else ""
	return ""


static func outer_radius(seal: Dictionary, rules: Dictionary) -> float:
	return float(seal.get("shore_radius_m", 0.0)) + maxf(0.0, float(rules.get("width_m", 0.0)))


## Distance from `position` to this landform's shoreline (negative on land).
static func shore_gap(seal: Dictionary, position: Vector3) -> float:
	var centre: Vector2 = seal.get("centre", Vector2.INF)
	return Vector2(position.x, position.z).distance_to(centre) - float(seal.get("shore_radius_m", 0.0))


## Radial outward race velocity at `position`, or ZERO outside/open. The core
## band keeps full strength; only the outer edge blends into open water.
static func velocity_at(seal: Dictionary, rules: Dictionary, position: Vector3, flags: Object) -> Vector3:
	var centre: Vector2 = seal.get("centre", Vector2.INF)
	if not centre.is_finite() or not position.is_finite() or not is_sealed(seal, flags):
		return Vector3.ZERO
	var outer := outer_radius(seal, rules)
	var offset := Vector2(position.x, position.z) - centre
	var distance := offset.length()
	if distance >= outer:
		return Vector3.ZERO
	var blend := clampf(float(rules.get("edge_blend_m", 0.0)), 0.0, maxf(0.0, float(rules.get("width_m", 0.0))))
	var influence := 1.0 if blend <= 0.0 else 1.0 - smoothstep(outer - blend, outer, distance)
	# Dead centre has no radial direction; it is dry land, so any fixed choice
	# only has to be finite.
	var direction := Vector2(1, 0) if distance <= 0.0001 else offset / distance
	var strength := maxf(0.0, float(rules.get("strength_m_s", 0.0))) * influence
	return Vector3(direction.x, 0.0, direction.y) * strength


## World-authored flight volumes: the race disc as z-strips whose widths
## follow the circle, seabed to above Veilfall. A single square would overhang
## neighbouring earlier land at its corners; a small shoal needs one box.
static func flight_volumes(seal: Dictionary, rules: Dictionary) -> Array[AABB]:
	var centre: Vector2 = seal.get("centre", Vector2.ZERO)
	var outer := outer_radius(seal, rules)
	var floor_y := float(rules.get("flight_floor_y_m", -100.0))
	var height := float(rules.get("flight_ceiling_y_m", 1000.0)) - floor_y
	var strips := 1 if str(seal.get("kind", "")) == "rest_shoal" else maxi(1, int(rules.get("flight_strips", 8)))
	var volumes: Array[AABB] = []
	for index in strips:
		var z0 := centre.y - outer + 2.0 * outer * float(index) / float(strips)
		var z1 := centre.y - outer + 2.0 * outer * float(index + 1) / float(strips)
		var nearest := clampf(centre.y, z0, z1) - centre.y
		var half := sqrt(maxf(0.0, outer * outer - nearest * nearest))
		volumes.append(AABB(Vector3(centre.x - half, floor_y, z0), Vector3(half * 2.0, height, z1 - z0)))
	return volumes


## Keeps Fly's existing restriction list equal to the currently sealed discs.
## Fly accepts one required flag per restriction, while a seal opens on any of
## its `opening_flags`; correctness therefore depends on this re-sync running
## on every flag revision (water_gate_seal_view.gd::_refresh). Do not register
## these once at build time.
## Returns the number of restrictions now registered by the seals.
static func sync_flight(fly: Object, seals: Array[Dictionary], rules: Dictionary, flags: Object,
		dock_names: Dictionary) -> int:
	if fly == null or not fly.has_method("register_restriction"):
		return 0
	var ours: Dictionary = {}
	for seal: Dictionary in seals:
		ours[str(seal.label)] = true
	var entries: Array = fly.get("restrictions")
	for index in range(entries.size() - 1, -1, -1):
		if ours.has(str(entries[index].get("id", "")).get_slice(";", 0)):
			entries.remove_at(index)
	var count := 0
	for seal: Dictionary in seals:
		if not is_sealed(seal, flags):
			continue
		var dock := first_closed_dock(seal, flags)
		var id := "%s; clear the %s dock first" % [str(seal.label), str(dock_names.get(dock, dock))]
		for volume: AABB in flight_volumes(seal, rules):
			fly.call("register_restriction", id, volume, str(seal.required_flags[-1]))
			count += 1
	return count

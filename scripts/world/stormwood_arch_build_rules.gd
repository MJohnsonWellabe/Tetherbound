extends RefCounted

const ARCHES := preload("res://scripts/world/stormwood_arch_rules.gd")

static func cost(at: Vector3) -> Array:
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_items_recipes.json"))
	var result: Array = payload.recipes.stormglass_arch.cost.duplicate(true)
	if str(footing_at(at).get("fixed_twin", "")) == "e_crown":
		for row: Dictionary in result:
			if str(row.id) == "stormglass": row.id = "stormglass_crown"
	return result

static func records(buildings: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in buildings:
		if str(row.get("id", "")) == "stormglass_arch" and str(row.get("realm", "")) == "stormwood" and not bool(row.get("removed", false)):
			result.append(row)
	return result

static func footing_at(at: Vector3, radius: float = 5.0) -> Dictionary:
	for socket: Dictionary in ARCHES.config().footings:
		if Vector2(at.x, at.z).distance_to(Vector2(float(socket.at[0]), float(socket.at[1]))) <= radius:
			return socket
	return {}

## Host and placement preview share the gate. The host chooses the twin from
## committed records once, then saves both UIDs in the same atomic delta.
static func placement(at: Vector3, realm: String, flags: RefCounted, buildings: Array) -> Dictionary:
	if realm != "stormwood":
		return {"ok": false, "reason": "Stormglass roads belong to the Stormwood."}
	if not flags.has(str(ARCHES.config().recipe_flag)):
		return {"ok": false, "reason": "Keeper Ondra can teach you to raise an arch."}
	if not at.is_finite() or at.x < -2560 or at.x > 2048 or at.z < 0 or at.z > 6144:
		return {"ok": false, "reason": "The arch needs a footing inside the forest."}
	if at.z >= 3550 and not flags.has("stormwood:rootgate_released"):
		return {"ok": false, "reason": "The Rootgate must open before you build beyond it."}
	# The island and surrounding live glass cannot become a second access path.
	if at.x > 350 and at.z >= 2150 and at.z <= 3550:
		return {"ok": false, "reason": "Raise the Crown's twin on the Still Grove footing."}
	var socket := footing_at(at)
	if not socket.is_empty() and not ARCHES.is_available(socket, flags):
		return {"ok": false, "reason": "This footing's road has not opened yet."}
	var fixed := str(socket.get("fixed_twin", ""))
	var active := records(buildings)
	var ordinary_count := 0
	var crown_count := 0
	var unpaired := ""
	for row: Dictionary in active:
		var raw: Array = row.get("position", [])
		if raw.size() == 3 and at.distance_to(Vector3(float(raw[0]), float(raw[1]), float(raw[2]))) < 5.0:
			return {"ok": false, "reason": "Another arch already occupies this footing."}
		var twin := str(row.get("arch_twin", ""))
		if twin == "e_crown":
			crown_count += 1
			if fixed == twin:
				return {"ok": false, "reason": "The Crown already has its twin."}
			continue
		ordinary_count += 1
		if twin.is_empty() and unpaired.is_empty():
			unpaired = str(row.get("uid", ""))
	var limit := int(ARCHES.config().player_pair_limit)
	var full := ordinary_count >= (limit - crown_count) * 2 if fixed.is_empty() else ceili(float(ordinary_count) / 2.0) + crown_count >= limit
	if full:
		return {"ok": false, "reason": "Three player roads are already standing. Dismantle an arch first."}
	return {"ok": true, "reason": "", "twin": fixed if not fixed.is_empty() else unpaired,
		"footing": str(socket.get("id", "")), "crown": fixed == "e_crown"}

static func definition(uid: String, buildings: Array) -> Dictionary:
	for row: Dictionary in records(buildings):
		if str(row.get("uid", "")) == uid:
			var p: Array = row.position
			return {"id": uid, "name": "Raised Stormglass Arch", "at": [p[0], p[2]],
				"yaw_deg": row.get("yaw_deg", 0.0), "starts_lit": true,
				"arch_twin": str(row.get("arch_twin", "")), "constructed": true}
	return {}

static func linked_twin(id: String, flags: RefCounted, buildings: Array) -> Dictionary:
	if id == "e_crown":
		for row: Dictionary in records(buildings):
			if str(row.get("arch_twin", "")) == id:
				return definition(str(row.uid), buildings)
		return {}
	var source := definition(id, buildings)
	if source.is_empty():
		return ARCHES.linked_twin(id, flags)
	var twin_id := str(source.arch_twin)
	if twin_id == "e_crown":
		return ARCHES.definition(twin_id)
	var twin := definition(twin_id, buildings)
	if twin.is_empty() or str(twin.arch_twin) != id:
		return {}
	return twin

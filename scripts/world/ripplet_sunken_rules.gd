extends RefCounted

const RIPPLET := preload("res://scripts/player/ripplet_traversal.gd")
const SATCHEL := preload("res://scripts/world/death_satchel_rules.gd")
const HARVEST := preload("res://scripts/world/harvest_logic.gd")

static func site(id: String) -> Dictionary:
	for row: Dictionary in RIPPLET.config().sites:
		if row.id == id: return row
	return {}

static func previous_flag(row: Dictionary, flags: RefCounted) -> String:
	var prefix := "cache:ripplet:" + str(row.id)
	if row.kind == "cache": return prefix if flags.has(prefix) else ""
	var latest := ""
	for flag: String in flags.all_set():
		if flag.begins_with(prefix + ":day:") and (latest.is_empty() or int(flag.get_slice(":", 4)) > int(latest.get_slice(":", 4))): latest = flag
	return latest

static func node_candidate(row: Dictionary, previous: String, day: int) -> Dictionary:
	# Existing durable world flags carry the last harvest day until the shared
	# F32 stock service is integrated. Its pure timing/yield rules stay canonical.
	var stock := {"revision":0, "next_ready_day":1}
	if not previous.is_empty():
		stock.revision = 1
		stock.next_ready_day = int(previous.get_slice(":", 4)) + int(row.respawn_days)
	var definition := row.duplicate(true)
	definition.realm = "water"
	definition.outputs = row.get("outputs", {str(row.item):int(row.count)})
	return HARVEST.renewable_candidate(definition, stock, day, int(stock.revision))

static func claim_key(row: Dictionary, flags: RefCounted, day: int) -> String:
	var previous := previous_flag(row, flags)
	var prefix := "cache:ripplet:" + str(row.id)
	if row.kind == "cache": return prefix if previous.is_empty() else ""
	if not node_candidate(row, previous, day).get("ok", false): return ""
	return prefix + ":day:" + str(day)

static func evaluate(intent: Dictionary, actor: Dictionary, flags: RefCounted, day: int) -> Dictionary:
	var row := site(str(intent.get("site_id", "")))
	if row.is_empty(): return RIPPLET.deny("That sunken find is unknown.")
	var uid := str(intent.get("creature_uid", ""))
	if actor.get("realm") != "water" or not actor.get("diving", false) or actor.get("mounted_uid") != uid \
		or actor.get("combat", true) or actor.get("sealed", true) or not actor.get("motion_valid", true) or not RIPPLET.can_dive(actor.get("admitted", {}), uid):
		return RIPPLET.deny("Dive with your own Ripplet to reach this find.")
	var raw: Array = row.position
	var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	var position: Variant = actor.get("position")
	if not position is Vector3 or not position.is_finite() or position.distance_to(at) > 3.6: return RIPPLET.deny("Move closer to the sunken find.")
	var key := claim_key(row, flags, day)
	if key.is_empty() or intent.get("claim_key") != key: return RIPPLET.deny("That find is spent or has changed. Try again when it returns.")
	var slots: Variant = actor.get("admitted", {}).get("inventory", [])
	if not SATCHEL.valid_slots(slots): return RIPPLET.deny("Your satchel is not ready.")
	var inventory := SATCHEL.inventory_from(slots)
	var outputs: Dictionary = row.get("outputs", {str(row.item):int(row.count)})
	if row.kind == "node": outputs = node_candidate(row, previous_flag(row, flags), day).outputs
	for item: String in outputs:
		if inventory.add(item,int(outputs[item])) != 0: return RIPPLET.deny("Make room for the whole find first.")
	return {"ok":true, "reason":"", "row":row, "outputs":outputs, "key":key, "previous":previous_flag(row, flags), "character_id":actor.admitted.character_id}

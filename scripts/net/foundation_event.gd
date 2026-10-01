extends RefCounted

## Ordered host obligations use the existing reward_deliveries world carrier.
## This codec grants nothing; only the authenticated production writer appends.
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const FIELDS := ["version", "kind", "delivery_id", "world_id", "world_namespace", "session_id", "source_id", "duties", "status"]

static func make(world: RefCounted, epoch: String, source: String, duties: Array) -> Dictionary:
	var row := {"version": 1, "kind": "foundation_event", "world_id": world.world_id,
		"world_namespace": world.reward_delivery_namespace, "session_id": epoch, "source_id": source,
		"duties": duties.duplicate(true), "status": "retained"}
	row.delivery_id = identity(row)
	return row if valid(row, world.reward_delivery_namespace, world.world_id) else {}

static func identity(row: Dictionary) -> String:
	return "foundation_event:" + JSON.stringify([row.get("world_namespace"), row.get("session_id"), row.get("source_id")]).sha256_text()

static func valid(raw: Variant, namespace: String, world_id: String) -> bool:
	if not raw is Dictionary or raw.size() != FIELDS.size(): return false
	for key: String in FIELDS:
		if not raw.has(key): return false
	if raw.version != 1 or raw.kind != "foundation_event" or raw.status != "retained" \
		or raw.world_namespace != namespace or raw.world_id != world_id or raw.delivery_id != identity(raw) \
		or not ESSENCE._opaque_id(raw.session_id) or not ESSENCE._opaque_id(raw.source_id) \
		or not raw.duties is Array or raw.duties.is_empty(): return false
	for duty: Variant in raw.duties:
		if not duty is Dictionary or duty.size() != 4 or not duty.get("character_id") is String or duty.character_id.is_empty() \
			or duty.get("action") not in ["research_event", "master_win", "boss_relic", "rematch_win", "bounty_event"] \
			or not duty.get("intent") is Dictionary or not duty.get("context") is Dictionary: return false
	return true

static func errors(rows: Dictionary, namespace: String, world_id: String) -> Array[String]:
	var result: Array[String] = []
	for key: Variant in rows:
		var row: Variant = rows[key]
		if str(key).begins_with("foundation_event:") or (row is Dictionary and row.get("kind") == "foundation_event"):
			if not valid(row, namespace, world_id) or row.delivery_id != key: result.append("Invalid retained Foundation event")
	return result

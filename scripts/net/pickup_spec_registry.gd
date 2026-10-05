extends RefCounted

## Host-side truth for one-time world finds. A guest's claim_pickup pays into
## the host's character authority (world_ledger._claim_pickup), so the item
## and count must come from the host's own world, never the request. Each
## find registers what it holds when the host's world stands it up
## (item_cache_pickup.gd and felled_resource.gd); key and TM finds carry their
## item in the flag itself. A flag the host never stood up returns {} and the
## claim keeps the legacy local-only grant, which never reaches the authority.

const KEY_PREFIX := "pickup:" # key_pickup.gd FLAG_PREFIX
const TM_PREFIX := "tm:" # tm_pickup.gd FLAG_PREFIX
const MAX_ENTRIES := 8192

static var _specs: Dictionary = {}


static func register(flag: String, item: String, count: int) -> void:
	if flag.is_empty() or item.is_empty() or count <= 0:
		return
	if _specs.size() >= MAX_ENTRIES and not _specs.has(flag):
		return
	_specs[flag] = {"item": item, "count": count}


## {item, count} the host holds for this find, or {} when unknown.
static func lookup(flag: String) -> Dictionary:
	if _specs.has(flag):
		return (_specs[flag] as Dictionary).duplicate()
	for prefix: String in [KEY_PREFIX, TM_PREFIX]:
		if flag.begins_with(prefix) and flag.length() > prefix.length():
			return {"item": flag.substr(prefix.length()), "count": 1}
	return {}


static func clear() -> void:
	_specs.clear()

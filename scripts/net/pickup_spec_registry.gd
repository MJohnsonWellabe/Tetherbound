extends RefCounted

## Host-side truth for one-time world finds. A guest's claim_pickup pays into
## the host's character authority (world_ledger._claim_pickup), so the item
## and count must come from the host's own world, never the request. Each
## find registers what it holds when the host's world stands it up
## (item_cache_pickup.gd, felled_resource.gd and harvest_node.gd); key and TM finds carry their
## item in the flag itself. A flag the host never stood up returns {} and the
## claim keeps the legacy local-only grant, which never reaches the authority.

const KEY_PREFIX := "pickup:" # key_pickup.gd FLAG_PREFIX
const TM_PREFIX := "tm:" # tm_pickup.gd FLAG_PREFIX
const MAX_ENTRIES := 8192

static var _specs: Dictionary = {}


## `alt_count` is a second legal yield for the same find (a harvest node's
## right-tool yield); 0 when there is only one.
static func register(flag: String, item: String, count: int, alt_count: int = 0) -> void:
	if flag.is_empty() or item.is_empty() or count <= 0:
		return
	if _specs.size() >= MAX_ENTRIES and not _specs.has(flag):
		return
	_specs[flag] = {"item": item, "count": count, "alt": maxi(0, alt_count)}


## The host-legal amount for a claim of this find: the requested amount when
## it is one of the registered yields, otherwise the base yield.
static func legal_amount(spec: Dictionary, requested: int) -> int:
	if spec.is_empty(): return 0
	if int(spec.get("alt", 0)) > 0 and requested == int(spec.alt): return requested
	return int(spec.get("count", 0))


## {item, count} the host holds for this find, or {} when unknown.
static func lookup(flag: String) -> Dictionary:
	if _specs.has(flag):
		return (_specs[flag] as Dictionary).duplicate()
	for prefix: String in [KEY_PREFIX, TM_PREFIX]:
		if flag.begins_with(prefix) and flag.length() > prefix.length():
			return {"item": flag.substr(prefix.length()), "count": 1, "alt": 0}
	return {}


static func clear() -> void:
	_specs.clear()

extends RefCounted

## Host-side truth for one-time world finds. A guest's claim_pickup pays into
## the host's character authority (world_ledger._claim_pickup), so the item
## and count must come from the host's own world, never the request. Each
## find registers what it holds when the host's world stands it up
## (item_cache_pickup.gd, felled_resource.gd, harvest_node.gd, key_pickup.gd and
## tm_pickup.gd). A flag the host never stood up returns {} and the
## claim keeps the legacy local-only grant, which never reaches the authority.

const MAX_ENTRIES := 8192

static var _specs: Dictionary = {}


## `tool` names the tool a harvest needs (harvest_node.gd: items.gathered_with)
## and `alt_count` is its right-tool yield; a tool-gated harvest pays only
## alt_count and only to a guest holding the tool.
static func register(flag: String, item: String, count: int, alt_count: int = 0, tool: String = "") -> void:
	if flag.is_empty() or item.is_empty() or count <= 0:
		return
	if _specs.size() >= MAX_ENTRIES and not _specs.has(flag):
		return
	_specs[flag] = {"item": item, "count": count, "alt": maxi(0, alt_count), "tool": tool}


## {item, count, alt, tool} the host's own world stood up for this find, or
## {} when unknown. Never inferred from the flag text: a forged
## "pickup:<any item>" must not mint into the host's record (review B3).
static func lookup(flag: String) -> Dictionary:
	if _specs.has(flag):
		return (_specs[flag] as Dictionary).duplicate()
	return {}


## A one-time find was claimed: its entry is no longer needed (keeps the
## registry far below MAX_ENTRIES over a long session; review S7).
static func consume(flag: String) -> void:
	_specs.erase(flag)


static func clear() -> void:
	_specs.clear()

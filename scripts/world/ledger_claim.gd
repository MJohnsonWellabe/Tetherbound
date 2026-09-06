extends RefCounted

## Stage B Wave 3 lane 3.B. What a pickup or a harvest point needs from the
## ledger, in one place.
##
## D103 turned every world find into an INTENT: the consumer stops writing its
## own progression flag and stops granting its own item, submits, and waits for
## the committed DELTA to tell it the claim landed. Six consumers do that --
## `item_cache_pickup.gd`, `key_pickup.gd`, `tm_pickup.gd`, `harvest_node.gd`,
## `felled_resource.gd` and `vegetation_harvest_point.gd` -- and the three
## things they all need are the same three things:
##
##   * find `Game.ledger` and submit through it;
##   * decide what a verdict means (`ok` -> it committed here and now,
##     `pending` -> the host has not answered and NOTHING may change locally,
##     anything else -> a refusal with one sentence to show);
##   * recognise the committed delta when it arrives.
##
## `scripts/build/storage_container.gd` (lane 3.D) is the finished precedent for
## the conversation itself; this is the same conversation with the parts that
## are identical across six files lifted out rather than pasted six times. It
## deliberately holds no state: the consumer owns whether it has a claim in
## flight, because the consumer is what a refusal has to be shown against.
##
## Nothing here repeats a RULE from `scripts/net/world_ledger.gd`. It reads a
## verdict and it reads a delta; it never decides whether a claim is valid.

const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")


## `Game.ledger` -- the transport lane 3.A mounts at an identical path in every
## process. `null` when there is no `Game` (a bare unit fixture), which every
## caller has to answer for anyway.
static func transport(node: Node) -> Node:
	if node == null or not node.is_inside_tree():
		return null
	var game := node.get_node_or_null(^"/root/Game")
	if game == null:
		return null
	return game.get("ledger") as Node


## Submit `intent` and hand back `world_ledger.gd`'s verdict shape, always --
## never `null`, so no caller branches on the type of the answer. A hard
## refusal is SHOWN here (one sentence, through `Game.push_world_message`)
## because a host and a solo player get their refusal as this return value and
## nothing else would ever say it; a client's refusal arrives later and
## `ledger_rpc.gd::_rpc_verdict` speaks it there, so this cannot double up.
static func submit(node: Node, intent: Dictionary) -> Dictionary:
	var ledger := transport(node)
	if ledger == null:
		return {
			"ok": false, "kind": str(intent.get("kind", "")), "peer": 0,
			"code": "offline", "reason": "The world is not ready yet.",
			"pending": false, "delta": {"seq": 0, "realm": "", "ops": []},
		}
	var verdict: Dictionary = ledger.call("submit", intent)
	if not bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)):
		var reason := str(verdict.get("reason", ""))
		var game := node.get_node_or_null(^"/root/Game")
		if game != null and not reason.is_empty():
			game.call("push_world_message", reason)
	return verdict


## Whether a caller may keep waiting on this verdict: it committed here and now
## (host or solo), or the host still has to answer. Either way the consumer
## changes NOTHING locally -- `delta_applied` is what removes a pickup, which is
## the single change that makes the race safe.
static func in_flight(verdict: Dictionary) -> bool:
	return bool(verdict.get("ok", false)) or bool(verdict.get("pending", false))


## Did this delta set world flag `flag` to true? That op is what "this find is
## claimed" IS -- the same `pickup:`/`cache:`/`tm:`/`harvest_node:` flag D72 and
## T3-PICKUPS already wrote, now written once by the host and mirrored to every
## peer, so recognising it needs no second id scheme.
static func sets_world_flag(delta: Dictionary, flag: String) -> bool:
	if flag.is_empty():
		return false
	for raw: Variant in (delta.get("ops", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("scope", "")) != "world" or str(op.get("op", "")) != "flag":
			continue
		if str(op.get("id", "")) == flag and bool(op.get("value", true)):
			return true
	return false


## The `scene`-scope ops in `delta` named `op_name`, for the live mirrors that
## own their own format -- today `veg_deplete`, whose durable half is an
## ordinary world flag and whose live half only `vegetation.gd` can apply.
## `WorldLedger.scene_ops()` is the filter; this only narrows it by name so a
## consumer does not re-write the same two lines.
static func scene_ops_named(delta: Dictionary, op_name: String) -> Array:
	var out: Array = []
	for raw: Variant in WORLD_LEDGER.scene_ops(delta):
		if str((raw as Dictionary).get("op", "")) == op_name:
			out.append(raw)
	return out


## Connect `handler` to the transport's `delta_applied`, idempotently. Every
## consumer here listens for exactly one signal and none of them should have to
## remember whether `_ready()` already ran once.
static func listen(node: Node, handler: Callable) -> bool:
	var ledger := transport(node)
	if ledger == null:
		return false
	if not ledger.is_connected("delta_applied", handler):
		ledger.connect("delta_applied", handler)
	return true

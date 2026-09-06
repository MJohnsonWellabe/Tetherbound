extends RefCounted

## Stage B Wave 5 lane 5.A. What a STORY TRIGGER needs from the ledger.
##
## `scripts/world/ledger_claim.gd` is the same idea for a pickup or a harvest
## point, and this is deliberately its sibling rather than an extension of it:
## a find is one op with one scope, and a story beat is two scopes that have to
## be told apart before anything is submitted. D99 is what tells them apart --
## `progression_state.scope_of()` classifies every flag id as `world` (something
## happened to THE WORLD once: a gate opened, a boss fell, a relay went dark) or
## `player` (a tutorial beat, a readiness check, a personal payoff) -- and this
## file is where that classification becomes an intent kind:
##
##   `world`  -> `set_world_flag`, committed once, mirrored to every peer.
##   `player` -> `grant_player_flag`, addressed to the peers who earned it --
##               the speaker alone for a personal beat, everybody for D99's
##               residual "a shared camp is everyone's camp" flags.
##
## Nothing here repeats a RULE from `scripts/net/world_ledger.gd`. It decides
## which intent a flag id IS and it reads a delta; the ledger decides whether
## the intent survives.
##
## ## Why a story trigger reads `world_flags()` and not `Game.progression`
##
## The merged view answers "does EITHER store hold this", which is the right
## question for an objective line and the wrong question for a gate. A gate that
## asks the merged view can be opened by a PLAYER flag that happens to collide
## with its id, and -- much more importantly -- reads as shut on the peer that
## did not personally open it if anybody ever mis-scopes the id. `world_flag()`
## below is the narrow read: the world's store, and only it. Directive rule 3 is
## the reason the narrow read matters at all: a character who is behind must
## walk through a gate somebody else opened.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")

## D99's residual table, made executable. These are PLAYER flags that are
## granted to EVERY connected peer the moment the world gains the pieces --
## "a shared camp is everyone's camp". A prefix entry covers the numbered
## ladder (`creature_bed_built_2`, `_3`) the same way `flag_scopes.json` does.
##
## Anything not named here is a personal fact and is addressed to one peer.
const SHARED_PLAYER_FLAG_IDS: Array[String] = [
	"home_built",
	"home_materials_gathered",
	"creature_bed_built",
]
const SHARED_PLAYER_FLAG_PREFIXES: Array[String] = [
	"creature_bed_built_",
]


## The world's own flag store (`Game.world.flags`), never the merged view.
## `null` when there is no `Game`, which every caller has to answer for anyway.
static func world_flags(node: Node) -> RefCounted:
	var game := _game(node)
	if game == null:
		return null
	if game.has_method("world_flags"):
		return game.call("world_flags") as RefCounted
	var world: Variant = game.get("world")
	return (world as RefCounted).get("flags") as RefCounted if world != null else null


## Does THE WORLD say this happened? The read every gate, bridge, relay and
## shrine restore path makes.
static func world_flag(node: Node, id: String) -> bool:
	var flags := world_flags(node)
	return flags != null and bool(flags.call("has", id))


## The realm a story intent belongs to (D97: every intent carries one and
## nothing reads a global "current realm"). `Game.current_realm` is already the
## LOCAL player's own `PlayerState.realm`, so this is per-player by
## construction -- two peers standing in two realms stamp two different realms,
## which is exactly the rule.
static func realm_of(node: Node) -> String:
	var game := _game(node)
	if game == null:
		return "meadows"
	var realm := str(game.get("current_realm"))
	return realm if not realm.is_empty() else "meadows"


## Every peer in the session, or `[]` solo -- in which case the ledger's own
## `_peers()` falls back to whoever asked, which solo is the only player there
## is. Read off the session rather than `Game.players` because the session's
## registry is the one list that is the same on every process.
static func session_peer_ids(node: Node) -> Array:
	var game := _game(node)
	if game == null:
		return []
	var session: Variant = game.get("session")
	if session == null:
		return []
	var out: Array = []
	for raw: Variant in ((session as Node).call("peers") as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = raw
		if not row.has("peer_id"):
			continue
		var id := int(row["peer_id"])
		if id != 0 and not out.has(id):
			out.append(id)
	return out


## THE entry point. Write story flag `id`, through the ledger, under whichever
## scope D99 gives it. Returns `world_ledger.gd`'s verdict shape, always.
##
## An id the scope table does not name is a `push_error` and a WORLD write --
## the same choice `merged_progression.gd::store_for()` already makes, and for
## the same reason: the error is how a missed classification gets found, and the
## write is why the game does not stall on one. `tests/test_flag_scopes.gd`
## guarantees no shipped id takes that path.
static func write_flag(node: Node, id: String, value: bool = true) -> Dictionary:
	if id.is_empty():
		return _offline("set_world_flag")
	var scope := PROGRESSION_STATE.scope_of(id)
	if scope == "":
		push_error("unscoped story flag: %s" % id)
	if scope == PROGRESSION_STATE.SCOPE_PLAYER:
		return grant_player_flag(node, id, peers_for_player_flag(node, id))
	return set_world_flag(node, id, value)


## One world fact, committed once for everybody.
static func set_world_flag(node: Node, id: String, value: bool = true) -> Dictionary:
	if id.is_empty():
		return _offline("set_world_flag")
	return LEDGER_CLAIM.submit(node, {
		"kind": "set_world_flag", "realm": realm_of(node), "id": id, "value": value,
	})


## One personal fact, addressed to `peers`. An empty `peers` means "whoever
## asked", which is the ledger's own default and is the right answer for the
## ordinary case: the speaker is the player whose conversation this is.
static func grant_player_flag(node: Node, id: String, peers: Array = []) -> Dictionary:
	if id.is_empty():
		return _offline("grant_player_flag")
	var intent := {"kind": "grant_player_flag", "realm": realm_of(node), "id": id}
	if not peers.is_empty():
		intent["peers"] = peers
	return LEDGER_CLAIM.submit(node, intent)


## Who a player flag is addressed to: everybody for D99's residual home and
## creature-bed flags, the asking peer for everything else.
static func peers_for_player_flag(node: Node, id: String) -> Array:
	if not is_shared_player_flag(id):
		return []
	return session_peer_ids(node)


## D99's residual table: is this one of the player flags a shared camp hands to
## everybody?
static func is_shared_player_flag(id: String) -> bool:
	if SHARED_PLAYER_FLAG_IDS.has(id):
		return true
	for prefix: String in SHARED_PLAYER_FLAG_PREFIXES:
		if id.begins_with(prefix):
			return true
	return false


## Did this delta set world flag `id`? The same reader
## `ledger_claim.sets_world_flag()` gives a pickup, spelled here so a story
## consumer has one import rather than two.
static func delta_sets_world_flag(delta: Dictionary, id: String) -> bool:
	return LEDGER_CLAIM.sets_world_flag(delta, id)


## Did this delta carry ANY world flag at all? A story restore path does not
## care which one moved -- it re-reads the world and re-poses itself -- so this
## is the cheap gate that keeps it from re-reading on a delta that only moved a
## chest's revision.
static func delta_has_world_flag(delta: Dictionary) -> bool:
	for raw: Variant in (delta.get("ops", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("scope", "")) == "world" and str(op.get("op", "")) == "flag":
			return true
	return false


## Connect `handler` to the ledger transport's `delta_applied`, idempotently.
##
## ORDERING, and this is the trap lane 3.B paid for: `ledger_rpc.gd::_rpc_delta`
## sweeps the `progression_restore` group BEFORE it emits `delta_applied`, and
## `_commit_here` (the host's and solo's path) does not sweep the group AT ALL.
## So a consumer that is only in the group is restored on clients and never on
## the host, and a consumer that only listens here is restored twice on clients.
## Every story consumer therefore does BOTH -- joins the group and listens here
## -- and makes its own `restore_progression_from_game()` idempotent, which it
## has to be anyway because a save reload calls it too.
static func listen(node: Node, handler: Callable) -> bool:
	return LEDGER_CLAIM.listen(node, handler)


## Re-pose every `progression_restore` consumer in this tree from `game`. The
## same sweep `ledger_rpc.gd::_restore_progression()` runs on a client, run here
## so the HOST -- whose committed delta never reaches `_rpc_delta` -- gets it
## too. Idempotent by contract: a restore path is written to be callable on any
## frame, from a save load, a snapshot, or a delta.
static func restore_all(node: Node) -> void:
	if node == null or not node.is_inside_tree():
		return
	var game := _game(node)
	var tree := node.get_tree()
	if game == null or tree == null:
		return
	for consumer in tree.get_nodes_in_group("progression_restore"):
		if consumer.has_method("restore_progression_from_game"):
			consumer.call("restore_progression_from_game", game)


static func _game(node: Node) -> Node:
	if node == null or not node.is_inside_tree():
		return null
	return node.get_node_or_null(^"/root/Game")


static func _offline(kind: String) -> Dictionary:
	return {
		"ok": false, "kind": kind, "peer": 0, "code": "malformed",
		"reason": "That story change has no identity to record.",
		"pending": false, "delta": {"seq": 0, "realm": "", "ops": []},
	}

extends Node

## Small scene adapter for production Game.progression. Add under a realm scene,
## configure before entering the tree, and call emit_event from successful world
## actions. It does not consume dialogue queues or own another progression store.
##
## ## Stage B Wave 6 lane 6.E: this is where a chapter flag becomes an intent
##
## D103. `realm_chapter_progression.gd` decides WHICH flags an event sets; this
## node is the only thing in that pair that lives in a scene tree, so it is
## where the write reaches `Game.ledger`. It hands the logic a `writer` --
## `_write_flag` below -- and the logic calls it instead of writing the flag
## itself.
##
## Two rules the shape exists for:
##
##   * **D97: the realm is the REALM'S own id, never `Game.current_realm`.**
##     `realm_id` is configured by the world that mounts this node
##     (`cloudreach_chapter.gd` sets `"cloudreach"`), so a Cloudreach act
##     completion is filed against Cloudreach whichever realm the local player
##     is standing in when it commits. From Wave 6 two peers stand in two
##     realms at once and `current_realm` is the local player's, not the
##     record's.
##   * **`pending` is not a refusal.** A client's submit returns pending and
##     nothing is set locally. The committed delta sets it, and `_process`'s
##     existing revision poll plus the `progression_restore` sweep both land on
##     `reconcile()` -- which is already the "recover the aggregates from
##     whatever the store now holds" path, written for save loads and reused
##     here unchanged.
signal chapter_changed(result: Dictionary)

const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

var realm_id := "cloudreach"
var chapter: Dictionary = {}
var _revision := -1


func _ready() -> void:
	add_to_group("realm_chapter_events")
	add_to_group("progression_restore")
	restore_progression_from_game(get_node_or_null(^"/root/Game"))


func _process(_delta: float) -> void:
	var game := get_node_or_null(^"/root/Game")
	if not _in_realm(game):
		return
	var progression: RefCounted = game.get("progression")
	if _revision != int(progression.get("revision")):
		_publish(game, LOGIC.reconcile(progression, chapter, _writer()))


func emit_event(event: String) -> Dictionary:
	var game := get_node_or_null(^"/root/Game")
	if not _in_realm(game):
		return {"accepted": false, "changed": false, "pending": false,
			"completed_ids": [], "granted_flags": []}
	var result := LOGIC.dispatch(game.get("progression"), chapter, event, _writer())
	_publish(game, result)
	return result


## Re-run the chapter's aggregate recovery through the ledger. `_process` does
## this on a revision change; `cloudreach_chapter.gd` calls it directly rather
## than reaching for `LOGIC.reconcile` itself, so there is exactly one place
## that knows a chapter flag is an intent and not a local write.
func reconcile_now() -> Dictionary:
	var game := get_node_or_null(^"/root/Game")
	if not _in_realm(game):
		return {"accepted": false, "changed": false, "pending": false,
			"completed_ids": [], "granted_flags": []}
	var result := LOGIC.reconcile(game.get("progression"), chapter, _writer())
	_publish(game, result)
	return result


func restore_progression_from_game(game: Node) -> void:
	_revision = -1
	if _in_realm(game):
		_publish(game, LOGIC.reconcile(game.get("progression"), chapter, _writer()))


func _in_realm(game: Node) -> bool:
	return game != null and str(game.get("current_realm")) == realm_id


## The `Callable(flag) -> verdict` `realm_chapter_progression.gd` writes through.
## Invalid when this node is not in a tree, which is the only state in which it
## could not reach a transport anyway -- the logic then takes its own local
## write path, exactly as it does under a unit fixture.
func _writer() -> Callable:
	if not is_inside_tree():
		return Callable()
	return Callable(self, "_write_flag")


## Submit ONE chapter flag as an intent, and answer with `world_ledger.gd`'s
## verdict shape -- always, never null.
##
## The kind is chosen by D99's scope table, the same classification
## `story_ledger.gd` makes for a dialogue effect. This does not call that file
## because its `realm_of()` reads `Game.current_realm`, which is precisely the
## read D97 forbids for a record: a chapter flag belongs to `realm_id`.
##
## A missing transport answers `offline` rather than pushing a world message:
## an early boot frame or a capture tool has nobody to tell, and the logic's own
## fallback is the right behaviour there, not a line on the player's screen.
func _write_flag(flag: String) -> Dictionary:
	var transport := LEDGER_CLAIM.transport(self)
	if transport == null:
		return _offline(flag)
	var scope := PROGRESSION_STATE.scope_of(flag)
	if scope == "":
		# The same loud-but-not-fatal choice `merged_progression.gd::store_for()`
		# makes: the error is how a missed classification gets found, and the
		# world write is why a chapter does not stall on one.
		push_error("unscoped chapter flag: %s" % flag)
	var kind := "grant_player_flag" if scope == PROGRESSION_STATE.SCOPE_PLAYER \
		else "set_world_flag"
	var intent := {"kind": kind, "realm": realm_id, "id": flag}
	if kind == "set_world_flag":
		intent["value"] = true
	return transport.call("submit", intent)


func _offline(flag: String) -> Dictionary:
	return {
		"ok": false, "kind": "set_world_flag", "peer": 0, "code": "offline",
		"reason": "", "pending": false, "id": flag,
		"delta": {"seq": 0, "realm": "", "ops": []},
	}


func _publish(game: Node, result: Dictionary) -> void:
	_revision = int(game.get("progression").get("revision"))
	if bool(result.get("changed", false)):
		chapter_changed.emit(result)

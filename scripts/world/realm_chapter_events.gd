extends Node

## Small scene adapter for production Game.progression. Add under a realm scene,
## configure before entering the tree, and call emit_event from successful world
## actions. It does not consume dialogue queues or own another progression store.
signal chapter_changed(result: Dictionary)

const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
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
		_publish(game, LOGIC.reconcile(progression, chapter))


func emit_event(event: String) -> Dictionary:
	var game := get_node_or_null(^"/root/Game")
	if not _in_realm(game):
		return {"accepted": false, "changed": false, "completed_ids": [], "granted_flags": []}
	var result := LOGIC.dispatch(game.get("progression"), chapter, event)
	_publish(game, result)
	return result


func restore_progression_from_game(game: Node) -> void:
	_revision = -1
	if _in_realm(game):
		_publish(game, LOGIC.reconcile(game.get("progression"), chapter))


func _in_realm(game: Node) -> bool:
	return game != null and str(game.get("current_realm")) == realm_id


func _publish(game: Node, result: Dictionary) -> void:
	_revision = int(game.get("progression").get("revision"))
	if bool(result.get("changed", false)):
		chapter_changed.emit(result)

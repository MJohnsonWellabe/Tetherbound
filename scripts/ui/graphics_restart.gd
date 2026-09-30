extends RefCounted

## Graphics restart preparation uses the existing save authority. Return a
## checked result before transport teardown or arming any process restart.
## No world write is permitted for a guest, including an incomplete join.
static func save_progress(game: Node) -> bool:
	if game == null:
		return false
	if bool(game.call("is_host")):
		return bool(game.call("save_game", int(game.call("autosave_slot"))))
	var session: Node = game.get("session")
	if session == null or not bool(session.call("client_character_save_ready")):
		return false
	var save_system: RefCounted = game.get("save_system")
	var local: RefCounted = game.get("local")
	if save_system == null or local == null:
		return false
	var character_id := str(local.get("character_id"))
	if character_id == "":
		return false
	game.call("_capture_player_pose")
	return bool(save_system.call("save_character", game, character_id))

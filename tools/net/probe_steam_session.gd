extends SceneTree

## Opt-in native integration probe. Run the pinned Steam runtime with isolated
## APPDATA and an explicit local TETHERBOUND_STEAM_APP_ID. Sends no invitations.
## Uses the real title host route, Meadows, coordinator and Session. It does
## not prove a remote join, internet relay delivery or the earned expedition.
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not Engine.has_singleton("Steam") or OS.get_environment("TETHERBOUND_STEAM_APP_ID").is_empty():
		print("Steam session probe requires the Steam runtime and an explicit local AppID")
		quit(2)
		return
	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	await process_frame
	await process_frame
	var title := current_scene
	var game := root.get_node("Game")
	var session: Node = game.get("session")
	var lobby := game.get_node_or_null("SteamLobby")
	if title == null or lobby == null:
		print("Steam session probe failed: title/coordinator did not mount")
		quit(1)
		return
	# Fixture: a fresh isolated character/world. No earned progression claimed.
	title.call("_show_host_friends_choices")
	if not bool(title.get("_friends_host_mode")):
		print("Steam session probe failed: ", lobby.call("last_error"))
		quit(1)
		return
	game.call("reset_for_new_game")
	title.call("_enter_world", "Hosting Steam integration probe…")
	var deadline := Time.get_ticks_msec() + 180000
	while not bool(lobby.call("is_hosting")) and Time.get_ticks_msec() < deadline:
		await process_frame
		if not str(lobby.call("last_error")).is_empty():
			break
	_check(bool(lobby.call("is_hosting")), "real Steam lobby ready after Meadows build: %s" % lobby.call("last_error"))
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/world/meadows_playground.tscn", "production Meadows is current")
	_check(session.call("transport_kind") == "steam", "Session installed native Steam transport")
	_check(bool(session.call("is_host")) and int(session.call("local_peer_id")) == 1, "authoritative host has peer id 1")
	_check(int(session.call("peer_count")) == 1, "registry contains exactly the local host")
	_check(game.get_node_or_null("LanBeacon") == null, "Steam route did not advertise a LAN address")
	var lobby_id := int(lobby.get("_current_lobby"))
	if lobby_id > 0:
		var steam := Engine.get_singleton("Steam")
		_check(str(steam.call("getLobbyData", lobby_id, "ready")) == "1", "lobby publishes ready only with active Session")
		_check(str(steam.call("getLobbyData", lobby_id, "product")) == "tetherbound", "lobby identifies the product")
		_check(int(steam.call("getLobbyMemberLimit", lobby_id)) == 4, "native lobby has four member capacity")
		var hello := {"steam_protocol": "tetherbound-invite-v1", "steam_lobby_id": lobby_id}
		_check(str(lobby.call("admission_error", 1, hello)).is_empty(), "native host identity resolves to current lobby membership")
		hello["steam_lobby_id"] = lobby_id + 1
		_check(not str(lobby.call("admission_error", 1, hello)).is_empty(), "wrong lobby claim is refused")
		var snapshot: Dictionary = session.call("_world_snapshot")
		print("Fresh-world snapshot Variant payload: %d bytes; excludes RPC framing and does not bound grown worlds" % var_to_bytes(snapshot).size())
	# Exercise production save/leave and coordinator teardown; no direct native
	# leave call can hide a lifecycle omission in the application.
	session.call("leave", "steam_probe_done")
	for frame in 10:
		await process_frame
	_check(not bool(session.call("is_active")), "session closed")
	_check(int(lobby.get("_current_lobby")) == 0 and not bool(lobby.call("is_hosting")), "coordinator released native lobby")
	print("Steam production host probe: %d failures; remote joining/relay/overlay untested" % _failures.size())
	quit(0 if _failures.is_empty() else 1)

func _check(passed: bool, label: String) -> void:
	print("  %s %s" % ["PASS" if passed else "FAIL", label])
	if not passed:
		_failures.append(label)

extends SceneTree

## Run in an empty temporary project with the pinned Steam runtime, not a world.
## Explicit TETHERBOUND_STEAM_APP_ID required. No invitations are sent.
## Proves local native initialization, host socket and lobby callback only.
var _steam: Object
var _peer: MultiplayerPeer
var _finished := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("Steam native probe engine: ", Engine.get_version_info().get("string"))
	var app_text := OS.get_environment("TETHERBOUND_STEAM_APP_ID")
	if not app_text.is_valid_int() or app_text.to_int() <= 0:
		_fail("Explicit local AppID required")
		return
	if not Engine.has_singleton("Steam") or not ClassDB.class_exists("SteamMultiplayerPeer"):
		_fail("Steam runtime classes missing")
		return
	_steam = Engine.get_singleton("Steam")
	var result: Dictionary = _steam.call("steamInitEx", app_text.to_int(), false)
	print("Steam initialization status: ", result.get("status", -1))
	if int(result.get("status", -1)) != 0:
		_fail("Steam initialization failed")
		return
	ProjectSettings.set_setting("steam/multiplayer_peer/max_channels", 4)
	_steam.call("initRelayNetworkAccess")
	_peer = ClassDB.instantiate("SteamMultiplayerPeer") as MultiplayerPeer
	_peer.set("server_relay", true)
	var error: int = _peer.call("create_host", 0)
	print("Native host: error=%d id=%d status=%d lanes=%d" % [error, _peer.get_unique_id(), _peer.get_connection_status(), ProjectSettings.get_setting("steam/multiplayer_peer/max_channels")])
	if error != OK or _peer.get_unique_id() != 1 or _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_fail("Native host socket failed")
		return
	_steam.connect("lobby_created", _on_lobby_created)
	# Private probe lobby, distinct from product friends-only sessions.
	_steam.call("createLobby", 0, 4)
	var deadline := Time.get_ticks_msec() + 20000
	while not _finished and Time.get_ticks_msec() < deadline:
		_steam.call("run_callbacks")
		await process_frame
	if not _finished:
		_fail("Native lobby callback timed out")

func _on_lobby_created(result: int, lobby: int) -> void:
	print("Private lobby callback: result=%d valid_id=%s" % [result, lobby > 0])
	if result != 1 or lobby <= 0:
		_fail("Native lobby creation failed")
		return
	_steam.call("leaveLobby", lobby)
	_peer.close()
	_finished = true
	print("Steam local host probe passed; no remote join or relay delivery was tested")
	quit(0)

func _fail(message: String) -> void:
	print("Steam native probe failed: ", message)
	if _peer != null:
		_peer.close()
	_finished = true
	quit(1)

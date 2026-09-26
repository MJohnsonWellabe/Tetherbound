extends Node

## Optional GodotSteam lobby/discovery coordinator.
##
## This script deliberately contains no compile-time reference to GodotSteam.
## A stock Godot build can parse and run the game; initialize() simply reports
## that Steam friends are unavailable. GodotSteam 4.20 (Godot 4.7 / SDK 1.64)
## exposes the singleton and SteamMultiplayerPeer dynamically.
##
## Lobby metadata carries the product, the wire protocol and the short
## build/content token from `build_fingerprint.gd`, so a joiner can refuse a
## mismatched friend before dialling. The token is a convenience check. The
## host's `session.gd::_rpc_hello` still compares the full fingerprint before
## admission.
##
## GodotSteam's native SteamPacketPeer reads
## `steam/multiplayer_peer/max_channels`; the project setting is pinned to 4
## by the integration owner. That leaves Session's application lanes 1 and 2
## valid (ledger/encounters and snapshots) under the Steam transport.

const BUILD_FINGERPRINT := preload("res://scripts/net/build_fingerprint.gd")
const PRODUCT := "tetherbound"
# v5 adds exact host confirmation for ordinary shared-wild catch completion.
# Bump the value in build_fingerprint.gd; ENet and Steam admission share it.
const PROTOCOL := BUILD_FINGERPRINT.WIRE_PROTOCOL
## Session maps this exact refusal to `incompatible_version`, the same code as
## a build/content mismatch.
const PROTOCOL_REFUSAL := "This connection uses an incompatible Tetherbound protocol."
const LOBBY_CAPACITY := 4
const FRIENDS_ONLY := 1
const CALLBACK_OK := 1
const JOIN_TIMEOUT_MS := 20_000
const WORLD_SETTLE_FRAMES := 30
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const APP_ID_SETTING := "steam/initialization/app_data/app_id"
## How long the in-world "invitation received" notice stays on screen.
const INVITE_NOTICE_S := 8.0
const INVITE_NOTICE_LAYER := 90

signal invite_received(lobby_id: int)
signal lobby_ready()
signal changed()

var _steam: Object = null
var _peer_factory: Callable
var _initialized := false
var _sdk_started := false
var _callbacks_connected := false
var _last_error := ""
var _status := "Steam friends are not initialized."
var _revision := 0
var _pending_invite := 0
## The friend whose Steam invite `_pending_invite` came from (join_requested);
## 0 when unknown (a cold-launch lobby id carries no inviter).
var _pending_inviter := 0

var _state := "idle"
var _deadline_ms := 0
var _settle_frames := 0
var _create_in_flight := false
var _joining_lobby := 0
var _current_lobby := 0
var _expected_host := 0
var _hosting := false
var _cancelled_joins: Dictionary = {}
var _terminal_transport_error := ""
## Last joinable value sent to Steam for the hosted lobby; null until the
## first publish, so the first host-ready refresh always writes it.
var _published_joinable: Variant = null
var _notice_layer: CanvasLayer = null
var _notice_label: Label = null
var _notice_until_ms := 0

## Focused tests inject a signal-compatible fake without making the product
## depend on a mock framework. Production never calls this hook.
var _test_app_id := 0
var _test_force_unavailable := false


static func ensure(game: Node) -> Node:
	if game == null:
		return null
	var existing := game.get_node_or_null(^"SteamLobby")
	if existing != null:
		return existing
	var coordinator := new()
	coordinator.name = "SteamLobby"
	game.add_child(coordinator)
	return coordinator


func _ready() -> void:
	name = "SteamLobby"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_session()


func initialize() -> bool:
	if _initialized:
		return true
	var app_id := _test_app_id if _test_app_id > 0 else configured_app_id()
	if app_id <= 0:
		_set_error("Steam friends need a Tetherbound Steam App ID.")
		return false
	if _test_force_unavailable:
		_set_error("Steam friends are unavailable in this build.")
		return false
	if _steam == null:
		if not Engine.has_singleton("Steam"):
			_set_error("Steam friends are unavailable in this build.")
			return false
		_steam = Engine.get_singleton("Steam")
	if _steam == null or not _steam.has_method("steamInit"):
		_set_error("Steam friends are unavailable in this build.")
		return false
	if _test_app_id <= 0 and not ClassDB.class_exists("SteamMultiplayerPeer"):
		_set_error("Steam networking is unavailable in this build.")
		return false
	_connect_callbacks_once()
	# Callbacks are pumped by _process(), so embedded callbacks stay disabled.
	if not _sdk_started:
		if not bool(_steam.call("steamInit", app_id, false)):
			_set_error("Steam could not start. Open Steam and sign in, then try again.")
			return false
		_sdk_started = true
	if _steam.has_method("loggedOn") and not bool(_steam.call("loggedOn")):
		_set_error("Steam is offline. Sign in before using friend invitations.")
		return false
	_initialized = true
	_status = "Steam friends are ready."
	_last_error = ""
	if _steam.has_method("initRelayNetworkAccess"):
		_steam.call("initRelayNetworkAccess")
	_bind_session()
	_queue_launch_invite()
	_touch()
	return true


func last_error() -> String:
	return _last_error


func status_text() -> String:
	return _status


func revision() -> int:
	return _revision


func pending_invite_id() -> int:
	return _pending_invite


## The Steam name of the friend who sent the pending invite, for the Join
## Friend screen (MULTIPLAYER: show who the invitation is from before joining).
## Empty when no invite is pending (or `lobby_id` names another one), its
## sender is unknown, or Steam has no name for them yet.
func pending_inviter_name(lobby_id: int = 0) -> String:
	if _pending_invite <= 0 or _pending_inviter <= 0 or _steam == null \
			or not _steam.has_method("getFriendPersonaName"):
		return ""
	if lobby_id > 0 and lobby_id != _pending_invite:
		return ""
	var name := str(_steam.call("getFriendPersonaName", _pending_inviter)).strip_edges()
	return "" if name == "[unknown]" else name


## Native lobby requests have no request token.  After a timeout the old
## callback must finish before another request can be attributed safely.
func retry_pending_reason(lobby_id: int = 0) -> String:
	if _create_in_flight:
		return "Steam is still finishing the friends lobby request. Retry will be available when it responds. Restart the game if it never finishes."
	if lobby_id > 0 and _cancelled_joins.has(lobby_id):
		return "Steam is still finishing the join request. Retry will be available when it responds. Restart the game if it never finishes."
	return ""


func clear_pending_invite() -> void:
	if _pending_invite == 0:
		return
	_pending_invite = 0
	_pending_inviter = 0
	_touch()


## Arm friends-only hosting before the title changes scene. Lobby creation is
## deferred until the authored world is standing and has settled for the same
## 30 frames used by JoinDriver.
func begin_host_after_world() -> bool:
	if not initialize():
		return false
	if _hosting:
		return true
	if _create_in_flight:
		_set_error("Steam is still finishing the previous lobby request.")
		return false
	var session := _session()
	if session == null:
		_set_error("This build has no multiplayer session to host with.")
		return false
	if bool(session.call("is_active")):
		_set_error("Close the current session before hosting for friends.")
		return false
	_state = "host_waiting_for_world"
	_settle_frames = WORLD_SETTLE_FRAMES
	_status = "Loading the world before opening the friends lobby…"
	_last_error = ""
	_touch()
	return true


## Join the discovery lobby only. The UI chooses/applies a portable character
## and builds its world after lobby_ready; dial_selected_friend() opens the
## actual peer from the far side of that build.
func request_join(lobby_id: int) -> bool:
	if not initialize():
		return false
	if lobby_id <= 0:
		_set_error("That Steam invitation is invalid.")
		return false
	if _hosting or _session_is_live():
		_set_pending_invite(lobby_id)
		_set_error("Leave the current world before joining this invitation.")
		return false
	if _state == "joining_lobby":
		_set_error("Steam is already joining a friends lobby.")
		return false
	if _cancelled_joins.has(lobby_id):
		_set_error("Steam is still closing the previous attempt for this lobby.")
		return false
	if _current_lobby != 0:
		_leave_lobby(_current_lobby)
		_current_lobby = 0
	_joining_lobby = lobby_id
	if _pending_invite == lobby_id:
		_pending_invite = 0
		_pending_inviter = 0
	_state = "joining_lobby"
	_deadline_ms = Time.get_ticks_msec() + JOIN_TIMEOUT_MS
	_status = "Joining your friend’s Steam lobby…"
	_last_error = ""
	_steam.call("joinLobby", lobby_id)
	_touch()
	return true


## Called only by JoinDriver after its world-settle boundary.
func dial_selected_friend(summary: Dictionary) -> bool:
	if not _initialized or _state != "lobby_ready" or _current_lobby <= 0:
		_set_error("Join the friend lobby before connecting to its world.")
		return false
	var owner := int(_steam.call("getLobbyOwner", _current_lobby))
	if owner <= 0:
		_fail_join("That lobby no longer has a host.", true)
		return false
	if _expected_host <= 0 or owner != _expected_host:
		_fail_join("That lobby’s original host left; host migration is not supported.", true)
		return false
	var session := _session()
	if session == null:
		_set_error("This build has no multiplayer session to join with.")
		return false
	var peer := _make_peer()
	if peer == null:
		_set_error("Steam networking is unavailable in this build.")
		return false
	peer.set("server_relay", true)
	var err := int(peer.call("create_client", owner, 0))
	if err != OK:
		peer.call("close")
		_set_error("Could not open a Steam connection to the lobby host.")
		return false
	var hello := summary.duplicate(true)
	hello["steam_protocol"] = PROTOCOL
	hello["steam_lobby_id"] = _current_lobby
	if not bool(session.call("join_with_peer", peer, hello, "steam")):
		peer.call("close")
		_set_error("The Steam connection could not start the game session.")
		return false
	_state = "connecting"
	_status = "Connecting to your friend’s world…"
	_last_error = ""
	_touch()
	return true


func is_hosting() -> bool:
	return _hosting


## True while this machine hosts a friends lobby whose game session already
## seats LOBBY_CAPACITY players. The Players tab disables Invite on it, and the
## lobby is published unjoinable so a Steam "Join Game" cannot even try.
func is_full() -> bool:
	if not _hosting:
		return false
	var session := _session()
	return session != null and bool(session.call("is_active")) \
		and int(session.call("peer_count")) >= LOBBY_CAPACITY


## Mirrors the session's free seats onto Steam's joinable flag. Called on host
## ready and on every admitted/departed peer.
func _refresh_joinable() -> void:
	if not _hosting or _current_lobby <= 0 or _steam == null \
			or not _steam.has_method("setLobbyJoinable"):
		return
	var joinable := not is_full()
	if _published_joinable != null and bool(_published_joinable) == joinable:
		return
	_steam.call("setLobbyJoinable", _current_lobby, joinable)
	_published_joinable = joinable
	_touch()


func _on_session_peers_changed(_peer_id: int, _character_id: String = "") -> void:
	_refresh_joinable()


## A Steam socket is not lobby admission. Bind the native transport identity
## to current membership before Session prepares realms or sends its snapshot.
func admission_error(peer_id: int, summary: Dictionary) -> String:
	if not _hosting or _current_lobby <= 0:
		return "The friends lobby is no longer available."
	var session := _session()
	var peer: MultiplayerPeer = session.get("_peer") if session != null else null
	if peer == null or not peer.has_method("get_steam_id_for_peer_id"):
		return "The Steam connection identity could not be verified."
	var steam_id := int(peer.call("get_steam_id_for_peer_id", peer_id))
	var members: Array[int] = []
	for index in int(_steam.call("getNumLobbyMembers", _current_lobby)):
		members.append(int(_steam.call("getLobbyMemberByIndex", _current_lobby, index)))
	return member_admission_error(steam_id, members, _current_lobby, summary)


static func member_admission_error(steam_id: int, members: Array[int],
		lobby_id: int, summary: Dictionary) -> String:
	if steam_id <= 0 or not members.has(steam_id):
		return "Join the friends lobby before connecting to this world."
	if summary.get("steam_protocol") != PROTOCOL:
		return PROTOCOL_REFUSAL
	if summary.get("steam_lobby_id") != lobby_id:
		return "This connection belongs to a different friends lobby."
	return ""


func invite_friends() -> bool:
	if not _initialized or not _hosting or _state != "host_ready" or _current_lobby <= 0:
		_set_error("Finish opening the friends lobby before inviting anyone.")
		return false
	if is_full():
		_set_error("This world is full (%d/%d). A friend can be invited when a seat opens." \
			% [LOBBY_CAPACITY, LOBBY_CAPACITY])
		return false
	if not _steam.has_method("isOverlayEnabled") or not bool(_steam.call("isOverlayEnabled")):
		_set_error("The Steam invite overlay is unavailable. Check that the Steam overlay is enabled.")
		return false
	_steam.call("activateGameOverlayInviteDialog", _current_lobby)
	return true


## Cancels only a prospective client join. It never closes an active hosted
## game; a late successful callback is recognized and immediately left.
func cancel_join() -> void:
	if _hosting or _session_is_live():
		return
	if _joining_lobby != 0:
		_cancelled_joins[_joining_lobby] = "cancelled"
		_leave_lobby(_joining_lobby)
		_joining_lobby = 0
	if _current_lobby != 0:
		_leave_lobby(_current_lobby)
		_current_lobby = 0
	if _state in ["joining_lobby", "lobby_ready", "connecting"]:
		_state = "idle"
		_status = "Steam join cancelled."
		_last_error = ""
		_touch()


func _process(_delta: float) -> void:
	if _initialized and _steam != null:
		_steam.call("run_callbacks")
	if _notice_layer != null and _notice_layer.visible \
			and Time.get_ticks_msec() >= _notice_until_ms:
		_notice_layer.visible = false
	match _state:
		"host_waiting_for_world":
			_tick_host_world()
		"host_creating":
			if Time.get_ticks_msec() > _deadline_ms:
				# The native callback has no request token. Keep create_in_flight
				# true until it arrives so a retry cannot claim the wrong lobby.
				_state = "host_create_timed_out"
				_set_error(retry_pending_reason())
		"joining_lobby":
			if Time.get_ticks_msec() > _deadline_ms:
				var stale := _joining_lobby
				_cancelled_joins[stale] = "timed_out"
				_leave_lobby(stale)
				_joining_lobby = 0
				_state = "idle"
				_set_error(retry_pending_reason(stale))
		"lobby_ready":
			if _current_lobby > 0:
				var owner := int(_steam.call("getLobbyOwner", _current_lobby))
				if owner <= 0:
					_fail_join("That lobby’s host left.", true)
				elif _expected_host <= 0 or owner != _expected_host:
					_fail_join("That lobby’s original host left; host migration is not supported.", true)


func _tick_host_world() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	if tree.current_scene.is_in_group(&"title_screen") \
			or tree.current_scene.scene_file_path == TITLE_SCENE:
		return
	_settle_frames -= 1
	if _settle_frames > 0:
		return
	_create_in_flight = true
	_state = "host_creating"
	_deadline_ms = Time.get_ticks_msec() + JOIN_TIMEOUT_MS
	_status = "Opening a friends-only Steam lobby…"
	_steam.call("createLobby", FRIENDS_ONLY, LOBBY_CAPACITY)
	_touch()


func _on_lobby_created(result: int, lobby_id: int) -> void:
	_create_in_flight = false
	if _state != "host_creating":
		if result == CALLBACK_OK and lobby_id > 0:
			_leave_lobby(lobby_id)
		if _state == "host_create_timed_out":
			_state = "idle"
			_status = "Steam finished the previous lobby request. You can retry friends hosting."
			_last_error = ""
			_touch()
		return
	if result != CALLBACK_OK or lobby_id <= 0:
		_state = "idle"
		_set_error("Steam could not create the friends lobby.")
		return
	_current_lobby = lobby_id
	_expected_host = int(_steam.call("getSteamID"))
	if _expected_host <= 0:
		_fail_host("Steam could not identify the lobby host.")
		return
	if not _publish_metadata(lobby_id):
		_fail_host("Steam could not publish the lobby compatibility data.")
		return
	var peer := _make_peer()
	if peer == null:
		_fail_host("Steam networking is unavailable in this build.")
		return
	peer.set("server_relay", true)
	var err := int(peer.call("create_host", 0))
	if err != OK:
		peer.call("close")
		_fail_host("Steam could not open the relay host.")
		return
	var session := _session()
	if session == null or not bool(session.call("host_with_peer", peer, LOBBY_CAPACITY, "steam")):
		peer.call("close")
		_fail_host("The Steam relay could not start the game session.")
		return
	_hosting = true
	_state = "host_ready"
	# No player count here: this line is shown under the Players tab's live
	# count and was never refreshed as friends joined or left.
	_status = "Friends lobby ready."
	_last_error = ""
	# Ready is published only after Session owns a connected host peer.
	if not bool(_steam.call("setLobbyData", lobby_id, "ready", "1")):
		session.call("leave", "steam_lobby_metadata_failed")
		_hosting = false
		_state = "idle"
		_set_error("Steam could not publish that the friends lobby was ready.")
		return
	_published_joinable = null
	_refresh_joinable()
	lobby_ready.emit()
	_touch()


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# createLobby also emits lobby_joined. It belongs to the hosted lobby and
	# must not be mistaken for a stale client attempt.
	if _hosting and lobby_id == _current_lobby:
		return
	if _cancelled_joins.has(lobby_id):
		var cancelled_reason := str(_cancelled_joins.get(lobby_id, "cancelled"))
		_cancelled_joins.erase(lobby_id)
		if response == CALLBACK_OK:
			_leave_lobby(lobby_id)
		if cancelled_reason == "timed_out":
			_status = "Steam finished the previous join request. You can retry."
			_last_error = ""
		_touch()
		return
	if _state != "joining_lobby" or lobby_id != _joining_lobby:
		if response == CALLBACK_OK:
			_leave_lobby(lobby_id)
		return
	_joining_lobby = 0
	if response != CALLBACK_OK:
		_state = "idle"
		_set_error(_join_response_text(response))
		return
	_current_lobby = lobby_id
	var compatibility := _compatibility_error(lobby_id)
	if not compatibility.is_empty():
		_fail_join(compatibility, true)
		return
	_state = "lobby_ready"
	_status = "Friend lobby found. Choose a character to join."
	_last_error = ""
	lobby_ready.emit()
	_touch()


func _on_join_requested(lobby_id: int, friend_id: int) -> void:
	_set_pending_invite(lobby_id, friend_id)
	# The title screen answers an invitation itself. In a world nothing else
	# would say one arrived, so the invite would only surface after the player
	# happened to leave; say it here and keep it pending for the title.
	if _hosting or _session_is_live() or _in_world_scene():
		var who := pending_inviter_name(lobby_id)
		_show_world_notice("%s invited you to their world. Save and return to the title screen to join." \
			% (who if not who.is_empty() else "A Steam friend"))


func _on_lobby_kicked(lobby_id: int, _admin_id: int, _due_to_disconnect: int) -> void:
	if lobby_id != _current_lobby:
		return
	if _hosting:
		var session := _session()
		if session != null and bool(session.call("is_active")):
			session.call("leave", "steam_lobby_closed")
	else:
		_terminal_transport_error = "The Steam lobby closed."
		var session := _session()
		# A joined guest must take the same immediate failure route as a lost
		# server.  Calling Session.leave() alone would leave the guest standing
		# in the host snapshot with no transport; that becomes local host
		# authority on the next frame and can autosave the foreign world.  The
		# driver first saves only an acknowledged portable character, then
		# changes to title in that same call stack.
		var driver := get_parent().get_node_or_null(^"JoinDriver") if get_parent() != null else null
		if driver != null and driver.has_method("_fail"):
			driver.call("_fail", _terminal_transport_error)
		elif session != null and bool(session.call("is_active")):
			session.call("leave", "steam_lobby_closed")
			# This fallback has no JoinDriver to carry a retry message, but it
			# must still leave the guest world before host authority can resume.
			session.call("_return_to_title", "host_gone")
		else:
			var message := _terminal_transport_error
			_terminal_transport_error = ""
			_fail_join(message, false)


func _on_transport_closed() -> void:
	if _current_lobby != 0:
		_leave_lobby(_current_lobby)
	_current_lobby = 0
	_expected_host = 0
	_joining_lobby = 0
	_hosting = false
	_published_joinable = null
	_state = "idle"
	if _terminal_transport_error.is_empty():
		_status = "Steam friends are ready."
		_last_error = ""
	else:
		_status = _terminal_transport_error
		_last_error = _terminal_transport_error
		_terminal_transport_error = ""
	# A separately received invitation remains pending across teardown.
	_touch()


func _publish_metadata(lobby_id: int) -> bool:
	var product_ok := bool(_steam.call("setLobbyData", lobby_id, "product", PRODUCT))
	var protocol_ok := bool(_steam.call("setLobbyData", lobby_id, "protocol", PROTOCOL))
	var host_ok := bool(_steam.call("setLobbyData", lobby_id, "host_steam_id", str(_expected_host)))
	var build_ok := bool(_steam.call("setLobbyData", lobby_id, "build",
		BUILD_FINGERPRINT.token(BUILD_FINGERPRINT.current())))
	var ready_ok := bool(_steam.call("setLobbyData", lobby_id, "ready", "0"))
	# The host world's stable id, so a joiner (and a rejoin) can name which
	# world the invitation is for. Informational: admission still rests on
	# lobby membership and the full fingerprint in Session's hello.
	var world_ok := bool(_steam.call("setLobbyData", lobby_id, "world_id", _host_world_id()))
	return product_ok and protocol_ok and build_ok and host_ok and ready_ok and world_ok


func _host_world_id() -> String:
	var game := get_parent()
	var world: Variant = game.get("world") if game != null else null
	if world is Object and is_instance_valid(world):
		return str((world as Object).get("world_id"))
	return ""


## The world id a lobby's host published; empty when unknown.
func lobby_world_id(lobby_id: int = 0) -> String:
	var id := lobby_id if lobby_id > 0 else _current_lobby
	if _steam == null or id <= 0:
		return ""
	return str(_steam.call("getLobbyData", id, "world_id")).strip_edges()


func _compatibility_error(lobby_id: int) -> String:
	if int(_steam.call("getLobbyOwner", lobby_id)) <= 0:
		return "That lobby no longer has a host."
	if int(_steam.call("getNumLobbyMembers", lobby_id)) > LOBBY_CAPACITY:
		return "That Steam lobby is full."
	if str(_steam.call("getLobbyData", lobby_id, "product")) != PRODUCT:
		return "That invitation belongs to a different game."
	if str(_steam.call("getLobbyData", lobby_id, "protocol")) != PROTOCOL:
		return "That friend is using an incompatible Tetherbound protocol."
	var host_build := str(_steam.call("getLobbyData", lobby_id, "build"))
	var own_build := BUILD_FINGERPRINT.token(BUILD_FINGERPRINT.current())
	if host_build != own_build:
		return "Your friend is running a different version of Tetherbound (theirs %s, yours %s). Both players need the same version." \
			% [host_build if not host_build.is_empty() else "unknown", own_build]
	var host_text := str(_steam.call("getLobbyData", lobby_id, "host_steam_id")).strip_edges()
	if not host_text.is_valid_int() or int(host_text) <= 0:
		return "That lobby is missing its original host identity."
	_expected_host = int(host_text)
	if int(_steam.call("getLobbyOwner", lobby_id)) != _expected_host:
		return "That lobby’s original host left; host migration is not supported."
	if str(_steam.call("getLobbyData", lobby_id, "ready")) != "1":
		return "Your friend’s world is not ready yet."
	return ""


func _make_peer() -> MultiplayerPeer:
	if not _peer_factory.is_valid() and not ClassDB.class_exists("SteamMultiplayerPeer"):
		return null
	var candidate: Object = _peer_factory.call() if _peer_factory.is_valid() \
		else ClassDB.instantiate("SteamMultiplayerPeer")
	return candidate as MultiplayerPeer


func _connect_callbacks_once() -> void:
	if _callbacks_connected or _steam == null:
		return
	_connect_signal("lobby_created", _on_lobby_created)
	_connect_signal("lobby_joined", _on_lobby_joined)
	_connect_signal("join_requested", _on_join_requested)
	_connect_signal("lobby_kicked", _on_lobby_kicked)
	_callbacks_connected = true


func _connect_signal(signal_name: StringName, method: Callable) -> void:
	if _steam.has_signal(signal_name) and not _steam.is_connected(signal_name, method):
		_steam.connect(signal_name, method)


func _bind_session() -> void:
	var session := _session()
	if session != null and session.has_signal("transport_closed") \
			and not session.is_connected("transport_closed", _on_transport_closed):
		session.connect("transport_closed", _on_transport_closed)
	if session != null and session.has_signal("snapshot_applied") \
			and not session.is_connected("snapshot_applied", _on_snapshot_applied):
		session.connect("snapshot_applied", _on_snapshot_applied)
	if session != null and session.has_signal("peer_joined") \
			and not session.is_connected("peer_joined", _on_session_peers_changed):
		session.connect("peer_joined", _on_session_peers_changed)
	if session != null and session.has_signal("peer_left") \
			and not session.is_connected("peer_left", _on_session_peers_changed):
		session.connect("peer_left", _on_session_peers_changed)


func _session() -> Node:
	var game := get_parent()
	if game == null:
		return null
	var value: Variant = game.get("session")
	return value as Node


func _session_is_live() -> bool:
	var session := _session()
	return session != null and bool(session.call("is_active"))


func _on_snapshot_applied() -> void:
	if _state != "connecting":
		return
	_state = "joined"
	_status = "Joined your friend’s world."
	_last_error = ""
	_touch()


func _fail_host(message: String) -> void:
	if _current_lobby != 0:
		_leave_lobby(_current_lobby)
	_current_lobby = 0
	_expected_host = 0
	_hosting = false
	_state = "idle"
	_set_error(message)


func _fail_join(message: String, leave: bool) -> void:
	if leave and _current_lobby != 0:
		_leave_lobby(_current_lobby)
	_current_lobby = 0
	_expected_host = 0
	_joining_lobby = 0
	_state = "idle"
	_set_error(message)


## Closing the window must not leave this account sitting in a Steam lobby:
## friends would keep seeing a joinable host that no longer exists until
## Steam times the member out.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		leave_lobbies_for_quit()


func leave_lobbies_for_quit() -> void:
	if _joining_lobby != 0:
		_cancelled_joins[_joining_lobby] = "cancelled"
		_leave_lobby(_joining_lobby)
		_joining_lobby = 0
	if _current_lobby != 0:
		_leave_lobby(_current_lobby)
		_current_lobby = 0


func world_notice_text() -> String:
	if _notice_layer == null or not _notice_layer.visible or _notice_label == null:
		return ""
	return _notice_label.text


func _in_world_scene() -> bool:
	var tree := get_tree() if is_inside_tree() else null
	if tree == null or tree.current_scene == null:
		return false
	return not tree.current_scene.is_in_group(&"title_screen") \
		and tree.current_scene.scene_file_path != TITLE_SCENE


## A passive top-of-screen line. It takes no input, so it never enters
## input_owner and cannot steal a controller from whatever is open.
func _show_world_notice(text: String) -> void:
	if _notice_layer == null:
		_notice_layer = CanvasLayer.new()
		_notice_layer.name = "InviteNotice"
		_notice_layer.layer = INVITE_NOTICE_LAYER
		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.anchor_left = 0.5
		panel.anchor_right = 0.5
		panel.offset_left = -360.0
		panel.offset_right = 360.0
		panel.offset_top = 24.0
		_notice_label = Label.new()
		_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_notice_label.add_theme_font_size_override("font_size", 22)
		_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(_notice_label)
		_notice_layer.add_child(panel)
		add_child(_notice_layer)
	_notice_label.text = text
	_notice_layer.visible = true
	_notice_until_ms = Time.get_ticks_msec() + int(INVITE_NOTICE_S * 1000.0)


func _leave_lobby(lobby_id: int) -> void:
	if _steam != null and lobby_id > 0:
		_steam.call("leaveLobby", lobby_id)


func _set_pending_invite(lobby_id: int, inviter: int = 0) -> void:
	if lobby_id <= 0:
		return
	if lobby_id != _pending_invite:
		# A new invitation is not an earlier attempt's failure; the Join
		# Friend screen shows `last_error` in place of the invitation.
		_last_error = ""
	if lobby_id != _pending_invite or inviter > 0:
		_pending_inviter = maxi(inviter, 0)
	_pending_invite = lobby_id
	invite_received.emit(lobby_id)
	_touch()


func _set_error(message: String) -> void:
	_last_error = message
	_status = message
	_touch()


func _touch() -> void:
	_revision += 1
	changed.emit()


func _queue_launch_invite() -> void:
	var lobby_id := connect_lobby_from_args(OS.get_cmdline_args())
	if lobby_id == 0:
		lobby_id = connect_lobby_from_args(OS.get_cmdline_user_args())
	if lobby_id == 0 and _steam.has_method("getLaunchCommandLine"):
		lobby_id = connect_lobby_from_args(
			str(_steam.call("getLaunchCommandLine")).split(" ", false))
	if lobby_id > 0:
		_set_pending_invite(lobby_id)


static func configured_app_id() -> int:
	return app_id_from_sources(
		OS.get_environment("TETHERBOUND_STEAM_APP_ID"),
		OS.get_environment("SteamAppId"),
		ProjectSettings.get_setting(APP_ID_SETTING, 0))


static func app_id_from_sources(explicit: Variant, steam_environment: Variant,
		project_value: Variant) -> int:
	for source: Variant in [explicit, steam_environment, project_value]:
		var text := str(source).strip_edges()
		if text.is_valid_int() and int(text) > 0:
			return int(text)
	return 0


static func connect_lobby_from_args(args: Array) -> int:
	for index in args.size():
		var token := str(args[index]).strip_edges()
		if token == "+connect_lobby" and index + 1 < args.size():
			var value := str(args[index + 1]).strip_edges()
			return int(value) if value.is_valid_int() and int(value) > 0 else 0
		if token.begins_with("+connect_lobby="):
			var value := token.trim_prefix("+connect_lobby=").strip_edges()
			return int(value) if value.is_valid_int() and int(value) > 0 else 0
	return 0


static func _join_response_text(response: int) -> String:
	match response:
		2:
			return "That Steam lobby no longer exists."
		3:
			return "Steam did not allow this account into the lobby."
		4:
			return "That Steam lobby is full."
		6:
			return "Steam did not allow this account into the lobby."
		15:
			return "Steam is receiving join requests too quickly. Wait a moment and retry."
		_:
			return "Steam could not join that friends lobby."


func _inject_native_for_test(steam: Object, app_id: int = 123,
		peer_factory: Callable = Callable(), force_unavailable: bool = false) -> void:
	_steam = steam
	_test_app_id = app_id
	_peer_factory = peer_factory
	_test_force_unavailable = force_unavailable

extends "res://tests/test_case.gd"

const STEAM_LOBBY := preload("res://scripts/net/steam_lobby.gd")


class MockSteam:
	extends Node

	signal lobby_created(result: int, lobby_id: int)
	signal lobby_joined(lobby_id: int, permissions: int, locked: bool, response: int)
	signal join_requested(lobby_id: int, friend_id: int)
	signal lobby_kicked(lobby_id: int, admin_id: int, due_to_disconnect: int)

	var joined: Array[int] = []
	var left: Array[int] = []
	var callbacks := 0
	var lobby_owner := 500
	var members := 1
	var overlay_enabled := false
	var overlay_opened := 0
	var metadata: Dictionary = {
		"product": "tetherbound",
		"protocol": STEAM_LOBBY.PROTOCOL,
		"build": STEAM_LOBBY.BUILD_FINGERPRINT.token(STEAM_LOBBY.BUILD_FINGERPRINT.current()),
		"host_steam_id": "500",
		"ready": "1",
	}

	func steamInit(_app_id: int, _embedded: bool) -> bool:
		return true

	func loggedOn() -> bool:
		return true

	func initRelayNetworkAccess() -> void:
		pass

	func run_callbacks() -> void:
		callbacks += 1

	func joinLobby(lobby_id: int) -> void:
		joined.append(lobby_id)

	func leaveLobby(lobby_id: int) -> void:
		left.append(lobby_id)

	func getLobbyOwner(_lobby_id: int) -> int:
		return lobby_owner

	func getNumLobbyMembers(_lobby_id: int) -> int:
		return members

	func getLobbyData(_lobby_id: int, key: String) -> String:
		return str(metadata.get(key, ""))

	func isOverlayEnabled() -> bool:
		return overlay_enabled

	func activateGameOverlayInviteDialog(lobby_id: int) -> void:
		overlay_opened = lobby_id


func test_native_unavailable_is_optional_and_actionable() -> void:
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(null, 123, Callable(), true)
	assert_false(lobby.initialize())
	assert_eq(lobby.last_error(), "Steam friends are unavailable in this build.")
	assert_false(lobby.is_hosting())
	lobby.free()


func test_cancelled_join_leaves_late_successful_callback() -> void:
	var steam := MockSteam.new()
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	assert_true(lobby.request_join(111))
	assert_eq(steam.joined, [111])
	lobby.cancel_join()
	assert_eq(steam.left, [111])
	steam.lobby_joined.emit(111, 0, false, 1)
	assert_eq(steam.left, [111, 111], "late membership is not leaked")
	assert_eq(lobby.status_text(), "Steam join cancelled.")
	lobby.free()
	steam.free()


func test_timed_out_join_stays_pending_until_late_callback_then_allows_retry() -> void:
	var steam := MockSteam.new()
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	assert_true(lobby.request_join(111))
	lobby._deadline_ms = 0
	lobby._process(0.0)
	assert_false(lobby.retry_pending_reason(111).is_empty(),
		"a timeout cannot advertise retry while its untagged callback is unresolved")
	assert_false(lobby.request_join(111), "the unresolved attempt must retain its tombstone")
	steam.lobby_joined.emit(111, 0, false, 2)
	assert_eq(lobby.retry_pending_reason(111), "")
	assert_true(lobby.request_join(111), "the matching callback releases retry")
	assert_eq(steam.joined, [111, 111])
	lobby.free()
	steam.free()


func test_timed_out_host_request_stays_pending_until_callback_finishes() -> void:
	var steam := MockSteam.new()
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	lobby._create_in_flight = true
	lobby._state = "host_create_timed_out"
	assert_false(lobby.retry_pending_reason().is_empty())
	steam.lobby_created.emit(2, 0)
	assert_eq(lobby.retry_pending_reason(), "",
		"the completed native request must release the Players retry action")
	lobby.free()
	steam.free()


func test_mismatched_success_callback_is_left_without_stealing_attempt() -> void:
	var steam := MockSteam.new()
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	assert_true(lobby.request_join(111))
	steam.lobby_joined.emit(222, 0, false, 1)
	assert_eq(steam.left, [222])
	assert_false(lobby.request_join(333), "the matching callback is still pending")
	assert_eq(steam.joined, [111])
	lobby.free()
	steam.free()


func test_original_host_departure_refuses_lobby_before_dial() -> void:
	var steam := MockSteam.new()
	steam.lobby_owner = 501
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	assert_true(lobby.request_join(111))
	steam.lobby_joined.emit(111, 0, false, 1)
	assert_eq(lobby.last_error(),
		"That lobby’s original host left; host migration is not supported.")
	assert_eq(steam.left, [111])
	lobby.free()
	steam.free()


func test_protocol_mismatch_leaves_metadata_lobby() -> void:
	var steam := MockSteam.new()
	# v2 peers can send direct revive completions and have no host-clock RPCs.
	steam.metadata["protocol"] = "tetherbound-invite-v2"
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	assert_true(lobby.request_join(222))
	steam.lobby_joined.emit(222, 0, false, 1)
	assert_eq(lobby.last_error(), "That friend is using an incompatible Tetherbound protocol.")
	assert_eq(steam.left, [222])
	lobby.free()
	steam.free()


func test_build_mismatch_leaves_metadata_lobby_before_dial() -> void:
	var steam := MockSteam.new()
	steam.metadata["build"] = "%s|0.0.0.other|deadbeef" % STEAM_LOBBY.PROTOCOL
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	assert_true(lobby.request_join(444))
	steam.lobby_joined.emit(444, 0, false, 1)
	assert_true(lobby.last_error().begins_with(
		"Your friend is running a different version of Tetherbound (theirs %s|0.0.0.other|deadbeef, yours "
			% STEAM_LOBBY.PROTOCOL), lobby.last_error())
	assert_eq(steam.left, [444], "a mismatched build is refused before any peer connection")
	lobby.free()
	steam.free()


func test_missing_build_metadata_is_refused_as_unknown_version() -> void:
	var steam := MockSteam.new()
	steam.metadata.erase("build")
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	assert_true(lobby.request_join(445))
	steam.lobby_joined.emit(445, 0, false, 1)
	assert_true(lobby.last_error().contains("(theirs unknown, yours "), lobby.last_error())
	assert_eq(steam.left, [445])
	lobby.free()
	steam.free()


func test_invite_overlay_unavailable_is_actionable() -> void:
	var steam := MockSteam.new()
	var lobby := STEAM_LOBBY.new()
	lobby._inject_native_for_test(steam)
	assert_true(lobby.initialize())
	lobby._hosting = true
	lobby._state = "host_ready"
	lobby._current_lobby = 333
	assert_false(lobby.invite_friends())
	assert_eq(lobby.last_error(),
		"The Steam invite overlay is unavailable. Check that the Steam overlay is enabled.")
	assert_eq(steam.overlay_opened, 0)
	lobby.free()
	steam.free()


func test_app_id_has_no_spacewars_default() -> void:
	assert_eq(STEAM_LOBBY.app_id_from_sources("", "", 0), 0)
	assert_eq(STEAM_LOBBY.app_id_from_sources("730", "480", 99), 730)
	assert_eq(STEAM_LOBBY.app_id_from_sources("bad", "22", 99), 22)


func test_native_identity_must_be_a_member_of_the_claimed_lobby() -> void:
	var hello := {"steam_protocol": STEAM_LOBBY.PROTOCOL, "steam_lobby_id": 101}
	var members: Array[int] = [500, 501]
	assert_eq(STEAM_LOBBY.member_admission_error(501, members, 101, hello), "")
	assert_false(STEAM_LOBBY.member_admission_error(999, members, 101, hello).is_empty(),
		"a known host Steam ID alone does not admit a socket outside the lobby")
	hello["steam_lobby_id"] = 202
	assert_false(STEAM_LOBBY.member_admission_error(501, members, 101, hello).is_empty())
	hello["steam_lobby_id"] = 101
	hello["steam_protocol"] = "tetherbound-invite-v2"
	assert_false(STEAM_LOBBY.member_admission_error(501, members, 101, hello).is_empty())


func test_connect_lobby_launch_argument_parsing() -> void:
	assert_eq(STEAM_LOBBY.connect_lobby_from_args(["+connect_lobby", "7654"]), 7654)
	assert_eq(STEAM_LOBBY.connect_lobby_from_args(["+connect_lobby=8765"]), 8765)
	assert_eq(STEAM_LOBBY.connect_lobby_from_args(["+connect_lobby", "nope"]), 0)

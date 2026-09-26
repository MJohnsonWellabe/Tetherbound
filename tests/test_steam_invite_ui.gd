extends "res://tests/test_case.gd"

const GAME_STATE := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TITLE := preload("res://scripts/ui/title_screen.gd")
const PLAYERS_TAB := preload("res://scripts/ui/tab_players.gd")
const CHARACTER_IDENTITY := preload("res://scripts/save/character_identity.gd")

const TEST_DIR := "user://test_steam_invite_ui/"

var game: Node
var saver: RefCounted


class LobbyErrorStub extends RefCounted:
	var message := ""

	func last_error() -> String:
		return message


func before_each() -> void:
	_wipe_test_dir()
	game = GAME_STATE.new()
	saver = SAVE_GAME.new(TEST_DIR)
	game.save_system = saver
	game.reset_for_new_game()


func after_each() -> void:
	if game != null:
		game.free()
		game = null
	_wipe_test_dir()


func test_cold_steam_invite_parser_accepts_both_launch_forms() -> void:
	assert_eq(TITLE.parse_connect_lobby(PackedStringArray([
		"+connect_lobby", "76561198012345678",
	])), 76561198012345678)
	assert_eq(TITLE.parse_connect_lobby(PackedStringArray([
		"+connect_lobby=76561198087654321",
	])), 76561198087654321)
	assert_eq(TITLE.parse_connect_lobby(PackedStringArray(["+connect_lobby", "not-an-id"])), 0)
	assert_eq(TITLE.parse_connect_lobby(PackedStringArray(["--mp-host", "27015"])), 0,
		"Steam parsing must not reinterpret the established ENet automation flags")


func test_selected_portable_character_replaces_run_state_without_loading_its_world() -> void:
	game.local.character_id = "portable-rin"
	game.local.display_name = "Rin"
	game.local.chosen_character = "kael"
	game.party.add(game.make_creature("terrapup", "Compass"))
	game.inventory.add("berries", 3)
	assert_true(saver.save_character(game, "portable-rin"), "fixture portable character must save")

	# This is local WORLD state from a different run. A friend join must reset
	# it and apply only Rin's portable half rather than loading an autosave.
	game.day = 19
	game.placed_buildings = [{"id": "wall", "position": [1.0, 0.0, 1.0]}]
	game.party.clear()
	game.local.character_id = "wrong-live-character"
	assert_true(TITLE.prepare_steam_character(game, {
		"kind": "existing",
		"character_id": "portable-rin",
	}))
	assert_eq(game.day, 1)
	assert_true(game.placed_buildings.is_empty(), "a guest must not bring their local world")
	assert_eq(game.party.size(), 1)
	assert_eq(str(game.party.at(0).get("nickname")), "Compass")
	assert_eq(str(game.local.character_id), "portable-rin")
	assert_eq(str(game.local.display_name), "Rin")

	var summary := TITLE.steam_character_summary(game)
	assert_eq(str(summary.get("character_id")), "portable-rin")
	assert_eq(str(summary.get("display_name")), "Rin")
	assert_eq(str(summary.get("appearance_id")), "kael")


func test_deliberate_new_friend_character_clears_stale_identity_and_world() -> void:
	game.day = 8
	game.local.character_id = "old-id"
	game.placed_buildings = [{"id": "tent"}]
	assert_true(TITLE.prepare_steam_character(game, {
		"kind": "new",
		"appearance_id": "mira",
		"display_name": "  New   Ranger  ",
	}))
	assert_eq(game.day, 1)
	assert_true(game.placed_buildings.is_empty())
	assert_true(CHARACTER_IDENTITY.is_valid(str(game.local.character_id)))
	assert_true(str(game.local.character_id).begins_with(CHARACTER_IDENTITY.PREFIX))
	assert_ne(str(game.local.character_id), "old-id")
	assert_eq(str(game.local.chosen_character), "mira")
	assert_eq(str(game.local.display_name), "New Ranger")


## F01#6: a guest process that restarted holds a freshly minted live id, so a
## direct-address join must still find the character it saved.
func test_a_restarted_guest_still_sees_its_saved_portable_characters() -> void:
	assert_true(TITLE._saved_portable_character_ids(game).is_empty(), "a new machine has none")
	game.local.character_id = "portable-rin"
	game.local.display_name = "Rin"
	assert_true(saver.save_character(game, "portable-rin"), "fixture portable character must save")
	game.reset_for_new_game()
	game.local.character_id = CHARACTER_IDENTITY.mint()
	assert_ne(str(game.local.character_id), "portable-rin", "boot minted a new live id")
	assert_eq(TITLE._saved_portable_character_ids(game), ["portable-rin"],
		"the saved character is offered even though the live id names no file")


## Owner ruling "rejoin returns to exact spot": a Steam invite restores the
## portable character, pose included; that pose must not place the guest in
## whatever world the friend hosts. The join clears it (and a loaded slot's
## queued fly state) so only `rejoin_pose.gd`'s host-instance check can seat it.
func test_a_steam_join_does_not_place_a_saved_pose_before_the_host_is_known() -> void:
	game.local.character_id = "portable-rin"
	game.local.display_name = "Rin"
	game.local.pose = {"realm": "meadows", "position": [40.0, 3.0, -60.0], "model_yaw": 0.0,
		"camera_yaw": 0.0, "camera_pitch": 0.0}
	assert_true(saver.characters().write("portable-rin", game.local.save_data(),
		{"last_world_instance_id": "instance-host-a"}), "fixture portable character must save")
	game.reset_for_new_game()
	assert_true(TITLE.prepare_steam_character(game, {"kind": "existing", "character_id": "portable-rin"}))
	assert_false((game.get("saved_player_pose") as Dictionary).is_empty(),
		"the portable restore brings the saved pose back (the gap this closes)")
	var candidate: Dictionary = TITLE.rejoin_pose_candidate(game)
	assert_eq(str(candidate.get("world_instance_id")), "instance-host-a")
	game.set_meta("pending_fly_load", {"safe_anchor": [1.0, 2.0, 3.0]})
	TITLE.clear_pose_for_join(game)
	assert_true((game.get("saved_player_pose") as Dictionary).is_empty(),
		"no world can place the pose before the host snapshot decides")
	assert_false(game.has_meta("pending_fly_load"), "nor a queued fly state")


func test_players_invite_button_preserves_specific_coordinator_error() -> void:
	var lobby := LobbyErrorStub.new()
	lobby.message = "Steam is offline. Sign in before using friend invitations."
	assert_eq(PLAYERS_TAB._steam_error(lobby, "generic"), lobby.message)
	lobby.message = ""
	assert_eq(PLAYERS_TAB._steam_error(lobby, "generic"), "generic")


func test_native_lobby_failure_invalidates_a_ready_join_before_character_selection() -> void:
	assert_true(TITLE.pending_steam_join_has_failure(123, "That lobby’s host left."),
		"a ready callback cannot keep a pending join alive after native failure")
	assert_false(TITLE.pending_steam_join_has_failure(123, ""))
	assert_false(TITLE.pending_steam_join_has_failure(0, "That lobby’s host left."))


func test_unresolved_native_request_cannot_advertise_actionable_retry() -> void:
	assert_false(TITLE.steam_retry_is_actionable(
		"Steam is still finishing the join request."))
	assert_true(TITLE.steam_retry_is_actionable(""))


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	_remove_contents(dir)


func _remove_contents(dir: DirAccess) -> void:
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			var child := DirAccess.open(dir.get_current_dir().path_join(entry))
			if child != null:
				_remove_contents(child)
			dir.remove(entry)
		else:
			dir.remove(entry)
		entry = dir.get_next()
	dir.list_dir_end()

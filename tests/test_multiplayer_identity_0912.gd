extends "res://tests/test_case.gd"

## Owner 2026-09-12 Tier 4 multiplayer UX contract. The expensive two-peer
## acceptance remains in the net smokes; these checks keep the identity and
## presentation seams cheap enough to run with the ordinary source/unit suite.

const GAME := preload("res://autoload/game_state.gd")
const TITLE := preload("res://scripts/ui/title_screen.gd")
const TAB_MAP := preload("res://scripts/ui/tab_map.gd")
const REMOTE_TRAINER := preload("res://scenes/player/remote_trainer.tscn")
const VILLAGE_BOUNDARY := preload("res://scripts/world/village_boundary.gd")


class RemoteTrainerDouble extends Node3D:
	var net_realm := "meadows"
	var peer_id := 22
	var display_name := "Juniper"


func test_fresh_identity_keeps_the_players_body_and_name_but_not_an_old_save_id() -> void:
	var game := GAME.new()
	game.local.character_id = "previous-run"
	game.local.display_name = "Previous"
	game.local.chosen_character = "trainer"
	game.local.realm = "cloudreach"
	game.local.pose = {"position": [800.0, 30.0, 900.0]}

	TITLE._set_fresh_player_identity(game, "kael", "  Juniper   Vale  ")
	game.reset_for_new_game()

	assert_eq(str(game.local.character_id), "",
		"a new trainer must mint a new portable identity instead of overwriting the prior one")
	assert_eq(str(game.local.display_name), "Juniper Vale")
	assert_eq(str(game.local.chosen_character), "kael")
	assert_eq(str(game.local.realm), "meadows",
		"a fresh join builds the Meadows shell, where Grandpa's Village is authored")
	assert_true((game.local.pose as Dictionary).is_empty(),
		"a stale returning pose must not move a fresh joiner away from the village spawn")
	game.free()


func test_fresh_name_is_bounded_for_the_remote_badge() -> void:
	var game := GAME.new()
	TITLE._set_fresh_player_identity(game, "sera", "12345678901234567890")
	assert_eq(str(game.local.display_name), "12345678901234")
	TITLE._set_fresh_player_identity(game, "sera", "     ")
	assert_eq(str(game.local.display_name), "Trainer")
	game.free()


func test_remote_badge_uses_the_chosen_name_at_compact_fixed_screen_size() -> void:
	var trainer := REMOTE_TRAINER.instantiate()
	trainer.set("peer_id", 22)
	trainer.set("display_name", "Juniper")
	trainer.call("_apply_nameplate")
	var plate := trainer.get_node(^"Nameplate") as Label3D
	assert_eq(plate.text, "Juniper")
	assert_true(plate.fixed_size, "remote names should remain readable at co-op distance")
	assert_true(plate.font_size <= 30, "the old 48px nameplate dominated the player body")
	assert_true(plate.outline_size <= 6, "the old 14px outline made the badge visually enormous")
	trainer.free()


func test_same_realm_remote_player_has_a_named_full_map_record() -> void:
	var remote := RemoteTrainerDouble.new()
	remote.position = Vector3(12.0, 1.0, 24.0)
	var record: Dictionary = TAB_MAP.remote_player_marker_record(remote, "meadows")
	assert_eq(str(record.get("display_name", "")), "Juniper")
	assert_eq(record.get("position"), remote.position)
	assert_true(TAB_MAP.remote_player_marker_record(remote, "cloudreach").is_empty())
	remote.free()


func test_authored_fresh_spawn_is_inside_grandpas_village() -> void:
	var scene_source := FileAccess.get_file_as_string("res://scenes/world/meadows_playground.tscn")
	assert_true(scene_source.contains("1, 0, 40, 0"),
		"the fresh Player scene transform must retain its authored x/z origin")
	var config: Dictionary = VILLAGE_BOUNDARY.load_config()
	assert_true(VILLAGE_BOUNDARY.contains(VILLAGE_BOUNDARY.outline(config), Vector2.ZERO),
		"the authored fresh spawn must remain inside Grandpa's Village boundary")


func test_late_joiner_companion_path_is_still_active() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/story/sequence_director.gd")
	assert_true(source.contains("_hand_a_late_arrival_a_companion()"))
	assert_true(source.contains("await _encounter.call(\"adopt_starter\", _sandbox_starter)"))
	assert_true(source.contains("int(party.call(\"size\")) > 0"),
		"an existing party must not receive a duplicate late-join starter")


func test_strict_two_peer_proof_uses_production_entry_and_live_state() -> void:
	var runner := FileAccess.get_file_as_string("res://tools/net/peer_runner.gd")
	var smoke := FileAccess.get_file_as_string(
		"res://tests/smoke_net_meadows_identity_fresh_join.gd")
	assert_true(runner.contains("title.call(\"_finish_new_game_with_identity\""),
		"the host proof must finish the production title identity path")
	assert_true(runner.contains("TITLE_SCREEN._set_fresh_player_identity"),
		"the unattended fresh join must use the title's identity owner")
	assert_true(runner.contains("\"player_identity\":"))
	assert_true(runner.contains("\"model_appearance_id\""),
		"the proof must read built rig art, not only requested or registry data")
	assert_true(runner.contains("\"inside_grandpas_village\""),
		"the proof must classify the live Player transform against the authored boundary")
	assert_true(smoke.contains("\"production_host\"")
		and smoke.contains("\"production_join\""))
	assert_true(smoke.contains("SECOND_WORLD_DELTA"),
		"the one-starter proof must exercise catch-up re-arming, not only wait once")
	assert_false(smoke.contains("\"party_grant\""),
		"the multiplayer proof may observe the production starter but never fabricate one")

extends "res://tests/test_case.gd"

const ORDER := preload("res://scripts/data/biome_order.gd")
const HEARTS := preload("res://autoload/realm_heart_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const MERGED := preload("res://autoload/merged_progression.gd")

class AdmissionGame extends "res://autoload/game_state.gd":
	func _ready() -> void:
		pass

class PortalSession extends Node:
	var enabled: Variant = false
	func portal_runtime_ready() -> Variant:
		return enabled

class MalformedSessionOwner extends RefCounted:
	var session: Variant

var game: Node
var session: PortalSession

func before_each() -> void:
	ORDER.clear_test_overrides()
	game = AdmissionGame.new()
	game.world = WORLD.new()
	game.local = PLAYER.new()
	game.set("_merged_progression", MERGED.new(game.world.flags, game.local.flags))
	game.realm_hearts = HEARTS.new({"realms": {
		"meadows": {"scene": "res://meadows.tscn", "entry_key_flag": ""},
		"water": {"scene": "res://water.tscn", "entry_key_flag": "realm_key_water"},
		"cloudreach": {"scene": "res://cloudreach.tscn", "entry_key_flag": "realm_key_cloudreach"},
		"biome5": {"scene": "res://reserved.tscn", "entry_key_flag": ""}}})
	session = PortalSession.new()
	game.session = session

func after_each() -> void:
	ORDER.clear_test_overrides()
	session.free()
	game.free()

func test_off_uses_real_legacy_key_even_when_retirement_flag_is_false() -> void:
	assert_false(ORDER.portal_runtime_ready(game))
	assert_true(ORDER.legacy_physical_crossings(game))
	assert_true(game.can_enter_realm("meadows"))
	game.local.redesign_character.portal_unlocks.append("cloudreach")
	assert_false(game.can_enter_realm("cloudreach"), "inactive candidate unlock cannot replace the legacy key")
	game.progression.set_flag("realm_key_cloudreach")
	assert_true(game.can_enter_realm("cloudreach"))

func test_on_uses_host_or_personal_unlock_and_ignores_legacy_key() -> void:
	session.enabled = true
	assert_false(ORDER.legacy_physical_crossings(game))
	game.progression.set_flag("realm_key_cloudreach")
	assert_false(game.can_enter_realm("cloudreach"))
	game.world.redesign_world.portal_unlocks.append("cloudreach")
	assert_true(game.can_enter_realm("cloudreach"))
	game.world.redesign_world.portal_unlocks.clear()
	game.local.redesign_character.portal_unlocks.append("cloudreach")
	assert_true(game.can_enter_realm("cloudreach"))

func test_on_canonicalizes_water_and_never_admits_reserved_biomes() -> void:
	session.enabled = true
	game.local.redesign_character.portal_unlocks.append("tidewake")
	assert_true(game.can_enter_realm("water"))
	game.local.redesign_character.portal_unlocks.append("biome5")
	assert_false(game.can_enter_realm("biome5"))
	assert_false(game.can_enter_realm("unknown"))

func test_malformed_runtime_readiness_preserves_off_policy() -> void:
	for malformed: Variant in [1, "true", null]:
		session.enabled = malformed
		assert_false(ORDER.portal_runtime_ready(game))
		assert_true(ORDER.legacy_physical_crossings(game))

func test_non_object_session_preserves_off_policy_without_dynamic_call() -> void:
	var owner := MalformedSessionOwner.new()
	for malformed: Variant in [1, "true", {}, []]:
		owner.session = malformed
		assert_false(ORDER.portal_runtime_ready(owner))
		assert_true(ORDER.legacy_physical_crossings(owner))

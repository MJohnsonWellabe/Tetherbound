extends "res://tests/test_case.gd"

## Pure state-contract coverage for the world-facing Realm Heart shrine and
## realm gate.  Rendering/input still belongs to scene smoke evidence; these
## tests pin the durable transitions without requiring a running world.

const PROGRESSION := preload("res://autoload/progression_state.gd")
const REALM_HEARTS := preload("res://autoload/realm_heart_state.gd")
const SHRINE := preload("res://scripts/world/realm_heart_shrine.gd")
const GATE := preload("res://scripts/world/realm_gate.gd")


class FakeGame extends Node:
	var progression: RefCounted = null
	var realm_hearts: RefCounted = null
	var entered_realm := ""
	var entered_at := ""

	func enter_realm(destination: String, entry_id: String = "") -> void:
		entered_realm = destination
		entered_at = entry_id


var game: FakeGame = null
var shrine: Node3D = null
var gate: Node3D = null


func before_each() -> void:
	game = FakeGame.new()
	game.progression = PROGRESSION.new()
	game.realm_hearts = REALM_HEARTS.new({
		"hearts": {
			"meadows": {
				"earned_flag": "realm_heart_meadows_earned",
				"placed_flag": "realm_heart_meadows_placed",
				"power": {"max_stamina_multiplier": 2.0},
			},
		},
	})
	shrine = SHRINE.new()
	gate = GATE.new()


func after_each() -> void:
	shrine.free()
	gate.free()
	game.free()


func test_shrine_exposes_all_four_durable_states() -> void:
	assert_eq(shrine.call("state_for", game), SHRINE.STATE_UNEARNED)
	game.progression.call("set_flag", "realm_heart_meadows_earned")
	assert_eq(shrine.call("state_for", game), SHRINE.STATE_EARNED_UNPLACED)
	assert_true(game.realm_hearts.call("place", "meadows", game.progression))
	assert_eq(shrine.call("state_for", game), SHRINE.STATE_PLACED_INACTIVE)
	assert_true(game.realm_hearts.call("activate", "meadows", game.progression))
	assert_eq(shrine.call("state_for", game), SHRINE.STATE_ACTIVE)


func test_gate_never_unlocks_without_the_durable_key_flag() -> void:
	assert_eq(gate.call("state_for", game), GATE.STATE_LOCKED)
	assert_false(gate.call("try_unlock", game))
	assert_false(game.progression.call("has", "realm_gate_cloudreach_unlocked"))


func test_gate_unlock_retains_key_and_persists_its_own_flag() -> void:
	game.progression.call("set_flag", "realm_key_cloudreach")
	assert_eq(gate.call("state_for", game), GATE.STATE_UNLOCKABLE)
	assert_true(gate.call("try_unlock", game))
	assert_true(game.progression.call("has", "realm_key_cloudreach"), "the realm key is an entitlement, not a consumable")
	assert_true(game.progression.call("has", "realm_gate_cloudreach_unlocked"))
	assert_eq(gate.call("state_for", game), GATE.STATE_UNLOCKED)


func test_gate_passes_realm_and_authored_entry_to_game_router() -> void:
	gate.call("setup", "cloudreach", "meadows_arrival", "Cloudreach Cliffs", "realm_key_cloudreach", "cloudreach_gate_open")
	game.progression.call("set_flag", "cloudreach_gate_open")
	assert_true(gate.call("try_enter", game))
	assert_eq(game.entered_realm, "cloudreach")
	assert_eq(game.entered_at, "meadows_arrival")


func test_components_build_their_world_contract_without_external_assets() -> void:
	# The tiny test runner executes from SceneTree._init(), before a root is
	# available.  Call the same primitive builders directly to execute every
	# mesh/material/collision property without pretending this is a scene smoke.
	shrine.call("_build_visual")
	shrine.call("_build_prompt")
	gate.call("_build_visual")
	gate.call("_build_prompt")
	assert_true(shrine.get_node_or_null(^"RealmHeart") != null)
	assert_true(shrine.get_node_or_null(^"Interactable") != null)
	assert_true(gate.get_node_or_null(^"LockedBarrier") != null)
	assert_true(gate.get_node_or_null(^"Interactable") != null)

extends "res://tests/test_case.gd"

## Real ceremony ownership and roster transitions with a scoped service double.
## No rendering, transport or durable typed settlement is claimed here.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")

class GameFixture extends Node:
	var party := PARTY.new()
	var pending_catch: RefCounted

class ScopedService extends Node:
	signal release_completed(release_id: String, result: Dictionary)
	var active := "alpha_offer"
	func owns_pending_capture(creature: RefCounted) -> bool:
		return creature != null and not active.is_empty() and creature.get_meta("foundation_capture_offer", "") == active
	func quote_release(_pending_uid: String, _released_uid: String) -> Dictionary: return {}
	func submit_release(_request: Dictionary) -> void: pass
	func reconcile_release(_release_id: String) -> void: pass

class TabFixture extends "res://scripts/ui/tab_creatures.gd":
	var fixture: Node
	var released_card: RefCounted
	func state() -> Node: return fixture
	func say(_message: String) -> void: pass
	func _water_capture_service(_creature: RefCounted) -> Node: return null
	func _show_release_done(released: RefCounted, _newcomer_name: String, _payout_text: String = "") -> void:
		released_card = released
		_release_stage = "done"

func test_completed_alpha_service_does_not_block_the_next_free_slot_catch() -> void:
	var game := GameFixture.new()
	var tab := TabFixture.new()
	tab.fixture = game
	var service := ScopedService.new()
	assert_true(tab.configure_release_service(service))
	var alpha := SPECIES.spawn("bramblebun")
	alpha.set_meta("foundation_capture_offer", "alpha_offer")
	assert_true(tab._typed_release_required(alpha))
	service.active = "" # Previous typed decision finished; service stays mounted.
	var ordinary := SPECIES.spawn("bramblebun")
	game.pending_catch = ordinary
	assert_false(tab._typed_release_required(ordinary))
	tab._maybe_begin_release()
	assert_eq(game.party.size(), 1)
	assert_true(game.party.at(0) == ordinary)
	assert_true(game.pending_catch == null)
	tab.free()
	service.free()
	game.free()

func test_completed_alpha_service_does_not_steal_the_next_full_roster_ceremony() -> void:
	var game := GameFixture.new()
	for index: int in 5: game.party.add(SPECIES.spawn("bramblebun"))
	var tab := TabFixture.new()
	tab.fixture = game
	var service := ScopedService.new()
	assert_true(tab.configure_release_service(service))
	service.active = ""
	var original := game.party.at(2)
	var ordinary := SPECIES.spawn("bramblebun")
	game.pending_catch = ordinary
	tab._release_stage = "confirm"
	tab._release_target = 2
	tab._release_for = ordinary
	tab._do_release()
	assert_eq(game.party.size(), 5)
	assert_true(game.party.members().has(ordinary))
	assert_false(game.party.members().has(original))
	assert_true(tab.released_card == original)
	assert_true(game.pending_catch == null)
	tab.free()
	service.free()
	game.free()

func test_submitted_typed_decision_cannot_fall_back_when_its_offer_disappears() -> void:
	var tab := TabFixture.new()
	var service := ScopedService.new()
	assert_true(tab.configure_release_service(service))
	service.active = ""
	tab._release_request_id = "original_pending_decision"
	assert_true(tab._typed_release_required(SPECIES.spawn("bramblebun")))
	tab.free()
	service.free()

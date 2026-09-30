extends "res://tests/test_case.gd"

const MERGED := preload("res://autoload/merged_progression.gd")
const FLAGS := preload("res://autoload/progression_state.gd")

class Traveler extends RefCounted:
	var character_id := "owner_a"
	var redesign_character := {"relics_held": [], "relics_hung": [], "transaction_receipts": [], "portal_unlocks": []}

class HostWorld extends RefCounted:
	var redesign_world := {"portal_unlocks": [], "fifth_arch_stirred": false}


func test_detached_views_follow_canonical_rebind_and_weak_lifetime() -> void:
	var reader := MERGED.new()
	var first := Traveler.new()
	first.redesign_character.relics_held = ["tidewake"]
	reader.bind_traveler(first)
	var exported: Array[String] = reader.traveler_relics_held()
	exported.append("stormwood")
	assert_eq(first.redesign_character.relics_held, ["tidewake"], "readers cannot mutate the canonical carrier")
	var replacement := Traveler.new()
	replacement.character_id = "owner_b"
	replacement.redesign_character.relics_hung = ["cloudreach"]
	reader.bind_traveler(replacement)
	assert_eq(reader.traveler_character_id(), "owner_b")
	assert_true(reader.traveler_relics_held().is_empty(), "replacement local has its own entitlement")
	assert_eq(reader.traveler_relics_hung(), ["cloudreach"])
	replacement = null
	assert_eq(reader.traveler_character_id(), "", "reader does not keep replaced owner alive")
	assert_true(reader.traveler_relics_hung().is_empty())


func test_ahead_world_flags_do_not_supply_personal_ending_entitlements() -> void:
	var world_flags := FLAGS.new()
	world_flags.set_flag("water_currents_restored")
	var traveler := Traveler.new()
	var reader := MERGED.new(world_flags, FLAGS.new())
	reader.bind_traveler(traveler)
	assert_true(reader.has("water_currents_restored"), "legacy world UI remains readable")
	assert_true(reader.traveler_relics_held().is_empty(), "ahead host cannot grant this traveler Stormwood ownership")
	assert_true(reader.traveler_transaction_receipts().is_empty(), "ahead host cannot invent a personal Home arrival")
	traveler.redesign_character.transaction_receipts = ["home_return_after_stormwood:world_a:owner_a:ticket_a"]
	var foreign := Traveler.new()
	foreign.character_id = "owner_b"
	reader.bind_traveler(foreign)
	assert_eq(reader.traveler_character_id(), "owner_b")
	assert_true(reader.traveler_transaction_receipts().is_empty(), "switching owner cannot inherit the first owner's receipt")


func test_finite_portal_host_or_personal_unlock_home_and_sealed_fifth() -> void:
	var traveler := Traveler.new()
	var world := HostWorld.new()
	var reader := MERGED.new()
	reader.bind_traveler(traveler, world)
	assert_true(reader.portal_is_unlocked("meadows"), "Home availability does not require an unlock array")
	assert_false(reader.portal_is_unlocked("tidewake"))
	world.redesign_world.portal_unlocks = ["tidewake"]
	assert_true(reader.portal_is_unlocked("tidewake"), "host world unlock is visible")
	traveler.redesign_character.portal_unlocks = ["cloudreach"]
	assert_true(reader.portal_is_unlocked("cloudreach"), "portable traveler unlock is visible")
	assert_false(reader.portal_is_unlocked("stormwood"), "locked live destination remains locked")
	world.redesign_world.fifth_arch_stirred = true
	world.redesign_world.portal_unlocks.append("biome5")
	traveler.redesign_character.portal_unlocks.append("biome5")
	assert_false(reader.portal_is_unlocked("biome5"), "even corrupt forbidden unlocks cannot make the stirred arch travelable")
	assert_false(reader.portal_is_unlocked("water"), "runtime aliases must pass the central canonical boundary")
	assert_false(reader.portal_is_unlocked("typo_biome"))
	reader.bind_traveler(Traveler.new(), HostWorld.new())
	assert_false(reader.portal_is_unlocked("tidewake"), "new canonical host cannot retain previous host eligibility")

extends "res://tests/test_case.gd"
const RUNS_IN_INITIALIZED_TREE := true

## Maela's Galecrest loaner ends at chapter completion (#356 Question A,
## coordinator ruling: spec conformance with CREATURES/SYSTEMS "temporary",
## "not permanent free traversal inventory"). Config:
## `fly_traversal.json` `mentor_loaner.ends_at_flag`.

const FLY := preload("res://scripts/player/fly_controller.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")

class FlyGame extends Node:
	var party: RefCounted = PARTY.new()
	var progression: RefCounted = PROGRESSION.new()
	var current_realm := "cloudreach"
	var realm_hearts: RefCounted = null

var fly: Node
var game: Node
var player: CharacterBody3D

class TransportPlayer extends CharacterBody3D:
	var available := true
	func is_carried() -> bool: return false
	func locomotion_enabled() -> bool: return available


func before_each() -> void:
	player = null
	fly = FLY.new()
	game = FlyGame.new()
	fly._game = game
	fly.config = JSON.parse_string(FileAccess.get_file_as_string(FLY.CONFIG_PATH))


func after_each() -> void:
	if player != null: player.free()
	fly.free()
	game.free()


func test_the_end_flag_is_config() -> void:
	assert_eq(str(fly.config.get("mentor_loaner", {}).get("ends_at_flag", "")), "cloudreach_chapter_complete")


func test_rule_table() -> void:
	var loaner := {"available_during_trial": true, "available_after_unlock": true}
	assert_true(FLY.mentor_loaner_available(loaner, true, false, false), "trial")
	assert_true(FLY.mentor_loaner_available(loaner, false, true, false), "after unlock, during the chapter")
	assert_false(FLY.mentor_loaner_available(loaner, false, false, false), "neither")
	assert_false(FLY.mentor_loaner_available(loaner, false, true, true), "chapter complete ends it")
	assert_false(FLY.mentor_loaner_available(loaner, true, true, true), "ended even with a trial box set")


func test_a_non_fly_team_loses_the_loaner_at_chapter_completion() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		game.party.add(SPECIES.spawn(species))
	game.progression.set_flag("fly_traversal_unlocked")
	var carrier: RefCounted = fly.eligible_creature()
	assert_ne(carrier, null, "the loaner serves the chapter's routes after the unlock")
	game.progression.set_flag("cloudreach_chapter_complete")
	assert_eq(fly.eligible_creature(), null, "no loaner once the chapter is complete")
	assert_eq(game.party.size(), 5, "and nothing was ever added to the party")


func test_an_owned_carrier_still_flies_after_the_chapter() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "galecrest"]:
		game.party.add(SPECIES.spawn(species))
	game.party.set_active(4)
	game.progression.set_flag("fly_traversal_unlocked")
	game.progression.set_flag("cloudreach_chapter_complete")
	var carrier: RefCounted = fly.eligible_creature()
	assert_ne(carrier, null, "the ending applies to the loaner only")
	if carrier != null:
		assert_true((game.party.members() as Array).has(carrier), "the owned Galecrest carries")


func _at_master_approach() -> void:
	player = TransportPlayer.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(player)
	fly._player = player
	player.global_position = Vector3(400, 610, 3250)
	game.progression.set_flag("fly_traversal_unlocked")
	game.progression.set_flag("cloudreach_chapter_complete")
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		game.party.add(SPECIES.spawn(species))


func test_ground_team_retains_only_master_transport_after_chapter() -> void:
	_at_master_approach()
	var carrier: RefCounted = fly.eligible_creature()
	assert_ne(carrier, null, "ground team can launch at the authored Master approach")
	assert_true(carrier.has_meta(PARTY.LOANER_META))
	assert_eq(game.party.size(), 5)
	fly._loaner_transport_route = fly._master_transport_route()
	fly._creature = carrier
	fly.state = "glide"
	var route: Dictionary = fly._loaner_transport_route
	for path: Array in route.paths:
		for raw: Array in path:
			var point := Vector3(raw[0], raw[1], raw[2])
			player.global_position = point
			assert_ne(fly.eligible_creature(), null, "carrier persists along transport")
			assert_true(FLY.transport_route_contains(route, point))
	assert_ne(fly._restricted_reason(Vector3(950,1020,2706), Vector3.ZERO), "", "cannot explore outside the transport corridor")
	fly.state = "grounded"
	fly._loaner_transport_route = {}
	player.global_position = Vector3.ZERO
	assert_eq(fly.eligible_creature(), null, "no launch elsewhere")
	player.global_position = Vector3(400,610,3250)
	player.available = false
	assert_eq(fly.eligible_creature(), null, "combat cannot borrow the carrier")
	player.available = true
	game.current_realm = "stormwood"
	assert_eq(fly.eligible_creature(), null, "realm scope is enforced")


func test_master_transport_requires_unlock_and_fly_only_destination() -> void:
	_at_master_approach()
	fly.config["unlock_flag"] = "not_earned"
	assert_eq(fly.eligible_creature(), null)
	fly.config["unlock_flag"] = "fly_traversal_unlocked"
	fly.config.loaner_transport_routes.master_t4_perch.master_id = "master_t1"
	assert_eq(fly.eligible_creature(), null, "ordinary Master stands do not grant Fly")


func test_owned_carrier_takes_precedence_at_master_approach() -> void:
	_at_master_approach()
	# Use the existing party's first slot, without introducing a sixth member.
	game.party.at(0).species_id = "galecrest"
	game.party.set_active(0)
	assert_eq(fly.eligible_creature(), game.party.active())


func test_master_loaner_cannot_cut_outside_an_authored_corridor_bend() -> void:
	_at_master_approach()
	var loaner: RefCounted = fly.eligible_creature()
	fly._creature = loaner
	fly._loaner_transport_route = fly._master_transport_route()
	var route: Dictionary = fly._loaner_transport_route
	# Both endpoints are inside the shipping 110m corridor, but the midpoint
	# is 111.79m from its closest centreline. Endpoint-only checks let it pass.
	var from := Vector3(866.26522, 1057.36291, 2896.78219)
	var to := Vector3(873.63862, 1070.90472, 2892.50991)
	assert_true(FLY.transport_route_contains(route, from))
	assert_true(FLY.transport_route_contains(route, to))
	assert_false(FLY.transport_route_contains(route, (from + to) * 0.5))
	assert_false(FLY.transport_route_allows_step(route, from, to))
	assert_ne(fly._restricted_reason(from, to), "", "actual loaner movement must use the swept check")
	game.party.at(0).species_id = "galecrest"
	fly._creature = game.party.at(0)
	assert_eq(fly._restricted_reason(from, to), "", "the Master-only restriction does not apply to owned creatures")
	assert_eq(game.party.size(), 5)


func test_master_transport_accepts_authored_legs_and_overlapping_capsules() -> void:
	var route: Dictionary = fly.config.loaner_transport_routes.master_t4_perch
	for path: Array in route.paths:
		for i in range(1, path.size()):
			var a := Vector3(path[i - 1][0], path[i - 1][1], path[i - 1][2])
			var b := Vector3(path[i][0], path[i][1], path[i][2])
			assert_true(FLY.transport_route_allows_step(route, a, b))
	var joined := {"corridor_radius_m": 2.0, "paths": [[[0,0,0],[10,0,0],[10,0,10]]]}
	assert_true(FLY.transport_route_allows_step(joined, Vector3(7,0,1), Vector3(9,0,3)), "valid turn spans overlapping capsules")
	assert_false(FLY.transport_route_allows_step(joined, Vector3(7,0,2), Vector3(8,0,3)), "a concave shortcut leaves the union")
	assert_false(FLY.transport_route_allows_step(joined, Vector3.INF, Vector3.ZERO))
	assert_false(FLY.transport_route_allows_step({}, Vector3.ZERO, Vector3.ZERO))

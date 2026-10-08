extends "res://tests/test_case.gd"

## Process-writer selection only. Detached Game, real creature clocks, and
## explicit map/session/maintenance doubles; no network or F48 proof claim.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const NATIVE_CASE := preload("res://tests/helpers/passive_native_case.gd")

class LegacySession extends Node:
	var blocked := false
	func _owner_training_mutation_blocked(_owner: RefCounted) -> bool: return blocked
	func _altar_current_epoch() -> String: return "fixture-epoch"

class CanonicalSession extends LegacySession:
	var canonical := true
	func canonical_guest_passive() -> bool: return canonical

class MapFixture extends RefCounted:
	var visits := 0
	var region_updates := 0
	var discovered := 0
	func discovered_landmark_count() -> int: return discovered
	func mark_visited(_at: Vector3) -> void:
		visits += 1
		discovered = 1
	func update_region(_at: Vector3) -> void: region_updates += 1

class QuestFixture extends RefCounted:
	var updates := 0
	var lesson_signature := ""
	func set_realm(_realm: String) -> bool: return false
	func tracked_text(_progression: RefCounted) -> String:
		updates += 1
		return "current objective" + lesson_signature
	func tracked_hint(_progression: RefCounted) -> String: return "current hint" + lesson_signature
	func lesson_goal_signature() -> String: return lesson_signature

class GameFixture extends "res://autoload/game_state.gd":
	var actor: Node3D
	var autosave_ticks := 0
	var bed_ticks := 0
	var catch_ticks := 0
	func _tick_autosave(_delta: float) -> void: autosave_ticks += 1
	func _tick_creature_bed_recovery(_delta: float) -> void: bed_ticks += 1
	func _watch_pending_catch() -> void: catch_ticks += 1
	func _find_player() -> Node3D: return actor

var game: GameFixture
var owner_session: CanonicalSession
var map_state: MapFixture
var quests: QuestFixture
var creature: RefCounted
var original_feed: RefCounted
var _native_ready := false
var _native_completed := false

func _native_setup() -> void:
	original_feed = FEED._active
	game = GameFixture.new()
	game.actor = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(game.actor)
	game.actor.position = Vector3(2, 0, 0)
	owner_session = CanonicalSession.new()
	game.session = owner_session
	map_state = MapFixture.new()
	game.map = map_state
	quests = QuestFixture.new()
	game.quest_log = quests
	creature = SPECIES.spawn("terrapup")
	creature.rested = true
	creature.rested_seconds_left = 0.25
	creature.active_buffs.append({"id": "fixture", "remaining_s": 0.25, "stat": "attack", "scale": 1.2})
	assert_true(game.party.add(creature))
	game._travel_pos = Vector3.ZERO
	game._travel_pos_valid = true
	_native_ready = true

func _native_cleanup() -> void:
	if is_instance_valid(game):
		if is_instance_valid(game.actor): game.actor.free()
		game.free()
	if is_instance_valid(owner_session): owner_session.free()
	FEED.set_active(original_feed)

func _native_case_canonical_guest_preserves_care_and_bond_but_runs_other_process_work() -> void:
	var nourishment: float = creature.nourishment
	var happiness: float = creature.happiness
	var observations: Array[Dictionary] = []
	game.party_passive_tick.connect(func(packet: Dictionary) -> void: observations.append(packet))
	game._process(0.5)
	assert_eq(creature.nourishment, nourishment)
	assert_eq(creature.happiness, happiness)
	assert_eq(creature.rested_seconds_left, 0.25)
	assert_true(creature.rested)
	assert_eq(creature.distance_m_together, 0.0)
	assert_eq(creature.landmarks_visited_together, 0)
	assert_false(game._travel_pos_valid)
	assert_true(creature.active_buffs.is_empty(), "real buff clock still expires")
	assert_eq([game.autosave_ticks, game.bed_ticks, game.catch_ticks], [1, 1, 1])
	assert_eq([map_state.visits, map_state.region_updates, map_state.discovered], [1, 1, 1])
	assert_eq(game.objective_text, "current objective")
	assert_eq(game.objective_hint, "current hint")
	assert_eq(observations.size(), 1)
	assert_false(observations[0].condition_tick_applied, "buff-only observation never claims a condition tick")
	assert_eq(observations[0].delta, 0.5)
	assert_eq(observations[0].buffs_before.size(), 1)
	assert_true(observations[0].buffs_after.is_empty())
	assert_eq(observations[0].before.nourishment, observations[0].after.nourishment)
	# A canonical guest still receives live guidance when its flag revision
	# stays fixed. A posed line must survive both lesson and device changes.
	var revision := int(game.progression.get("revision"))
	var updates := quests.updates
	quests.lesson_signature = " next"
	game._process(0.0)
	assert_eq(int(game.progression.get("revision")), revision)
	assert_eq(game.objective_text, "current objective next")
	assert_eq(game.objective_hint, "current hint next")
	assert_eq(quests.updates, updates + 1)
	game.objective_text = "posed objective"
	game.objective_hint = ""
	game._objective_is_posed = true
	quests.lesson_signature = " later"
	game._last_input_was_gamepad = not game._last_input_was_gamepad
	game._process(0.0)
	assert_eq(game.objective_text, "posed objective")
	assert_eq(game.objective_hint, "")
	assert_eq(quests.updates, updates + 1)
	assert_true(game._objective_is_posed)

	_native_completed = true

func _native_case_absent_or_false_capability_keeps_local_clocks_and_bond() -> void:
	var legacy := LegacySession.new()
	game.session = legacy
	assert_false(game._canonical_guest_passive())
	var nourishment: float = creature.nourishment
	game._process(0.5)
	assert_true(creature.nourishment < nourishment)
	assert_false(creature.rested)
	assert_eq(creature.distance_m_together, 2.0)
	assert_eq(creature.landmarks_visited_together, 1)
	game.session = owner_session
	owner_session.canonical = false
	assert_false(game._canonical_guest_passive())
	game.actor.position.x += 2.0
	game._process(0.5)
	assert_eq(creature.distance_m_together, 4.0)
	game.session = null
	assert_false(game._canonical_guest_passive())
	legacy.free()

	_native_completed = true

func _native_case_canonical_interval_does_not_accumulate_resume_distance_or_landmarks() -> void:
	game._process(0.1)
	assert_false(game._travel_pos_valid, "fence resets even before discovery throttle runs")
	game.actor.position.x = 12.0
	game._process(0.5)
	assert_eq(map_state.discovered, 1)
	owner_session.canonical = false
	game.actor.position.x = 14.0
	game._process(0.5)
	assert_eq(creature.distance_m_together, 0.0, "first resumed position establishes a fresh baseline")
	assert_eq(creature.landmarks_visited_together, 0, "existing discoveries do not become delayed bond grants")
	game.actor.position.x = 16.0
	game._process(0.5)
	assert_eq(creature.distance_m_together, 2.0)

	_native_completed = true

func _native_case_existing_transaction_fence_still_blocks_all_mutation() -> void:
	owner_session.blocked = true
	game._process(0.5)
	assert_false(game._travel_pos_valid)
	assert_eq([game.autosave_ticks, game.bed_ticks, game.catch_ticks], [0, 0, 0])
	assert_eq([map_state.visits, map_state.region_updates], [0, 0])
	assert_eq(creature.active_buffs.size(), 1)
	assert_eq(creature.rested_seconds_left, 0.25)
	_native_completed = true

func test_canonical_guest_preserves_care_and_bond_but_runs_other_process_work() -> void:
	NATIVE_CASE.run_case(self, "res://tests/test_canonical_guest_passive_fence.gd", "_native_case_canonical_guest_preserves_care_and_bond_but_runs_other_process_work", 27)

func test_absent_or_false_capability_keeps_local_clocks_and_bond() -> void:
	NATIVE_CASE.run_case(self, "res://tests/test_canonical_guest_passive_fence.gd", "_native_case_absent_or_false_capability_keeps_local_clocks_and_bond", 9)

func test_canonical_interval_does_not_accumulate_resume_distance_or_landmarks() -> void:
	NATIVE_CASE.run_case(self, "res://tests/test_canonical_guest_passive_fence.gd", "_native_case_canonical_interval_does_not_accumulate_resume_distance_or_landmarks", 6)

func test_existing_transaction_fence_still_blocks_all_mutation() -> void:
	NATIVE_CASE.run_case(self, "res://tests/test_canonical_guest_passive_fence.gd", "_native_case_existing_transaction_fence_still_blocks_all_mutation", 6)

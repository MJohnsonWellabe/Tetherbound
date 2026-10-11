extends "res://tests/test_case.gd"

## Data-only integration of production SaveGame data loading and offline admission.
## No world, fight, input, accepted transaction, or earned result is fabricated.
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const TEMPLATE := "res://tests/fixtures/earned_saves/generated_input_base"
const GENERATED_LEVEL := 20  # Disclosed failed Hall input; no Hall/profile dependency.

class DataGame extends "res://autoload/game_state.gd":
	func initialize_data() -> void:
		# Keep the actual Game containers and Session; this test has no menu/world.
		reset_for_new_game()
		_mount_session()
		# Session._ready normally reads this exact checked-in configuration.
		session.set("_config", session.call("_load_config"))

var _games: Array[Node] = []

func after_each() -> void:
	for game: Node in _games:
		game.free()
	_games.clear()
	preload("res://scripts/creatures/progression_feed.gd").set_active(null)

func test_generated_levels_survive_same_process_and_fresh_offline_admission() -> void:
	var directory := "user://generated_admission_%s/save" % Crypto.new().generate_random_bytes(12).hex_encode()
	var manifest: Dictionary = DOCUMENT.parse(FileAccess.get_file_as_string(TEMPLATE.path_join("PROVENANCE.json")))
	for relative: String in manifest.files_sha256:
		var source := TEMPLATE.path_join("save").path_join(relative)
		var destination := directory.path_join(relative)
		assert_eq(FileAccess.get_sha256(source), manifest.files_sha256[relative])
		assert_eq(DirAccess.make_dir_recursive_absolute(destination.get_base_dir()), OK)
		assert_eq(DirAccess.copy_absolute(source, destination), OK)
	var game := _game(directory)
	if not _load(game, "template"):
		return
	_observe(game, "template")
	# The failed Hall attempt declared this unearned L20/full-HP input. Recreate
	# only its party setup; this test neither generates Hall outcomes nor plays it.
	for index in 5:
		var creature: RefCounted = game.party.at(index)
		creature.level = GENERATED_LEVEL
		creature.xp = 0
		creature.recompute_stats_from_base(PROGRESSION.config())
		var tiers := BREAKTHROUGH.caught_tiers(int(creature.level))
		var record: Dictionary = game.local.redesign_character.creatures[creature.uid]
		record.breakthroughs = tiers
		record.cap_level = BREAKTHROUGH.level_cap(tiers)
		creature.heal_fully()
	var expected := _cards(game.local.save_data().party)
	var saved := game.save_game(0)
	assert_true(saved, "declared generated input must save through Game.save_game")
	_observe(game, "generated_before_reload")
	if not saved or not _load(game, "same_process"):
		return
	_assert_admitted(game, expected, "same_process")
	var cold := _game(directory)
	if not _load(cold, "fresh_session"):
		return
	_assert_admitted(cold, expected, "fresh_session")

func _game(directory: String) -> DataGame:
	var game := DataGame.new()
	# run_tests executes in SceneTree._init before a main loop is installed.
	# Detached production Game data and its real parented Session need no scene.
	game.initialize_data()
	game.save_system = SAVE.new(directory)
	_games.append(game)
	return game

func _load(game: DataGame, phase: String) -> bool:
	# Game.load_game forwards to this exact loader, then restores scene nodes.
	# The data unit retains its real Session without requiring an installed tree.
	var loaded := bool(game.save_system.call("load_slot", game, 0))
	assert_true(loaded, phase + " production data Load")
	return loaded

func _cards(party: Array) -> Array:
	var cards: Array = []
	for raw: Dictionary in party:
		var card: Dictionary = {}
		for field: String in ["uid", "species_id", "level", "hp", "max_hp", "attack", "defence", "move_quick", "move_charged"]:
			card[field] = raw.get(field)
		cards.append(card)
	return cards

func _observe(game: DataGame, phase: String) -> Dictionary:
	var session: Node = game.session
	var admitted: Dictionary = session.call("admitted_character_state", session.call("local_peer_id"))
	var authority: RefCounted = session.get("_character_authority")
	var character := str(game.local.character_id)
	var portable := AUTHORITY.portable_projection(game.local.save_data())
	var row := {"phase": phase, "local": _cards(game.local.save_data().party),
		"admitted": _cards(admitted.get("party", [])), "character": character,
		"record_errors": AUTHORITY.errors(portable, character),
		"revision": authority.call("revision", character), "training_lock": authority.call("training_lock_reason", character),
		"detached_portable_training_recovery": _training_recovery(portable, character, game.world)}
	print("GENERATED ADMISSION " + JSON.stringify(row))
	return admitted

func _assert_admitted(game: DataGame, expected: Array, phase: String) -> void:
	var admitted := _observe(game, phase)
	assert_false(admitted.is_empty(), phase + " offline admission must exist")
	assert_eq(_cards(game.local.save_data().party), expected, phase + " local cards")
	assert_eq(_cards(admitted.get("party", [])), expected, phase + " authority cards")

func _training_recovery(portable: Dictionary, character: String, world: RefCounted) -> Dictionary:
	# Observe journal recovery on a separate disposable authority. Calling this
	# diagnostic on the live Session authority could repair the state under test.
	var probe := AUTHORITY.new()
	if not probe.bind_world(str(world.reward_delivery_namespace)):
		return {"ok": false, "code": "world_not_bound"}
	var seed: Dictionary = probe.seed_admitted_character(portable, character)
	if seed.get("ok") != true:
		return seed
	return probe.recover_durable_training(character, world.reward_deliveries)

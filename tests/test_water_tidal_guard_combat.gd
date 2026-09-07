extends "res://tests/test_case.gd"

const RELICS := preload("res://autoload/realm_heart_state.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class GameAdapter extends Node:
	var realm_hearts: RefCounted = RELICS.new()

class Body extends Node3D:
	func centre() -> Vector3: return global_position
	func facing() -> Vector3: return Vector3.FORWARD
	func add_impulse(_direction: Vector3, _amount: float) -> void: pass
	func play_hit() -> void: pass
	func play_faint() -> void: pass
	func play_attack() -> void: pass
	func combat_config() -> Dictionary:
		return {"power": 8.0, "reach": 20.0, "arc_degrees": 180.0, "lunge": 0.0}

class Manager extends "res://scripts/combat/combat_manager.gd":
	func _ready() -> void:
		set_physics_process(false)
		_moves = MOVE_DB.new()
	func _flash_at(_where: Vector3, _charged: bool, _tint: Variant = null, _struck: Node3D = null, _damage_fraction: float = 0.0) -> void:
		pass

func _run_initialized_cases() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var old_game := tree.root.get_node_or_null("Game")
	if old_game != null: old_game.name = "OriginalGame"
	var game := GameAdapter.new()
	game.name = "Game"
	tree.root.add_child(game)
	var manager := Manager.new()
	game.add_child(manager)
	var ally := Body.new()
	var enemy := Body.new()
	game.add_child(ally)
	game.add_child(enemy)
	ally.position = Vector3(0, 0, -1)
	var creature := CREATURE.from_species("terrapup", {"base_hp": 1000.0, "base_attack": 20.0, "base_defence": 20.0, "type": "ground"})
	manager._party = [creature] as Array[RefCounted]
	manager._active_index = 0
	manager._ally_body = ally
	manager._wild = enemy
	manager._enemy = CREATURE.from_species("terrapup", {"base_hp": 1000.0, "base_attack": 20.0, "base_defence": 20.0, "type": "ground"})
	manager.state = manager.State.ACTIVE
	var flags := FLAGS.new()
	for id in ["water", "meadows", "cloudreach", "stormwood"]:
		flags.set_flag(game.realm_hearts.earned_flag(id))
		assert_true(game.realm_hearts.place(id, flags))
	var payload := {"damage": 100.0, "move_id": "", "type_mult": 1.0, "lunge": 0.0}
	var unchanged := payload.duplicate(true)
	for id in ["", "water", "meadows", "cloudreach", "stormwood"]:
		game.realm_hearts.clear_active()
		if id != "": assert_true(game.realm_hearts.activate(id, flags))
		creature.hp = creature.max_hp
		var before: float = creature.hp
		manager.apply_host_enemy_hit(payload)
		assert_almost_eq(before - creature.hp, 90.0 if id == "water" else 100.0, 0.0001, "Host hit must apply only the current owner's power: " + id)
		assert_eq(payload, unchanged, "The shared host payload must remain base damage")
		assert_eq(game.realm_hearts.active_id(), id)
	# Drive the ordinary production strike, resetting the RNG and creature HP
	# so the difference must come from the owner's active relic, not a new roll.
	game.realm_hearts.clear_active()
	creature.hp = creature.max_hp
	manager._rng.seed = 7731
	var before: float = creature.hp
	manager._on_enemy_strike()
	var ordinary_damage: float = before - creature.hp
	assert_true(ordinary_damage > 0.0, "The real ordinary strike must connect")
	assert_true(game.realm_hearts.activate("water", flags))
	creature.hp = creature.max_hp
	manager._rng.seed = 7731
	before = creature.hp
	manager._on_enemy_strike()
	assert_almost_eq(before - creature.hp, ordinary_damage * 0.9, 0.0001, "Ordinary strike must use the same single reduction as a host hit")
	assert_eq(game.realm_hearts.active_id(), "water")
	assert_eq(game.realm_hearts.stamina_capacity_multiplier(), 1.0)
	game.free()
	if old_game != null: old_game.name = "Game"

func test_actual_owner_health_mutation_and_ordinary_strike_in_initialized_tree() -> void:
	var path := "user://water-tidal-guard-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null: return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_water_tidal_guard_combat.gd").new()\n\ttest._run_initialized_cases()\n\tprint("TIDAL_GUARD_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count >= 28 else 1)\n')
	file.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", ProjectSettings.globalize_path("user://water-tidal-guard-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("TIDAL_GUARD_RESULT="):
			result = JSON.parse_string(line.trim_prefix("TIDAL_GUARD_RESULT="))
	assert_true(int(result.get("assertions", 0)) >= 28, combined)
	assert_eq(result.get("failures", ["missing result"]), [])

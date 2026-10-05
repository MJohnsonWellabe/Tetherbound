extends "res://tests/test_case.gd"

## F33 Harness maximum HP, fight-scoped (coordinator ruling 2026-10-05), on the
## PRODUCTION combat_manager paths: the solo enemy strike (_on_enemy_strike)
## and the session hit (apply_host_enemy_hit), plus the host's struck card.
## - start: in a fight the creature shows hp x s over max x s, same fraction;
## - a hit: the bar drops by the rolled damage, i.e. stored HP loses damage / s;
## - end: out of the fight the stored fraction is the fraction it fought at;
## - authority: a session hit's host s replaces the local record's;
## - save: the saved party row (save_game._party_to_array) holds the base max
##   mid-fight and after it.
## Disclosed fixtures: a stub Game holding the owner record and relic state, a
## stub body pair, and gear written straight into the record (as the
## test_creature_gear fixtures do). Runs in a child tree like
## test_water_tidal_guard_combat so /root/Game is the stub.

const RELICS := preload("res://autoload/realm_heart_state.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const GEAR := preload("res://scripts/creatures/creature_gear.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

class LocalRecord extends RefCounted:
	var redesign_character: Dictionary = {"creatures": {}}

class GameAdapter extends Node:
	var realm_hearts: RefCounted = RELICS.new()
	var local: RefCounted = LocalRecord.new()

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

class Party extends RefCounted:
	var list: Array = []
	func members() -> Array: return list


func _strike(manager: Node, creature: RefCounted, seed_value: int) -> float:
	manager._action = manager.Action.READY
	manager._reset_player_poise()
	manager._rng.seed = seed_value
	var before: float = creature.hp
	manager._on_enemy_strike()
	return before - float(creature.hp)


func _saved_max(creature: RefCounted) -> float:
	var party := Party.new()
	party.list = [creature]
	return float((SAVE.new("user://harness_max_hp_probe")._party_to_array(party)[0] as Dictionary).max_hp)


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
	var uid := str(creature.get("uid"))
	manager._party = [creature] as Array[RefCounted]
	manager._active_index = 0
	manager._ally_body = ally
	manager._wild = enemy
	manager._enemy = CREATURE.from_species("terrapup", {"base_hp": 1000.0, "base_attack": 20.0, "base_defence": 20.0, "type": "ground"})
	manager.state = manager.State.ACTIVE
	var base_max: float = creature.max_hp
	var creatures: Dictionary = game.local.redesign_character.creatures

	# Bare: no raise, the reference damage for a fixed roll.
	creature.hp = base_max * 0.5
	assert_eq(manager.display_hp(creature), Vector2(creature.hp, base_max), "bare: the stored HP is shown")
	var bare_loss := _strike(manager, creature, 7731)
	assert_true(bare_loss > 0.0, "the real solo strike connects")

	# Rootiron Harness (charm empty so the roll is unchanged but for defence).
	# Defence is a separate Harness stat; isolate max HP by comparing the
	# displayed loss to the stored loss at the same roll.
	creatures[uid] = {"gear": {"harness": "rootiron_harness", "charm": ""}}
	manager._party_hp_scale.clear()
	var s := float(GEAR.modifiers(creatures[uid].gear, GEAR.config()).max_hp)
	assert_true(s > 1.0, "Rootiron raises maximum HP (s=%.2f)" % s)
	creature.hp = base_max * 0.5
	var shown: Vector2 = manager.display_hp(creature)
	assert_almost_eq(shown.y, base_max * s, 0.001, "start: the fight shows the raised maximum")
	assert_almost_eq(shown.x / shown.y, 0.5, 0.0001, "start: current HP keeps its fraction")
	assert_almost_eq(creature.max_hp, base_max, 0.0001, "start: the stored maximum is untouched")
	var hud_text := preload("res://scripts/ui/combat_hud.gd").ally_level_text(creature, manager)
	assert_true(hud_text.contains("/%d" % roundi(base_max * s)), "the combat HUD names the raised maximum: " + hud_text)
	var shown_before: float = manager.display_hp(creature).x
	var stored_loss := _strike(manager, creature, 7731)
	var shown_loss: float = shown_before - manager.display_hp(creature).x
	assert_almost_eq(stored_loss * s, shown_loss, 0.001, "a hit: the bar drops by the rolled damage")
	assert_true(stored_loss < bare_loss / s + 0.001, "a hit: the stored HP loses at most damage / s (defence also helps)")
	assert_almost_eq(_saved_max(creature), base_max, 0.0001, "save mid-fight: the base maximum")
	var fraction_in_fight: float = manager.display_hp(creature).x / manager.display_hp(creature).y

	# Session hit: the host's s is the authority, not the local record's.
	var host_s := 1.24
	creature.hp = base_max * 0.5
	manager._action = manager.Action.READY
	manager._reset_player_poise()
	manager.apply_host_enemy_hit({"damage": 100.0, "move_id": "", "type_mult": 1.0, "lunge": 0.0, "hp_scale": host_s})
	assert_almost_eq(base_max * 0.5 - creature.hp, 100.0 / host_s, 0.0001, "session hit: stored HP loses damage / host s")
	assert_almost_eq(base_max * 0.5 * host_s - manager.display_hp(creature).x, 100.0, 0.0001,
		"session hit: a rolled hit of 100 drops the displayed bar by exactly 100")
	assert_almost_eq(manager.display_hp(creature).y, base_max * host_s, 0.001, "session hit: the bar shows the host's maximum")
	manager._party_hp_scale.clear()
	manager.apply_host_enemy_hit({"damage": 100.0, "move_id": "", "type_mult": 1.0, "lunge": 0.0, "hp_scale": 99.0})
	assert_true(float(manager._party_hp_scale[uid]) <= float(manager._max_hp_scale()) + 0.0001,
		"a host s is bounded by the strongest authored Harness")

	# End: out of the fight nothing is raised; the stored fraction is the one shown.
	creature.hp = base_max * fraction_in_fight
	manager.state = manager.State.INACTIVE
	assert_eq(manager.display_hp(creature), Vector2(creature.hp, base_max), "end: the stored HP is shown again")
	assert_almost_eq(creature.hp / creature.max_hp, fraction_in_fight, 0.0001, "end: the fraction it fought at")
	assert_almost_eq(_saved_max(creature), base_max, 0.0001, "save after the fight: the base maximum")
	assert_eq(preload("res://scripts/ui/combat_hud.gd").ally_level_text(creature, manager), "Lv %d" % int(creature.level),
		"out of a fight the HUD line is the level alone")

	# Gear off: no raise at all.
	manager.state = manager.State.ACTIVE
	creatures.erase(uid)
	manager._party_hp_scale.clear()
	assert_eq(manager.display_hp(creature), Vector2(creature.hp, base_max), "no Harness, no raise")
	game.free()
	if old_game != null: old_game.name = "Game"


func test_harness_max_hp_is_fight_scoped_on_the_production_combat_paths() -> void:
	var path := "user://harness-max-hp-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null: return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_harness_max_hp.gd").new()\n\ttest._run_initialized_cases()\n\tprint("HARNESS_HP_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count >= 18 else 1)\n')
	file.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute,
		"--log-file", ProjectSettings.globalize_path("user://harness-max-hp-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("HARNESS_HP_RESULT="):
			result = JSON.parse_string(line.trim_prefix("HARNESS_HP_RESULT="))
	assert_true(int(result.get("assertions", 0)) >= 18, combined)
	assert_eq(result.get("failures", ["missing result"]), [])

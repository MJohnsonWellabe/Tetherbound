extends SceneTree

## Actual WorldState/WorldSave disk bytes versus read-only F49 observation.
## Declared seed fixtures reproduce the R8 saved/override mismatch. No earned
## route, input, rewards or full handoff acceptance is claimed by this probe.
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const WORLD := preload("res://autoload/world_state.gd")
const STORE := preload("res://scripts/save/world_save.gd")
const SPAWNS := preload("res://scripts/combat/spawn_tables.gd")
var _checks := 0
var _failures: Array[String] = []

class ObservedGame extends Node:
	var world: RefCounted
	var world_seed: int:
		get: return int(world.get("world_seed"))

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)

func _run() -> void:
	var had_override := OS.has_environment(SPAWNS.SEED_ENV_VAR)
	var previous_override := OS.get_environment(SPAWNS.SEED_ENV_VAR)
	var game := ObservedGame.new()
	game.world = WORLD.new()
	game.world.set("world_seed", 1434901555)
	var store := STORE.new("user://f19_population_probe_%d" % OS.get_process_id())
	_check(store.write("observed-world", game.world.call("save_data")), "actual WorldSave write")
	var save_path: String = store.path_for("observed-world")
	var before := FileAccess.get_file_as_bytes(save_path)
	var disk: Dictionary = store.read("observed-world")
	_check(int(disk.get("world_seed")) == 1434901555, "saved ordinary world seed")
	var handoff := HANDOFF.new(self, game, "user://unused_population_handoff")
	var fixture := {"generator": "existing boundary generator", "owner_policy": "#5726060136810",
		"prior_earned_play": false, "continuous_fresh_save": false}
	_check(HANDOFF._generated_fixture_valid(fixture), "explicit generated input provenance is unearned")
	for field: String in ["prior_earned_play", "continuous_fresh_save"]:
		var invalid_flag := fixture.duplicate(true)
		invalid_flag[field] = true
		_check(not HANDOFF._generated_fixture_valid(invalid_flag), "generated input refuses a true " + field + " claim")
		invalid_flag[field] = 0
		_check(not HANDOFF._generated_fixture_valid(invalid_flag), "generated input requires a typed false " + field)
	var invalid := fixture.duplicate(true)
	invalid["passed"] = true
	_check(not HANDOFF._generated_fixture_valid(invalid), "generated provenance refuses a PASS field")
	invalid = fixture.duplicate(true)
	invalid.owner_policy = "unbound policy"
	_check(not HANDOFF._generated_fixture_valid(invalid), "generated input requires its exact owner policy")
	invalid = fixture.duplicate(true)
	invalid.generator = " "
	_check(not HANDOFF._generated_fixture_valid(invalid), "generated input requires its named generator")
	var pieces := HANDOFF.new(self, game, "user://unused_generated_handoff", HANDOFF.MEADOWS_PIECES, HANDOFF.MEADOWS_REALMS)
	_check(pieces._generated_origin_valid({"boundary": "warrens", "provenance": fixture}), "Warrens may seed the next parallel segment")
	_check(pieces._generated_origin_valid({"boundary": "hall", "provenance": fixture}), "Hall fixture retains an explicit unearned origin")
	for boundary: String in ["opening_team", "bridge", "unknown", "completed_world"]:
		_check(not pieces._generated_origin_valid({"boundary": boundary, "provenance": fixture}), "generated input refuses boundary " + boundary)
	_check(not handoff._generated_origin_valid({"boundary": "meadows_settled", "provenance": fixture}), "generated input retains the required five-creature piece lineage")
	_check(not pieces.export_boundary("warrens", {"passed": true}, "generated_fixture", fixture), "generated export refuses an earned proof before any save")
	_check(pieces.history.is_empty() and pieces.snapshots.is_empty(), "rejected generated export creates no earned history")
	OS.unset_environment(SPAWNS.SEED_ENV_VAR)
	var observed: Dictionary = handoff.population_provenance()
	_check(observed.saved_world_seed == disk.world_seed, "normal observed saved seed matches disk")
	_check(observed.effective_encounter_seed == disk.world_seed, "normal encounter population matches disk")
	_check(observed.has_environment_override == false and observed.environment_override == "", "normal override absent")
	OS.set_environment(SPAWNS.SEED_ENV_VAR, "4")
	observed = handoff.population_provenance()
	_check(observed.saved_world_seed == disk.world_seed, "override does not rewrite reported saved seed")
	_check(observed.effective_encounter_seed == 4, "actual encounter-only override observed")
	_check(observed.has_environment_override == true and observed.environment_override == "4", "override provenance retained")
	_check(int(game.world.get("world_seed")) == disk.world_seed, "observation leaves actual world unchanged")
	_check(FileAccess.get_file_as_bytes(save_path) == before, "observation leaves actual save bytes unchanged")
	OS.unset_environment(SPAWNS.SEED_ENV_VAR)
	_check(handoff.population_provenance().effective_encounter_seed == disk.world_seed, "ordinary reload population differs from capture override")
	if had_override: OS.set_environment(SPAWNS.SEED_ENV_VAR, previous_override)
	else: OS.unset_environment(SPAWNS.SEED_ENV_VAR)
	_check(store.delete("observed-world"), "remove only probe-owned actual disk file")
	game.free()
	print("F19 POPULATION PROVENANCE " + JSON.stringify({"checks": _checks, "failures": _failures,
		"scope": "Actual split disk seed and read-only provenance; declared fixtures, no earned route"}))
	quit(0 if _failures.is_empty() else 1)

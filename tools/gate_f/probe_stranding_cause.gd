extends SceneTree

## T2-STRANDING. Answers the open question in `RESTARTS.md`'s "South Bridge
## gate still never opens" entry directly, live in the engine, rather than by
## re-reading telemetry: whether `_ally`/`_ally.fainted`/`_ally_body`/
## `is_instance_valid(_ally_body)` are true or false at the moment a trainer
## challenge is attempted, for the exact save the run actually produced.
##
##   godot --headless --path . --script tools/gate_f/probe_stranding_cause.gd
##
## Loads gate-f-run-20260828T183531Z's real `S05-exit.json` (party: one
## fainted Ripplet, "Moss") through the production `SaveGame.load_slot()`
## path, presses the same `creature_recall` action RIG-13's own S05-09a step
## presses after every load, then asks `EncounterDirector.can_challenge()`
## the same question `trainer_npc.gd::_on_challenged()` asks before every
## fight in the game -- including the South Bridge grunt. Then heals the
## party's only creature the same way a creature bed does
## (`creature_instance.gd::heal_fully()`) and asks again, to prove the block
## is the ordinary, recoverable "no usable creature" rule rather than
## anything wrong with the bridge, the gate, or the `move_to` primitive.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const REAL_STRANDED_SAVE := "res://ralph/reports/gate-f-run-20260828T183531Z/S05/saves/S05-exit.json"
const SETTLE_FRAMES := 300

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	var save := SAVE_GAME.new()
	var slot_dst := save.slot_path(4)
	DirAccess.make_dir_recursive_absolute(slot_dst.get_base_dir())
	if not FileAccess.file_exists(REAL_STRANDED_SAVE):
		print("PROBE FAIL: %s does not exist" % REAL_STRANDED_SAVE)
		quit(1)
		return
	var bytes := FileAccess.get_file_as_bytes(REAL_STRANDED_SAVE)
	var out := FileAccess.open(slot_dst, FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()
	print("seeded slot 4 from the real S05-exit.json (%d bytes)" % bytes.size())

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("PROBE FAIL: no Game autoload after boot")
		quit(1)
		return

	var applied := save.load_slot(game, 4)
	print("load_slot(4) applied: %s" % applied)
	for i in 60:
		await physics_frame

	var party: RefCounted = game.get("party")
	if party == null:
		print("PROBE FAIL: Game has no party after load")
		quit(1)
		return
	var active: RefCounted = party.call("active")
	if active == null:
		print("PROBE FAIL: party.active() is null after loading a 1-creature save")
		quit(1)
		return
	print("party size after load: %d" % int(party.call("size")))
	print("active creature: %s  fainted=%s  hp=%s/%s"
		% [str(active.call("label")), str(active.get("fainted")), str(active.get("hp")), str(active.get("max_hp"))])

	var director := world.get_node_or_null(^"EncounterDirector")
	if director == null:
		print("PROBE FAIL: world has no EncounterDirector")
		quit(1)
		return

	print("")
	print("--- BEFORE creature_recall (mirrors a fresh load, pre S05-09a) ---")
	print("_ally=%s _ally_body=%s" % [str(director.get("_ally")), str(director.get("_ally_body"))])

	print("")
	print("--- pressing creature_recall (RIG-13's S05-09a step: summon_active_creature()) ---")
	var summoned: bool = await director.call("summon_active_creature")
	print("summon_active_creature() returned: %s" % str(summoned))
	var ally_after: RefCounted = director.get("_ally")
	var ally_body_after: Node3D = director.get("_ally_body")
	print("_ally=%s  _ally.fainted=%s  _ally_body=%s  is_instance_valid(_ally_body)=%s" % [
		str(ally_after), str(ally_after.get("fainted")) if ally_after != null else "n/a",
		str(ally_body_after), str(is_instance_valid(ally_body_after))
	])
	if summoned:
		_fail("summon_active_creature() succeeded with a fainted-only party -- expected it to refuse (creature_bed.gd L864 guard)")
	if ally_body_after != null:
		_fail("_ally_body was spawned despite a fainted-only party")

	var spec := TRAINER_NPC.trainer("south_bridge_grunt")
	if spec.is_empty():
		print("PROBE FAIL: no trainer spec 'south_bridge_grunt' in trainers.json")
		quit(1)
		return
	var can_before: bool = director.call("can_challenge", spec)
	print("")
	print("can_challenge(south_bridge_grunt) BEFORE healing: %s" % str(can_before))
	if can_before:
		_fail("can_challenge() returned true with a fainted-only party -- expected false")

	print("")
	print("--- healing the party's only creature the way a creature bed does (heal_fully()) ---")
	active.call("heal_fully")
	print("active creature after heal_fully(): fainted=%s hp=%s/%s"
		% [str(active.get("fainted")), str(active.get("hp")), str(active.get("max_hp"))])

	var summoned2: bool = await director.call("summon_active_creature")
	print("summon_active_creature() after heal returned: %s" % str(summoned2))
	if not summoned2:
		_fail("summon_active_creature() still refused after heal_fully() -- the ally should now be deployable")

	var can_after: bool = director.call("can_challenge", spec)
	print("can_challenge(south_bridge_grunt) AFTER healing: %s" % str(can_after))
	if not can_after:
		_fail("can_challenge() still false after healing the only creature -- something else is also blocking the gate")

	print("")
	if _failures.is_empty():
		print("PROBE PASS: the block is exactly and only the fainted-ally rule "
			+ "(encounter_director.gd L864/L1568), and it clears the moment the "
			+ "party's only creature is healed -- the same recovery a creature "
			+ "bed performs. No other obstruction found at the gate.")
		quit(0)
	else:
		print("PROBE FOUND UNEXPECTED BEHAVIOUR (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)

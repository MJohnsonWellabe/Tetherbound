extends SceneTree

## Balance evidence, not a victory smoke. All damage/AI/XP/rounds come from the
## production Cloudreach director and manager. No lethal seam or HP assignments.
## Movement/attacks/run use combat_pilot; voluntary switching presses party_cycle
## through the production CombatHUD (the base pilot otherwise calls cycle_active).
## Flat collision fixture isolates stats/AI from world hazards and route geometry.
## --fixed-fps 60 accelerates wall time without changing simulation time.
## Example: godot --headless --path . --fixed-fps 60 --script
## tools/_probe_cloudreach_combat_balance.gd -- --pilot=brawler_switch --loss-retry

const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const MANAGER := preload("res://scripts/combat/cloudreach_combat_manager.gd")
const CAMERA := preload("res://scripts/player/camera_rig.gd")
const HUD := preload("res://scenes/combat/combat_hud.tscn")
const PILOT := preload("res://tools/combat_pilot.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const PARTY := preload("res://autoload/party.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RECOVERY := preload("res://scripts/creatures/home_recovery.gd")
const PROMPT := preload("res://scripts/world/interactable.gd")
const TEAMS := {
	"mixed": ["terrapup", "ripplet", "galewisp", "mosshell", "duskhush"],
	"ground": ["terrapup", "bramblebun", "mudsnout", "trailpup", "meadowhart"],
}
const CAMPS := {
	"trainer_ila_lower_ring": "galefoot_waycamp",
	"keeper_maela_trial": "windscar_flight_aerie_camp",
	"young_trainer_tavi_upper_ring": "cliffhold_commons",
	"officer_voss_summit_approach": "summit_bivouac",
	"captain_veyra_storm_anchor": "summit_bivouac",
}
## Explicit assignment scope; newly authored optional rematches are separate
## encounters with their own unlock/reward contracts, not an eighth base rung.
const LADDER: Array[String] = [
	"trainer_ila_lower_ring", "trainer_orrin_bridge_watch", "tether_lieutenant_senn",
	"keeper_maela_trial", "young_trainer_tavi_upper_ring", "officer_voss_summit_approach",
	"captain_veyra_storm_anchor",
]
const OUTPUT_DIR := "res://ralph/reports/CLOUDREACH-COMBAT-BALANCE-0905"
const MAX_BATTLE_FRAMES := 36000

class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 100.0
	func ground_height_near(_at: Vector3) -> float:
		return 100.0

class TrainerStandIn extends Node3D:
	func add_prompt(label: String, radius: float) -> Node3D:
		var prompt := PROMPT.new()
		prompt.position = Vector3.UP
		prompt.configure(label, radius)
		add_child(prompt)
		return prompt

class NoOwnerSaves extends RefCounted:
	func save(_game: Node, _slot: int) -> bool:
		return true

class InputPilot extends PILOT:
	var switch_input := false
	var voluntary_switches := 0
	func _act(ally_body: Node3D, foe_body: Node3D) -> void:
		if switch_input and _should_switch():
			var before: RefCounted = manager.call("active_creature")
			await press("party_cycle")
			if manager.call("active_creature") != before:
				voluntary_switches += 1
			return
		await super._act(ally_body, foe_body)

var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _manager: Node
var _director: Node
var _pilot: InputPilot
var _modes: Array[String] = ["spacer", "brawler", "brawler_switch"]
var _team := "mixed"
var _lead := 0
var _tag := ""
var _only := ""
var _loss_retry := false
var _report: Dictionary = {}
var _errors: Array[String] = []
var _switches := 0
var _starts: Array[String] = []
var _wins: Array[String] = []
var _losses: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pilot="):
			_modes.assign([arg.trim_prefix("--pilot=")])
		elif arg.begins_with("--team="):
			_team = arg.trim_prefix("--team=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--lead="):
			_lead = clampi(int(arg.trim_prefix("--lead=")), 0, 4)
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=").validate_filename()
		elif arg == "--loss-retry":
			_loss_retry = true
	if not TEAMS.has(_team):
		push_error("Unknown team")
		quit(1)
		return
	await _setup()
	_report = {"team": _team, "tag": _tag, "species": TEAMS[_team], "starting_level": 25, "lead_index": _lead,
		"source_sha256": {"chapter": FileAccess.get_sha256(DIRECTOR.CHAPTER_PATH),
			"encounters": FileAccess.get_sha256(DIRECTOR.CONFIG_PATH),
			"combat": FileAccess.get_sha256("res://data/config/combat.json"),
			"progression": FileAccess.get_sha256(PROGRESSION.CONFIG_PATH)},
		"progression": "Natural production battle XP; full recovery/rest XP at named camp boundaries only",
		"limitations": ["Flat arena; no approach travel, wild attrition, geometry or finale hazards",
			"Camp services assumed reached; recovery uses public home_recovery.rest for each of five",
			"No consumables spent; missing HP/revive estimates measure optional camp avoidance",
			"Average default individuality, fresh bond counters, installed default moves, no candy or stat boosts",
			"Production damage RNG remains random; exact damage/duration varies across runs",
			"No owner saves; prerequisite flags seeded solely for challenge access"],
		"runs": [], "retry": {}}
	for mode: String in _modes:
		await _reset_party()
		_pilot.pilot = PILOT.Pilot.SPACER if mode == "spacer" else PILOT.Pilot.BRAWLER
		_pilot.switch_input = mode.ends_with("_switch")
		var run := {"pilot": mode, "fights": [], "recoveries": []}
		for id: String in LADDER:
			if not _only.is_empty() and id != _only:
				continue
			if CAMPS.has(id):
				run["recoveries"].append(_recover(str(CAMPS[id])))
			var result := await _fight(id, false)
			run["fights"].append(result)
			if not bool(result.get("won", false)) and id != "captain_veyra_storm_anchor":
				# Loss is evidence; allow later fights a documented retreat rather
				# than hiding all subsequent rungs behind an exhausted five.
				run["recoveries"].append(_recover("retreat_after_loss:" + id))
		_report["runs"].append(run)
	if _loss_retry:
		await _reset_party()
		_pilot.pilot = PILOT.Pilot.BRAWLER
		_pilot.switch_input = true
		var id := "trainer_ila_lower_ring"
		var lost := await _fight(id, true)
		var can_retry_before_recovery: bool = _director.can_challenge(_director.trainer_specs[id])
		var recovery := _recover("galefoot_waycamp_retry")
		var retry := await _fight(id, false)
		_report["retry"] = {"loss": lost, "challengeable_while_fainted": can_retry_before_recovery,
			"recovery": recovery, "retry": retry,
			"passed": not lost.get("won", false) and lost.get("loss_callback", false)
				and lost.get("faints", 0) == 5 and retry.get("won", false)}
		if not _report["retry"]["passed"]:
			_errors.append("Actual all-five loss/recovery/retry did not complete")
	_report["errors"] = _errors
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var suffix := "%s-%s-lead%d%s" % [_team, "-".join(_modes), _lead, "-" + _only if not _only.is_empty() else ""]
	if not _tag.is_empty():
		suffix += "-" + _tag
	var output := OUTPUT_DIR + "/" + suffix + ".json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(_report, "\t"))
	file.close()
	print("CLOUDREACH BALANCE COMPLETE: %s errors=%s" % [output, _errors])
	_world.queue_free()
	await process_frame
	quit(0 if _errors.is_empty() else 1)

func _setup() -> void:
	await process_frame
	_game = root.get_node("Game")
	_game.set_process(false)
	_game.save_system = NoOwnerSaves.new()
	_game.progression = FLAGS.new()
	_game.party = PARTY.new()
	_game.inventory = INVENTORY.new(_game.items)
	_world = FlatWorld.new()
	_world.name = "CloudreachBalanceFixture"
	root.add_child(_world)
	current_scene = _world
	var floor := StaticBody3D.new()
	floor.position.y = 99.5
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(240, 1, 240)
	collision.shape = box
	floor.add_child(collision)
	_world.add_child(floor)
	_player = CharacterBody3D.new()
	_player.name = "Player"
	_player.position = Vector3(0, 100, 0)
	_world.add_child(_player)
	_rig = CAMERA.new()
	_rig.name = "CameraRig"
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	_rig.add_child(camera)
	_world.add_child(_rig)
	camera.current = true
	_rig.set_target(_player)
	_manager = MANAGER.new()
	_manager.name = "CombatManager"
	_manager.ground_world = _world
	_manager.creature_switched.connect(func(_index: int) -> void: _switches += 1)
	_world.add_child(_manager)
	var data := DIRECTOR.read_json(DIRECTOR.CONFIG_PATH)
	var reused := {}
	data["wild_sites"] = []
	for placement: Dictionary in data["trainers"]:
		var id := str(placement["id"])
		var trainer := TrainerStandIn.new()
		trainer.position = Vector3(70, 100, 70)
		_world.add_child(trainer)
		placement["reuse_npc_id"] = id
		reused[id] = trainer
		for flag: String in placement.get("requires_flags", []):
			_game.progression.set_flag(flag)
	_director = DIRECTOR.new()
	_director.name = "EncounterDirector"
	_director.player_path = ^"../Player"
	_director.manager_path = ^"../CombatManager"
	_director.camera_rig_path = ^"../CameraRig"
	_director.setup(_world, reused, data)
	_director.trainer_started.connect(func(id: String) -> void: _starts.append(id))
	_director.trainer_victory.connect(func(id: String) -> void: _wins.append(id))
	_director.trainer_lost.connect(func(id: String) -> void: _losses.append(id))
	_world.add_child(_director)
	var hud := HUD.instantiate()
	hud.manager_path = ^"../CombatManager"
	hud.director_path = ^"../EncounterDirector"
	_world.add_child(hud)
	_pilot = InputPilot.new(self, _manager, _director, _rig)
	_pilot.use_switching = false
	_pilot.listen()
	await _frames(20)

func _reset_party() -> void:
	await _leave()
	_director.dismiss_active_creature()
	_game.party.clear()
	for species: String in TEAMS[_team]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
		member.heal_fully()
		_game.party.add(member)
	_game.party.set_active(_lead)
	for spec: Dictionary in _director.trainer_specs.values():
		_game.progression.set_flag(str(spec["defeat_flag"]), false)
	await _frames(15)

func _party_snapshot() -> Array:
	var members: Array = []
	for i in _game.party.size():
		var member: RefCounted = _game.party.at(i)
		members.append({"species": member.species_id, "level": member.level,
			"xp": member.xp, "hp": member.hp, "max_hp": member.max_hp,
			"fainted": member.fainted, "bond_nodes": member.bond_nodes()})
	return members

func _recover(camp: String) -> Dictionary:
	var before := _party_snapshot()
	var replacement_cost := _consumable_equivalent()
	for i in _game.party.size():
		RECOVERY.rest(_game.party.at(i), PROGRESSION.config())
	return {"camp": camp, "before": before, "after": _party_snapshot(),
		"consumables_equivalent_before": replacement_cost}

## Cost to restore current HP using the real item values. No items are used.
## Per-creature ceiling matters: one large potion cannot heal two creatures.
func _consumable_equivalent() -> Dictionary:
	var potion: Dictionary = _game.items.definition("potion_large")
	var revive: Dictionary = _game.items.definition("revive")
	var potions := 0
	var revives := 0
	for member: Dictionary in _party_snapshot():
		var missing := float(member["max_hp"]) - float(member["hp"])
		if member["fainted"]:
			revives += 1
			missing = float(member["max_hp"]) * (1.0 - float(revive.get("revive", 0.5)))
		potions += ceili(maxf(0.0, missing - 0.001) / float(potion.get("heal", 80.0)))
	return {"potion_large": potions, "revive": revives}

func _fight(id: String, passive: bool) -> Dictionary:
	await _leave()
	_director.dismiss_active_creature()
	_player.global_position = Vector3(0, 100, 0)
	_player.velocity = Vector3.ZERO
	await _frames(10)
	await _director.summon_active_creature()
	await _frames(10)
	seed(90525 + hash(id))
	_pilot.reset_tally()
	_pilot.voluntary_switches = 0
	_switches = 0
	_starts.clear()
	_wins.clear()
	_losses.clear()
	var spec: Dictionary = _director.trainer_specs[id]
	var before := _party_snapshot()
	var rewards_before: int = _game.inventory.count("coin")
	var start_frame := Engine.get_physics_frames()
	var record := {"id": id, "passive": passive, "team_before": before,
		"deployed_before": str(_director.ally_instance().species_id) if _director.ally_instance() != null else "",
		"opposition": spec["team"], "rounds": []}
	if not _director.begin_trainer_battle(spec, null):
		_errors.append(id + " challenge refused")
		record["error"] = "challenge refused"
		return record
	while _director.trainer_battle_active() and Engine.get_physics_frames() - start_frame < MAX_BATTLE_FRAMES:
		if _manager.is_fighting() and not passive:
			var opponent: RefCounted = _manager.enemy()
			var ally: RefCounted = _manager.active_creature()
			var round_start := Engine.get_physics_frames()
			var round_result: Dictionary = await _pilot.fight_to_the_end()
			round_result["species"] = opponent.species_id
			round_result["ally_at_start"] = ally.species_id
			round_result["seconds"] = float(Engine.get_physics_frames() - round_start) / Engine.physics_ticks_per_second
			record["rounds"].append(round_result)
			print("ROUND %s %s %.2fs outcome=%s" % [id, opponent.species_id, round_result["seconds"], round_result["outcome"]])
			if round_result["timed_out"]:
				_errors.append(id + " pilot round timeout")
				break
		else:
			await physics_frame
	var frames := Engine.get_physics_frames() - start_frame
	var timed_out: bool = _director.trainer_battle_active()
	await _leave()
	await _frames(160)
	var hp := 0.0
	var max_hp := 0.0
	var faints := 0
	for member: Dictionary in _party_snapshot():
		hp += member["hp"]
		max_hp += member["max_hp"]
		faints += 1 if member["fainted"] else 0
	var won: bool = _game.progression.has(str(spec["defeat_flag"]))
	record.merge({"won": won, "timed_out": timed_out,
		"seconds": float(frames) / Engine.physics_ticks_per_second,
		"team_after": _party_snapshot(), "party_hp_fraction": hp / max_hp,
		"consumables_to_full": _consumable_equivalent(),
		"missing_hp": max_hp - hp, "faints": faints,
		"hits_dealt": _pilot.hits_dealt, "hits_taken": _pilot.hits_taken,
		"damage_dealt": _pilot.damage_dealt, "damage_taken": _pilot.damage_taken,
		"misses_both_sides": _pilot.misses, "switches_total": _switches,
		"switches_voluntary": _pilot.voluntary_switches,
		"quick_inputs": _pilot.quick_thrown, "charged_inputs": _pilot.charged_thrown,
		"verdicts_on_enemy": _pilot.verdicts_on_enemy,
		"verdicts_on_ally": _pilot.verdicts_on_ally,
		"coins_paid": _game.inventory.count("coin") - rewards_before,
		"start_callbacks": _starts.duplicate(), "victory_callback": _wins.has(id),
		"loss_callback": _losses.has(id)})
	if timed_out:
		_errors.append(id + " unresolved battle")
	print("FIGHT %s won=%s seconds=%.2f hp=%.1f%% faints=%d hits=%d/%d damage=%.1f/%.1f switches=%d/%d" % [
		id, won, record["seconds"], hp / max_hp * 100, faints,
		_pilot.hits_dealt, _pilot.hits_taken, _pilot.damage_dealt, _pilot.damage_taken,
		_switches, _pilot.voluntary_switches])
	return record

func _leave() -> void:
	for i in 6:
		if not _director.trainer_battle_active() and not _manager.is_fighting():
			return
		if _manager.is_fighting():
			await _pilot.press("combat_run")
		await _frames(120)

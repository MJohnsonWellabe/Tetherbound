extends SceneTree

## F14#1 / F14#0: one named Tidewake trainer fight played BY INPUT in the actual
## Water world, not on the flat combat_depth fixture. The real Water archipelago
## scene, the trainer's installed body (Nerissa's in the Heart Chamber), the
## production summon and challenge prompt, the production CombatManager and
## hosted trainer roster. The shared READER/MASHER policy
## (tests/helpers/f22_pattern_pilot.gd) presses the real input actions, with
## movement mapped through the production CameraRig as a player's stick is.
##
## One process = one fight (a fresh world each time, so no defeat flag, failure
## relocation or party state carries between runs). Loop it for C2 seeds:
##
##   godot --headless --path . --fixed-fps 60 --script tests/smoke_tidewake_named_inworld_c2.gd \
##     -- --trainer=water_trainer_nerissa --starter=ripplet --policy=READER --seed=0 \
##        [--party-level=43] [--gear-tier=<tier>] [--gear-upgrade=0..3] --json=<file>
##
## Preparation that is NOT ordinary play, disclosed in the JSON: the party is
## granted (the original five at --party-level, starter leading), the player
## is placed in front of the trainer, and Nerissa's two upstream pump flags are
## set so the Heart Chamber stands. No HP, damage, victory or roster injection.
const PILOT := preload("res://tests/helpers/f22_pattern_pilot.gd")
const GEAR := preload("res://tests/helpers/f33_gear_fixture.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
const INTERIOR_FLAGS := ["water_veilfall_intake_stopped", "water_veilfall_return_opened"]
const FIGHT_CAP_S := 900.0


## The shared pilot, driven against production nodes instead of its fixture.
class WorldPilot:
	extends "res://tests/helpers/f22_pattern_pilot.gd"
	var rig: Node
	var _observation_scope: Array = []

	func bind(manager: Node, ally: CharacterBody3D, wild: CharacterBody3D) -> bool:
		_manager = manager
		_ally = ally
		_wild = wild
		var enemy: RefCounted = wild.get("instance") if is_instance_valid(wild) else null
		var arena: Node = manager.arena() if is_instance_valid(manager) else null
		var active: bool = is_instance_valid(manager) and manager.state == MANAGER.State.ACTIVE
		var scope: Array = []
		if active and is_instance_valid(ally) and is_instance_valid(wild) and enemy != null and is_instance_valid(arena):
			scope = [manager.get_instance_id(), str(manager.encounter_id()), arena.get_instance_id(),
				wild.get_instance_id(), enemy.get_instance_id(), str(enemy.get("uid"))]
		if scope != _observation_scope:
			_observation_scope = scope
			_prepared_body = 0
			_tell_seen_frame = -1
			_opening_seen_frame = -1
			_escape_dir = Vector3.ZERO
			_last_shape.clear()
			_fields.clear()
			_pending_field.clear()
		if not active: return true # Send-out gaps supply no combat observation.
		if scope.is_empty():
			_tally["fixture_error"] = "active world pilot lost its actual bodies, opponent or arena"
			return false
		var patterns: Variant = wild.get("_patterns")
		var current: Variant = wild.get("_pattern_context")
		var observer: Variant = wild.get("_pattern_observer")
		var director: Node = manager.get("_encounter_link")
		if not patterns is Dictionary or patterns.get("runtime_enabled") != true \
			or not current is Dictionary or current.get("species_id") != enemy.get("species_id") \
			or current.get("trainer_owned") != wild.get("trainer_owned") \
			or current.get("move_quick") != enemy.get("move_quick") or current.get("move_charged") != enemy.get("move_charged") \
			or not current.get("pattern_id") is String or not current.get("sendout_index") is int \
			or not observer is Callable or not observer.is_valid() or not is_instance_valid(director) \
			or observer != Callable(director, "_f22_visible_observation").bind(wild):
			_tally["fixture_error"] = "world pilot requires the current Director's live pattern context and bound observer"
			return false
		# Adopt the Director's existing setup. The inherited fixture initializer
		# must never reset live patterns, cues, cursors or the host observer.
		context = current.duplicate(true)
		_prepared_body = wild.get_instance_id()
		return true

	func step(policy: String) -> void:
		_release_attack()
		_release_move()
		if not is_instance_valid(_manager) or _manager.state != MANAGER.State.ACTIVE: return
		if _wild == null or not is_instance_valid(_wild) or _ally == null or not is_instance_valid(_ally):
			return
		_enemy_windup_before_tick = _wild.is_winding_up()
		_act(policy)
		_frames += 1

	## Production movement is camera-relative: map the world direction the
	## policy wants through the CameraRig's planar basis, as the captain smoke does.
	func _walk(direction: Vector3) -> void:
		var local: Vector3 = rig.planar_basis().inverse() * direction if rig != null else direction
		super(local)


var _checks: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var trainer_id := "water_trainer_nerissa"
	var starter := "ripplet"
	var policy := "READER"
	var seed_value := 0
	var level := 43
	var out := ""
	var gear: Dictionary = GEAR.from_args()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="): trainer_id = arg.trim_prefix("--trainer=")
		elif arg.begins_with("--starter="): starter = arg.trim_prefix("--starter=")
		elif arg.begins_with("--policy="): policy = arg.trim_prefix("--policy=")
		elif arg.begins_with("--seed="): seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--party-level="): level = int(arg.trim_prefix("--party-level="))
		elif arg.begins_with("--json="): out = arg.trim_prefix("--json=")
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "inworld-c2-%d" % seed_value
	game.world.world_id = "inworld-c2-world-%d" % seed_value
	game.save_system = SAVE.new("user://inworld_c2_%d_%d/" % [seed_value, Time.get_ticks_usec()])
	var party: Array[RefCounted] = []
	for id: String in [starter] + RETAINED:
		var creature: RefCounted = SPECIES.spawn(id)
		creature.set_level(level, PROGRESSION.config())
		game.local.party.add(creature)
		party.append(creature)
	# Ordinary named fights require the same complete owner carrier and saved
	# authority as play. Keep this smoke's unique SaveSystem; never save the
	# gear-only legacy fixture rows used by detached balance simulations.
	game.local.redesign_character = game.local.save_data().redesign_character
	GEAR.equip(self, party, str(gear.tier), int(gear.upgrade), false)
	var result := {"trainer": trainer_id, "starter": starter, "pilot": policy, "seed": seed_value,
		"gear": GEAR.label(str(gear.tier), int(gear.upgrade)),
		"party_level": level, "fixture": "actual Water world; granted party; player placed at the trainer; pump flags set; isolated canonical save/admission",
		"won": false, "error": ""}
	if not str(gear.tier).is_empty():
		result.fixture += "; granted Harness/Charm gear merged into complete owner records; not earned gear"
	var entry_max: Dictionary = {}
	var party_max := 0.0
	for member in party:
		entry_max[member.get_instance_id()] = float(member.max_hp)
		party_max += float(member.max_hp)
	for flag: String in INTERIOR_FLAGS:
		game.world.flags.set_flag(flag)
	if not game.save_system.save(game, SAVE.AUTOSAVE_SLOT):
		_finish(out, result, "isolated fixture save refused")
		return
	# Fresh retained duties route through the actual session registry before
	# owner staging. Lazy character admission alone cannot establish that peer.
	if not game.session.host():
		_finish(out, result, "actual host session refused")
		return
	var registry: RefCounted = game.session.get("_registry")
	if registry == null or int(registry.call("peer_for_character", game.local.character_id)) != game.session.local_peer_id():
		_finish(out, result, "actual host registry did not register the fixture character")
		return
	var admitted: Dictionary = game.session.admitted_character_state(game.session.local_peer_id())
	var admitted_party: Array = admitted.get("party", [])
	if admitted.get("character_id") != game.local.character_id or admitted_party.size() != party.size():
		_finish(out, result, "isolated fixture party admission refused")
		return
	for index in party.size():
		if not admitted_party[index] is Dictionary or admitted_party[index].get("uid") != party[index].get("uid"):
			_finish(out, result, "isolated fixture party admission changed identity")
			return
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 600000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not world.shell_build_complete():
		_finish(out, result, "Water world did not build")
		return
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var player: Node3D = world.local_rig()
	var spec: Dictionary = director.trainer_specs.get(trainer_id, {})
	if spec.has("position") and not director.trainer_nodes.has(trainer_id):
		var at: Array = spec.position
		var near := Vector3(float(at[0]), 0.0, float(at[2]) + 6.0)
		near.y = float(world.ground_height_at(near.x, near.z)) + 0.3
		player.global_position = near
	deadline = Time.get_ticks_msec() + 60000
	while not director.trainer_nodes.has(trainer_id) and Time.get_ticks_msec() < deadline:
		await process_frame
	var trainer: Node3D = director.trainer_nodes.get(trainer_id)
	if trainer == null:
		_finish(out, result, "trainer not stood up")
		return
	player.global_position = trainer.global_position + Vector3(0, 0.1, -2.7)
	player.velocity = Vector3.ZERO
	await _frames(20)
	if not await director.summon_active_creature():
		_finish(out, result, "summon failed")
		return
	await _frames(12)
	var prompt: Node3D = director.trainer_prompts.get(trainer_id)
	if prompt == null or prompt.interaction_offer(player.global_position).is_empty():
		_finish(out, result, "no challenge prompt in reach")
		return
	prompt.interaction_activate()
	await _frames(3)
	var dialogue: Node = world.get_node_or_null("DialoguePanel")
	for step in 30:
		if manager.is_fighting() or dialogue == null or not dialogue.is_open():
			break
		dialogue.advance()
		await _frames(3)
	if not (director.trainer_battle_id() == trainer_id and manager.is_fighting()):
		result.entry = {"requested":trainer_id,"active":director.trainer_battle_id(),
			"pending":director.trainer_challenge_pending(),"sent":int(director.get("_trainer_battle_sent")),
			"manager_state":int(manager.get("state")),"dialogue_open":dialogue != null and dialogue.is_open(),
			"mounted_npc_matches":director.get("_trainer_node") == trainer,
			"sendout_body_valid":is_instance_valid(director.get("_trainer_body")),
			"can_challenge":director.can_challenge(spec)}
		_finish(out, result, "challenge did not start the fight")
		return
	var arena: Variant = manager.get("_arena")
	result.arena_radius = snappedf(float((arena as Node).get("radius")), 0.01) if arena is Node else -1.0
	var pilot := WorldPilot.new()
	pilot.rig = world.get_node("CameraRig")
	pilot._tally = {"hits": 0, "incoming_hits": 0, "misses": 0, "max_hit_frac": 0.0, "neutral_worst_frac": 0.0, "events": [],
		"player_windup_cancellations": 0, "charged_interrupts": 0, "stagger_events": 0,
		"burst_uses": 0, "charged_uses": 0, "quick_uses": 0}
	pilot._entry_maxima = entry_max
	manager.hit_landed.connect(pilot._on_hit)
	manager.state_changed.connect(pilot._on_state_changed)
	(manager.get("_rng") as RandomNumberGenerator).seed = seed_value
	var seeded: Dictionary = {}
	var tells: Array = []
	var observed: Array = []
	var tell_began: Array = [-1]
	var fight_s := 0.0
	var opponents := 0
	while director.trainer_battle_active() and fight_s < FIGHT_CAP_S:
		var enemy: CharacterBody3D = manager.enemy_body() as CharacterBody3D
		var ally: CharacterBody3D = director.ally_body() as CharacterBody3D
		if is_instance_valid(enemy) and not seeded.has(enemy.get_instance_id()):
			seeded[enemy.get_instance_id()] = true
			opponents += 1
			(enemy.get("_rng") as RandomNumberGenerator).seed = seed_value + opponents
			enemy.telegraph_started.connect(func(seconds: float) -> void:
				tells.append(seconds)
				tell_began[0] = Engine.get_physics_frames())
			# Observed, not declared: physics frames from the tell's start to its
			# strike, for every tell the pilot did not interrupt (F14 re-check).
			enemy.strike_ready.connect(func() -> void:
				if tell_began[0] >= 0:
					observed.append(snappedf((Engine.get_physics_frames() - tell_began[0]) / 60.0, 0.01))
				tell_began[0] = -1)
		if not pilot.bind(manager, ally, enemy):
			pilot._release_attack()
			pilot._release_move()
			_finish(out, result, str(pilot._tally.get("fixture_error", "world pilot binding refused")))
			return
		if manager.is_fighting():
			pilot.step(policy)
		await physics_frame
		fight_s += 1.0 / Engine.physics_ticks_per_second
	pilot._release_attack()
	pilot._release_move()
	var party_hp := 0.0
	var faints := 0
	for member in party:
		party_hp += member.hp_fraction() * float(entry_max[member.get_instance_id()])
		if member.fainted:
			faints += 1
	result.won = game.world.flags.has(str(spec.get("defeat_flag", "")))
	result.seconds = snappedf(fight_s, 0.01)
	result.opponents_seen = opponents
	result.lead_lost_frac = 1.0 - party[0].hp_fraction()
	result.party_lost_frac = 1.0 - party_hp / maxf(1.0, party_max)
	result.faints = faints
	result.party_wiped = faints == party.size()
	result.max_hit_frac = pilot._tally.max_hit_frac
	result.incoming_hits = pilot._tally.incoming_hits
	result.hits = pilot._tally.hits
	result.min_tell_s = tells.min() if not tells.is_empty() else -1.0
	result.max_tell_s = tells.max() if not tells.is_empty() else -1.0
	result.observed_tells = observed.size()
	result.terminal_outcome = str(manager.get("_outcome"))
	# Preserve the actual retained terminal result when a completed creature
	# round cannot advance; these observations do not settle or replay it.
	var rounds: Dictionary = director.get("_ordinary_combat_rounds")
	var terminal: Dictionary = rounds.get(str((director.get("_encounter") as Dictionary).get("encounter_id", "")), {})
	result.terminal = {"manager_state": int(manager.get("state")), "trainer_active": director.trainer_battle_active(),
		"round": int(terminal.get("round", 0)), "round_resolved": terminal.get("resolved", false),
		"completion_resolved": terminal.get("completion_resolved", false),
		"resolution_result": (terminal.get("last_resolution_result", {}) as Dictionary).duplicate(true),
		"round_exit_pending": not (director.get("_ordinary_combat_round_exit") as Dictionary).is_empty()}
	result.min_observed_tell_s = observed.min() if not observed.is_empty() else -1.0
	result.max_observed_tell_s = observed.max() if not observed.is_empty() else -1.0
	result.capped = fight_s >= FIGHT_CAP_S
	if int(result.hits) + int(result.incoming_hits) == 0:
		_finish(out, result, "fight ended without an observed damage exchange")
		return
	_finish(out, result, "")


func _finish(out: String, result: Dictionary, error: String) -> void:
	result.error = error
	print("TIDEWAKE INWORLD C2 " + JSON.stringify(result))
	if not out.is_empty():
		var file := FileAccess.open(out, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(result))
	quit(0 if error.is_empty() else 1)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

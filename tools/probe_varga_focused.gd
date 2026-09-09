extends SceneTree

## One authorized synthetic admission/position seam; inherited controller combat.
const ENTRY := preload("res://tests/smoke_stormwood_continuous.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const TELEMETRY := preload("res://tests/helpers/stormwood_combat_telemetry.gd")
const VARGA := "lieutenant_varga_rodline_bridge"
var finished := false
var segment: ObservedSegment
var telemetry := TELEMETRY.new()
var output: FileAccess
var last_sample_ms := 0
var last_impact_key := ""
var game: Node
var world: Node3D

class ObservedSegment extends ENTRY.Segment:
	var observe: Callable
	var duel_started := -1
	var counts := {"quick_presses": 0, "quick_releases": 0,
		"player_hits": 0, "enemy_hits": 0, "player_misses": 0,
		"enemy_misses": 0, "player_damage": 0.0, "enemy_damage": 0.0,
		"stick": [0.0, 0.0]}
	func _fight_current_encounter(label: String) -> bool:
		duel_started = Time.get_ticks_msec()
		observe.call("duel_entry")
		var ok: bool = await super._fight_current_encounter(label)
		observe.call("duel_return")
		duel_started = -1
		return ok
	func _set_action(action: StringName, pressed: bool) -> void:
		if action == &"combat_quick":
			if not pressed and duel_started >= 0 and (not bool(manager.call("is_fighting"))
					or Time.get_ticks_msec() - duel_started >= 180000):
				observe.call("terminal_before_quick_release")
			counts["quick_presses" if pressed else "quick_releases"] += 1
		super._set_action(action, pressed)
	func _send_stick(x: float, y: float) -> void:
		counts.stick = [x, y]
		super._send_stick(x, y)
	func on_hit(on_enemy: bool, amount: float) -> void:
		counts["player_hits" if on_enemy else "enemy_hits"] += 1
		counts["player_damage" if on_enemy else "enemy_damage"] += amount
	func on_miss(by_player: bool) -> void:
		counts["player_misses" if by_player else "enemy_misses"] += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_timeout.call_deferred()
	output = FileAccess.open(OS.get_environment("TETHERBOUND_TELEMETRY_OUTPUT"), FileAccess.WRITE)
	if output == null:
		_finish(false, "cannot open telemetry artifact")
		return
	game = root.get_node("Game")
	game.set("save_system", SAVE.new("user://synthetic_varga_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]))
	await process_frame
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "synthetic-varga-diagnostic")
	game.get("world").set("world_id", "synthetic-varga-diagnostic")
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	var key: String = game.get("realm_hearts").call("entry_key_for_realm", "stormwood")
	var verdict: Dictionary = game.get("ledger").call("submit", {
		"kind": "set_world_flag", "realm": "cloudreach", "id": key, "value": true})
	if not bool(verdict.get("ok", false)) or bool(verdict.get("pending", false)):
		_finish(false, "synthetic router key refused")
		return
	for id: String in ENTRY.ENTRY_PARTY:
		var creature: RefCounted = SPECIES.spawn(id)
		creature.call("set_level", 44, PROGRESSION.config())
		if not bool(game.get("party").call("add", creature)):
			_finish(false, "synthetic party add refused")
			return
	_write({"label": "fixture", "synthetic": true, "route_key": key,
		"stormwood_seeded_flags": [], "party": ENTRY.ENTRY_PARTY, "level": 44})
	var source := Node3D.new()
	root.add_child(source)
	current_scene = source
	await process_frame
	if not await game.call("enter_realm", "stormwood", "stormwood_arrival_from_cloudreach"):
		_finish(false, "production router refused synthetic admission")
		return
	for _frame in ENTRY.SCENE_WAIT_FRAMES:
		world = current_scene as Node3D
		if world != null and world.name == "Stormwood" and world.call("shell_build_complete") \
				and str(game.get("pending_realm_entry")) == "" \
				and bool(world.get_node("EncounterDirector").get("population_ready")):
			break
		await physics_frame
	if world == null or world.name != "Stormwood" or not world.call("shell_build_complete") \
			or str(game.get("pending_realm_entry")) != "" \
			or not bool(world.get_node("EncounterDirector").get("population_ready")):
		_finish(false, "production world did not settle")
		return
	segment = ObservedSegment.new()
	segment.tree = self
	segment.world = world
	segment.game = game
	segment.player = world.get_node("Player")
	segment.camera = world.get_node("CameraRig")
	segment.director = world.get_node("EncounterDirector")
	segment.manager = world.get_node("CombatManager")
	segment.arbiter = get_first_node_in_group("interaction_arbiter")
	segment.navigator = NAVIGATOR.new(self, segment.player, segment.camera, segment._send_stick)
	segment.observe = _capture
	game.get("session").connect("stormwood_encounter_message", segment._on_stormwood_encounter_message)
	segment.manager.connect("exited", segment._on_combat_exited)
	segment.manager.connect("hit_landed", segment.on_hit)
	segment.manager.connect("attack_missed", segment.on_miss)
	var trainers: Node = world.get_node("StormwoodTrainers")
	var spec: Dictionary = trainers.get("authored_specs").get(VARGA, {})
	if spec.is_empty() or not (spec.get("requires_flags", []) as Array).is_empty():
		_finish(false, "Varga authored admission differs from prelaunch empty-prerequisite brief")
		return
	var trainer: Node3D = trainers.call("body_for", VARGA)
	var at := trainer.global_position + Vector3(0, 0, -2)
	at.y = float(world.call("ground_height_at", at.x, at.z)) + 0.3
	# The only authorized human placement; no setup mutation after this point.
	segment.player.global_position = at
	segment.player.velocity = Vector3.ZERO
	_write({"label": "single_fixture_placement", "position": [at.x, at.y, at.z],
		"flags_at_start": game.get("progression").call("all_set")})
	physics_frame.connect(_sample)
	var won: bool = await segment._defeat_trainer(VARGA)
	_finish(won, "synthetic Varga sequence returned; no campaign credit")

func _sample() -> void:
	if finished or segment == null:
		return
	var hub := world.get_node_or_null("StormwoodEncounterHub")
	var fight: Node = hub.get("fights").get(VARGA) if hub != null else null
	var impact: Dictionary = fight.get("last_strike") if is_instance_valid(fight) else {}
	var key := "%s/%s/%s/%s" % [impact.get("encounter_id", ""), impact.get("round", -1),
		impact.get("action", -1), impact.get("host_now_ms", -1)]
	if not impact.is_empty() and key != last_impact_key:
		last_impact_key = key
		_capture("new_impact")
	if Time.get_ticks_msec() - last_sample_ms >= 1000:
		last_sample_ms = Time.get_ticks_msec()
		_capture("periodic")

func _capture(label: String) -> void:
	if segment == null or not is_instance_valid(world):
		_write({"label": label, "world_ready": false})
		return
	var hub := world.get_node_or_null("StormwoodEncounterHub")
	var fight: Node = hub.get("fights").get(VARGA) if hub != null else null
	# A finished round can leave a freed body reference in the manager until
	# its next begin. Validate Variant before any typed assignment/cast.
	var raw_ally: Variant = segment.director.call("ally_body")
	var raw_replica: Variant = segment.manager.call("enemy_body")
	var ally: Node3D = TELEMETRY.live_body(raw_ally)
	var replica: Node3D = TELEMETRY.live_body(raw_replica)
	var row := telemetry.capture(label, fight, segment.manager, ally, replica, segment.counts)
	row["duel_elapsed_ms"] = Time.get_ticks_msec() - segment.duel_started if segment.duel_started >= 0 else -1
	row["quick_reach"] = segment.manager.call("combat_move_reach", "quick")
	row["quick_pressed"] = Input.is_action_pressed("combat_quick")
	row["last_outcome"] = segment._last_combat_outcome
	row["trainer_outcomes"] = segment._trainer_outcomes.duplicate(true)
	row["failures"] = segment.failures.duplicate()
	row["player_position"] = [segment.player.global_position.x, segment.player.global_position.y, segment.player.global_position.z]
	var vitals: RefCounted = segment.player.get("vitals")
	row["human_health"] = vitals.get("health") if vitals != null else null
	row["human_max_health"] = vitals.get("max_health") if vitals != null else null
	_write(row)

func _write(row: Dictionary) -> void:
	if output != null:
		output.store_line(JSON.stringify(row))
		output.flush()
	if str(row.get("label", "")) != "periodic" and str(row.get("label", "")) != "new_impact":
		print("VARGA FOCUSED ", row.get("label", ""), " round=", row.get("round", -1), " wall_ms=", Time.get_ticks_msec())

func _timeout() -> void:
	await create_timer(590.0, true, false, true).timeout
	if not finished:
		_finish(false, "590-second internal watchdog")

func _finish(ok: bool, detail: String) -> void:
	if finished:
		return
	_capture("terminal_outer")
	finished = true
	_write({"label": "result", "ok": ok, "detail": detail,
		"failures": segment.failures if segment != null else [], "wall_ms": Time.get_ticks_msec()})
	if output != null:
		output.close()
	print("VARGA FOCUSED ", "PASS" if ok else "FAIL", ": ", detail)
	quit(0 if ok else 1)

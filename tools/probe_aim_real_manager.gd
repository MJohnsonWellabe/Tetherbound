extends SceneTree

## One synthetic encounter; no campaign acceptance or post-setup repair.
const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
var world: Node3D
var game: Node
var prep: RefCounted
var catcher: RefCounted
var manager: Node
var wild: Node3D
var player: CharacterBody3D
var rig: Node3D
var output: FileAccess
var finished := false
var phase := "boot"
var releases := 0
var strikes := 0
var misses := 0
var seen_launch: Dictionary = {}
var sampler: Node
var manual: ManualCancel

class ManualCancel extends Node:
	var aim: Node
	var event_for: Callable
	var record: Callable
	var observed := false
	var valid := false
	var cancelled := false
	var held := false
	var commit_frame := -1
	var cancel_frame := -1
	func _physics_process(_delta: float) -> void:
		if not observed and float(aim.get("_windup")) > 0:
			observed = true
			commit_frame = Engine.get_physics_frames()
			var preview: Dictionary = aim.call("aim_report")
			valid = aim.get("_committed_assist_point") != Vector3.INF \
				and bool(preview.get("eligible", false)) \
				and not bool(preview.get("trajectory_blocked", true))
			record.call("manual_commit")
			held = true
			Input.parse_input_event(event_for.call(&"menu_cancel", true))
			Input.flush_buffered_events()
		if observed and not cancelled and int(aim.get("state")) == 0:
			cancelled = true
			cancel_frame = Engine.get_physics_frames()
			record.call("manual_cancel")
			stop()
	func stop() -> void:
		set_physics_process(false)
		if held:
			held = false
			Input.parse_input_event(event_for.call(&"menu_cancel", false))
			Input.flush_buffered_events()
	func _exit_tree() -> void:
		stop()

class Sampler extends Node:
	var observe: Callable
	func _physics_process(_delta: float) -> void:
		observe.call()

class InputTrace extends Node:
	var observe: Callable
	func _input(event: InputEvent) -> void:
		if event is InputEventJoypadButton:
			observe.call("delivered_button:%d:%s" % [event.button_index, event.pressed])

class AimPhaseTrace extends Node:
	var observe: Callable
	var label := ""
	func _physics_process(_delta: float) -> void:
		observe.call(label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(590.0, true, false, true).timeout.connect(func() -> void:
		_finish(false, "590-second watchdog at " + phase))
	output = FileAccess.open(OS.get_environment("TETHERBOUND_TELEMETRY_OUTPUT"), FileAccess.WRITE)
	if output == null:
		_finish(false, "cannot open telemetry")
		return
	game = root.get_node("Game")
	game.set("save_system", SAVE.new("user://synthetic_aim_%d" % OS.get_process_id()))
	await process_frame
	game.call("reset_for_new_game")
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 60
	var starter: RefCounted = SPECIES.spawn("terrapup")
	var cfg: Dictionary = PROGRESSION.config()
	starter.call("set_level", int(cfg.get("level", {}).get("starter_level", 3)), cfg)
	if not bool(game.get("party").call("add", starter)):
		_finish(false, "initial starter grant refused")
		return
	game.get("inventory").call("add", "orb_basic", 15)
	world = (load("res://scenes/world/meadows_playground.tscn") as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	var director := world.get_node("EncounterDirector")
	var deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < deadline:
		if world.call("shell_build_complete") and director.call("wild_creature") != null:
			break
		await physics_frame
	if not world.call("shell_build_complete") or director.call("wild_creature") == null:
		_finish(false, "90-second world readiness deadline")
		return
	player = world.get_node("Player")
	rig = world.get_node("CameraRig")
	manager = world.get_node("CombatManager")
	player.global_position = Vector3(48, float(world.call("ground_height_at", 48, -58)) + 1, -58)
	player.velocity = Vector3.ZERO
	if director.call("ally_body") == null:
		if not await director.call("summon_active_creature"):
			_finish(false, "initial party deployment refused")
			return
	for _frame in 120:
		await physics_frame
	wild = director.call("wild_creature")
	prep = OPENING.new()
	prep.set("_tree", self)
	prep.set("_world", world)
	if not prep.call("_collect_world_nodes"):
		_finish(false, "opening dependencies absent")
		return
	prep.set("_wild", wild)
	phase = "fixture_complete"
	_capture(phase)
	phase = "engagement"
	if not await prep.call("_walk_to_and_engage_wild", wild, 2600):
		_finish(false, "ordinary engagement failed")
		return
	var aim: Node = manager.call("throw_aim")
	aim.connect("orb_struck", func(_body: Node3D, _offset: float) -> void:
		strikes += 1
		_capture("orb_struck"))
	aim.connect("orb_missed", func(reason: String) -> void:
		misses += 1
		_capture("orb_missed:" + reason))
	manager.connect("catch_resolved", func(success: bool, shakes: int) -> void:
		_capture("catch_resolved:%s:%d" % [success, shakes]))
	sampler = Sampler.new()
	sampler.observe = _sample
	world.add_child(sampler)
	var input_trace := InputTrace.new()
	input_trace.observe = _capture
	world.add_child(input_trace)
	for label: String in ["before_native_aim", "after_native_aim"]:
		var trace := AimPhaseTrace.new()
		trace.label = label
		trace.observe = _aim_trace
		trace.process_physics_priority = aim.process_physics_priority
		aim.get_parent().add_child(trace)
		aim.get_parent().move_child(trace, aim.get_index() + (1 if label == "after_native_aim" else 0))
	phase = "manual_aim"
	if not await prep.call("_open_throw_aim") or not await prep.call("_aim_at_wild") \
			or not prep.call("_final_throw_verdict_ready"):
		_finish(false, "manual case cannot acquire strict eligible aim")
		return
	var stock_before := int(game.get("inventory").call("count", "orb_basic"))
	var tool_before := str(game.get("equipped_tool"))
	var enemy_before: RefCounted = manager.call("enemy")
	var own_before: RefCounted = manager.call("active_creature")
	manual = ManualCancel.new()
	manual.aim = aim
	manual.event_for = prep._event_for
	manual.record = _capture
	manual.process_physics_priority = aim.process_physics_priority
	aim.get_parent().add_child(manual)
	aim.get_parent().move_child(manual, aim.get_index() + 1)
	phase = "manual_eight_tick_tap"
	await prep.call("_tap_action", &"interact")
	_capture("tap_return")
	for _frame in 3:
		await process_frame
	_capture("post_hud_idle")
	var manual_ok: bool = manual.observed and manual.valid and manual.cancelled \
		and manual.cancel_frame == manual.commit_frame + 1 \
		and bool(manager.call("is_fighting")) and not bool(manager.call("is_aiming")) \
		and manager.call("enemy") == enemy_before and manager.call("active_creature") == own_before \
		and not own_before.get("fainted") and not enemy_before.get("fainted") \
		and int(game.get("inventory").call("count", "orb_basic")) == stock_before \
		and str(game.get("equipped_tool")) == tool_before \
		and (aim.call("last_launch") as Dictionary).is_empty() \
		and not Input.is_action_pressed("combat_run") \
		and not Input.is_action_pressed("creature_recall")
	manual.stop()
	manual.queue_free()
	manual = null
	if not manual_ok:
		_finish(false, "manual valid-windup cancellation contract failed")
		return
	print("REAL_MANAGER manual valid cancellation PASS")
	phase = "actual_catch_existing"
	catcher = OPENING.new()
	var party_before := int(game.get("party").call("size"))
	var target_species := str(enemy_before.get("species_id"))
	var result: Dictionary = await catcher.call("catch_existing", self, world, game, player, rig, wild)
	_capture("catch_existing_return")
	var party: RefCounted = game.get("party")
	var ok := bool(result.get("passed", false)) and not bool(manager.call("is_fighting")) \
		and str(manager.call("outcome")) == "caught" and int(party.call("size")) == party_before + 1 \
		and str(party.call("at", party_before).get("species_id")) == target_species \
		and releases > 0 and strikes > 0 \
		and int(game.get("inventory").call("count", "orb_basic")) < stock_before
	_finish(ok, "catch_existing failures=" + str(result.get("failures", [])))

func _sample() -> void:
	if finished:
		return
	var aim: Node = manager.call("throw_aim")
	var launch: Dictionary = aim.call("last_launch")
	if not launch.is_empty() and launch != seen_launch:
		seen_launch = launch.duplicate(true)
		releases += 1
		_capture("native_release")

func _aim_trace(label: String) -> void:
	if finished:
		return
	var aim: Node = manager.call("throw_aim")
	if phase.begins_with("manual") or (phase == "actual_catch_existing" and
			(bool(manager.call("is_aiming")) or Input.is_action_just_pressed("interact"))):
		_capture(label)

func _capture(label: String) -> void:
	if output == null:
		return
	var data := {"label": label, "phase": phase, "ms": Time.get_ticks_msec(),
		"physics": Engine.get_physics_frames(), "process": Engine.get_process_frames(),
		"releases": releases, "strikes": strikes, "misses": misses}
	if is_instance_valid(manager):
		data.fighting = manager.call("is_fighting")
		data.aiming = manager.call("is_aiming")
		data.outcome = manager.call("outcome")
		var aim: Node = manager.call("throw_aim")
		data.preview = aim.call("aim_report")
		data.committed_point = str(aim.get("_committed_assist_point"))
		data.windup = aim.get("_windup")
		data.guard_positive = float(aim.get("_guard")) > 0.0
		data.guard_precise = "%.20f" % float(aim.get("_guard"))
		data.last_launch = aim.call("last_launch")
		for entry in [["enemy", manager.call("enemy")], ["ally", manager.call("active_creature")]]:
			var creature: RefCounted = entry[1]
			if creature != null:
				data[entry[0]] = {"id": creature.get_instance_id(), "species": creature.get("species_id"),
					"hp": creature.get("hp"), "level": creature.get("level"), "fainted": creature.get("fainted")}
	if is_instance_valid(game):
		data.orbs = game.get("inventory").call("count", "orb_basic")
		data.party_size = game.get("party").call("size")
		data.tool = game.get("equipped_tool")
		data.flags = game.get("progression").call("all_set")
	if is_instance_valid(player):
		data.player_pose = str(player.global_position)
	if is_instance_valid(wild):
		data.wild_pose = str(wild.global_position)
	data.actions = {"interact": Input.is_action_pressed("interact"),
		"interact_edge": Input.is_action_just_pressed("interact"),
		"interact_release": Input.is_action_just_released("interact"),
		"cancel_edge": Input.is_action_just_pressed("menu_cancel"),
		"cancel": Input.is_action_pressed("menu_cancel"), "flee": Input.is_action_pressed("combat_run"),
		"recall": Input.is_action_pressed("creature_recall")}
	output.store_line(JSON.stringify(data))
	output.flush()
	print("REAL_MANAGER ", JSON.stringify(data))

func _finish(ok: bool, reason: String) -> void:
	if finished:
		return
	finished = true
	_capture("terminal:" + reason)
	if is_instance_valid(manual):
		manual.stop()
	if prep != null:
		prep.call("_stop_left_stick")
		prep.call("_stop_right_stick")
	print("REAL_MANAGER_RESULT passed=", ok, " phase=", phase, " reason=", reason)
	if output != null:
		output.close()
	quit(0 if ok else 1)

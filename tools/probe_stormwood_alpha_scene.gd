extends SceneTree

## SYNTHETIC DIAGNOSTIC ONLY. Seeds chapter entitlement/party and places the
## trainer near the actual named Alpha. No earned route or milestone claim.
const ENTRY := preload("res://tests/smoke_stormwood_continuous.gd")
const CROWN := preload("res://tests/helpers/stormwood_crown_build_segment.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

var finished := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_timeout.call_deferred()
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new("user://synthetic_alpha_scene_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]))
	await process_frame
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "synthetic-alpha-diagnostic")
	game.get("world").set("world_id", "synthetic-alpha-diagnostic")
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	for flag: String in ENTRY.COMPLETED_CLOUDREACH_FLAGS:
		game.get("ledger").call("submit", {"kind": "set_world_flag", "realm": "cloudreach", "id": flag, "value": true})
	for id: String in ENTRY.ENTRY_PARTY:
		var creature := SPECIES.spawn(id)
		creature.set_level(44, PROGRESSION.config())
		game.get("party").call("add", creature)
	var source := Node3D.new()
	root.add_child(source)
	current_scene = source
	await process_frame
	if not await game.call("enter_realm", "stormwood", "stormwood_arrival_from_cloudreach"):
		_finish(false, "synthetic router setup refused")
		return
	var world: Node3D
	for _frame in ENTRY.SCENE_WAIT_FRAMES:
		world = current_scene as Node3D
		if world != null and world.name == "Stormwood" \
				and world.call("shell_build_complete") and str(game.get("pending_realm_entry")) == "" \
				and bool(world.get_node("EncounterDirector").get("population_ready")):
			break
		await physics_frame
	if world == null or world.name != "Stormwood" or not world.call("shell_build_complete") \
			or str(game.get("pending_realm_entry")) != "" \
			or not bool(world.get_node("EncounterDirector").get("population_ready")):
		_finish(false, "synthetic Stormwood scene never became ready")
		return
	var helper := CROWN.new()
	helper._tree = self
	helper._game = game
	helper._world = world
	helper._player = world.get_node("Player")
	helper._camera = world.get_node("CameraRig")
	helper._director = world.get_node("EncounterDirector")
	helper._manager = world.get_node("CombatManager")
	helper._arbiter = get_first_node_in_group("interaction_arbiter")
	helper._navigator = NAVIGATOR.new(self, helper._player, helper._camera, helper._drive_stick)
	var alpha := helper._named_wild("capacitor_alpha")
	if alpha == null:
		_finish(false, "actual named Alpha absent")
		return
	# The only position fixture: arrive undeployed near the actual named body.
	# Let production aggression announce naturally, then use ordinary recall.
	var at := alpha.global_position + Vector3(0, 0, -3)
	at.y = float(world.call("ground_height_at", at.x, at.z)) + 0.3
	helper._player.global_position = at
	helper._player.velocity = Vector3.ZERO
	for _frame in 60:
		await physics_frame
	print("SYNTHETIC ALPHA pre-recall ", helper._alpha_admission_snapshot(alpha))
	if not await helper._ensure_usable_ally("synthetic diagnostic healthy control"):
		_finish(false, "ordinary recall/cycle failed")
		return
	helper._manager.exited.connect(helper._on_combat_exited)
	var observed := {"entered": 0}
	helper._manager.entered.connect(func() -> void: observed.entered += 1)
	print("SYNTHETIC ALPHA healthy-control ", helper._alpha_admission_snapshot(alpha))
	# Reuse unchanged ordinary helper admission/fight logic. Even a successful
	# synthetic clear here is diagnostic and cannot replace the earned prefix.
	var cleared: bool = await helper._clear_capacitor_alpha()
	print("SYNTHETIC ALPHA terminal ", {"cleared": cleared, "entered": observed.entered,
		"snapshot": helper._alpha_admission_snapshot(alpha), "failures": helper.failures})
	_finish(cleared, "synthetic diagnostic only; earned campaign unchanged")

func _timeout() -> void:
	await create_timer(300.0, true, false, true).timeout
	if not finished:
		_finish(false, "synthetic admission diagnostic five-minute ceiling")

func _finish(ok: bool, detail: String) -> void:
	if finished:
		return
	finished = true
	print("SYNTHETIC ALPHA SCENE ", "PASS" if ok else "FAIL", ": ", detail)
	quit(0 if ok else 1)

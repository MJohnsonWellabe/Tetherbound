extends SceneTree

## Queue-only F37 proof. Explicit party/L30/deep-water fixtures; real controller
## taps, buoyancy, serialization and host claims. Not an earned campaign run,
## real device, visual judgment or two-peer rejoin proof.
const SCENE := preload("res://scenes/world/water_archipelago.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
var world: Node3D
var game: Node
var failures: Array[String] = []
var finished := false
# Proof endpoints only; no shipping flag, durable state or schema change.
var _surface_only := false
var _surface_capture := false
var _dive_only := false
var _dive_capture := false
var _surface_offload := false
var _surface_deadline := 0
var _surface_observed := {"distance_m": 0.0, "physics_s": 0.0, "currents": [], "captures": []}

func _init() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	print("F37 ", "PASS " if value else "FAIL ", message)
	if not value: failures.append(message)

func frames(count: int) -> void:
	for frame in count: await physics_frame

func tap(action: String) -> void:
	var binding: InputEventJoypadButton
	for candidate: InputEvent in InputMap.action_get_events(action):
		if candidate is InputEventJoypadButton:
			binding = candidate.duplicate() as InputEventJoypadButton
			break
	if binding == null:
		check(false, "physical controller binding exists for " + action)
		return
	await process_frame
	binding.pressed = true
	Input.parse_input_event(binding)
	Input.flush_buffered_events()
	await process_frame
	await frames(2)
	binding = binding.duplicate() as InputEventJoypadButton
	binding.pressed = false
	Input.parse_input_event(binding)
	Input.flush_buffered_events()
	await process_frame
	await frames(3)

func run() -> void:
	_surface_only = OS.get_cmdline_user_args().has("--through-surface")
	_surface_capture = OS.get_cmdline_user_args().has("--capture-surface")
	_dive_only = OS.get_cmdline_user_args().has("--through-dive")
	_dive_capture = OS.get_cmdline_user_args().has("--capture-dive")
	_surface_offload = OS.get_cmdline_user_args().has("--functional-offload")
	if (_surface_only and _dive_only) or (_surface_capture and not _surface_only) \
		or (_dive_capture and not _dive_only) or (_surface_offload and not (_surface_capture or _dive_only)):
		check(false, "capture/offload requires one explicit matching traversal endpoint")
		finish()
		return
	if _surface_offload and not preload("res://tests/helpers/f19_functional_offload.gd").configure("ripplet_dive_driver" if _dive_only else "ripplet_surface_driver"):
		check(false, "surface offload requires the real Compatibility display")
		finish()
		return
	_surface_deadline = Time.get_ticks_msec() + 240000
	create_timer(240).timeout.connect(func() -> void:
		if not finished:
			check(false,"watchdog")
			finish())
	await process_frame
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "f37-ripplet-fixture"
	game.world.world_id = "f37-ripplet-world"
	game.save_system = SAVE.new("user://f37_ripplet_%d" % Time.get_ticks_usec())
	var creature := SPECIES.spawn("ripplet")
	# Surface endpoint retains this existing fixture's default starter level.
	# The original default proof still stages its L30 Dive boundary unchanged.
	if not _surface_only:
		creature.level = 30
		creature.recompute_stats_from_base(preload("res://scripts/creatures/progression.gd").config())
	game.party.add(creature)
	# Serialization returns a normalized COPY; it does not admit a live UID.
	# Keep this pre-admission L30 fixture explicit, including its earlier caps.
	game.local.redesign_character = game.local.save_data().redesign_character
	if not _surface_only:
		game.local.redesign_character.creatures[creature.uid].breakthroughs = [1,2]
		game.local.redesign_character.creatures[creature.uid].cap_level = 30
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	while not world.shell_build_complete(): await process_frame
	var player: CharacterBody3D = world.get_node("Player")
	var camera: Node = world.get_node("CameraRig")
	var director: Node = world.get_node("EncounterDirector")
	var riding: Node = world.get_node("RidingController")
	var swimming: Node = player.swim_controller
	check(game.inventory.count("swim_saddle") == 0 and not game.local.flags.has("water_swim_stone_earned"),"opening has no saddle/Stone")
	check(director.summon_active_creature(),"summon owned Ripplet")
	await frames(30)
	# Fixture seats the trainer within the normal mount prompt's reach.
	var body: CharacterBody3D = director.ally_body()
	player.global_position = body.global_position + Vector3(2,0,0)
	await frames(2)
	await tap("interact")
	await frames(10)
	check(riding.is_mounted(),"ordinary Interact mounts with host authorization")
	if not riding.is_mounted():
		finish()
		return
	if _surface_only:
		await _run_surface(player, camera, director, riding, swimming, creature, body)
		finish()
		return
	body.global_position = Vector3(-215,-0.7,166)
	body.velocity = Vector3.ZERO
	await frames(10)
	check(world.water_depth_at(body.global_position) >= 8.0,"optional dive fixture has clearance")
	check(riding.ride_speed_now() > 3.8,"surface speed exceeds human")
	var before := body.global_position
	camera.set("yaw",0.0)
	Input.action_press("move_forward")
	await frames(120)
	Input.action_release("move_forward")
	check(body.global_position.distance_to(before) > 8.0,"ordinary input drives surface displacement")
	await tap("jump")
	check(not riding.diving,"level without L30 feast cannot Dive")
	# Explicit admitted breakthrough fixture. Real feast proof is F28 dependency.
	game.local.redesign_character.creatures[creature.uid].breakthroughs = [1,2,3]
	game.local.redesign_character.creatures[creature.uid].cap_level = 40
	await tap("jump")
	await frames(30)
	check(riding.diving,"tap Jump starts unlocked Dive")
	check(body.global_position.y < -4.5,"production buoyancy submerges carrier")
	if _dive_only:
		await _run_dive(player, director, riding, creature, body)
		finish()
		return
	var aquatic: Dictionary = swimming.save_data()
	check(aquatic.mount.creature_uid == creature.uid,"save binds stable UID")
	check(aquatic.mount.dive.remaining_s < 20.0,"save captures spent dive timer")
	var clean: Dictionary = preload("res://scripts/save/water_traversal_save.gd").sanitise(DOCUMENT.parse(DOCUMENT.stringify(aquatic)))
	check(clean.get("mount", {}).get("dive", {}).get("remaining_s") == aquatic.mount.dive.remaining_s,"production save codec preserves exact remaining dive debt")
	await tap("jump")
	await frames(30)
	check(not riding.diving and body.global_position.y > -1.0,"tap surfaces without held input")
	check(is_equal_approx(creature.swim_stamina_fraction,float(world.get_node("MountedSwimming").state.stamina_fraction)),"stamina remains on owned creature")
	# Reuse the original saved aquatic payload. A newer unmounted load must
	# supersede its queued reconstruction before any deferred body work runs.
	check(swimming.restore_save_data(clean), "saved owned UID queues production reconstruction")
	var unmounted := clean.duplicate(true)
	unmounted.erase("mount")
	unmounted.mode = 1
	check(swimming.restore_save_data(unmounted), "newer unmounted pose supersedes queued mount")
	for frame in 4: await process_frame
	check(swimming.get("_pending_mount").is_empty() and not riding.is_mounted() and not player.is_carried(),
		"superseded reconstruction never reattaches its old carrier")
	check(game.party.size() == 1 and game.party.at(0).uid == creature.uid,
		"supersession preserves the original owned UID without another creature")
	check(swimming.restore_save_data(clean), "current saved owned UID still reconstructs normally")
	for frame in 120:
		await physics_frame
		if swimming.get("_pending_mount").is_empty(): break
	check(riding.is_mounted() and director.ally_instance() == creature and riding.mount_body() != null,
		"current reconstruction seats the same owned individual")
	check(riding.dive_save().get("remaining_s") == clean.mount.dive.remaining_s,
		"current reconstruction preserves the original remaining Dive debt")
	finish()

func _run_surface(player: CharacterBody3D, camera: Node3D, director: Node, riding: Node,
		swimming: Node, creature: RefCounted, body: CharacterBody3D) -> void:
	var route: Dictionary = {}
	for candidate: Dictionary in world.config.get("water_routes", []):
		if candidate.get("id") == "first_shore_to_lantern_cove_direct": route = candidate
	check(not route.is_empty() and str(route.get("required_departure_flag", "")).is_empty() \
		and route.get("required_equipment", []).is_empty(), "opening Lantern crossing is authored and ungated")
	if not failures.is_empty(): return
	var departure := Vector3.INF
	var arrival := Vector3.INF
	for anchor: Dictionary in world.config.anchors:
		var at: Array = anchor.safe_position
		if anchor.id == route.from_anchor: departure = Vector3(float(at[0]), float(at[1]), float(at[2]))
		if anchor.id == route.to_anchor: arrival = Vector3(float(at[0]), float(at[1]), float(at[2]))
	check(departure.is_finite() and arrival.is_finite(), "both actual dry Lantern anchors resolve")
	if not failures.is_empty(): return
	var uid := str(creature.uid)
	var level_before := int(creature.level)
	var cap_before: Dictionary = game.local.redesign_character.creatures[uid].duplicate(true)
	var navigator := preload("res://tests/helpers/stick_navigator.gd").new(self, body, camera, _surface_stick)
	if not await _surface_move(departure, navigator, player, director, riding, creature, body): return
	check(body.is_on_floor() and not swimming.is_swimming(), "ordinary riding reaches the actual dry departure")
	if not failures.is_empty(): return
	# Cross the actual opening edge. No position, current,
	# unlock, clock, resource, camera or ownership writes follow initial setup.
	if not await _surface_move(arrival, navigator, player, director, riding, creature, body, 0): return
	check(body.is_on_floor() and not swimming.is_swimming(), "ordinary mounted crossing reaches its real dry shore")
	var human_speed := float((swimming.get("_config") as Dictionary).human.speed_m_s)
	var measured_speed := float(_surface_observed.distance_m) / maxf(0.000001, float(_surface_observed.physics_s))
	check(float(_surface_observed.physics_s) > 0.0 and measured_speed > human_speed,
		"actual voluntary surface motion exceeds configured human swimming speed")
	check(not _surface_observed.currents.is_empty(), "actual mounted movement crosses nonsealed Lantern currents")
	check(not _surface_capture or not _surface_observed.captures.is_empty(), "requested surface capture observes the actual current crossing")
	check(int(creature.level) == level_before and game.local.redesign_character.creatures[uid] == cap_before,
		"surface riding keeps the starter's original level and breakthrough record")
	check(game.inventory.count("swim_saddle") == 0 and not game.local.flags.has("water_swim_stone_earned"),
		"opening current crossing needs neither saddle nor Swim Stone")
	print("F37 SURFACE ENDPOINT " + JSON.stringify({"passed": failures.is_empty(), "owned_uid": uid,
		"starter_level": level_before, "route": route.id, "observed": _surface_observed,
		"measured_speed_m_s": measured_speed, "human_speed_m_s": human_speed,
		"setup": "existing owned starter and initial prompt-reach fixture; no L30/Dive staging",
		"earned_campaign": false, "dive_or_rejoin_proof": false}))

func _surface_bound(player: CharacterBody3D, director: Node, riding: Node, creature: RefCounted,
		body: CharacterBody3D, allow_dive: bool = false) -> bool:
	return not finished and current_scene == world and not paused and is_instance_valid(body) \
		and game.party.size() == 1 and game.party.at(0) == creature \
		and director.ally_instance() == creature and director.ally_body() == body \
		and riding.is_mounted() and riding.mount_body() == body and player.get("_carrier") == body \
		and (allow_dive or not riding.diving) and not director.trainer_battle_active() \
		and not world.get_node("CombatManager").is_fighting() \
		and preload("res://scripts/ui/input_owner.gd").current(self) == null

func _surface_move(target: Vector3, navigator: RefCounted, player: CharacterBody3D, director: Node,
		riding: Node, creature: RefCounted, body: CharacterBody3D, crossing: int = -1) -> bool:
	var captured := false
	var water: Node = world.get_node("MountedSwimming")
	var human_speed := float((player.swim_controller.get("_config") as Dictionary).human.speed_m_s)
	while not finished and Time.get_ticks_msec() < _surface_deadline:
		if not _surface_bound(player, director, riding, creature, body):
			check(false, "surface movement retains its actual owner, carrier and free input")
			_surface_stick(0, 0)
			return false
		var offset: Vector3 = target - body.global_position
		offset.y = 0
		if offset.length() <= 1.0:
			_surface_stick(0, 0)
			await frames(8)
			var settled: bool = _surface_bound(player, director, riding, creature, body)
			check(settled, "surface shore settling retains its actual owner, carrier and free input")
			return settled
		var direction := offset.normalized()
		var before := body.global_position
		var sample: Dictionary = world.currents.sample(before)
		var in_water: bool = water.state.mode == preload("res://scripts/player/swim_state.gd").Mode.MOUNTED \
			and player.swim_controller.state.mode == preload("res://scripts/player/swim_state.gd").Mode.MOUNTED
		navigator.call("push_once", direction)
		await physics_frame
		if not _surface_bound(player, director, riding, creature, body):
			check(false, "surface physics retains its actual owner, carrier and free input")
			_surface_stick(0, 0)
			return false
		var step: Vector3 = body.global_position - before
		step.y = 0
		if not step.is_finite() or step.length() > 3.0:
			check(false, "ordinary riding has no teleport-sized movement sample")
			_surface_stick(0, 0)
			return false
		if crossing >= 0 and in_water and water.state.mode == preload("res://scripts/player/swim_state.gd").Mode.MOUNTED \
			and player.swim_controller.state.mode == preload("res://scripts/player/swim_state.gd").Mode.MOUNTED and step.dot(direction) > 0.001:
			if riding.ride_speed_now() <= human_speed:
				check(false, "live Ripplet surface speed exceeds human speed")
				_surface_stick(0, 0)
				return false
			var delta: float = body.get_physics_process_delta_time()
			var voluntary: Vector3 = step - world.current_at(before) * float(preload("res://scripts/player/ripplet_traversal.gd").config().current_multiplier) * delta
			_surface_observed.distance_m += voluntary.dot(direction)
			_surface_observed.physics_s += delta
			var flow: Vector3 = sample.get("velocity", Vector3.ZERO)
			var current_id := str(sample.get("id", ""))
			if not sample.has("seal") and current_id.begins_with("first_shore_to_lantern_cove_") and flow.length() > 0.001:
				if not _surface_observed.currents.has(current_id): _surface_observed.currents.append(current_id)
				if _surface_capture and not captured and offset.length() < 80.0 and offset.length() > 30.0:
					_surface_stick(0, 0)
					var ready := func() -> bool:
						return _surface_bound(player, director, riding, creature, body) and body.is_visible_in_tree() \
							and water.state.mode == preload("res://scripts/player/swim_state.gd").Mode.MOUNTED
					var drawing_before := RenderingServer.render_loop_enabled
					RenderingServer.render_loop_enabled = true
					var actual: bool = await preload("res://tests/helpers/f20_ending_probe.gd").new().capture(self,
						"ripplet-surface-current-%d" % crossing, ready)
					RenderingServer.render_loop_enabled = drawing_before
					check(actual, "actual Low surface frame retains the owned rider and carrier")
					if not actual: return false
					_surface_observed.captures.append(Time.get_ticks_msec())
					captured = true
	_surface_stick(0, 0)
	check(false, "ordinary surface route stays inside the original 240-second watchdog")
	return false

func _surface_stick(x: float, y: float) -> void:
	for axis: int in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run_dive(player: CharacterBody3D, director: Node, riding: Node, creature: RefCounted,
		body: CharacterBody3D) -> void:
	var adapter := preload("res://tools/net/proof_steps_f37.gd")
	check(not _dive_capture or preload("res://scripts/player/ripplet_traversal.gd").config().presentation_enabled,
		"requested Dive capture requires installed cache and node presentation")
	if not failures.is_empty(): return
	for request: Array in [["f37_sunken_claim", {"site_id":"lantern_arch_cache"}],
		["f37_sunken_claim", {"site_id":"lantern_pearl_bed"}], ["f37_hidden_route", {}]]:
		var result: Dictionary = await adapter.step(self, str(request[0]), request[1])
		print("F37 DIVE CONTENT " + JSON.stringify({"action":request[0], "args":request[1], "result":result}))
		check(result.get("verdict") == "PASS" and _dive_bound(player, director, riding, creature, body),
			"existing physical claim/optional-route step retains the actual owned Dive")
		if not failures.is_empty(): return
	# Complete the three ordinary content actions inside the host's real Dive
	# allowance before requesting a slow hosted draw. Never refresh that timer.
	if _dive_capture:
		var ready := func() -> bool:
			return _dive_bound(player, director, riding, creature, body) and body.is_visible_in_tree()
		var drawing_before := RenderingServer.render_loop_enabled
		RenderingServer.render_loop_enabled = true
		var captured: bool = await preload("res://tests/helpers/f20_ending_probe.gd").new().capture(self,
			"ripplet-dive-completed-finds-and-route", ready)
		RenderingServer.render_loop_enabled = drawing_before
		check(captured, "actual Low Dive content frame retains the owned mount")
		if not captured: return
	print("F37 DIVE ENDPOINT " + JSON.stringify({"passed":failures.is_empty(), "owned_uid":creature.uid,
		"level":creature.level, "breakthroughs":game.local.redesign_character.creatures[creature.uid].breakthroughs,
		"setup":"existing owned L30/breakthrough and deep-water fixtures; physical content steps only",
		"earned_campaign":false, "rejoin_proof":false}))

func _dive_bound(player: CharacterBody3D, director: Node, riding: Node, creature: RefCounted,
		body: CharacterBody3D) -> bool:
	return _surface_bound(player, director, riding, creature, body, true) and riding.diving \
		and world.get_node("MountedSwimming").state.mode == preload("res://scripts/player/swim_state.gd").Mode.MOUNTED \
		and player.swim_controller.state.mode == preload("res://scripts/player/swim_state.gd").Mode.MOUNTED \
		and body.global_position.y < -4.0

## Existing physical F37 steps require these two runner hooks. They retain
## each supplied frame budget/tolerance and never stage position or Dive time.
func _step_move_to(args: Dictionary) -> Dictionary:
	var player: CharacterBody3D = world.get_node("Player")
	var director: Node = world.get_node("EncounterDirector")
	var riding: Node = world.get_node("RidingController")
	var creature: RefCounted = director.ally_instance()
	var body: CharacterBody3D = director.ally_body()
	var target := Vector3(float(args.get("x", NAN)), 0, float(args.get("z", NAN)))
	var budget := int(args.get("budget_frames", 0))
	var tolerance := float(args.get("close_enough", 0))
	if not target.is_finite() or budget <= 0 or tolerance <= 0:
		return {"verdict":"FAIL", "detail":"existing Dive step requires finite target and its positive budget/tolerance"}
	var navigator := preload("res://tests/helpers/stick_navigator.gd").new(self, body, world.get_node("CameraRig"), _surface_stick)
	for frame in budget:
		if Time.get_ticks_msec() >= _surface_deadline or not _dive_bound(player, director, riding, creature, body):
			_surface_stick(0, 0)
			return {"verdict":"FAIL", "detail":"ordinary content movement lost its owned Dive or original watchdog"}
		var offset: Vector3 = target - body.global_position
		offset.y = 0
		if offset.length() <= tolerance:
			_surface_stick(0, 0)
			return {"verdict":"PASS", "detail":"ordinary mapped owned Dive reached the existing content target"}
		navigator.push_once(offset.normalized())
		await physics_frame
		if not _dive_bound(player, director, riding, creature, body):
			_surface_stick(0, 0)
			return {"verdict":"FAIL", "detail":"content movement's physics lost the actual owned Dive"}
	_surface_stick(0, 0)
	return {"verdict":"FAIL", "detail":"ordinary content movement exhausted its existing step frame budget"}

func _press_edge(action: String, pressed: bool) -> Dictionary:
	for candidate: InputEvent in InputMap.action_get_events(action):
		if candidate is InputEventJoypadButton:
			var event := candidate.duplicate() as InputEventJoypadButton
			event.device = 0
			event.pressed = pressed
			Input.parse_input_event(event)
			Input.flush_buffered_events()
			return {"ok":true}
	return {"ok":false, "reason":"existing physical Dive step lacks mapped controller binding"}

func finish() -> void:
	if finished: return
	finished = true
	_surface_stick(0, 0)
	Input.action_release("move_forward")
	print("F37 RIPPLET FIXTURE ","PASS" if failures.is_empty() else "FAIL", " ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

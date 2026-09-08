extends "res://tests/helpers/stormwood_earned_rootgate_segment.gd"

## Earned live continuation only. Stops at physical core arrival before Marrow.
const ENTRY_FLAGS := [ROOTGATE, ACT_II, TRUTH, GUARDIAN_CLEAR,
	"stormwood:rod_verge_disabled", "stormwood:rod_hollows_disabled"]
const CORE := "stormwood:core_reached"
# Same whole-ramp contract as smoke_stormheart_ascent.gd, whose default
# physics clock is 60Hz. The synthetic walker itself is never instantiated.
const ASCENT_FRAMES := 6000
const ASCENT_SCALE := 4.0
const ASCENT_HZ := 60
const CORE_TOLERANCE := 3.5
const TRAINERS := ["officer_nysa_deepwood_rod", "outerworks_lieutenant_sera",
	"officer_kestrel_outer_works"]
var _outcomes: Dictionary = {}

static func missing_entry_flags(flags: RefCounted) -> Array[String]:
	var missing: Array[String] = []
	for flag: String in ENTRY_FLAGS:
		if flags == null or not flags.call("has", flag):
			missing.append(flag)
	return missing

func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.get("current_realm")) != "stormwood":
		_fail("Dynamo continuation requires the retained live Stormwood scene")
		return result()
	if not missing_entry_flags(game.get("progression")).is_empty() or _has(CORE):
		_fail("Dynamo entry requires earned Rootgate and both earlier rod switches, before core")
		return result()
	_player = world.get_node_or_null("Player")
	_camera = world.get_node_or_null("CameraRig")
	_manager = world.get_node_or_null("CombatManager")
	_director = world.get_node_or_null("EncounterDirector")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	var session := game.get_node_or_null("Session")
	_party_before = _roster_ids()
	if _player == null or _camera == null or _manager == null or _director == null \
			or _arbiter == null or session == null or _party_before.size() != 5:
		_fail("Dynamo continuation needs live controllers and the retained five creatures")
		return result()
	_navigator = NAVIGATOR.new(tree, _player, _camera, _drive_stick)
	_manager.exited.connect(_on_combat_exited)
	session.stormwood_encounter_message.connect(_observe_trainer)
	await _continue_deepwood()
	session.stormwood_encounter_message.disconnect(_observe_trainer)
	_manager.exited.disconnect(_on_combat_exited)
	return result()

func _continue_deepwood() -> void:
	if not await _return_paid_arch():
		return
	for point in [Vector2(-650, 3550), Vector2(-450, 3960)]:
		if not await _walk_xz(point, "released Rootgate road to Lantern Hollow"):
			return
	if not await _receipt("stormwood:lantern_hollow_reached"):
		return
	var sable := _world.get_node_or_null("StormwoodPeople/Sable") as Node3D
	var prompt := sable.get_node_or_null("Interactable") as Node3D if sable != null else null
	if sable == null or prompt == null:
		_fail("Lantern Hollow is missing Sable's actual conversation prompt")
		return
	var approach := Vector2(sable.global_position.x, sable.global_position.z - 2.5)
	if not await _activate_exact(sable, prompt, approach, "Sable captive truth") \
			or not await _dialogue("Sable") or not await _receipt("stormwood:captive_truth_learned"):
		return
	if not await _walk_xz(Vector2(-890, 4490), "Deepwood station") \
			or not await _trainer(TRAINERS[0]) or not await _rod("deepwood_rod_station") \
			or not await _receipt("stormwood:deepwood_station_disabled"):
		return
	for point in [Vector2(-150, 4460), Vector2(-310, 5050), Vector2(-100, 5350)]:
		if not await _walk_xz(point, "Deepwood road to Dynamo approach"):
			return
	if not await _trainer(TRAINERS[1]) or not await _rod("dynamo_approach_rod_station") \
			or not await _receipt("stormwood:all_rods_disabled"):
		return
	if not await _walk_xz(Vector2(-120, 5270), "Ember Bivouac arrival") \
			or not await _receipt("stormwood:ember_bivouac_reached") \
			or not await _trainer(TRAINERS[2]) or not await _receipt("stormwood:kestrel_defeated"):
		return
	if not await _climb_core() or not await _receipt(CORE):
		return
	if _roster_ids() != _party_before or _tree.current_scene != _world:
		_fail("Dynamo arrival replaced the retained party or world")
		return
	_complete = true
	_note("EARNED Deepwood truth, both remaining rod switches, Kestrel and physical Dynamo core arrival")

func _return_paid_arch() -> bool:
	var arches := _world.get_node_or_null("StormglassArches")
	var rows: Dictionary = arches.get("_arches") if arches != null else {}
	var record := paid_crown_record(_game.get("placed_buildings"))
	var origin: Node3D = (rows.get("e_crown", {}) as Dictionary).get("node")
	var destination: Node3D = (rows.get(str(record.get("uid", "")), {}) as Dictionary).get("node")
	if not is_instance_valid(origin) or not is_instance_valid(destination):
		return _fail("earned Crown return requires both actual paid passage bodies")
	for point in [Vector2(805, 2545), Vector2(590, 2540)]:
		if not await _walk_xz(point, "Crown return ring"):
			return false
	var outside := origin.to_global(Vector3(0, 0, -5))
	if not await _walk_xz(Vector2(outside.x, outside.z), "outside Crown return passage"):
		return false
	_navigator.reset()
	for _frame in 1800:
		if _player.global_position.distance_to(destination.global_position) < 12.0:
			_drive_stick(0, 0)
			return true
		if _manager.is_fighting():
			if not await _fight_current("Crown return passage"):
				return false
		elif _navigator.can_walk():
			await _navigator.step(origin.to_global(Vector3(0, 0, 3.5)))
		else:
			await _tree.physics_frame
	_drive_stick(0, 0)
	return _fail("ordinary Crown passage did not return to the actual paid twin")

func _dialogue(label: String) -> bool:
	var panel := _world.get_node("DialoguePanel")
	for _frame in 180:
		if panel.is_open():
			break
		await _tree.physics_frame
	if not panel.is_open():
		return _fail(label + " exact interaction did not open dialogue")
	for _line in 64:
		if not panel.is_open():
			return true
		await _tap(&"interact")
	return _fail(label + " dialogue did not close within its input bound")

func _trainer(id: String) -> bool:
	var cast := _world.get_node("StormwoodTrainers")
	var spec: Dictionary = cast.get("authored_specs").get(id, {})
	var body := cast.call("body_for", id) as Node3D
	var prompt := body.call("prompt_node") as Node3D if body != null else null
	if spec.is_empty() or body == null or prompt == null:
		return _fail(id + " actual trainer is absent")
	if not await _ensure_usable_ally(id):
		return false
	if not _director.call("can_challenge", spec):
		return _fail(id + " requires an unmet earned prerequisite or usable ally")
	if not await _activate_exact(body, prompt,
			Vector2(body.global_position.x, body.global_position.z - 2), id) or not await _dialogue(id):
		return false
	for _frame in 600:
		if _director.trainer_battle_active():
			break
		await _tree.physics_frame
	if not _director.trainer_battle_active():
		return _fail(id + " dialogue did not start actual hosted combat")
	# One wall-clock bounded driver spans all actual roster rounds; no nested
	# fight wait can outlive this five-minute sequence cap.
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	var started := Time.get_ticks_msec()
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	var next_quick := 0
	var tick := 0
	var release_tick := -1
	while _director.trainer_battle_active() and Time.get_ticks_msec() - started < 300000:
		_drive_stick(0, 0)
		if release_tick >= 0 and tick >= release_tick:
			_set_action(&"combat_quick", false)
			release_tick = -1
		var enemy := _manager.call("enemy_body") as Node3D
		var ally := _director.call("ally_body") as Node3D
		if _manager.is_fighting() and enemy != null and ally != null:
			var offset := enemy.global_position - ally.global_position
			offset.y = 0
			if offset.length() > float(_manager.combat_move_reach("quick")) * 0.8:
				var local := (_camera.call("planar_basis") as Basis).inverse() * offset.normalized()
				_drive_stick(local.x, local.z)
			if Time.get_ticks_msec() >= next_quick and _manager.quick_ready():
				_set_action(&"combat_quick", true)
				release_tick = tick + 2
				next_quick = Time.get_ticks_msec() + 900
		tick += 1
		await _tree.physics_frame
	_set_action(&"combat_quick", false)
	_drive_stick(0, 0)
	await _tree.process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before
	if Time.get_ticks_msec() - started >= 300000 or _director.trainer_battle_active() \
			or not bool(_outcomes.get(id, false)):
		return _fail(id + " did not publish its actual hosted victory within five minutes")
	return await _receipt(str(spec.get("defeat_flag", "")))

func _observe_trainer(event: Dictionary) -> void:
	if str(event.get("kind", "")) == "finished":
		_outcomes[str(event.get("trainer_id", ""))] = bool(event.get("won", false))

func _rod(id: String) -> bool:
	var owner := _world.get_node("StormwoodRodStations")
	var spec: Dictionary = {}
	for row: Dictionary in owner.get("stations"):
		if str(row.id) == id:
			spec = row
	var station := owner.get_node_or_null(NodePath(id)) as Node3D
	var prompt := station.get_node_or_null("RodSwitch") as Node3D if station != null else null
	if spec.is_empty() or prompt == null or not _has(str(spec.guard_defeat_flag)):
		return _fail(id + " is missing its actual switch or earned guard victory")
	if not await _activate_exact(station, prompt,
			Vector2(prompt.global_position.x, prompt.global_position.z - 1.8), id):
		return false
	return await _receipt(str(spec.disabled_flag))

func _climb_core() -> bool:
	var trunk := _world.get_node_or_null("StormheartTree") as Node3D
	if trunk == null:
		return _fail("actual Stormheart ascent absent")
	if not await _walk_xz(Vector2(-100, 5350), "Stormheart approach foot"):
		return false
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = ASCENT_SCALE
	Engine.physics_ticks_per_second = ASCENT_HZ
	await _tree.process_frame
	var passed := await _walk_actual_ascent(trunk)
	_drive_stick(0, 0)
	await _tree.process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before
	return passed

func _walk_actual_ascent(trunk: Node3D) -> bool:
	var started := Engine.get_physics_frames()
	var approach := trunk.to_global(Vector3(0, 6, -40))
	# Enter through the open rail ends. The ring approach is outside the
	# helix's outer rail; a diagonal directly to lookahead crosses that rail.
	var mouth := trunk.to_global(Vector3(-4, 6, -26))
	var ramp_start := trunk.to_global(trunk.call("ascent_point", 0.0))
	var stage := 0
	var last_progress := 0.0
	var furthest := 0.0
	_navigator.reset()
	while Engine.get_physics_frames() - started < ASCENT_FRAMES:
		if _manager.is_fighting() or _director.trainer_battle_active():
			return _fail("unexpected combat blocks the bounded physical Stormheart ascent")
		if stage == 0 and _player.global_position.distance_to(approach) < CORE_TOLERANCE:
			stage = 1
			_navigator.reset()
		if stage == 1 and _player.global_position.distance_to(mouth) < 0.8:
			stage = 2
			_navigator.reset()
		if stage == 2 and _player.global_position.distance_to(ramp_start) < 0.8:
			stage = 3
			_navigator.reset()
		var progress := clampf((_player.global_position.y - (trunk.global_position.y + 6.0)) / 144.0, 0, 1)
		furthest = maxf(furthest, progress)
		if stage == 3 and furthest >= 0.998 and _player.is_on_floor() \
				and _player.global_position.distance_to(trunk.call("core_anchor")) <= CORE_TOLERANCE:
			return true
		# Same continuous look-ahead as the actual ascent smoke. Fixed widely
		# spaced turns can reject a valid sloped foot position or cut the helix.
		var fraction := minf(1.0, maxf(progress + 0.008, last_progress + 0.002))
		var target := approach
		match stage:
			1: target = mouth
			2: target = ramp_start
			3: target = trunk.to_global(trunk.call("ascent_point", fraction))
		last_progress = maxf(last_progress, progress)
		if _navigator.can_walk():
			await _navigator.step(target)
		else:
			await _tree.physics_frame
	return _fail("physical Stormheart ascent exceeded its shared 6000-frame budget at " + str(_player.global_position))

func _receipt(flag: String) -> bool:
	if flag.is_empty() or not await _wait_flag(flag, 300):
		return _fail("ordinary action did not earn " + flag)
	_note("EARNED " + flag)
	return true

func result() -> Dictionary:
	return {"passed": _complete and failures.is_empty(), "failures": failures.duplicate(),
		"transcript": transcript.duplicate(), "endpoint": "earned physical Dynamo core, before Marrow"}

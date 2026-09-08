extends "res://tests/helpers/stormwood_earned_dynamo_segment.gd"

## Earned release -> voluntary pending-newcomer farewell -> Spark -> physical
## Waterward gate. No entry fixture or Water opening is executed here.
const RELEASE_FLAGS := ["stormwood:marrow_defeated", "stormwood:legendary_freed",
	"realm_heart_stormwood_earned", "stormwood:long_storm_ended"]
const OFFERED := "stormwood:legendary_offer_made"
const SETTLED := "stormwood:legendary_ceremony_settled"
const WATER_KEY := "realm_key_water"
const WATER_UNLOCK := "realm_gate_water_unlocked"
const ENTRY_WAIT_FRAMES := 7200
const CEREMONY_FRAMES := 60
var _finished_dialogues: Array[String] = []
var _arrived_world: Node3D
var _water_population_seen := false
var _water_director: Node
var _gate_activations := 0
var _gate_prompt_id := 0
var _panel: Node

static func same_five(before: Array[int], after: Array[int]) -> bool:
	if before.size() != 5 or before != after:
		return false
	var unique: Dictionary = {}
	for id in before:
		if id == 0 or unique.has(id):
			return false
		unique[id] = true
	return true

func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.get("current_realm")) != "stormwood":
		_fail("Waterward handoff requires the retained earned Stormwood scene")
		return result()
	for flag: String in RELEASE_FLAGS:
		if not _has(flag):
			_fail("Waterward handoff lacks earned " + flag)
			return result()
	if _has(OFFERED) or _has(WATER_UNLOCK) or game.get("pending_catch") != null:
		_fail("Waterward entry must precede the actual Stormheart offer and gate")
		return result()
	_player = world.get_node_or_null("Player")
	_camera = world.get_node_or_null("CameraRig")
	_manager = world.get_node_or_null("CombatManager")
	_director = world.get_node_or_null("EncounterDirector")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	_panel = world.get_node_or_null("DialoguePanel")
	_party_before = _roster_ids()
	if _player == null or _camera == null or _manager == null or _director == null \
			or _arbiter == null or _panel == null or _party_before.size() != 5:
		_fail("Waterward handoff lacks actual controllers or the retained five")
		return result()
	_navigator = NAVIGATOR.new(tree, _player, _camera, _drive_stick)
	_manager.exited.connect(_on_combat_exited)
	_panel.finished.connect(_dialogue_finished)
	await _continue_waterward()
	_disconnect_source()
	if is_instance_valid(_arbiter) and _arbiter.activated.is_connected(_watch_gate_activation):
		_arbiter.activated.disconnect(_watch_gate_activation)
	if tree.node_added.is_connected(_watch_arrival_node):
		tree.node_added.disconnect(_watch_arrival_node)
	if is_instance_valid(_water_director) and _water_director.population_ready.is_connected(_water_population_ready):
		_water_director.population_ready.disconnect(_water_population_ready)
	return result()

func _continue_waterward() -> void:
	if not await _drain_exact("stormwood_stormheart_release"):
		return
	var ending := _world.get_node_or_null("StormwoodEnding") as Node3D
	var offer := ending.get_node_or_null("StormheartOffer") as Node3D if ending != null else null
	if offer == null or not await _core_south_ring() or not await _activate_exact(ending, offer,
			Vector2(offer.global_position.x, offer.global_position.z + 2), "Stormheart offer") \
			or not await _drain_exact("stormwood_stormheart_offer") \
			or not await _decline_pending_stormheart():
		return
	if not await _receipt(OFFERED) or not bool(_game.call("player_flags").call("has", SETTLED)):
		_fail("actual Stormheart farewell lacks its saved personal/world settlement")
		return
	if not await _descend_core():
		return
	for point in [Vector2(-310, 5050), Vector2(-150, 4460), Vector2(-450, 3960)]:
		if not await _walk_xz(point, "earned Spark return to Lantern Hollow"):
			return
	var shrine := _world.get_node_or_null("SparkOfStormwoodShrine") as Node3D
	var prompt := shrine.get_node_or_null("Interactable") as Node3D if shrine != null else null
	if shrine == null or prompt == null or not await _activate_exact(shrine, prompt,
			Vector2(prompt.global_position.x, prompt.global_position.z - 2), "Place earned Spark") \
			or not await _receipt("realm_heart_stormwood_placed") or not await _receipt("stormwood:spark_placed"):
		return
	for point in [Vector2(-150, 4460), Vector2(-310, 5050), Vector2(-100, 5350)]:
		if not await _walk_xz(point, "return to the cleared high platform"):
			return
	if not await _climb_core():
		return
	var view := ending.get_node_or_null("WaterwardView") as Node3D
	if view == null or not await _core_south_ring() or not await _activate_exact(ending, view,
			Vector2(view.global_position.x, view.global_position.z + 2), "Waterward view") \
			or not await _drain_exact("stormwood_waterward_aftermath"):
		return
	for flag in ["stormwood:waterward_revealed", WATER_KEY, "waterward_route_revealed", "stormwood:chapter_complete"]:
		if not await _receipt(flag):
			return
	await _cross_water_gate()

func _dialogue_finished(id: String) -> void:
	_finished_dialogues.append(id)

func _drain_exact(id: String) -> bool:
	for _frame in 180:
		if _panel.is_open() or _finished_dialogues.has(id):
			break
		await _tree.process_frame
	if _finished_dialogues.has(id):
		return true
	if not _panel.is_open() or str(_panel.get("_runner").call("conversation_id")) != id:
		return _fail("expected actual dialogue did not open: " + id)
	for _line in 64:
		if _finished_dialogues.has(id):
			return true
		if not _panel.is_open() or str(_panel.get("_runner").call("conversation_id")) != id:
			return _fail("expected dialogue changed before its finished signal: " + id)
		await _tap(&"interact")
	return _fail("actual dialogue exceeded its existing input bound: " + id)

func _decline_pending_stormheart() -> bool:
	var menu: Node = _game.call("menu")
	var pending: RefCounted = _game.get("pending_catch")
	if pending == null or str(pending.get("species_id")) != "fulgocobra" \
			or int(pending.get("level")) != 44 or _party_before.has(pending.get_instance_id()) or menu == null:
		return _fail("actual offered Stormheart is not the distinct level44 pending newcomer")
	var tab: Node
	for index in (menu.get("_tabs") as Array).size():
		if str(menu.get("_tabs")[index].get("id", "")) == "creatures":
			tab = menu.get("_bodies")[index]
	if tab == null:
		return _fail("actual offer ceremony has no creatures tab")
	for _frame in CEREMONY_FRAMES:
		if menu.is_open() and str(tab.get("_release_stage")) == "choose":
			break
		await _tree.process_frame
	if not menu.is_open() or str(tab.get("_release_stage")) != "choose" \
			or _tree.root.gui_get_focus_owner() != tab.get("_pending_button") \
			or not same_five(_party_before, _roster_ids()):
		return _fail("actual ceremony did not focus the pending Stormheart beside the same five")
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "confirm" or int(tab.get("_release_target")) != 5 \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_keep") or _game.get("pending_catch") != pending:
		return _fail("farewell must target only the pending newcomer with Keep as default")
	await _gui_tap("ui_down")
	if _tree.root.gui_get_focus_owner() != tab.get("_farewell_release"):
		return _fail("ordinary Down did not focus Let them go")
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "done" or _game.get("pending_catch") != null \
			or not same_five(_party_before, _roster_ids()) or _tree.root.gui_get_focus_owner() != tab.get("_farewell_done"):
		return _fail("declining the Stormheart changed the five or left pending state")
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "":
		return _fail("Back to belt did not close the farewell")
	await _gui_tap("menu_cancel")
	return (not menu.is_open() and not _tree.paused and _tree.current_scene == _world) \
		or _fail("the actual farewell did not return world control")

func _gui_tap(action: String) -> void:
	_set_action(action, true)
	for _frame in 3:
		await _tree.process_frame
	_set_action(action, false)
	for _frame in 5:
		await _tree.process_frame

func _disconnect_source() -> void:
	if is_instance_valid(_manager) and _manager.exited.is_connected(_on_combat_exited):
		_manager.exited.disconnect(_on_combat_exited)
	if is_instance_valid(_panel) and _panel.finished.is_connected(_dialogue_finished):
		_panel.finished.disconnect(_dialogue_finished)

func _cross_water_gate() -> void:
	var gate := _world.get_node_or_null("WaterwardRealmGate") as Node3D
	var prompt := gate.get_node_or_null("Interactable") as Node3D if gate != null else null
	if gate == null or prompt == null or str(gate.get("destination_realm")) != "water" \
			or str(gate.get("destination_entry_id")) != "water_arrival_from_stormwood":
		_fail("actual Waterward gate/First Shore destination absent")
		return
	if not await _walk_xz(Vector2(prompt.global_position.x, prompt.global_position.z - 2), "actual Waterward gate"):
		return
	_drive_stick(0, 0)
	_gate_prompt_id = prompt.get_instance_id()
	_arbiter.activated.connect(_watch_gate_activation)
	_tree.node_added.connect(_watch_arrival_node)
	var source_id := _world.get_instance_id()
	for press in 2:
		await _tree.process_frame
		if _arbiter.winning_provider() != prompt or not bool(_arbiter.winner().get("actionable", false)) \
				or not _arbiter.enabled() or INPUT_OWNER.current(_tree) != null:
			_fail("actual Waterward gate does not own the exact actionable input")
			return
		if press == 1:
			_disconnect_source()
		await _tap(&"interact")
		if _gate_activations != press + 1:
			_fail("ordinary Interact did not activate the exact Waterward gate once")
			return
		if press == 0 and (not _has(WATER_UNLOCK) or _has(WATER_KEY)):
			_fail("first Waterward input did not atomically consume key and persist gate unlock")
			return
	if is_instance_valid(_arbiter):
		_arbiter.activated.disconnect(_watch_gate_activation)
	for _frame in ENTRY_WAIT_FRAMES:
		var arrived := _tree.current_scene as Node3D
		if is_instance_valid(arrived) and arrived.get_instance_id() != source_id \
				and str(_game.get("current_realm")) == "water" and str(_game.get("pending_realm_entry")).is_empty() \
				and arrived.has_method("shell_build_complete") and arrived.shell_build_complete() \
				and _water_population_seen and arrived.get_node_or_null("EncounterDirector") == _water_director \
				and INPUT_OWNER.current(_tree) == null:
			var player := arrived.get_node_or_null("Player") as Node3D
			var anchor: Vector3 = arrived.call("entry_anchor", "from_stormwood")
			if player == null or player.global_position.distance_to(anchor) > CORE_TOLERANCE \
					or not same_five(_party_before, _roster_ids()) or not _has(WATER_UNLOCK) or _has(WATER_KEY):
				_fail("natural First Shore arrival lacks exact anchor/key receipt or retained five")
				return
			_arrived_world = arrived
			_complete = true
			_note("ARRIVED naturally at First Shore through the two-input Waterward gate with the same five; STOP before Water opening")
			return
		await _tree.physics_frame
	_fail("natural Water entry did not settle within the existing scene budget")

func _watch_gate_activation(provider: Object) -> void:
	if is_instance_valid(provider) and provider.get_instance_id() == _gate_prompt_id:
		_gate_activations += 1

func _watch_arrival_node(node: Node) -> void:
	var script: Script = node.get_script()
	if script != null and script.resource_path == "res://scripts/combat/water_encounter_director.gd" \
			and node.get_parent() != null and not bool(node.get_parent().get("simulation_only")):
		_water_director = node
		node.population_ready.connect(_water_population_ready)

func _water_population_ready() -> void:
	_water_population_seen = true

func _descend_core() -> bool:
	var trunk := _world.get_node_or_null("StormheartTree") as Node3D
	if trunk == null:
		return _fail("actual Stormheart descent geometry absent")
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = ASCENT_SCALE
	Engine.physics_ticks_per_second = ASCENT_HZ
	await _tree.process_frame
	var passed := await _walk_actual_descent(trunk)
	_drive_stick(0, 0)
	await _tree.process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before
	return passed

func _core_south_ring() -> bool:
	var trunk := _world.get_node_or_null("StormheartTree") as Node3D
	if trunk == null:
		return _fail("actual core ring absent")
	# The core floor is a ring with a real centre opening. Cross its east
	# shoulder rather than aiming from the north landing through that opening.
	for local in [Vector3(26, 150, 0), Vector3(0, 150, 26)]:
		var at := trunk.to_global(local)
		if not await _walk_xz(Vector2(at.x, at.z), "actual core ring shoulder"):
			return false
	return true

func _walk_actual_descent(trunk: Node3D) -> bool:
	var started := Engine.get_physics_frames()
	# Approach the upper helix from its open +X endpoint, staying on the
	# ring's east half away from the cutout/centre opening.
	var upper: Array[Vector3] = [Vector3(0, 150, 26), Vector3(26, 150, 0), Vector3(0, 150, -26)]
	# Reverse the native-tested ascent mouth. The actual descent helper also
	# passes the native geometry probe; full-world ceremony remains unproved.
	var lower: Array[Vector3] = [Vector3(-4, 6, -26), Vector3(0, 6, -40)]
	var foot := Vector3(-100, float(_world.call("ground_height_at", -100.0, 5350.0)) + 0.2, 5350)
	var upper_index := 0
	var lower_index := 0
	var phase := "upper"
	var last_progress := 1.0
	_navigator.reset()
	while Engine.get_physics_frames() - started < ASCENT_FRAMES:
		if _manager.is_fighting() or _director.trainer_battle_active():
			return _fail("unexpected combat blocks the bounded physical Stormheart descent")
		var target: Vector3
		match phase:
			"upper":
				target = trunk.to_global(upper[upper_index])
				if _player.is_on_floor() and _player.global_position.distance_to(target) < CORE_TOLERANCE:
					upper_index += 1
					_navigator.reset()
					if upper_index == upper.size():
						phase = "helix"
			"helix":
				var progress := clampf((_player.global_position.y - (trunk.global_position.y + 6)) / 144.0, 0, 1)
				var fraction := maxf(0.0, minf(progress - 0.008, last_progress - 0.002))
				target = trunk.to_global(trunk.call("ascent_point", fraction))
				last_progress = minf(last_progress, progress)
				if progress <= 0.002 and _player.is_on_floor() \
						and _player.global_position.distance_to(trunk.to_global(trunk.call("ascent_point", 0.0))) < 0.8:
					phase = "lower"
					_navigator.reset()
			"lower":
				target = trunk.to_global(lower[lower_index])
				var tolerance := 0.8 if lower_index == 0 else CORE_TOLERANCE
				if _player.is_on_floor() and _player.global_position.distance_to(target) < tolerance:
					lower_index += 1
					_navigator.reset()
					if lower_index == lower.size():
						phase = "foot"
			"foot":
				target = foot
				if _player.is_on_floor() and _player.global_position.distance_to(foot) < CORE_TOLERANCE:
					_note("DESCENDED actual Stormheart helix/mouth/approach within its whole-route frame bound")
					return true
		if _navigator.can_walk():
			await _navigator.step(target)
		else:
			await _tree.physics_frame
	return _fail("physical Stormheart descent exceeded its shared 6000-frame budget at " + str(_player.global_position))

func result() -> Dictionary:
	return {"passed": _complete and failures.is_empty(), "world": _arrived_world,
		"game": _game, "failures": failures.duplicate(), "transcript": transcript.duplicate(),
		"endpoint": "earned natural First Shore arrival, before Water opening"}

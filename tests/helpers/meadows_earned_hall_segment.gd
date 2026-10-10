extends "res://tests/helpers/meadows_earned_relay_segment.gd"

## On-foot continuation after the earned Mill crossing. The Relay entrypoint
## is not called: only its physical prompt, care, walking and combat observers
## are reused. Warden combat, riding and the legendary choice are later work.
const HALL_CONFIG := "res://data/config/stronghold.json"
const ESSENCE_CAPS := preload("res://scripts/creatures/essence.gd")
const CAPTAIN_IDS := ["captain_riverwatch", "captain_field", "captain_ridge"]
const SIGILS := ["field_sigil", "ridge_sigil", "river_sigil"]
const HALL_FLAGS := ["defeated_stronghold_patrol", "defeated_stronghold_courtyard", "defeated_stronghold_elite"]
const ROOM_FRAMES := 600  # smoke_stronghold's existing chamber-hop budget.
## VICTORY_READ_FRAMES (a player reading a victory line, F04#6) is inherited from the relay segment.
const ENTRANCE_FRAMES := 950  # Its separate authored 40m ramp budget.
## Owner 10-04 segment ruling: the route is proven as the Sigil captains and
## gate (sigils) and the Hall gauntlet (hall, from the sigils piece's own
## saved end state). STAGE_FULL keeps the continuous driver's single run.
const STAGE_FULL := "full"
const STAGE_SIGILS := "sigils"
const STAGE_HALL := "hall"
var run_stage := STAGE_FULL
var _hold: Node3D
var _sigil_gate: Node3D
var _hall_config: Dictionary
var _named_trainer := ""
var _observed_trainers: Array[String] = []
var _round_start := 0


## The established COMBAT §7 reader (tests/helpers/f22_pattern_pilot.gd,
## the F22#1/F04#7 C2 policy) driving the earned route's actual fight. Its
## `_read` decisions are reused unchanged; only the input layer differs:
## presses and stick deflection go through the physical controller bindings,
## the stick camera-relative, and the production foe is never reconfigured.
class HallReader extends "res://tests/helpers/f22_pattern_pilot.gd":
	var rig: Node3D
	var presses := {}

	func _init(camera_rig: Node3D) -> void:
		rig = camera_rig
		_tally = {"burst_uses": 0, "events": []}

	func step(manager: Node, ally: Node3D, foe: Node3D) -> void:
		_release_attack()
		_release_move()
		_manager = manager
		_ally = ally
		_wild = foe
		_read("READER")
		_frames += 1

	func _walk(direction: Vector3) -> void:
		direction.y = 0.0
		var local := (rig.call("planar_basis") as Basis).inverse() * direction.normalized()
		for action: String in ["move_right", "move_back"]:
			var event := _joypad(action)
			if event is InputEventJoypadMotion:
				var axis := event as InputEventJoypadMotion
				axis.axis_value = (local.x if action == "move_right" else local.z) * signf(axis.axis_value)
				Input.parse_input_event(axis)

	func _release_move() -> void:
		for action: String in ["move_right", "move_back"]:
			var event := _joypad(action)
			if event is InputEventJoypadMotion:
				(event as InputEventJoypadMotion).axis_value = 0.0
				Input.parse_input_event(event)

	func _press(action: String) -> void:
		var event := _joypad(action)
		if not event is InputEventJoypadButton:
			push_error("Hall reader has no physical controller button: " + action)
			return
		(event as InputEventJoypadButton).pressed = true
		Input.parse_input_event(event)
		_pressed = action
		presses[action] = int(presses.get(action, 0)) + 1

	func _release_attack() -> void:
		if _pressed.is_empty():
			return
		var event := _joypad(_pressed)
		if event is InputEventJoypadButton:
			(event as InputEventJoypadButton).pressed = false
			Input.parse_input_event(event)
		_pressed = ""

	func release_all() -> void:
		_release_attack()
		_release_move()

	static func _joypad(action: String) -> InputEvent:
		for configured: InputEvent in InputMap.action_get_events(action):
			if configured is InputEventJoypadButton or configured is InputEventJoypadMotion:
				var event: InputEvent = configured.duplicate()
				event.device = 0
				return event
		return null


## The established COMBAT §7 reader (tests/helpers/f22_pattern_pilot.gd,
## the F22#1/F04#7 C2 policy) driving the earned route's actual fight. Its
## `_read` decisions are reused unchanged; only the input layer differs:
## presses and stick deflection go through the physical controller bindings,
## the stick camera-relative, and the production foe is never reconfigured.
class HallReader extends "res://tests/helpers/f22_pattern_pilot.gd":
	var rig: Node3D
	var presses := {}

	func _init(camera_rig: Node3D) -> void:
		rig = camera_rig
		_tally = {"burst_uses": 0, "events": []}

	func step(manager: Node, ally: Node3D, foe: Node3D) -> void:
		_release_attack()
		_release_move()
		_manager = manager
		_ally = ally
		_wild = foe
		_read("READER")
		_frames += 1

	func _walk(direction: Vector3) -> void:
		direction.y = 0.0
		var local := (rig.call("planar_basis") as Basis).inverse() * direction.normalized()
		for action: String in ["move_right", "move_back"]:
			var event := _joypad(action)
			if event is InputEventJoypadMotion:
				var axis := event as InputEventJoypadMotion
				axis.axis_value = (local.x if action == "move_right" else local.z) * signf(axis.axis_value)
				Input.parse_input_event(axis)

	func _release_move() -> void:
		for action: String in ["move_right", "move_back"]:
			var event := _joypad(action)
			if event is InputEventJoypadMotion:
				(event as InputEventJoypadMotion).axis_value = 0.0
				Input.parse_input_event(event)

	func _press(action: String) -> void:
		var event := _joypad(action)
		if not event is InputEventJoypadButton:
			push_error("Hall reader has no physical controller button: " + action)
			return
		(event as InputEventJoypadButton).pressed = true
		Input.parse_input_event(event)
		_pressed = action
		presses[action] = int(presses.get(action, 0)) + 1

	func _release_attack() -> void:
		if _pressed.is_empty():
			return
		var event := _joypad(_pressed)
		if event is InputEventJoypadButton:
			(event as InputEventJoypadButton).pressed = false
			Input.parse_input_event(event)
		_pressed = ""

	func release_all() -> void:
		_release_attack()
		_release_move()

	static func _joypad(action: String) -> InputEvent:
		for configured: InputEvent in InputMap.action_get_events(action):
			if configured is InputEventJoypadButton or configured is InputEventJoypadMotion:
				var event: InputEvent = configured.duplicate()
				event.device = 0
				return event
		return null


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Earned Hall needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" or INPUT_OWNER.current(tree) != null:
		_fail("Earned Hall requires ordinary world input in the retained Meadows")
		return result()
	_collect(world)
	if _player == null or _rig == null or _mill == null or _hold == null or _sigil_gate == null \
			or _trainers == null or _panel == null or _director == null or _combat == null or _arbiter == null:
		_fail("The actual Mill, Sigil Gate, Hall or input dependencies are missing")
		return result()
	_initial_ids = _party_ids()
	if run_stage != STAGE_HALL and not _sigil_start_ready():
		return result()
	if run_stage == STAGE_HALL and not _hall_start_ready():
		return result()
	_hall_config = _read(HALL_CONFIG)
	if gauntlet_path(_hall_config).size() != 3:
		_fail("The current authored three-guard passage chain is incomplete")
		return result()
	for flag: String in HALL_FLAGS + ["defeated_warden"]:
		if _has(flag) or not shutter_receipt(_hold, flag, false):
			_fail("The actual unopened Hall shutter is absent or already open: " + flag)
			return result()
	_input = INPUTS.new()
	_input._tree = tree
	_hook()
	if run_stage == STAGE_HALL:
		_completed = await _travel_hall()
	else:
		_completed = await _travel()
	_stick(0.0, 0.0)
	_unhook()
	return result()


## The sigils/full start: the actual paid Mill far-bank crossing, every captain
## unbeaten, no Sigil carried and the gate still shut.
func _sigil_start_ready() -> bool:
	var terrain := _read(TERRAIN)
	var channel: Dictionary = mill_config(terrain).get("channel", {})
	var bank := float(channel.get("half_width", 0.0)) + float(channel.get("rim", 0.0)) + 3.0
	if not retained_five(_initial_ids, _initial_ids) or _fighting() or channel.is_empty() \
			or not _has("relay_disabled") or not _has("captive_rescued") or not _has("mill_crossing_restored") \
			or not bool(_mill.call("is_open")) or _count(GEAR) != 0 \
			or float(_mill.call("depth_past_crossing", Vector2(_player.global_position.x, _player.global_position.z))) < bank - 0.6:
		return _fail("Hall must follow the actual paid Mill far-bank crossing with the same earned five")
	for id: String in CAPTAIN_IDS:
		if _has(str(TRAINERS.trainer(id).get("defeat_flag", ""))):
			return _fail("The next captain is already defeated: " + id)
	for id: String in SIGILS:
		if _count(id) != 0:
			return _fail("The next earned sigil is already carried: " + id)
	if _has("hall_approach_open") or bool(_sigil_gate.call("is_open")) or _has("defeated_warden"):
		return _fail("The Sigil/Hall route is already completed or bypassed")
	return true


## The hall start: the sigils piece's own end state. Every captain beaten,
## all three Sigils spent on the open gate, the player past its plane.
func _hall_start_ready() -> bool:
	if not retained_five(_initial_ids, _initial_ids) or _fighting():
		return _fail("Hall gauntlet must start from the retained five in ordinary world input")
	for id: String in CAPTAIN_IDS:
		if not _has(str(TRAINERS.trainer(id).get("defeat_flag", ""))):
			return _fail("The Hall gauntlet needs every Sigil captain beaten first: " + id)
	var road := departure_spine(_read(TERRAIN))
	var gate_at := Vector2(_sigil_gate.global_position.x, _sigil_gate.global_position.z)
	var gate_join := nearest_index(road, gate_at)
	var crossing := gate_crossing_points(_sigil_gate.global_transform, road[gate_join], road[gate_join + 1]) \
		if gate_join + 1 < road.size() else []
	var here := Vector2(_player.global_position.x, _player.global_position.z)
	if not _has("hall_approach_open") or not bool(_sigil_gate.call("is_open")) or not all_sigils(_sigil_stock(), 0) \
			or crossing.size() != 2 or (here - gate_at).dot((crossing[1] - crossing[0]).normalized()) <= 0.0:
		return _fail("The Hall gauntlet must start past the actual opened Sigil Gate with the Sigils spent")
	if _has("defeated_warden"):
		return _fail("The Warden is already beaten")
	return true


## M2 "save/reload at ... Sigils": an optional reload with all three earned
## Sigils carried, between the last captain and the Sigil Gate. The caller's
## hook saves, frees the world and loads it back; the segment then binds to
## the rebuilt world. Unset (the default) changes nothing.
var before_gate: Callable
## F02#4/#6: optional stage hooks, each `func(label: String) -> bool`. The
## caller may save and reload there (the segment rebinds to the rebuilt world,
## as for `before_gate`) or only mark a ledger stage. `after_captain` runs after
## each captain's win (label: trainer id), `after_hall` once the Warden arena
## is reached (label "hall"). Unset (the default) changes nothing.
var after_captain: Callable
var after_hall: Callable


func _collect(world: Node) -> void:
	_world = world as Node3D
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_mill = world.get_node_or_null("MillCrossing") as Node3D
	_hold = world.get_node_or_null("Stronghold") as Node3D
	_sigil_gate = world.get_node_or_null("SigilGate") as Node3D
	_trainers = world.get_node_or_null("Trainers") as Node3D
	_panel = world.get_node_or_null("DialoguePanel")
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = _tree.get_first_node_in_group("interaction_arbiter")


func _hook() -> void:
	_nav = NAV.new(_tree, _player, _rig, _stick)
	_combat.connect("entered", _on_entered)
	_combat.connect("hit_landed", _on_hit)
	_combat.connect("attack_missed", func(by_player: bool) -> void: print("DIAG MISS f=%d by_player=%s" % [Engine.get_physics_frames(), by_player]))
	_combat.connect("hit_landed", func(e: bool, a: float) -> void:
		var en: RefCounted = _combat.call("enemy")
		var al: RefCounted = _combat.call("active_creature")
		var ab := _director.call("ally_body") as Node3D
		var fb := _combat.call("enemy_body") as Node3D
		if ab and fb and not e:
			var off := ab.global_position - fb.global_position
			off.y = 0
			var fc: Vector3 = fb.call("facing")
			fc.y = 0
			print("DIAG GAP %.2f angle=%.0f committed=%s cfgrange=%.2f" % [off.length(), rad_to_deg(fc.angle_to(off)), _combat.call("player_is_committed"), float((fb.call("combat_config") as Dictionary).get("range", 0))])
		print("DIAG HIT f=%d enemy_side=%s amt=%.1f ally=%s %s/%s enemy=%s L%s %s/%s" % [Engine.get_physics_frames(), e, a,
			al.get("species_id") if al else "-", al.get("hp") if al else "-", al.get("max_hp") if al else "-",
			en.get("species_id") if en else "-", en.get("level") if en else "-", en.get("hp") if en else "-", en.get("max_hp") if en else "-"]))
	_combat.connect("exited", _on_exit)
	_panel.connect("finished", _on_dialogue_finished)
	_arbiter.connect("activated", _on_activated)


func _unhook() -> void:
	for pair: Array in [[_combat, "entered", _on_entered], [_combat, "hit_landed", _on_hit],
			[_combat, "exited", _on_exit], [_panel, "finished", _on_dialogue_finished],
			[_arbiter, "activated", _on_activated]]:
		var node: Object = pair[0]
		if is_instance_valid(node) and node.is_connected(str(pair[1]), pair[2]):
			node.disconnect(str(pair[1]), pair[2])


func _stage_hook(hook: Callable, label: String) -> bool:
	if not hook.is_valid():
		return true
	_stick(0.0, 0.0)
	_unhook()
	var ok: bool = await hook.call(label)
	if not ok:
		return _fail("The stage hook (save/reload) after %s failed" % label)
	_collect(_tree.current_scene)
	_initial_ids = _party_ids()
	if _player == null or _sigil_gate == null or _combat == null or _panel == null or _arbiter == null or _hold == null:
		return _fail("The world after %s lacks the route dependencies" % label)
	_hook()
	return true


func _reload_with_sigils() -> bool:
	if not before_gate.is_valid():
		return true
	if not all_sigils(_sigil_stock(), 1):
		return _fail("The Sigil reload was reached without the three earned Sigils")
	_stick(0.0, 0.0)
	_unhook()
	var ok: bool = await before_gate.call()
	if not ok:
		return _fail("The save/reload with the three Sigils carried failed")
	_collect(_tree.current_scene)
	# The retained-five checks compare creature instance ids, which a load
	# replaces; the caller's reload has already required the saved party UIDs
	# to be identical, so re-baseline on the reloaded instances.
	_initial_ids = _party_ids()
	if _player == null or _sigil_gate == null or _combat == null or _panel == null or _arbiter == null:
		return _fail("The reloaded world lacks the Sigil Gate route dependencies")
	_hook()
	if not all_sigils(_sigil_stock(), 1):
		return _fail("The three earned Sigils did not survive the reload")
	return true


## A spine point that is only a bend in the road (not a captain's junction or
## the gate's) counts as passed within this radius: the points are 60-150 m
## apart, and a wild pack plus a villager standing on the (-152,4235) bend
## held the walker 8.7 m short of it after two real wild wins (seed 15).
const SPINE_BEND_RADIUS := 10.0


func _travel() -> bool:
	var road := departure_spine(_read(TERRAIN))
	if road.is_empty() or not await _prepare():
		return _fail("The current on-foot departure spine or earned care is unavailable")
	var previous := 0
	for id: String in CAPTAIN_IDS:
		var body := _trainers.call("body_for", id) as Node3D
		if not is_instance_valid(body):
			return _fail("The actual Upper Meadows captain is absent: " + id)
		var join := nearest_index(road, Vector2(body.global_position.x, body.global_position.z))
		if join < previous:
			return _fail("The current captain positions no longer follow the authored road order")
		for index in range(previous, join + 1):
			if not await _walk_ground(road[index], 1.5 if index == join else SPINE_BEND_RADIUS):
				return false
		if not await _fight_named(body, id):
			return false
		# Return through the actual road junction before following its next leg.
		if not await _walk_ground(road[join]):
			return false
		if not await _stage_hook(after_captain, id):
			return false
		previous = join + 1
	if not await _reload_with_sigils():
		return false
	var gate_at := Vector2(_sigil_gate.global_position.x, _sigil_gate.global_position.z)
	var gate_join := nearest_index(road, gate_at)
	if gate_join < previous or gate_join + 1 >= road.size():
		return _fail("The current Sigil Gate does not lie after the three captains on the spine")
	for index in range(previous, gate_join + 1):
		if not await _walk_ground(road[index], 1.5 if index == gate_join else SPINE_BEND_RADIUS):
			return false
	var crossing := gate_crossing_points(_sigil_gate.global_transform, road[gate_join], road[gate_join + 1])
	if crossing.size() != 2 or not await _walk_ground(crossing[0], 0.6):
		return _fail("The actual Sigil Gate near side could not be reached")
	var before := _sigil_stock()
	var actual_keys: Array = _sigil_gate.get("key_item_ids")
	if not keys_match(actual_keys) or not all_sigils(before, 1):
		return _fail("The actual gate lacks precisely the three earned captain sigils")
	if not await _talk(_sigil_gate.get_node_or_null("Interactable") as Node3D, str(_sigil_gate.get("unlocked_conversation"))):
		return false
	var shape := _sigil_gate.get("_shape") as CollisionShape3D
	if not sigil_paid_receipt(before, _sigil_stock(), _has("hall_approach_open"), bool(_sigil_gate.call("is_open")),
			shape != null and shape.disabled):
		return _fail("The exact gate input did not spend all three sigils and disable the real leaf")
	if not await _walk_ground(crossing[1], 0.6):
		return false
	var direction := (crossing[1] - crossing[0]).normalized()
	var depth := (Vector2(_player.global_position.x, _player.global_position.z) - gate_at).dot(direction)
	if depth < crossing[1].distance_to(gate_at) - 0.6:
		return _fail("The player has not physically crossed the actual Sigil Gate plane")
	_receipt("hall_approach_open", {"sigils_before": before, "sigils_after": _sigil_stock(), "depth": depth})
	if run_stage == STAGE_SIGILS:
		return true
	return await _travel_hall()


func _travel_hall() -> bool:
	var road := departure_spine(_read(TERRAIN))
	var gate_join := nearest_index(road, Vector2(_sigil_gate.global_position.x, _sigil_gate.global_position.z))
	# The last creature bed before the Warden (the_waystop) stands just past
	# the gate: a player sleeps the five back before the Hall's three guards.
	if party_hp_fraction(_game.get("party")) < 0.95 and not await _camp_care():
		return false
	# Stop the terrain spine before it enters the raised Hall footprint.
	var entrance := _hold.call("marker", "entrance") as Vector3
	if not bool(_hold.call("has_marker", "entrance")):
		return _fail("The actual Hall has no approach-ramp entrance marker")
	var entrance_join := nearest_index(road, Vector2(entrance.x, entrance.z))
	for index in range(gate_join + 1, entrance_join + 1):
		if not await _walk_ground(road[index]):
			return false
	if not await _walk(entrance, 0.6):
		return false
	var stages := gauntlet_path(_hall_config)
	var hall_trainers := _hold.call("trainers_node") as Node3D
	if hall_trainers == null or not await _walk_marker(str(stages[0].from), ENTRANCE_FRAMES):
		return _fail("The ordinary Hall ramp did not reach the outer works")
	_supported_y = (_hold.call("marker", str(stages[0].from)) as Vector3).y
	_in_hall = true
	for stage: Dictionary in stages:
		var flag := str(stage.flag)
		if _has(flag) or not shutter_receipt(_hold, flag, false):
			return _fail("The next Hall passage was open before its own guard fell: " + flag)
		var body := hall_trainers.call("body_for", str(stage.trainer)) as Node3D
		if not is_instance_valid(body) or not await _fight_named(body, str(stage.trainer)):
			return false
		for _frame in 120:
			if shutter_receipt(_hold, flag, true):
				break
			await _tree.physics_frame
		if not _has(flag) or not shutter_receipt(_hold, flag, true):
			return _fail("The actual guard victory did not release its own physical shutter: " + flag)
		# Return to the room axis before the narrow passage, instead of drawing
		# a diagonal from the trainer's side alcove through a chamber wall.
		var crossing_start := Engine.get_physics_frames()
		if not await _walk_marker(str(stage.from), ROOM_FRAMES):
			return false
		var shutter := _hold.get_node("BlastShutterBody_" + flag) as Node3D
		var centre: Vector3 = _hold.call("marker", str(stage.from))
		var remaining := room_frames_remaining(Engine.get_physics_frames() - crossing_start)
		if remaining <= 0 or not await _walk(Vector3(shutter.global_position.x, centre.y, shutter.global_position.z), 0.6, remaining):
			return _fail("The actual Hall passage exceeded its unchanged chamber-hop budget")
		remaining = room_frames_remaining(Engine.get_physics_frames() - crossing_start)
		if remaining <= 0 or not await _walk_marker(str(stage.to), remaining):
			return false
		if room_frames_remaining(Engine.get_physics_frames() - crossing_start) <= 0:
			return _fail("Late arrival cannot complete the Hall passage")
		_receipt("hall_passage_crossed", {"trainer": stage.trainer, "flag": flag, "from": stage.from, "to": stage.to,
			"player": _player.global_position})
	if not await _stage_hook(after_hall, "hall"):
		return false
	if not retained_five(_initial_ids, _party_ids()) or _tree.current_scene != _world \
			or str(_game.get("current_realm")) != "meadows" or _fighting() or _has("defeated_warden") \
			or not shutter_receipt(_hold, "defeated_warden", false):
		return _fail("The retained five did not reach the arena with the Warden and final passage still ahead")
	_receipt("warden_arena_entered", {"party_ids": _party_ids(), "trainers": _observed_trainers.duplicate(),
		"player": _player.global_position, "marker": _hold.call("marker", "warden_arena"), "travel": "on_foot"})
	return true


## Standing still, the exact prompt must keep winning before Interact: at the
## Sigil Gate a roadside plant's harvest offer took the Interact frame just
## after the walker stopped. A player steps closer until the gate's own
## prompt holds.
const PROMPT_SETTLE_FRAMES := 12
const PROMPT_SETTLE_STEPS := 20


## A press that lands on a harvestable plant beside the target (the Sigil Gate
## stands among them) just gathers it; a player presses again.
func _retryable_activation() -> bool:
	return _activated_name.contains("/Vegetation/")


func _approach_prompt(prompt: Node3D) -> bool:
	for _attempt in PROMPT_SETTLE_STEPS:
		if not await super._approach_prompt(prompt):
			return false
		var held := true
		for _frame in PROMPT_SETTLE_FRAMES:
			await _tree.physics_frame
			if not is_instance_valid(prompt) or _arbiter.call("winning_provider") != prompt \
					or not bool(_arbiter.call("winner").get("actionable", false)):
				held = false
				break
		if held:
			return true
		if not is_instance_valid(prompt):
			return false
		_receipt("prompt_settle_step", {"wanted": str(prompt.get_path()) if is_instance_valid(prompt) else "",
			"winner": str((_arbiter.call("winning_provider") as Node).get_path()) if _arbiter.call("winning_provider") is Node else ""})
		for _frame in 10:
			_nav.step(prompt.global_position)
			await _tree.physics_frame
		_stick(0.0, 0.0)
	return _fail("The exact live prompt never held the Interact offer while standing still")


## Carried care runs out over three captains and their roads (L15 local run:
## no revive or potion left after Captain Hald, Grandpa's bed the only
## fallback). A player instead beds the hurt five at the nearest authored camp
## on the route (rest_point.gd, `full_heal_seconds` while bedded): the real bed
## panel, production recovery ticks, an early wake, then back to the road.
const CAMP_BED := preload("res://scripts/build/creature_bed.gd")
const BED_INPUT := preload("res://tests/helpers/gate_b_tail_segment.gd")
const CAMP_REACH_M := 1400.0
const CAMP_BELOW := 0.6  # Party HP fraction under which a captain is not taken on carried care.
var camp_rests := 0
var _in_hall := false


func _prepare() -> bool:
	if not _in_hall and not _carried_care_covers() and not await _camp_care():
		return false
	return await super._prepare()


func _prepare_for_trainer() -> bool:
	if not _in_hall and party_hp_fraction(_game.get("party")) < CAMP_BELOW and not await _camp_care():
		return false
	return await super._prepare_for_trainer()


func _carried_care_covers() -> bool:
	var inventory := _game.get("inventory") as RefCounted
	var fainted := 0
	var low := false
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		if bool(member.get("fainted")):
			fainted += 1
		elif float(member.get("hp")) < float(member.get("max_hp")) * CARE_BELOW:
			low = true
	return fainted <= int(inventory.call("count", "revive")) \
		and (not low or int(inventory.call("count", "potion_small")) > 0)


static func party_hp_fraction(party: RefCounted) -> float:
	var hp := 0.0
	var most := 0.0
	for member: RefCounted in party.call("members"):
		hp += 0.0 if bool(member.get("fainted")) else float(member.get("hp"))
		most += float(member.get("max_hp"))
	return hp / most if most > 0.0 else 0.0


## Authored camp beds ahead on this route only (rest_point.gd's reserved
## indices for highfield_stockcamp -14, the_waystop -15, ridge_patrol_camp
## -16): never Grandpa's installed bed, the Hall's own recovery bed, a
## player-built one, or a camp behind the route (ranger_camp's bed prompt
## measured 15.9 m from a walker standing 1.4 m from it in plan, Hall proof
## render 38044156997).
const CAMP_BEDS_AHEAD := [-14, -15, -16]


static func is_camp_bed(bed: Node) -> bool:
	return bed != null and bed.get_script() == CAMP_BED and bed.name != "HomeCreatureBed" \
		and bed.has_method("build_index") and CAMP_BEDS_AHEAD.has(int(bed.call("build_index")))


func _nearest_camp_bed() -> Node3D:
	var best: Node3D = null
	for node: Node in _world.find_children("*", "Node3D", true, false):
		if not is_camp_bed(node):
			continue
		var bed := node as Node3D
		if best == null or bed.global_position.distance_to(_player.global_position) \
				< best.global_position.distance_to(_player.global_position):
			best = bed
	return best


func _camp_care() -> bool:
	var party := _game.get("party") as RefCounted
	var bed := _nearest_camp_bed()
	if bed == null or bed.global_position.distance_to(_player.global_position) > CAMP_REACH_M:
		return _fail("Spent carried care has no authored camp bed within reach of the route")
	var resume := Vector2(_player.global_position.x, _player.global_position.z)
	var before := _party_hp()
	if not await _walk_ground(Vector2(bed.global_position.x, bed.global_position.z), 6.0):
		return false
	var driver := BED_INPUT.new()
	driver._tree = _tree
	driver._world = _world
	driver._game = _game
	driver._player = _player
	driver._rig = _rig
	driver._party = party
	driver._bed = bed
	if not driver._collect_nodes():
		return _fail("Camp bed input dependencies are missing: " + str(driver.failures))
	driver._resolve_move_bindings()
	var prompt := bed.get_node_or_null("Interactable") as Node3D
	var heal_seconds := PROGRESSION.creature_bed_full_heal_seconds(PROGRESSION.config())
	for index in int(party.call("size")):
		var member: RefCounted = party.call("at", index)
		if not bool(member.get("fainted")) and float(member.get("hp")) >= float(member.get("max_hp")) * 0.95:
			continue
		if prompt == null or not await driver._assign_to_bed(index):
			return _fail("Camp bed assignment failed: " + str(driver.failures))
		var deadline := Time.get_ticks_msec() + int((heal_seconds * 2.0 + 30.0) * 1000.0)
		while float(member.get("hp")) < float(member.get("max_hp")) - 0.01:
			if _fighting():
				_stick(0.0, 0.0)
				if not await _fight():
					return false
			if Time.get_ticks_msec() >= deadline or not bool(member.get("resting")) or _tree.paused:
				return _fail("Production camp-bed recovery stopped before full HP")
			await _tree.physics_frame
		if not await driver._walk_to_prompt(prompt, "camp creature bed"):
			return _fail("Could not return to the camp bed to wake: " + str(driver.failures))
		await driver._tap(&"interact")
		var panel: Node = await driver._wait_for_panel("creature_bed_panel.gd")
		if panel == null or not await driver._focus_the_row_for(panel, index):
			return _fail("Camp bed panel could not select the sleeping creature to wake")
		await driver._tap(&"ui_accept")
		await driver._tap(&"menu_cancel")
		await driver._settle(8)
		if bool(member.get("resting")) or bool(member.get("fainted")) or _tree.paused:
			return _fail("Camp bed early wake left the creature asleep, fainted or the world paused")
	camp_rests += 1
	_receipt("camp_bed_recovery", {"bed": str(bed.get_path()), "bed_index": bed.call("build_index"),
		"before": before, "after": _party_hp(), "full_heal_seconds": heal_seconds})
	return await _walk_ground(resume, 3.0)


## Ordinary wilds on this route take the same reader as the named fights. The
## inherited campaign pilot stalled on a road wild (Hall proof 38032275731:
## 0 hits in its 7200-frame budget, charged refused for Energy). Loss
## recovery and the win verdict are the inherited ones, unchanged.
func _fight() -> bool:
	if bool(_director.call("trainer_battle_active")) or _fight_enemy == null:
		return _fail("An unexpected trainer or unobserved encounter interrupted the Hall route")
	var pilot := HallReader.new(_rig)
	while _fighting() and within_battle_deadline(Engine.get_physics_frames() - _fight_started):
		if _combat.call("enemy") != _fight_enemy or bool(_director.call("trainer_battle_active")):
			pilot.release_all()
			return _fail("The admitted wild identity changed during the input fight")
		var ally := _director.call("ally_body") as Node3D
		var foe := _combat.call("enemy_body") as Node3D
		if is_instance_valid(ally) and is_instance_valid(foe):
			pilot.step(_combat, ally, foe)
		else:
			pilot.release_all()
		await _tree.physics_frame
	pilot.release_all()
	if not _fighting() and str(_combat.call("outcome")) == "lost" and _wild_losses < MAX_WILD_LOSSES:
		_wild_losses += 1
		_receipt("wild_loss_recovered", {"number": _wild_losses, "hits": _fight_hits,
			"frames": Engine.get_physics_frames() - _fight_started, "party": _party_hp()})
		for _frame in 180:
			if INPUT_OWNER.current(_tree) == null:
				break
			await _tree.physics_frame
		return await _prepare()
	if not within_battle_deadline(Engine.get_physics_frames() - _fight_started) \
			or _fighting() or str(_combat.call("outcome")) != "won" or _fight_hits <= 0:
		return _fail("Real wild combat did not win with landed strikes inside its unchanged physics budget (outcome '%s', fighting %s, hits %d, frames %d, presses %s, party %s)" % [
			str(_combat.call("outcome")), _fighting(), _fight_hits, Engine.get_physics_frames() - _fight_started,
			JSON.stringify(pilot.presses), _party_hp()])
	_receipt("wild_victory", {"hits": _fight_hits, "presses": pilot.presses.duplicate(),
		"enemy_id": _fight_enemy.get_instance_id(), "frames": Engine.get_physics_frames() - _fight_started})
	for _frame in 120:
		if INPUT_OWNER.current(_tree) == null:
			return true
		await _tree.physics_frame
	return _fail("The actual wild victory did not release world input")


func _walk_marker(id: String, budget: int) -> bool:
	if not bool(_hold.call("has_marker", id)):
		return _fail("The actual Hall route marker is missing: " + id)
	return await _walk(_hold.call("marker", id), 0.6, budget)


func _fight_named(body: Node3D, id: String) -> bool:
	_captain_spec = TRAINERS.trainer(id)
	var flag := str(_captain_spec.get("defeat_flag", ""))
	if _captain_spec.is_empty() or flag.is_empty() or _has(flag) or not await _prepare_for_trainer():
		return _fail("The exact unbeaten trainer or actual carried preparation is unavailable: " + id)
	var prompt := body.get_node_or_null("Interactable") as Node3D
	if not await _approach_prompt(prompt):
		return false
	var before_items := _captain_stock()
	var before_xp := _xp_snapshot()
	var xp_caps := _xp_cap_totals()
	if xp_caps.size() != before_xp.size():
		return _fail("The retained five lack exact admitted XP caps: " + id)
	_captain_start = 0
	_round_start = Engine.get_physics_frames()
	_captain_rounds = 0
	_captain_wins = 0
	_captain_hits = 0
	_captain_kills.clear()
	_expected_xp.clear()
	for member: int in before_xp:
		_expected_xp[member] = 0
	_named_trainer = id
	_captain_active = true
	if not await _talk(prompt, str(_captain_spec.get("challenge", ""))):
		return false
	if not bool(_director.call("trainer_battle_active")) or str(_director.call("trainer_battle_id")) != id:
		return _fail("Physical challenge input did not admit the exact required trainer: " + id)
	var pilot := HallReader.new(_rig)
	var team_size := TRAINERS.team_of(_captain_spec).size()
	while bool(_director.call("trainer_battle_active")) and round_within_deadline(Engine.get_physics_frames() - _round_start):
		if not _failures.is_empty():
			break
		var ally := _director.call("ally_body") as Node3D
		var foe := _combat.call("enemy_body") as Node3D
		if bool(_combat.call("is_fighting")) and is_instance_valid(ally) and is_instance_valid(foe):
			pilot.step(_combat, ally, foe)
		else:
			pilot.release_all()
		await _tree.physics_frame
	pilot.release_all()
	_captain_active = false
	# Retain the actual failed oracle as well as successful outcomes. A
	# generic failure must not lose the round/hit/physical-input witness.
	var actual_enemy: RefCounted = _combat.call("enemy")
	_receipt("trainer_attempt", {"id": id, "rounds": _captain_rounds, "wins": _captain_wins,
		"hits": _captain_hits, "kills": _captain_kills.size(), "team_size": team_size,
		"frames": Engine.get_physics_frames() - _captain_start,
		"within_round_deadline": round_within_deadline(Engine.get_physics_frames() - _round_start),
		"fighting": _fighting(), "flag": _has(flag), "presses": pilot.presses.duplicate(),
		"read_escapes": int(pilot._tally.get("read_escapes", 0)), "read_interrupts": int(pilot._tally.get("read_interrupts", 0)),
		"enemy_species": str(actual_enemy.get("species_id")) if actual_enemy != null else "",
		"enemy_hp": float(actual_enemy.get("hp")) if actual_enemy != null else -1.0,
		"items_before": before_items, "items_after": _captain_stock(),
		"xp_before": before_xp, "xp_after": _xp_snapshot(), "expected_xp": _expected_xp.duplicate(), "xp_cap_totals": xp_caps})
	if not round_within_deadline(Engine.get_physics_frames() - _round_start) or _fighting() \
			or not _failures.is_empty() or _captain_rounds != team_size or _captain_wins != team_size \
			or _captain_kills.size() != team_size or _captain_hits <= 0 or not _has(flag) \
			or not retained_five(_initial_ids, _party_ids()) \
			or not exact_item_reward(before_items, _captain_stock(), _captain_spec.get("reward", {})) \
			or not exact_capped_captain_xp(before_xp, _xp_snapshot(), _expected_xp, xp_caps):
		return _fail("Required trainer lacks exact admitted opponents, killing hits, configured rewards/XP and retained-five receipts: " + id)
	_observed_trainers.append(id)
	_receipt("trainer_defeated", {"id": id, "rounds": _captain_rounds, "wins": _captain_wins, "hits": _captain_hits,
		"items_before": before_items, "items_after": _captain_stock(), "xp_before": before_xp,
		"xp_after": _xp_snapshot(), "expected_xp": _expected_xp.duplicate(), "xp_cap_totals": xp_caps, "frames": Engine.get_physics_frames() - _captain_start})
	# A row's `victory_conversation` (the captains' Sigil handover, F04#6) opens
	# a deferred frame after the win; it is read through with Interact at a
	# reader's pace (one line per VICTORY_READ_FRAMES) before world input is
	# expected back.
	var victory := not str(_captain_spec.get("victory_conversation", "")).is_empty()
	var read := not victory
	for frame in 120 + (VICTORY_READ_FRAMES * 8 if victory else 0):
		if bool(_panel.call("is_open")):
			read = true
			if frame % VICTORY_READ_FRAMES == VICTORY_READ_FRAMES - 1:
				await _input._tap("interact")
		elif INPUT_OWNER.current(_tree) == null and (read or frame >= 30):
			return true
		await _tree.physics_frame
	return _fail("The actual trainer victory did not return ordinary world input: " + id)


func _on_entered() -> void:
	# Relay's observer fixes one captain ID; this route binds the exact current
	# named trainer while retaining its killing-hit XP and outcome observers.
	_fight_started = Engine.get_physics_frames()
	_fight_enemy = _combat.call("enemy")
	_fight_hits = 0
	if not _captain_active:
		return
	var team := TRAINERS.team_of(_captain_spec)
	if str(_director.call("trainer_battle_id")) != _named_trainer or _captain_rounds >= team.size() \
			or not opponent_matches(_fight_enemy, team[_captain_rounds]):
		_fail("The actual admission differs from the next named trainer/opponent")
		return
	if _captain_rounds == 0:
		_captain_start = Engine.get_physics_frames()
	_captain_rounds += 1
	_round_start = Engine.get_physics_frames()


static func departure_spine(terrain: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for id: String in ["band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"]:
		var band := trail_points(terrain, "bands", id)
		if band.is_empty():
			return []
		if out.is_empty():
			var crossing := mill_config(terrain)
			var road: Array = crossing.get("road", [])
			if road.is_empty():
				return []
			for index in range(nearest_index(band, _v2(road[-1])), band.size()):
				out.append(band[index])
		else:
			if out[-1] != band[0]:
				return []
			out.append_array(band.slice(1))
	return out


static func gauntlet_path(config: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var room := "outer_works"
	for flag: String in HALL_FLAGS:
		var edge: Dictionary = {}
		for passage: Dictionary in config.get("passages", []):
			if str(passage.get("from", "")) == room and str(passage.get("gated_by_flag", "")) == flag:
				edge = passage
		var trainer := ""
		for entry: Dictionary in config.get("gauntlet", []):
			if str(entry.get("chamber", "")) == room \
					and str(TRAINERS.trainer(str(entry.get("trainer", ""))).get("defeat_flag", "")) == flag:
				trainer = str(entry.trainer)
		if edge.is_empty() or trainer.is_empty() or float(edge.get("width", 0)) <= 0:
			return []
		out.append({"from": room, "to": str(edge.to), "flag": flag, "trainer": trainer})
		room = str(edge.to)
	return out if room == "warden_arena" else []


static func gate_crossing_points(at: Transform3D, before: Vector2, after: Vector2) -> Array[Vector2]:
	var centre := Vector2(at.origin.x, at.origin.z)
	var forward := Vector2(at.basis.z.x, at.basis.z.z).normalized()
	if forward.length() < 0.99:
		return []
	if forward.dot(after - before) < 0:
		forward = -forward
	if (before - centre).dot(forward) >= 0 or (after - centre).dot(forward) <= 0:
		return []
	# Same 4m live gate prompt radius, plus 2m clear of its leaf on both sides.
	return [centre - forward * 6.0, centre + forward * 6.0]


static func keys_match(keys: Array) -> bool:
	if keys.size() != SIGILS.size():
		return false
	for id: String in SIGILS:
		if not keys.has(id):
			return false
	return true


## TRAINER_FRAMES is the earned bridge/tournament ROUND deadline; a named
## trainer fields several rounds, so each admitted opponent gets that budget.
static func round_within_deadline(elapsed: int) -> bool:
	return elapsed >= 0 and elapsed < TRAINER_FRAMES


static func room_frames_remaining(elapsed: int) -> int:
	return maxi(0, ROOM_FRAMES - elapsed) if elapsed >= 0 else 0


static func all_sigils(stock: Dictionary, count: int) -> bool:
	if stock.size() != SIGILS.size():
		return false
	for id: String in SIGILS:
		if not stock.has(id) or int(stock[id]) != count:
			return false
	return true


static func sigil_paid_receipt(before: Dictionary, after: Dictionary, flag: bool, opened: bool, leaf_disabled: bool) -> bool:
	return all_sigils(before, 1) and all_sigils(after, 0) and flag and opened and leaf_disabled


static func shutter_receipt(hold: Node3D, flag: String, opened: bool) -> bool:
	if not is_instance_valid(hold):
		return false
	var body := hold.get_node_or_null("BlastShutterBody_" + flag) as StaticBody3D
	var mesh := hold.get_node_or_null("BlastShutter_" + flag) as MeshInstance3D
	if body == null or mesh == null or body.get_child_count() != 1:
		return false
	var shape := body.get_child(0) as CollisionShape3D
	return shape != null and shape.shape != null and shape.disabled == opened and mesh.visible != opened


func _sigil_stock() -> Dictionary:
	var stock := {}
	for id: String in SIGILS:
		stock[id] = _count(id)
	return stock


func _xp_cap_totals() -> Dictionary:
	var caps := {}
	var cfg := PROGRESSION.config()
	var personal: Variant = _game.get("local").get("redesign_character")
	if not personal is Dictionary:
		return caps
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		var cap := ESSENCE_CAPS.creature_cap(personal, str(member.get("uid")))
		if cap < 1:
			return {}
		cap = mini(cap, int(cfg.get("level", {}).get("cap", member.get("level"))))
		caps[member.get_instance_id()] = total_xp(cap, 0, cfg)
	return caps


static func exact_capped_captain_xp(before: Dictionary, after: Dictionary, awarded: Dictionary, caps: Dictionary) -> bool:
	# Keep the killing-hit observer's configured award intact. Production
	# gain_xp discards overflow at the creature's admitted cap; a generated
	# L20/cap20 input therefore earns zero banked XP, never an invented gain.
	if before.size() != 5 or after.size() != 5 or awarded.size() != 5 or caps.size() != 5:
		return false
	for id: int in before:
		if not after.has(id) or not awarded.has(id) or not caps.has(id):
			return false
		if int(before[id]) < 0 or int(caps[id]) < int(before[id]) or int(awarded[id]) < 0:
			return false
		if int(after[id]) != mini(int(before[id]) + int(awarded[id]), int(caps[id])):
			return false
	return true


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	_receipts.append(detail)
	print("EARNED HALL — ", detail)


func _fail(message: String) -> bool:
	_failures.append(message)
	print("EARNED HALL FAIL — ", message)
	return false

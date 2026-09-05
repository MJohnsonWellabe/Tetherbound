extends SceneTree

## CL-G12 / CURRENT_STATE.md §3 P1 "Player sleep: the loft bed does not work".
##
## Owner, asked directly on 2026-09-04: *"I've never been able to sleep in the
## loft bed."* `tests/smoke_home_sleep.gd` passes, and so does
## `smoke_gate_b_continuous`'s sleep beat -- but both TELEPORT the body onto
## the loft (`_stand_beside()` sets `global_position` to the bed marker plus
## 1.5m and lets it drop). Nothing in the repository has ever driven a real
## body from the ground floor UP THE STAIR with stick input alone, which is
## the only path a player has. The gap between those two facts is where the
## defect lives, so this probe is the missing measurement:
##
##   1. dump the loft's real geometry (tread tops, loft slab top, the ledge
##      between them, the beam and rail spans, the bed marker, the prompt);
##   2. drive a REAL `CharacterBody3D` from the ground floor to the stair
##      foot, up the flight, and across the loft to the bed, using nothing
##      but held stick input through `player_controller.gd`;
##   3. at every step log the winning arbiter prompt, the SleepPrompt's own
##      `interaction_offer()` verdict (in range? sight line? enabled?), and
##      the body's height against the tread it should be standing on;
##   4. finally press interact through the arbiter and report whether the
##      night actually passed.
##
##   godot --headless --path . --script tools/gate_f/probe_loft_bed_reach.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SEQUENCE_DIRECTOR_SCRIPT := "res://scripts/story/sequence_director.gd"
const SETTLE_FRAMES := 240
const STARTER_SPECIES := "terrapup"

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _house: Node3D = null
var _arbiter: Node = null
var _sleep_prompt: Node3D = null
var _failures: Array[String] = []
var _stick := Vector2.ZERO


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("PROBE FAIL: no Game autoload")
		quit(1)
		return
	var progression: RefCounted = game.get("progression")
	progression.call("load_data", {})
	var party: RefCounted = game.get("party")
	# Same compatibility inference smoke_home_sleep uses: two party members
	# restores the `free_play` beat, which is what unlocks the front door and
	# (on the same gate) the bed's Sleep prompt.
	for species_id in [STARTER_SPECIES, STARTER_SPECIES]:
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature == null or not bool(party.call("add", creature)):
			print("PROBE FAIL: could not seed a two-creature party before boot")
			quit(1)
			return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_house = _world.get_node_or_null(^"GrandpaHouse") as Node3D
	_arbiter = get_first_node_in_group(&"interaction_arbiter")
	if _player == null or _rig == null or _house == null or _arbiter == null:
		print("PROBE FAIL: player=%s rig=%s house=%s arbiter=%s"
			% [_player, _rig, _house, _arbiter])
		quit(1)
		return
	_sleep_prompt = _house.get_node_or_null(^"SleepPrompt") as Node3D

	var sequence := _find_by_script(_world, SEQUENCE_DIRECTOR_SCRIPT)
	print("story beat: %s" % (str(sequence.call("beat")) if sequence != null else "<no director>"))

	_dump_geometry()
	await _walk_the_stair()
	await _press_interact(game, progression)

	print("")
	if _failures.is_empty():
		print("PROBE RESULT: the loft bed is reachable and sleepable on foot")
		quit(0)
		return
	print("PROBE RESULT: %d unresolved" % _failures.size())
	for f in _failures:
		print("  - %s" % f)
	quit(1)


# ------------------------------------------------------------------ geometry


func _k(name_key: String) -> Variant:
	return _house.get_script().get_script_constant_map().get(name_key)


func _dump_geometry() -> void:
	print("")
	print("=== 1. the loft's real geometry (house-local metres) ===")
	var inner_w := float(_k("INNER_W"))
	var inner_d := float(_k("INNER_D"))
	var floor_h := float(_k("FLOOR_H"))
	var loft_w := float(_k("LOFT_W"))
	var steps := int(_k("STAIR_STEPS"))
	var run := float(_k("STAIR_RUN"))
	var loft_top_c := float(_k("LOFT_TOP"))
	var rise := loft_top_c / float(steps)
	var depth := run / float(steps)
	var start_x := -inner_w * 0.5 + loft_w + run
	var loft_top := loft_top_c
	print("  house origin      : %s" % str(_house.global_position))
	print("  ground slab top   : y=0.12   loft slab top: y=%.2f" % loft_top)
	print("  stair: %d treads, rise %.3fm, going %.3fm, foot x=%.2f head x=%.2f, z band %.2f..%.2f"
		% [steps, rise, depth, start_x, start_x - run,
			-inner_d * 0.5 + 0.6 - float(_k("STAIR_WIDTH")) * 0.5,
			-inner_d * 0.5 + 0.6 + float(_k("STAIR_WIDTH")) * 0.5])
	print("  top tread top     : y=%.2f (x %.2f..%.2f)"
		% [rise * steps, start_x - run, start_x - run + depth])
	print("  LEDGE at the loft edge: %.3fm  (STEP_HEIGHT is %.2f)"
		% [loft_top - rise * steps, 0.35])
	print("  loft beam          : y %.2f..%.2f, x %.3f..%.3f, z %.2f..%.2f"
		% [floor_h, floor_h + 0.4, -inner_w * 0.5 + loft_w - 0.125,
			-inner_w * 0.5 + loft_w + 0.125, 0.6 - 2.1, 0.6 + 2.1])
	print("  loft rail          : y %.2f..%.2f, x %.3f..%.3f, z %.2f..%.2f"
		% [loft_top, loft_top + 0.9, -inner_w * 0.5 + loft_w - 0.12,
			-inner_w * 0.5 + loft_w, 0.6 - 2.1, 0.6 + 2.1])
	for key in ["bed", "stairs_bottom", "stairs_top", "grandpa", "door"]:
		var m: Vector3 = _house.call("marker", key)
		print("  marker %-14s world %s   local %s" % [key, str(m.snapped(Vector3.ONE * 0.01)),
			str(_to_local(m).snapped(Vector3.ONE * 0.01))])
	if _sleep_prompt == null:
		_failures.append("GrandpaHouse built no SleepPrompt at all")
		return
	print("  SleepPrompt        : world %s local %s  radius=%.2f enabled=%s label='%s'"
		% [str(_sleep_prompt.global_position.snapped(Vector3.ONE * 0.01)),
			str(_to_local(_sleep_prompt.global_position).snapped(Vector3.ONE * 0.01)),
			float(_sleep_prompt.get("radius")), str(_sleep_prompt.get("enabled")),
			str(_sleep_prompt.get("label"))])


# ------------------------------------------------------------------ the walk


## Ground floor -> stair foot -> stair head -> the bed, held stick only.
func _walk_the_stair() -> void:
	print("")
	print("=== 2. a real body walks the stair, stick input only ===")
	var bottom: Vector3 = _house.call("marker", "stairs_bottom")
	var top: Vector3 = _house.call("marker", "stairs_top")
	var bed: Vector3 = _house.call("marker", "bed")

	# Start where the opening actually leaves a player who has finished with
	# Grandpa: on the ground floor near his corner, not on the stair.
	var start := _to_world(Vector3(0.0, 0.4, 1.4))
	await _place(start)
	print("  start: world %s local %s" % [str(_player.global_position.snapped(Vector3.ONE * 0.01)),
		str(_to_local(_player.global_position).snapped(Vector3.ONE * 0.01))])

	var reached_foot := await _hold_toward("stair foot", bottom, 900, 0.45)
	if not reached_foot:
		_failures.append("a body holding the stick at the stair foot never arrived")
	# Held at the stair head until the body is actually ON the loft slab --
	# a horizontal-distance arrival fires halfway up the flight, which is how
	# an earlier cut of this probe reported "arrived" from y=2.21.
	var reached_head := await _hold_toward("stair head", top, 1200, 1.0,
		float(_k("FLOOR_H")) + 0.20)
	if not reached_head:
		_failures.append("a body holding the stick at the stair head could not climb the flight")
	var on_loft := _to_local(_player.global_position).y > float(_k("FLOOR_H")) + 0.20
	print("  after the climb: local %s  on the loft slab? %s"
		% [str(_to_local(_player.global_position).snapped(Vector3.ONE * 0.01)), str(on_loft)])
	if not on_loft:
		_failures.append("the body never got onto the loft floor")
	var reached_bed := await _hold_toward("the bed", bed, 700, 1.6)
	if not reached_bed:
		_failures.append("a body on the loft holding the stick at the bed never got within 1.6m")


## Hold the stick straight at `point` and report every 30 frames what the
## interaction system is saying while we do it.
## `min_local_y`, when given, is an EXTRA arrival condition in house-local
## metres: the leg is not done until the body is that high. Without it a
## stair-head waypoint is "reached" from three treads down.
func _hold_toward(what: String, point: Vector3, frames: int, close_enough: float,
		min_local_y: float = -INF) -> bool:
	print("  -- toward %s (%s) --" % [what, str(_to_local(point).snapped(Vector3.ONE * 0.01))])
	var last := _player.global_position
	for i in frames:
		var to := point - _player.global_position
		if Vector2(to.x, to.z).length() <= close_enough and absf(to.y) < 1.2 \
				and _to_local(_player.global_position).y >= min_local_y:
			_stop()
			print("     ARRIVED after %d frames at local %s | %s"
				% [i, str(_to_local(_player.global_position).snapped(Vector3.ONE * 0.01)), _offer_line()])
			return true
		to.y = 0.0
		_push(to.normalized())
		await physics_frame
		if i % 30 == 29:
			var moved := last.distance_to(_player.global_position)
			last = _player.global_position
			print("     t=%4d local=%s  moved/30f=%.2fm  gap=%.2fm | %s"
				% [i + 1, str(_to_local(_player.global_position).snapped(Vector3.ONE * 0.01)),
					moved, Vector2(to.x, to.z).length(), _offer_line()])
	_stop()
	print("     BUDGET EXHAUSTED at local %s | %s"
		% [str(_to_local(_player.global_position).snapped(Vector3.ONE * 0.01)), _offer_line()])
	return false


## What the interaction system is offering right now, and why the bed is or
## is not part of it -- the whole point of the probe.
func _offer_line() -> String:
	var winner := str(_arbiter.call("prompt"))
	var bed_state := "no SleepPrompt"
	if _sleep_prompt != null:
		var offer: Dictionary = _sleep_prompt.call("interaction_offer", _player.global_position)
		var d := _player.global_position.distance_to(_sleep_prompt.global_position)
		bed_state = "bed d=%.2f r=%.2f enabled=%s offer=%s" % [d,
			float(_sleep_prompt.get("radius")), str(_sleep_prompt.get("enabled")),
			("YES" if not offer.is_empty() else "none")]
	return "arbiter='%s' | %s" % [winner if not winner.is_empty() else "-", bed_state]


# --------------------------------------------------------------- the pressing


func _press_interact(game: Node, progression: RefCounted) -> void:
	print("")
	print("=== 3. press interact where the walk left the body ===")
	print("  offering: %s" % _offer_line())
	progression.call("set_flag", "player_slept_at_home", false)
	var day_before := int(game.get("day"))
	var fired := bool(_arbiter.call("activate"))
	for i in 150:
		await physics_frame
	var day_after := int(game.get("day"))
	print("  activate()=%s   day %d -> %d" % [str(fired), day_before, day_after])
	if day_after <= day_before:
		_failures.append("pressing interact where the stair walk ended did not pass the night")


# ---------------------------------------------------------------- machinery


func _to_world(local: Vector3) -> Vector3:
	return _house.global_transform * local


func _to_local(world: Vector3) -> Vector3:
	return _house.global_transform.affine_inverse() * world


func _place(pos: Vector3) -> void:
	_player.global_position = pos
	_player.velocity = Vector3.ZERO
	_stop()
	for i in 30:
		await physics_frame


func _find_by_script(node: Node, path: String) -> Node:
	var script := node.get_script() as Script
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _push(direction: Vector3) -> void:
	var basis: Basis = _rig.call("planar_basis")
	var local := basis.inverse() * direction
	_stick = Vector2(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
	_drive()


func _stop() -> void:
	_stick = Vector2.ZERO
	_drive()


func _drive() -> void:
	_press_axis(&"move_right", clampf(_stick.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick.y, 0.0, 1.0))


func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	var binding := _physical_binding(action)
	var motion := binding as InputEventJoypadMotion
	if motion == null:
		return
	var m := InputEventJoypadMotion.new()
	m.axis = motion.axis
	m.axis_value = signf(motion.axis_value) * strength
	Input.parse_input_event(m)


func _physical_binding(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event
	return null

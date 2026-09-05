extends SceneTree

## CL-G12, the fast half. Same question as `probe_loft_bed_reach.gd` -- can a
## real body get from Grandpa's ground floor to his loft bed on stick input
## alone -- asked against a SYNTHETIC world holding only the house, a player,
## a camera rig and an interaction arbiter.
##
## Why a second probe rather than only the real one: booting
## `meadows_playground.tscn` costs minutes (terrain, scatter, the settlement),
## and the geometry under test is entirely `grandpa_house.gd`'s own. This one
## boots in seconds, so the stair can actually be iterated on; the real-world
## probe is what proves the finding is not an artefact of the synthetic scene.
##
##   godot --headless --path . --script tools/gate_f/probe_loft_bed_climb.gd

const GRANDPA_HOUSE := preload("res://scripts/world/grandpa_house.gd")
const CAMERA_RIG_SCRIPT := preload("res://scripts/player/camera_rig.gd")
const ARBITER_SCRIPT := preload("res://scripts/world/interaction_arbiter.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const SETTLE_FRAMES := 90

var _world: Node3D = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _house: Node3D = null
var _arbiter: Node = null
var _sleep_prompt: Node3D = null
var _failures: Array[String] = []
var _stick := Vector2.ZERO
var _diagnosed := 0
var _frozen_windows := 0


func _init() -> void:
	_run()


func _run() -> void:
	_world = Node3D.new()
	_world.name = "World"
	root.add_child(_world)
	current_scene = _world
	await process_frame

	_rig = CAMERA_RIG_SCRIPT.new() as Node3D
	_rig.name = "CameraRig"
	_world.add_child(_rig)
	var camera := Camera3D.new()
	camera.current = true
	_rig.add_child(camera)

	_player = PLAYER_SCENE.instantiate() as CharacterBody3D
	_player.name = "Player"
	_world.add_child(_player)

	_arbiter = ARBITER_SCRIPT.new()
	_arbiter.name = "InteractionArbiter"
	_world.add_child(_arbiter)
	_arbiter.call("set_player", _player)

	_house = GRANDPA_HOUSE.new()
	_house.name = "GrandpaHouse"
	_house.position = Vector3.ZERO
	_world.add_child(_house)
	_house.call("build", _rig, _player)
	# The story director is what normally opens this gate; there is none here.
	_house.call("set_door_open", true)
	_house.call("set_sleep_enabled", true)

	_player.global_position = Vector3(2.0, 0.4, 1.4)
	for i in SETTLE_FRAMES:
		await physics_frame

	_sleep_prompt = _house.get_node_or_null(^"SleepPrompt") as Node3D
	_dump_geometry()
	await _walk_the_stair()
	await _press_interact()

	print("")
	if _failures.is_empty():
		print("PROBE RESULT: the loft bed is reachable on foot in the synthetic house")
		quit(0)
		return
	print("PROBE RESULT: %d unresolved" % _failures.size())
	for f in _failures:
		print("  - %s" % f)
	quit(1)


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
	var width := float(_k("STAIR_WIDTH"))
	var loft_top_c := float(_k("LOFT_TOP"))
	var rise := loft_top_c / float(steps)
	var depth := run / float(steps)
	var start_x := -inner_w * 0.5 + loft_w + run
	var loft_top := loft_top_c
	print("  ground slab top y=0.12   loft slab top y=%.2f   loft edge x=%.2f"
		% [loft_top, -inner_w * 0.5 + loft_w])
	print("  stair: %d treads, rise %.3f, going %.3f, x %.2f..%.2f, z %.2f..%.2f"
		% [steps, rise, depth, start_x - run, start_x,
			-inner_d * 0.5 + 0.6 - width * 0.5, -inner_d * 0.5 + 0.6 + width * 0.5])
	print("  top tread top y=%.2f -> LEDGE onto the loft = %.3fm (STEP_HEIGHT 0.35)"
		% [rise * steps, loft_top - rise * steps])
	print("  north wall inner face z=%.3f; walkable stair z band %.3f..%.3f (capsule r=0.40)"
		% [-(float(_k("EXT_HALF_D")) - 0.11) + 0.225,
			-(float(_k("EXT_HALF_D")) - 0.11) + 0.225 + 0.40,
			-inner_d * 0.5 + 0.6 + width * 0.5 - 0.40])
	for key in ["bed", "stairs_bottom", "stairs_top"]:
		print("  marker %-14s local %s" % [key,
			str((_house.call("marker", key) as Vector3).snapped(Vector3.ONE * 0.01))])
	_dump_bed_solid()
	if _sleep_prompt == null:
		_failures.append("GrandpaHouse built no SleepPrompt at all")
		return
	print("  SleepPrompt local %s radius=%.2f enabled=%s label='%s'"
		% [str(_sleep_prompt.position.snapped(Vector3.ONE * 0.01)),
			float(_sleep_prompt.get("radius")), str(_sleep_prompt.get("enabled")),
			str(_sleep_prompt.get("label"))])


## The mattress collider's real footprint, read off the shape rather than
## guessed -- the wake beat stages the body against it and CURRENT_STATE's
## second P1 row says the body ends up inside it.
func _dump_bed_solid() -> void:
	var mesh: Mesh = load("res://assets/props/quaternius_furniture/BedTwin.obj")
	if mesh == null:
		print("  BedTwin.obj did not load")
		return
	var aabb := mesh.get_aabb()
	var scale_factor := float(_k("FURNITURE_SCALE"))
	print("  BedTwin.obj aabb pos=%s size=%s  (x%.2f -> %s)"
		% [str(aabb.position.snapped(Vector3.ONE * 0.001)),
			str(aabb.size.snapped(Vector3.ONE * 0.001)), scale_factor,
			str((aabb.size * scale_factor).snapped(Vector3.ONE * 0.001))])
	var bed_at := Vector3(-float(_k("INNER_W")) * 0.5 + 1.3, float(_k("FLOOR_H")) + 0.25,
		-float(_k("INNER_D")) * 0.5 + 1.9)
	var half := aabb.size * scale_factor * 0.5
	print("  mattress collider: x %.3f..%.3f  y %.3f..%.3f  z %.3f..%.3f"
		% [bed_at.x - half.x, bed_at.x + half.x, bed_at.y, bed_at.y + 0.3,
			bed_at.z - half.z, bed_at.z + half.z])
	var wake := Vector3(-float(_k("INNER_W")) * 0.5 + 1.3, float(_k("FLOOR_H")) + 0.55 + 0.05,
		-float(_k("INNER_D")) * 0.5 + 1.6 + 1.5)
	print("  WAKE staging point (bed marker + BED_LIE_REACH): %s" % str(wake.snapped(Vector3.ONE * 0.01)))
	print("  ...inside the mattress footprint? %s"
		% str(absf(wake.z - bed_at.z) <= half.z and absf(wake.x - bed_at.x) <= half.x))


func _walk_the_stair() -> void:
	print("")
	print("=== 2. a real body walks the stair, stick input only ===")
	var bottom: Vector3 = _house.call("marker", "stairs_bottom")
	var top: Vector3 = _house.call("marker", "stairs_top")
	var bed: Vector3 = _house.call("marker", "bed")
	print("  start: %s" % str(_player.global_position.snapped(Vector3.ONE * 0.01)))

	if not await _hold_toward("stair foot", bottom, 900, 0.45):
		_failures.append("a body holding the stick at the stair foot never arrived")
	# Held at the stair head until the body is actually ON the loft slab --
	# a horizontal-distance arrival fires halfway up the flight, which is how
	# an earlier cut of this probe reported "arrived" from y=2.21.
	if not await _hold_toward("stair head", top, 1200, 1.0, float(_k("FLOOR_H")) + 0.20):
		_failures.append("a body holding the stick at the stair head could not climb the flight")
	var on_loft := _player.global_position.y > float(_k("FLOOR_H")) + 0.20
	print("  after the climb: %s  on the loft slab? %s"
		% [str(_player.global_position.snapped(Vector3.ONE * 0.01)), str(on_loft)])
	if not on_loft:
		_failures.append("the body never got onto the loft floor")
	if not await _hold_toward("the bed", bed, 700, 1.6):
		_failures.append("a body on the loft holding the stick at the bed never got within 1.6m")


## `min_local_y`, when given, is an EXTRA arrival condition in house-local
## metres: the leg is not done until the body is that high. Without it a
## stair-head waypoint is "reached" from three treads down.
func _hold_toward(what: String, point: Vector3, frames: int, close_enough: float,
		min_local_y: float = -INF) -> bool:
	print("  -- toward %s (%s) --" % [what, str(point.snapped(Vector3.ONE * 0.01))])
	_diagnosed = 0
	_frozen_windows = 0
	var last := _player.global_position
	var best := INF
	for i in frames:
		var to := point - _player.global_position
		if Vector2(to.x, to.z).length() <= close_enough and absf(to.y) < 1.2 \
				and _player.global_position.y >= min_local_y:
			_stop()
			print("     ARRIVED after %d frames at %s | %s"
				% [i, str(_player.global_position.snapped(Vector3.ONE * 0.01)), _offer_line()])
			return true
		best = minf(best, Vector2(to.x, to.z).length())
		to.y = 0.0
		_push(to.normalized())
		await physics_frame
		if i % 30 == 29:
			var moved := last.distance_to(_player.global_position)
			last = _player.global_position
			print("     t=%4d pos=%s moved/30f=%.2fm gap=%.2fm floor=%s wall=%s | %s"
				% [i + 1, str(_player.global_position.snapped(Vector3.ONE * 0.01)), moved,
					Vector2(to.x, to.z).length(), str(_player.is_on_floor()),
					str(_player.is_on_wall()), _offer_line()])
			# Diagnose a REAL freeze (two consecutive half-second windows with
			# the body essentially still), not a transient scrape mid-flight.
			if moved < 0.02:
				_frozen_windows += 1
				if _frozen_windows == 2 and _diagnosed < 2:
					_diagnosed += 1
					_diagnose(to.normalized())
			else:
				_frozen_windows = 0
	_stop()
	print("     BUDGET EXHAUSTED at %s (closest %.2fm) | %s"
		% [str(_player.global_position.snapped(Vector3.ONE * 0.01)), best, _offer_line()])
	return false


## When a leg stalls, say WHY in the only terms that can be acted on: which
## static boxes the capsule is actually touching, and which of the three
## `player_controller.gd::_try_step_up` gates refuses. Colliders in
## `grandpa_house.gd` are unnamed, so each is identified by its own centre and
## box size, which is unique.
func _diagnose(direction: Vector3) -> void:
	print("     WEDGE DIAGNOSIS at %s (pushing %s)"
		% [str(_player.global_position.snapped(Vector3.ONE * 0.01)),
			str(direction.snapped(Vector3.ONE * 0.01))])
	print("       on_floor=%s on_wall=%s wall_normal=%s slides=%d"
		% [str(_player.is_on_floor()), str(_player.is_on_wall()),
			str(_player.get_wall_normal().snapped(Vector3.ONE * 0.01)),
			_player.get_slide_collision_count()])
	for i in _player.get_slide_collision_count():
		var c := _player.get_slide_collision(i)
		print("       slide %d: normal=%s collider=%s"
			% [i, str(c.get_normal().snapped(Vector3.ONE * 0.01)), _describe(c.get_collider())])
	for label in _touching():
		print("       touching: %s" % label)
	var step_h := 0.35
	var probe := direction.normalized() * 0.25
	var up := Vector3.UP * step_h
	var blocked_up := _player.test_move(_player.global_transform, up)
	var raised := _player.global_transform.translated(up)
	var blocked_fwd := _player.test_move(raised, probe)
	print("       _try_step_up gate 1 (headroom %.2fm blocked?) = %s" % [step_h, str(blocked_up)])
	print("       _try_step_up gate 2 (raised advance %.2fm blocked?) = %s"
		% [probe.length(), str(blocked_fwd)])
	if not blocked_up and not blocked_fwd:
		var forward := raised.translated(probe)
		var drop := PhysicsTestMotionResult3D.new()
		var params := PhysicsTestMotionParameters3D.new()
		params.from = forward
		params.motion = Vector3.DOWN * step_h
		var landed := PhysicsServer3D.body_test_motion(_player.get_rid(), params, drop)
		print("       _try_step_up gate 3 (lands on ground?) = %s normal=%s"
			% [str(landed), str(drop.get_collision_normal().snapped(Vector3.ONE * 0.01))])


## Every static box whose own shape overlaps a capsule-sized query at the
## body's position, described by centre and size.
func _touching() -> Array[String]:
	var out: Array[String] = []
	var space := _player.get_world_3d().direct_space_state
	var shape := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.9
	shape.shape = capsule
	shape.transform = Transform3D(Basis.IDENTITY, _player.global_position + Vector3.UP * 0.95)
	shape.collide_with_areas = false
	shape.exclude = [_player.get_rid()]
	for hit in space.intersect_shape(shape, 16):
		out.append(_describe(hit.get("collider")))
	return out


func _describe(collider: Object) -> String:
	var body := collider as Node3D
	if body == null:
		return str(collider)
	var size := "?"
	for child in body.get_children():
		var cs := child as CollisionShape3D
		if cs != null and cs.shape is BoxShape3D:
			size = str((cs.shape as BoxShape3D).size.snapped(Vector3.ONE * 0.01))
	return "%s box size=%s at %s" % [body.name, size,
		str(body.global_position.snapped(Vector3.ONE * 0.01))]


func _offer_line() -> String:
	var winner := str(_arbiter.call("prompt"))
	var bed_state := "no SleepPrompt"
	if _sleep_prompt != null:
		var offer: Dictionary = _sleep_prompt.call("interaction_offer", _player.global_position)
		var d := _player.global_position.distance_to(_sleep_prompt.global_position)
		bed_state = "bed d=%.2f r=%.2f on=%s offer=%s" % [d,
			float(_sleep_prompt.get("radius")), str(_sleep_prompt.get("enabled")),
			("YES" if not offer.is_empty() else "none")]
	return "arbiter='%s' | %s" % [winner if not winner.is_empty() else "-", bed_state]


func _press_interact() -> void:
	print("")
	print("=== 3. press interact where the walk left the body ===")
	print("  offering: %s" % _offer_line())
	var fired := bool(_arbiter.call("activate"))
	print("  arbiter.activate() = %s" % str(fired))
	if not fired:
		_failures.append("pressing interact where the stair walk ended activated nothing")
	await physics_frame


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

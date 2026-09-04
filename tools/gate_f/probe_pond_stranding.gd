extends SceneTree

## GATE2-EVIDENCE-0903. Is the Pond arrival trapping the player, or is the
## harness walker too naive to leave it?
##
##   godot --headless --path . --script tools/gate_f/probe_pond_stranding.gd
##
## The Gate 2 evidence run's S05 walked the authored route out of the village
## to the Pond, arrived (the `move_to` for the pond target reported ARRIVED),
## and then spent its entire 29,250-frame detour budget travelling 25 m --
## frozen at (-328.8, -14.17, 505.4) to a tenth of a metre for 500 play
## seconds, with the harness reporting "0 held", i.e. locomotion was ENABLED
## the whole time. Reproduced twice, on two independent runs from the same
## save.
##
## `docs/HANDOFF_2026-09-03.md` names the trap this probe exists to avoid:
## "Harness defects that look exactly like game defects... Before believing a
## failure describes the game, ask what the harness did to produce it. The
## inverse error is also live, so do not assume the harness is wrong either."
## The South Bridge "entombment" was a harness teleport outrunning Terrain3D's
## collision; the settlement fence corner was a real concave corner the walker
## could not round. This probe separates those two by never using the walker
## at all.
##
## Method, deliberately below the walker: place the real player body at a ring
## of points around the stall coordinate, let physics settle, then inject a
## REAL left-stick deflection (`InputEventJoypadMotion` through the live
## InputMap, the same path `stick_navigator.gd` and every smoke uses) in eight
## compass directions in turn, and measure how far the body actually travels.
## A body that will not move in ANY direction under a full-deflection stick is
## wedged by the world. A body that moves freely in most directions is a
## navigation problem, not a world hole -- and the directions it refuses name
## what is holding it.
##
## Also reported per stand, because they are what distinguishes the two:
##   * the authored ground height (`playground_world.gd::ground_height_at`)
##     against where the body actually settles -- a body resting well above or
##     below the heightfield is on something else, or on nothing;
##   * whether the body is on the floor, and every collider actually touching
##     it, by name and class, from the real `KinematicCollision3D` records.

const SCENE := "res://scenes/world/meadows_playground.tscn"

## Where S05 froze, and the pond arrival target it froze next to.
const STALL := Vector2(-328.8, 505.4)
const POND_TARGET := Vector2(-342.0, 507.0)
## S05's next waypoint after the pond: the Old Bram detour. The stall happened
## on the leg to this point, so this is the bearing that actually mattered.
const DETOUR_TARGET := Vector2(195.0, 905.0)

const RING_RADIUS := 6.0
const SETTLE_FRAMES := 300
const PLACE_SETTLE_FRAMES := 90
const PUSH_FRAMES := 120

var _world: Node = null
var _player: CharacterBody3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _find_player(_world)
	if _player == null:
		print("PROBE FAIL: no Player body in the scene")
		quit(1)
		return

	print("=== pond stranding probe ===")
	print("stall point (%.1f, %.1f); pond target (%.1f, %.1f); detour bearing toward (%.0f, %.0f)"
		% [STALL.x, STALL.y, POND_TARGET.x, POND_TARGET.y, DETOUR_TARGET.x, DETOUR_TARGET.y])
	print("")

	var stands := {"stall": STALL, "pond_target": POND_TARGET}
	for i in 8:
		var angle := TAU * float(i) / 8.0
		stands["ring_%03d" % int(rad_to_deg(angle))] = STALL + Vector2(cos(angle), sin(angle)) * RING_RADIUS

	var trapped := 0
	for name: String in stands.keys():
		await _report_stand(name, stands[name] as Vector2)
		if _last_stand_trapped:
			trapped += 1
	print("")
	print("VERDICT INPUT: %d of %d stands could not move in ANY of eight directions."
		% [trapped, stands.size()])
	print("A world hole traps every bearing; a navigation problem leaves most bearings open.")
	quit(0)


var _last_stand_trapped := false


func _report_stand(label: String, at: Vector2) -> void:
	var ground := _ground_at(at)
	_place(at, ground + 1.0)
	for i in PLACE_SETTLE_FRAMES:
		await physics_frame
	var settled := _player.global_position
	print("--- %s at (%.1f, %.1f)" % [label, at.x, at.y])
	print("    authored ground %.2f; body settled at y %.2f (delta %+.2f); on_floor=%s"
		% [ground, settled.y, settled.y - ground, str(_player.is_on_floor())])
	var touching := _touching()
	print("    touching: %s" % ("nothing" if touching.is_empty() else ", ".join(touching)))

	var best := 0.0
	var moved: Array[String] = []
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var dir := Vector2(cos(angle), sin(angle))
		_place(at, ground + 1.0)
		for f in 30:
			await physics_frame
		var before := _player.global_position
		_stick(dir.x, dir.y)
		for f in PUSH_FRAMES:
			await physics_frame
		_stick(0.0, 0.0)
		for f in 5:
			await physics_frame
		var after := _player.global_position
		var travelled := Vector2(after.x - before.x, after.z - before.z).length()
		best = maxf(best, travelled)
		if travelled >= 1.0:
			moved.append("%03d:%.1fm" % [int(rad_to_deg(angle)), travelled])
	_last_stand_trapped = best < 1.0
	print("    stick push, 8 bearings, %d frames each: best %.2f m; moved: %s"
		% [PUSH_FRAMES, best, ("NONE -- wedged" if moved.is_empty() else ", ".join(moved))])


func _touching() -> Array[String]:
	var out: Array[String] = []
	for i in _player.get_slide_collision_count():
		var c := _player.get_slide_collision(i)
		var collider := c.get_collider()
		if collider == null:
			continue
		out.append("%s (%s)" % [str((collider as Node).name if collider is Node else collider),
			collider.get_class()])
	return out


func _place(at: Vector2, y: float) -> void:
	_player.global_position = Vector3(at.x, y, at.y)
	_player.velocity = Vector3.ZERO
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.global_position = _player.global_position


func _ground_at(at: Vector2) -> float:
	if _world.has_method("ground_height_at"):
		var h := float(_world.call("ground_height_at", at.x, at.y))
		if not is_nan(h):
			return h
	return 0.0


func _stick(x: float, y: float) -> void:
	_axis(JOY_AXIS_LEFT_X, x)
	_axis(JOY_AXIS_LEFT_Y, y)


func _axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _find_player(from: Node) -> CharacterBody3D:
	if from is CharacterBody3D and str(from.name) == "Player":
		return from as CharacterBody3D
	for child in from.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null

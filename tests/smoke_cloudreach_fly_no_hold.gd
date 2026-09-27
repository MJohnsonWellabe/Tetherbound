extends SceneTree

## SYSTEMS Fly no-hold climb + interim `fly_descend` toggle (#356), with real
## input events on the production Player over real collision. Fixture world
## (floor, one authored updraft off to the side); not route evidence.
##
##   godot --headless --path . --script tests/smoke_cloudreach_fly_no_hold.gd
##
## Prints `FLY NO HOLD: n assertions, m failures`; exit 0 on pass.

const PLAYER := preload("res://scenes/player/player.tscn")
const CAMERA := preload("res://scripts/player/camera_rig.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const UPDRAFT := AABB(Vector3(30, 0, -10), Vector3(20, 40, 20))
var world: Node3D
var player: CharacterBody3D
var fly: Node
var game: Node
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	game = root.get_node("Game")
	game.current_realm = "cloudreach"
	game.pending_realm_entry = ""
	game.saved_player_pose = {}
	game.party = PARTY.new()
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		game.party.add(SPECIES.spawn(species))
	game.party.set_active(4)
	game.progression.set_flag("fly_traversal_unlocked")
	_build_world()
	await _frames(60)
	_check(player.is_on_floor(), "fixture starts on the floor")

	# 1. Held A: exactly one pulse, then the flyer sinks again.
	player.vitals.rest()
	await _deploy()
	_check(fly.is_flying(), "double jump deploys Fly")
	var start_y := player.global_position.y
	_action("jump", true)
	var peak := start_y
	var pulse_frames := 0
	var pulse_speed_ok := true
	for i in 90:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
		if fly.state == "climb":
			pulse_frames += 1
			pulse_speed_ok = pulse_speed_ok and absf(player.velocity.y - 8.0) < 0.01
	var end_y := player.global_position.y
	_action("jump", false)
	# 0.5 s at 8 m/s is 4 m; the existing vertical easing (12 m/s^2) then
	# coasts the last 8 m/s off (~2.7 m) before the ordinary sink resumes.
	_check(peak - start_y > 3.5 and peak - start_y < 7.5,
		"one A press climbs one 0.5 s pulse at 8 m/s plus its coast (%.2f m)" % (peak - start_y))
	_check(pulse_frames >= 28 and pulse_frames <= 32, "the pulse lasts 0.5 s (%d frames at 60 Hz)" % pulse_frames)
	_check(pulse_speed_ok, "the pulse climbs AT 8 m/s for its whole duration")
	_check(end_y < peak - 0.3, "holding A does not repeat the climb (peak %.2f, after 1.5 s %.2f)" % [peak, end_y])

	# 2. A fresh tap refreshes to 0.5 s and never stacks.
	await _tap("jump")
	await _frames(12)
	var before_refresh := float(fly.climb_pulse_left)
	await _tap("jump")
	var after_refresh := float(fly.climb_pulse_left)
	_check(before_refresh > 0.0 and before_refresh < 0.45, "the first pulse was running down (%.2f s)" % before_refresh)
	_check(after_refresh <= 0.5 + 0.001 and after_refresh > 0.45, "a fresh tap refreshes to 0.5 s, not more (%.2f s)" % after_refresh)

	# 3. Climb pays climb stamina while the pulse runs.
	player.vitals.stamina = 50.0
	await _tap("jump")
	var climb_from := float(player.vitals.stamina)
	await _frames(20)
	var climb_spent := climb_from - float(player.vitals.stamina)
	await _frames(40)
	var glide_from := float(player.vitals.stamina)
	await _frames(20)
	var glide_spent := glide_from - float(player.vitals.stamina)
	_check(climb_spent > glide_spent * 1.3, "the pulse pays climb stamina (%.3f vs glide %.3f over 1/3 s)" % [climb_spent, glide_spent])

	# 4. LT tap toggles a descent that lasts with nothing held, until landing.
	await _tap("fly_descend")
	await _frames(30)
	_check(fly.state == "descent", "one LT tap keeps descending with no button held")
	for i in 600:
		await physics_frame
		if player.is_on_floor() and not fly.is_flying():
			break
	_check(not fly.is_flying() and player.is_on_floor(), "the toggled descent ends on the floor")
	_check(not bool(fly.descend_toggled), "landing clears the toggle")

	# 5. The next LT tap ends the descent in the air.
	player.vitals.rest()
	await _deploy()
	await _tap("jump")
	await _frames(20)
	await _tap("fly_descend")
	await _frames(10)
	_check(fly.state == "descent", "LT tap descends")
	await _tap("fly_descend")
	await _frames(5)
	_check(fly.is_flying() and fly.state == "glide", "the next LT tap returns to the glide (%s)" % fly.state)
	for i in 900:
		await physics_frame
		if not fly.is_flying():
			break

	# 6. One tap inside an authored updraft rides it to its roof, no hold.
	player.vitals.rest()
	player.global_position = Vector3(40, 0.2, 0)
	player.velocity = Vector3.ZERO
	await _frames(20)
	await _deploy()
	await _tap("jump")
	var ride_peak := player.global_position.y
	for i in 240:
		await physics_frame
		ride_peak = maxf(ride_peak, player.global_position.y)
	_check(ride_peak > 12.0, "a single tap in the current climbs well past one pulse (%.2f m)" % ride_peak)
	_check(ride_peak <= 18.3, "the authored roof still caps the ride (%.2f m)" % ride_peak)

	for action: String in ["jump", "fly_descend"]:
		_action(action, false)
	world.free()
	for failure: String in failures:
		printerr("FAIL: " + failure)
	print("FLY NO HOLD: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _build_world() -> void:
	world = Node3D.new()
	world.name = "FlyNoHoldFixture"
	root.add_child(world)
	_box("Floor", Vector3(0, -1, 0), Vector3(200, 2, 200))
	var rig := SpringArm3D.new()
	rig.name = "CameraRig"
	rig.set_script(CAMERA)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	player = PLAYER.instantiate()
	player.position = Vector3(0, 0.1, 0)
	world.add_child(player)
	fly = player.fly_controller
	fly.register_updraft("fixture", UPDRAFT, 12.0, 20.0)


func _box(id: String, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = id
	body.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	world.add_child(body)


func _deploy() -> void:
	await _tap("jump")
	await _frames(7)
	await _tap("jump")
	await _frames(3)


func _tap(action: String) -> void:
	_action(action, true)
	await _frames(1)
	_action(action, false)
	await _frames(1)


func _action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)

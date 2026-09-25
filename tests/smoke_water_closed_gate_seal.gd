extends SceneTree

## Production Water scene/body/input smoke for the closed-gate flank repair
## (WORLD §6.1, F12). Replays the reproduced Tidal Cradle flank: with the
## shared `water_aquaryn_resolved` fact missing, walk around the dock barrier
## and swim at the first rest shoal, then straight at the second. The tide race
## must turn the swimmer back without a landing. Then the shared fact alone is
## set and the same swimmer, from where the race left them, lands on the shoal.
##
## Disclosed fixtures: the four earlier Water dock facts are set directly (no
## earned story), and one initial position write places the player on the
## Cradle departure anchor. All later movement is real action input.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const EARLIER := [
	"water_swim_lesson_complete",
	"water_dock_reedhaven_repaired",
	"water_dock_brine_steps_trial_won",
	"water_dock_shellwatch_residents_freed_and_pump_disabled",
]
const GATE := "water_aquaryn_resolved"
# Open-water flank outside both closed departure strips, south-west of the
# barrier: beach 22 m lateral of the sheltered line, then water 45 m along and
# 22 m lateral (sheltered half-width 9 m, direct 14 m), 52 m from the shoal.
const FLANK_BEACH := Vector3(540.0, 0.0, 1722.7)
const FLANK_WATER := Vector3(500.68, 0.0, 1750.3)

var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var swimming: Node
var assertions := 0
var finished := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(240.0).timeout.connect(func() -> void:
		if not finished:
			_fail("240 second watchdog expired"))
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_water_closed_gate_seal_fixture")
	game.current_realm = "water"
	for flag: String in EARLIER:
		game.world.flags.call("set_flag", flag, true)
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 600:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _expect(bool(world.call("shell_build_complete")), "Water shell failed to build"):
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	var races: Node = world.get_node_or_null("WaterGateTideRaces")
	if not _expect(swimming != null and races != null, "production swim controller or tide races missing"):
		return
	var config: Dictionary = world.get("config")
	var departure := _anchor(config, "tidal_cradle_to_salt_crown_departure")
	var shoal := _anchor(config, "tidal_cradle_to_salt_crown_rest_01")
	var second := _anchor(config, "tidal_cradle_to_salt_crown_rest_02")
	if not _expect(departure.is_finite() and shoal.is_finite() and second.is_finite(), "Cradle anchors missing"):
		return
	if not _expect(not game.world.flags.has(GATE), "gate fixture must start closed"):
		return
	if not _expect(bool(races.call("is_race_visible", "tidal_cradle_to_salt_crown_rest_01"))
			and bool(races.call("is_race_visible", "salt_crown")), "closed tide races are not visible"):
		return
	if not _expect(not bool(races.call("is_race_visible", "tidal_cradle")), "opened Cradle still shows a race"):
		return
	var fly: Node = player.get_node_or_null("FlyController")
	var closed_flight := int(races.get("flight_restrictions"))
	if not _expect(fly != null and closed_flight > 0 and (fly.get("restrictions") as Array).size() >= closed_flight,
		"sealed discs are not registered with this trainer's Fly controller"):
		return
	departure.y = float(world.call("ground_height_at", departure.x, departure.z)) + 0.15
	player.global_position = departure
	player.velocity = Vector3.ZERO
	await _frames(45)
	if not _expect(player.is_on_floor() and not swimming.is_swimming(), "departure anchor did not settle dry"):
		return
	var vitals: RefCounted = player.get("vitals")
	# Walk past the barrier's end on the beach, then swim outside both strips.
	var beach_reached := await _attempt(FLANK_BEACH, 1.5, 900)
	if not _expect(beach_reached <= 1.5, "could not walk around the barrier: %.2f m" % beach_reached):
		return
	var water_reached := await _attempt(FLANK_WATER, 1.5, 20 * Engine.physics_ticks_per_second)
	if not _expect(water_reached <= 1.5 and swimming.is_swimming(),
		"could not swim the open-water flank outside the strips: %.2f m" % water_reached):
		return
	var flank_sample: Dictionary = world.currents.sample(player.global_position)
	if not _expect(Vector3(flank_sample.velocity).length() < 0.5, "flank point is not open water: %s" % flank_sample):
		return
	var shoal_radius := 20.0
	var wading := 0.9 / 0.35
	var closest := await _attempt(shoal, 0.5, 20 * Engine.physics_ticks_per_second)
	if not _expect(closest > shoal_radius + wading,
		"closed race let the swimmer reach %.2f m from the first shoal centre" % closest):
		return
	if not _expect(not _dry_on(shoal, shoal_radius), "swimmer landed on the first shoal while closed"):
		return
	var second_closest := await _attempt(second, 0.5, 10 * Engine.physics_ticks_per_second)
	if not _expect(second_closest > shoal_radius + wading,
		"closed race let the swimmer reach %.2f m from the second shoal centre" % second_closest):
		return
	if not _expect(swimming.is_swimming(), "fixture expected the swimmer still in open water"):
		return
	var explanation := str(races.get("last_message"))
	if not _expect(explanation == "The tide race on the Salt Crown crossing throws you back. Clear the Tidal Cradle dock first.",
		"swimmer was not told why the race turned them back: '%s'" % explanation):
		return
	var stamina_when_opened: float = vitals.stamina
	# Only the shared departure fact changes. The race must clear on its own.
	game.world.flags.call("set_flag", GATE, true)
	await _frames(2)
	if not _expect(not bool(races.call("is_race_visible", "tidal_cradle_to_salt_crown_rest_01")),
		"opened gate still shows the first shoal race"):
		return
	if not _expect(int(races.get("flight_restrictions")) < closed_flight,
		"opening the gate did not release its Fly restrictions"):
		return
	var landed := await _attempt(shoal, 1.0, 40 * Engine.physics_ticks_per_second)
	if not _expect(landed <= 1.0, "open gate swimmer did not reach the first shoal centre: %.2f" % landed):
		return
	await _frames(30)
	if not _expect(player.is_on_floor() and not swimming.is_swimming() and _dry_on(shoal, shoal_radius),
		"open gate swimmer did not stand dry on the first shoal"):
		return
	if not _expect(Vector2(swimming.state.safe_landing.x - shoal.x, swimming.state.safe_landing.z - shoal.z).length() < 6.0,
		"first shoal did not become the safe landing"):
		return
	finished = true
	print("WATER CLOSED GATE SEAL OK assertions=%d closed_first_closest_m=%.2f closed_second_closest_m=%.2f stamina_at_open=%.2f health=%.2f explanation='%s'" % [
		assertions, closest, second_closest, stamina_when_opened, vitals.health, explanation])
	quit(0)


func _dry_on(centre: Vector3, radius: float) -> bool:
	var offset := player.global_position - centre
	offset.y = 0.0
	return offset.length() <= radius and player.is_on_floor() and not swimming.is_swimming()


## Steers with real input toward `target`; never fails on timeout. Returns the
## closest horizontal approach reached.
func _attempt(target: Vector3, tolerance: float, frame_limit: int) -> float:
	var closest := INF
	for _frame in frame_limit:
		var offset := target - player.global_position
		offset.y = 0.0
		closest = minf(closest, offset.length())
		if offset.length() <= tolerance:
			break
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
		if float(player.get("vitals").health) <= 0.0:
			_fail("died while steering toward %s from %s" % [target, player.global_position])
			return -1.0
	_action(false)
	await _frames(2)
	return closest


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _anchor(config: Dictionary, id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.id) == id:
			return Vector3(float(anchor.safe_position[0]), float(anchor.safe_position[1]), float(anchor.safe_position[2]))
	return Vector3.INF


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _expect(condition: bool, message: String) -> bool:
	assertions += 1
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	_action(false)
	finished = true
	push_error("WATER CLOSED GATE SEAL: " + message)
	quit(1)
	return false

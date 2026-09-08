extends SceneTree

## Bounded chapter-entry diagnostic, NOT fresh-save campaign acceptance.
## The default fixture is an empty solo Water realm at its production arrival;
## --through-reedhaven supplies only disclosed pre-arrival knife/axe hotbar tools.
## --through-brine additionally carries the disclosed synthetic level-44 party.
## --through-shellwatch retains that same state and party without another fixture.
## --through-tidal-recipe continues only to Alpha defeat and Iona's recipe.
## No actor pose, Water fact, inventory, HP or stamina is injected after arrival.
## The player walks to Pell, finishes his real dialogue, then earns the physical lesson.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const REEDHAVEN := preload("res://tests/helpers/water_reedhaven_segment.gd")
const BRINE := preload("res://tests/helpers/water_brine_segment.gd")
const SHELLWATCH := preload("res://tests/helpers/water_shellwatch_segment.gd")
const TIDAL := preload("res://tests/helpers/water_tidal_segment.gd")
const BRINE_PARTY: Array[String] = [
	"sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail",
]
const BRINE_PARTY_LEVEL := 44
var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var navigator: RefCounted
var finished := false
var activated: Object
var swim_metres := 0.0
var through_reedhaven := false
var through_brine := false
var through_shellwatch := false
var through_tidal_recipe := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var selection := requested_segments(OS.get_cmdline_user_args())
	through_reedhaven = bool(selection.through_reedhaven)
	through_brine = bool(selection.through_brine)
	through_shellwatch = bool(selection.through_shellwatch)
	through_tidal_recipe = bool(selection.through_tidal_recipe)
	_watchdog.call_deferred()
	game = root.get_node("Game")
	var scratch_dir := "user://water_opening_continuous_%d/" % Time.get_ticks_usec()
	game.save_system = SAVE.new(scratch_dir)
	game.reset_for_new_game()
	if str(game.save_system.slot_path(0)) != scratch_dir + "slot_0.json":
		_fail("Opening did not retain its test-owned save binding")
		return
	print("WATER OPENING SAVE: " + ProjectSettings.globalize_path(scratch_dir))
	game.current_realm = "water"
	# Optional composition fixture, before world/arrival: tools carried from
	# the prior chapter. Never grant Water materials or replace earned lesson
	# progress. The reusable Reedhaven segment itself grants nothing.
	if through_reedhaven:
		if game.inventory.add("axe", 1) != 0 or game.inventory.add("knife", 1) != 0 \
				or game.inventory.count("axe") != 1 or game.inventory.count("knife") != 1:
			_fail("Could not create disclosed pre-arrival knife/axe fixture")
			return
		game.assign_hotbar(0, "axe")
		game.assign_hotbar(1, "knife")
		print("WATER OPENING FIXTURE: pre-arrival knife/axe for optional Reedhaven; no Water materials/progress")
	if through_brine:
		for species_id: String in BRINE_PARTY:
			var creature: RefCounted = SPECIES.spawn(species_id)
			if creature == null:
				_fail("Could not construct disclosed Brine party member " + species_id)
				return
			creature.set_level(BRINE_PARTY_LEVEL, PROGRESSION.config())
			if not game.local.party.add(creature):
				_fail("Could not add disclosed Brine party member " + species_id)
				return
		print("WATER OPENING FIXTURE: synthetic carried level-44 party %s; not an earned Stormwood handoff" %
			str(BRINE_PARTY))
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 1200:
		if world.shell_build_complete():
			break
		await physics_frame
	if not world.shell_build_complete():
		_fail("Water shell did not become ready")
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	navigator = NAV.new(self, player, camera, _stick)
	await _frames(30)
	var arrival: Vector3 = world.entry_anchor("from_stormwood")
	if not arrival.is_finite() or not player.is_on_floor() or player.global_position.distance_to(arrival) > 3.0:
		_fail("Production arrival did not settle at First Shore: player=%s expected=%s" % [player.global_position, arrival])
		return
	print("WATER OPENING ARRIVED: production pose=%s; fixture tools=%s synthetic_party=%s, not earned Stormwood transition" % [
		player.global_position, through_reedhaven, through_brine])
	if game.world.flags.has("water_swim_lesson_complete") or game.local.flags.has("water_swim_lesson_briefed"):
		_fail("Opening fixture already contains lesson progress")
		return
	var pell := world.find_child("water_pell", true, false) as Node3D
	if pell == null:
		_fail("Pell's production body is absent")
		return
	var prompt := pell.call("prompt_node") as Node3D
	var arbiter: Node = world.get_node("InteractionArbiter")
	arbiter.activated.connect(func(provider: Object) -> void: activated = provider)
	var greeted := false
	for stance in 8:
		var angle := TAU * float(stance) / 8.0
		var point := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.3
		point.y = world.ground_height_at(point.x, point.z) + 0.1
		if not await _walk(point, "Pell grounded interaction stance"):
			return
		await _frames(8)
		if arbiter.call("winning_provider") != prompt:
			continue
		activated = null
		await _tap("interact")
		if activated == prompt:
			greeted = true
			break
	if not greeted:
		_fail("Pell never received the actual arbiter interaction: %s" % str(arbiter.call("winner")))
		return
	var panel: Node = world.get_node("DialoguePanel")
	if not panel.is_open():
		_fail("Pell interaction did not open dialogue")
		return
	for line in 30:
		if not panel.is_open():
			break
		await _tap("interact")
	if panel.is_open() or not game.local.flags.has("water_swim_lesson_briefed"):
		_fail("Controller dialogue did not earn Pell's briefing")
		return
	print("WATER OPENING BRIEFED through Pell's production dialogue")
	var spec: Dictionary = world.config.swim_lesson
	if not await _walk(_anchor(str(spec.start_anchor)), "west lesson landing"):
		return
	var first := _v(spec.surface_polyline[0])
	var last := _v(spec.surface_polyline[-1])
	if not await _swim_to(first):
		return
	swim_metres = 0.0
	if not await _swim_to(last):
		return
	if not await _swim_to(_anchor(str(spec.end_anchor))):
		return
	await _frames(20)
	if not game.world.flags.has("water_swim_lesson_complete") or swim_metres < 50.0:
		_fail("Ordinary crossing did not earn the lesson flag; observed swimming=%.3fm" % swim_metres)
		return
	if not player.is_on_floor() or player.swim_controller.is_swimming():
		_fail("Lesson completion did not end at dry grounded landing")
		return
	print("WATER OPENING PASS: arrival -> Pell -> physical lesson; swimming=%.3fm; no post-arrival fixture writes" % swim_metres)
	if through_reedhaven:
		var segment := REEDHAVEN.new()
		segment.setup(self, world, player, camera)
		var repaired: bool = await segment.run()
		print("WATER REEDHAVEN RESULT: %s" % str(segment.result()))
		if not repaired or not bool(segment.result().ok):
			_fail("Ordinary Reedhaven continuation failed; inspect its exact result above")
			return
		print("WATER OPENING THROUGH REEDHAVEN PASS: paid repair earned through ordinary crossing and gathering")
	if through_brine:
		var brine := BRINE.new()
		brine.setup(self, world, player, camera)
		var trial_won: bool = await brine.run()
		print("WATER BRINE RESULT: %s" % str(brine.result()))
		if not trial_won or not bool(brine.result().ok):
			_fail("Ordinary Brine continuation failed; inspect its exact result above")
			return
		print("WATER OPENING THROUGH BRINE PASS: Tovin and dock trial flags earned")
	if through_shellwatch:
		var shellwatch := SHELLWATCH.new()
		shellwatch.setup(self, world, player, camera)
		var shellwatch_open: bool = await shellwatch.run()
		print("WATER SHELLWATCH RESULT: %s" % str(shellwatch.result()))
		if not shellwatch_open or not bool(shellwatch.result().ok):
			_fail("Ordinary Shellwatch continuation failed; inspect its exact result above")
			return
		print("WATER OPENING THROUGH SHELLWATCH PASS: residents, pump and next dock resolved")
	if through_tidal_recipe:
		var tidal := TIDAL.new()
		tidal.setup(self, world, player, camera)
		var recipe_earned: bool = await tidal.run()
		print("WATER TIDAL RESULT: %s" % str(tidal.result()))
		if not recipe_earned or not bool(tidal.result().ok):
			_fail("Ordinary Tidal recipe continuation failed; inspect exact result above")
			return
		print("WATER OPENING THROUGH TIDAL RECIPE PASS: Alpha/Stone/recipe earned; saddle/capture/mounted suffix unproven")
	finished = true
	quit(0)


static func requested_segments(args: PackedStringArray) -> Dictionary:
	var wants_tidal := "--through-tidal-recipe" in args
	var wants_shellwatch := wants_tidal or "--through-shellwatch" in args
	var wants_brine := wants_shellwatch or "--through-brine" in args
	return {
		"through_tidal_recipe": wants_tidal,
		"through_shellwatch": wants_shellwatch,
		"through_brine": wants_brine,
		"through_reedhaven": wants_brine or "--through-reedhaven" in args,
	}

func _walk(point: Vector3, label: String) -> bool:
	if not point.is_finite():
		return _fail(label + " target is not finite")
	var distance := player.global_position.distance_to(point)
	var arrived: bool = await navigator.walk_to(point, maxi(1200, int(distance * 65)), 1.0)
	_stick(0, 0)
	if not arrived or navigator.confined_resets() > 0:
		return _fail("%s failed: player=%s target=%s resets=%d" % [label, player.global_position, point, navigator.confined_resets()])
	return true

func _swim_to(point: Vector3) -> bool:
	var previous := player.global_position
	for frame in 2400:
		var offset := point - player.global_position
		offset.y = 0
		if offset.length() < 0.5:
			_stick(0, 0)
			return true
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_stick(0, -1)
		await physics_frame
		if player.swim_controller.is_swimming():
			swim_metres += Vector2(player.global_position.x - previous.x, player.global_position.z - previous.z).length()
		previous = player.global_position
		if player.vitals.health <= 0:
			return _fail("Player died during ordinary lesson approach/crossing")
	return _fail("Lesson movement stalled: player=%s target=%s" % [player.global_position, point])

func _anchor(id: String) -> Vector3:
	for row: Dictionary in world.config.anchors:
		if str(row.id) == id:
			var point := _v(row.safe_position)
			point.y = world.ground_height_at(point.x, point.z) + 0.15
			return point
	return Vector3.INF

func _v(row: Array) -> Vector3:
	return Vector3(float(row[0]), float(row[1]), float(row[2]))

func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)

func _tap(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(8)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _fail(reason: String) -> bool:
	_stick(0, 0)
	finished = true
	print("WATER OPENING FAIL: " + reason)
	quit(1)
	return false

func _watchdog() -> void:
	await create_timer(1200.0 if through_reedhaven else 600.0).timeout
	if not finished:
		_fail("Opening watchdog expired (20 minutes with Reedhaven; 10 minutes lesson-only)")

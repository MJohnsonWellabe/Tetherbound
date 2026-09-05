extends SceneTree

## Isolated real Player/CharacterBody + Fly + Interactable/input fixture.
## Repositions between stations; does not claim continuous chapter travel.
const PLAYER := preload("res://scenes/player/player.tscn")
const CAMERA := preload("res://scripts/player/camera_rig.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const PHYSICAL := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

var world: Node3D
var player: CharacterBody3D
var physical: Node3D
var fly: Node
var events: Node
var game: Node
var failures: Array[String] = []
var assertions := 0
var payout_count := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	game = root.get_node("Game")
	game.current_realm = "cloudreach"
	game.pending_realm_entry = ""
	game.saved_player_pose = {}
	game.progression = FLAGS.new()
	game.party = PARTY.new()
	# Existing installed capability fixture, no species assumption in runtime.
	game.party.add(SPECIES.spawn("galecrest"))
	_build()
	await _frames(40)
	_check(player.is_on_floor(), "real grounded Player fixture")
	_check(not physical.activate("aerie_repair"), "repair refuses missing prerequisites")
	_check(not physical.encounter_won("invented_opponent"), "unknown encounter cannot grant progress")
	game.progression.set_flag("realm_key_cloudreach")
	game.progression.set_flag("cloudreach_chapter_started")
	game.progression.set_flag("cloudreach_crisis_learned")
	game.progression.set_flag("cloudreach_lower_anchors_investigated")
	_check(physical.encounter_won("tether_lieutenant_senn"), "trusted real-win seam accepts correct encounter")
	_check(physical.encounter_won("tether_lieutenant_senn") and payout_count == 1, "duplicate win pays only once")
	game.progression.set_flag("causeway_survivors_reconnected")
	_check(physical.encounter_won("keeper_maela_trial"), "mentor battle records separately")
	_check(not game.progression.has("fly_traversal_unlocked"), "mentor battle alone cannot unlock Fly")
	game.inventory.remove("gale_fiber", game.inventory.count("gale_fiber"))
	await _walk_to(Vector3(5,0,0))
	await _interact()
	_check(not game.progression.has("windscar_aerie_prepared"), "real interact rejects insufficient fiber")
	game.inventory.add("gale_fiber", 3)
	await _interact()
	_check(game.progression.has("windscar_aerie_prepared"), "real input restores perch with fiber")
	_check(game.inventory.count("gale_fiber") == 0, "repair consumes exact cost once")
	_check(not physical.activate("aerie_repair"), "completed repair cannot spend again")
	_check(physical.consume_dialogue_effect("cloudreach:cloudreach_maela_flight_trial_ready"), "Maela readiness advances Act I")
	_check(not game.progression.has("fly_traversal_unlocked"), "readiness only authorizes a trial")
	await _walk_to(Vector3(0,0,0))
	await _interact()
	_check(physical.trial_active, "real launch-marker input authorizes bounded trial")
	var feed_before_trial: int = game.progression_feed.revision
	await _deploy()
	_check(fly.is_flying(), "two airborne Jump presses use production Fly")
	_action("jump", true)
	for i in 180:
		await physics_frame
		if player.position.y >= 5.0:
			break
	_action("jump", false)
	_action("move_right", true)
	for i in 300:
		await physics_frame
		_action("jump", player.position.y < 5.0)
		if physical.trial_gate_index == 3:
			break
	_action("move_right", false)
	_action("jump", false)
	_check(physical.trial_gate_index == 3, "real collision-body movement crosses three ordered wind gates (gate=%s state=%s position=%s)" % [physical.trial_gate_index, fly.state, player.position])
	_action("fly_descend", true)
	for i in 180:
		await physics_frame
		if player.is_on_floor() and not fly.is_flying():
			break
	_action("fly_descend", false)
	await _frames(3)
	_check(game.progression.has("fly_traversal_unlocked"), "full gate route plus real landing unlocks Fly")
	_check(not physical.trial_active, "trial authorization is revoked after success")
	var route_events: Array = game.progression_feed.since(feed_before_trial).filter(func(event: Dictionary) -> bool: return str(event.get("source", "")) == "fly_route")
	_check(route_events.size() == 1, "legitimate authored trial landing emits one shared Fly-route bond credit")
	if route_events.size() == 1:
		_check(is_equal_approx(float(route_events[0].after) - float(route_events[0].before), 25.0), "Fly-route credit uses the configured small travel bonus")
	var before_duplicate: int = game.progression_feed.revision
	physical._on_landed(player.global_position, "galecrest")
	_check(game.progression_feed.revision == before_duplicate, "replaying a landing cannot farm bond credit")
	_check(not game.progression.has("sky_shrine_reached"), "unrelated trial landing does not fabricate High Roost arrival")
	_check(not physical.consume_dialogue_effect("cloudreach:cloudreach_sora_storm_engine_truth"), "Sora truth refuses missing shrine and vanes")
	# This second flight uses a scaled landing destination in the same fixture;
	# it exercises real floor contact, not the full authored mountain crossing.
	player.vitals.rest()
	await _deploy()
	_action("jump", true)
	for i in 150:
		await physics_frame
		if player.position.y >= 5:
			break
	_action("jump", false)
	_action("move_right", true)
	for i in 180:
		await physics_frame
		if player.position.x >= 51:
			break
	_action("move_right", false)
	_action("fly_descend", true)
	for i in 180:
		await physics_frame
		if player.is_on_floor() and not fly.is_flying():
			break
	_action("fly_descend", false)
	_check(game.progression.has("sky_shrine_reached"), "observed Fly followed by actual destination floor contact records shrine arrival")
	for id: String in ["shrine_vane_west", "shrine_vane_east", "shrine_vane_crown"]:
		_check(not physical.consume_dialogue_effect("cloudreach:cloudreach_sora_storm_engine_truth"), "truth waits for every vane")
		var at: Vector3 = physical.get("_prompts")[id]["root"].global_position
		await _station(at)
		await _interact()
		_check(game.progression.has(physical.get("_prompts")[id]["spec"]["completion_flag"]), id + " uses real input")
	_check(physical.consume_dialogue_effect("cloudreach:cloudreach_sora_storm_engine_truth"), "truth accepted after all physical vanes")
	_check(not game.progression.has("cloudreach_upper_route_unlocked"), "truth does not turn windlass")
	await _station(Vector3(40,0,0))
	await _interact()
	_check(game.progression.has("cloudreach_upper_route_unlocked"), "windlass input releases upper road")
	await _station(Vector3(50,0,0))
	await _frames(3)
	_check(game.progression.has("cloudreach_act_ii_complete"), "real grounded road threshold completes Act II")
	var saved: Dictionary = game.progression.save_data()
	game.progression = FLAGS.new()
	game.progression.load_data(saved)
	physical.restore_progression_from_game(game)
	_check(game.progression.has("cloudreach_upper_route_unlocked") and not physical.trial_active, "reload preserves durable progress but no temporary trial")
	_check(not physical.consume_dialogue_effect("cloudreach:encounter:captain_veyra_storm_anchor_won"), "dialogue cannot fabricate boss victory")
	for action: String in ["jump", "move_right", "move_left", "fly_descend", "interact"]:
		_action(action, false)
	world.free()
	for failure: String in failures:
		printerr("FAIL: " + failure)
	print("CLOUDREACH PHYSICAL: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _build() -> void:
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(30,-1,0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(150,2,100)
	collision.shape = shape
	floor_body.add_child(collision)
	world.add_child(floor_body)
	var rig := SpringArm3D.new()
	rig.name = "CameraRig"
	rig.set_script(CAMERA)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	player = PLAYER.instantiate()
	player.position = Vector3(0,0.1,0)
	world.add_child(player)
	fly = player.fly_controller
	var arbiter := ARBITER.new()
	world.add_child(arbiter)
	arbiter.set_player(player)
	events = EVENTS.new()
	events.chapter = RULES.read(PHYSICAL.CHAPTER_PATH)
	world.add_child(events)
	var data := RULES.read(PHYSICAL.DATA_PATH)
	data["updrafts"] = []
	data["restrictions"] = []
	data["landing_objectives"] = [{"id": "sky_shrine", "position": [60,0,0], "radius_m": 15, "height_tolerance_m": 2, "requires_flags": ["fly_traversal_unlocked"], "completion_flag": "sky_shrine_reached", "event": "landmark:sky_shrine_heartstone_reached"}]
	data["ground_triggers"] = [{"id": "road", "position": [50,0,0], "radius_m": 3, "height_tolerance_m": 2, "requires_flags": ["cloudreach_upper_route_unlocked"], "completion_flag": "cloudreach_act_ii_complete", "event": "counterweight_road_entered"}]
	var selected: Array = []
	var positions := {"aerie_repair": [5,0,0], "flight_trial_start": [0,0,0], "shrine_vane_west": [20,0,0], "shrine_vane_east": [26,0,0], "shrine_vane_crown": [32,0,0], "shrine_windlass": [40,0,0]}
	for spec: Dictionary in data["interactions"]:
		if positions.has(spec["id"]):
			spec["position"] = positions[spec["id"]]
			selected.append(spec)
	data["interactions"] = selected
	data["trial"] = {"bounds_position": [-10,-2,-20], "bounds_size": [70,30,40], "gates": [{"position": [8,8,0], "radius_m": 5}, {"position": [16,8,0], "radius_m": 5}, {"position": [24,8,0], "radius_m": 5}], "landing_position": [0,0,0], "landing_radius_m": 38, "landing_height_tolerance_m": 2, "minimum_flight_seconds": 1.5, "updraft": {"id": "cloudreach_trial_lift", "position": [-5,0,-10], "size": [60,14,20], "lift_speed": 10, "ceiling_y": 12}}
	physical = PHYSICAL.new()
	world.add_child(physical)
	physical.configure(player, fly, Callable(events, "emit_event"), func(at: Vector3) -> Vector3: return at, data, _payout, false)


func _payout(_id: String) -> bool:
	payout_count += 1
	return true


func _walk_to(at: Vector3) -> void:
	for i in 300:
		var dx := at.x - player.position.x
		if absf(dx) < 0.8:
			break
		_action("move_right", dx > 0)
		_action("move_left", dx < 0)
		await physics_frame
	_action("move_right", false)
	_action("move_left", false)
	await _frames(12)


func _station(at: Vector3) -> void:
	player.position = at + Vector3.UP * 0.08
	player.velocity = Vector3.ZERO
	await _frames(15)


func _interact() -> void:
	_action("interact", true)
	await _frames(4)
	_action("interact", false)
	await _frames(5)


func _deploy() -> void:
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	await _frames(7)
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	await _frames(3)


func _action(action: String, pressed: bool) -> void:
	if Input.is_action_pressed(action) == pressed:
		return
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	assertions += 1
	print(("ok " if condition else "FAIL ") + message)
	if not condition:
		failures.append(message)

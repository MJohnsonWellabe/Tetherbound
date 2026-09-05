extends SceneTree

## Isolated real-physics fixture, NOT production captain/combat or route proof.
## Exercises the production Interactable/arbiter on a moving CharacterBody,
## collision under wind, save restoration and recovery handoff. No owner saves.
const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const CHAPTER := preload("res://scripts/world/realm_chapter_progression.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")

class DrivenBody extends CharacterBody3D:
	var finale: Node3D
	var move_enabled := true
	func _physics_process(delta: float) -> void:
		if move_enabled:
			var stick := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
			velocity.x = stick.x * 6.0
			velocity.z = stick.y * 6.0
		velocity.y -= 25.0 * delta
		if finale != null:
			finale.apply_hazards(self, delta)
		move_and_slide()

var failures: Array[String] = []
var flags: RefCounted
var chapter: Dictionary
var creature_piloted := true
var recovered := 0
var _body: DrivenBody
var _finale: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _press(action: String, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)


func _event(event: String) -> Dictionary:
	return CHAPTER.dispatch(flags, chapter, event)


func _recover(body: CharacterBody3D, camp_id: String, at: Vector3) -> void:
	recovered += 1
	_check(camp_id == "summit_bivouac", "Recovery uses authored camp identity")
	body.global_position = at
	body.velocity = Vector3.ZERO


func _box(parent: Node, at: Vector3, size: Vector3) -> void:
	var solid := StaticBody3D.new()
	solid.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	solid.add_child(collider)
	parent.add_child(solid)


func _run() -> void:
	await process_frame
	var game := root.get_node_or_null("Game")
	if game != null:
		game.set_process(false)
	flags = FLAGS.new()
	chapter = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_chapter.json"))
	var scene := Node3D.new()
	scene.name = "FinaleFixture"
	root.add_child(scene)
	current_scene = scene
	_box(scene, Vector3(0, -0.5, 0), Vector3(76, 1, 76))
	# Wall across the wind direction at x=0,z=7. Real collisions stop the body.
	_box(scene, Vector3(0, 2, 7), Vector3(20, 4, 1))
	_body = DrivenBody.new()
	_body.name = "ControlledCreatureFixture"
	_body.position = Vector3(0, 0.2, 0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	_body.add_child(shape)
	scene.add_child(_body)
	var arbiter := ARBITER.new()
	scene.add_child(arbiter)
	arbiter.set_player(_body)
	var data := FINALE.read_config()
	data["arena_origin"] = [0.0, 0.0, 0.0]
	data["aftermath_witness"]["position"] = [0.0, 0.0, -10.0]
	data["recovery"]["safe_position"] = [-10.0, 0.2, -10.0]
	_finale = FINALE.new()
	_finale.setup(flags, _event, func() -> CharacterBody3D: return _body,
		func() -> bool: return creature_piloted, _recover, data)
	scene.add_child(_finale)
	_body.finale = _finale
	await _frames(20)
	_check(_body.is_on_floor(), "CharacterBody rests on a real floor")
	_check(not _finale.strike_relay("west", _body), "Relay refuses pre-victory use")
	for flag: String in data["requires_flags"]:
		flags.set_flag(flag)
	_check(_finale.encounter_started("captain_veyra_storm_anchor"), "Real encounter-start seam accepts gated captain")
	_finale.set_process(false)
	_finale.elapsed = 2.0
	_press("move_back", true)
	await _frames(95)
	_press("move_back", false)
	_check(_body.position.z < 6.3, "Body did not pass through windward wall")
	_check(_body.position.z > 3.5, "Synthetic movement input actually moved body")
	_body.position = Vector3(0, 0.1, 0)
	for tick in range(180):
		_body.velocity = Vector3.ZERO
		_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(_body.velocity.length() <= 7.01 and _body.velocity.length() > 6.5,
		"Wind accumulates against fresh locomotion but stays at configured speed cap")
	_body.position = Vector3(-20, 0.1, -12)
	for tick in range(20):
		_body.velocity = Vector3.ZERO
		_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(_body.velocity.is_zero_approx(), "Lee pocket sheds accumulated drift")
	_check(_finale.encounter_won("captain_veyra_storm_anchor"), "Injected production-win seam advances once")
	_check(not _finale.encounter_won("captain_veyra_storm_anchor"), "Duplicate win refused")
	_body.position = Vector3(-29, 0.1, 3.0)
	creature_piloted = false
	_finale.sync_progression()
	_check(not _finale.strike_relay("west", _body), "Human cannot strike relay")
	creature_piloted = true
	_finale.sync_progression()
	_finale.elapsed = 0.0
	for relay: Dictionary in data["relays"]:
		_body.position = FINALE.vec(relay["offset"]) + Vector3(0, 0.1, -1.0)
		_body.velocity = Vector3.ZERO
		await _frames(5)
		var prompt: Node3D = _finale.get_node("Relay_" + str(relay["id"]))
		_check(not prompt.interaction_offer(_body.global_position).is_empty(), "Reachable relay offers interaction")
		_press("interact", true)
		await _frames(3)
		_press("interact", false)
		await _frames(3)
		_check(flags.has(str(relay["flag_id"])), "Shared input arbiter strikes " + str(relay["id"]))
	_check(flags.has("storm_anchor_network_disabled"), "Three physical relay interactions disable network")
	_check(not flags.has("cloudreach_winds_restored"), "Network does not auto-witness restoration")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(flags.save_data()))
	flags = FLAGS.new()
	flags.load_data(saved)
	_finale.setup(flags, _event, func() -> CharacterBody3D: return _body,
		func() -> bool: return creature_piloted, _recover, data)
	_check(_finale.phase == "awaiting_restoration", "Saved network restores presentation without replay")
	_body.position = Vector3(0, 0.1, -10)
	_check(_finale.witness_restoration(_body), "Physical overlook visit witnesses restoration")
	_check(not _finale.witness_restoration(_body), "Duplicate witness is idempotent")
	_check(not flags.has("realm_key_water"), "Heart/key still require reward dialogue")
	_body.move_enabled = false
	_body.position = Vector3(40, -8, 0)
	_body.velocity = Vector3(0, -20, 0)
	_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(_body.velocity.y > 0 and _body.velocity.x < 0, "Recovery current lifts and returns inward")
	_body.position = Vector3(30, -30, 0)
	_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(recovered == 1, "Deep fall hands off once to safe bivouac")
	_check(_body.position.distance_to(Vector3(-10, 0.2, -10)) < 0.01, "Recovery callback physically places body safely")
	_check(flags.has("cloudreach_winds_restored"), "Recovery retains finale state")
	_body.finale = null
	scene.queue_free()
	await process_frame
	print("CLOUDREACH FINALE FIXTURE %s: body/input/collision, three relays, saved phase, aftermath, recovery" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

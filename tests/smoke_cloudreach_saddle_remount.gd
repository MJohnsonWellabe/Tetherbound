extends SceneTree

## F06 / C1: the owner's Cloudreach saddle report, on the production scene.
##
##   godot --headless --path . --script tests/smoke_cloudreach_saddle_remount.gd
##
## Owner playtest 2026-09-11 (archive/docs/owner-2026-09-19/
## OWNER_PLAYTEST_2026-09-11_COMBAT_CLOUDREACH.md): "I couldn't get back on the
## creatures with the saddle after going into cloudreach." Before this lane's
## fix `scenes/world/cloudreach_cliffs.tscn` had no RidingController at all, so
## the first check below failed on unmodified main.
##
## Disclosed fixture, not earned-route proof: the party, the saddle in the bag
## and the Meadows-earned `saddle_fitted_meadowhart` flag are seeded before the
## scene loads, as a Meadows arrival would carry them, and the closed-gate leg
## places the trainer and the mount in front of the upper counterweight gate.
## Every mount, ride, dismount and remount below is the real `interact`, move
## and jump bindings through the real arbiter; nothing writes a mounted state.
##
## Pins, in order:
##   1. Cloudreach has a ground-riding controller.
##   2. The ride offer wins the prompt beside the saddled Meadowhart, and the
##      ordinary interact press mounts it.
##   3. Riding moves the mount under the stick.
##   4. Interact dismounts onto ground; interact again REMOUNTS (the report).
##   5. Fly refuses to launch while riding, even with Fly unlocked.
##   6. A mounted run at the closed upper counterweight gate cannot cross it.
##   7. The party is the same five, same order, no sixth, throughout.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")

const MOUNT_SPECIES := "meadowhart"
const TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const CLOSED_GATE_ID := "upper_counterweight_gate"

var _failures: Array[String] = []
var _checks := 0
var _world: Node3D
var _player: CharacterBody3D
var _game: Node
var _riding: Node
var _director: Node
var _arbiter: Node
var _rig: Node
var _party_uids: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("current_realm", "cloudreach")
	_game.set("pending_realm_entry", "")
	_game.set("saved_player_pose", {})
	var flags: RefCounted = _game.get("progression")
	flags.call("set_flag", "realm_key_cloudreach")
	flags.call("set_flag", RIDING.saddle_fitted_flag(MOUNT_SPECIES))
	var party: RefCounted = PARTY.new()
	for species: String in TEAM:
		party.call("add", SPECIES.spawn(species))
	party.call("set_active", 0)
	_game.set("party", party)
	(_game.get("inventory") as RefCounted).call("add", "saddle", 1)
	for i in int(party.call("size")):
		_party_uids.append(str((party.call("at", i) as RefCounted).get("uid")))

	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	_arbiter = _world.get_node(^"InteractionArbiter")
	if not await _wait_for_mount_in_world():
		_report()
		return

	_riding = _world.get_node_or_null(^"RidingController")
	_check(_riding != null, "Cloudreach has a ground-riding controller")
	if _riding == null:
		_report()
		return

	await _walk_to_mount()
	await _mount_by_interact("first mount")
	await _ride_forward()
	await _dismount_by_interact("first dismount")
	await _walk_to_mount()
	await _mount_by_interact("remount after dismount")
	await _fly_refused_while_riding()
	await _dismount_by_interact("second dismount")
	await _closed_gate_holds_a_mounted_run()
	_check_party("end of run")
	_report()


## The realm does not bring the companion out by itself; the player calls it
## with the ordinary recall binding, as on any arrival.
func _wait_for_mount_in_world() -> bool:
	for frame in 2400:
		await physics_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		if _director == null:
			continue
		if frame % 120 == 90 and _director.call("ally_body") == null:
			await _press("creature_recall")
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible and frame > 60:
			_check(str(body.get("species_id")) == MOUNT_SPECIES, "the active Meadowhart follows the trainer into Cloudreach")
			for i in 60:
				await physics_frame
			return true
	_fail("the active companion never appeared in Cloudreach")
	return false


## Walk the trainer to the mount with the stick until the ride offer wins.
func _walk_to_mount() -> void:
	for frame in 900:
		_arbiter.call("_recompute")
		if _arbiter.call("winning_provider") == _riding:
			break
		var body: Node3D = _director.call("ally_body")
		if body == null:
			break
		_steer_toward(body.global_position)
		await physics_frame
	_release_move()
	for i in 6:
		await physics_frame
	_arbiter.call("_recompute")
	_check(_arbiter.call("winning_provider") == _riding,
		"the ride offer wins the prompt beside the saddled Meadowhart (prompt '%s')" % str(_arbiter.call("prompt")))


func _mount_by_interact(context: String) -> void:
	await _press("interact")
	for i in 20:
		await physics_frame
	_check(bool(_riding.call("is_mounted")), "%s: the ordinary interact press mounts" % context)
	_check(_player.call("carrier") == _director.call("ally_body"), "%s: the trainer is carried by the owned mount" % context)
	_check_party(context)


func _ride_forward() -> void:
	var body: Node3D = _riding.call("mount_body")
	if body == null:
		_fail("not mounted; the ride leg cannot run")
		return
	var start := body.global_position
	Input.action_press("move_forward", 1.0)
	for i in 90:
		await physics_frame
	_release_move()
	for i in 10:
		await physics_frame
	var moved := Vector2(body.global_position.x - start.x, body.global_position.z - start.z).length()
	_check(moved > 2.0, "the stick moves the mount (%.2f m in 1.5 s)" % moved)


func _dismount_by_interact(context: String) -> void:
	var ridden: Node3D = _riding.call("mount_body")
	var level := ridden.global_position.y if ridden != null else NAN
	await _press("interact")
	for i in 60:
		await physics_frame
	_check(not bool(_riding.call("is_mounted")), "%s: interact dismounts" % context)
	_check(_player.call("carrier") == null, "%s: nothing carries the trainer afterwards" % context)
	_check(_player.collision_layer != 0 and _player.is_on_floor(),
		"%s: the trainer stands, solid, on ground (trainer %s, vy %.2f)" % [context, _player.global_position, _player.velocity.y])
	# The Cloudreach dismount searches 2 m above to 3 m below the mount's feet.
	_check(not is_nan(level) and _player.global_position.y > level - 3.2 and _player.global_position.y < level + 2.2,
		"%s: set down beside the mount's level %.2f, not on another stratum (%.2f)" % [context, level, _player.global_position.y])
	_check_party(context)


func _fly_refused_while_riding() -> void:
	var fly: Node = _player.get("fly_controller")
	(_game.get("progression") as RefCounted).call("set_flag", "fly_traversal_unlocked")
	await _press("jump")
	for i in 8:
		await physics_frame
	await _press("jump")
	for i in 20:
		await physics_frame
	_check(fly != null and not bool(fly.call("is_flying")), "a mounted double jump does not deploy Fly")
	_check(fly != null and str(fly.call("launch_blockers")).contains("riding"),
		"Fly names riding as the reason it will not launch (%s)" % (str(fly.call("launch_blockers")) if fly != null else "no controller"))
	(_game.get("progression") as RefCounted).call("set_flag", "fly_traversal_unlocked", false)


## Fixture: stand in front of the closed ground gate, then mount and ride
## straight at it with the stick. The barrier is the same StaticBody the
## walking trainer meets; the mount must meet it too.
func _closed_gate_holds_a_mounted_run() -> void:
	var flags: RefCounted = _game.get("progression")
	var spec := _gate_spec(CLOSED_GATE_ID)
	if spec.is_empty() or bool(flags.call("has", str(spec.requires_unlock))):
		_fail("the closed-gate fixture is unavailable (spec missing or already unlocked)")
		return
	var gate := _vec3(spec.position)
	var along := _route_direction_at(str(spec.requires_unlock), gate)
	var stand := gate - along * 9.0
	stand.y = float(_world.call("ground_height_near", stand + Vector3.UP * 4.0)) + 0.4
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	var mount: Node3D = _director.call("ally_body")
	var beside := stand + along.cross(Vector3.UP).normalized() * 3.0
	if mount == null or not bool(mount.call("place_on_ground", beside)):
		_fail("could not stand the mount in front of the closed gate at %s" % beside)
		return
	for i in 90:
		await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("mount at the closed gate")
	var body: Node3D = _riding.call("mount_body")
	if body == null:
		return
	var furthest := -INF
	for frame in 360:
		_steer_toward(gate + along * 14.0)
		await physics_frame
		furthest = maxf(furthest, (body.global_position - gate).dot(along))
	_release_move()
	for i in 10:
		await physics_frame
	_check(furthest < 0.0, "a mounted run does not cross the closed counterweight gate (furthest %.2f m past its plane)" % furthest)
	_check(not bool(flags.call("has", str(spec.requires_unlock))), "the gate's unlock flag is untouched")
	await _dismount_by_interact("dismount at the closed gate")


func _gate_spec(id: String) -> Dictionary:
	for raw: Variant in (_world.call("config_data") as Dictionary).get("gates", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw
	return {}


func _route_direction_at(flag: String, at: Vector3) -> Vector3:
	for raw: Variant in (_world.call("config_data") as Dictionary).get("routes", []):
		if not raw is Dictionary or str((raw as Dictionary).get("requires_unlock", "")) != flag:
			continue
		var line: Array = (raw as Dictionary).get("polyline", [])
		for i in line.size() - 1:
			var a := _vec3(line[i])
			var b := _vec3(line[i + 1])
			if Geometry3D.get_closest_point_to_segment(at, a, b).distance_to(at) < 2.0:
				var d := b - a
				d.y = 0.0
				return d.normalized()
	return Vector3.FORWARD


func _check_party(context: String) -> void:
	var party: RefCounted = _game.get("party")
	var now: Array[String] = []
	for i in int(party.call("size")):
		now.append(str((party.call("at", i) as RefCounted).get("uid")))
	_check(now == _party_uids, "%s: the same five companions, same order, no sixth (%d)" % [context, now.size()])


func _steer_toward(target: Vector3) -> void:
	var offset := target - _player.global_position
	offset.y = 0.0
	if offset.length() < 0.05:
		_release_move()
		return
	var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
	Input.action_press("move_right", maxf(local.x, 0.0))
	Input.action_press("move_left", maxf(-local.x, 0.0))
	Input.action_press("move_back", maxf(local.z, 0.0))
	Input.action_press("move_forward", maxf(-local.z, 0.0))


func _release_move() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _vec3(raw: Variant) -> Vector3:
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL %s" % message)


func _report() -> void:
	print("CLOUDREACH SADDLE REMOUNT %s checks=%d failures=%d" % ["OK" if _failures.is_empty() else "FAIL", _checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)

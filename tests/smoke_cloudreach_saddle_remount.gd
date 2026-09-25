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
const SAVE := preload("res://scripts/save/save_game.gd")

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
var _mounted_hop_m := INF


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
	await _jump_apex_is_capped()
	await _dismount_by_interact("first dismount")
	await _trainer_hop_is_not_lower_than_the_mounted_hop()
	await _walk_to_mount()
	await _mount_by_interact("remount after dismount")
	await _fly_refused_while_riding()
	await _dismount_by_interact("second dismount")
	await _closed_gate_holds_a_mounted_run()
	await _long_mounted_descent_is_not_a_fall()
	await _ride_off_edges_by_input()
	await _no_room_refusal_and_forced_fallbacks()
	await _mounted_save_reload_after_descent()
	await _combat_start_forced_dismount()
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
	var at := _player.global_position
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.5, at + Vector3.DOWN * 1.0, _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(ray)
	var index := float(_world.call("ground_height_at", at.x, at.z))
	print("DISMOUNT %s trainer_y=%.2f collider_top=%s surface_index=%.2f mount_level=%.2f" % [context, at.y, str((hit.get("position", Vector3.INF) as Vector3).y) if not hit.is_empty() else "miss", index, level])
	_check(not hit.is_empty() and absf(at.y - (hit["position"] as Vector3).y) < 0.3,
		"%s: the trainer's feet are on the collider top, not inside it" % context)
	_check_party(context)


## SYSTEMS §8: a mounted hop is no higher than the trainer's own 1.35 m.
func _jump_apex_is_capped() -> void:
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		_fail("not mounted; the jump leg cannot run")
		return
	for i in 20:
		await physics_frame
	var start := body.global_position.y
	var apex := start
	await _press("jump")
	for i in 90:
		await physics_frame
		apex = maxf(apex, body.global_position.y)
	_mounted_hop_m = apex - start
	_check(_mounted_hop_m > 0.5, "a mounted hop leaves the ground (%.2f m)" % _mounted_hop_m)


## Measured on foot, same physics step, right after the first dismount.
func _trainer_hop_is_not_lower_than_the_mounted_hop() -> void:
	for i in 20:
		await physics_frame
	var start := _player.global_position.y
	var apex := start
	await _press("jump")
	for i in 90:
		await physics_frame
		apex = maxf(apex, _player.global_position.y)
	var trainer_hop := apex - start
	_check(_mounted_hop_m <= trainer_hop + 0.05,
		"SYSTEMS §8: the mounted hop (%.2f m) is no higher than the trainer's own (%.2f m)" % [_mounted_hop_m, trainer_hop])


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
	_check(furthest > -4.0, "the mounted run actually reached the barrier rather than stalling short (%.2f m)" % furthest)
	_check(not bool(flags.call("has", str(spec.requires_unlock))), "the gate's unlock flag is untouched")
	await _dismount_by_interact("dismount at the closed gate")


## Review finding: the realm's grounded-fall anchor stood still under a rider,
## so any descent of 100 m below the mount point read as a fall every frame.
## Fixture: the mounted pair is placed on the arrival road, 360 m below the
## gate where the trainer last stood.
func _long_mounted_descent_is_not_a_fall() -> void:
	await _walk_to_mount()
	await _mount_by_interact("mount for the long descent")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	var fly: Node = _player.get("fly_controller")
	var anchor: Vector3 = fly.get("safe_anchor")
	var recoveries := [0]
	var on_recovered := func(_reason: Variant = null) -> void: recoveries[0] += 1
	if fly.has_signal("recovered"):
		fly.connect("recovered", on_recovered)
	var low := Vector3(0.0, 0.0, -250.0)
	low.y = float(_world.call("ground_height_near", Vector3(0.0, 110.0, -250.0))) + 0.3
	body.global_position = low
	body.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame
	_check(anchor.y - body.global_position.y > 100.0, "the fixture puts the rider more than 100 m below the last anchor (%.1f m)" % (anchor.y - body.global_position.y))
	_check(recoveries[0] == 0 and bool(_riding.call("is_mounted")) and _player.call("carrier") == body,
		"a mounted descent past 100 m is not treated as a fall (recoveries %d)" % recoveries[0])
	var followed: Vector3 = fly.get("safe_anchor")
	_check(absf(followed.y - body.global_position.y) < 3.0,
		"the ride keeps Fly's safe anchor on the mount's ground (anchor y %.1f, mount y %.1f)" % [followed.y, body.global_position.y])
	# Review finding: the stale anchor bit at the END of the ride. Get off low
	# and stay low.
	var low_y := body.global_position.y
	await _dismount_by_interact("dismount after the long descent")
	for i in 60:
		await physics_frame
	_check(recoveries[0] == 0 and absf(_player.global_position.y - low_y) < 4.0,
		"getting off after the descent leaves the trainer where they got off (y %.1f, recoveries %d)" % [_player.global_position.y, recoveries[0]])
	if fly.has_signal("recovered"):
		fly.disconnect("recovered", on_recovered)


## Coordinator review of #229: the fall legs must RIDE off an edge, not
## teleport the mount over air. Fixture: the trainer and companion are stood
## on the arrival road where it drops to a lower terrace (the follower was
## seen walking off it at (9.5, 102.7, -240)); everything after the mount is
## the stick. The ride heads off that edge, crosses the terrace and keeps going
## toward open air. SYSTEMS §8 parity: a drop a walker survives is survived
## mounted with no snap-back; a fall past 100 m (a walker's recovery depth) is
## caught and returned to verified ground with the rider seated.
const TERRACE_ROAD := Vector3(7.6, 105.41, -245.03)
const TERRACE_TOWARD := Vector3(10.6, 83.9, -239.4)

func _ride_off_edges_by_input() -> void:
	_player.global_position = TERRACE_ROAD
	_player.velocity = Vector3.ZERO
	var ally: Node3D = _director.call("ally_body")
	if ally != null:
		# On the road ribbon itself, not its steep shoulder.
		ally.call("place_on_ground", TERRACE_ROAD + Vector3(-1.0, 0.0, -2.5))
	for i in 60:
		await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("mount above the terrace")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	for i in 30:
		await physics_frame
	_check(body.is_on_floor(), "the mount stands on the road before the ride-off (%s)" % body.global_position)
	var heading := TERRACE_TOWARD - body.global_position
	heading.y = 0.0
	heading = heading.normalized()
	var drops: Array = []
	var recovered_before: int = int(_riding.get("mounted_fall_recoveries"))
	var takeoff := NAN
	var lowest := INF
	var was_airborne := false
	var airborne_frames := 0
	for frame in 3600:
		if int(_riding.get("mounted_fall_recoveries")) > recovered_before:
			break
		_steer_toward(body.global_position + heading * 50.0)
		await physics_frame
		if not bool(_riding.call("is_mounted")):
			break
		if body.is_on_floor():
			if was_airborne and airborne_frames > 20:
				drops.append({"from": takeoff, "to": body.global_position.y, "fell": takeoff - body.global_position.y, "recovered": false})
			was_airborne = false
			airborne_frames = 0
			takeoff = body.global_position.y
		else:
			if not was_airborne:
				lowest = body.global_position.y
			was_airborne = true
			airborne_frames += 1
			lowest = minf(lowest, body.global_position.y)
	_release_move()
	var recovered := int(_riding.get("mounted_fall_recoveries")) > recovered_before
	if recovered:
		drops.append({"from": takeoff, "to": lowest, "fell": takeoff - lowest, "recovered": true})
	for i in 60:
		await physics_frame
	print("EDGE RIDE drops=%s end=%s mounted=%s" % [drops, body.global_position, _riding.call("is_mounted")])
	var survived := drops.filter(func(d: Dictionary) -> bool: return not bool(d.recovered) and float(d.fell) > 3.0)
	_check(not survived.is_empty(), "riding off the road by input drops to a lower level and lands (%s)" % [survived])
	for d: Dictionary in survived:
		_check(float(d.fell) < 100.0, "a %.1f m ride-off a walker would survive is not snapped back" % float(d.fell))
	_check(recovered, "riding on off the terrace into open air is eventually caught by the mounted-fall recovery")
	if recovered:
		var last: Dictionary = drops[drops.size() - 1]
		_check(float(last.fell) > 95.0, "the mount fell as far as a walker would before recovery (%.1f m)" % float(last.fell))
		_check(body.is_on_floor() and bool(_riding.call("is_mounted")) and _player.call("carrier") == body,
			"after the recovery the mount stands on ground with the rider seated (%s)" % body.global_position)
	_check_party("edge ride")


## SYSTEMS §8 "dismount at supported nearby clearance, otherwise show
## refusal", and the forced-dismount fallbacks. Fixture: test-only walls are
## raised around the ridden mount on open ground so no dismount spot is clear;
## the refusal is the ordinary interact press.
func _no_room_refusal_and_forced_fallbacks() -> void:
	if not bool(_riding.call("is_mounted")):
		await _walk_to_mount()
		await _mount_by_interact("mount for the refusal leg")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	# Let the ride record a clear spot on open ground first.
	for i in 40:
		await physics_frame
	var remembered: Vector3 = _riding.get("_clear_spot")
	_check(remembered != Vector3.INF, "riding on open ground records a clear dismount spot (%s)" % remembered)
	var walls := _enclose(body)
	for i in 4:
		await physics_frame
	var hud := _world.get_node_or_null(^"PlaygroundHUD")
	await _press("interact")
	var said := ""
	for i in 20:
		await physics_frame
		var label: Variant = hud.get("_hotbar_message") if hud != null else null
		if label is Label and (label as Label).visible:
			said = (label as Label).text
	_check(bool(_riding.call("is_mounted")), "boxed in, the interact press does not dismount")
	_check(said.contains("No room to dismount"), "the refusal says why ('%s')" % said)
	# A forced ending (what a fight or modal does) must still end the ride:
	# at the remembered clear spot, never inside the mount.
	_riding.call("dismount")
	for i in 30:
		await physics_frame
	_check(not bool(_riding.call("is_mounted")), "a forced dismount ends the ride even boxed in")
	_check(str(_riding.get("last_dismount_rule")) in ["remembered", "history", "mounted_from"],
		"the forced dismount used a verified fallback (%s)" % str(_riding.get("last_dismount_rule")))
	_check(_player.global_position.distance_to(body.global_position) <= 8.5,
		"the fallback is nearby, not back along the route (%.1f m)" % _player.global_position.distance_to(body.global_position))
	_check(not _trainer_overlaps(body), "the trainer is not set down inside the mount")
	_check(_player.is_on_floor(), "the trainer stands on ground after the forced dismount (%s)" % _player.global_position)
	for wall: Node in walls:
		wall.queue_free()
	for i in 10:
		await physics_frame
	_check_party("refusal and fallbacks")


func _enclose(body: Node3D) -> Array:
	var walls: Array = []
	var radius := float(body.call("body_radius")) if body.has_method("body_radius") else 1.2
	var inner := radius + 0.25
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var wall := StaticBody3D.new()
		wall.name = "TestEnclosure"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var along := Vector3(absf(side.z), 0.0, absf(side.x))
		box.size = along * (inner * 2.0 + 1.0) + Vector3.UP * 6.0 + side.abs() * 0.4
		shape.shape = box
		wall.add_child(shape)
		_world.add_child(wall)
		wall.global_position = body.global_position + side * (inner + 0.2) + Vector3.UP * 2.0
		walls.append(wall)
	return walls


func _trainer_overlaps(body: Node3D) -> bool:
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or not body is CollisionObject3D:
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = Transform3D(Basis.IDENTITY, _player.global_position + collision.position)
	query.collision_mask = 0xFFFFFFFF
	var skip: Array[RID] = [_player.get_rid()]
	query.exclude = skip
	for hit: Dictionary in _player.get_world_3d().direct_space_state.intersect_shape(query, 16):
		if hit["collider"] == body:
			return true
	return false


## Coordinator review of #229: a forced dismount at combat start must not put
## the trainer inside the mount, which keeps its collision while the fight
## drives it. Fixture: a wild is spawned beside the ridden mount and the
## director's own fight start is called, as an engage does.
func _combat_start_forced_dismount() -> void:
	await _press("creature_recall")
	for i in 30:
		await physics_frame
	if _director.call("ally_body") == null:
		await _press("creature_recall")
		for i in 60:
			await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("mount before the fight")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	var wild: Node3D = _director.call("spawn_wild", "cloudling", body.global_position + Vector3(6.0, 0.5, 0.0), {"name": "TestFightWild"})
	if wild == null:
		wild = _director.call("spawn_wild", "bramblebun", body.global_position + Vector3(6.0, 0.5, 0.0), {"name": "TestFightWild"})
	if wild == null:
		_fail("could not spawn a wild for the combat-start leg")
		return
	for i in 10:
		await physics_frame
	_director.call("_start_fight", wild)
	for i in 90:
		await physics_frame
	var manager := _world.get_node_or_null(^"CombatManager")
	_check(manager != null and bool(manager.call("is_fighting")), "the fight started")
	_check(not bool(_riding.call("is_mounted")), "combat admission ends the ride")
	_check(not _trainer_overlaps(body), "combat admission does not leave the trainer inside the mount (rule %s)" % str(_riding.get("last_dismount_rule")))
	_check(_player.collision_layer != 0, "the trainer is solid again in the fight")
	_check_party("combat start")


## Review finding F1: the anchor frozen at the top of a ride made a reload
## after a long descent "recover" the trainer back up to where it began. The
## in-ride anchor check above is the direct witness; this leg is the reload
## half. The ride began at the gate (~474 m) and the anchor has followed the
## mounted descent to the arrival road; save, reload, stay low.
func _mounted_save_reload_after_descent() -> void:
	if not bool(_riding.call("is_mounted")):
		await _walk_to_mount()
		await _mount_by_interact("mount before saving")
	var body: Node3D = _riding.call("mount_body")
	if body == null:
		return
	for i in 30:
		await physics_frame
	var level := body.global_position.y
	_game.set("save_system", SAVE.new("user://cloudreach_saddle_remount_smoke/"))
	_check(bool(_game.call("save_game", 0)), "save WHILE MOUNTED on the arrival road after the descent")
	_world.queue_free()
	await physics_frame
	_check(bool(_game.call("load_game", 0)), "load that save")
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	_arbiter = _world.get_node(^"InteractionArbiter")
	for i in 240:
		await physics_frame
	_director = _world.get_node_or_null(^"EncounterDirector")
	_riding = _world.get_node_or_null(^"RidingController")
	var anchor: Vector3 = (_player.get("fly_controller") as Node).get("safe_anchor")
	_check(not bool(_player.call("is_carried")) and _player.is_on_floor(),
		"a mounted save reloads with the trainer standing on ground, not carried (%s)" % _player.global_position)
	_check(absf(_player.global_position.y - level) < 4.0 and (anchor == Vector3.INF or anchor.y < 400.0),
		"...where the ride was saved, not the top of the ride (trainer y %.1f, saved at %.1f, anchor %s)" % [_player.global_position.y, level, anchor])
	_check_party("mounted save/reload")
	await _press("creature_recall")
	for i in 90:
		await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("remount after reloading a mounted save")
	await _dismount_by_interact("dismount after the reload")


func _open_air_near(from: Vector3) -> Vector3:
	var space := _player.get_world_3d().direct_space_state
	for radius: float in [40.0, 70.0, 100.0, 140.0, 200.0]:
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var at := from + Vector3(cos(angle), 0.0, sin(angle)) * radius
			var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at + Vector3.DOWN * 400.0)
			if space.intersect_ray(ray).is_empty():
				return at + Vector3.UP * 3.0
	return Vector3.INF


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

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
## Disclosed fixtures, not earned-route proof (each leg's comment repeats its
## own):
##   - the party, the saddle in the bag and the Meadows-earned
##     `saddle_fitted_meadowhart` flag are seeded before the scene loads;
##   - teleports: the trainer and mount to the upper counterweight gate, the
##     mounted pair to the arrival road for the long descent and the save leg,
##     the trainer and mount to the Broken Causeways ledge road and the
##     arrival terrace road for the ride-off and mid-drop legs;
##   - test-only StaticBody walls around the mount (refusal and combat legs),
##     pillars on the ring's 16 points and one slab (the rule ladder), and a
##     slab across the route behind the mount (the closed-wall leg);
##   - the rule ladder writes the controller's private per-ride memory
##     (`_clear_spot`, `_ground_history`, `_mounted_from`) and calls
##     `dismount()` directly, as a fight or modal does;
##   - the modal is the arbiter's lockout set directly; forced mid-drop
##     dismount is a direct `dismount()` call;
##   - the combat leg spawns a wild with `spawn_wild` and calls the director's
##     private `_start_fight`;
##   - the finale leg moves the finale controller node to the causeway floor
##     and sets (then clears) the captain-victory flag;
##   - the camera assertions read the rig's private `_target`; the admission
##     leg reads and clears the Game's `_pending_world_message`, calls
##     `begin_trainer_battle` directly for the first challengeable Cloudreach
##     trainer (after setting `cloudreach_chapter_started`), and leaves its wild fight with the manager's `try_flee`;
##   - Fly's pending-anchor flag is raised by hand for the M3 wiring check,
##     and the M3 timeout check runs a bare Fly controller with a fake client
##     session and a proxy that never answers.
## Every other mount, ride, dismount and remount below is the real `interact`,
## move and jump bindings through the real arbiter.
##
## Pins, in order:
##   1. Cloudreach has a ground-riding controller.
##   2. The ride offer wins the prompt beside the saddled Meadowhart, and the
##      ordinary interact press mounts it.
##   3. Riding moves the mount under the stick, and ticks Fly's carried
##      anchor clock; an unanswered carried proposal times out and retries.
##   4. Interact dismounts onto ground; interact again REMOUNTS (the report).
##   5. Fly refuses to launch while riding, even with Fly unlocked.
##   6. A mounted run at the closed upper counterweight gate cannot cross it.
##   7. A long mounted descent is not a fall; ride-offs match a walker's.
##   8. Dismount placement, measured on the `dismounted` signal: rule, reach,
##      floor, no overlap with the mount's capsule (geometry, any layer), not
##      inside world collision, clear line from the saddle -- for the refusal
##      and modal deferral, every fallback rung (a hop included), a closed wall
##      behind the ride, and a forced dismount mid-drop.
##  8b. The finale pilot waits for a boxed-in rider, then takes the ally with
##      the camera, never while the trainer is carried; release does not
##      resume a ride. Combat admission is refused boxed in and otherwise
##      dismounts BEFORE the fight begins; the camera stays on the ally.
##   9. Saving while mounted after a descent reloads on the ground, at the
##      saved spot, with Fly's anchor there too.
##  10. The party is the same five, same order, no sixth, throughout.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

const FLY := preload("res://scripts/player/fly_controller.gd")

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
## The last placement recorded on the `dismounted` signal (`_on_dismounted`).
var _placement: Dictionary = {}
var _placement_mount: Node3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_carried_anchor_proposal_times_out()
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
	_riding.connect("dismounted", _on_dismounted)

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
	await _no_room_refusal_and_modal_deferral()
	await _dismount_rule_ladder()
	await _forced_dismount_never_crosses_a_closed_wall()
	await _forced_dismount_mid_drop()
	await _mounted_save_reload_after_descent()
	await _finale_pilot_handoff_while_mounted()
	await _combat_admission_dismounts_first()
	_check_party("end of run")
	_report()


## M3, solo-runnable: a guest's carried anchor proposal that the host never
## answers (a lost packet, or `remote_trainer.gd` dropping it without a reply)
## must time out and be re-proposed, as on foot. Fixture: a bare Fly controller
## with a fake carried trainer, a fake session that says "client", and a fake
## own proxy that swallows every proposal.
class FakeCarriedTrainer extends CharacterBody3D:
	func is_carried() -> bool:
		return true


class FakeClientSession extends Node:
	func is_active() -> bool:
		return true

	func is_multi_peer() -> bool:
		return true

	func is_host() -> bool:
		return false


class FakeGame extends Node:
	var current_realm := "cloudreach"


class SilentProxy extends Node:
	var asked := 0

	func request_landing_anchor(_at: Vector3, _realm: String, _id: int) -> void:
		asked += 1


func _carried_anchor_proposal_times_out() -> void:
	var fly: Node = FLY.new()
	var game := FakeGame.new()
	var session := FakeClientSession.new()
	session.name = "Session"
	game.add_child(session)
	var trainer := FakeCarriedTrainer.new()
	var proxy := SilentProxy.new()
	proxy.add_to_group(&"remote_trainer")
	root.add_child(proxy)
	fly.set("_game", game)
	fly.set("_player", trainer)
	fly.set("config", JSON.parse_string(FileAccess.get_file_as_string(FLY.CONFIG_PATH)))
	var timeout := float(((fly.get("config") as Dictionary).get("landing_anchor", {}) as Dictionary).get("pending_timeout_s", 5.0))
	if not fly.has_method("observe_carried_ground") or not fly.has_method("tick_carried_anchor"):
		_fail("Fly has no carried-anchor path (observe_carried_ground / tick_carried_anchor)")
	else:
		var a := Vector3(0.0, 105.0, -250.0)
		var b := a + Vector3(30.0, 0.0, 0.0)
		fly.call("observe_carried_ground", a)
		_check(proxy.asked == 1 and bool(fly.get("_anchor_pending")), "a carried guest proposes its anchor to the host (asked %d)" % proxy.asked)
		for i in int(floor((timeout - 0.2) / 0.1)):
			fly.call("tick_carried_anchor", 0.1)
		fly.call("observe_carried_ground", b)
		_check(proxy.asked == 1, "while the proposal is pending (under %.1f s) it is not re-sent (asked %d)" % [timeout, proxy.asked])
		for i in 4:
			fly.call("tick_carried_anchor", 0.1)
		fly.call("observe_carried_ground", b)
		_check(proxy.asked == 2 and bool(fly.get("_anchor_pending")),
			"an unanswered carried proposal times out after %.1f s and is re-proposed (asked %d)" % [timeout, proxy.asked])
	proxy.queue_free()
	fly.free()
	trainer.free()
	game.free()


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
	# M3 wiring: the ride itself ticks Fly's pending-proposal clock. Fixture:
	# the pending flag is raised by hand (solo has no host to ask).
	var fly: Node = _player.get("fly_controller")
	fly.set("_anchor_pending", true)
	fly.set("_anchor_pending_for", 0.0)
	for i in 30:
		await physics_frame
	var ticked := float(fly.get("_anchor_pending_for"))
	fly.set("_anchor_pending", false)
	fly.set("_anchor_pending_for", 0.0)
	_check(ticked > 0.4, "while carried, the ride ticks Fly's anchor-proposal clock (%.2f s over 30 frames)" % ticked)


func _dismount_by_interact(context: String) -> void:
	var ridden: Node3D = _riding.call("mount_body")
	var level := ridden.global_position.y if ridden != null else NAN
	_arm_placement(ridden)
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
	_check_placement(context, ["clear"])
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
## teleport the mount over air. SYSTEMS §8 parity with walking: a drop a walker
## survives is survived mounted with no snap-back; a fall past 100 m (a
## walker's recovery depth) is caught and returned to verified ground with the
## rider seated. Fixture, per edge: the trainer and companion are stood on the
## upper surface (disclosed); everything after the mount is the stick.
##
## LEDGE: the raised Broken Causeways road crosses the 390 m causeway floor;
## its side is a sheer ~11 m drop onto open, flat floor (a physics survey of the
## solo world found it; the floor runs well past any ride's reach).
## TERRACE: the arrival road's shoulder above the cloud sea; below it is only
## steep rock and then air, so a ride off it falls past 100 m.
const LEDGE_ROAD := Vector3(-104.0, 401.6, 1664.0)
const LEDGE_TOWARD := Vector3(-94.0, 390.0, 1647.0)
const TERRACE_ROAD := Vector3(7.6, 105.41, -245.03)
const TERRACE_TOWARD := Vector3(10.6, 83.9, -239.4)

func _ride_off_edges_by_input() -> void:
	var ledge := await _ride_off_edge(LEDGE_ROAD, LEDGE_TOWARD, Vector3(2.0, 0.0, 1.0), "ledge", 600)
	var landed: Array = ledge.drops.filter(func(d: Dictionary) -> bool: return not bool(d.recovered) and float(d.fell) > 3.0)
	_check(not landed.is_empty(), "riding off the causeway ledge by input drops to the floor below and lands (%s)" % [ledge.drops])
	for d: Dictionary in landed:
		_check(float(d.fell) < 100.0, "a %.1f m ride-off a walker would survive is not snapped back" % float(d.fell))
	_check(not ledge.recovered, "the survivable ride-off triggers no mounted-fall recovery")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body != null:
		_check(body.is_on_floor() and body.global_position.y < LEDGE_ROAD.y - 3.0 and bool(_riding.call("is_mounted")),
			"after the ride-off the mount stands on the lower floor with the rider seated (%s)" % body.global_position)
		await _dismount_by_interact("dismount on the floor below the ledge")
	_check_party("ledge ride")

	var terrace := await _ride_off_edge(TERRACE_ROAD, TERRACE_TOWARD, Vector3(-1.0, 0.0, -2.5), "terrace", 3600)
	_check(terrace.recovered, "riding on off the terrace into open air is eventually caught by the mounted-fall recovery")
	body = _riding.call("mount_body")
	if terrace.recovered and body != null:
		var last: Dictionary = terrace.drops[terrace.drops.size() - 1]
		_check(float(last.fell) > 95.0, "the mount fell as far as a walker would before recovery (%.1f m)" % float(last.fell))
		_check(body.is_on_floor() and bool(_riding.call("is_mounted")) and _player.call("carrier") == body,
			"after the recovery the mount stands on ground with the rider seated (%s)" % body.global_position)
	_check_party("edge ride")


## Stand at `road`, mount by interact, then hold the stick toward `toward`
## until `frames` pass, the ride ends, or a mounted-fall recovery fires.
## Returns {drops, recovered}; each drop is {from, to, fell, recovered}.
func _ride_off_edge(road: Vector3, toward: Vector3, mount_offset: Vector3, label: String, frames: int) -> Dictionary:
	if bool(_riding.call("is_mounted")):
		await _dismount_by_interact("dismount before the %s ride" % label)
	_player.global_position = road
	_player.velocity = Vector3.ZERO
	# The follower's own catch-up after the trainer's teleport moves the ally
	# during the first frames and can set it off the road's side, so the
	# fixture waits it out and seats the ally last (as the mid-drop leg does).
	# Moved there first: the Cloudreach ground source picks the stratum
	# nearest the body's own height.
	for i in 60:
		await physics_frame
	var ally: Node3D = _director.call("ally_body")
	if ally != null:
		# On the road itself, not its steep shoulder.
		ally.global_position = road + mount_offset
		ally.call("place_on_ground", road + mount_offset)
	for i in 10:
		await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("mount above the %s" % label)
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return {"drops": [], "recovered": false}
	for i in 30:
		await physics_frame
	_check(body.is_on_floor() and absf(body.global_position.y - road.y) < 2.0,
		"the mount stands on the %s road before the ride-off (%s)" % [label, body.global_position])
	var heading := toward - body.global_position
	heading.y = 0.0
	heading = heading.normalized()
	var drops: Array = []
	var recovered_before: int = int(_riding.get("mounted_fall_recoveries"))
	var takeoff := body.global_position.y
	var lowest := INF
	var was_airborne := false
	var airborne_frames := 0
	for frame in frames:
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
	print("EDGE RIDE %s drops=%s end=%s mounted=%s" % [label, drops, body.global_position, _riding.call("is_mounted")])
	return {"drops": drops, "recovered": recovered}


## SYSTEMS §8 "dismount at supported nearby clearance, otherwise show
## refusal", then a modal forcing the ride to end in the same box. Fixture:
## four test-only walls are raised around the ridden mount on open ground, so
## no ring spot has a clear line from the saddle and the remembered spot, the
## history and the mount point all lie outside a wall; the modal is the
## arbiter's lockout set directly, which is what `sequence_director.gd`'s
## `_refresh_lockout` does for a panel. Pinned outcome for this geometry:
## the refusal, then "deferred" (the rider stays seated INSIDE the walls),
## then "clear" on the first frame after the walls come down.
func _no_room_refusal_and_modal_deferral() -> void:
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
	var centre := body.global_position
	var walls := _enclose(body)
	var wall_half := _enclosure_inner(body)
	for i in 4:
		await physics_frame
	_check(remembered == Vector3.INF or _outside_box(remembered, centre, wall_half),
		"fixture: the remembered spot lies beyond a wall from the saddle (%s)" % remembered)
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

	_arm_placement(body)
	_arbiter.call("set_enabled", false)
	for i in 20:
		await physics_frame
	_check(not bool(_arbiter.call("enabled")), "fixture: the modal lockout holds for the leg")
	_check(bool(_riding.call("is_mounted")) and _player.call("carrier") == body and _placement.is_empty(),
		"a modal cannot put the trainer down with nothing verified: the rider stays seated (mounted %s)" % _riding.call("is_mounted"))
	_check(str(_riding.get("last_dismount_rule")) == "deferred",
		"the forced dismount in the box is 'deferred' (%s)" % str(_riding.get("last_dismount_rule")))
	_check(not _outside_box(_player.global_position, centre, wall_half - 0.2),
		"the trainer never crossed a wall to the remembered spot (%s, box half-width %.2f)" % [_player.global_position, wall_half])
	for wall: Node in walls:
		wall.queue_free()
	for i in 20:
		await physics_frame
	_arbiter.call("set_enabled", true)
	_check(not bool(_riding.call("is_mounted")), "once the walls are gone the held modal ends the ride on its next retry")
	_check_placement("modal retry after the walls fell", ["clear"])
	for i in 30:
		await physics_frame
	_check_party("refusal and modal deferral")


## Every fallback rung, one at a time. Fixture, disclosed: test-only pillars
## stand on each of the ring's 16 candidate points so "clear" cannot answer,
## and the controller's private per-ride memory (`_clear_spot`,
## `_ground_history`, `_mounted_from`) is written to stage each rung; the
## dismount is the forced call a fight or modal makes. The candidate spot P is
## on open ground 2.2 m out between two ring directions.
func _dismount_rule_ladder() -> void:
	# remembered: used when verified.
	await _ladder_case("remembered is used", {"clear": "P"}, "remembered")
	# M2: a wall between the saddle and the remembered spot rejects it; nothing
	# else is staged, so the modal-style forced dismount defers.
	await _ladder_case("remembered behind a wall", {"clear": "P", "wall": true}, "deferred")
	# H1: the NEWEST in-reach sample wins over an older one 20 m back.
	await _ladder_case("newest in-reach history", {"history": ["FAR", "P"]}, "history")
	# H1: a sample beyond REMEMBERED_SPOT_REACH_M is never used.
	await _ladder_case("history out of reach", {"history": ["FAR"]}, "deferred")
	await _ladder_case("mounted_from", {"history": ["FAR"], "mounted_from": "P"}, "mounted_from")
	# M-C: a forced dismount during a hop, with the ring blocked and a verified
	# remembered spot in reach, stands the trainer on that ground rather than
	# setting them down in the air beside the hopping mount.
	await _ladder_case("mid-hop prefers ground", {"clear": "P", "hop": true}, "remembered")
	_check_party("dismount rule ladder")


func _ladder_case(label: String, stage: Dictionary, expect: String) -> void:
	await _mount_on_causeway_floor("the ladder: %s" % label)
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		_fail("%s: not mounted" % label)
		return
	for i in 20:
		await physics_frame
	var base := body.global_position
	var basis := body.global_transform.basis
	var side := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var p_dir := side.rotated(Vector3.UP, deg_to_rad(22.5))
	var p := base + p_dir * 2.2
	p.y = _floor_y(p, base.y)
	var far := base - p_dir * 20.0
	far.y = _floor_y(far, base.y)
	var hop := bool(stage.get("hop", false))
	# A hop gets knee-high pillars: they block every ring spot on the ground
	# but leave the air beside a hopping mount open, so an "airborne" answer
	# is possible and only the rule ORDER keeps the trainer on ground.
	var pillars := _pillar_ring(body, 0.4 if hop else 4.0)
	var blockers: Array = []
	if bool(stage.get("wall", false)):
		blockers.append(_wall_across(base, p))
	for i in 3:
		await physics_frame
	if hop:
		await _press("jump")
		for i in 40:
			if not body.is_on_floor() and body.global_position.y > base.y + 0.7:
				break
			await physics_frame
		_check(not body.is_on_floor() and body.global_position.y > base.y + 0.7,
			"fixture: the mount is mid-hop (%.2f m up)" % (body.global_position.y - base.y))
	var named := {"P": p, "FAR": far}
	_riding.set("_clear_spot", named.get(str(stage.get("clear", "")), Vector3.INF))
	var history: Array[Vector3] = []
	for key: String in stage.get("history", []):
		history.append(named[key])
	# The ride's own newest sample (the mount's current footing) stays newest:
	# the mount stands on it, so its capsule overlap must reject it.
	history.append(body.global_position)
	_riding.set("_ground_history", history)
	_riding.set("_mounted_from", named.get(str(stage.get("mounted_from", "")), Vector3.INF))
	_arm_placement(body)
	var ok := bool(_riding.call("dismount"))
	var rule := str(_riding.get("last_dismount_rule"))
	_check(rule == expect, "ladder %s: rule '%s' (expected '%s')" % [label, rule, expect])
	if expect == "deferred":
		_check(not ok and bool(_riding.call("is_mounted")) and _player.call("carrier") == body,
			"ladder %s: nothing verified, so the rider stays seated" % label)
		_check(_player.global_position.distance_to(p) > 1.0 and _player.global_position.distance_to(far) > 5.0,
			"ladder %s: the trainer was not moved to the rejected spot (%s)" % [label, _player.global_position])
	else:
		_check(ok and not bool(_riding.call("is_mounted")), "ladder %s: the ride ended" % label)
		_check(not _placement.is_empty() and Vector2(_placement.at.x - p.x, _placement.at.z - p.z).length() < 0.05,
			"ladder %s: the trainer is set down at P, not the older sample 20 m back (%s vs P %s)" % [label, _placement.get("at"), p])
		_check_placement("ladder %s" % label, [expect])
	for node: Node in pillars + blockers:
		node.queue_free()
	for i in 10:
		await physics_frame


## Coordinator review of 358148b1 (gate-bypass risk): a forced dismount must
## never put the trainer beyond something that closed behind the ride. Fixture:
## on the causeway floor the mount is ridden 1.5 s by the stick, so the ride's
## own ground samples lie behind it; then a test-only slab (standing in for a
## gate or arena seal) is raised across the route just behind the mount,
## pillars block the ring, and the forced `dismount()` a fight or modal makes
## is called. Whatever rule answers, the trainer is never on the far side.
func _forced_dismount_never_crosses_a_closed_wall() -> void:
	await _mount_on_causeway_floor("the closed-wall leg")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	var start := body.global_position
	Input.action_press("move_forward", 1.0)
	for i in 90:
		await physics_frame
	_release_move()
	for i in 10:
		await physics_frame
	var heading := body.global_position - start
	heading.y = 0.0
	_check(heading.length() > 8.0, "fixture: the ride covered ground before the wall went up (%.1f m)" % heading.length())
	heading = heading.normalized()
	var samples: Array = _riding.get("_ground_history")
	var wall_at := body.global_position - heading * 1.75
	var behind := samples.filter(func(v: Vector3) -> bool: return (v - wall_at).dot(heading) < 0.0)
	_check(behind.size() >= 3, "fixture: %d of the ride's %d ground samples lie beyond the wall" % [behind.size(), samples.size()])
	var slab := _static_box(wall_at + Vector3.UP * 2.0, Vector3(14.0, 6.0, 0.3), Basis(Vector3.UP, atan2(heading.x, heading.z)), "TestClosedGate")
	var pillars := _pillar_ring(body)
	for i in 3:
		await physics_frame
	_arm_placement(body)
	var ok := bool(_riding.call("dismount"))
	var rule := str(_riding.get("last_dismount_rule"))
	var at := _player.global_position
	var side := (at - wall_at).dot(heading)
	print("CLOSED WALL rule=%s ok=%s trainer=%s side=%.2f" % [rule, ok, at, side])
	_check(side > 0.0, "a forced dismount never puts the trainer beyond the wall that closed behind the ride (rule %s, %.2f m on the mount's side)" % [rule, side])
	if ok:
		_check_placement("closed wall", ["remembered", "history", "mounted_from", "clear"])
	else:
		_check(rule == "deferred" and bool(_riding.call("is_mounted")), "closed wall: nothing verified on the near side, so the rider stays seated (%s)" % rule)
	for node: Node in pillars + [slab]:
		node.queue_free()
	for i in 10:
		await physics_frame
	_check_party("closed wall")


## H1's own scenario, ridden: off the causeway road by the stick, and a forced
## dismount (the call a fight or modal makes) while the mount is 4 m into the
## 11 m drop. Pinned for this geometry: "airborne" -- the trainer comes off
## beside the mount into the same air and lands on the floor below, never back
## on the upper road. Fixture: trainer and mount stood on the road, as in the
## ride-off leg.
func _forced_dismount_mid_drop() -> void:
	if bool(_riding.call("is_mounted")):
		await _dismount_by_interact("dismount before the mid-drop leg")
	_player.global_position = LEDGE_ROAD
	_player.velocity = Vector3.ZERO
	var ally: Node3D = _director.call("ally_body")
	for i in 60:
		await physics_frame
	if ally != null:
		ally.call("place_on_ground", LEDGE_ROAD + Vector3(2.0, 0.0, 1.0))
	for i in 10:
		await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("mount above the ledge for the mid-drop leg")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	for i in 30:
		await physics_frame
	var takeoff := body.global_position.y
	var heading := LEDGE_TOWARD - body.global_position
	heading.y = 0.0
	heading = heading.normalized()
	var fired := false
	for frame in 600:
		_steer_toward(body.global_position + heading * 50.0)
		await physics_frame
		if not body.is_on_floor() and takeoff - body.global_position.y >= 4.0:
			_release_move()
			_arm_placement(body)
			_riding.call("dismount")
			fired = true
			break
	_release_move()
	_check(fired, "the ride reached 4 m into the causeway drop (takeoff %.1f, mount %s)" % [takeoff, body.global_position])
	if not fired:
		return
	var rule := str(_placement.get("rule", _riding.get("last_dismount_rule")))
	_check(rule == "airborne", "a forced dismount mid-drop uses the 'airborne' rule (%s)" % rule)
	_check(not _placement.is_empty() and float(_placement.distance) <= 8.0,
		"mid-drop the trainer comes off beside the mount (%.1f m), not back along the route" % float(_placement.get("distance", INF)))
	_check(not _placement.is_empty() and not bool(_placement.overlap) and bool(_placement.line_clear),
		"mid-drop placement: clear of the mount and a clear line from the saddle (%s)" % _placement)
	_check(not _placement.is_empty() and float((_placement.at as Vector3).y) < takeoff - 3.0,
		"mid-drop placement is below the road, not on it (y %.1f, road %.1f)" % [float((_placement.get("at", Vector3.INF) as Vector3).y), takeoff])
	for i in 180:
		await physics_frame
	_check(_player.is_on_floor() and _player.global_position.y < takeoff - 8.0,
		"the trainer lands on the causeway floor below the ledge (y %.1f, road %.1f)" % [_player.global_position.y, takeoff])
	_check_party("mid-drop forced dismount")


## Fixture for the ladder and combat legs: the open, flat Broken Causeways
## floor below the ledge (the ride-off leg lands there; it runs well past any
## ride's reach). The trainer is teleported there, the companion stood beside,
## then the ordinary walk and interact mount it.
const CAUSEWAY_FLOOR := Vector3(-74.0, 390.1, 1573.0)
## The arrival road where the long-descent leg stands the mounted pair: the
## wild-spawn support rule needs the realm's surface index, which the causeway
## floor lacks, so the fight is staged here.
const ARRIVAL_ROAD := Vector3(0.0, 105.3, -250.0)

func _mount_on_causeway_floor(label: String) -> void:
	await _mount_on_open_ground(CAUSEWAY_FLOOR, label)


func _mount_on_open_ground(where: Vector3, label: String) -> void:
	if bool(_riding.call("is_mounted")):
		await _dismount_by_interact("dismount before %s" % label)
	if _director.call("ally_body") == null:
		await _press("creature_recall")
		for i in 60:
			await physics_frame
	_player.global_position = where
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	var ally: Node3D = _director.call("ally_body")
	if ally != null:
		ally.call("place_on_ground", where + Vector3(3.0, 0.0, 1.0))
	for i in 20:
		await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("mount on open ground for %s" % label)
	var body: CharacterBody3D = _riding.call("mount_body")
	for i in 20:
		await physics_frame
	_check(body != null and body.is_on_floor() and absf(body.global_position.y - where.y) < 1.5,
		"fixture: the mount stands on open ground for %s (%s)" % [label, body.global_position if body != null else "-"])


## The walls of the refusal and combat legs: four slabs around `body`, each
## `_enclosure_inner(body)` from its centre, higher than the mount.
func _enclose(body: Node3D) -> Array:
	var walls: Array = []
	var inner := _enclosure_inner(body)
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var along := Vector3(absf(side.z), 0.0, absf(side.x))
		walls.append(_static_box(body.global_position + side * (inner + 0.2) + Vector3.UP * 2.0,
			along * (inner * 2.0 + 1.0) + Vector3.UP * 6.0 + side.abs() * 0.4, Basis.IDENTITY, "TestEnclosure"))
	return walls


func _enclosure_inner(body: Node3D) -> float:
	var radius := float(body.call("body_radius")) if body.has_method("body_radius") else 1.2
	return radius + 0.25


func _outside_box(at: Vector3, centre: Vector3, half: float) -> bool:
	return absf(at.x - centre.x) > half or absf(at.z - centre.z) > half


## A 0.3 m pillar on each of the controller's 16 ring points (2 radii by 8
## directions, from the species' dismount distance and the mount's facing).
func _pillar_ring(body: Node3D, height: float = 4.0) -> Array:
	var pillars: Array = []
	var distance := float(SPECIES.rideable(MOUNT_SPECIES).get("dismount_distance", 1.6))
	var basis := body.global_transform.basis
	var side := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	for reach: float in [distance, distance + 1.2]:
		for step in 8:
			var dir := side.rotated(Vector3.UP, TAU * float(step) / 8.0)
			var at := body.global_position + dir * reach
			if height > 1.0:
				pillars.append(_static_box(at + Vector3.UP * (height * 0.5 - 0.5), Vector3(0.3, height, 0.3), Basis.IDENTITY, "TestPillar"))
			else:
				# A knee-high post just beside the point, so the ring's floor ray
				# still meets the ground (a post top would be a floor to stand
				# on) while the trainer's capsule there overlaps the post.
				var beside := at + dir.cross(Vector3.UP).normalized() * 0.18
				pillars.append(_static_box(beside + Vector3.UP * height * 0.5, Vector3(0.14, height, 0.14), Basis.IDENTITY, "TestPost"))
	return pillars


## A thin slab across the line from the mount to `spot`, clear of the mount's
## capsule, taller than the saddle.
func _wall_across(base: Vector3, spot: Vector3) -> Node3D:
	var dir := Vector3(spot.x - base.x, 0.0, spot.z - base.z).normalized()
	var mid := base + dir * (float(_director.call("ally_body").call("body_radius")) + 0.2)
	return _static_box(mid + Vector3.UP * 2.0, Vector3(1.2, 6.0, 0.15), Basis(Vector3.UP, atan2(dir.x, dir.z)), "TestWall")


func _static_box(at: Vector3, size: Vector3, basis: Basis, label: String) -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.name = label
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	wall.add_child(shape)
	_world.add_child(wall)
	wall.global_transform = Transform3D(basis, at)
	return wall


func _floor_y(at: Vector3, level: float) -> float:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, level + 3.0, at.z), Vector3(at.x, level - 6.0, at.z), _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(ray)
	return (hit["position"] as Vector3).y if not hit.is_empty() else level


## H3: the placement is recorded on the `dismounted` signal, the moment the
## trainer is set down, with the mount's geometry measured directly.
func _arm_placement(body: Node3D) -> void:
	_placement = {}
	_placement_mount = body


func _on_dismounted() -> void:
	var body := _placement_mount
	if body == null or not is_instance_valid(body):
		return
	var at := _player.global_position
	var record := {"at": at, "rule": str(_riding.get("last_dismount_rule")), "mount_at": body.global_position,
		"distance": at.distance_to(body.global_position), "overlap": _overlaps_mount_at(at, body)}
	var space := _player.get_world_3d().direct_space_state
	var down := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.5, at + Vector3.DOWN * 1.0, 0xFFFFFFFF, [_player.get_rid()])
	var hit := space.intersect_ray(down)
	record["floor_ok"] = not hit.is_empty() and (hit["normal"] as Vector3).y >= cos(deg_to_rad(45.0)) \
		and absf(at.y - (hit["position"] as Vector3).y) < 0.3
	record["floor_is_mount"] = not hit.is_empty() and hit["collider"] == body
	var skip: Array[RID] = [_player.get_rid()]
	if body is CollisionObject3D:
		skip.append((body as CollisionObject3D).get_rid())
	var line := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP * 1.0, at + Vector3.UP * 1.0, 0xFFFFFFFF, skip)
	record["line_clear"] = space.intersect_ray(line).is_empty()
	# The trainer's capsule against world collision at the spot, mount excluded.
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = collision.shape
	shape_query.transform = Transform3D(Basis.IDENTITY, at + collision.position + Vector3.UP * 0.02)
	shape_query.collision_mask = _player.collision_mask
	shape_query.exclude = skip
	record["in_geometry"] = not space.intersect_shape(shape_query, 1).is_empty()
	_placement = record
	print("PLACEMENT %s" % record)


func _check_placement(context: String, rules: Array) -> void:
	if _placement.is_empty():
		_fail("%s: no placement was recorded on the dismounted signal" % context)
		return
	_check(str(_placement.rule) in rules, "%s: rule '%s' (expected %s)" % [context, _placement.rule, rules])
	_check(float(_placement.distance) <= 8.0, "%s: set down %.2f m from the mount (reach 8 m)" % [context, float(_placement.distance)])
	_check(bool(_placement.floor_ok), "%s: walkable floor under the trainer's feet at placement (on the mount: %s)" % [context, _placement.floor_is_mount])
	_check(not bool(_placement.overlap), "%s: the trainer's capsule does not overlap the mount's capsule (geometry, any layer)" % context)
	_check(not bool(_placement.in_geometry), "%s: the trainer's capsule is not inside world collision" % context)
	_check(bool(_placement.line_clear), "%s: a clear line from the saddle to the spot" % context)


## Geometric capsule-capsule overlap between the trainer standing at `at` and
## every capsule collider of `body`, from shapes and transforms only: a
## following mount has collision layer 0, which a physics query never reports.
func _overlaps_mount_at(at: Vector3, body: Node3D) -> bool:
	var collision := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or not collision.shape is CapsuleShape3D:
		_fail("the trainer's collider is not a capsule; the overlap check cannot measure it")
		return true
	var mine := collision.shape as CapsuleShape3D
	var a := _segment(mine, Transform3D(Basis.IDENTITY, at + collision.position))
	var found := false
	for child: Node in body.get_children():
		var other := child as CollisionShape3D
		if other == null or not other.shape is CapsuleShape3D:
			continue
		found = true
		var theirs := other.shape as CapsuleShape3D
		var b := _segment(theirs, other.global_transform)
		var closest := Geometry3D.get_closest_points_between_segments(a[0], a[1], b[0], b[1])
		if closest[0].distance_to(closest[1]) < mine.radius + theirs.radius:
			return true
	if not found:
		_fail("the mount has no capsule collider to measure against")
	return false


func _segment(shape: CapsuleShape3D, at: Transform3D) -> Array[Vector3]:
	var half := maxf(shape.height * 0.5 - shape.radius, 0.0)
	var up := at.basis.y.normalized()
	return [at.origin - up * half, at.origin + up * half]


## Coordinator review H-A: the finale's creature-piloting exam taking the
## ally while the trainer rides it. Fixture, disclosed: the pair is stood on
## the causeway floor, the finale controller node is moved there and the
## captain-victory flag set so the runtime's `break_the_eye` handoff runs
## there; walls first box the mount in (nothing verified: the exam must WAIT),
## then come down. The phase is cleared again to release the pilot.
func _finale_pilot_handoff_while_mounted() -> void:
	await _mount_on_causeway_floor("the finale pilot")
	var body: CharacterBody3D = _riding.call("mount_body")
	var runtime := _world.get_node_or_null(^"CloudreachRuntime")
	var finale: Node3D = runtime.get("finale") if runtime != null else null
	if body == null or finale == null:
		_fail("the finale pilot leg has no mount or finale controller")
		return
	var flags: RefCounted = _game.get("progression")
	var victory := str((finale.get("config") as Dictionary).get("captain_victory_flag", "captain_veyra_defeated"))
	var finale_home := finale.global_position
	for i in 20:
		await physics_frame
	var walls := _enclose(body)
	for i in 4:
		await physics_frame
	var deferred_before := int(_riding.get("deferred_dismounts")) if _riding.get("deferred_dismounts") != null else 0
	finale.global_position = body.global_position
	flags.call("set_flag", victory)
	var co_driven := 0
	for i in 60:
		await physics_frame
		if bool(runtime.call("creature_piloted")) and bool(_player.call("is_carried")):
			co_driven += 1
	_check(str(finale.get("phase")) == "break_the_eye", "fixture: the finale is in break_the_eye (%s)" % finale.get("phase"))
	_check(co_driven == 0, "boxed in: the creature is never piloted while the trainer is carried (%d frames)" % co_driven)
	_check(bool(_riding.call("is_mounted")) and not bool(runtime.call("creature_piloted")),
		"boxed in: the exam waits for the rider; the rider stays seated (piloted %s)" % runtime.call("creature_piloted"))
	_check(_riding.get("deferred_dismounts") != null and int(_riding.get("deferred_dismounts")) == deferred_before + 1,
		"60 frames of waiting are one deferral event, told once (%s)" % str(_riding.get("deferred_dismounts")))
	_arm_placement(body)
	for wall: Node in walls:
		wall.queue_free()
	for i in 60:
		await physics_frame
		if bool(runtime.call("creature_piloted")) and bool(_player.call("is_carried")):
			co_driven += 1
	_check(co_driven == 0, "the creature is never piloted while the trainer is carried (%d frames)" % co_driven)
	_check(bool(runtime.call("creature_piloted")) and runtime.call("controlled_body") == body,
		"with room, the rider comes off and the exam pilots the ally")
	_check_placement("finale pilot handoff", ["clear", "remembered", "history", "mounted_from"])
	_check(_rig.get("_target") == body, "a second into the exam the camera is on the piloted creature")
	_check(not bool(_player.call("is_carried")) and _player.is_on_floor(), "the trainer stands, not carried, while the creature is piloted")
	flags.call("set_flag", victory, false)
	for i in 30:
		await physics_frame
	_check(not bool(runtime.call("creature_piloted")), "clearing the phase releases the pilot")
	_check(not bool(_riding.call("is_mounted")) and _player.call("carrier") == null and bool(body.call("is_following")),
		"after release the ally follows and no ride resumes on it (mounted %s)" % _riding.call("is_mounted"))
	_check(_rig.get("_target") == _player, "after release the camera is back on the trainer")
	finale.global_position = finale_home
	_check_party("finale pilot handoff")


## SYSTEMS §8 "Combat admission dismounts safely first. No mounted
## catch/combat." (coordinator review M-A/M-B). Fixture: the pair stood on the
## arrival road, a wild spawned 6 m away (`spawn_wild`), the director's
## private `_start_fight` called as an engage does, first with the refusal
## leg's walls around the mount (no verified ground: the admission is refused
## and the rider stays seated), then with the walls gone (the rider comes off
## onto the ground BEFORE the fight places anyone, and the fight's camera
## stays on the ally).
func _combat_admission_dismounts_first() -> void:
	await _mount_on_open_ground(ARRIVAL_ROAD, "the fight")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	for i in 30:
		await physics_frame
	var wild: Node3D = null
	for offset: Vector3 in [Vector3(6.0, 0.5, 0.0), Vector3(-6.0, 0.5, 0.0), Vector3(0.0, 0.5, 6.0), Vector3(0.0, 0.5, -6.0)]:
		wild = _director.call("spawn_wild", "bramblebun", body.global_position + offset, {"name": "TestFightWild"})
		if wild != null:
			break
	if wild == null:
		_fail("could not spawn a wild for the combat-admission leg")
		return
	var manager := _world.get_node_or_null(^"CombatManager")
	var walls := _enclose(body)
	for i in 4:
		await physics_frame
	var deferred_before := int(_riding.get("deferred_dismounts")) if _riding.get("deferred_dismounts") != null else 0
	_arm_placement(body)
	# Two engage presses and one challenge, over two seconds, in one boxed-in
	# episode. Each must show the refusal (read synchronously from the Game's
	# pending world message, before the HUD takes it).
	var refusals: Array[String] = []
	for press in 2:
		_game.set("_pending_world_message", "")
		_director.call("_start_fight", wild)
		refusals.append(str(_game.get("_pending_world_message")))
		for i in 70:
			await physics_frame
	_check(manager != null and not bool(manager.call("is_fighting")),
		"boxed in, the fight is refused rather than begun with a rider on (fighting %s)" % (manager.call("is_fighting") if manager != null else "-"))
	_check(refusals.size() == 2 and refusals.all(func(m: String) -> bool: return m.contains("No room to dismount")),
		"every refused engage press shows the refusal, the second one too (%s)" % [refusals])
	# Fixture: the chapter-started flag an ordinary arrival sets, which opens
	# the lower-ring trainer's challenge.
	(_game.get("progression") as RefCounted).call("set_flag", "cloudreach_chapter_started")
	for i in 5:
		await physics_frame
	var trainer_id := ""
	var specs: Dictionary = _director.get("trainer_specs") if _director.get("trainer_specs") != null else {}
	for id: String in specs:
		if id != "captain_veyra_storm_anchor" and bool(_director.call("can_challenge", specs[id])) \
				and (_director.get("trainer_nodes") as Dictionary).has(id):
			trainer_id = id
			break
	var starts: Array[String] = []
	var on_start := func(id: String) -> void: starts.append(id)
	if _director.has_signal("trainer_started"):
		_director.connect("trainer_started", on_start)
	if trainer_id.is_empty():
		_fail("no challengeable Cloudreach trainer for the refused-challenge check")
	else:
		_game.set("_pending_world_message", "")
		var began := bool(_director.call("begin_trainer_battle", specs[trainer_id], (_director.get("trainer_nodes") as Dictionary)[trainer_id]))
		var said := str(_game.get("_pending_world_message"))
		for i in 10:
			await physics_frame
		_check(not began and starts.is_empty() and not bool(_director.call("trainer_battle_active")),
			"boxed in, challenging %s is refused: false, no trainer_started, no battle (began %s, starts %s)" % [trainer_id, began, starts])
		_check(said.contains("No room to dismount"), "the refused challenge shows the refusal ('%s')" % said)
	_check(bool(_riding.call("is_mounted")) and _player.call("carrier") == body and _placement.is_empty(),
		"boxed in, the rider stays seated: no mounted combat, no spot guessed")
	_check(str(_riding.get("last_dismount_rule")) == "deferred",
		"the refused admission's dismount is 'deferred' (%s)" % str(_riding.get("last_dismount_rule")))
	_check(_riding.get("deferred_dismounts") != null and int(_riding.get("deferred_dismounts")) == deferred_before + 1,
		"three refused requests over two seconds are one deferral episode (%s, was %d)" % [str(_riding.get("deferred_dismounts")), deferred_before])
	for wall: Node in walls:
		wall.queue_free()
	for i in 4:
		await physics_frame
	_arm_placement(body)
	var fighting_at_placement := [false]
	var watch := func() -> void: fighting_at_placement[0] = manager != null and bool(manager.call("is_fighting"))
	_riding.connect("dismounted", watch)
	_director.call("_start_fight", wild)
	_riding.disconnect("dismounted", watch)
	_check(not fighting_at_placement[0], "the rider came off BEFORE the fight began (fighting at placement: %s)" % fighting_at_placement[0])
	_check(manager != null and bool(manager.call("is_fighting")), "with room, the fight starts")
	_check_placement("combat admission", ["clear"])
	for i in 60:
		await physics_frame
	_check(not bool(_riding.call("is_mounted")) and not bool(_player.call("is_carried")),
		"in the fight nothing carries the trainer")
	_check(_player.is_on_floor() and _player.collision_layer != 0,
		"the trainer stands, solid, on ground in the fight (%s)" % _player.global_position)
	_check(_rig.get("_target") == body, "a second into the fight the camera is on the ally, not the trainer (M-B)")
	_check(not _overlaps_mount_at(_player.global_position, body), "the trainer is not inside the ally in the fight")
	# The refused challenge left nothing behind: once this fight is over, the
	# same trainer can be challenged. The wild fight is left by the manager's
	# own disengage (`try_flee`, what the flee button calls).
	if not trainer_id.is_empty() and manager != null:
		_check(bool(manager.call("try_flee")), "fixture: the wild fight is fled")
		for frame in 900:
			if not bool(manager.call("is_fighting")):
				break
			await physics_frame
		for i in 60:
			await physics_frame
		_check(not bool(manager.call("is_fighting")), "fixture: the wild fight is over")
		var began := bool(_director.call("begin_trainer_battle", specs[trainer_id], (_director.get("trainer_nodes") as Dictionary)[trainer_id]))
		_check(began and starts == [trainer_id], "a later challenge of %s works (began %s, starts %s)" % [trainer_id, began, starts])
	if _director.is_connected("trainer_started", on_start):
		_director.disconnect("trainer_started", on_start)
	_check_party("combat admission")


## Review finding F1, reload half, and M4. Fixture, disclosed: the trainer
## stands on the causeway road (~401 m) until Fly's anchor is there, mounts,
## and the mounted pair is then placed on the arrival road (~105 m), as the
## long-descent leg does, and ridden a moment. Save WHILE MOUNTED, reload.
## Fix witness against the controller before 6db201b3c (no carried anchor):
## there the reload's anchor stays on the causeway road ~300 m up. Against the
## current main, which already carries the anchor, it is a regression guard.
func _mounted_save_reload_after_descent() -> void:
	if bool(_riding.call("is_mounted")):
		await _dismount_by_interact("dismount before the save leg")
	var fly: Node = _player.get("fly_controller")
	_player.global_position = LEDGE_ROAD
	_player.velocity = Vector3.ZERO
	for i in 60:
		await physics_frame
	var ally: Node3D = _director.call("ally_body")
	if ally != null:
		ally.call("place_on_ground", LEDGE_ROAD + Vector3(2.0, 0.0, 1.0))
	for i in 10:
		await physics_frame
	var high: Vector3 = fly.get("safe_anchor")
	_check(high != Vector3.INF and high.y > 390.0, "fixture: on foot on the causeway road, Fly's anchor is up there (%s)" % high)
	await _walk_to_mount()
	await _mount_by_interact("mount on the causeway road before saving")
	var body: CharacterBody3D = _riding.call("mount_body")
	if body == null:
		return
	var low := Vector3(0.0, 0.0, -250.0)
	low.y = float(_world.call("ground_height_near", Vector3(0.0, 110.0, -250.0))) + 0.3
	body.global_position = low
	body.velocity = Vector3.ZERO
	Input.action_press("move_forward", 1.0)
	for i in 30:
		await physics_frame
	_release_move()
	for i in 30:
		await physics_frame
	var saved_at := _player.global_position
	var level := body.global_position.y
	_check(bool(_riding.call("is_mounted")), "still mounted at the save")
	_game.set("save_system", SAVE.new("user://cloudreach_saddle_remount_smoke/"))
	_check(bool(_game.call("save_game", 0)), "save WHILE MOUNTED on the arrival road, ~300 m below where the trainer last stood")
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
	_riding.connect("dismounted", _on_dismounted)
	var anchor: Vector3 = (_player.get("fly_controller") as Node).get("safe_anchor")
	_check(not bool(_player.call("is_carried")) and _player.is_on_floor(),
		"a mounted save reloads with the trainer standing on ground, not carried (%s)" % _player.global_position)
	var flat := Vector2(_player.global_position.x - saved_at.x, _player.global_position.z - saved_at.z).length()
	_check(absf(_player.global_position.y - level) < 4.0 and flat < 6.0,
		"...at the saved spot (trainer %s, saved %s)" % [_player.global_position, saved_at])
	_check(anchor != Vector3.INF and absf(anchor.y - level) < 5.0,
		"...and Fly's anchor came down with the ride, not left on the road ~300 m up (anchor %s, saved level %.1f)" % [anchor, level])
	_check_party("mounted save/reload")
	await _press("creature_recall")
	for i in 90:
		await physics_frame
	await _walk_to_mount()
	await _mount_by_interact("remount after reloading a mounted save")
	await _dismount_by_interact("dismount after the reload")


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

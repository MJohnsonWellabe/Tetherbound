extends SceneTree

## F06: a companion is never lost to a fall in Cloudreach.
##
##   godot --headless --path . --script tests/smoke_cloudreach_companion_fall.gd
##
## ROADMAP F06: foot, Fly and loaner paths "cannot bypass a gate or lose a
## companion". A two-peer smoke saw the active Meadowhart follower walk off the
## arrival road and fall without end (y 88 -> -124 -> -638 -> -10196 ...) on
## host and guest; a solo capture saw it slide off the road's steep shoulder
## after a long trainer teleport. The trainer already had a grounded-fall rule
## (`cloudreach_physical_runtime.gd`); its companion had none.
##
## On the production scene. Nothing writes a recovered state; only the runtime
## moves the companion back. Disclosed fixtures, every one:
##   - the party (and, for leg D, the Meadowhart saddle fitting and a saddle
##     in the bag) is seeded before the scene loads; the companion is called
##     with the real recall binding;
##   - the trainer is TELEPORTED to each road point by position (leg A picks
##     the point by probing where the follower's station lies over open air);
##   - leg A also sets the companion on the road beside the trainer by
##     position once, then leaves it to its own follow logic;
##   - legs B and D drop the companion by position over open air;
##   - leg C adds a temporary 12 m collision slab stranded_drop_m + 10 m below the road (30 m as shipped);
##   - leg D calls `set_following(false)` directly, standing in for the fight
##     and the finale pilot, before its real mount via the ride prompt;
##   - leg F adds a temporary 30-degree collision slab beside the road and
##     teleports the trainer onto it;
##   - leg E builds a SYNTHETIC CharacterBody3D answering
##     `is_local_deployment()`; it is not a real `remote_creature.gd` copy.
##
## Pins, in order:
##   A. Stood still at the arrival road's edge (the reported section, near
##      (7, 105, -246)) where the raw flank station is over open air, the
##      follower -- with Cloudreach's station validator -- stays on the road;
##      then, put over that edge by position (disclosed, as legs B and D), it is
##      caught at the configured fall_drop_m (100 m as shipped) and is back on
##      verified ground beside the trainer in bounded time.
##   B. A companion dropped over open air is recovered to verified walkable
##      ground next to the trainer, clear of the trainer's capsule where it
##      was placed.
##   C. A companion stranded on a ledge (30 m as shipped) below the trainer (the
##      steep-shoulder slide) is recovered too.
##   D. A companion that is not following is left alone; a ridden mount is
##      left to the real riding controller's own drop recovery.
##   F. On a 30-degree slope, a large companion still finds a spot.
##   E. Only a body that answers as this process's own deployment is ever
##      recoverable: one that answers as another peer's is refused.
##   G. The party is the same five throughout.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const HELPER_PATH := "res://scripts/world/cloudreach_companion_fall.gd"
const RIDING := preload("res://scripts/world/riding_controller.gd")

const TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const ROAD_CENTRE := Vector3(-3.0, 106.0, -246.0)
const CONFIG_PATH := "res://data/config/cloudreach_physical_runtime.json"
## Seconds a fall may take to be caught. The rule acts `fall_drop_m` down
## (100 m is about 4.5 s of free fall); the rest is margin for walking off.
const RECOVERY_BUDGET_S := 12.0
const SLOPE_DEG := 30.0

## `companion_fall_recovery` from the runtime's JSON: the smoke measures
## against the configured depths, never its own copies of them.
var _cfg: Dictionary = {}
var _fall_drop_m := NAN
var _stranded_drop_m := NAN
## `fall_drop_m` plus three physics frames of free fall at that depth: the
## rule can only act on the frame after the companion crosses it.
var _caught_by_m := NAN
var _failures: Array[String] = []
var _checks := 0
var _world: Node3D
var _player: CharacterBody3D
var _game: Node
var _director: Node
var _runtime: Node
var _riding: Node
var _arbiter: Node
var _rig: Node
var _party_uids: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	_cfg = ((parsed as Dictionary).get("companion_fall_recovery", {}) as Dictionary) if parsed is Dictionary else {}
	_fall_drop_m = float(_cfg.get("fall_drop_m", NAN))
	_stranded_drop_m = float(_cfg.get("stranded_drop_m", NAN))
	var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_caught_by_m = _fall_drop_m + 3.0 * sqrt(2.0 * gravity * _fall_drop_m) / 60.0
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("current_realm", "cloudreach")
	_game.set("pending_realm_entry", "")
	_game.set("saved_player_pose", {})
	(_game.get("progression") as RefCounted).call("set_flag", "realm_key_cloudreach")
	(_game.get("progression") as RefCounted).call("set_flag", RIDING.saddle_fitted_flag("meadowhart"))
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
	if not await _wait_for_companion():
		_report()
		return
	_runtime = _world.find_child("PhysicalRuntime", true, false)
	_riding = _world.get_node_or_null(^"RidingController")
	_runtime_loaded_the_config()

	await _walk_off_the_road_edge()
	await _dropped_over_open_air()
	await _stranded_on_a_lower_ledge()
	await _not_following_is_left_alone()
	await _ridden_mount_is_the_riding_controllers()
	await _large_companion_on_a_slope()
	_remote_copy_is_refused()
	_check_party("end of run")
	_report()


func _wait_for_companion() -> bool:
	for frame in 2400:
		await physics_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		if _director == null:
			continue
		if frame % 120 == 90 and _director.call("ally_body") == null:
			await _press("creature_recall")
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible and frame > 60:
			_check(str(body.get("species_id")) == "meadowhart", "the active Meadowhart follows the trainer into Cloudreach")
			for i in 60:
				await physics_frame
			return true
	_fail("the active companion never appeared in Cloudreach")
	return false


func _ally() -> CharacterBody3D:
	return _director.call("ally_body") as CharacterBody3D


## LOW-3: the runtime runs with the JSON's values, not only its code defaults.
func _runtime_loaded_the_config() -> void:
	if _runtime == null or not _runtime.has_method("companion_fall_settings"):
		_fail("the runtime exposes no companion fall settings")
		return
	var live: Dictionary = _runtime.call("companion_fall_settings")
	var mismatched: Array[String] = []
	for key: String in _cfg.keys():
		if key.begins_with("_"):
			continue
		if not live.has(key) or not is_equal_approx(float(live[key]), float(_cfg[key])):
			mismatched.append("%s json=%s live=%s" % [key, _cfg[key], live.get(key)])
	_check(not _cfg.is_empty() and mismatched.is_empty() and live.size() == _cfg.size() - 1,
		"the runtime loaded companion_fall_recovery from the JSON (%d values%s)" % [live.size(), "" if mismatched.is_empty() else ": " + ", ".join(mismatched)])


## Leg A. Walk from the road centre toward the follower's station side to the first
## road point whose raw station is over open air; stand the trainer there, let
## the follower follow, then drop it over that edge by position.
func _walk_off_the_road_edge() -> void:
	# Which side the station lies on depends on the camera (a fixed flank),
	# so measure it from the road centre first and walk that way to the edge.
	var centre := ROAD_CENTRE
	centre.y = _floor_y(centre, 6.0)
	await _stand_trainer(centre + Vector3.UP * 0.1)
	var offset: Vector3 = (_ally().call("formation_target") as Vector3) - _player.global_position
	offset.y = 0.0
	var toward := offset.normalized()
	# Rocks and verge props hold the edge in places. Try successive stretches
	# of the reported section until one has its raw station over open air.
	var ally := _ally()
	var tried := 0
	var tried_edge := false
	for row in range(-12, 28, 4):
		var from := centre + Vector3(0.0, 0.0, float(row))
		from.y = _floor_y(from, 6.0)
		if is_nan(from.y):
			continue
		var stand := _stand_with_station_over_air(from, toward, offset)
		if stand == Vector3.INF:
			continue
		tried += 1
		await _stand_trainer(stand + Vector3.UP * 0.1)
		# The companion on the road beside the trainer, as one arriving after
		# the trainer's long move would be: along the road, not behind the
		# trainer, whose own capsule would stand between it and its station.
		var along := toward.cross(Vector3.UP).normalized()
		var inside := stand - toward * 1.0 + along * 3.5
		if is_nan(_floor_y(inside, 2.0)):
			inside = stand - toward * 1.0 - along * 3.5
		ally.global_position = Vector3(inside.x, _floor_y(inside, 4.0) + 0.05, inside.z)
		ally.velocity = Vector3.ZERO
		await physics_frame
		var station: Vector3 = ally.call("formation_target")
		if not _void_below(station):
			continue
		# With the realm's station validator (follower_creature.gd
		# station_validator -> cloudreach_encounter_director.gd
		# verified_follow_spot) the follower, left to itself, stays on the road.
		tried_edge = true
		var worst_drop := 0.0
		for frame in 300:
			await physics_frame
			worst_drop = maxf(worst_drop, _player.global_position.y - ally.global_position.y)
		print("A: trainer %s station %s over open air; follower worst drop %.2f m, now %s" % [_player.global_position, station, worst_drop, ally.global_position])
		_check((ally.get("station_validator") as Callable).is_valid() and worst_drop <= 1.5,
			"A: with the station validator, a companion following at the edge stays on the road (worst drop %.2f m <= 1.5)" % worst_drop)
		# Disclosed fixture, as legs B and D: put the companion over that open
		# air by position; the runtime must catch and recover it.
		# Well out past the edge (as leg B's 24 m): a body dropped just past the
		# lip steers back onto the road before it has fallen at all.
		var drop_at := station + toward * 20.0
		drop_at.y = _player.global_position.y + 3.0
		_check(_void_below(drop_at), "A precondition: open air past that edge at %s" % drop_at)
		var before: Variant = _recoveries()
		ally.global_position = drop_at
		ally.velocity = Vector3.ZERO
		var result := await _watch_for_fall_and_recovery(20.0)
		var during := int(_recoveries()) - int(before)
		_check(bool(result.fell), "A: the companion put over the edge falls (lowest %.1f m)" % result.lowest)
		_check(result.lowest > _player.global_position.y - _caught_by_m,
			"A: the companion is caught before it is %.0f m down, within %.1f m (lowest %.1f m, trainer at %.1f m)" % [_fall_drop_m, _caught_by_m, result.lowest, _player.global_position.y])
		_check(bool(result.recovered),
			"A: the companion is back on verified ground beside the trainer within %.0f s of falling (%s)" % [RECOVERY_BUDGET_S, result.detail])
		_check(int(before) >= 0 and during >= 1, "A: the runtime's recovery caught it during the 20 s watch (%d recoveries)" % during)
		print("A: recoveries during the 20 s watch: %d" % during)
		break
	_check(tried_edge, "A: found a stretch of the arrival road whose flank station is over open air (%d tried)" % tried)


## Leg B. Disclosed fixture: the companion is put over open air beside the road.
func _dropped_over_open_air() -> void:
	var stand := ROAD_CENTRE
	stand.y = _floor_y(stand, 6.0)
	await _stand_trainer(stand + Vector3.UP * 0.1)
	var ally := _ally()
	var over_air := Vector3(stand.x - 24.0, stand.y + 3.0, stand.z)
	_check(_void_below(over_air), "B precondition: open air beside the road at %s" % over_air)
	var before: Variant = _recoveries()
	ally.global_position = over_air
	ally.velocity = Vector3.ZERO
	var result := await _watch_for_fall_and_recovery(RECOVERY_BUDGET_S + 2.0)
	_check(bool(result.fell), "B: the companion falls from open air (lowest %.1f m)" % result.lowest)
	_check(bool(result.recovered), "B: recovered to verified ground beside the trainer within %.0f s (%s)" % [RECOVERY_BUDGET_S, result.detail])
	_check(int(_recoveries()) > int(before), "B: the runtime's companion fall recovery did it (%s -> %s)" % [before, _recoveries()])
	# Measured where the recovery PUT it, not where the follower later walked.
	var spot: Vector3 = _runtime.call("companion_fall_last_spot") if _runtime.has_method("companion_fall_last_spot") else Vector3.INF
	var gap := Vector2(spot.x - _player.global_position.x, spot.z - _player.global_position.z).length() if spot.is_finite() else -1.0
	var needed := float(ally.call("body_radius")) + 0.4
	_check(gap >= needed,
		"B: the recovery spot %s clears the trainer's capsule (%.2f m centre gap, capsules need %.2f m)" % [spot, gap, needed])


## Leg C. The steep-shoulder slide stopped some 30 m down, on ground. The
## arrival road has no such ledge within reach of a headless probe, so this is
## a DISCLOSED fixture: a temporary 12 m slab over the open air beside the
## road, stranded_drop_m + 10 m below the trainer, removed afterwards.
func _stranded_on_a_lower_ledge() -> void:
	var stand := ROAD_CENTRE
	stand.y = _floor_y(stand, 6.0)
	await _stand_trainer(stand + Vector3.UP * 0.1)
	# Deeper than the stranded depth, well short of the fall depth.
	var depth := minf(_stranded_drop_m + 10.0, (_stranded_drop_m + _fall_drop_m) * 0.5)
	var ledge_top := Vector3(stand.x - 26.0, stand.y - depth, stand.z)
	_check(depth > _stranded_drop_m and depth < _fall_drop_m and _void_below(ledge_top + Vector3.UP * depth),
		"C precondition: open air beside the road above a fixture slab %.0f m down (stranded at %.0f m, fall at %.0f m)" % [depth, _stranded_drop_m, _fall_drop_m])
	var slab := StaticBody3D.new()
	slab.name = "CompanionFallFixtureLedge"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(12.0, 1.0, 12.0)
	shape.shape = box
	slab.add_child(shape)
	_world.add_child(slab)
	slab.global_position = ledge_top - Vector3.UP * 0.5
	for i in 2:
		await physics_frame
	var ally := _ally()
	var before: Variant = _recoveries()
	ally.global_position = ledge_top + Vector3.UP * 0.1
	ally.velocity = Vector3.ZERO
	var stood_on_ledge := false
	var recovered := false
	var detail := ""
	for frame in int(RECOVERY_BUDGET_S * 60.0):
		await physics_frame
		if ally.is_on_floor() and absf(ally.global_position.y - ledge_top.y) < 1.0:
			stood_on_ledge = true
		detail = _beside_trainer_detail(ally)
		if detail.begins_with("ok"):
			recovered = true
			break
	slab.queue_free()
	_check(stood_on_ledge, "C: the companion stood on the ledge %.0f m below the trainer (a drop the %.0f m fall rule never sees)" % [depth, _fall_drop_m])
	_check(recovered, "C: a companion stranded on a ledge below the trainer is brought back beside them (%s)" % detail)
	_check(int(_recoveries()) > int(before), "C: by the runtime's recovery, not by walking (%s -> %s)" % [before, _recoveries()])


## Leg D, first half. Following off: the fight and the finale pilot own the
## body then. Fixture: `set_following(false)` is called directly here.
func _not_following_is_left_alone() -> void:
	var stand := ROAD_CENTRE
	stand.y = _floor_y(stand, 6.0)
	await _stand_trainer(stand + Vector3.UP * 0.1)
	var ally := _ally()
	var before: Variant = _recoveries()
	ally.call("set_following", false)
	ally.global_position = Vector3(stand.x - 24.0, stand.y + 3.0, stand.z)
	ally.velocity = Vector3.ZERO
	for i in 480:
		await physics_frame
	_check(_recoveries() == before and ally.global_position.y < stand.y - _fall_drop_m,
		"D: a companion with following switched off is left alone (recoveries %s -> %s, y %.1f)" % [before, _recoveries(), ally.global_position.y])
	ally.call("set_following", true)
	var recovered := false
	var detail := ""
	for frame in 240:
		await physics_frame
		detail = _beside_trainer_detail(ally)
		if detail.begins_with("ok"):
			recovered = true
			break
	_check(recovered, "D: following again, it is recovered at once (%s)" % detail)


## Leg D, second half. A real ride through the real prompt: the riding
## controller owns a mount that drops, and catches it itself.
func _ridden_mount_is_the_riding_controllers() -> void:
	if _riding == null:
		_fail("D: Cloudreach has no RidingController")
		return
	var stand := ROAD_CENTRE
	stand.y = _floor_y(stand, 6.0)
	await _stand_trainer(stand + Vector3.UP * 0.1)
	await _walk_to_mount()
	await _press("interact")
	for i in 20:
		await physics_frame
	var body: CharacterBody3D = _riding.call("mount_body")
	_check(bool(_riding.call("is_mounted")) and body == _ally(), "D: the ordinary interact press mounts the companion")
	if body == null:
		return
	for i in 90:
		await physics_frame
	var before: Variant = _recoveries()
	var ride_before := int(_riding.get("mounted_fall_recoveries"))
	var over_air := Vector3(stand.x - 24.0, body.global_position.y + 3.0, stand.z)
	body.global_position = over_air
	body.velocity = Vector3.ZERO
	for i in 240:
		await physics_frame
	_check(int(_riding.get("mounted_fall_recoveries")) > ride_before and int(_recoveries()) == int(before),
		"D: a ridden mount that drops is caught by the riding controller, not by this rule (ride %d -> %d, companion rule %s -> %s)" % [ride_before, int(_riding.get("mounted_fall_recoveries")), before, _recoveries()])
	await _press("interact")
	for i in 60:
		await physics_frame
	_check(not bool(_riding.call("is_mounted")), "D: interact dismounts again")
	for i in 60:
		await physics_frame


## Leg F. MEDIUM-3: the capsule test on a slope. Fixture: a 30 m, 30-degree
## collision slab in the open air beside the road, the trainer teleported onto
## it, and the companion dropped over open air. Meadowhart's 1.25 m radius
## would cut into a 30-degree slope if only the centre ray's floor were used.
func _large_companion_on_a_slope() -> void:
	var centre := Vector3(ROAD_CENTRE.x - 46.0, ROAD_CENTRE.y, ROAD_CENTRE.z)
	var clear := true
	for dx in [-14.0, -7.0, 0.0, 7.0, 14.0]:
		for dz in [-14.0, 0.0, 14.0]:
			clear = clear and _void_below(centre + Vector3(dx, 12.0, dz))
	_check(clear, "F precondition: open air where the slope slab goes")
	if not clear:
		return
	var slab := StaticBody3D.new()
	slab.name = "CompanionFallFixtureSlope"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30.0, 1.0, 30.0)
	shape.shape = box
	slab.add_child(shape)
	_world.add_child(slab)
	slab.global_transform = Transform3D(Basis(Vector3.FORWARD, deg_to_rad(SLOPE_DEG)), centre)
	for i in 2:
		await physics_frame
	var normal := slab.global_basis.y.normalized()
	await _stand_trainer(centre + normal * 0.5 + Vector3.UP * 0.3)
	var ally := _ally()
	var before: Variant = _recoveries()
	ally.global_position = Vector3(ROAD_CENTRE.x - 24.0, _player.global_position.y + 3.0, ROAD_CENTRE.z)
	ally.velocity = Vector3.ZERO
	var result := await _watch_for_fall_and_recovery(RECOVERY_BUDGET_S + 2.0)
	var spot: Vector3 = _runtime.call("companion_fall_last_spot") if _runtime.has_method("companion_fall_last_spot") else Vector3.INF
	_check(int(_recoveries()) > int(before) and bool(result.recovered),
		"F: a %.2f m-radius companion is recovered onto a %.0f-degree slope beside the trainer (%s; spot %s)" % [float(ally.call("body_radius")), SLOPE_DEG, result.detail, spot])
	slab.queue_free()
	for i in 2:
		await physics_frame


func _walk_to_mount() -> void:
	for frame in 900:
		_arbiter.call("_recompute")
		if _arbiter.call("winning_provider") == _riding:
			break
		var body: Node3D = _ally()
		if body == null:
			break
		_steer_toward(body.global_position)
		await physics_frame
	_release_move()
	for i in 6:
		await physics_frame


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


## Leg E. The multiplayer rule. A real session is not staged here: this is a
## SYNTHETIC CharacterBody3D that answers `is_local_deployment()` the way a
## `remote_creature.gd` copy of another peer's creature does (false), then the
## way this process's own follower does (true).
func _remote_copy_is_refused() -> void:
	if not ResourceLoader.exists(HELPER_PATH):
		_fail("E: the companion fall helper %s does not exist" % HELPER_PATH)
		return
	var helper: GDScript = load(HELPER_PATH)
	var fake := GDScript.new()
	fake.source_code = "extends CharacterBody3D\nvar local := false\nfunc is_local_deployment() -> bool:\n\treturn local\nfunc is_following() -> bool:\n\treturn true\n"
	fake.reload()
	var remote: CharacterBody3D = fake.new()
	_world.add_child(remote)
	_check(not bool(helper.call("recoverable", remote)), "E: a body answering as another peer's creature (synthetic) is never recovered locally")
	remote.set("local", true)
	_check(bool(helper.call("recoverable", remote)), "E: the same synthetic body answering as this process's own would be")
	_check(bool(helper.call("recoverable", _ally())), "E: this process's own deployed follower is recoverable")
	remote.queue_free()


## Watch the companion for `seconds`. `fell` once it is more than 10 m below
## the trainer; `recovered` once, after that, it stands on verified ground
## beside the trainer within the budget.
func _watch_for_fall_and_recovery(seconds: float, already_fell: bool = false) -> Dictionary:
	var ally := _ally()
	var lowest := ally.global_position.y
	var fell_frame := 0 if already_fell else -1
	var recovered := false
	var detail := "fell, not recovered" if already_fell else "never fell"
	for frame in int(seconds * 60.0):
		await physics_frame
		lowest = minf(lowest, ally.global_position.y)
		if fell_frame < 0 and ally.global_position.y < _player.global_position.y - 10.0:
			fell_frame = frame
			detail = "fell, not recovered"
		if fell_frame >= 0 and not recovered:
			var here := _beside_trainer_detail(ally)
			if here.begins_with("ok"):
				recovered = frame - fell_frame <= int(RECOVERY_BUDGET_S * 60.0)
				detail = "%s after %.2f s" % [here, float(frame - fell_frame) / 60.0]
			elif frame - fell_frame > int(RECOVERY_BUDGET_S * 60.0):
				detail = "not recovered after %.0f s: %s" % [RECOVERY_BUDGET_S, here]
	return {"fell": fell_frame >= 0, "recovered": recovered, "lowest": lowest, "detail": detail}


## "ok ..." when the companion stands on floor beside the trainer on a physics
## floor whose normal the body can stand on; otherwise why not.
func _beside_trainer_detail(ally: CharacterBody3D) -> String:
	var at := ally.global_position
	var trainer := _player.global_position
	var planar := Vector2(at.x - trainer.x, at.z - trainer.z).length()
	var reach := float(ally.call("resolved_station_distance")) + 4.0
	if planar > reach or absf(at.y - trainer.y) > 3.0:
		return "at %s, %.1f m from the trainer, dy %.1f" % [at, planar, at.y - trainer.y]
	if not ally.is_on_floor():
		return "near but not on floor at %s" % at
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.6, at + Vector3.DOWN * 1.2, 1, [ally.get_rid(), _player.get_rid()])
	var hit := ally.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return "no physics floor under %s" % at
	if (hit["normal"] as Vector3).y < cos(ally.floor_max_angle):
		return "floor under %s too steep (normal %s)" % [at, hit["normal"]]
	if absf(at.y - (hit["position"] as Vector3).y) > 0.5:
		return "not seated on the floor (%.2f vs %.2f)" % [at.y, (hit["position"] as Vector3).y]
	return "ok at %s, %.1f m from the trainer" % [at, planar]


func _recoveries() -> Variant:
	if _runtime == null or not _runtime.has_method("companion_fall_recoveries"):
		return -1
	return int(_runtime.call("companion_fall_recoveries"))


func _stand_trainer(at: Vector3) -> void:
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	for i in 45:
		await physics_frame
	_check(_player.is_on_floor(), "the trainer stands on ground at %s" % _player.global_position)


## First point walking from the road centre toward the station side that is
## still walkable road (within a metre and a half of the road's level, a
## trainer-walkable normal) while the station beside it is over open air.
func _stand_with_station_over_air(from: Vector3, toward: Vector3, offset: Vector3) -> Vector3:
	var space := _player.get_world_3d().direct_space_state
	var step := 0.0
	while step < 30.0:
		var at := from + toward * step
		step += 0.5
		var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, from.y + 1.5, at.z), Vector3(at.x, from.y - 1.5, at.z), 1, [_player.get_rid()])
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or (hit["normal"] as Vector3).y < cos(deg_to_rad(35.0)):
			continue
		var road: Vector3 = hit["position"]
		if _void_below(road + offset + Vector3.UP * 2.0):
			return road
	return Vector3.INF


func _floor_y(at: Vector3, reach: float) -> float:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * reach, at + Vector3.DOWN * reach, 1, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(ray)
	return NAN if hit.is_empty() else (hit["position"] as Vector3).y


func _void_below(at: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at + Vector3.DOWN * 400.0, 1)
	return _player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _check_party(context: String) -> void:
	var party: RefCounted = _game.get("party")
	var now: Array[String] = []
	for i in int(party.call("size")):
		now.append(str((party.call("at", i) as RefCounted).get("uid")))
	_check(now == _party_uids, "%s: the same five companions, same order, no sixth (%d)" % [context, now.size()])


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


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
	print("CLOUDREACH COMPANION FALL %s checks=%d failures=%d" % ["OK" if _failures.is_empty() else "FAIL", _checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)

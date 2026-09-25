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
## Disclosed fixtures, on the production scene: the party is seeded before the
## scene loads, the companion is called with the real recall binding, and the
## trainer is stood at chosen road points by position. Nothing writes a
## recovered state; only the runtime moves the companion back.
##
## Pins, in order:
##   A. Stood still at the arrival road's edge (on the reported section, near
##      (7, 105, -246)), the trainer's companion
##      walks its camera-safe station off the road (root cause, pinned as a
##      precondition), and is back on verified ground beside the trainer
##      within a bounded time instead of falling forever.
##   B. A companion dropped over open air beside the road is recovered to
##      verified walkable ground next to the trainer, clear of the trainer.
##   C. A companion stranded on a lower ledge well below the trainer (the
##      steep-shoulder slide; a disclosed temporary slab) is recovered too.
##   D. A companion that is not following (combat, riding and the finale pilot
##      all switch following off) is left to its owner system.
##   E. Only this process's own deployed body is ever recovered: a remote copy
##      of another peer's creature is refused.
##   F. The party is the same five throughout.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const HELPER_PATH := "res://scripts/world/cloudreach_companion_fall.gd"

const TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const ROAD_CENTRE := Vector3(-3.0, 106.0, -246.0)
## Seconds a fall may take to be caught. The rule acts 100 m down, which a
## free fall reaches in about 4.5 s; the rest is margin for walking off.
const RECOVERY_BUDGET_S := 12.0
## A fall that is caught never gets anywhere near this far below the trainer.
const LOST_BELOW_M := 220.0

var _failures: Array[String] = []
var _checks := 0
var _world: Node3D
var _player: CharacterBody3D
var _game: Node
var _director: Node
var _runtime: Node
var _party_uids: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("current_realm", "cloudreach")
	_game.set("pending_realm_entry", "")
	_game.set("saved_player_pose", {})
	(_game.get("progression") as RefCounted).call("set_flag", "realm_key_cloudreach")
	var party: RefCounted = PARTY.new()
	for species: String in TEAM:
		party.call("add", SPECIES.spawn(species))
	party.call("set_active", 0)
	_game.set("party", party)
	for i in int(party.call("size")):
		_party_uids.append(str((party.call("at", i) as RefCounted).get("uid")))

	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	if not await _wait_for_companion():
		_report()
		return
	var chapter := _world.find_child("CloudreachChapter", true, false)
	_runtime = _world.find_child("PhysicalRuntime", true, false)
	print("runtime=%s chapter=%s" % [_runtime, chapter])

	await _walk_off_the_road_edge()
	await _dropped_over_open_air()
	await _stranded_on_a_lower_ledge()
	await _not_following_is_left_alone()
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


## Leg A. Walk from the road centre toward the follower's station side to the first
## road point whose station is over open air; stand the trainer there, let it be.
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
	# of the reported section until the follower, left to itself, walks off.
	var ally := _ally()
	var tried := 0
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
		var fell := false
		for frame in 300:
			await physics_frame
			if ally.global_position.y < _player.global_position.y - 10.0:
				fell = true
				break
		print("A: trainer %s station %s over open air; follower %s" % [_player.global_position, station, "walked off" if fell else "held by the edge at %s" % ally.global_position])
		if not fell:
			continue
		_check(true, "A: the follower walks its camera-safe station off the road edge on its own (stretch %d tried)" % tried)
		var result := await _watch_for_fall_and_recovery(20.0, true)
		_check(result.lowest > _player.global_position.y - LOST_BELOW_M,
			"A: the companion is never lost to the drop (lowest %.1f m, trainer at %.1f m)" % [result.lowest, _player.global_position.y])
		_check(bool(result.recovered),
			"A: the companion is back on verified ground beside the trainer within %.0f s of falling (%s)" % [RECOVERY_BUDGET_S, result.detail])
		print("A: recoveries after the 20 s watch: %s" % str(_recoveries()))
		return
	_fail("A: on %d road stretches with the station over open air, the follower never walked off" % tried)


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
	var gap := Vector2(ally.global_position.x - _player.global_position.x, ally.global_position.z - _player.global_position.z).length()
	_check(gap >= float(ally.call("body_radius")) + 0.4,
		"B: the recovered companion is clear of the trainer's capsule (%.2f m centre gap)" % gap)


## Leg C. The steep-shoulder slide stopped some 30 m down, on ground. The
## arrival road has no such ledge within reach of a headless probe, so this is
## a DISCLOSED fixture: a temporary 12 m slab over the open air beside the
## road, 30 m below the trainer, removed afterwards.
func _stranded_on_a_lower_ledge() -> void:
	var stand := ROAD_CENTRE
	stand.y = _floor_y(stand, 6.0)
	await _stand_trainer(stand + Vector3.UP * 0.1)
	var ledge_top := Vector3(stand.x - 26.0, stand.y - 30.0, stand.z)
	_check(_void_below(ledge_top + Vector3.UP * 30.0), "C precondition: open air beside the road above the fixture slab")
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
	_check(stood_on_ledge, "C: the companion stood on the ledge 30 m below the trainer (a fall the 100 m rule never sees)")
	_check(recovered, "C: a companion stranded on a ledge below the trainer is brought back beside them (%s)" % detail)
	_check(int(_recoveries()) > int(before), "C: by the runtime's recovery, not by walking (%s -> %s)" % [before, _recoveries()])


## Leg D. Following off: combat, riding and the finale pilot own the body then.
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
	_check(_recoveries() == before and ally.global_position.y < stand.y - 100.0,
		"D: a companion that is not following is left to its owning system (recoveries %s -> %s, y %.1f)" % [before, _recoveries(), ally.global_position.y])
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


## Leg E. The multiplayer rule: another peer's creature, drawn here by
## `remote_creature.gd`, answers false to `is_local_deployment()`.
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
	_check(not bool(helper.call("recoverable", remote)), "E: a remote copy of another peer's creature is never recovered locally")
	remote.set("local", true)
	_check(bool(helper.call("recoverable", remote)), "E: the same body owned here would be")
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
	_check(_player.is_on_floor(), "the trainer stands on the road at %s" % _player.global_position)


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

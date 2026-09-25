extends SceneTree

## F03 (WORLD §11 Hall-approach activity, Alpha Galecrest 5001). The activity
## is optional only if a player who keeps to the road can decline it. The pack
## is the chapter's largest AGGRESSIVE cluster, centred 36.6 m from the
## Stronghold-approach spine; an aggressor that notices a road walker chases
## and starts the fight itself, which would make the "optional" activity a
## toll on the main route.
##
## Witness: the same retained-five fixture as `smoke_alpha_pins.gd
## --hall-activity` (a fresh game, five members, seated on the spine south of
## the pack), then real `move_forward` input along the authored spine
## polyline (terrain_playground.json trail band `band5_stronghold_approach`)
## past the pack to the far side. PASS when no fight starts, no member of the
## pack is left chasing, and the trainer reaches the far waypoint. Receipts
## record the closest approach to the alpha and to any pack member.
##
##   godot --headless --path . --script tests/smoke_hall_alpha_decline.gd

const MEADOWS_SCENE := "res://scenes/world/meadows_playground.tscn"
const PILOT := preload("res://tools/combat_pilot.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const HALL_ONCE_FLAG := "wild_once_5001"
const PACK_ORDER := 5001
const HALL_PARTY := ["terrapup", "trailpup", "bramblebun", "burrowback", "meadowhart"]
const HALL_LEVEL := 18
## The spine, south to north past the pack (trail band points), starting a
## little up the first leg so the seat is on the road, not at its vertex.
const START_XZ := Vector2(-68.0, 7146.0)
const WAYPOINTS := [Vector2(-20.0, 7250.0), Vector2(30.0, 7310.0), Vector2(80.0, 7370.0)]
const ARRIVE_M := 2.5
const LEG_FRAMES := 2400

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_finish("no Game autoload")
		return
	game.call("reset_for_new_game")
	var party: RefCounted = game.get("party") as RefCounted
	party.call("clear")
	for species_id: String in HALL_PARTY:
		var member: RefCounted = SPECIES.spawn(species_id)
		if member == null or not bool(party.call("add", member)):
			_finish("could not create retained member " + species_id)
			return
		member.call("set_level", HALL_LEVEL, PROGRESSION.config())
		member.set("hp", member.get("max_hp"))

	var world := (load(MEADOWS_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 300:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	var manager := world.get_node_or_null(^"CombatManager") as Node
	var director := world.get_node_or_null(^"EncounterDirector") as Node
	if player == null or rig == null or manager == null or director == null:
		_finish("Meadows lacks live player, rig, manager or director")
		return
	var seat := Vector3(START_XZ.x, 0.0, START_XZ.y)
	seat.y = float(world.call("ground_height_at", seat.x, seat.z)) + 1.0
	player.set_physics_process(false)
	player.global_position = seat
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	rig.global_position = seat + Vector3.UP * float(rig.get("_height"))
	rig.reset_physics_interpolation()
	if director.call("ally_instance") == null and not await director.call("summon_active_creature"):
		_finish("retained active creature did not deploy at the road")
		return
	var ally := director.call("ally_body") as Node3D
	if ally != null:
		ally.set_physics_process(false)
	for _frame in 40:
		await physics_frame
	player.set_physics_process(true)
	if ally != null:
		ally.set_physics_process(true)
	director.call("_tick_streaming")

	var pack := await _pack(director)
	var alpha: Node3D = null
	for body: Node3D in pack:
		if str((director.get("_once_only") as Dictionary).get(body, "")) == HALL_ONCE_FLAG:
			alpha = body
	if alpha == null or pack.size() < 2:
		_finish("the authored Hall pack (order %d) was not built (alpha=%s, members=%d)" % [
			PACK_ORDER, str(alpha), pack.size()])
		return

	var pilot := PILOT.new(self, manager, director, rig)
	var closest_alpha := INF
	var closest_pack := INF
	for raw: Variant in WAYPOINTS:
		var xz := raw as Vector2
		var target := Vector3(xz.x, player.global_position.y, xz.y)
		# Walk in short slices so the closest approach is sampled along the way.
		var frames := 0
		while frames < LEG_FRAMES:
			var left := await pilot.walk_trainer_to(player, target, ARRIVE_M, 30)
			frames += 36
			closest_alpha = minf(closest_alpha, _flat(alpha, player))
			for body: Node3D in pack:
				closest_pack = minf(closest_pack, _flat(body, player))
			if bool(manager.call("is_fighting")):
				var foe := manager.call("enemy_body") as Node3D
				_finish("walking the road started a fight with %s (closest alpha %.1f m, pack %.1f m)" % [
					str(foe.name) if foe != null else "?", closest_alpha, closest_pack])
				return
			if left <= ARRIVE_M:
				break
		if frames >= LEG_FRAMES:
			_finish("road input did not reach waypoint (%.0f, %.0f)" % [xz.x, xz.y])
			return

	var chasing := 0
	for body: Node3D in pack:
		if _flat(body, player) < 12.0:
			chasing += 1
	if chasing > 0:
		_failures.append("%d pack member(s) followed the trainer to the far waypoint" % chasing)
	print("hall alpha decline receipt: " + JSON.stringify({
		"closest_alpha_m": snappedf(closest_alpha, 0.1),
		"closest_pack_m": snappedf(closest_pack, 0.1),
		"pack_members": pack.size(),
		"alpha_once_flag_set": bool((game.get("progression") as RefCounted).call("has", HALL_ONCE_FLAG)),
	}))
	_finish("")


func _pack(director: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for _frame in 120:
		found.clear()
		for candidate: Variant in director.get("_wild_creatures"):
			var body := candidate as Node3D
			if body != null and is_instance_valid(body) \
					and str(body.name).begins_with("Wild_galecrest_%d_" % PACK_ORDER):
				found.append(body)
		if not found.is_empty():
			return found
		await physics_frame
	return found


func _flat(body: Node3D, player: Node3D) -> float:
	if body == null or not is_instance_valid(body):
		return INF
	var d := body.global_position - player.global_position
	d.y = 0.0
	return d.length()


func _finish(failure: String) -> void:
	Input.action_release("move_forward")
	if not failure.is_empty():
		_failures.append(failure)
	if _failures.is_empty():
		print("hall alpha decline: OK -- road input walked the spine past the Hall pack without a fight")
		quit(0)
		return
	for f in _failures:
		print("hall alpha decline FAIL: " + f)
	quit(1)

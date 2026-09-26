extends RefCounted

## Real Deep Watch gate for Tidewake F13: win the named Tidecoil fight
## (`water_deep_watch_tidecoil`) in the production Water scene with real input.
##
## Entry: `await TidecoilFight.new().run(tree, world)` with the trainer already
## on Deep Watch (any dry point) and an owned party in `Game.local.party`.
## Steps, all by input on the production nodes:
##   1. walk (stick via stick_navigator, route from the pocket smoke's
##      `plan_route` over the baked ground) to the lowest dry shore nearest
##      Tidecoil's reef edge;
##   2. deploy the active lead by the `creature_recall` action;
##   3. stick toward the resident named body (the human wades/swims) until the
##      fight starts, either by Tidecoil's own aggressive initiation or by the
##      arbiter offering Engage on the director and one `interact` press;
##   4. the shared campaign pilot (tests/helpers/cloudreach_live_segment.gd
##      CampaignPilot over tools/combat_pilot.gd) presses move/quick/charged/
##      party_cycle through the production CombatManager to the manager's end.
## The completion flag must be written by the director's own won terminal; this
## helper writes no flag, HP, position or ledger entry. Returns a dictionary
## {won, resolved, outcome, engaged_by, ...} and prints one TIDECOIL line.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const WALK := preload("res://tests/smoke_water_pocket_walk_claim.gd")
const LIVE := preload("res://tests/helpers/cloudreach_live_segment.gd")
const PILOT := preload("res://tools/combat_pilot.gd")
const TIDECOIL_ID := "water_deep_watch_tidecoil"
const RESOLVED := "water_named_deep_watch_tidecoil_resolved"
const SITE := Vector3(1483.196, -0.5075, 3427.917)

var _tree: SceneTree
var _world: Node3D
var _player: CharacterBody3D
var _camera: Node3D
var _arbiter: Node
var _nav: RefCounted
var result := {}


func run(tree: SceneTree, world: Node3D) -> Dictionary:
	_tree = tree
	_world = world
	_player = world.get_node("Player")
	_camera = world.get_node("CameraRig")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	_nav = NAV.new(tree, _player, _camera, _stick)
	var game: Node = tree.root.get_node("Game")
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	result = {"won": false, "resolved": false, "outcome": "", "engaged_by": "", "step": "start"}
	# 1. Lowest dry, gentle shore nearest the reef edge (else the plateau).
	result.shore_kind = "low_shore"
	var stand := _shore()
	if not stand.is_finite():
		return _done("no low shore near Tidecoil")
	result.shore = stand
	var here := Vector2(_player.global_position.x, _player.global_position.z)
	var plan: Dictionary = WALK.plan_route(world, here, Vector2(stand.x, stand.z))
	var route: Array = plan.points
	if route.is_empty():
		return _done("no dry route to the shore")
	var walked := 0.0
	for index in route.size():
		var point: Vector2 = route[index]
		var before := _player.global_position
		var budget := maxi(900, int(Vector2(before.x, before.z).distance_to(point) * 90.0))
		var ok: bool = await _nav.walk_to(Vector3(point.x, 0.0, point.y), budget,
				2.0 if index == route.size() - 1 else 1.8)
		walked += Vector2(before.x, before.z).distance_to(Vector2(_player.global_position.x, _player.global_position.z))
		if not ok:
			return _done("shore walk stalled at leg %d/%d at %s" % [index + 1, route.size(), _player.global_position])
	_stick(0.0, 0.0)
	result.walked_to_shore_m = snappedf(walked, 1.0)
	# 2. Named body resident, lead deployed by input.
	var body: Node3D = null
	for _frame in 600:
		await tree.physics_frame
		body = _tidecoil(director)
		if body != null:
			break
	if body == null:
		return _done("named Tidecoil body never resident")
	if director.call("ally_body") == null:
		await _tap(&"creature_recall")
		for _frame in 30:
			await tree.physics_frame
	if director.call("ally_body") == null:
		return _done("creature_recall did not deploy the lead")
	# 3. Close on it until the fight starts.
	var engage_prompt := ""
	var closest := INF
	var stuck := 0
	var last := _player.global_position
	for frame in 5400:
		if bool(manager.call("is_fighting")):
			if str(result.engaged_by).is_empty():
				result.engaged_by = "tidecoil_initiated"
			break
		var winner: Dictionary = _arbiter.call("winner")
		if _arbiter.call("winning_provider") == director and bool(winner.get("actionable", false)):
			_stick(0.0, 0.0)
			engage_prompt = str(_arbiter.call("prompt"))
			result.engaged_by = "interact_engage"
			await _tap(&"interact")
			continue
		var flat := Vector3(body.global_position.x - _player.global_position.x, 0.0,
				body.global_position.z - _player.global_position.z)
		closest = minf(closest, flat.length())
		if frame % 60 == 59:
			stuck = stuck + 1 if last.distance_to(_player.global_position) < 0.5 else 0
			last = _player.global_position
		var direction := flat.normalized()
		if stuck > 1:
			direction = direction.rotated(Vector3.UP, 1.2 if (frame / 180) % 2 == 0 else -1.2)
		if flat.length() > 1.5:
			_nav.push_once(direction * 0.8)
		await tree.physics_frame
	_stick(0.0, 0.0)
	result.engage_prompt = engage_prompt
	result.closest_approach_m = snappedf(closest, 0.1)
	result.swimming_at_engage = _swimming()
	if not bool(manager.call("is_fighting")):
		return _done("fight never started; player=%s body=%s prompt=%s" % [
			_player.global_position, body.global_position, _arbiter.call("prompt")])
	var foe: Node = manager.call("enemy_body") as Node
	result.opponent = str(foe.get_meta("water_named_encounter", "")) if foe != null else ""
	# 4. Pilot the owned party to the manager's end.
	var pilot := LIVE.CampaignPilot.new(tree, manager, director, _camera)
	pilot.pilot = PILOT.Pilot.SPACER
	pilot.use_switching = false
	pilot.switch_input = true
	var hits := [0, 0]
	var on_hit := func(on_enemy: bool, _amount: float) -> void:
		hits[0 if on_enemy else 1] += 1
	manager.hit_landed.connect(on_hit)
	var observed: Dictionary = {}
	for _round in 6:
		observed = await pilot.fight_to_the_end()
		if not bool(manager.call("is_fighting")):
			break
	pilot._move_toward(Vector3.ZERO)
	manager.hit_landed.disconnect(on_hit)
	for _frame in 30:
		await tree.physics_frame
	var faints := 0
	for member: RefCounted in game.local.party.members():
		faints += int(bool(member.get("fainted")))
	result.outcome = str(observed.get("outcome", ""))
	result.timed_out = bool(observed.get("timed_out", false))
	result.fight_frames = pilot.fight_frames
	result.fight_seconds = snappedf(pilot.fight_frames / 60.0, 0.1)
	result.hits_dealt = hits[0]
	result.hits_taken = hits[1]
	result.charged = pilot.charged_thrown
	result.quick = pilot.quick_thrown
	result.switches = pilot.voluntary_switches
	result.fainted = "%d/%d" % [faints, game.local.party.members().size()]
	result.resolved = game.world.flags.has(RESOLVED)
	result.won = result.outcome == "won" and bool(result.resolved)
	return _done("won" if bool(result.won) else "fight ended without a recorded win")


func _done(step: String) -> Dictionary:
	_stick(0.0, 0.0)
	result.step = step
	print("TIDECOIL ", result)
	return result


func _shore() -> Vector3:
	var best := Vector3.INF
	for ring in range(8, 200, 3):
		for step in 90:
			var angle := TAU * step / 90.0
			var at := SITE + Vector3(cos(angle), 0.0, sin(angle)) * float(ring)
			var h := _h(at.x, at.z)
			if not is_finite(h) or h < 1.0 or h > 4.0:
				continue
			var gx := _h(at.x + 1.0, at.z) - _h(at.x - 1.0, at.z)
			var gz := _h(at.x, at.z + 1.0) - _h(at.x, at.z - 1.0)
			if not is_finite(gx) or not is_finite(gz) or rad_to_deg(atan(sqrt(gx * gx + gz * gz) * 0.5)) > 20.0:
				continue
			return at
	# Deep Watch meets the reef edge in a ~12 m cliff everywhere near Tidecoil
	# (probe: gentle 12-15 m plateau, then 12 m -> sea in ~4 m). Fallback: the
	# dry plateau point toward the island centre that smoke_water_deep_watch_chart
	# uses; the trainer then walks off the edge into the water by stick.
	for distance: float in [20.0, 25.0, 30.0, 40.0, 50.0, 60.0]:
		var candidate := SITE + (Vector3(1350.0, 0.0, 3500.0) - SITE).normalized() * distance
		if _h(candidate.x, candidate.z) >= 0.8:
			result.shore_kind = "cliff_plateau"
			return candidate
	return best


func _h(x: float, z: float) -> float:
	return float(_world.call("ground_height_at", x, z))


func _tidecoil(director: Node) -> Node3D:
	for wild: Variant in director.get("_wild_creatures"):
		if is_instance_valid(wild) and str((wild as Node).get_meta("water_named_encounter", "")) == TIDECOIL_ID:
			return wild as Node3D
	return null


func _swimming() -> bool:
	var swim: Node = _player.get("swim_controller")
	return swim != null and bool(swim.call("is_swimming"))


func _tap(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		for _frame in 6:
			await _tree.physics_frame


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)

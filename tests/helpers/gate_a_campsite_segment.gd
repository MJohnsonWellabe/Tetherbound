extends "res://tests/helpers/gate_b_tail_segment.gd"

## Gate A's paid-build continuation: the CURRENT paid build, placed by the
## controller out of the stock `gate_a_material_route.gd` just gathered.
##
## Why this replaced `gate_a_build_segment.gd` in the continuous run. That
## segment raises the legacy house (floors, walls, door, roof) and refuses to
## start below 39 wood / 34 stone. The material route stopped funding that bill
## when the house was retired for the campsite (its header: "The legacy house
## bill is gone"): it now gathers exactly `required_stock()` -- tent, campfire,
## bedroll and three creature beds, wood 30 / stone 8 / fiber 34 -- and
## SYSTEMS.md puts a "mandatory elaborate house" out of scope. So the continuous
## run always ended "caller has insufficient natural materials: need 39 wood and
## 34 stone" the moment the material route passed: the helper, not the game,
## was stale. Gate B already builds this campsite through
## `gate_b_tail_segment.gd`; this reuses that file's controller-driven
## placement (`_place_the_campsite`, `_place_the_creature_beds`, `_place_fixture`).
##
## One override. The tail's `_place_bedroll_in_tent` builds the bedroll
## directly (`build_real()` + `register_building`), which breaks Gate A's
## "every change to play state comes from a physical joypad event" contract.
## Here the bedroll is armed through the Build catalogue and placed with the
## Place button, from a stance that puts the live ghost inside the tent.
## Coordinator ruling (continuous-core repair): keep the controller-only rule
## for Gate A; the Gate B helper is left as it is and flagged as a follow-up.

const ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const BUILD_ROUTE := preload("res://tests/helpers/gate_a_build_segment.gd")
## Stance corrections allowed before the bedroll is called unplaceable. Each
## re-reads the camera's forward after the previous walk, so a camera that
## drifted during a walk is corrected rather than compounded.
const BEDROLL_AIM_ATTEMPTS := 5


func run_campsite(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		rig: Node3D, route: RefCounted) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = rig
	_progression = _game.get("progression") if _game != null else null
	_party = _game.get("party") if _game != null else null
	if _progression == null or _party == null or route == null:
		_fail("campsite segment dependencies are incomplete")
		return _result()
	if not _collect_nodes():
		return _result()
	_resolve_move_bindings()
	var required: Dictionary = ROUTE.required_stock()
	var before := {}
	for id: String in required.keys():
		before[id] = _count(id)
		if int(before[id]) < int(required[id]):
			_fail("the material route handed over %s; the campsite needs %s" % [_stock(), str(required)])
			return _result()

	if not await _walk_home(route):
		return _result()
	if not await _place_the_campsite():
		return _result()
	if not await _place_the_creature_beds():
		return _result()
	for id: String in required.keys():
		var spent := int(before[id]) - _count(id)
		if spent != int(required[id]):
			_fail("the campsite and three beds spent %d %s; the catalogue bill is %d"
				% [spent, id, int(required[id])])
	if failures.is_empty():
		transcript.append("paid campsite and three creature beds placed by controller; spent %s; %s left"
			% [str(required), _stock()])
	return _result()


## Back through a village gate (the route can end outside the fence), to the
## Village Square, then down the Practice Meadow road's own authored points to
## the build patch -- the same legs `gate_a_build_segment.gd` walks.
func _walk_home(route: RefCounted) -> bool:
	var square: Vector2 = BUILD_ROUTE.BUILD_ROUTE_XZ[0]
	var square_at := Vector3(square.x, _player.global_position.y, square.y)
	if not await route.call("cross_village_fence_toward", square_at):
		for line: Variant in (route.get("failures") as Array):
			_fail("walk home: %s" % str(line))
		if failures.is_empty():
			_fail("walk home: the village fence crossing ended without a verdict")
		return false
	for i in BUILD_ROUTE.BUILD_ROUTE_XZ.size():
		var point: Vector2 = BUILD_ROUTE.BUILD_ROUTE_XZ[i]
		var what := "the Village Square" if i == 0 else "Practice Meadow road point %d" % i
		var arrived := false
		for attempt in 3:
			if _nav != null:
				_nav.reset()
			arrived = await _walk_to(Vector3(point.x, _player.global_position.y, point.y),
				what, 2.0 if i > 0 else 0.75, attempt == 2, attempt == 2)
			if arrived:
				break
		if not arrived:
			return false
	transcript.append("walked home through the village to the Practice Meadow build patch")
	return true


## Controller-only bedroll: arm it in the Build catalogue, then stand so the
## live ghost (`build_placer.gd`: player + camera forward * PLACE_AHEAD,
## grid-snapped) falls on the tent, and press Place only once the ghost reads
## green -- which for a bedroll means `_bedroll_has_tent` accepted it.
func _place_bedroll_in_tent(tent: Node3D) -> Node3D:
	var target := tent.global_position
	var placer := _tree.get_first_node_in_group(&"build_placer")
	if placer == null:
		_fail("no BuildPlacer in the world; the bedroll cannot be placed")
		return null
	if not await _stow_piece():
		return null
	if not await _select_piece("bedroll"):
		return null
	await _settle(10)
	for attempt in BEDROLL_AIM_ATTEMPTS:
		var stance := target - _forward() * PLACE_AHEAD
		stance.y = _player.global_position.y
		await _walk_to(stance, "bedroll stance facing the tent (aim %d)" % (attempt + 1),
			MOVE_EPSILON, false, false)
		await _settle(10)
		if str(_game.get("pending_build")) != "bedroll":
			_fail("the armed bedroll was lost while lining up on the tent (pending '%s')"
				% str(_game.get("pending_build")))
			return null
		if not bool(placer.get("_ghost_ok")):
			transcript.append("bedroll ghost not green on aim %d (%s); re-aiming at the tent"
				% [attempt + 1, str(placer.get("_ghost_reason"))])
			continue
		var before: Array[Node] = _tree.get_nodes_in_group(&"placed_building")
		await _tap(&"build_place")
		await _settle(12)
		for node: Node in _tree.get_nodes_in_group(&"placed_building"):
			if before.has(node):
				continue
			if str(node.get_meta("building_id", "")) == "bedroll":
				await _stow_piece()
				transcript.append("bedroll placed inside the tent with the Place button")
				return node as Node3D
		_fail("a green bedroll ghost at the tent placed nothing")
		return null
	_fail("the controller could not line the bedroll ghost up inside the tent at %s in %d aims"
		% [str(target.round()), BEDROLL_AIM_ATTEMPTS])
	return null


## The tail's objective checks assume Gate B's state: a registered team, so
## `tournament_team_ready` is set and the ladder (objectives.json) has moved
## past `tournament_build_team` onto the camp rungs. Gate A reaches the build
## with its starter and one catch, and the ladder is ordered -- "Build your
## full team of five" comes BEFORE "Make camp" -- so the tracked line there
## must still be the team rung. Asserting the Gate B rung would demand the
## objective skip an unfinished step. So: with the team flag set, the parent's
## exact check runs unchanged; without it, the tracked rung must be exactly
## `tournament_build_team`, AND the camp rung the parent expected must have its
## own completion flag already written (checked where it can be named below),
## so the build still has to have registered as progress.
const RUNG_DONE_FLAG := {
	"tournament_build_home": "",  # asked after the campsite, before any bed: home_built must still be UNSET
	"tournament_build_creature_beds": "home_built",
	"tournament_sleep": "creature_bed_built_3",
}


func _objective_should_be(rung_id: String, after: String) -> void:
	if _flag("tournament_team_ready"):
		super._objective_should_be(rung_id, after)
		return
	var quest_log := QUEST_LOG.new()
	var tracked := str(quest_log.call("tracked_id", _progression))
	if tracked != "tournament_build_team":
		_fail("'%s' is done with the team not yet ready; the tracked objective is '%s', expected the "
			% [after, tracked] + "earlier 'tournament_build_team' rung to stay tracked")
	var done_flag := str(RUNG_DONE_FLAG.get(rung_id, ""))
	if not done_flag.is_empty() and not _flag(done_flag):
		_fail("'%s' is done and its progress flag '%s' is unset" % [after, done_flag])
	transcript.append("objective after %s: '%s' stays tracked (team of %d not yet ready); %s"
		% [after, tracked, int(_party.call("size")),
			"'%s' set" % done_flag if not done_flag.is_empty() else "camp rung pending its first bed"])


func _count(id: String) -> int:
	return int((_game.get("inventory") as RefCounted).call("count", id))

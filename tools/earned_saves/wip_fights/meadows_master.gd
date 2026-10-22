extends RefCounted

## Meadows adapter for Routes-owned master_visit.gd. Root must integrate that
## dependency before running. One invocation visits Orin OR Mira; the chain
## owner exports the actual save afterward. No XP, level, healing, recipe,
## reward or outcome is supplied here. Training to the cap is a prior piece.
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const HALL := preload("res://tests/helpers/meadows_earned_hall_segment.gd")
const STORAGE := preload("res://tools/earned_saves/wip_fights/storage_trip.gd")
const INPUT := preload("res://scripts/ui/input_owner.gd")
const VISIT_PATH := "res://tools/earned_saves/master_visit.gd"
const ROUTE := preload("res://tests/helpers/meadows_earned_material_segment.gd")
const LEVELS := {"master_t1": 10, "master_t2": 20}
const ROUND_FRAMES := 9000
var _tree: SceneTree
var _game: Node
var _travel: RefCounted
var _failures: Array[String] = []
var _receipts: Array = []

func run(tree: SceneTree, world: Node3D, game: Node, args: Dictionary = {}) -> Dictionary:
	_tree = tree
	_game = game
	_failures.clear()
	_receipts.clear()
	var master_id := str(args.get("master_id", ""))
	if not LEVELS.has(master_id):
		return _failed("Meadows adapter requires master_t1 (Orin) or master_t2 (Mira)")
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		return _failed("Master adapter requires the actual live world and Game")
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" or INPUT.current(tree) != null:
		return _failed("Master adapter requires ordinary input in the retained Meadows")
	if not ResourceLoader.exists(VISIT_PATH):
		return _failed("Root must integrate Routes-owned master_visit.gd before this piece")
	var party_before := _party()
	var selected := select_challenger(party_before, int(LEVELS[master_id]), str(args.get("creature_uid", "")))
	if selected.is_empty():
		return _failed("Need five retained unique creatures and a healthy challenger at exact level %d" % LEVELS[master_id])
	_travel = TRAVEL.new(tree, game)
	_receipts.append({"beat": "master_preflight", "master_id": master_id, "challenger": selected, "party": party_before})
	var visit: RefCounted = (load(VISIT_PATH) as Script).new()
	var outcome: Dictionary = await visit.run(tree, world, game, {
		"master_id": master_id, "creature_uid": str(selected.uid),
		"interact": func(prompt: Node3D) -> bool: return await _travel.activate(prompt),
		"tap": func(action: String) -> void: await _travel.tap(action),
		"fight_round": func() -> Dictionary: return await _fight_round(),
		# Orin stands past the South Bridge gully: travel by the village gates
		# and the bridge to a stand on the bridge side of the site first.
		"travel": func(site: Node3D) -> bool: return await _route_to(site),
		"storage": STORAGE,
		"rebind": func(returned: Node3D) -> bool:
			return returned == tree.current_scene and str(game.get("current_realm")) == "meadows" and _travel._bind(),
		"chest": true})
	_failures.append_array(outcome.get("failures", []))
	_failures.append_array(_travel.failures)
	_receipts.append_array(outcome.get("receipts", []))
	var party_after := _party()
	if party_after.map(func(card: Dictionary) -> String: return str(card.uid)) != party_before.map(func(card: Dictionary) -> String: return str(card.uid)):
		_failures.append("Master visit did not retain the same five creature identities in order")
	_receipts.append({"beat": "master_return", "party": party_after})
	return {"passed": bool(outcome.get("passed", false)) and _failures.is_empty(),
		"failures": _failures.duplicate(), "receipts": _receipts.duplicate(true)}

static func select_challenger(party: Array, level: int, wanted: String) -> Dictionary:
	if party.size() != 5:
		return {}
	var ids := {}
	var selected := {}
	for card: Dictionary in party:
		var uid := str(card.get("uid", ""))
		if uid.is_empty() or ids.has(uid):
			return {}
		ids[uid] = true
		if int(card.get("level", -1)) != level or bool(card.get("fainted", true)) or bool(card.get("resting", true)):
			continue
		if selected.is_empty() and (wanted.is_empty() or wanted == uid):
			selected = card.duplicate(true)
	return selected

func _route_to(site: Node3D) -> bool:
	var world := _tree.current_scene as Node3D
	var player := world.get_node_or_null("Player") as CharacterBody3D
	var rig := world.get_node_or_null("CameraRig") as Node3D
	if player == null or rig == null:
		return false
	var toward := Vector2(8.0, 1340.0) - Vector2(site.global_position.x, site.global_position.z)
	var stand := Vector2(site.global_position.x, site.global_position.z) + toward.normalized() * 4.0
	var walker := ROUTE.new()
	var arrived: bool = await walker.walk_route(_tree, world, _game, player, rig,
		Vector3(stand.x, float(world.call("ground_height_at", stand.x, stand.y)), stand.y))
	_failures.append_array(walker.failures)
	_receipts.append({"beat": "master_travel", "arrived": arrived, "stand": str(stand), "player": str(player.global_position)})
	return arrived


func _party() -> Array:
	var cards: Array = []
	for member: RefCounted in _game.get("party").call("members"):
		cards.append({"uid": str(member.get("uid")), "species": str(member.get("species_id")),
			"level": int(member.get("level")), "fainted": bool(member.get("fainted")), "resting": bool(member.get("resting"))})
	return cards

func _fight_round() -> Dictionary:
	# Routes currently records the callback result then polls the saved win.
	# Keep a failed callback yielding and input-free until its outer deadline;
	# never start a second attack attempt after a failed round.
	await _tree.physics_frame
	if not _failures.is_empty():
		return {"passed": false, "failures": _failures.duplicate()}
	var world := _tree.current_scene
	var rig := world.get_node_or_null("CameraRig") as Node3D
	var combat := world.get_node_or_null("CombatManager")
	var director := world.get_node_or_null("EncounterDirector")
	if rig == null or combat == null or director == null:
		return _failed("Master round lost the production camera/combat/director")
	var pilot := HALL.HallReader.new(rig)
	var start := Engine.get_physics_frames()
	while bool(combat.call("is_fighting")) and Engine.get_physics_frames() - start < ROUND_FRAMES:
		var ally := director.call("ally_body") as Node3D
		var foe := combat.call("enemy_body") as Node3D
		if not is_instance_valid(ally) or not is_instance_valid(foe):
			break
		pilot.step(combat, ally, foe)
		await _tree.physics_frame
	pilot.release_all()
	var finished := not bool(combat.call("is_fighting"))
	if not finished:
		_failures.append("Master round exceeded its deadline or lost an active body")
	return {"passed": finished, "frames": Engine.get_physics_frames() - start,
		"presses": pilot.presses.duplicate(), "read": pilot._tally.duplicate()}

func _failed(message: String) -> Dictionary:
	_failures.append(message)
	return {"passed": false, "failures": _failures.duplicate(), "receipts": _receipts.duplicate(true)}

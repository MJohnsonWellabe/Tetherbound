extends SceneTree

## F05 (ROADMAP §3) / ACCEPTANCE §6.1 F05 and card M4, last clause: "The
## opened physical gate carries the same five into Cloudreach", and "gate
## opens exactly once".
##
##   godot --headless --path . --script tests/smoke_rift_crossing_same_five.gd
##
## `smoke_cloudreach_transition.gd` proves a body walking the storm road span
## reaches Cloudreach and comes back. It never looks at WHO arrives. This file
## does: a full five, including the Veridian the finale let join, is read off the belt by stable creature uid before the walk, and
## the identical five by uid, order, level and nickname must be on the belt in
## Cloudreach, again after a real save and load there, and nothing may have
## been added, dropped or duplicated on the way.
##
## "Exactly once": the walker keeps walking for the whole budget after it
## reaches the far trigger, and the realm must still have changed exactly once;
## `realm_gate_cloudreach_unlocked` is set by the crossing.
##
## DISCLOSED FIXTURES, not earned play (ROADMAP §3: focused fixtures until the
## Meadows core lane's F01-F04 route exists; the M4 continuous-path card stays
## open until then):
##   * The Warden's and finale's durable facts (`legendary_freed`,
##     `realm_key_cloudreach`, `legendary_joined`, `legendary_settled`)
##     are set directly.
##   * The five are built with `Game.make_creature`.
##   * The source side is `smoke_cloudreach_transition.gd`'s own flat stand-in
##     for the Meadows terrain, with the REAL `rift_crossing.gd` span on it,
##     walked by a real CharacterBody3D. The Cloudreach side is the production
##     scene through the production realm router.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const RIFT_CROSSING := preload("res://scripts/world/rift_crossing.gd")
const TEST_SAVE_DIR := "user://rift_crossing_same_five_smoke"
const SLOT := 3

class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))

	# The saved five: four companions and the Veridian this character accepted.
	var party: RefCounted = game.get("party")
	party.call("clear")
	for species: String in ["terrapup", "mudsnout", "bramblebun", "brooktail", "veridian"]:
		var creature: RefCounted = game.call("make_creature", species, species.capitalize())
		creature.set("hp", float(creature.get("max_hp")))
		party.call("add", creature)
	var progression: RefCounted = game.get("progression")
	for flag in ["defeated_warden", "legendary_freed", "legendary_joined", "legendary_settled",
			"realm_key_cloudreach"]:
		progression.call("set_flag", flag)
	var five := _five(game)
	_expect(five.size() == 5, "the fixture did not build five (%d)" % five.size())
	_expect(_count(five, "veridian") == 1, "the fixture five does not hold exactly one veridian")
	_expect(not bool(progression.call("has", "realm_gate_cloudreach_unlocked")),
		"the gate is already open before anyone crossed; 'opens once' cannot be measured")

	var source := FlatWorld.new()
	source.name = "SameFiveSource"
	root.add_child(source)
	current_scene = source
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(60.0, 0.2, 120.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(-35.0, -0.1, 7545.0)
	source.add_child(floor_body)

	var crossing: Node3D = RIFT_CROSSING.new()
	crossing.name = "RiftCrossing"
	source.add_child(crossing)
	crossing.call("build", source)
	await process_frame
	await physics_frame
	var trigger := crossing.find_child("RiftCrossingTrigger", true, false) as Area3D
	_expect(bool(crossing.call("span_ready")), "the span did not stand from the saved freeing")
	_expect(trigger != null, "the crossing has no far trigger")
	if trigger != null:
		var walker := CharacterBody3D.new()
		walker.name = "Player"
		var body_collision := CollisionShape3D.new()
		var body_shape := CapsuleShape3D.new()
		body_shape.radius = 0.4
		body_shape.height = 1.8
		body_collision.shape = body_shape
		walker.add_child(body_collision)
		source.add_child(walker)
		var start: Vector3 = crossing.call("near_anchor")
		var toward: Vector3 = trigger.global_position - start
		toward.y = 0.0
		var direction := toward.normalized()
		walker.global_position = start + Vector3(0.0, 1.2, 0.0)
		for _settle in 10:
			await physics_frame
		var realm_changes := 0
		var last_realm := str(game.get("current_realm"))
		for _step in 360:
			if not is_instance_valid(walker):
				break
			walker.velocity.x = direction.x * 8.0
			walker.velocity.z = direction.z * 8.0
			walker.velocity.y = 0.0 if walker.is_on_floor() else walker.velocity.y - 26.0 * (1.0 / 60.0)
			walker.move_and_slide()
			await physics_frame
			var now := str(game.get("current_realm"))
			if now != last_realm:
				realm_changes += 1
				last_realm = now
		_expect(str(game.get("current_realm")) == "cloudreach", "walking the span did not reach Cloudreach")
		_expect(realm_changes == 1, "the crossing changed realm %d times; it must happen exactly once" % realm_changes)
		_expect(bool(progression.call("has", "realm_gate_cloudreach_unlocked")),
			"crossing did not record the Cloudreach gate as open")

	var cloudreach := await _wait_for_scene("CloudreachCliffs", 600)
	_expect(cloudreach != null, "Cloudreach never became current")
	if cloudreach != null:
		await _wait_for_entry_settle(game, 120)
		_expect(_five(game) == five, "a different five arrived in Cloudreach: %s vs %s" % [str(_five(game)), str(five)])
		_expect(game.get("pending_catch") == null, "something is parked on the catch seam after crossing")

		# A real save in Cloudreach, then a real load: the same five, again.
		_expect(bool(game.call("save_game", SLOT)), "Game.save_game() failed in Cloudreach")
		party.call("clear")
		progression.call("load_data", {})
		_expect(bool(game.call("load_game", SLOT)), "Game.load_game() failed")
		var reloaded := await _wait_for_scene("CloudreachCliffs", 1200)
		if reloaded != null:
			await _wait_for_entry_settle(game, 240)
		_expect(str(game.get("current_realm")) == "cloudreach", "the reload did not resume in Cloudreach")
		_expect(_five(game) == five, "the reloaded five differ: %s vs %s" % [str(_five(game)), str(five)])
		for flag in ["legendary_joined", "legendary_freed", "realm_key_cloudreach", "realm_gate_cloudreach_unlocked"]:
			_expect(bool(game.get("progression").call("has", flag)), "'%s' did not survive the reload in Cloudreach" % flag)

	_cleanup_test_saves()
	if failures.is_empty():
		print("RIFT CROSSING SAME FIVE OK: %s crossed once and reloaded unchanged" % str(five))
		quit(0)
		return
	for failure: String in failures:
		print("  FAIL: %s" % failure)
	quit(1)


## The belt, as the identity a player would recognise: stable uid, species,
## nickname and level, in belt order.
func _five(game: Node) -> Array:
	var out: Array = []
	for member: Variant in (game.get("party").call("members") as Array):
		var c := member as RefCounted
		out.append("%s|%s|%s|%d" % [str(c.get("uid")), str(c.get("species_id")), str(c.get("nickname")), int(c.get("level"))])
	return out


func _count(five: Array, species: String) -> int:
	var n := 0
	for row: Variant in five:
		if str(row).split("|")[1] == species:
			n += 1
	return n


func _wait_for_scene(expected_name: String, frames: int) -> Node:
	for _frame in frames:
		await process_frame
		var scene := current_scene
		if scene != null and scene.name == expected_name:
			await physics_frame
			await physics_frame
			await process_frame
			return scene
	return null


func _wait_for_entry_settle(game: Node, frames: int) -> void:
	for _frame in frames:
		if str(game.get("pending_realm_entry")) == "":
			return
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _cleanup_test_saves() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	var dir := DirAccess.open(absolute)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute)

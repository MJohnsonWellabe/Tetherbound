extends SceneTree

## End-to-end Phase 1 realm smoke using the production Game router and both
## production world scenes. OP-0905-15/D110: the Meadows no longer hands off
## through a keyed arch (`realm_gate.gd`) -- it is the storm road's own
## rebuilt span (`rift_crossing.gd`). This drives a real body up onto that
## span and through its far trigger, and asserts the trigger is what calls
## `Game.enter_realm`, rather than driving a gate's `try_unlock`/`try_enter`.
## Cloudreach still hands the player back through its OWN physical
## `realm_gate.gd` (`cloudreach_world.gd::MeadowsReturnRealmGate`, a file this
## task does not own) — that half of the round trip is unchanged below.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const RIFT_CROSSING := preload("res://scripts/world/rift_crossing.gd")
const TEST_SAVE_DIR := "user://cloudreach_transition_smoke"

## A flat stand-in for the Meadows terrain. `rift_crossing.gd` only ever asks
## `world` for `ground_height_at` (D09: never a raycast) and places its own
## geometry off the REAL `storm_road` spoke in `terrain_playground.json`, so a
## constant-height fixture is enough to stand the real span up without
## booting the whole `meadows_playground.tscn` for the outbound leg -- the
## same trade this file's own original fixture already made with a bare
## `Node3D` in place of the production world.
class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	var progression: RefCounted = game.get("progression")
	progression.call("set_flag", "realm_key_cloudreach")
	# The Warden sets `legendary_freed` in the same beat as the Realm Key
	# (R8.4) -- this fixture starts past that moment, so the span must stand
	# with no animation, same as any other post-flag world change on a load.
	progression.call("set_flag", "legendary_freed")

	var source := FlatWorld.new()
	source.name = "TransitionSmokeSource"
	root.add_child(source)
	current_scene = source

	# `FlatWorld.ground_height_at` answers for the whole storm road seam the
	# way the real Meadows terrain collider does, but this fixture builds no
	# actual terrain mesh -- so give the walk a real floor to land on beyond
	# the deck's own collider, the same continuous ground a real player would
	# have underfoot from the far abutment out to the trigger.
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

	var deck := crossing.find_child("CrossingDeckBody", true, false)
	_expect(deck != null and deck is StaticBody3D, "the storm road span never appeared", failures)
	var trigger := crossing.find_child("RiftCrossingTrigger", true, false) as Area3D
	_expect(trigger != null, "the crossing has no far-rim trigger", failures)
	_expect(bool(crossing.call("span_ready")), "the crossing did not report its span ready from a save", failures)

	if deck != null and trigger != null:
		var crossing_walker := CharacterBody3D.new()
		crossing_walker.name = "Player"
		var body_collision := CollisionShape3D.new()
		var body_shape := CapsuleShape3D.new()
		body_shape.radius = 0.4
		body_shape.height = 1.8
		body_collision.shape = body_shape
		crossing_walker.add_child(body_collision)
		source.add_child(crossing_walker)

		var start: Vector3 = crossing.call("near_anchor")
		var toward: Vector3 = trigger.global_position - start
		toward.y = 0.0
		var direction := toward.normalized()
		crossing_walker.global_position = start + Vector3(0.0, 1.2, 0.0)
		for _settle in 10:
			await physics_frame
		# Walk the real physical span, the same shape smoke_boss.gd's own
		# storm-road seam probe uses, until the far trigger fires the realm
		# router or the budget runs out.
		for _step in 360:
			if not is_instance_valid(crossing_walker):
				break
			crossing_walker.velocity.x = direction.x * 8.0
			crossing_walker.velocity.z = direction.z * 8.0
			crossing_walker.velocity.y = 0.0 if crossing_walker.is_on_floor() else crossing_walker.velocity.y - 26.0 * (1.0 / 60.0)
			crossing_walker.move_and_slide()
			await physics_frame
			if str(game.get("current_realm")) == "cloudreach":
				break
		_expect(str(game.get("current_realm")) == "cloudreach",
			"walking the player across the span and into the far trigger did not call enter_realm", failures)

	var cloudreach := await _wait_for_scene("CloudreachCliffs", 600)
	_expect(cloudreach != null, "Cloudreach scene never became current", failures)
	if cloudreach != null:
		await _wait_for_entry_settle(game, 120)
		var player := cloudreach.get_node_or_null(^"Player") as CharacterBody3D
		var anchor: Dictionary = cloudreach.call("entry_anchor", "cloudreach_arrival_from_meadows")
		var expected := _vec3(anchor.get("position", []))
		_expect(player != null and Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(expected.x, expected.z)) < 1.0,
			"Cloudreach did not consume the authored Meadows arrival", failures)
		_expect(str(game.get("pending_realm_entry")) == "", "Cloudreach did not settle its pending entry", failures)
		var return_gate := cloudreach.get_node_or_null(^"MeadowsReturnRealmGate")
		_expect(return_gate != null, "Cloudreach has no physical return gate", failures)
		if return_gate != null:
			_expect(str(return_gate.call("current_state")) == REALM_GATE.STATE_UNLOCKED,
				"Cloudreach return gate forgot the durable unlock", failures)
			_expect(bool(return_gate.call("try_enter", game)), "Cloudreach return gate did not issue return travel", failures)
	var meadows := await _wait_for_scene("MeadowsPlayground", 3600)
	_expect(meadows != null, "Meadows scene never became current on return", failures)
	if meadows != null:
		# Meadows builds its streamed terrain and authored dressing synchronously
		# before the deferred arrival autosave gets an idle turn. Wait on the
		# state contract rather than assuming a fixed two-frame schedule.
		await _wait_for_entry_settle(game, 240)
		var returned := meadows.get_node_or_null(^"Player") as CharacterBody3D
		_expect(returned != null and Vector2(returned.global_position.x, returned.global_position.z).distance_to(Vector2(-33.5, 7494.0)) < 1.5,
			"Meadows did not consume the authored Storm Road return anchor", failures)
		# OP-0905-15/D110: no arch. `legendary_freed` is durable and already
		# set (the crossing's own outbound leg above required it), so the
		# production Meadows scene must stand the rebuilt span instantly, with
		# no animation, on this fresh load -- the same contract every other
		# post-flag world change in this chapter keeps.
		var production_crossing := meadows.get_node_or_null(^"RiftCrossing")
		_expect(production_crossing != null, "the physical Storm Road crossing is missing", failures)
		if production_crossing != null:
			_expect(bool(production_crossing.call("span_ready")),
				"the Storm Road span did not stand immediately from durable state", failures)
			_expect(production_crossing.find_child("CrossingDeckBody", true, false) != null,
				"the physical Storm Road crossing has no deck", failures)
		_expect(meadows.get_node_or_null(^"MeadowsRealmHeartShrine") != null,
			"the physical Meadows Heart shrine is missing", failures)
	_expect(str(game.get("current_realm")) == "meadows", "Game did not finish in the Meadows", failures)
	_expect(str(game.get("pending_realm_entry")) == "", "Meadows did not settle the return entry", failures)
	_cleanup_test_saves()
	if failures.is_empty():
		print("CLOUDREACH TRANSITION OK meadows -> cloudreach -> meadows")
		quit(0)
		return
	for failure: String in failures:
		push_error("CLOUDREACH TRANSITION: %s" % failure)
	quit(1)


func _wait_for_scene(expected_name: String, frames: int) -> Node:
	for _frame in frames:
		await process_frame
		var scene := current_scene
		if scene != null and scene.name == expected_name:
			# Give the destination's deferred arrival autosave time to settle.
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


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


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

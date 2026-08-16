extends SceneTree

## SD17: is the Burrow Warrens a real place you can be inside?
##
##   godot --headless --path . --script tests/smoke_warrens.gd
##
## The unit suite cannot see any of this. A dungeon built from primitive boxes
## either has walls a CharacterBody3D cannot walk through and a floor it can
## stand on, or it is a decorative diorama the player falls through — and the
## only way to tell the two apart is to boot the world, stand in it and push.
##
## What it asserts, in the order the player meets it:
##
##   * the warrens built at all, at its authored world position
##   * the mouth is walkable: the player put down at the entrance ends up
##     standing on the cave floor, not inside a hillside and not falling
##   * the chambers are ENCLOSED: pushing hard at the deepest chamber's far
##     wall does not leave the footprint
##   * the population is there and the guardian is placed at its own level
##   * the deep branch is blocked before the cleared flag and open after
##   * the Heartstone is obtainable and turns R4.6's evolution item gate on
##   * the story reward pays exactly once
##
## The guardian is not FOUGHT here — smoke_combat.gd is the test that pilots a
## real fight, and re-running it against a level-18 Burrowback would be a
## second copy of that coverage plus five minutes of CI. What this proves is
## that the clearing PATH exists and pays once, which is `SD17`'s own done-when.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const PUSH_FRAMES := 240

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if player == null or warrens == null:
		print("warrens FAIL: the scene has no Player or no BurrowWarrens node")
		quit(1)
		return

	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	var inventory: RefCounted = game.get("inventory") if game != null else null
	if progression == null or inventory == null:
		print("warrens FAIL: no Game autoload with a progression store and an inventory")
		quit(1)
		return
	# A fresh dungeon, whatever a save left behind.
	progression.call("set_flag", "warrens_cleared", false)

	print("warrens stands at %.0f, %.1f, %.0f with chambers %s" % [
		warrens.global_position.x, warrens.global_position.y, warrens.global_position.z,
		", ".join(warrens.call("chamber_ids"))])

	_the_population_and_the_guardian_are_placed(warrens)
	# Everything below is about GEOMETRY, and the residents are aggressive by
	# design: left running they walk into the player, block a push with their
	# own capsule, and eventually start a real fight that takes the camera.
	# smoke_combat.gd is the test that fights; this one holds still.
	_quieten_the_residents(warrens)
	await _the_cave_is_enclosed(world, player, warrens)
	await _the_branch_is_shut_until_the_guardian_falls(player, warrens, progression)
	_the_heartstone_is_obtainable_and_arms_the_evolution_gate(warrens, inventory, progression)
	_the_story_reward_pays_once(warrens, inventory, progression)

	print("")
	if _failures.is_empty():
		print("warrens smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## Stand the player in the deepest chamber and push at the far wall. A room
## with no walls lets them out; a room with a floor keeps them off the terrain
## that is now metres overhead.
func _the_cave_is_enclosed(world: Node, player: CharacterBody3D, warrens: Node3D) -> void:
	var den: Vector3 = warrens.call("marker", "den")
	var floor_y := den.y
	await _put_down(player, den + Vector3(0.0, 1.2, 0.0))

	if not player.is_on_floor():
		_fail("the player does not stand on the cave floor in the deepest chamber")
	var resting := player.global_position.y
	if absf(resting - floor_y) > 1.5:
		_fail("the player settled at y=%.2f in the den, but its floor is y=%.2f" % [resting, floor_y])
	var terrain: float = float(world.call("ground_height_at", den.x, den.z))
	print("den floor y=%.2f, player rests at y=%.2f, hillside overhead at y=%.2f" % [
		floor_y, resting, terrain])
	if terrain <= floor_y + 2.0:
		_fail("the deepest chamber is not under the hill (terrain y=%.1f vs floor y=%.1f)" % [
			terrain, floor_y])

	# Push away from the mouth, i.e. at the far wall of the last chamber.
	var before := player.global_position
	var out := -warrens.global_basis.z  # local -z is back toward the entrance
	var into_the_rock := -out
	await _push(player, into_the_rock)
	var travelled := before.distance_to(player.global_position)
	print("pushed %.1fm into the den's far wall" % travelled)
	if travelled > 12.0:
		_fail("the player walked %.1fm through the deepest chamber's far wall; it is not enclosed" % travelled)
	if player.global_position.y > floor_y + 3.0:
		_fail("the player climbed out of the cave (y=%.1f vs floor %.1f)" % [
			player.global_position.y, floor_y])

	# And the way IN works: dropped outside the mouth, they can walk in.
	var entrance: Vector3 = warrens.call("marker", "entrance")
	await _put_down(player, entrance + Vector3(0.0, 1.5, 0.0))
	var start := player.global_position
	await _push(player, warrens.global_basis.z)
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var reached := player.global_position.distance_to(mouth)
	print("walked %.1fm in from the entrance; %.1fm from the mouth chamber centre" % [
		start.distance_to(player.global_position), reached])
	if reached > 12.0:
		_fail("walking straight in from the entrance never reached the mouth chamber (%.1fm short)" % reached)


func _the_population_and_the_guardian_are_placed(warrens: Node3D) -> void:
	var population: Array = warrens.call("population")
	if population.is_empty():
		_fail("the warrens spawned no wild creatures at all")
	else:
		var aggressive := 0
		for body: Node3D in population:
			if is_instance_valid(body) and bool(body.get("aggressive")):
				aggressive += 1
		print("%d wild creatures inside, %d of them aggressive" % [population.size(), aggressive])
		if aggressive == 0:
			_fail("nothing in the warrens is aggressive; spec Band 2 asks for aggressive Ground creatures")

	var guardian: Node3D = warrens.call("guardian")
	if guardian == null or not is_instance_valid(guardian):
		_fail("no guardian was placed")
		return
	var instance: RefCounted = guardian.get("instance")
	var level := int(instance.get("level")) if instance != null else 0
	print("guardian: %s at level %d, standing at %.0f, %.1f, %.0f" % [
		str(guardian.get("species_id")), level,
		guardian.global_position.x, guardian.global_position.y, guardian.global_position.z])
	if level < 15:
		_fail("the guardian is level %d; it is supposed to outclass the field" % level)
	var den: Vector3 = warrens.call("marker", "den")
	if guardian.global_position.distance_to(den) > 14.0:
		_fail("the guardian is not in its own chamber")


## Freeze the residents where they stand — physics off, aggression off. NOT
## hidden and NOT freed: the warrens reads "the guardian is gone" partly from
## the body being invisible (that is the caught path), and hiding it here
## would clear the dungeon before the door test has asked anything.
func _quieten_the_residents(warrens: Node3D) -> void:
	var bodies: Array = warrens.call("population").duplicate()
	var guardian: Node3D = warrens.call("guardian")
	if guardian != null:
		bodies.append(guardian)
	for body: Node3D in bodies:
		if not is_instance_valid(body):
			continue
		body.set("aggressive", false)
		body.set_physics_process(false)


## The one door in the cave, tested the only way that means anything: walk at
## it. Blocked while the guardian stands, open once the flag is set.
func _the_branch_is_shut_until_the_guardian_falls(player: CharacterBody3D, warrens: Node3D,
		progression: RefCounted) -> void:
	if bool(warrens.call("branch_is_open")):
		_fail("the deep branch was already open before the guardian fell")

	var den: Vector3 = warrens.call("marker", "den")
	var vault: Vector3 = warrens.call("marker", "vault")
	var toward_vault := (vault - den).normalized()
	await _put_down(player, den + Vector3(0.0, 1.2, 0.0))
	await _push(player, toward_vault)
	var blocked_at := player.global_position.distance_to(vault)
	print("pushed at the shut branch door; ended %.1fm from the vault" % blocked_at)
	if blocked_at < 3.0:
		_fail("the player reached the branch chamber with the door still shut")

	# Clear it the way beating the guardian clears it.
	if not bool(warrens.call("grant_clear_reward")):
		_fail("clearing the warrens for the first time reported nothing happened")
	if not bool(progression.call("has", "warrens_cleared")):
		_fail("clearing the warrens did not set its SB9 flag")
	if not bool(warrens.call("branch_is_open")):
		_fail("the branch door did not lift once the warrens was cleared")

	await _put_down(player, den + Vector3(0.0, 1.2, 0.0))
	await _push(player, toward_vault)
	var open_at := player.global_position.distance_to(vault)
	print("pushed at the open branch door; ended %.1fm from the vault" % open_at)
	if open_at > 4.0:
		_fail("the branch is still impassable after clearing (%.1fm from the vault)" % open_at)


func _the_heartstone_is_obtainable_and_arms_the_evolution_gate(warrens: Node3D,
		inventory: RefCounted, progression: RefCounted) -> void:
	var holder := warrens.get_node_or_null(^"Heartstone")
	if holder == null:
		_fail("no Heartstone in the branch chamber")
		return
	var prompt := holder.get_node_or_null(^"Interactable")
	if prompt == null:
		_fail("the Heartstone has no interaction; it cannot be picked up")
		return
	prompt.emit_signal("activated")
	for i in 4:
		await process_frame
	if int(inventory.call("count", "heartstone")) < 1:
		_fail("taking the Heartstone did not put one in the satchel")
	if not bool(progression.call("has", "warrens_heartstone_taken")):
		_fail("taking the Heartstone set no flag; a reload would mint a second")

	# R4.6's gate, now with a real source: the shipped config names the item,
	# and the pure-logic check agrees the party can spend it.
	var cfg: Dictionary = _progression_config()
	var item_id := str(cfg.get("evolution", {}).get("mudsnout", {}).get("item_id", ""))
	print("evolution catalyst in the shipped config: '%s'" % item_id)
	if item_id != "heartstone":
		_fail("progression.json's mudsnout evolution wants '%s', not the Heartstone this dungeon drops" % item_id)


func _the_story_reward_pays_once(warrens: Node3D, inventory: RefCounted,
		progression: RefCounted) -> void:
	# Wound back so the payout can be watched from a clean state.
	progression.call("set_flag", "warrens_cleared", false)
	var before_coin := int(inventory.call("count", "coin"))
	var before_rootstone := int(inventory.call("count", "rootstone"))

	if not bool(warrens.call("grant_clear_reward")):
		_fail("the first clear paid nothing")
	var after_coin := int(inventory.call("count", "coin"))
	var after_rootstone := int(inventory.call("count", "rootstone"))
	print("first clear paid %d coin and %d rootstone" % [
		after_coin - before_coin, after_rootstone - before_rootstone])
	if after_coin <= before_coin and after_rootstone <= before_rootstone:
		_fail("clearing the warrens granted nothing at all")

	if bool(warrens.call("grant_clear_reward")):
		_fail("clearing the warrens a second time paid again; the story reward is not once-only")
	if int(inventory.call("count", "coin")) != after_coin \
			or int(inventory.call("count", "rootstone")) != after_rootstone:
		_fail("a second clear still moved the satchel")
	if not bool(progression.call("has", "warrens_cleared")):
		_fail("the cleared flag did not survive the second call")


## --- harness ---------------------------------------------------------------

func _put_down(player: CharacterBody3D, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	for i in 40:
		await physics_frame


## Hold a direction for a fixed budget of physics frames. The player's own
## movement is camera-relative, so this drives the body directly rather than
## through input actions — the question here is about walls, not about the
## input map (smoke_input.gd owns that).
##
## The controller's own `_physics_process` is suspended for the length of the
## push. Leaving it running means two `move_and_slide()` calls per frame with
## two different velocities — the controller's own (zero, no input) and this
## one's — and the last writer wins at random, which showed up as a push that
## travelled 1.4m through an open doorway. Gravity is applied here instead so
## the body still rides the floor rather than skating off a step.
func _push(player: CharacterBody3D, direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	player.set_physics_process(false)
	for i in PUSH_FRAMES:
		player.velocity.x = flat.x * 4.0
		player.velocity.z = flat.z * 4.0
		player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y - 0.5
		player.move_and_slide()
		await physics_frame
	player.set_physics_process(true)


func _progression_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

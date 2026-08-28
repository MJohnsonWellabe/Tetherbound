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
##   * no ground comes through any chamber's floor
##   * the whole route -- entrance, mouth, hall, den, branch -- can be WALKED,
##     by the player's own controller, in one go
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
## CONTENT-0828B. The species' own unscaled size, so the guardian's alpha
## multiplier is checked against the animal rather than against a number
## copied into this file.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SETTLE_FRAMES := 240
const PUSH_FRAMES := 240
## The walked route (`_the_route_can_be_walked`): how close counts as arrived,
## and how long one leg may take before it has plainly run into something.
const ARRIVED_M := 3.0
const WALK_FRAMES := 600

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
	await _the_route_can_be_walked(player, warrens, progression)
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
	print("den floor y=%.2f, player rests at y=%.2f, terrain at the same spot y=%.2f" % [
		floor_y, resting, terrain])
	_no_ground_comes_through_a_floor(world, warrens)

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


## The check that would have caught BAND2-63-WARRENS a whole relocation
## earlier, and did not exist.
##
## What shipped from OW5D was a cave translated onto ground nobody had probed:
## the terrain surface ran THROUGH the hall, the player walked up it and jammed
## against the ceiling, and the den -- guardian, clear flag, heartstone -- was
## unreachable on foot. Every assertion in this file passed, because every one
## of them teleports the player into the chamber it is about.
##
## The rule a cave has to keep is simple and does not care whether it is buried
## in a flank or standing in a knoll of its own: at no point under a chamber
## may the ground be BETWEEN that chamber's floor and its ceiling. Above the
## ceiling is a buried room. Below the floor is a room standing proud on its
## own skirt. In between is a room with a hillside in it.
func _no_ground_comes_through_a_floor(world: Node, warrens: Node3D) -> void:
	var config := _warrens_config()
	var site: Dictionary = config.get("site", {})
	var floor_y: float = warrens.global_position.y + float(site.get("floor_clearance", 0.35))
	var worst := 0.0
	var worst_id := ""
	for entry: Variant in config.get("chambers", []):
		var chamber: Dictionary = entry as Dictionary
		var centre: Array = chamber.get("at", [0.0, 0.0])
		var size: Array = chamber.get("size", [4.0, 4.0])
		var ceiling: float = floor_y + float(chamber.get("height", 4.0))
		for ix in 5:
			for iz in 5:
				var local := Vector3(
					float(centre[0]) + float(size[0]) * (float(ix) / 4.0 - 0.5),
					0.0,
					float(centre[1]) + float(size[1]) * (float(iz) / 4.0 - 0.5))
				var at: Vector3 = warrens.to_global(local)
				var ground := float(world.call("ground_height_at", at.x, at.z))
				if is_nan(ground):
					continue
				# How far INTO the room the ground reaches, if it does at all.
				var into: float = minf(ground - floor_y, ceiling - ground)
				if into > worst:
					worst = into
					worst_id = str(chamber.get("id", ""))
	print("deepest the ground reaches into any chamber: %.2f m%s" % [
		worst, "" if worst_id == "" else " (%s)" % worst_id])
	if worst > 0.35:
		_fail("the ground surfaces %.2fm inside the '%s' chamber; the player will walk up it"
			% [worst, worst_id])


## The other half of the same lesson: walk the whole thing, with the player's
## own controller, through the doorways, in one go.
##
## `_push()` below drives `velocity` with `_physics_process` SUSPENDED, which is
## correct for the wall tests it was written for and useless for this one --
## `player_controller.gd::_try_step_up()` is what gets a CharacterBody3D over
## the cave's own doorway sill and it runs in `_physics_process`. So this
## presses the real `move_forward` action and steers by yawing the camera the
## movement is relative to, which is what a player does.
func _the_route_can_be_walked(player: CharacterBody3D, warrens: Node3D,
		progression: RefCounted) -> void:
	var config := _warrens_config()
	var chambers: Dictionary = {}
	for entry: Variant in config.get("chambers", []):
		chambers[str((entry as Dictionary).get("id", ""))] = entry
	await _put_down(player, warrens.call("marker", "entrance") + Vector3(0.0, 1.5, 0.0))
	# The branch door is the one thing on this route that is SUPPOSED to stop
	# the player, and the test above has already proved it does.
	progression.call("set_flag", "warrens_cleared")
	warrens.call("grant_clear_reward")
	var walked := 0.0
	for leg: String in ["mouth", "hall", "den", "vault"]:
		for target: Vector3 in _doorway_then_room(warrens, config, chambers, leg):
			walked += await _walk_to(player, warrens, target)
		var short: float = player.global_position.distance_to(warrens.call("marker", leg))
		if short > 3.5:
			_fail("walking the cave never reached the '%s' chamber (stopped %.1fm short)"
				% [leg, short])
			return
	print("walked the whole cave, entrance to branch chamber: %.0f m" % walked)


## The doorway into a chamber, then the chamber. A passage's side walls overlap
## the chamber wall they cut by `wall_thickness`, leaving a stub inside the room
## at the corner of the doorway; a person steers round it without noticing and a
## straight line into the far room's centre wedges on it.
func _doorway_then_room(warrens: Node3D, config: Dictionary, chambers: Dictionary,
		id: String) -> Array:
	var out: Array = []
	var room: Vector3 = warrens.call("marker", id)
	for entry: Variant in config.get("passages", []):
		var passage: Dictionary = entry as Dictionary
		if str(passage.get("to", "")) != id or not chambers.has(str(passage.get("from", ""))):
			continue
		var a: Array = (chambers[str(passage.get("from", ""))] as Dictionary).get("at", [0.0, 0.0])
		var b: Array = (chambers[id] as Dictionary).get("at", [0.0, 0.0])
		out.append(warrens.to_global(Vector3(
			(float(a[0]) + float(b[0])) * 0.5,
			room.y - warrens.global_position.y,
			(float(a[1]) + float(b[1])) * 0.5)))
	out.append(room)
	return out


## Hold `move_forward` with the camera yawed at `target` until the player is
## within `ARRIVED_M` of it or the budget runs out. Returns metres walked.
func _walk_to(player: CharacterBody3D, warrens: Node3D, target: Vector3) -> float:
	var rig: Node3D = _camera_rig(player)
	var walked := 0.0
	var frames := 0
	Input.action_press("move_forward")
	while frames < WALK_FRAMES:
		var to_target := target - player.global_position
		to_target.y = 0.0
		if to_target.length() <= ARRIVED_M:
			break
		if rig != null:
			# camera_rig.gd:239's own convention: the camera sits behind the
			# direction of travel.
			var yaw := atan2(-to_target.x, -to_target.z)
			rig.set("yaw", yaw)
			rig.rotation = Vector3(rig.rotation.x, yaw, 0.0)
		var before := player.global_position
		await physics_frame
		walked += Vector2(player.global_position.x - before.x,
			player.global_position.z - before.z).length()
		frames += 1
	Input.action_release("move_forward")
	return walked


func _camera_rig(player: CharacterBody3D) -> Node3D:
	var named: Variant = player.get("_camera_rig")
	if named is Node3D and is_instance_valid(named as Node3D):
		return named as Node3D
	for child in player.get_parent().get_children():
		if child is Node3D and child.has_method("planar_basis"):
			return child as Node3D
	return null


func _warrens_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/burrow_warrens.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


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
	# "Outclasses the field" is a RELATIVE claim, so measure it against the
	# field. This was a bare `level < 15` until SH47 retuned the warrens down
	# to sit where a player leaving Band 1 actually is (residents 10-13 -> 9-11,
	# guardian 18 -> 14) and the constant failed a guardian that had in fact
	# got RELATIVELY stronger: 15 was two levels over the old deepest resident,
	# 14 is three over the new one. A magic number here silently pins the
	# dungeon's tuning to whatever it happened to be the day it was written.
	var deepest := 0
	for body: Node3D in population:
		var resident: RefCounted = body.get("instance") if is_instance_valid(body) else null
		if resident != null:
			deepest = maxi(deepest, int(resident.get("level")))
	if level <= deepest:
		_fail("the guardian is level %d and the warrens' own residents reach %d; "
			% [level, deepest] + "it is supposed to outclass the field, not join it")
	var den: Vector3 = warrens.call("marker", "den")
	if guardian.global_position.distance_to(den) > 14.0:
		_fail("the guardian is not in its own chamber")

	# CONTENT-0828B. The owner's complaint was that the descent has no payoff,
	# and CONTENT-0828's answer to it was that the cave HAD an alpha and a
	# prize but the alpha did not READ as one -- it wore the ordinary
	# burrowback texture at a model-only scale, so a roadside duskhush looked
	# more like an alpha than the chapter's boss. Every part of that answer was
	# presentation, and NOTHING asserted any of it: the whole payoff could
	# regress to a big ordinary burrowback and this test would still pass and
	# still print the same line. Asserted against the config rather than
	# against numbers repeated here, so retuning the guardian stays a data edit.
	var spec: Dictionary = _warrens_config().get("guardian", {})
	if not guardian.has_meta("alpha"):
		_fail("the guardian is not marked as an alpha; encounter_director's own "
			+ "field alphas are, and the dungeon boss reading as less of an alpha "
			+ "than a roadside spawn is the defect CONTENT-0828 fixed")
	var want_scale := float(spec.get("scale", 1.0))
	if want_scale > 1.0:
		# The GAMEPLAY size, not the art pivot, and read through the public
		# accessors rather than off `body_scale`. `body_scale` is the
		# BEFORE-populate input field; the guardian is dressed AFTER the
		# director has spawned it, so it goes through
		# `apply_size_multiplier()`, which scales the live `_height`/`_radius`
		# and leaves `body_scale` at 1.0. Asserting the field would have
		# reported a bug that is not there and missed the one that would be.
		#
		# What is actually being asserted: `body_height()`/`body_radius()` are
		# what the capsule, the hit cone's reach and the catch accuracy bonus
		# all read, so if these moved with the silhouette then the fight moved
		# with it too -- and if they did not, the guardian is a big picture over
		# a field-sized body, which `creature_body.gd` calls "the invisible
		# discrepancy PW2 forbids": a swing that visually connects resolving
		# against a body that is not there.
		var look: Dictionary = SPECIES.placeholder(str(guardian.get("species_id")))
		var want_height := float(look.get("height", 0.0)) * want_scale
		if want_height > 0.0 and not is_equal_approx(float(guardian.call("body_height")), want_height):
			_fail("the guardian's body height is %.2f m but its species at %.2fx is %.2f m; "
				% [float(guardian.call("body_height")), want_scale, want_height]
				+ "the silhouette scaled and the capsule, reach and catch odds did not")
	var want_move := str(spec.get("signature_move", ""))
	if want_move != "" and instance != null:
		var charged := str(instance.get("move_charged"))
		if charged != want_move:
			_fail("the guardian's charged move is '%s' but its config asks for '%s'; "
				% [charged, want_move]
				+ "the signature move is what makes this a different fight rather than a longer one")
	print("guardian reads as an alpha: %.2f m tall (species %.2f m), charged move %s" % [
		float(guardian.call("body_height")),
		float(SPECIES.placeholder(str(guardian.get("species_id"))).get("height", 0.0)),
		str(instance.get("move_charged")) if instance != null else "?"])


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
	_before.clear()
	for entry: Variant in _clear_reward().get("items", []):
		var id := str((entry as Dictionary).get("id", ""))
		if id != "":
			_before[id] = int(inventory.call("count", id))

	if not bool(warrens.call("grant_clear_reward")):
		_fail("the first clear paid nothing")
	var after_coin := int(inventory.call("count", "coin"))
	var after_rootstone := int(inventory.call("count", "rootstone"))
	print("first clear paid %d coin and %d rootstone" % [
		after_coin - before_coin, after_rootstone - before_rootstone])
	if after_coin <= before_coin and after_rootstone <= before_rootstone:
		_fail("clearing the warrens granted nothing at all")

	# CONTENT-0828. Coin and rootstone alone are not the payout any more, and
	# checking only those two would have missed the part the design turns on.
	# The clear pays two Greater Orbs on purpose: the door the guardian's
	# defeat just opened has the only wild Terrapup in the game behind it
	# (burrow_warrens.json `_comment_spawns_special`), so the reward for
	# beating the alpha is the means to catch what it was standing in front
	# of. An item id typo'd in that file pushes an error and pays nothing, and
	# nothing else in the suite would have caught it: `test_chapter_rewards.gd`
	# checks the AUDIT names real items, and the audit is a different file from
	# the config the dungeon actually reads. So the assertion is against the
	# config's own list rather than against numbers repeated here -- retuning
	# the payout stays a data edit, dropping an item on the floor does not.
	var reward: Dictionary = _clear_reward()
	for entry: Variant in reward.get("items", []):
		var item: Dictionary = entry as Dictionary
		var id := str(item.get("id", ""))
		var want := int(item.get("count", 0))
		if id == "" or want <= 0:
			continue
		var moved: int = int(inventory.call("count", id)) - int(_before.get(id, 0))
		print("  clear reward: %d %s" % [moved, id])
		if moved < want:
			_fail("the clear reward names %d %s and the satchel gained %d" % [want, id, moved])

	if bool(warrens.call("grant_clear_reward")):
		_fail("clearing the warrens a second time paid again; the story reward is not once-only")
	if int(inventory.call("count", "coin")) != after_coin \
			or int(inventory.call("count", "rootstone")) != after_rootstone:
		_fail("a second clear still moved the satchel")
	if not bool(progression.call("has", "warrens_cleared")):
		_fail("the cleared flag did not survive the second call")


## --- harness ---------------------------------------------------------------

## What each reward item's count was before the payout, keyed by item id.
var _before: Dictionary = {}


## The clear reward as the dungeon's own config declares it. Read here rather
## than duplicated as literals so retuning the payout stays a data edit.
func _clear_reward() -> Dictionary:
	var file := FileAccess.open("res://data/config/burrow_warrens.json", FileAccess.READ)
	if file == null:
		_fail("burrow_warrens.json will not open")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("burrow_warrens.json did not parse as an object")
		return {}
	return ((parsed as Dictionary).get("clear", {}) as Dictionary).get("reward", {}) as Dictionary


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

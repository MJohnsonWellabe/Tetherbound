extends SceneTree

## R8.2/SG38: is the stronghold route a real place you can walk, in order?
##
##   godot --headless --path . --script tests/smoke_stronghold.gd
##
## Same argument `smoke_warrens.gd` makes for the dungeon, and the same shape.
## A route built from primitive boxes either has floors a CharacterBody3D can
## stand on, walls it cannot walk through and doorways it can, or it is a
## diorama the player falls out of — and the only way to tell those apart is to
## boot the world, stand in it and push.
##
## What it asserts, in the order the player meets it:
##
##   * the complex built, with spec §8's five spaces in §8's order
##   * every one of the five has a floor the player actually stands on
##   * they are traversable IN ORDER: pushed from each space toward the next,
##     the player arrives — including the corner into the Legendary Chamber
##   * the one door is shut before the elite falls and open after, so the
##     Warden Arena is genuinely behind the gauntlet
##   * each gauntlet trainer is placed in its own space and is challengeable
##   * the recovery point is a real creature bed and really revives and heals
##   * the Legendary Chamber holds the machine massing, at the board's scale,
##     and reports itself as the PLACEHOLDER it is
##
## Nobody is FOUGHT here. `smoke_trainer_battle.gd` is the test that pilots a
## trainer fight end to end and re-running it three times would be three copies
## of that coverage plus ten minutes of CI. What this proves is that the route
## exists, that its fights are reachable and challengeable in order, and that
## the door between them is real.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const HOME_RECOVERY := preload("res://scripts/creatures/home_recovery.gd")

const SETTLE_FRAMES := 240
## 600 physics frames at 4 m/s is 40m of walking — the longest hop on the route
## (the outer works to the courtyard) is 32m centre to centre. A budget that
## merely ALMOST covers the distance reads as a wall in the report, which is
## exactly how the first run of this test mis-reported two perfectly good
## doorways.
const PUSH_FRAMES := 600

## §8's five spaces, in §8's order. Hard-coded HERE on purpose: this is the one
## thing in the item that is not tunable, and a test that read the order out of
## the same config the builder reads could not catch it being reordered.
const ROUTE := ["outer_works", "courtyard", "tether_approach", "warden_arena", "legendary_chamber"]
const ELITE_FLAG := "defeated_stronghold_elite"

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
	var hold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	if player == null or hold == null:
		print("stronghold FAIL: the scene has no Player or no Stronghold node")
		quit(1)
		return

	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression == null:
		print("stronghold FAIL: no Game autoload with a progression store")
		quit(1)
		return
	# A fresh stronghold, whatever a save left behind.
	progression.call("set_flag", ELITE_FLAG, false)

	print("stronghold stands at %.0f, %.1f, %.0f" % [
		hold.global_position.x, hold.global_position.y, hold.global_position.z])

	_the_five_spaces_exist_in_order(hold)
	await _the_player_stands_on_every_floor(player, hold)
	await _the_way_in_is_walkable(player, hold)
	_the_gauntlet_is_placed_and_challengeable(world, hold)
	_the_recovery_point_revives_and_heals(hold)
	_the_machine_stands_in_the_legendary_chamber(hold)
	await _the_route_is_traversable_in_order(player, hold, progression)

	print("")
	if _failures.is_empty():
		print("stronghold smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## §8 names five spaces and names them in one order. Nothing else in the item
## is allowed to reorder them.
func _the_five_spaces_exist_in_order(hold: Node3D) -> void:
	var route: Array = hold.call("route")
	print("route: %s" % " -> ".join(route))
	if route.size() != ROUTE.size():
		_fail("the stronghold has %d spaces; spec §8 names %d" % [route.size(), ROUTE.size()])
	for i in mini(route.size(), ROUTE.size()):
		if str(route[i]) != ROUTE[i]:
			_fail("space %d is '%s'; spec §8 puts '%s' there" % [i + 1, str(route[i]), ROUTE[i]])
	for id: String in ROUTE:
		var size: Vector3 = hold.call("chamber_size", id)
		if size.x < 6.0 or size.y < 6.0 or size.z < 3.0:
			_fail("'%s' is %.0fx%.0fx%.0fm; that is not a space the player can fight in" % [
				id, size.x, size.y, size.z])
		else:
			print("  %-18s %.0f x %.0f m, %.0fm to the ceiling" % [id, size.x, size.y, size.z])


## A built floor above its own ground, five times over. The player is put down
## a little over each space's marker and has to settle ON it — not fall through
## the slab, and not land on the meadow several metres below.
func _the_player_stands_on_every_floor(player: CharacterBody3D, hold: Node3D) -> void:
	for id: String in ROUTE:
		# The middle of the Legendary Chamber is 15m of machine, so the floor
		# there is checked where a player actually gets to stand: the mark the
		# reveal is staged from.
		var at: Vector3 = hold.call("marker", "reveal_stand" if id == "legendary_chamber" else id)
		await _put_down(player, at + Vector3(0.0, 1.4, 0.0))
		var resting := player.global_position.y
		if not player.is_on_floor():
			_fail("the player does not stand on '%s''s floor" % id)
		if absf(resting - at.y) > 1.6:
			_fail("the player settled at y=%.2f in '%s', whose floor is y=%.2f" % [resting, id, at.y])
		print("  %-18s floor y=%.2f, player rests at y=%.2f" % [id, at.y, resting])


## The complex's floor stands above its own highest ground, which on this site
## is metres over the meadow at the west end. So the way in is a long sampled
## ramp, and the only question worth asking about a ramp is whether a capsule
## can actually climb it — `burrow_warrens.gd`'s apron exists because a 0.35m
## sill silently stopped a smoke test 1.4m short of an open cave mouth.
func _the_way_in_is_walkable(player: CharacterBody3D, hold: Node3D) -> void:
	var entrance: Vector3 = hold.call("marker", "entrance")
	var first: Vector3 = hold.call("marker", "outer_works")
	await _put_down(player, entrance + Vector3(0.0, 1.5, 0.0))
	var start := player.global_position
	await _push(player, (first - entrance).normalized())
	var reached := player.global_position.distance_to(first)
	print("walked %.1fm in from the entrance; %.1fm from the Outer Works' centre" % [
		start.distance_to(player.global_position), reached])
	if reached > 14.0:
		_fail("walking in from the entrance never reached the Outer Works (%.1fm short)" % reached)
	if absf(player.global_position.y - first.y) > 1.6:
		_fail("the player came in at y=%.2f but the works' floor is y=%.2f" % [
			player.global_position.y, first.y])


## SG38: three fights across the five spaces (the Warden himself is R8.3's
## fourth). Each has to be a body standing in its OWN space, offering a prompt,
## with a team and a defeat flag of its own.
func _the_gauntlet_is_placed_and_challengeable(world: Node, hold: Node3D) -> void:
	var trainers: Node3D = hold.call("trainers_node")
	if trainers == null:
		_fail("the stronghold placed no trainers at all; SG38's gauntlet is missing")
		return
	var director := world.get_node_or_null(^"EncounterDirector")
	var expected := {
		"stronghold_patrol": "outer_works",
		"stronghold_courtyard": "courtyard",
		"stronghold_elite": "tether_approach",
	}
	var placed := int(trainers.call("placed"))
	print("gauntlet: %d trainer(s) placed" % placed)
	if placed < 2 or placed > 4:
		_fail("the gauntlet fields %d trainers; §8/§12 ask for 2-4 across the five spaces" % placed)

	var flags := {}
	for id: String in expected:
		var body: Node3D = trainers.call("body_for", id) as Node3D
		if body == null:
			_fail("gauntlet trainer '%s' was never stood up" % id)
			continue
		var room: Vector3 = hold.call("marker", expected[id])
		var away := body.global_position.distance_to(room)
		var spec: Dictionary = TRAINERS.trainer(id)
		var team: Array = TRAINERS.team_of(spec)
		var flag := str(spec.get("defeat_flag", ""))
		print("  %-22s in %-16s (%.1fm from its centre), %d creature(s), flag '%s'" % [
			id, str(expected[id]), away, team.size(), flag])
		if away > 16.0:
			_fail("'%s' is %.1fm from the middle of '%s'; it is not in its own space" % [
				id, away, str(expected[id])])
		if team.is_empty():
			_fail("'%s' fields nobody; there is no fight there" % id)
		if flag == "":
			_fail("'%s' has no defeat_flag; beating them would change nothing" % id)
		elif flags.has(flag):
			_fail("'%s' shares a defeat flag with '%s'" % [id, str(flags[flag])])
		else:
			flags[flag] = id
		if body.get_node_or_null(^"Interactable") == null:
			_fail("'%s' offers no prompt; they cannot be challenged" % id)
		if director != null and not bool(director.call("can_challenge", spec)):
			# Only meaningful with a living ally, which this test does not set
			# up — reported, not failed, so the check stays honest about what
			# it actually proves. smoke_trainer_battle.gd owns the live path.
			print("    (not challengeable right now: no living ally in this bare boot)")


## SG38's recovery opportunity, and the one assertion that matters about it: a
## fainted, hurt creature comes back. `home_recovery.gd` is the shared logic and
## it is what the panel calls, so this drives the same function the player does.
func _the_recovery_point_revives_and_heals(hold: Node3D) -> void:
	var bed: Node3D = hold.call("recovery_point")
	if bed == null:
		_fail("there is no recovery point before the Warden")
		return
	var at: Vector3 = hold.call("marker", "recovery")
	var approach: Vector3 = hold.call("marker", "tether_approach")
	print("recovery point at %.0f, %.1f, %.0f (%.1fm into the Tether Chamber Approach)" % [
		at.x, at.y, at.z, at.distance_to(approach)])
	if at.distance_to(approach) > 14.0:
		_fail("the recovery point is not in the Tether Chamber Approach, where §8 puts it")
	if bed.get_node_or_null(^"Interactable") == null:
		_fail("the recovery point offers no interaction; it cannot be used")

	var cfg := _progression_config()
	var creature: RefCounted = TRAINERS.creature_for({"species": "mudsnout", "level": 12})
	if creature == null:
		_fail("no mudsnout in species.json; the rest check cannot run")
		return
	creature.set("hp", 0.0)
	creature.set("fainted", true)
	var before_xp := int(creature.get("xp"))
	HOME_RECOVERY.rest(creature, cfg)
	print("rested a fainted level-12 mudsnout: fainted=%s hp=%d/%d, xp %d -> %d" % [
		str(creature.get("fainted")), int(creature.get("hp")), int(creature.get("max_hp")),
		before_xp, int(creature.get("xp"))])
	if bool(creature.get("fainted")):
		_fail("resting at the stronghold's recovery point did not revive a fainted creature")
	if int(creature.get("hp")) < int(creature.get("max_hp")):
		_fail("resting did not heal to full")


## The centrepiece, and the seam. This asserts the SCALE (which is real work and
## survives the asset swap) and asserts that the build still calls itself a
## placeholder (which is the honest part).
func _the_machine_stands_in_the_legendary_chamber(hold: Node3D) -> void:
	var machine: Node3D = hold.call("machine")
	if machine == null:
		_fail("the Legendary Chamber has no tether mechanism in it")
		return
	var chamber: Vector3 = hold.call("marker", "legendary_chamber")
	var away := machine.global_position.distance_to(chamber)
	var placeholder: bool = bool(hold.call("machine_is_placeholder"))
	var aabb := _aabb_of(machine)
	print("machine '%s': %.1fm from the chamber centre, bounding %0.1f x %0.1f x %0.1f m, placeholder=%s" % [
		machine.name, away, aabb.size.x, aabb.size.y, aabb.size.z, str(placeholder)])
	if away > 2.0:
		_fail("the machine is %.1fm off the middle of its own chamber" % away)
	if aabb.size.y < 12.0:
		_fail("the machine stands %.1fm tall; its board draws it at ~15m" % aabb.size.y)
	var room: Vector3 = hold.call("chamber_size", "legendary_chamber")
	if room.z < aabb.size.y + 3.0:
		_fail("the chamber's %.0fm ceiling does not clear its own %.1fm machine" % [room.z, aabb.size.y])
	if placeholder and machine.name != "TetherMachinePlaceholder":
		_fail("the machine is a placeholder but is not named as one; the seam is hidden")
	if not placeholder:
		print("  (the licensed hero asset is installed; this run is not testing the placeholder)")


## The route, walked. From each space's centre, push toward the next and check
## the player gets there — the doorway between them is either cut or it is not.
## The shutter into the Warden Arena is checked BOTH ways round on the way past.
func _the_route_is_traversable_in_order(player: CharacterBody3D, hold: Node3D,
		progression: RefCounted) -> void:
	if bool(hold.call("door_is_open", ELITE_FLAG)):
		_fail("the way into the Warden Arena was already open before the elite fell")

	for i in ROUTE.size() - 1:
		var from_id: String = ROUTE[i]
		var to_id: String = ROUTE[i + 1]
		var from: Vector3 = hold.call("marker", from_id)
		var to: Vector3 = hold.call("marker", to_id)
		var gated := to_id == "warden_arena"

		if gated:
			# Shut: pushing at it must NOT reach the arena.
			await _put_down(player, from + Vector3(0.0, 1.2, 0.0))
			await _push(player, (to - from).normalized())
			var blocked := player.global_position.distance_to(to)
			print("  %s -> %s with the shutter down: ended %.1fm short" % [from_id, to_id, blocked])
			if blocked < 6.0:
				_fail("the player reached the Warden Arena with the shutter still down")
			# Beaten, the way beating the elite beats it.
			progression.call("set_flag", ELITE_FLAG)
			for f in 8:
				await process_frame
			if not bool(hold.call("door_is_open", ELITE_FLAG)):
				_fail("the shutter did not lift once the elite's defeat flag was set")

		await _put_down(player, from + Vector3(0.0, 1.2, 0.0))
		await _push(player, (to - from).normalized())
		var reached := player.global_position.distance_to(to)
		var half: Vector3 = hold.call("chamber_size", to_id)
		var allowed := maxf(half.x, half.y) * 0.5 + 2.0
		print("  %s -> %s: ended %.1fm from its centre (allowed %.1f)" % [
			from_id, to_id, reached, allowed])
		if reached > allowed:
			_fail("walking from '%s' toward '%s' never got there (%.1fm short)" % [
				from_id, to_id, reached])
		if not player.is_on_floor():
			_fail("the player left the floor walking from '%s' to '%s'" % [from_id, to_id])


## --- harness ---------------------------------------------------------------

func _aabb_of(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child in _all_children(node):
		var mesh := child as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var local := mesh.mesh.get_aabb()
		var here := AABB(node.to_local(mesh.global_position) + local.position, local.size)
		if first:
			box = here
			first = false
		else:
			box = box.merge(here)
	return box


func _all_children(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_all_children(child))
	return out


func _put_down(player: CharacterBody3D, at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	for i in 40:
		await physics_frame


## Hold a direction for a fixed budget of physics frames, driving the body
## directly. Same technique — and the same suspension of the controller's own
## `_physics_process` — that `smoke_warrens.gd` documents: two `move_and_slide()`
## calls a frame with two different velocities is a race, and it showed up there
## as a push that travelled 1.4m through an open doorway.
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

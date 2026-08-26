extends SceneTree

## Does the fight park the trainer somewhere solid?
##
##   godot --headless --path . --script tools/_probe_stand_aside.gd
##
## `combat_manager.gd::_stand_the_trainer_aside` moves the trainer out of the
## camera's way when a fight opens:
##
##     var spot := centre + side * (radius * 0.55) - forward * 1.2
##     var height := _ground_height(spot.x, spot.z)
##     if not is_nan(height): spot.y = height
##     _player.global_position = spot
##
## The HEIGHT is validated. Nothing validates whether anything is standing
## there. It is a raw position write, not a physics move, so a rock, a tree or a
## boulder at that spot ends with the body inside it -- and the body stays there
## when the fight ends, which is where the next walk begins.
##
## That is the shape of the still-open CI failure: `stopped 23.7m away` against a
## target 23.2m from the start, i.e. a walk that covered nothing. Check-in 9
## measured that all three practice-cluster targets are reachable FROM THE START
## POINT, so the route is fine and the start is not.
##
## This engages real fights and reports, for each, whether the spot the trainer
## was moved to is clear -- eight sweeps through the physics server with the
## body's own shape, the same predicate `player_controller.gd::_entombed_at`
## uses. It changes nothing and asserts nothing.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const START := Vector3(48.0, 0.0, -58.0)
const PROBE_M := 0.45
const STEP_HEIGHT := 0.35


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var manager := world.get_node_or_null(^"CombatManager")
	if player == null or rig == null or director == null or manager == null:
		print("missing a node")
		quit(1)
		return
	var game := root.get_node_or_null(^"Game")
	if game != null:
		var inv: RefCounted = game.get("inventory")
		if inv != null:
			inv.call("add", "orb_basic", 30)
	if director.call("ally_instance") == null:
		await director.call("adopt_starter", "terrapup")

	var blocked := 0
	for attempt in 3:
		var start := START
		start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
		player.global_position = start
		player.velocity = Vector3.ZERO
		for i in 30:
			await physics_frame

		var target: Node3D = null
		for i in 400:
			await physics_frame
			var c := director.call("wild_creature") as Node3D
			if c != null and c.visible and bool(c.call("is_alive")):
				target = c
				break
		if target == null:
			print("attempt %d: no wild creature" % attempt)
			break

		var name := str(target.name)
		for i in 1500:
			if not is_instance_valid(target):
				break
			var to := target.global_position - player.global_position
			to.y = 0.0
			if to.length() <= 3.6:
				break
			rig.set("yaw", atan2(-to.x, -to.z))
			Input.action_press("move_forward")
			await physics_frame
		Input.action_release("move_forward")
		for i in 10:
			await physics_frame

		var before := player.global_position
		Input.action_press("interact")
		await physics_frame
		await physics_frame
		Input.action_release("interact")
		for i in 60:
			await physics_frame

		if not bool(manager.call("is_fighting")):
			print("attempt %d (%s): did not engage from %.1f, %.2f, %.1f" % [
				attempt, name, before.x, before.y, before.z])
			continue

		var after := player.global_position
		var clear := _clear_directions(player)
		if clear < 8:
			blocked += 1
		print("attempt %d (%s): engaged. trainer moved %.1f, %.2f, %.1f -> %.1f, %.2f, %.1f (%.1fm). clear directions %d/8%s" % [
			attempt, name, before.x, before.y, before.z, after.x, after.y, after.z,
			before.distance_to(after), clear, "   <-- STOOD IN SOMETHING" if clear < 8 else ""])

		# Leave the fight the way the tests do rather than resolving it: this
		# probe is about the placement, not the catch.
		manager.call("end_fight") if manager.has_method("end_fight") else null
		for i in 60:
			await physics_frame

	print("")
	print("%d of 3 engagements left the trainer with a blocked direction" % blocked)
	quit(0)


## How many of eight compass directions the body can sweep into, from
## STEP_HEIGHT up. The same predicate player_controller.gd::_entombed_at uses.
func _clear_directions(player: CharacterBody3D) -> int:
	var raised := player.global_transform.translated(Vector3.UP * STEP_HEIGHT)
	var clear := 0
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var dir := Vector3(sin(angle), 0.0, cos(angle))
		if not player.test_move(raised, dir * PROBE_M):
			clear += 1
	return clear

extends SceneTree

## T5-CARE: where does an ordinary player come back to after a death or a fall?
##
##   godot --headless --path . --script tools/_play_t5_respawn.gd
##
## Section H asks whether the player understands where their things went when
## they die, and section I9 asks that core verbs never fail. Both run through
## one number: `playground_world.gd::_spawn_position`, which is what
## `player_death.gd` and the world perimeter corridor BOTH teleport the player
## to.
##
## `_place_player()` sets it from the Player node's own scene position -- the
## world ORIGIN -- and runs before the settlement is built. `data/config/
## village.json` puts the `workshop` at (2, 2), whose footprint covers that
## origin. So this checks the thing that follows: is the respawn point inside a
## building, and what happens to a player returned to it?
##
## Run WITHOUT the free-play flag, i.e. the ordinary opening, because the point
## is what happens to a real player rather than to a harness fixture.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("T5> no player")
		quit(1)
		return

	var spawn: Vector3 = world.get("_spawn_position")
	print("")
	print("T5> === respawn point audit (ordinary opening, no fixture flags) ===")
	print("T5> the player is standing at %s" % str(player.global_position))
	print("T5> _spawn_position (used by player_death.gd AND the perimeter rescue) = %s" % str(spawn))

	# Is that point inside anything?
	var space := world.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	query.shape = capsule
	query.transform = Transform3D(Basis(), spawn)
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]
	var hits: Array = space.intersect_shape(query, 16)
	print("T5> bodies overlapping a player capsule at the respawn point: %d" % hits.size())
	var names := {}
	for h: Variant in hits:
		var node := (h as Dictionary)["collider"] as Node
		var parent := node.get_parent()
		var label := "%s under %s" % [node.name, parent.name if parent != null else "-"]
		names[label] = true
	for label: String in names.keys():
		print("T5>   %s" % label)

	# Now DO it: put the player there the way a death does, and watch.
	print("T5> --- teleporting the player to the respawn point, as a death does ---")
	player.global_position = spawn
	player.velocity = Vector3.ZERO
	var launched := false
	var worst := 0.0
	for i in 180:
		await physics_frame
		var speed := player.velocity.length()
		worst = maxf(worst, speed)
		if speed > 1000.0:
			launched = true
	var landed := player.global_position
	print("T5> 3 seconds later the player is at %s (top speed reached %.0f m/s)" % [str(landed), worst])
	var distance := Vector2(landed.x, landed.z).distance_to(Vector2(spawn.x, spawn.z))
	if launched or distance > 50.0:
		print("T5> VERDICT: FAIL — respawning threw the player %.0fm from the respawn point "
			% distance + "at up to %.0f m/s. Death and the fall-rescue both land here." % worst)
	elif not hits.is_empty():
		print("T5> VERDICT: the respawn point is INSIDE %d collider(s); the player came to rest "
			% hits.size() + "%.1fm away. Not a launch, but they respawn inside a building." % distance)
	else:
		print("T5> VERDICT: PASS — the respawn point is clear and the player stays put.")
	quit(0)

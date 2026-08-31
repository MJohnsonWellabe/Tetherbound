extends SceneTree

## AUDIT-H probe: why does `tools/_play_t5_deaths.gd`'s 120m drop "land" on
## frame 11 at ~0 m/s instead of producing a real lethal fall?
##
##   godot --headless --path . --script tools/_probe_t5_falldrop.gd
##
## Traces position/velocity/on_floor for every frame of the drop so the
## question "did the fall happen at all" gets a frame-by-frame answer instead
## of the single post-hoc summary `_play_t5_deaths.gd` prints.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const PATCH := Vector2(30.0, -40.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	game.get("progression").call("set_flag", "opening:beat:free_play")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("no player")
		quit(1)
		return

	var ground := float(world.call("ground_height_at", PATCH.x, PATCH.y))
	print("T5FALL> ground_height_at(30,-40) = %.2f" % ground)
	player.global_position = Vector3(PATCH.x, ground + 1.0, PATCH.y)
	player.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame
	print("T5FALL> pre-drop pos %s on_floor=%s" % [str(player.global_position), str(player.is_on_floor())])

	var from := player.global_position
	player.global_position = from + Vector3.UP * 120.0
	player.velocity = Vector3.ZERO
	print("T5FALL> teleported to %s" % str(player.global_position))

	for f in 30:
		await physics_frame
		print("T5FALL> frame %2d pos (%.2f, %.2f, %.2f) vel %s on_floor=%s" % [
			f, player.global_position.x, player.global_position.y, player.global_position.z,
			str(player.velocity), str(player.is_on_floor())])
	quit(0)

extends SceneTree

## Headless: hold sprint across the meadow and write down every time the trainer
## changes clip, plus every frame the ground goes out from under him.
##
##   /opt/godot/godot --headless --path . --script tools/preview_locomotion_probe.gd
##
## The rendered strip answers "did the pose change". This answers the other
## half — whether the state machine is picking one clip and staying on it, or
## flickering between two on the crest of every hill. A clip change is a 0.18s
## cross-fade, so a state that flickers looks like a character who never quite
## commits to a stride, which is a different complaint with the same words.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const HOLD_FRAMES := 900


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var model: Node3D = player.get_node_or_null(^"Model") as Node3D
	var anim := _anim(model)

	Input.action_press("move_forward")
	Input.action_press("sprint")

	var changes := 0
	var airborne := 0
	var stopped := 0
	var last := ""
	for i in HOLD_FRAMES:
		await physics_frame
		var current := str(model.get("_current"))
		if current != last:
			changes += 1
			print("frame %4d  %6.2f m/s  on_floor %s  -> %s" % [
				i, player.call("ground_speed"), str(player.is_on_floor()), current
			])
			last = current
		if not player.is_on_floor():
			airborne += 1
		if not anim.is_playing():
			stopped += 1

	Input.action_release("move_forward")
	Input.action_release("sprint")
	print("")
	print("%d frames holding sprint: %d clip changes, %d frames airborne, %d frames with nothing playing"
		% [HOLD_FRAMES, changes, airborne, stopped])
	quit(0)


func _anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _anim(child)
		if found != null:
			return found
	return null

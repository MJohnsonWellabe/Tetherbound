extends SceneTree

## Through a walk cycle, where does each rig's arm actually POINT?
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --script tools/preview_swing_probe.gd
##
## The numeric half of `preview_arms.gd`, and the half that diagnoses rather
## than merely condemns. A bone's direction is its global pose Y axis in its own
## skeleton's space; both skeletons stand upright facing +Z, so the two are
## directly comparable and the angle between them is the error in degrees. That
## is the number the eye is reading when it says "his arms are wrong", and
## unlike the eye it says WHICH WAY and BY HOW MUCH.
##
## The shape of the output is as diagnostic as the size. A constant error across
## every phase is a REST POSE difference — the two rigs disagree about where the
## bone starts. An error that varies with phase is the MOTION going astray, and
## that one is the retarget's fault. The arms read 52° flat before the rest
## alignment went in and 95°-varying before the frame conjugation did.
##
## Expect: upper arm and forearm at 0.0°, hand within ~3°, thighs 5.1° and the
## pelvis 14.5° — the last two being rest differences that are deliberately kept
## rather than corrected, because they are the knight's build.

const TRAINER := preload("res://scripts/player/trainer_model.gd")
const RANGER := "res://assets/characters/Ranger.glb"
const LIBRARIES := [
	"res://assets/characters/Rig_Medium_General.glb",
	"res://assets/characters/Rig_Medium_MovementBasic.glb",
]
const PAIRS := [
	["upperarm.l", "DEF-upper_arm.L"],
	["lowerarm.l", "DEF-forearm.L"],
	["hand.l", "DEF-hand.L"],
	["upperleg.l", "DEF-thigh.L"],
	["hips", "DEF-spine"],
	["chest", "DEF-spine.003"],
]
const CLIP := "Walking_A"
const PHASES := [0.0, 0.25, 0.5, 0.75]


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var trainer := Node3D.new()
	trainer.set_script(TRAINER)
	world.add_child(trainer)

	var ranger := _ranger()
	world.add_child(ranger)

	for i in 60:
		await physics_frame

	var src_player := _player(ranger)
	var dst_player := _player(trainer)
	var src := _skeleton(ranger)
	var dst := _skeleton(trainer)

	print("--- REST directions (bone global rest Y, skeleton space) ---")
	for pair: Array in PAIRS:
		var si := src.find_bone(str(pair[0]))
		var ti := dst.find_bone(str(pair[1]))
		var a := src.get_bone_global_rest(si).basis.orthonormalized().y
		var b := dst.get_bone_global_rest(ti).basis.orthonormalized().y
		print("%-12s %s   %-22s %s   apart %5.1f deg" % [
			pair[0], _v(a), pair[1], _v(b), rad_to_deg(a.angle_to(b))
		])

	for phase: float in PHASES:
		print("--- %s phase %.2f (animated) ---" % [CLIP, phase])
		_seek(src_player, phase)
		_seek(dst_player, phase)
		await process_frame
		await process_frame
		for pair: Array in PAIRS:
			var si := src.find_bone(str(pair[0]))
			var ti := dst.find_bone(str(pair[1]))
			var a := src.get_bone_global_pose(si).basis.orthonormalized().y
			var b := dst.get_bone_global_pose(ti).basis.orthonormalized().y
			print("  %-12s src %s  tgt %s  apart %5.1f deg" % [
				pair[0], _v(a), _v(b), rad_to_deg(a.angle_to(b))
			])
	quit(0)


func _seek(player: AnimationPlayer, phase: float) -> void:
	player.play(CLIP)
	player.seek(player.get_animation(CLIP).length * phase, true)
	player.advance(0.0)


func _v(v: Vector3) -> String:
	return "(%+.2f,%+.2f,%+.2f)" % [v.x, v.y, v.z]


func _ranger() -> Node3D:
	var node: Node3D = (load(RANGER) as PackedScene).instantiate() as Node3D
	var player := AnimationPlayer.new()
	node.add_child(player)
	player.root_node = player.get_path_to(node)
	var library := AnimationLibrary.new()
	player.add_animation_library("", library)
	for path: String in LIBRARIES:
		var source: Node = (load(path) as PackedScene).instantiate()
		var from := _player(source)
		if from != null:
			for clip in from.get_animation_list():
				if not library.has_animation(clip):
					library.add_animation(clip, from.get_animation(clip).duplicate())
		source.queue_free()
	return node


func _skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _skeleton(child)
		if found != null:
			return found
	return null


func _player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _player(child)
		if found != null:
			return found
	return null

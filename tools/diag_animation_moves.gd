extends SceneTree

## When a clip plays, does anything actually move?
##
##   godot --headless --path . --script tools/diag_animation_moves.gd
##
## "Static posed and sliding around" has two very different causes and they
## look identical in game:
##
##   1. the clip never plays (or plays once and stops), or
##   2. the clip plays and drives nothing, because its track paths do not
##      resolve to this scene's skeleton.
##
## Cause 2 is silent — Godot does not error on an animation track that points
## at a node it cannot find. This samples the skeleton's actual bone poses at
## several times through each clip and reports how much they moved, which
## separates the two without guessing.

const MODELS := {
	"terrapup": "res://assets/pals/tetherbound/terrapup/models/pal_terrapup_lod0.glb",
	"trainer": "res://assets/characters/trainer/trainer_lod0.glb",
}
const SAMPLES := 8


func _find(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found := _find(child, type_name)
		if found != null:
			return found
	return null


func _pose_signature(skeleton: Skeleton3D) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in skeleton.get_bone_count():
		var t := skeleton.get_bone_pose(i)
		out.append(t.origin.x); out.append(t.origin.y); out.append(t.origin.z)
		var q := t.basis.get_rotation_quaternion()
		out.append(q.x); out.append(q.y); out.append(q.z); out.append(q.w)
	return out


func _init() -> void:
	_run()


func _run() -> void:
	for label: String in MODELS:
		var path: String = MODELS[label]
		print("\n=== %s" % label)
		var instance: Node = (load(path) as PackedScene).instantiate()
		root.add_child(instance)
		await process_frame

		var player := _find(instance, "AnimationPlayer") as AnimationPlayer
		var skeleton := _find(instance, "Skeleton3D") as Skeleton3D
		if player == null or skeleton == null:
			print("  missing AnimationPlayer or Skeleton3D")
			instance.queue_free()
			continue
		print("  %d bones, %d clips" % [skeleton.get_bone_count(), player.get_animation_list().size()])
		print("  animation root: %s -> %s" % [
			str(player.root_node), str(player.get_node_or_null(player.root_node))])

		for clip: String in player.get_animation_list():
			var animation := player.get_animation(clip)
			var length: float = maxf(animation.length, 0.001)
			var biggest := 0.0
			var first := PackedFloat32Array()
			for s in SAMPLES:
				player.play(clip)
				player.seek(length * float(s) / float(SAMPLES - 1), true)
				await process_frame
				var signature := _pose_signature(skeleton)
				if s == 0:
					first = signature
					continue
				var delta := 0.0
				for i in signature.size():
					delta = maxf(delta, absf(signature[i] - first[i]))
				biggest = maxf(biggest, delta)
			var verdict := "MOVES" if biggest > 0.001 else "*** DRIVES NOTHING ***"
			print("    %-10s length %.2fs  max bone delta %.5f  %s" % [
				clip, animation.length, biggest, verdict])
		instance.queue_free()
		await process_frame
	quit()

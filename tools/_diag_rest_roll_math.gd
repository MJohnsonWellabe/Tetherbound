extends SceneTree

## OWNER-0901-CREATURE-BED-POSE diagnostic. Prints the actual AABB of a
## creature's model before and after play_rest()'s roll, in `_model`'s own
## local space, to settle by measurement (not by hand-derived trig) what the
## rotate_z() call is actually doing to each axis. Headless-safe: no GPU
## render needed, only geometry queries.
##
##   godot --headless --path . --script tools/_diag_rest_roll_math.gd -- terrapup

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var species_id := args[0] if args.size() > 0 else "terrapup"

	var body := CREATURE_SCENE.instantiate() as Node3D
	body.set_script(CREATURE_BODY)
	root.add_child(body)
	body.call("setup", species_id, false)
	await process_frame

	var model: Node3D = body.call("model_pivot")
	print("species: %s" % species_id)
	print("model local transform BEFORE roll: origin=%s basis_euler_deg=%s"
		% [str(model.position), str(model.rotation_degrees)])
	var box_before: AABB = RENDER_BOUNDS.measure(model)
	print("model-space AABB BEFORE roll: position=%s size=%s" % [str(box_before.position), str(box_before.size)])

	body.call_deferred("play_rest")
	for i in 5:
		await process_frame

	print("model local transform AFTER roll: origin=%s basis_euler_deg=%s"
		% [str(model.position), str(model.rotation_degrees)])
	var box_after: AABB = RENDER_BOUNDS.measure(model)
	print("model-space AABB AFTER roll: position=%s size=%s" % [str(box_after.position), str(box_after.size)])

	# Where the AABB corners land in the BODY's own local space (model's
	# position/rotation applied), which is what actually gets placed at
	# REST_ANCHOR in the world.
	var xform: Transform3D = model.transform
	for corner_i in 8:
		var local_corner := box_after.position + Vector3(
			box_after.size.x * float(corner_i & 1),
			box_after.size.y * float((corner_i >> 1) & 1),
			box_after.size.z * float((corner_i >> 2) & 1)
		)
		var body_space := xform * local_corner
		print("  corner %d: model-local=%s -> body-local=%s" % [corner_i, str(local_corner), str(body_space)])

	quit(0)

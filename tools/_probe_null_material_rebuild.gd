extends SceneTree

## CL-G7 (N03-CREATURE-BODY-0905). Reproduces, in isolation, the engine error
## every headless world boot used to open with:
##
##   ERROR: Parameter "material" is null.
##      at: material_get_instance_shader_parameters (.../material_storage.cpp)
##      GDScript backtrace: _build_model (creature_body.gd) <- apply_size_multiplier
##
## It is the exact call order `burrow_warrens.gd::_dress_the_guardian()` uses on
## the Warren Guardian -- a body built and dressed, then re-sized in the SAME
## frame -- with nothing else in the scene, so the error (or its absence) is
## attributable to creature_body.gd alone.
##
##   godot --headless --path . --script tools/_probe_null_material_rebuild.gd
##   godot --headless --path . --script tools/_probe_null_material_rebuild.gd -- burrowback 1.35 same-frame
##   godot --headless --path . --script tools/_probe_null_material_rebuild.gd -- burrowback 1.35 next-frame
##   godot --headless --path . --script tools/_probe_null_material_rebuild.gd -- burrowback 1.35 hold-materials
##
## `hold-materials` is the diagnostic that pins the mechanism: it keeps a
## reference to every material the dressed art is wearing across the rebuild
## and nothing else. If the error is gone in that mode, the null material is
## an override the freed MeshInstance3D was the last holder of.
##
## Prints nothing useful itself beyond a marker line; the evidence is whether
## the engine prints `Parameter "material" is null.` between START and END.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var species_id := args[0] if args.size() > 0 else "burrowback"
	var multiplier := float(args[1]) if args.size() > 1 else 1.35
	var timing := args[2] if args.size() > 2 else "same-frame"

	var body := CREATURE_SCENE.instantiate() as Node3D
	body.set_script(CREATURE_BODY)
	root.add_child(body)
	body.call("setup", species_id, false)
	# Let `_ready()` build the body -- `@onready` fields are not set until the
	# tree has run its first frame, and a body in the real game is always
	# dressed AFTER it has been built.
	await process_frame
	print("PROBE START: %s x%.2f (%s): set_alpha then apply_size_multiplier" % [species_id, multiplier, timing])
	body.call("set_alpha", true)
	var held: Array[Material] = []
	if timing == "hold-materials":
		_hold(body.call("model_pivot") as Node, held)
		print("holding %d materials across the rebuild" % held.size())
	if timing == "next-frame":
		# A frame between dressing and resizing lets the rendering server
		# process the dressed instances before their art is freed.
		await process_frame
	body.call("apply_size_multiplier", multiplier)
	# A second rebuild through the same path, now from a body that has already
	# been dressed as an alpha (rim duplicates, aura) -- the state the guardian
	# is in when `_dress_the_guardian()` reaches it.
	body.call("apply_size_multiplier", 1.1)
	print("PROBE END: has_model=%s radius=%.3f" % [str(body.call("has_model")), float(body.call("body_radius"))])
	await process_frame
	body.free()
	await process_frame
	held.clear()
	quit(0)


func _hold(node: Node, into: Array[Material]) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var active: Material = instance.get_active_material(surface)
			if active != null:
				into.append(active)
	for child in node.get_children():
		_hold(child, into)

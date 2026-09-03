extends SceneTree

## CREATURE-LEGIBILITY-0903. Headless sanity check that
## creature_body.gd::_apply_ground_contact_shadow() actually builds a
## ContactShadow child with a sane size, without needing a real renderer.
##
##   godot --headless --path . --script tools/_probe_contact_shadow_check.gd

const CREATURE_SCENE := "res://scenes/creatures/creature.tscn"
const WILD_SCRIPT := "res://scripts/creatures/wild_creature.gd"


func _init() -> void:
	_run()


func _run() -> void:
	# `_init()` runs before the engine sets `main_loop`, so `is_inside_tree()`
	# reads false on a node added here until at least one frame has passed --
	# same trap `tests/smoke_wild_streaming.gd` documents on its own `_run()`.
	await process_frame
	var body: Node3D = (load(CREATURE_SCENE) as PackedScene).instantiate()
	body.set_script(load(WILD_SCRIPT))
	root.add_child(body)
	body.call("populate", "bramblebun", null)
	var shadow: Node = body.find_child("ContactShadow", false, false)
	if shadow == null:
		print("FAIL: no ContactShadow child built")
		quit(1)
		return
	if not (shadow is MeshInstance3D):
		print("FAIL: ContactShadow is not a MeshInstance3D")
		quit(1)
		return
	var mesh: QuadMesh = (shadow as MeshInstance3D).mesh as QuadMesh
	if mesh == null:
		print("FAIL: ContactShadow has no QuadMesh")
		quit(1)
		return
	print("OK: ContactShadow present, size=%s, visible=%s, material=%s" % [
		mesh.size, shadow.visible, (shadow as MeshInstance3D).material_override])
	quit(0)

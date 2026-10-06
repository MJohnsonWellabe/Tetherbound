extends "res://tests/test_case.gd"

## PERF (F26#5): scripts/world/static_mesh_batch.gd folds a settlement's plain
## kit modules into one mesh per material and hides the originals. Anything a
## merge would change, and anything a hidden original would take down with it,
## must keep drawing itself.

const BATCH := preload("res://scripts/world/static_mesh_batch.gd")


func _module(parent: Node3D, material: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = at
	parent.add_child(mi)
	return mi


func test_plain_modules_with_one_material_merge_into_one_batch() -> void:
	var building := Node3D.new()
	var plaster := StandardMaterial3D.new()
	var a := _module(building, plaster, Vector3.ZERO)
	var b := _module(building, plaster, Vector3(2.0, 0.0, 0.0))
	var stats := BATCH.merge(building)
	assert_eq(int(stats.meshes), 2)
	assert_eq(int(stats.batches), 1)
	assert_false(a.visible or b.visible, "the originals stop drawing")
	building.free()


func test_a_vertex_shader_module_keeps_drawing_itself() -> void:
	# Banner cloth reads VERTEX in the mesh's own space; merged, it would
	# ripple along the building's axes instead.
	var building := Node3D.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nvoid vertex() { VERTEX.z += sin(VERTEX.x); }\n"
	var cloth := ShaderMaterial.new()
	cloth.shader = shader
	var banner := _module(building, cloth, Vector3.ZERO)
	var stats := BATCH.merge(building)
	assert_eq(int(stats.meshes), 0)
	assert_true(banner.visible)
	building.free()


func test_alpha_blended_and_billboard_modules_keep_drawing_themselves() -> void:
	var building := Node3D.new()
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var sign_card := StandardMaterial3D.new()
	sign_card.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var pane := _module(building, glass, Vector3.ZERO)
	var card := _module(building, sign_card, Vector3(2.0, 0.0, 0.0))
	BATCH.merge(building)
	assert_true(pane.visible and card.visible)
	building.free()


func test_a_module_with_something_drawn_beneath_it_is_not_hidden() -> void:
	# Hiding a merged module hides its subtree: a lamp parented under a wall
	# module would go dark with it.
	var building := Node3D.new()
	var plaster := StandardMaterial3D.new()
	var wall := _module(building, plaster, Vector3.ZERO)
	var lamp := OmniLight3D.new()
	wall.add_child(lamp)
	var plain := _module(building, plaster, Vector3(2.0, 0.0, 0.0))
	BATCH.merge(building)
	assert_true(wall.visible, "the wall keeps drawing, so its lamp stays lit")
	assert_true(lamp.is_visible_in_tree())
	assert_false(plain.visible, "a plain sibling still merges")
	building.free()

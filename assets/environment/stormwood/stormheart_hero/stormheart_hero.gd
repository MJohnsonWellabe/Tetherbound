@tool
extends Node3D
## Asset-local appearance only. The cleared source mesh and all gameplay stay fixed.
const FAMILY := "res://assets/environment/stylized_nature/"
const LEAVES := preload("res://assets/environment/stormwood/stormheart_hero/stormheart_leaves.gdshader")
const BARK := preload("res://assets/environment/stormwood/stormheart_hero/stormheart_bark.gdshader")
# Centres/sizes follow the existing broad bough tiers. Every low cluster remains
# outside radius44; the inner upper split stays open rather than one round cap.
const CROWNS := [
    [Vector3(-129,176,-22), Vector3(65,31,57), 0.2],
    [Vector3(-93,190,-100), Vector3(67,36,62), 1.5],
    [Vector3(-127,225,-55), Vector3(62,31,55), 2.5],
    [Vector3(-88,242,-40), Vector3(61,34,60), 0.8],
    [Vector3(-55,282,-25), Vector3(61,34,59), 2.1],
    [Vector3(-77,266,-40), Vector3(50,30,51), 3.0],
    [Vector3(137,165,-40), Vector3(57,29,56), 1.2],
    [Vector3(105,183,-90), Vector3(67,35,61), 2.9],
    [Vector3(93,215,-18), Vector3(68,36,63), 0.5],
    [Vector3(112,238,-25), Vector3(65,32,57), 1.8],
    [Vector3(69,268,-20), Vector3(58,35,59), 2.7],
    [Vector3(43,284,-24), Vector3(52,31,53), 0.6],
    [Vector3(-60,222,65), Vector3(53,32,53), 1.3],
    [Vector3(60,237,59), Vector3(53,33,54), 2.3],
]
func _ready() -> void:
    if has_node("LivingCanopy"):
        return
    _finish_bark($LivingStormSplitTree)
    var crowns := Node3D.new()
    crowns.name = "LivingCanopy"
    add_child(crowns)
    for i in CROWNS.size():
        _add_crown(crowns, i)

func _finish_bark(node: Node) -> void:
    if node is MeshInstance3D:
        var visual := node as MeshInstance3D
        for i in visual.mesh.get_surface_count():
            var source := visual.mesh.surface_get_material(i) as StandardMaterial3D
            if source != null:
                var finish := ShaderMaterial.new()
                finish.shader = BARK
                finish.set_shader_parameter("source_atlas", source.albedo_texture)
                finish.set_shader_parameter("bark_detail", load(FAMILY + "Bark_TwistedTree.png"))
                visual.set_surface_override_material(i, finish)
    for child in node.get_children():
        _finish_bark(child)

func _add_crown(parent: Node3D, index: int) -> void:
    var path := FAMILY + ("TwistedTree_2.gltf" if index % 2 else "TwistedTree_4.gltf")
    var source := (load(path) as PackedScene).instantiate()
    var leaves := ArrayMesh.new()
    _collect_leaves(source, Transform3D.IDENTITY, leaves)
    source.free()
    var visual := MeshInstance3D.new()
    visual.name = "BoughLeafMass%02d" % index
    visual.mesh = leaves
    var row: Array = CROWNS[index]
    var rotation_basis := Basis(Vector3.UP, float(row[2]))
    var rotated_bounds := Transform3D(rotation_basis, Vector3.ZERO) * leaves.get_aabb()
    var size: Vector3 = row[1]
    var fit := size / rotated_bounds.size
    visual.basis = Basis.from_scale(fit) * rotation_basis
    visual.position = (row[0] as Vector3) - visual.basis * leaves.get_aabb().get_center()
    parent.add_child(visual)

func _collect_leaves(node: Node, pose: Transform3D, result: ArrayMesh) -> void:
    if node is Node3D:
        pose *= (node as Node3D).transform
    if node is MeshInstance3D:
        var mesh := (node as MeshInstance3D).mesh
        for surface in mesh.get_surface_count():
            var material := mesh.surface_get_material(surface) as StandardMaterial3D
            if material == null or not material.resource_name.begins_with("Leaves_"):
                continue
            var arrays := mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            for i in vertices.size():
                vertices[i] = pose * vertices[i]
                normals[i] = (pose.basis.inverse().transposed() * normals[i]).normalized()
            arrays[Mesh.ARRAY_VERTEX] = vertices
            arrays[Mesh.ARRAY_NORMAL] = normals
            var green := ShaderMaterial.new()
            green.shader = LEAVES
            # Preserve the TwistedTree UV/alpha pairing. A different species'
            # alpha atlas produces holes that destroy the broad crown masses.
            green.set_shader_parameter("leaf_atlas", load(FAMILY + "Leaves_TwistedTree_C.png"))
            green.set_shader_parameter("leaf_colour", Color("75924d"))
            result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
            result.surface_set_material(result.get_surface_count() - 1, green)
    for child in node.get_children():
        _collect_leaves(child, pose, result)


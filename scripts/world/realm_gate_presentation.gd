extends RefCounted

## The generated frame and a separate animated surface shaped to its measured
## aperture. This class has no collision, prompt, progression or travel logic.
const ENERGY := preload("res://shaders/realm_gate_energy.gdshader")
static var _frame: PackedScene
static var _aperture: ArrayMesh

static func frame(parent: Node3D, config: Dictionary) -> void:
	var path := str(config.frame_model)
	if _frame == null or _frame.resource_path != path:
		_frame = load(path) as PackedScene
	var model := _frame.instantiate() as Node3D
	model.name = "RealmGateFrame"
	parent.add_child(model)

static func veil(parent: Node3D, label: String, config: Dictionary) -> ShaderMaterial:
	if _aperture == null:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(config.aperture_profile)))
		var rows: Array = data.profile_y_left_right
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(1, rows.size()):
			var a: Array = rows[index - 1]
			var b: Array = rows[index]
			for corner: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2),
					Vector2i(0, 1), Vector2i(1, 2), Vector2i(1, 1)]:
				var row: Array = a if corner.x == 0 else b
				surface.set_normal(Vector3.FORWARD)
				surface.set_uv(Vector2(float(corner.y - 1), float(row[0]) / 4.2))
				surface.add_vertex(Vector3(float(row[corner.y]), float(row[0]), 0.0))
		_aperture = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = ENERGY
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = _aperture
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return material

static func style(material: ShaderMaterial, colour: Color, state: Dictionary) -> void:
	material.set_shader_parameter("energy_colour", colour)
	for key: String in ["intensity", "centre_opacity", "edge_opacity", "seal_presence", "seal_ready"]:
		material.set_shader_parameter(key, float(state[key]))

extends RefCounted

## P2-115 Water-only decoration. The shared bed's outer frame and full centre
## remain in place. No BuildPiece is created: it would also create a collider.
## Provenance: same generated_camp canvas maps and CapsuleMesh construction as
## creature_bed.gd, with a thicker open-front cushion composition.
const CONFIG := "res://data/config/water_camp_bed_presentation.json"
const BED := preload("res://scripts/build/creature_bed.gd")
const NODE_NAME := "WaterPaddedBolster"


static func settings() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return raw if raw is Dictionary else {}


static func attach(bed: Node3D, supplied: Dictionary = {}) -> Node3D:
	var config := supplied if not supplied.is_empty() else settings()
	if not bool(config.get("enabled", false)) or not is_instance_valid(bed):
		return null
	# Shared/player-built beds cannot acquire the candidate accidentally.
	if not str(bed.name).begins_with("water_camp_") or not str(bed.name).ends_with("_creature_bed"):
		return null
	if bed.has_node(NodePath(NODE_NAME)):
		return bed.get_node(NodePath(NODE_NAME)) as Node3D
	var radius := clampf(float(config.get("padding_radius_m", 0.22)), 0.16, 0.24)
	var length := clampf(float(config.get("segment_length_m", 1.0)), 0.8, 1.05)
	var inset := clampf(float(config.get("rim_inset_m", 0.18)), 0.0, 0.18)
	var side_height := clampf(float(config.get("side_center_height_m", 0.29)), 0.25, 0.32)
	var back_height := clampf(float(config.get("back_center_height_m", 0.44)), 0.38, 0.48)
	var radius_x := BED.RIM_RADIUS_X - inset
	var radius_z := BED.RIM_RADIUS_Z - inset
	var decoration := Node3D.new()
	decoration.name = NODE_NAME
	bed.add_child(decoration)
	var material := _canvas(config)
	# Negative Z is the back. The positive-Z half (including the existing rim
	# entry gap and Interactable) stays open. Ends taper down into the sides.
	for index in 9:
		var angle := PI + float(index) * PI / 8.0
		var backness := maxf(0.0, -sin(angle))
		var centre := Vector3(radius_x * cos(angle),
			lerpf(side_height, back_height, backness), radius_z * sin(angle))
		var tangent := Vector3(-radius_x * sin(angle), 0.0, radius_z * cos(angle)).normalized()
		var capsule := CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = length
		capsule.radial_segments = 16
		capsule.rings = 6
		var pad := MeshInstance3D.new()
		pad.name = "CanvasPad%02d" % index
		pad.mesh = capsule
		pad.material_override = material
		pad.transform = Transform3D(Basis(Quaternion(Vector3.UP, tangent)), centre)
		decoration.add_child(pad)
	return decoration


static func _canvas(config: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var tint: Array = config.get("canvas_tint", [1.65, 1.42, 1.08])
	material.albedo_color = Color(float(tint[0]), float(tint[1]), float(tint[2])) if tint.size() == 3 else BED.PAD_TINT
	material.albedo_texture = load(BED.PAD_CANVAS_ALBEDO) as Texture2D
	material.normal_enabled = true
	material.normal_texture = load(BED.PAD_CANVAS_NORMAL) as Texture2D
	material.normal_scale = 0.55
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * clampf(float(config.get("canvas_tile_scale", 3.0)), 2.0, 5.0)
	material.metallic = 0.0
	material.roughness = 0.95
	return material

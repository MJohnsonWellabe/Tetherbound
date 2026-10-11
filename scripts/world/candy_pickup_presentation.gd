extends RefCounted

## Regional adapters share the existing Meadows tier treatment. The cache
## itself keeps ownership of interaction and claims; only its visual is dressed.
const CONFIG := "res://data/config/candy_pickup_presentation.json"
const TIERS := preload("res://scripts/world/band_pickups.gd")
const SKILL_CONFIG := "res://data/config/water_crafting.json"


static func apply(pickup: Node3D, item_id: String, definition: Dictionary, placement_id: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary or not bool(parsed.get("enabled", false)):
		return
	if str(definition.get("kind", "")) == "skill_candy":
		_skill_tier(pickup, item_id, parsed.get("skill_tiers", {}))
		return
	if not TIERS.CANDY_LOOK.has(item_id):
		return
	var badge := Color(str(definition.get("colour", "#ffffff")))
	TIERS.dress(pickup, item_id, badge, TIERS.spin_phase_for(placement_id))
	_regional_tier(pickup, item_id, badge, parsed.get("regional_tiers", {}))


## P2-045 judge round 1: at regional camera distance Good and Great read as
## bloom-dominated see-through puffs that differ mainly by glow colour, and
## Great vanished on pale sand. Per tier, from config: an opaque body with its
## own albedo and a low emission, a smaller shared glow, and a lift for the
## body (its ground ring is lowered by the same amount so it stays down).
## Installed candy mesh only; the Meadows look is untouched.
static func _regional_tier(pickup: Node3D, item_id: String, badge: Color, tiers: Variant) -> void:
	if not tiers is Dictionary or not (tiers as Dictionary).get(item_id) is Dictionary:
		return
	var tier: Dictionary = (tiers as Dictionary)[item_id]
	var mesh: MeshInstance3D = TIERS._first_mesh(pickup)
	if mesh == null:
		return
	var body := mesh.material_override as StandardMaterial3D
	if body != null:
		body = body.duplicate() as StandardMaterial3D
		body.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		if tier.has("albedo"):
			# The installed wrapper texture is green. Multiplying it by blue
			# hides Great's body rather than giving it its own tier colour.
			body.albedo_texture = null
			body.albedo_color = Color(str(tier.albedo))
		if tier.has("emission"):
			body.emission_energy_multiplier = float(tier.emission)
		mesh.material_override = body
	if tier.has("glow_scale"):
		TIERS.PICKUP_GLOW.attach(pickup, badge, -1.0, float(tier.glow_scale))
	var lift := float(tier.get("lift_m", 0.0))
	if lift != 0.0:
		var parent_scale := 1.0
		var parent := mesh.get_parent()
		while parent is Node3D and parent != pickup:
			parent_scale *= absf((parent as Node3D).scale.y)
			parent = parent.get_parent()
		var local_lift := lift / maxf(parent_scale, 0.001)
		mesh.position.y += local_lift
		var ring := mesh.get_node_or_null(^"TierRing") as Node3D
		if ring != null:
			# The ring is a child of the scaled candy mesh; lift is in its
			# parent's metres, so convert it before restoring the ground plane.
			ring.position.y -= local_lift / maxf(absf(mesh.scale.y), 0.001)


## Skill sweets are the same installed wrapper family, with a black foil
## body and physical I/II/III marks. Shape and size carry the tier even when
## its label or hue cannot be read. These children never own pickup claims.
static func _skill_tier(pickup: Node3D, item_id: String, tuning: Variant) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SKILL_CONFIG))
	if not parsed is Dictionary:
		return
	var presentation: Dictionary = parsed.get("skill_candy_presentation", {})
	var tier: Dictionary = presentation.get("tiers", {}).get(item_id, {})
	if tier.is_empty():
		return
	var mesh := TIERS._first_mesh(pickup)
	if mesh == null or mesh.mesh == null or mesh.get_node_or_null(^"SkillTierMark") != null:
		return
	var cfg: Dictionary = tuning if tuning is Dictionary else {}
	var body := StandardMaterial3D.new()
	body.albedo_color = Color(str(presentation.get("all_tiers_body_colour", "#17161b")))
	body.roughness = float(cfg.get("roughness", 0.58))
	mesh.material_override = body
	var mark := StandardMaterial3D.new()
	mark.albedo_color = Color(str(presentation.get("marking_colour", "#ddd8e5")))
	mark.roughness = 0.7
	var bounds := mesh.get_aabb()
	var core := minf(bounds.size.x, bounds.size.z)
	var centre := bounds.get_center()
	var strokes := str(tier.get("marking", "I")).length()
	var width := core * float(cfg.get("mark_width_fraction", 0.10))
	var spacing := core * float(cfg.get("mark_spacing_fraction", 0.18))
	var length := core * float(cfg.get("mark_length_fraction", 0.52))
	var thickness := core * float(cfg.get("mark_depth_fraction", 0.02))
	var marking := Node3D.new()
	marking.name = "SkillTierMark"
	mesh.add_child(marking)
	for i in strokes:
		var bar := MeshInstance3D.new()
		bar.name = "RomanStroke%d" % (i + 1)
		var shape := BoxMesh.new()
		shape.size = Vector3(width, thickness, length)
		bar.mesh = shape
		bar.material_override = mark
		bar.position = Vector3(centre.x + (float(i) - float(strokes - 1) * 0.5) * spacing,
			bounds.end.y + thickness * 0.25, centre.z)
		marking.add_child(bar)
	# Extra foil folds are rooted inside each installed wrapper end. A
	# single, double or triple fan gives each grade a different silhouette.
	var fold_width := core * float(cfg.get("fold_width_fraction", 0.30))
	for side: float in [-1.0, 1.0]:
		for i in strokes - 1:
			var fold := MeshInstance3D.new()
			fold.name = "WrapperFold%s%d" % ["Left" if side < 0.0 else "Right", i + 1]
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			var reach := bounds.size.x * float(cfg.get("fold_reach_fraction", 0.18))
			var points := PackedVector3Array([Vector3(-side * reach * 0.3, 0.0, -fold_width * 0.5),
				Vector3(-side * reach * 0.3, 0.0, fold_width * 0.5),
				Vector3(side * reach, fold_width * 0.22, 0.0),
				Vector3(0.0, -fold_width * 0.18, 0.0)])
			for face: Vector3i in [Vector3i(0, 1, 2), Vector3i(0, 3, 1), Vector3i(0, 2, 3), Vector3i(1, 3, 2)]:
				var indices := [face.x, face.y, face.z] if side > 0.0 else [face.x, face.z, face.y]
				for index: int in indices:
					tool.add_vertex(points[index])
			tool.generate_normals()
			fold.mesh = tool.commit()
			fold.material_override = body
			fold.position = centre + Vector3(side * bounds.size.x * 0.38, 0.0, 0.0)
			fold.rotation.x = (-1.0 if i == 0 else 1.0) * 0.65
			mesh.add_child(fold)
	TIERS.PICKUP_GLOW.attach(pickup,
		Color(str(presentation.get("all_tiers_aura_colour", "#302d36"))), -1.0,
		float(cfg.get("glow_scale", 0.45)))

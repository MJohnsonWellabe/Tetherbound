extends RefCounted

## F41#14 (LANE-SW, 7 Nov 2026, OFF until judged): each Stormwood candy tier
## gets its own Blender body (stormwood_candy_tiers_1107.json). The installed
## candy body's mesh is swapped in place, so its spin, ring, crest, sparkles
## and wings stay attached; the new body is fitted to the old body's footprint
## and height times the tier's height_mult, so rarer reads bigger. Visual only.

const CONFIG := "res://data/config/stormwood_candy_tiers_1107.json"
const TIERS := preload("res://scripts/world/band_pickups.gd")
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")


static func config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) \
		if FileAccess.file_exists(CONFIG) else {}
	return parsed if parsed is Dictionary else {}


static func apply(pickup: Node3D, item_id: String, badge: Color, cfg: Dictionary = {}) -> bool:
	if cfg.is_empty():
		cfg = config()
	if not bool(cfg.get("enabled", false)):
		return false
	var tier: Variant = (cfg.get("items", {}) as Dictionary).get(item_id, null)
	if not tier is Dictionary:
		return false
	var body := TIERS._first_mesh(pickup)
	if body == null or body.mesh == null:
		return false
	var built := tier_mesh(str((tier as Dictionary).get("model", "")), body.mesh.get_aabb(),
		float((tier as Dictionary).get("height_mult", 1.0)))
	if built == null:
		return false
	body.mesh = built
	body.material_override = null
	if (tier as Dictionary).has("glow_scale"):
		TIERS.PICKUP_GLOW.attach(pickup, badge, -1.0, float((tier as Dictionary).glow_scale))
	return true


## The tier model merged into one mesh (its own surface materials kept), fitted
## to `fit`: same centre in x/z, same base, height fit.size.y * height_mult.
static func tier_mesh(path: String, fit: AABB, height_mult: float) -> ArrayMesh:
	var model := HERO_PROP.load_model(path)
	if model == null:
		return null
	var parts: Array = []
	var bounds := AABB()
	var first := true
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var pose := Transform3D.IDENTITY
		var at: Node = visual
		while at != null and at != model:
			if at is Node3D:
				pose = (at as Node3D).transform * pose
			at = at.get_parent()
		parts.append([visual.mesh, pose])
		var box := pose * visual.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if parts.is_empty() or bounds.size.y <= 0.0001:
		model.free()
		return null
	var k := fit.size.y * height_mult / bounds.size.y
	var centre := bounds.get_center()
	var place := Transform3D(Basis.from_scale(Vector3.ONE * k),
		Vector3(fit.get_center().x, fit.position.y, fit.get_center().z)) \
		* Transform3D(Basis.IDENTITY, Vector3(-centre.x, -bounds.position.y, -centre.z))
	var out := ArrayMesh.new()
	for part: Array in parts:
		var source := part[0] as Mesh
		for surface in source.get_surface_count():
			var tool := SurfaceTool.new()
			tool.append_from(source, surface, place * (part[1] as Transform3D))
			tool.commit(out)
			out.surface_set_material(out.get_surface_count() - 1, source.surface_get_material(surface))
	model.free()
	return out

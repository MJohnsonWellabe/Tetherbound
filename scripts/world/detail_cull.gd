extends RefCounted

## PERF (F26#5, 2026-10-05). Screen-size distance cull for small geometry.
##
## The realm far floors (Meadows 2 km, Cloudreach 3.5 km, Tidewake 6.5 km,
## Stormwood 9 km) keep the horizon in view, and they also kept drawing every
## small object inside that distance that had no visibility range of its own.
## Measured at the F26 start stands:
## - Stormwood's 802 wild creatures cost 1,566 draws and 2.5M primitives at
##   9 km, against almost nothing at 520 m.
## - Tidewake's camp creature-bed dressing cost 1,064 draws across 6.5 km.
##
## Each MeshInstance3D / MultiMeshInstance3D that has no visibility range gets
## one: the distance at which its world-space bounds would cover fewer than
## `pixels` pixels of a 1080p frame at the gameplay FOV. Size scales the
## range, so a 2 m creature fades out around half a kilometre, while a 40 m
## cliff or a horizon ring keeps tens of kilometres and never culls. The
## silhouette of the world stays; sub-pixel clutter stops costing draws.
##
## Left alone:
## - anything with an authored range;
## - emissive surfaces (a lit lamp reads as a point of light at any distance);
## - Terrain3D's own scatter;
## - the local player's own subtree;
## - nodes with meta `detail_cull_skip`.

const PERF_CONFIG := preload("res://scripts/world/performance_config.gd")
const SKIP_META := &"detail_cull_skip"


static func watch(world: Node) -> void:
	if world == null or not world.is_inside_tree():
		return
	var cfg := _config()
	if not bool(cfg.get("enabled", false)):
		return
	for node: Node in world.find_children("*", "GeometryInstance3D", true, false):
		apply(node as GeometryInstance3D, cfg)
	var tree := world.get_tree()
	var handler := Callable(_on_node_added)
	if not tree.node_added.is_connected(handler):
		tree.node_added.connect(handler)


static func _on_node_added(node: Node) -> void:
	if node is MeshInstance3D or node is MultiMeshInstance3D:
		# Builders place, scale and assign meshes after add_child; measure next frame.
		(func() -> void:
			if is_instance_valid(node) and node.is_inside_tree():
				apply(node as GeometryInstance3D, _config())).call_deferred()


static func apply(geometry: GeometryInstance3D, cfg: Dictionary) -> void:
	if geometry == null or not bool(cfg.get("enabled", false)):
		return
	if not (geometry is MeshInstance3D or geometry is MultiMeshInstance3D):
		return
	if geometry.visibility_range_end > 0.0 or geometry.visibility_range_begin > 0.0:
		return
	if _skipped(geometry):
		return
	var size := _world_size(geometry)
	if size <= 0.0:
		return
	if bool(cfg.get("skip_emissive", true)) and _emissive(geometry):
		return
	# Pixel height of an object of size h at distance d, for vertical FOV f and
	# a 1080-line frame: h / d * 1080 / (2 tan(f / 2)). Solved for d.
	var fov := deg_to_rad(float(cfg.get("reference_fov_deg", 70.0)))
	var lines := float(cfg.get("reference_lines", 1080.0))
	var pixels := maxf(0.5, float(cfg.get("pixels", 2.5)))
	var reach := size * lines / (2.0 * tan(fov * 0.5)) / pixels
	reach = maxf(reach, float(cfg.get("min_range_m", 150.0)))
	if reach >= float(cfg.get("ignore_beyond_m", 9000.0)):
		return
	geometry.visibility_range_end = reach
	geometry.visibility_range_end_margin = reach * float(cfg.get("fade_fraction", 0.1))
	geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED


static func _world_size(geometry: GeometryInstance3D) -> float:
	var box := geometry.get_aabb()
	if geometry is MultiMeshInstance3D:
		# A MultiMesh's AABB spans every instance; the object that shrinks to a
		# pixel is one instance, so measure its mesh instead.
		var mm := (geometry as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null:
			return 0.0
		box = mm.mesh.get_aabb()
	var scale := geometry.global_basis.get_scale()
	var extent := box.size * Vector3(absf(scale.x), absf(scale.y), absf(scale.z))
	return maxf(extent.x, maxf(extent.y, extent.z))


static func _skipped(node: Node) -> bool:
	var at := node
	while at != null:
		if at.has_meta(SKIP_META) or at.get_class() == "Terrain3D" or str(at.name) == "Player":
			return true
		at = at.get_parent()
	return false


static func _emissive(geometry: GeometryInstance3D) -> bool:
	var materials: Array[Material] = []
	if geometry.material_override != null:
		materials.append(geometry.material_override)
	var mesh: Mesh = null
	if geometry is MeshInstance3D:
		mesh = (geometry as MeshInstance3D).mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var material := (geometry as MeshInstance3D).get_active_material(surface)
			if material != null:
				materials.append(material)
	elif geometry is MultiMeshInstance3D and (geometry as MultiMeshInstance3D).multimesh != null:
		mesh = (geometry as MultiMeshInstance3D).multimesh.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			if mesh.surface_get_material(surface) != null:
				materials.append(mesh.surface_get_material(surface))
	for material: Material in materials:
		if material is BaseMaterial3D and (material as BaseMaterial3D).emission_enabled:
			return true
		if material is ShaderMaterial:
			var shader := (material as ShaderMaterial).shader
			if shader != null and shader.code.contains("EMISSION"):
				return true
	return false


static func _config() -> Dictionary:
	var cfg: Variant = PERF_CONFIG.config().get("detail_cull", {})
	return cfg if cfg is Dictionary else {}

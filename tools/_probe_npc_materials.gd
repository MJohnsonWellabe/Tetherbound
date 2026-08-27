extends SceneTree

## GF-B-010. Why does an NPC render as an unlit black silhouette in daylight
## when the player, a metre away and lit by the same sun, shades correctly?
##
##   godot --headless --path . --script tools/_probe_npc_materials.gd
##
## The player IS the control: `scripts/player/trainer_model.gd` extends the same
## `character_model.gd` every NPC is built through, so anything that differs
## between the trainer's built materials and a villager's or a grunt's is a
## candidate cause, and anything that matches is not.
##
## Prints, per character and per surface, every BaseMaterial3D property that can
## turn a lit surface black: the shading mode, both albedo channels, the whole
## emission group (Godot's `emission_operator` is the one that bit this file
## before -- see `character_model.gd::_shared_variant_material`), and the
## texture's own measured luminance, which is what decides whether a "correctly
## configured" material can produce a visible pixel at all.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")

const KEYS := ["trainer", "grandpa", "villager_farmer", "villager_keeper", "warden", "grunt"]


func _init() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)

	for key: String in KEYS:
		_report(key, CHARACTER_MODEL.config_for(key), root_node)
	for rank: Variant in NPC_RANKS.rank_ids():
		_report("rank:%s" % str(rank), NPC_RANKS.config_for(str(rank)), root_node)
	quit(0)


func _report(label: String, cfg: Dictionary, parent: Node3D) -> void:
	print("\n=== %s ===" % label)
	if cfg.is_empty():
		print("  (no config)")
		return
	print("  model: %s" % str(cfg.get("model", "")))
	print("  tint: %s  palette: %s" % [str(cfg.get("tint", "-")), str(cfg.get("palette", {}))])
	var holder := Node3D.new()
	holder.set_script(CHARACTER_MODEL)
	parent.add_child(holder)
	if not bool(holder.call("build_from_config", cfg)):
		print("  BUILD FAILED")
		return
	_walk(holder, "")
	holder.queue_free()


func _walk(node: Node, path: String) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				_describe("%s/%s" % [path, mi.name], s, mi.get_active_material(s))
	for child in node.get_children():
		_walk(child, "%s/%s" % [path, node.name])


func _describe(where: String, surface: int, mat: Material) -> void:
	if mat == null:
		print("  %s[%d]: NO MATERIAL" % [where, surface])
		return
	if not mat is BaseMaterial3D:
		print("  %s[%d]: %s (not a BaseMaterial3D)" % [where, surface, mat.get_class()])
		return
	var m := mat as BaseMaterial3D
	var tex: Texture2D = m.albedo_texture
	var tex_line := "none"
	if tex != null:
		tex_line = "%s %dx%d mean_luma=%.3f" % [
			tex.resource_path.get_file(), tex.get_width(), tex.get_height(), _mean_luma(tex)]
	var emis: Texture2D = m.emission_texture
	print("  %s[%d] name=%s" % [where, surface, m.resource_name])
	print("      shading=%d cull=%d unshaded=%s albedo=%s" % [
		m.shading_mode, m.cull_mode, str(m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED),
		m.albedo_color])
	print("      albedo_tex: %s" % tex_line)
	print("      emission_enabled=%s operator=%d colour=%s energy=%.3f tex=%s" % [
		m.emission_enabled, m.emission_operator, m.emission, m.emission_energy_multiplier,
		("none" if emis == null else emis.resource_path.get_file())])
	print("      metallic=%.2f roughness=%.2f specular=%.2f ao=%s rim=%s" % [
		m.metallic, m.roughness, m.metallic_specular, m.ao_enabled, m.rim_enabled])
	print("      transparency=%d blend=%d no_depth=%s vertex_colour_as_albedo=%s" % [
		m.transparency, m.blend_mode, m.no_depth_test, m.vertex_color_use_as_albedo])


## Mean relative luminance of the texture, 0..1, on a coarse grid -- the number
## that says whether the surface can produce a bright pixel at all.
func _mean_luma(tex: Texture2D) -> float:
	var img: Image = tex.get_image()
	if img == null:
		return -1.0
	if img.is_compressed():
		img = img.duplicate()
		if img.decompress() != OK:
			return -1.0
	var total := 0.0
	var samples := 0
	var step: int = maxi(1, img.get_width() / 64)
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var c := img.get_pixel(x, y)
			total += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			samples += 1
	return total / float(maxi(1, samples))

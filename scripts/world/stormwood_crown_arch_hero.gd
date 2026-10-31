extends RefCounted

## World dressing P2-041 (OFF until GPU judged). GPU 31 Oct: the Crown Arch is
## "a small square blue frame on an exposed square slab"; the octagonal-landing
## candidate gained +0.33 and all three judges asked for a real hero arch
## taller than the trainer, a crown keystone and crystal or copper accents,
## rooted in the moss rather than on a slab, and not hidden by the trainer.
## The coordinator's Meshy Crown Arch (assets/props/meshy-1031/crown_arch,
## provenance there) replaces the visible arch at about 5.5 m. Contract
## (crown_arch/reference/brief.md): the 2.2 x 2.5 m passage, runtime trigger,
## travel axis and terrain placement are unchanged. The old arch piece and the
## slab mesh are hidden, not freed: the footing collider, Passage area and
## relight prompt stay exactly as built. Config: data/config/crown_arch_hero.json.
const CONFIG := "res://data/config/crown_arch_hero.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const NODE_NAME := "CrownArchHero"


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


static func apply(arch: Node3D, piece: Node3D, slab: MeshInstance3D, clearance: Node3D) -> bool:
	var cfg := settings()
	if not bool(cfg.get("enabled", false)) or arch == null or arch.has_node(NODE_NAME):
		return false
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	if model == null:
		return false
	HERO_PROP.fit_height(model, float(cfg.get("height_m", 5.5)), float(cfg.get("sink_m", 0.15)))
	var bounds: AABB = model.transform * BOUNDS.measure(model)
	# Centre the arch on the authored travel axis (arch local Z).
	model.position.x -= bounds.get_center().x
	model.position.z -= bounds.get_center().z
	var across := maxf(bounds.size.x, bounds.size.z)
	var min_across := float(cfg.get("min_outer_width_m", 4.2))
	if across < min_across:
		# Never narrow the declared 2.2 m passage: widen until the outer span
		# clears the pillars around it.
		var widen := min_across / maxf(across, 0.01)
		model.scale.x *= widen
		model.position.x *= widen
	if cfg.has("glow_colour"):
		HERO_PROP.glow(model, Color(str(cfg.glow_colour)), float(cfg.get("glow_energy", 1.2)))
	var seat := Node3D.new()
	seat.name = NODE_NAME
	seat.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	seat.add_child(model)
	arch.add_child(seat)
	if piece != null and bool(cfg.get("hide_old_arch", true)):
		_hide_visuals(piece)
	if slab != null and bool(cfg.get("hide_slab", true)):
		slab.visible = false
	if clearance != null and cfg.has("grass_clear_radius_m"):
		clearance.set_meta("grass_clear_radius", float(cfg.grass_clear_radius_m))
	return true


## Hide every visual under the old arch piece; collision, areas and scripts
## (set_lit and the travel state) keep running on the hidden nodes.
static func _hide_visuals(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).visible = false
	elif node is Light3D:
		(node as Light3D).visible = false
	for child: Node in node.get_children():
		_hide_visuals(child)

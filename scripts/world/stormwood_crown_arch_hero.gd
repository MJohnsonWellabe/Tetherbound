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


static func apply(arch: Node3D, piece: Node3D, slab: MeshInstance3D, clearance: Node3D,
		ground_height: Callable = Callable()) -> bool:
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
	elif slab != null and cfg.get("slab_moss") is Dictionary:
		# The 9x9 m footing collider stands 0.2 m proud; hiding its mesh
		# floated the trainer. Re-skin it as a raised moss bank instead.
		var moss_cfg: Dictionary = cfg.slab_moss
		var moss := StandardMaterial3D.new()
		moss.albedo_texture = load(str(moss_cfg.get("albedo", ""))) as Texture2D
		moss.albedo_color = Color(str(moss_cfg.get("tint", "#ffffff")))
		moss.uv1_triplanar = true
		moss.uv1_scale = Vector3.ONE * float(moss_cfg.get("uv_per_m", 0.25))
		moss.roughness = 0.95
		slab.material_override = moss
	if clearance != null and cfg.has("grass_clear_radius_m"):
		clearance.set_meta("grass_clear_radius", float(cfg.grass_clear_radius_m))
	var skirt_cfg: Dictionary = cfg.get("skirt", {}) as Dictionary
	if slab != null and bool(skirt_cfg.get("enabled", false)):
		_skirt(arch, slab, skirt_cfg, ground_height)
	return true


## r3 (all six b1/b2 judges: "a hard-edged square slab floating over the
## moss"): a moss skirt slopes from the footing's top edge down into the
## sampled ground, so the 9x9 m footing reads as a raised mound, and installed
## rocks, ferns and glowing storm fungi break its outline. The footing
## collider is untouched; the skirt has no collider.
static func _skirt(arch: Node3D, slab: MeshInstance3D, cfg: Dictionary, ground_height: Callable) -> void:
	var box := slab.mesh as BoxMesh
	if box == null:
		return
	var half := box.size.x * 0.5
	var top := slab.position.y + box.size.y * 0.5 + (slab.get_parent() as Node3D).position.y
	var out := float(cfg.get("out_m", 2.6))
	var segments := 12
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	var ring_in := PackedVector3Array()
	var ring_out := PackedVector3Array()
	for side in 4:
		for k in segments:
			var t := float(k) / float(segments)
			var corner := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
			var a: Vector2 = corner[side]
			var b: Vector2 = corner[(side + 1) % 4]
			var p: Vector2 = a.lerp(b, t)
			var inner := p * half
			var wobble := 1.0 + 0.12 * sin(float(side * segments + k) * 1.7)
			var outer := p * half + p.normalized() * out * wobble
			ring_in.append(Vector3(inner.x, top + 0.01, inner.y))
			var gy := -0.08
			if ground_height.is_valid() and arch.is_inside_tree():
				var w := arch.to_global(Vector3(outer.x, 0.0, outer.y))
				var g := float(ground_height.call(w.x, w.z))
				if is_finite(g):
					gy = arch.to_local(Vector3(w.x, g, w.z)).y - 0.08
			ring_out.append(Vector3(outer.x, gy, outer.y))
	var n := ring_in.size()
	for i in n:
		var j := (i + 1) % n
		for v: Vector3 in [ring_in[i], ring_out[i], ring_out[j], ring_in[i], ring_out[j], ring_in[j]]:
			surface.set_uv(Vector2(v.x, v.z) * float(cfg.get("uv_per_m", 0.22)))
			surface.add_vertex(v)
	surface.generate_normals()
	var moss := slab.material_override
	var skirt := MeshInstance3D.new()
	skirt.name = "CrownArchMossSkirt"
	skirt.mesh = surface.commit()
	skirt.material_override = moss
	skirt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arch.add_child(skirt)
	# Edge dressing, deterministic per index.
	var dressing: Array = cfg.get("dressing", [])
	var count := int(cfg.get("dressing_count", 14))
	for i in count:
		if dressing.is_empty():
			break
		var entry: Dictionary = dressing[i % dressing.size()]
		var model := HERO_PROP.load_model(str(entry.get("model", "")))
		if model == null:
			continue
		var heights: Array = entry.get("height_m", [0.6, 1.0])
		HERO_PROP.fit_height(model, lerpf(float(heights[0]), float(heights[1]), float((i * 7) % 5) / 4.0), 0.06)
		if entry.has("glow_colour"):
			HERO_PROP.glow(model, Color(str(entry.glow_colour)), float(entry.get("glow_energy", 1.0)))
		var perim := float(i) / float(count) * 4.0
		var side_i := int(perim) % 4
		var t2 := perim - floor(perim)
		var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
		var p2: Vector2 = (corners[side_i] as Vector2).lerp(corners[(side_i + 1) % 4], t2)
		var at := p2 * (half + out * float(entry.get("at_fraction", 0.45)))
		var seat := Node3D.new()
		seat.name = "CrownArchEdge%02d" % i
		var y := 0.0
		if ground_height.is_valid() and arch.is_inside_tree():
			var w2 := arch.to_global(Vector3(at.x, 0.0, at.y))
			var g2 := float(ground_height.call(w2.x, w2.z))
			if is_finite(g2):
				y = arch.to_local(Vector3(w2.x, g2, w2.z)).y
		seat.position = Vector3(at.x, maxf(y, top * float(entry.get("lift_to_top", 0.0))), at.y)
		seat.rotation.y = float(i) * 2.3
		seat.add_child(model)
		arch.add_child(seat)


## Hide every visual under the old arch piece; collision, areas and scripts
## (set_lit and the travel state) keep running on the hidden nodes.
static func _hide_visuals(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).visible = false
	elif node is Light3D:
		(node as Light3D).visible = false
	for child: Node in node.get_children():
		_hide_visuals(child)

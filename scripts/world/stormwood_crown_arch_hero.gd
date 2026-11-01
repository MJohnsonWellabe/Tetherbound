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
	var cfg: Dictionary = parsed if parsed is Dictionary else {}
	return with_round2(cfg)


## P2-041 round 2 (GPU WD2 1 Nov, 4.78: "neither side reads as an arch, and the
## square slab is still exposed"; the CPU frames show the arch small at the far
## end of a hard-edged square slab with the trainer covering its opening).
## `round2_candidate`, OFF by default: its keys replace the hero's (a taller
## arch) and `edge_dressing` breaks the slab's square outline with half-sunk
## rock-family stones and bushes along its edges, so it reads as a mossy
## stone landing. Visual only; the footing collider and passage are unchanged.
static func with_round2(cfg: Dictionary) -> Dictionary:
	var cand: Variant = cfg.get("round2_candidate", {})
	if not cand is Dictionary or not bool((cand as Dictionary).get("enabled", false)):
		return cfg
	var merged := cfg.duplicate(true)
	for key: String in (cand as Dictionary):
		if key == "enabled" or key.begins_with("_"):
			continue
		merged[key] = (cand as Dictionary)[key]
	return merged


static func _dress_slab_edges(arch: Node3D, slab: MeshInstance3D, cfg: Dictionary) -> void:
	var dress: Variant = cfg.get("edge_dressing", {})
	if not dress is Dictionary or slab == null or slab.mesh == null:
		return
	var models: Array = (dress as Dictionary).get("models", [])
	if models.is_empty():
		return
	var box: AABB = slab.mesh.get_aabb()
	var to_arch := arch.global_transform.affine_inverse() * slab.global_transform
	var half := Vector2(box.size.x * slab.scale.x, box.size.z * slab.scale.z) * 0.5
	var centre := to_arch * box.get_center()
	var top := centre.y + box.size.y * 0.5 * slab.scale.y
	var per_side := maxi(1, int((dress as Dictionary).get("per_side", 4)))
	var sizes: Array = (dress as Dictionary).get("height_m", [0.6, 1.2])
	var keep_clear := float((dress as Dictionary).get("keep_passage_clear_m", 2.0))
	var root := Node3D.new()
	root.name = "CrownArchSlabEdge"
	arch.add_child(root)
	var index := 0
	for side: int in 4:
		for i in per_side:
			var t := (float(i) + 0.5) / float(per_side) * 2.0 - 1.0
			var local := Vector2.ZERO
			match side:
				0: local = Vector2(t * half.x, half.y)
				1: local = Vector2(t * half.x, -half.y)
				2: local = Vector2(half.x, t * half.y)
				3: local = Vector2(-half.x, t * half.y)
			# The travel axis is arch local Z: leave the walkway ends open.
			if side < 2 and absf(local.x) < keep_clear:
				continue
			var path := str(models[index % models.size()])
			index += 1
			var scene := load(path) as PackedScene
			if scene == null:
				continue
			var piece := scene.instantiate() as Node3D
			for body: Node in piece.find_children("*", "CollisionObject3D", true, false):
				body.queue_free()
			if (dress as Dictionary).has("tint"):
				var tint := Color(str((dress as Dictionary).tint))
				for mesh: Node in piece.find_children("*", "MeshInstance3D", true, false):
					var visual := mesh as MeshInstance3D
					for surface in visual.mesh.get_surface_count():
						var source := visual.get_active_material(surface) as StandardMaterial3D
						var tinted := source.duplicate() as StandardMaterial3D if source != null else StandardMaterial3D.new()
						tinted.albedo_color = tint
						tinted.roughness = 0.9
						visual.set_surface_override_material(surface, tinted)
			var size := lerpf(float(sizes[0]), float(sizes[1]), float((index * 7) % 5) / 4.0)
			var bounds: AABB = BOUNDS.measure(piece)
			var k := size / maxf(bounds.size.y, 0.01)
			piece.scale = Vector3(k * 1.3, k, k * 1.15)
			piece.position = Vector3(centre.x + local.x, top - size * 0.35, centre.z + local.y)
			piece.rotation.y = float((index * 73) % 360) * PI / 180.0
			root.add_child(piece)


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
	if slab != null:
		_dress_slab_edges(arch, slab, cfg)
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

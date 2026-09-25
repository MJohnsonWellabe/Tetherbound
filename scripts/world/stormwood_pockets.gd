extends Node3D

## WORLD §5.1 dead-end pockets: five walled clearings off the Stormwood roads,
## each holding one existing optional reward. Each clearing is closed on every
## side by a dead-trunk palisade with invisible static collision, except one
## mouth that faces its nearest road. `wall_boxes` is the single geometry
## source for the runtime colliders, the palisade and the tests.
const CONFIG_PATH := "res://data/config/stormwood_pockets.json"
const TRUNKS: Array[String] = [
	"res://assets/environment/stylized_nature/DeadTree_1.gltf",
	"res://assets/environment/stylized_nature/DeadTree_2.gltf",
	"res://assets/environment/stylized_nature/DeadTree_3.gltf",
]
## Collision reaches this far below the local ground so a slope under a
## 4 m segment never opens a gap beneath the wall.
const FOOTING_DEPTH_M := 3.0
const TRUNK_SCALE := 2.2


static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH)) as Dictionary


## Horizontal frame of a pocket: `forward` points out through the mouth.
static func frame(pocket: Dictionary) -> Dictionary:
	var yaw := deg_to_rad(float(pocket.mouth_yaw_deg))
	var forward := Vector2(sin(yaw), cos(yaw))
	return {"centre": Vector2(float(pocket.at[0]), float(pocket.at[1])), "forward": forward,
		"right": Vector2(forward.y, -forward.x)}


## Wall segments as {centre: Vector2, along: Vector2 (unit), length: float}.
## The four sides sit just outside the interior square; the mouth side leaves
## a centred gap of `mouth_width_m`.
static func wall_boxes(pocket: Dictionary, cfg: Dictionary) -> Array[Dictionary]:
	var half := float(cfg.interior_half_m)
	var thick := float(cfg.wall_thickness_m)
	var reach := half + thick
	var offset := half + thick * 0.5
	var gap := float(cfg.mouth_width_m) * 0.5
	var runs: Array = [
		[Vector2(-reach, -offset), Vector2(reach, -offset)],  # back
		[Vector2(-offset, -reach), Vector2(-offset, reach)],  # left
		[Vector2(offset, -reach), Vector2(offset, reach)],  # right
		[Vector2(-reach, offset), Vector2(-gap, offset)],  # mouth, left of the gap
		[Vector2(gap, offset), Vector2(reach, offset)],  # mouth, right of the gap
	]
	var f: Dictionary = frame(pocket)
	var out: Array[Dictionary] = []
	for run: Array in runs:
		var a := _to_world(f, run[0])
		var b := _to_world(f, run[1])
		var pieces := maxi(1, ceili(a.distance_to(b) / float(cfg.wall_segment_m)))
		var along := (b - a).normalized()
		for i in pieces:
			var p0 := a.lerp(b, float(i) / pieces)
			var p1 := a.lerp(b, float(i + 1) / pieces)
			out.append({"centre": (p0 + p1) * 0.5, "along": along, "length": p0.distance_to(p1)})
	return out


## True when `at` lies inside the pocket's walkable interior square.
static func contains(pocket: Dictionary, cfg: Dictionary, at: Vector2) -> bool:
	var f: Dictionary = frame(pocket)
	var local := at - (f.centre as Vector2)
	var half := float(cfg.interior_half_m)
	return absf(local.dot(f.right)) <= half and absf(local.dot(f.forward)) <= half


static func _to_world(f: Dictionary, local: Vector2) -> Vector2:
	return (f.centre as Vector2) + (f.right as Vector2) * local.x + (f.forward as Vector2) * local.y


## The two lure posts flanking a mouth (config `mouth_lure`), in world XZ:
## against the wall's outer face, `edge_offset_m` beyond each mouth edge.
static func lure_posts(pocket: Dictionary, cfg: Dictionary) -> Array[Vector2]:
	var lure: Dictionary = cfg.get("mouth_lure", {})
	if lure.is_empty():
		return []
	var f: Dictionary = frame(pocket)
	var out_m := float(cfg.interior_half_m) + float(cfg.wall_thickness_m) + float(lure.post_width_m) * 0.5 + 0.05
	var side_m := float(cfg.mouth_width_m) * 0.5 + float(lure.edge_offset_m)
	return [_to_world(f, Vector2(-side_m, out_m)), _to_world(f, Vector2(side_m, out_m))]


func build(world: Node3D) -> void:
	var cfg := config()
	var height := float(cfg.wall_height_m)
	var thick := float(cfg.wall_thickness_m)
	var show_models := not bool(world.get("simulation_only"))
	for pocket: Dictionary in cfg.pockets:
		var body := StaticBody3D.new()
		body.name = "Pocket_%s" % str(pocket.id)
		add_child(body)
		var walls := wall_boxes(pocket, cfg)
		for index in walls.size():
			var wall: Dictionary = walls[index]
			var centre: Vector2 = wall.centre
			var along: Vector2 = wall.along
			var ground := float(world.call("ground_height_at", centre.x, centre.y))
			var collision := CollisionShape3D.new()
			collision.name = "Wall%02d" % index
			var shape := BoxShape3D.new()
			shape.size = Vector3(float(wall.length), height + FOOTING_DEPTH_M, thick)
			collision.shape = shape
			collision.position = Vector3(centre.x, ground + (height - FOOTING_DEPTH_M) * 0.5, centre.y)
			collision.rotation.y = atan2(-along.y, along.x)
			body.add_child(collision)
			if show_models:
				_palisade(world, body, centre - along * float(wall.length) * 0.5, along, float(wall.length),
					float(cfg.palisade_spacing_m), index)
		_mouth_lure(world, body, pocket, cfg, show_models)


func _palisade(world: Node3D, parent: Node3D, start: Vector2, along: Vector2, length: float, spacing: float, salt: int) -> void:
	# At most `spacing` apart: the trunks read as the solid wall the collider is.
	var count := maxi(1, ceili(length / spacing))
	for i in count:
		var at := start + along * (float(i) + 0.5) * length / count
		var model := (load(TRUNKS[(salt + i) % TRUNKS.size()]) as PackedScene).instantiate() as Node3D
		model.position = Vector3(at.x, float(world.call("ground_height_at", at.x, at.y)) - 0.3, at.y)
		model.scale = Vector3.ONE * TRUNK_SCALE
		model.rotation.y = float((salt * 7 + i * 13) % 360) * PI / 180.0
		parent.add_child(model)


## The mouth lure: a wayfinding lamp on a post either side of the mouth. The
## posts collide on every peer; the lamps are art only.
func _mouth_lure(world: Node3D, body: StaticBody3D, pocket: Dictionary, cfg: Dictionary, show_models: bool) -> void:
	var lure: Dictionary = cfg.get("mouth_lure", {})
	if lure.is_empty():
		return
	var forward: Vector2 = frame(pocket).forward
	var width := float(lure.post_width_m)
	var height := float(lure.post_height_m)
	var wood: StandardMaterial3D = null
	var flame: StandardMaterial3D = null
	if show_models:
		wood = StandardMaterial3D.new()
		wood.albedo_color = Color(str(lure.post_colour))
		wood.albedo_texture = load("res://assets/environment/stylized_nature/Bark_TwistedTree.png")
		wood.uv1_scale = Vector3(0.35, 0.35, 1)
		wood.roughness = 0.88
		flame = StandardMaterial3D.new()
		flame.albedo_color = Color(str(lure.flame_albedo))
		flame.emission_enabled = true
		flame.emission = Color(str(lure.flame_emission))
		flame.emission_energy_multiplier = float(lure.flame_emission_energy)
		flame.roughness = 0.45
	var posts := lure_posts(pocket, cfg)
	for index in posts.size():
		var at: Vector2 = posts[index]
		var ground := float(world.call("ground_height_at", at.x, at.y))
		var collision := CollisionShape3D.new()
		collision.name = "LurePost%d" % index
		var shape := BoxShape3D.new()
		shape.size = Vector3(width, height + FOOTING_DEPTH_M, width)
		collision.shape = shape
		collision.position = Vector3(at.x, ground + (height - FOOTING_DEPTH_M) * 0.5, at.y)
		# Same yaw as the lamp holder below, so the collider matches the post.
		collision.rotation.y = atan2(forward.x, forward.y)
		body.add_child(collision)
		if not show_models:
			continue
		var holder := Node3D.new()
		holder.name = "MouthLamp%d" % index
		holder.position = Vector3(at.x, ground, at.y)
		# Local +Z (the lantern's arm) points out of the mouth along the approach.
		holder.rotation.y = atan2(forward.x, forward.y)
		body.add_child(holder)
		var post := MeshInstance3D.new()
		post.name = "Post"
		var box := BoxMesh.new()
		box.size = Vector3(width, height + 0.4, width)
		post.mesh = box
		post.material_override = wood
		post.position.y = (height - 0.4) * 0.5
		holder.add_child(post)
		var lantern_scale := float(lure.lantern_scale)
		var lantern := (load(str(lure.lantern_model)) as PackedScene).instantiate() as Node3D
		lantern.name = "Lantern"
		lantern.scale = Vector3.ONE * lantern_scale
		lantern.position = Vector3(0.0, float(lure.lantern_mount_height_m), width * 0.5)
		holder.add_child(lantern)
		# The installed lantern's cage centre sits at (0, 0.85, 0.73) in its own units.
		var cage := lantern.position + Vector3(0.0, 0.85, 0.73) * lantern_scale
		var bulb := MeshInstance3D.new()
		bulb.name = "AmberFlame"
		var sphere := SphereMesh.new()
		sphere.radius = float(lure.flame_radius_m)
		sphere.height = float(lure.flame_radius_m) * 2.0
		bulb.mesh = sphere
		bulb.material_override = flame
		bulb.position = cage
		holder.add_child(bulb)
		var light := OmniLight3D.new()
		light.name = "WarmMouthLight"
		light.position = cage + Vector3(0.0, 0.0, 0.3)
		light.light_color = Color(str(lure.light_colour))
		light.light_energy = float(lure.light_energy)
		light.omni_range = float(lure.light_range_m)
		light.shadow_enabled = false
		holder.add_child(light)

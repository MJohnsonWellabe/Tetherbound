extends RefCounted
## F41#1 floor_lanterns_1104 (OFF until judged; stormheart_presentation.json).
## Coordinator redirect 4 Nov 22:25: lighting and set dressing from installed
## families around the finale arena. Judges read the Stormheart hollow as a
## flat-lit plank drum with "no warm lanterns, no lamp pools" (the deck
## lanterns hang out of the arena views). A ring of installed Lantern_Wall
## posts stands on the hollow floor at the wall foot, each with an amber flame
## and a warm, shadowless pool of light. Visual only: no collider, so no route
## or arena change.

const CONFIG_PATH := "res://data/config/stormheart_presentation.json"
const NODE_NAME := "StormheartFloorLanterns"
## The installed Lantern_Wall's cage centre in its own units (stormwood_pockets.gd).
const LANTERN_CAGE := Vector3(0.0, 0.3, 0.8)


static func config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		return {}
	var cfg: Variant = (parsed as Dictionary).get("floor_lanterns_1104", {})
	return cfg if cfg is Dictionary and bool((cfg as Dictionary).get("enabled", false)) else {}


static func ring_points(cfg: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var centre: Array = cfg.get("centre", [-100.0, 5470.0])
	var c := Vector2(float(centre[0]), float(centre[1]))
	var count := int(cfg.get("count", 8))
	var radius := float(cfg.get("radius_m", 40.0))
	var phase := deg_to_rad(float(cfg.get("phase_deg", 22.5)))
	for i in count:
		var a := phase + TAU * float(i) / float(count)
		out.append(c + Vector2(cos(a), sin(a)) * radius)
	return out


static func install(world: Node3D, cfg: Dictionary = {}) -> Node3D:
	if cfg.is_empty():
		cfg = config()
	if cfg.is_empty() or world == null or world.has_node(NODE_NAME):
		return null
	var scene := load(str(cfg.get("lantern_model", "res://assets/props/quaternius_fantasy/Lantern_Wall.gltf"))) as PackedScene
	if scene == null:
		push_warning("Stormheart floor lanterns: lantern model missing")
		return null
	var root := Node3D.new()
	root.name = NODE_NAME
	world.add_child(root)
	var centre: Array = cfg.get("centre", [-100.0, 5470.0])
	var axis := Vector2(float(centre[0]), float(centre[1]))
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(str(cfg.get("post_colour", "#5a4630")))
	wood.roughness = 0.9
	var flame := StandardMaterial3D.new()
	flame.albedo_color = Color(str(cfg.get("flame_albedo", "#ffbd62")))
	flame.emission_enabled = true
	flame.emission = Color(str(cfg.get("flame_emission", "#ff9a3d")))
	flame.emission_energy_multiplier = float(cfg.get("flame_energy", 4.0))
	var height := float(cfg.get("post_height_m", 2.8))
	var lantern_scale := float(cfg.get("lantern_scale", 1.4))
	var index := 0
	for at: Vector2 in ring_points(cfg):
		var holder := Node3D.new()
		holder.name = "FloorLantern%02d" % index
		var ground := float(world.call("ground_height_at", at.x, at.y)) if world.has_method("ground_height_at") else 0.0
		holder.position = Vector3(at.x, ground, at.y)
		# Face the trunk axis so the lantern hangs toward the arena.
		var to_axis := axis - at
		holder.rotation.y = atan2(to_axis.x, to_axis.y)
		root.add_child(holder)
		var post := MeshInstance3D.new()
		post.name = "Post"
		var box := BoxMesh.new()
		box.size = Vector3(0.34, height + 0.4, 0.34)
		post.mesh = box
		post.material_override = wood
		post.position.y = (height - 0.4) * 0.5
		holder.add_child(post)
		var lantern := scene.instantiate() as Node3D
		lantern.name = "Lantern"
		lantern.scale = Vector3.ONE * lantern_scale
		lantern.position = Vector3(0.0, height - 0.6, 0.17)
		for body: Node in lantern.find_children("*", "CollisionObject3D", true, false):
			body.queue_free()
		holder.add_child(lantern)
		var cage := lantern.position + LANTERN_CAGE * lantern_scale
		var bulb := MeshInstance3D.new()
		bulb.name = "AmberFlame"
		var sphere := SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		bulb.mesh = sphere
		bulb.material_override = flame
		bulb.position = cage
		holder.add_child(bulb)
		var light := OmniLight3D.new()
		light.name = "WarmFloorLight"
		light.position = cage + Vector3(0.0, 0.0, 0.3)
		light.light_color = Color(str(cfg.get("light_colour", "#ffb15c")))
		light.light_energy = float(cfg.get("light_energy", 2.4))
		light.omni_range = float(cfg.get("light_range_m", 16.0))
		light.shadow_enabled = false
		holder.add_child(light)
		index += 1
	return root

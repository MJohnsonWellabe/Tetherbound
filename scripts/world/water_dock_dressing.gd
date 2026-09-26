extends Node3D

## X04 / F13#5 presentation: every Tidewake dock departure reads as a place
## people use. Config: data/config/water_dock_dressing.json. Built beside
## WaterDocks by water_world.gd. Presentation only -- no collision, nothing on
## the swim lane (the pier stands `lateral_offset_m` to one side of the
## safe->shore line), no gameplay state.

const CONFIG_PATH := "res://data/config/water_dock_dressing.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _built := false


func build(water_world: Node3D) -> void:
	if _built:
		return
	_built = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("water dock dressing config is invalid")
		return
	var cfg := parsed as Dictionary
	var world_cfg: Dictionary = water_world.get("config")
	var anchors := {}
	for anchor: Variant in world_cfg.get("anchors", []):
		anchors[str((anchor as Dictionary).get("id", ""))] = anchor
	for dock: Variant in world_cfg.get("docks", []):
		var anchor: Dictionary = anchors.get(str((dock as Dictionary).get("departure_anchor", "")), {})
		if anchor.is_empty():
			continue
		var site := Node3D.new()
		site.name = "%sDressing" % str((dock as Dictionary).get("id", "dock"))
		add_child(site)
		_dress(site, water_world, anchor, cfg)


func _dress(site: Node3D, world: Node3D, anchor: Dictionary, cfg: Dictionary) -> void:
	var safe_raw: Array = anchor.get("safe_position", [])
	var shore_raw: Array = anchor.get("shore_position", [])
	if safe_raw.size() < 3 or shore_raw.size() < 3:
		return
	var safe := Vector2(float(safe_raw[0]), float(safe_raw[2]))
	var shore := Vector2(float(shore_raw[0]), float(shore_raw[2]))
	var forward := (shore - safe).normalized()
	if forward.length() < 0.5:
		return
	var side := Vector2(-forward.y, forward.x)
	var yaw := atan2(forward.x, forward.y)
	var pier: Dictionary = cfg.get("pier", {})
	var length := float(pier.get("length_m", 9.0))
	var width := float(pier.get("width_m", 2.4))
	var start := shore - forward * float(pier.get("start_back_from_shore_m", 1.5)) \
		+ side * float(pier.get("lateral_offset_m", 4.0))
	var deck_y := maxf(float(pier.get("deck_height_m", 0.55)),
		_ground(world, start) + 0.2)
	# Deck: tiles laid along the pier.
	var tile := float(pier.get("tile_length_m", 1.8))
	var tiles := maxi(1, int(ceil(length / tile)))
	for i in tiles:
		var along := start + forward * (tile * (float(i) + 0.5))
		var plank := _fit_box(str(pier.get("deck_model", "")), Vector3(width, 0.18, tile), "PierDeck_%d" % i)
		if plank != null:
			plank.rotation.y = yaw
			plank.position += Vector3(along.x, deck_y - 0.18, along.y)
			site.add_child(plank)
	# Posts in pairs down both edges, from the seabed/ground up past the deck.
	var spacing := float(pier.get("post_spacing_m", 3.0))
	var post_height := float(pier.get("post_height_m", 1.9))
	var posts := int(floor(length / spacing)) + 1
	var lantern_cfg: Dictionary = cfg.get("lanterns", {})
	for i in posts:
		for edge: float in [-1.0, 1.0]:
			var at := start + forward * (spacing * float(i)) + side * edge * (width * 0.5)
			var base := minf(_ground(world, at), 0.0) - 0.4
			var top := deck_y + post_height * 0.55
			var post := _fit_upright(str(pier.get("post_model", "")), top - base,
				float(pier.get("post_radius_m", 0.16)), "PierPost_%d_%d" % [i, int(edge)])
			if post == null:
				continue
			post.position += Vector3(at.x, base, at.y)
			site.add_child(post)
			# Lanterns on the seaward pair and the landward pair.
			if i == 0 or i == posts - 1:
				_lantern(site, lantern_cfg, Vector3(at.x, top, at.y), yaw + (PI if edge < 0.0 else 0.0))
	# Cargo: a working cluster on land, to the pier's side, behind the route.
	var cargo: Dictionary = cfg.get("cargo", {})
	var origin := safe - forward * float(cargo.get("back_from_safe_m", 1.0)) \
		+ side * float(cargo.get("side_offset_m", 3.6))
	for item: Variant in cargo.get("items", []):
		var spec := item as Dictionary
		var offset: Array = spec.get("at", [0.0, 0.0])
		var at := origin + side * float(offset[0]) - forward * float(offset[1])
		var prop := _fit_height(str(spec.get("model", "")), float(spec.get("height_m", 1.0)), "Cargo")
		if prop == null:
			continue
		prop.position += Vector3(at.x, _ground(world, at), at.y)
		prop.rotation.y = yaw + deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		site.add_child(prop)


func _lantern(site: Node3D, cfg: Dictionary, at: Vector3, yaw: float) -> void:
	var lantern := _fit_height(str(cfg.get("model", "")), float(cfg.get("height_m", 0.62)), "PierLantern")
	if lantern == null:
		return
	lantern.position += at
	lantern.rotation.y = yaw
	site.add_child(lantern)
	var light := OmniLight3D.new()
	light.name = "PierLanternLight"
	light.light_color = Color(str(cfg.get("light_colour", "#ffc98a")))
	light.light_energy = float(cfg.get("light_energy", 0.9))
	light.omni_range = float(cfg.get("light_range_m", 7.0))
	light.shadow_enabled = false
	light.position = at + Vector3.UP * 0.3
	site.add_child(light)


func _ground(world: Node3D, at: Vector2) -> float:
	var y := float(world.call("ground_height_at", at.x, at.y))
	return y if is_finite(y) else 0.0


func _load(path: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("water dock dressing model missing: %s" % path)
		return null
	return packed.instantiate() as Node3D


## Uniform scale to `height`, feet on the local origin. The returned node's
## position already carries the foot offset; callers add the world position.
func _fit_height(path: String, height: float, id: String) -> Node3D:
	var node := _load(path)
	if node == null:
		return null
	node.name = id
	var bounds := RENDER_BOUNDS.measure(node)
	if bounds.size.y <= 0.001:
		node.free()
		return null
	var factor := height / bounds.size.y
	node.scale = Vector3.ONE * factor
	node.position = Vector3(0.0, -bounds.position.y * factor, 0.0)
	return node


## Non-uniform scale into an axis-aligned box (x across, y up, z along);
## centred on the local origin in x/z with its top at y = 0 + size.y.
func _fit_box(path: String, size: Vector3, id: String) -> Node3D:
	var node := _load(path)
	if node == null:
		return null
	node.name = id
	var bounds := RENDER_BOUNDS.measure(node)
	if bounds.size.x <= 0.001 or bounds.size.z <= 0.001:
		node.free()
		return null
	var s := Vector3(size.x / bounds.size.x, size.y / maxf(bounds.size.y, 0.001), size.z / bounds.size.z)
	var holder := Node3D.new()
	holder.name = id
	node.scale = s
	node.position = -Vector3(bounds.get_center().x * s.x, bounds.position.y * s.y, bounds.get_center().z * s.z)
	holder.add_child(node)
	return holder


## A log model stood on end: its longest axis becomes world up, scaled to
## `height` with a `radius` cross-section, base at the local origin.
func _fit_upright(path: String, height: float, radius: float, id: String) -> Node3D:
	var node := _load(path)
	if node == null:
		return null
	var bounds := RENDER_BOUNDS.measure(node)
	var longest := 0
	for axis in [1, 2]:
		if bounds.size[axis] > bounds.size[longest]:
			longest = axis
	var holder := Node3D.new()
	holder.name = id
	var turn := Node3D.new()
	turn.name = "Upright"
	holder.add_child(turn)
	turn.add_child(node)
	if longest == 0:
		turn.rotation.z = PI * 0.5
	elif longest == 2:
		turn.rotation.x = PI * 0.5
	var along := maxf(bounds.size[longest], 0.001)
	var across := maxf(bounds.size[(longest + 1) % 3], 0.001)
	var s := Vector3.ONE * (2.0 * radius / across)
	s[longest] = height / along
	node.scale = s
	node.position = -bounds.get_center() * s
	# After the turn the log is centred on the origin; lift its base to 0.
	holder.position = Vector3(0.0, height * 0.5, 0.0)
	return holder

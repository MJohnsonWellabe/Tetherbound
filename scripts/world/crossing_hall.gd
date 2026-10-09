extends Node3D

## F17 presentation owns no progression writes. Host WorldState is the sole
## shared display source; F18/F31 interactions validate and transact separately.
const ORDER := preload("res://scripts/data/biome_order.gd")
const CONFIG_PATH := "res://data/config/crossing_hall.json"
const ARCH_MODEL := "res://assets/buildings/quaternius_medieval/Wall_Arch.gltf"
const STAND_MODEL := "res://assets/props/quaternius_fantasy/BookStand.gltf"
const OPEN_MEMBRANE_EMISSION := .25
const RELIC_POWER_PANEL := preload("res://scripts/ui/relic_power_panel.gd")
const OBJECTIVE_BEACON := preload("res://scripts/world/objective_beacon.gd")
const WEATHER_PRESENTATION := preload("res://scripts/world/world_weather.gd")
const LANTERN_MODEL := "res://assets/props/quaternius_fantasy/Lantern_Wall.gltf"
const CATALOG_PRESENTATION := preload("res://scripts/world/meadows_catalog_presentation.gd")
const PORTAL_ACTION := preload("res://scripts/world/portal_arch.gd")
const PORTAL_DEPTH := preload("res://scripts/world/hall_portal_depth.gdshader")

var _config: Dictionary = {}
var _arches: Dictionary = {}
var _pedestals: Dictionary = {}
var _elapsed := 0.0
var _last_display: Dictionary = {}


func build(config: Dictionary) -> bool:
	if not validate_layout(config):
		push_error("Crossing Hall needs one home arch, seven signed arches and eight ordered pedestals")
		return false
	_config = config.duplicate(true)
	add_to_group("crossing_halls")
	for entry: Dictionary in _config.arches:
		_build_arch(entry)
	for entry: Dictionary in _config.pedestals:
		_build_pedestal(entry)
	_add_light(Vector3(0, 5.8, 5))
	_add_light(Vector3(12, 4.8, 0))
	for row: Dictionary in _config.get("interior_lights", []):
		_add_light(_position(row.at), float(row.get("yaw_deg", 0)))
	_build_frontage()
	_close_shell()
	_build_interior_ambient()
	_declare_interior_volumes()
	var catalog := CATALOG_PRESENTATION.new()
	catalog.name = "MeadowsCatalogPresentation"
	add_child(catalog)
	catalog.build("hall")
	var endwall := CATALOG_PRESENTATION.new()
	endwall.name = "MeadowsHallEndwallDressing"
	add_child(endwall)
	endwall.build("hall_endwall")
	refresh_from_game()
	set_process(true)
	return true


static func validate_layout(config: Dictionary) -> bool:
	var arches: Variant = config.get("arches")
	var pedestals: Variant = config.get("pedestals")
	if not arches is Array or not pedestals is Array or arches.size() != 8 or pedestals.size() != 8:
		return false
	var order := ORDER.ids(true)
	if order.size() != 8:
		return false
	var arch_ids: Array[String] = []
	for index: int in arches.size():
		var row: Variant = arches[index]
		if not row is Dictionary or not _position_valid(row.get("at")):
			return false
		var id := str(row.get("id", ""))
		if arch_ids.has(id) or str(row.get("biome", "")) != order[index]:
			return false
		if index == 0 and (id != "home" or row.get("kind") != "home"):
			return false
		if index > 0 and (id != order[index] or row.get("kind") != ("live" if index < 4 else "sealed")):
			return false
		arch_ids.append(id)
	for index: int in pedestals.size():
		var row: Variant = pedestals[index]
		if not row is Dictionary or row.get("biome") != order[index] or not _position_valid(row.get("at")):
			return false
	return _position_valid(config.get("home_arrival")) and _position_valid(config.get("shrine_entry"))


static func _position_valid(raw: Variant) -> bool:
	if not raw is Array or raw.size() != 3:
		return false
	for component: Variant in raw:
		if not (component is int or component is float) or not is_finite(float(component)):
			return false
	return true


func _build_arch(entry: Dictionary) -> void:
	var slot := Node3D.new()
	slot.name = "Arch_" + str(entry.id)
	slot.position = _position(entry.at)
	slot.rotation.y = deg_to_rad(float(entry.get("yaw_deg", 0)))
	slot.set_meta("biome", str(entry.biome))
	slot.add_to_group("crossing_hall_arches")
	add_child(slot)
	var frame := _add_model(slot, ARCH_MODEL)
	var depth: Dictionary = _config.get("arch_frame_depth", {})
	var args := OS.get_cmdline_user_args()
	if frame != null and not args.has("--hall-arch-depth-baseline") and \
			(bool(depth.get("enabled", false)) or args.has("--hall-arch-depth-candidate")):
		var factor := float(depth.get("factor", 1.0))
		if not is_finite(factor) or factor < 1.0 or factor > 6.0:
			push_error("Crossing Hall arch depth factor must be finite and within 1..6")
		else:
			# The installed frame is only64mm deep. Grow its existing depth;
			# width/height, portal surface, signs and approach marker stay fixed.
			frame.scale.z *= factor
			frame.set_meta("hall_arch_depth_factor", factor)
	var board := _label(slot, ORDER.display_name(str(entry.biome)), Vector3(0, 3.55, 0))
	board.name = "BiomeSign"
	var state := _label(slot, "Home arch" if entry.kind == "home" else "Sealed" if entry.kind == "sealed" else "Locked", Vector3(0, 2.95, .12))
	state.name = "StateSign"
	state.visible = state.text != board.text
	var arrival := Marker3D.new()
	arrival.name = "Approach"
	arrival.position = Vector3(0, .05, 2.8)
	slot.add_child(arrival)
	var membrane := MeshInstance3D.new()
	membrane.name = "PortalSurface"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.45, 2.4)
	membrane.mesh = mesh
	membrane.position = Vector3(0, 1.28, -.08)
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = .75
	membrane.material_override = material
	slot.add_child(membrane)
	_build_arch_surface_depth(slot, membrane)
	_arches[str(entry.id)] = slot


func _build_arch_surface_depth(slot: Node3D, baseline: MeshInstance3D) -> void:
	var cfg: Dictionary = _config.get("arch_surface_depth", {})
	var args := OS.get_cmdline_user_args()
	if args.has("--hall-surface-depth-baseline") or not (
			bool(cfg.get("enabled", false)) or args.has("--hall-surface-depth-candidate")):
		return
	var speed := float(cfg.get("flow_speed", 0.12))
	var depth := float(cfg.get("depth_strength", 0.5))
	if not is_finite(speed) or speed < 0.0 or speed > 1.0 \
			or not is_finite(depth) or depth < 0.0 or depth > 1.0:
		push_error("Hall portal depth requires finite speed/depth within0..1")
		return
	var candidate := MeshInstance3D.new()
	candidate.name = "PortalDepthSurface"
	candidate.mesh = baseline.mesh
	candidate.transform = baseline.transform
	var material := ShaderMaterial.new()
	material.shader = PORTAL_DEPTH
	material.set_shader_parameter("flow_speed", speed)
	material.set_shader_parameter("depth_strength", depth)
	candidate.material_override = material
	slot.add_child(candidate)
	baseline.hide()


func _refresh_arch_surface_depth(arch: Node3D) -> void:
	var surface := arch.get_node_or_null(^"PortalDepthSurface") as MeshInstance3D
	if surface == null:
		return
	var material := surface.material_override as ShaderMaterial
	var original := (arch.get_node(^"PortalSurface") as MeshInstance3D).material_override as StandardMaterial3D
	var state := str(arch.get_meta("arch_state", "sealed"))
	material.set_shader_parameter("state_mode", float(["sealed", "locked", "open", "stirred"].find(state)))
	material.set_shader_parameter("portal_tint", original.albedo_color)
	material.set_shader_parameter("radiance", original.emission_energy_multiplier if original.emission_enabled else 0.0)


func _build_pedestal(entry: Dictionary) -> void:
	var slot := Node3D.new()
	slot.name = "Pedestal_" + str(entry.biome)
	slot.position = _position(entry.at)
	slot.rotation.y = deg_to_rad(float(entry.get("yaw_deg", 0)))
	slot.set_meta("biome", str(entry.biome))
	slot.add_to_group("crossing_hall_pedestals")
	add_child(slot)
	_add_model(slot, STAND_MODEL)
	_build_meadows_relic_visual(slot, str(entry.biome))
	_build_cloudreach_relic_visual(slot, str(entry.biome))
	_build_stormwood_relic_visual(slot, str(entry.biome))
	# Measured installed BookStand bounds, authored in config so physics and
	# presentation share one native-scale footprint rather than a solid room.
	var collider: Dictionary = _config.get("pedestal_collider", {})
	var body := StaticBody3D.new()
	body.name = "PedestalBody"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = _position(collider.get("size", [.51, 1.44, .51]))
	shape.shape = box
	shape.position = _position(collider.get("at", [0, .72, 0]))
	body.add_child(shape)
	slot.add_child(body)
	# Free-standing: readable from every side of the stand, never mirrored.
	var label_at := _position(_config.get("pedestal_label_at", [0, 1.35, .15]))
	_label(slot, ORDER.display_name(str(entry.biome)), label_at).billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	var arrival := Marker3D.new()
	arrival.name = "Approach"
	arrival.position = Vector3(0, .05, 1.8)
	slot.add_child(arrival)
	_pedestals[str(entry.biome)] = slot
	var prompt := preload("res://scripts/world/interactable.gd").new()
	# Reserved biomes display as "Sealed"; "Hang your Sealed relic" named a
	# state as if it were an item (F17#6 r3 judge). They say why they are empty.
	var live := (ORDER.config().get("live", []) as Array).has(ORDER.canonical_id(str(entry.biome)))
	var offer := "Hang relic: %s" % ORDER.display_name(str(entry.biome)) if live else "Sealed shrine: no road reaches its relic yet"
	prompt.configure(offer, float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.interaction_radius_m), true)
	prompt.connect("activated", func() -> void: hang_relic(str(entry.biome)))
	slot.add_child(prompt)


func _build_meadows_relic_visual(slot: Node3D, biome: String) -> void:
	var cfg: Dictionary = _config.get("meadows_relic_visual", {})
	var args := OS.get_cmdline_user_args()
	if biome != "meadows" or args.has("--hall-relic-display-baseline") or \
			not (bool(cfg.get("enabled", false)) or args.has("--hall-relic-display-candidate")):
		return
	# Reuse the Meadows reward's established silhouette; this node never owns
	# a relic or submits a hang. Its visibility follows the host display only.
	var mount := Node3D.new()
	mount.name = "MeadowsRelicDisplay"
	mount.position = _position(cfg.get("at", [-.0131231, 1.34151, .02178]))
	mount.rotation.x = deg_to_rad(float(cfg.get("pitch_deg", -41.035)))
	mount.visible = false
	slot.add_child(mount)
	preload("res://scripts/world/trainer_aftermath.gd")._build_heart(mount, Vector3.ZERO, float(cfg.get("scale", .85)))


func _build_cloudreach_relic_visual(slot: Node3D, biome: String) -> void:
	var cfg: Dictionary = _config.get("cloudreach_relic_visual", {})
	var args := OS.get_cmdline_user_args()
	if biome != "cloudreach" or args.has("--hall-cloudreach-relic-baseline") or \
			not (bool(cfg.get("enabled", false)) or args.has("--hall-cloudreach-relic-candidate")):
		return
	var shrine := preload("res://scripts/world/realm_heart_shrine.gd")
	var material := StandardMaterial3D.new()
	material.albedo_color = shrine.HEART_READY
	material.roughness = .82
	material.emission_enabled = true
	material.emission = shrine.HEART_READY
	material.emission_energy_multiplier = 1.15
	var mount := Node3D.new()
	mount.name = "CloudreachRelicDisplay"
	mount.position = _position(cfg.get("at", [-.0131231, 1.34151, .02178]))
	mount.rotation.x = deg_to_rad(float(cfg.get("pitch_deg", -41.035)))
	mount.scale = Vector3.ONE * float(cfg.get("scale", .48))
	mount.visible = false
	slot.add_child(mount)
	shrine.build_cloudreach_relic(mount, material)


func _build_stormwood_relic_visual(slot: Node3D, biome: String) -> void:
	var cfg: Dictionary = _config.get("stormwood_relic_visual", {})
	var args := OS.get_cmdline_user_args()
	if biome != "stormwood" or args.has("--hall-stormwood-relic-baseline") or \
			not (bool(cfg.get("enabled", false)) or args.has("--hall-stormwood-relic-candidate")):
		return
	var shrine := preload("res://scripts/world/realm_heart_shrine.gd")
	var material := StandardMaterial3D.new()
	material.albedo_color = shrine.HEART_READY
	material.roughness = .82
	material.emission_enabled = true
	material.emission = shrine.HEART_READY
	material.emission_energy_multiplier = 1.15
	var mount := Node3D.new()
	mount.name = "StormwoodRelicDisplay"
	mount.position = _position(cfg.get("at", [-.0131231, 1.34151, .02178]))
	mount.rotation.x = deg_to_rad(float(cfg.get("pitch_deg", -41.035)))
	mount.scale = Vector3.ONE * float(cfg.get("scale", .44))
	mount.visible = false
	slot.add_child(mount)
	shrine.build_stormwood_relic(mount, material)


func _add_model(parent: Node3D, path: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Crossing Hall installed model missing: " + path)
		return null
	var model := packed.instantiate() as Node3D
	if model == null:
		push_error("Crossing Hall installed model is not spatial: " + path)
		return null
	parent.add_child(model)
	return model


func _label(parent: Node3D, text: String, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 32
	label.pixel_size = .006
	label.modulate = Color("f2e6cb")
	label.outline_modulate = Color("332c27")
	label.no_depth_test = false
	label.double_sided = false # Seen from behind it read mirrored ("sffilC...", F17#6 r4).
	parent.add_child(label)
	return label


func _add_light(at: Vector3, yaw_deg: float = 0.0) -> void:
	var lantern := Node3D.new()
	lantern.position = at
	lantern.rotation.y = deg_to_rad(yaw_deg)
	add_child(lantern)
	_add_model(lantern, LANTERN_MODEL)
	var settings: Dictionary = _config.get("light", {})
	# A visible flame, so the lantern reads as the light's source.
	var flame_material := StandardMaterial3D.new()
	flame_material.albedo_color = Color(str(settings.get("colour", "#ffd7a4")))
	flame_material.emission_enabled = true
	flame_material.emission = flame_material.albedo_color
	flame_material.emission_energy_multiplier = float(settings.get("flame_energy", 1.5))
	var flame := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = float(settings.get("flame_radius_m", .07))
	sphere.height = sphere.radius * 2
	flame.mesh = sphere
	flame.material_override = flame_material
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.position = _position(settings.get("flame_at", [0, .15, .12]))
	lantern.add_child(flame)
	var light := OmniLight3D.new()
	light.position = lantern.transform * flame.position # In the cage, not at the wall foot.
	light.light_color = Color(str(settings.get("colour", "#ffd7a4")))
	light.light_energy = float(settings.get("energy", 1.15))
	light.omni_range = float(settings.get("range_m", 8.5))
	light.shadow_enabled = false
	add_child(light)


## The frontage and tower carry the same retint as the shell recipe
## (building_prefabs.json crossing_hall_shell.retint): colour multiply, optional
## albedo swap, optional glow. One copy per source material.
func _retint(root: Node, retint: Dictionary) -> void:
	if retint.is_empty():
		return
	var made: Dictionary = {}
	for raw: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh.mesh == null:
			continue
		for index in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(index) as StandardMaterial3D
			if material == null or not retint.has(material.resource_name):
				continue
			if not made.has(material):
				var spec: Dictionary = retint[material.resource_name]
				var copy := material.duplicate() as StandardMaterial3D
				copy.albedo_color = Color(str(spec.get("color", "#ffffff")))
				if spec.has("texture"):
					copy.albedo_texture = load(str(spec.texture)) as Texture2D
				if spec.has("emission"):
					copy.emission_enabled = true
					copy.emission = Color(str(spec.emission))
					copy.emission_energy_multiplier = float(spec.get("energy", .85))
				made[material] = copy
			mesh.set_surface_override_material(index, made[material])


## The installed roof tiles are single-sided, so from the nave they were
## culled and the sky showed between the rafters, and sun or moonlight fell
## straight onto the floor. The Hall's own shell (its building's modules and
## the frontage/tower) casts double-sided shadows and its roof tiles render
## both faces. Materials are duplicated per surface: the kit's materials are
## shared with every other house.
func _close_shell() -> void:
	var building := get_parent() as Node3D
	if building == null:
		return
	for raw: Node in building.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh.mesh == null or mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue
		var roof := false
		var walk: Node = mesh
		while walk != null and walk != building:
			if str(walk.name).begins_with("Roof_"):
				roof = true
				break
			walk = walk.get_parent()
		if not roof and not _is_shell_module(mesh, building):
			continue
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		if not roof:
			continue
		for index in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(index) as BaseMaterial3D
			if material == null or material.cull_mode == BaseMaterial3D.CULL_DISABLED:
				continue
			var both := material.duplicate() as BaseMaterial3D
			both.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.set_surface_override_material(index, both)


func _is_shell_module(mesh: Node, building: Node) -> bool:
	var walk: Node = mesh
	while walk != null and walk != building:
		var name := str(walk.name)
		if name.begins_with("Wall_") or name.begins_with("Corner_") or name.begins_with("Floor_"):
			return true
		walk = walk.get_parent()
	return false


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < float(_config.get("refresh_seconds", .2)):
		return
	_elapsed = 0
	refresh_from_game()
	_refresh_interior_ambient()
	_refresh_home_membrane()


## The night sky ambient (art.json, energy ~2.3 to keep the outdoors readable)
## also lit the enclosed nave and Shrine Room flat blue, brighter than outside
## (F17#6 r1/r3 judges). The Warrens' interior ReflectionProbe ambient has no
## effect under the shipped Compatibility renderer (measured: probe active,
## frame unchanged), so the Hall uses material ambient occlusion instead: each
## Hall surface material (duplicated; the kit's are shared) carries a uniform
## AO map that scales AMBIENT light only (ao_light_affect 0), leaving the
## lanterns' direct light alone. It is enabled only while WorldLook is dark,
## because the Hall's walls are one shell seen from both sides: by day the
## exterior keeps the ordinary sky ambient.
var _night_materials: Array[BaseMaterial3D] = []
var _night_ambient_on := false


func _build_interior_ambient() -> void:
	var cfg: Dictionary = _config.get("interior_ambient", {})
	var building := get_parent() as Node3D
	if cfg.is_empty() or building == null:
		return
	var image := Image.create(4, 4, false, Image.FORMAT_L8)
	image.fill(Color.from_hsv(0, 0, clampf(float(cfg.get("night_ambient", .25)), 0.0, 1.0)))
	var occlusion := ImageTexture.create_from_image(image)
	var seen: Dictionary = {}
	for raw: Node in building.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh.mesh == null:
			continue
		if mesh.material_override is BaseMaterial3D:
			mesh.material_override = _night_material(mesh.material_override as BaseMaterial3D, occlusion, seen)
			continue
		for index in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(index) as BaseMaterial3D
			if material != null:
				mesh.set_surface_override_material(index, _night_material(material, occlusion, seen))
	_refresh_interior_ambient()


## One night copy per source material, so a material shared by many Hall
## modules stays one material here too. A material that already carries its
## own AO map is left alone.
func _night_material(source: BaseMaterial3D, occlusion: Texture2D, seen: Dictionary) -> BaseMaterial3D:
	if source.ao_enabled or source.ao_texture != null:
		return source
	if seen.has(source):
		return seen[source]
	var copy := source.duplicate() as BaseMaterial3D
	copy.ao_texture = occlusion
	copy.ao_light_affect = 0.0
	copy.ao_enabled = false
	seen[source] = copy
	_night_materials.append(copy)
	return copy


func _refresh_interior_ambient() -> void:
	if _night_materials.is_empty():
		return
	var tree := get_tree()
	var look: Node = tree.current_scene.get_node_or_null(^"WorldLook") if tree != null and tree.current_scene != null else null
	var dark := look != null and look.has_method("is_dark") and bool(look.call("is_dark"))
	if dark == _night_ambient_on:
		return
	_night_ambient_on = dark
	for material: BaseMaterial3D in _night_materials:
		material.ao_enabled = dark


## Coordinator ruling (F17#6 r4): at night the home arch's open membrane, seen
## straight through the entrance, read as a flat cream card in the doorway.
## While WorldLook is dark its emission is scaled by
## `home_membrane_night_emission_scale`. Presentation only: arch state,
## emission_enabled and portal logic are unchanged.
func _refresh_home_membrane() -> void:
	var arch: Node3D = _arches.get("home")
	if arch == null or str(arch.get_meta("arch_state", "")) != "open":
		return
	var surface := arch.get_node_or_null("PortalSurface") as MeshInstance3D
	var material := surface.material_override as StandardMaterial3D if surface != null else null
	if material == null:
		return
	var tree := get_tree()
	var look: Node = tree.current_scene.get_node_or_null(^"WorldLook") if tree != null and tree.current_scene != null else null
	var dark := look != null and look.has_method("is_dark") and bool(look.call("is_dark"))
	var scale := float(_config.get("home_membrane_night_emission_scale", 1.0)) if dark else 1.0
	material.emission_energy_multiplier = OPEN_MEMBRANE_EMISSION * scale
	var night_tint := Color(str(_config.get("home_membrane_night_tint", "#ffffff")))
	material.albedo_color = Color(str((_config.get("arch_materials", {}) as Dictionary).get("open", "#303947"))) * (night_tint if dark else Color.WHITE)
	material.emission = material.albedo_color
	_refresh_arch_surface_depth(arch)


func refresh_from_game() -> void:
	var game := get_node_or_null("/root/Game")
	var session: Node = game.get("session") if game != null else null
	_mount_portal_actions(session)
	var world: RefCounted = game.get("world") if game != null else null
	var display: Dictionary = world.get("redesign_world") if world != null else {}
	if display == _last_display:
		return
	_last_display = display.duplicate(true)
	apply_display(display)


## Mount the existing input adapter at each actual authored slot only after
## Session's unchanged runtime gate admits it. Late Session readiness retries
## here independently of whether the shared display has changed.
func _mount_portal_actions(session: Node) -> void:
	if not is_instance_valid(session) or not session.has_method("portal_runtime_ready") \
		or session.call("portal_runtime_ready") != true: return
	for id: String in _arches:
		var slot: Node3D = _arches[id]
		if not is_instance_valid(slot) or slot.get_parent() != self or slot.is_queued_for_deletion(): continue
		# Retain the original input component; never adopt or duplicate a
		# foreign child occupying this owned presentation name.
		if slot.get_node_or_null(^"PortalAction") != null: continue
		var action: Node3D = PORTAL_ACTION.new()
		action.name = "PortalAction"
		if not action.call("setup", id):
			action.free()
			continue
		slot.add_child(action)


func apply_display(display: Dictionary) -> void:
	var unlocked: Array = display.get("portal_unlocks", [])
	var shrine: Dictionary = display.get("shrine_display", {})
	var colors: Dictionary = _config.get("arch_materials", {})
	for id: String in _arches:
		var arch: Node3D = _arches[id]
		var state := "open" if id == "home" or unlocked.has(id) else "locked"
		if ORDER.ids(false).find(id) < 0 and id != "home":
			state = "stirred" if id == "biome5" and bool(display.get("fifth_arch_stirred", false)) else "sealed"
		arch.set_meta("arch_state", state)
		var material := (arch.get_node("PortalSurface") as MeshInstance3D).material_override as StandardMaterial3D
		material.albedo_color = Color(str(colors.get(state, "#303947")))
		material.emission_enabled = state == "open" or state == "stirred"
		material.emission = material.albedo_color
		material.emission_energy_multiplier = OPEN_MEMBRANE_EMISSION if state == "open" else .1
		_refresh_arch_surface_depth(arch)
		var state_sign := arch.get_node("StateSign") as Label3D
		state_sign.text = "Home arch" if id == "home" else state.capitalize()
		state_sign.visible = state_sign.text != (arch.get_node("BiomeSign") as Label3D).text
	_refresh_home_membrane()
	for id: String in _pedestals:
		var pedestal: Node3D = _pedestals[id]
		var displayed := bool(shrine.get(id, false))
		pedestal.set_meta("relic_displayed", displayed)
		var relic := pedestal.get_node_or_null(^"MeadowsRelicDisplay") as Node3D
		if relic != null:
			relic.visible = displayed
		var cloudreach_relic := pedestal.get_node_or_null(^"CloudreachRelicDisplay") as Node3D
		if cloudreach_relic != null:
			cloudreach_relic.visible = displayed
		var stormwood_relic := pedestal.get_node_or_null(^"StormwoodRelicDisplay") as Node3D
		if stormwood_relic != null:
			stormwood_relic.visible = displayed


func home_arrival() -> Vector3:
	return to_global(_position(_config.home_arrival))


func arch(id: String) -> Node3D:
	return _arches.get(id) as Node3D


func shrine_entry() -> Vector3:
	return to_global(_position(_config.shrine_entry))


func layout_signature() -> String:
	return JSON.stringify(_config).sha256_text()


func display_snapshot() -> Dictionary:
	return _last_display.duplicate(true)


static func _position(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


## Road-facing public facade, in the same native-scale installed village kit.
## It writes no world/personal state and adds no collision or ground footprint.
func _build_frontage() -> void:
	var settings: Dictionary = _config.get("frontage", {})
	if settings.is_empty():
		return
	var frontage := Node3D.new()
	frontage.name = "RoadFacingFrontage"
	add_child(frontage)
	for row: Dictionary in settings.get("modules", []):
		var holder := Node3D.new()
		holder.position = _position(row.at)
		holder.rotation.y = deg_to_rad(float(row.get("yaw_deg", 0)))
		frontage.add_child(holder)
		_add_model(holder, "res://assets/buildings/quaternius_medieval/" + str(row.module) + ".gltf")
	_retint(frontage, settings.get("retint", {}))
	var sign_settings: Dictionary = settings.get("sign", {})
	var sign := _label(frontage, str(sign_settings.get("text", "Crossing Hall")), _position(sign_settings.at))
	sign.name = "HallDestinationSign"
	sign.rotation.y = deg_to_rad(float(sign_settings.get("yaw_deg", 180)))
	sign.font_size = int(sign_settings.get("font_size", 48))
	sign.pixel_size = float(sign_settings.get("pixel_size", .008))
	sign.modulate = Color(str(sign_settings.get("colour", "#ead8ab")))
	var light_settings: Dictionary = settings.get("light", {})
	for row: Dictionary in settings.get("lanterns", []):
		var fixture := Node3D.new()
		fixture.position = _position(row.at)
		fixture.rotation.y = deg_to_rad(float(row.get("yaw_deg", 180)))
		frontage.add_child(fixture)
		_add_model(fixture, LANTERN_MODEL)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(str(light_settings.get("colour", "#ffd09b")))
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = float(light_settings.get("glow_energy", .5))
		var glow := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = float(light_settings.get("glow_radius_m", .065))
		sphere.height = sphere.radius * 2
		glow.mesh = sphere
		glow.material_override = material
		glow.position = _position(light_settings.get("glow_at", [0, .15, .12]))
		fixture.add_child(glow)
		var light := OmniLight3D.new()
		light.position = glow.position
		light.light_color = material.albedo_color
		light.light_energy = float(light_settings.get("energy", 1.7))
		light.omni_range = float(light_settings.get("range_m", 7.5))
		light.shadow_enabled = false
		fixture.add_child(light)
	# F17#6 r3 judge: at night the doorway read as a blank emissive plane (the
	# home arch membrane seen straight through it) and no light reached the
	# ground at the door. A low warm pool on the threshold and one in the
	# vestibule light the step and the arch reveal so the doorway has depth.
	for row: Dictionary in settings.get("door_pools", []):
		var pool := OmniLight3D.new()
		pool.name = str(row.get("name", "HallDoorPool"))
		pool.position = _position(row.at)
		pool.light_color = Color(str(row.get("colour", light_settings.get("colour", "#ffd09b"))))
		pool.light_energy = float(row.get("energy", 1.0))
		pool.omni_range = float(row.get("range_m", 4.0))
		pool.omni_attenuation = float(row.get("attenuation", 1.0))
		pool.shadow_enabled = false
		frontage.add_child(pool)


## Shrine relic hang through Session.request_relic_hang (host authority).
## F18 found an ordinary guest press did nothing: a guest's
## homestead_personal_view() is only a cache, so the request carried a stale
## or -1 character revision that the host refused as
## source_or_revision_changed, and that refusal came back on
## homestead_action_completed with nobody listening. A guest now refreshes the
## view first and waits for it (craft_panel.gd's pattern), and the host's
## saved decision is surfaced when it arrives.
const RELIC_VIEW_TIMEOUT_S := 3.0
const RELIC_REPLY_TIMEOUT_S := 10.0
var _relic_pending := ""
var _relic_game: Node


func hang_relic(biome: String, game: Node = null) -> void:
	if game == null:
		game = get_node_or_null(^"/root/Game")
	var session: Node = game.get("session") if game != null else null
	if session == null or not _relic_pending.is_empty():
		return
	if session.has_method("portal_runtime_ready") and session.call("portal_runtime_ready") != true:
		game.call("push_world_message", "The shrines are still asleep; they wake with the Hall's arches.")
		return
	# UX §shrine: with no relic to hang here, a pedestal opens the relic power
	# screen once any relic is hung (F31#2's one chosen power).
	if not _personal_list(game, "relics_held").has(biome) and not _personal_list(game, "relics_hung").is_empty():
		open_relic_power(game)
		return
	_relic_pending = biome
	_relic_game = game
	if not bool(session.call("is_host")):
		if not await _relic_view_refreshed(session):
			_relic_pending = ""
			game.call("push_world_message", "The shrine is waiting for the host. Try again.")
			return
		if not session.is_connected("homestead_action_completed", _relic_reply):
			session.connect("homestead_action_completed", _relic_reply)
	var verdict: Dictionary = session.call("request_relic_hang", biome)
	if verdict.get("code") == "awaiting_saved_decision":
		# Guest: the host's saved decision arrives on homestead_action_completed.
		# A reply that never comes must not lock the shrine for later presses.
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		await tree.create_timer(RELIC_REPLY_TIMEOUT_S).timeout
		if _relic_pending == biome:
			_relic_pending = ""
			if session.is_connected("homestead_action_completed", _relic_reply):
				session.disconnect("homestead_action_completed", _relic_reply)
		return
	_relic_pending = ""
	if verdict.get("ok") != true:
		game.call("push_world_message", _relic_refusal_text(verdict))
	else:
		open_relic_power(game, "Relic hung. Choose the power you carry.")


func _relic_view_refreshed(session: Node) -> bool:
	var state := {"done": false}
	var mark := func() -> void: state.done = true
	# Connect before asking, so a reply in the same frame is not missed.
	session.connect("homestead_personal_view_completed", mark, CONNECT_ONE_SHOT)
	session.call("homestead_personal_view")
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		if session.is_connected("homestead_personal_view_completed", mark):
			session.disconnect("homestead_personal_view_completed", mark)
		return state.done
	var timer := tree.create_timer(RELIC_VIEW_TIMEOUT_S)
	while not state.done and timer.time_left > 0.0:
		await tree.process_frame
	if session.is_connected("homestead_personal_view_completed", mark):
		session.disconnect("homestead_personal_view_completed", mark)
	return state.done


func _relic_reply(op: String, intent: Dictionary, result: Dictionary) -> void:
	if op != "relic_hang" or str(intent.get("biome", "")) != _relic_pending:
		return
	if not preload("res://scripts/ui/relic_power_panel.gd").reply_final(result):
		return # A guest's first reply is the host's checkpoint; the saved decision follows.
	_relic_pending = ""
	var game := _relic_game if is_instance_valid(_relic_game) else get_node_or_null(^"/root/Game")
	var session: Node = game.get("session") if game != null else null
	if session != null and session.is_connected("homestead_action_completed", _relic_reply):
		session.disconnect("homestead_action_completed", _relic_reply)
	if result.get("ok") != true and game != null:
		game.call("push_world_message", _relic_refusal_text(result))
	elif game != null:
		open_relic_power(game, "Relic hung. Choose the power you carry.")


static func _personal_list(game: Node, field: String) -> Array:
	var local: Variant = game.get("local") if game != null else null
	var personal: Variant = (local as Object).get("redesign_character") if local is Object else null
	return (personal as Dictionary).get(field, []) if personal is Dictionary else []


var _power_panel: CanvasLayer


func open_relic_power(game: Node, message: String = "") -> void:
	if not is_inside_tree():
		return
	if _power_panel == null or not is_instance_valid(_power_panel):
		_power_panel = RELIC_POWER_PANEL.new()
		_power_panel.name = "RelicPowerPanel"
		add_child(_power_panel)
	_power_panel.call("open", message)


static func _relic_refusal_text(verdict: Dictionary) -> String:
	match str(verdict.get("code", "")):
		"personal_relic_required": return "You have no relic for this shrine yet."
		"actual_shrine_pedestal_required", "source_or_revision_changed": return "Stand at the shrine and try again."
	return str(verdict.get("reason", verdict.get("code", "The relic is waiting for its saved transaction.")))


## F17#6 r4 judge: the cyan objective beam showed inside the Hall, in the
## creature's face and through the nave roof (the shell has no roof
## collider to test against). The Hall declares its interior boxes (local
## space, crossing_hall.json `interior_volumes`); objective_beacon.gd stands
## the beam down while the camera is inside any declared interior.
func _declare_interior_volumes() -> void:
	var boxes: Array[AABB] = []
	for row: Variant in _config.get("interior_volumes", []):
		if row is Dictionary and (row.get("min", []) as Array).size() == 3 and (row.get("max", []) as Array).size() == 3:
			var low := _position(row.min)
			boxes.append(AABB(low, _position(row.max) - low))
	if boxes.is_empty():
		return
	set_meta(OBJECTIVE_BEACON.INTERIOR_BOXES_META, boxes)
	add_to_group(OBJECTIVE_BEACON.INTERIOR_GROUP)
	if bool(_config.get("rain_shelter_enabled", false)):
		set_meta(WEATHER_PRESENTATION.RAIN_SHELTER_BOXES_META, boxes.duplicate())
		add_to_group(WEATHER_PRESENTATION.RAIN_SHELTER_GROUP)

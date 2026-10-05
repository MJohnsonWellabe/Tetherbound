extends RefCounted

## PERF (F26#5, 2026-10-05). Shadowed local lights stop casting shadows past
## a short camera distance.
##
## An omni light's shadow is a cube map: every caster in its range is drawn
## again for each face. Measured at the Meadows F26 stands, 11-13 shadowed
## interior room lights (cottages, inn, workshop, Grandpa's house) sat in the
## camera frustum from the street and the Crossing Hall nave. GrandpaHouse
## alone cost 2,446 draw calls from 236 surfaces at the nave, about 110 m
## away. TECHNICAL §10's budget is at most four overlapping shadowed omni/spot
## lights outdoors, normally none.
##
## A 6-9 m room light's shadow is detail for someone in or beside the room.
## Past `shadow_begin_m` it fades out over `length_m`. An exterior light keeps
## shining until `light_begin_m`, so lantern glow still reads across the
## village at night. An enclosed light (an ancestor named in
## `enclosed_ancestor_contains`) is untouched out to `enclosed_light_begin_m`
## and then fades out whole, light before shadow: without its shadow it would
## leak through its own walls, which two code-blind judge rounds caught as
## warm light on cottage exteriors when the shadow went first. Lights that already author their own distance fade
## are left alone. Only lights with shadows enabled are touched.

const PERF_CONFIG := preload("res://scripts/world/performance_config.gd")


static func watch(world: Node) -> void:
	if world == null or not world.is_inside_tree():
		return
	var cfg := _config()
	if not bool(cfg.get("enabled", false)):
		return
	for node: Node in world.find_children("*", "Light3D", true, false):
		apply(node as Light3D, cfg)
	var tree := world.get_tree()
	var handler := Callable(_on_node_added)
	if not tree.node_added.is_connected(handler):
		tree.node_added.connect(handler)


static func _on_node_added(node: Node) -> void:
	if node is OmniLight3D or node is SpotLight3D:
		# Builders often set shadow_enabled after add_child; look next frame.
		# Deferred by id: the node may be freed before then.
		_apply_deferred.call_deferred(node.get_instance_id())


static func _apply_deferred(id: int) -> void:
	var light := instance_from_id(id) as Light3D
	if light != null:
		apply(light, _config())


static func apply(light: Light3D, cfg: Dictionary) -> void:
	if light == null or not (light is OmniLight3D or light is SpotLight3D):
		return
	if not light.shadow_enabled or light.distance_fade_enabled or not bool(cfg.get("enabled", false)):
		return
	light.distance_fade_enabled = true
	light.distance_fade_length = float(cfg.get("length_m", 8.0))
	if _enclosed(light, cfg):
		# A room light without its shadow would shine through its own walls,
		# so it keeps both as authored and then fades out whole, finishing
		# before its shadow is allowed to drop. No leak band at any distance.
		var begin := float(cfg.get("enclosed_light_begin_m", 72.0))
		light.distance_fade_begin = begin
		light.distance_fade_shadow = begin + light.distance_fade_length
	else:
		light.distance_fade_begin = float(cfg.get("light_begin_m", 160.0))
		light.distance_fade_shadow = float(cfg.get("shadow_begin_m", 18.0))


static func _enclosed(light: Light3D, cfg: Dictionary) -> bool:
	var needles: Variant = cfg.get("enclosed_ancestor_contains", [])
	if not needles is Array:
		return false
	var at: Node = light.get_parent()
	while at != null:
		var name := str(at.name)
		for needle: Variant in needles:
			if name.contains(str(needle)):
				return true
		at = at.get_parent()
	return false


static func _config() -> Dictionary:
	var cfg: Variant = PERF_CONFIG.config().get("local_light_shadow_fade", {})
	return cfg if cfg is Dictionary else {}

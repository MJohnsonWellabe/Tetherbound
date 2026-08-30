extends Node3D

## PICKUP-GLOW. One highlight treatment for every pickup in the world.
##
## OWNER PLAYTEST, 2026-08-30, OP-0830-3: *"all items in the grass like tms,
## potions, orbs whatever should glow so they're visible."*
##
## The word that matters in that sentence is **whatever**. The repo already had
## five separate one-time-pickup props -- `key_pickup.gd`, `tm_pickup.gd`,
## `item_cache_pickup.gd`, `harvest_node.gd`, `death_satchel.gd` -- each with
## its own idea of how to be noticed (the key: four blind rounds of shape,
## metallic and emission work; the TM: a plinth, a spin and an `OmniLight3D`;
## the cache: a different `OmniLight3D`; the harvest node: nothing at all). Five
## treatments is why the answer to "does it glow" depended on which object you
## were standing in front of. This is the shared one, and every pickup path
## registers with it.
##
## ## What it draws
##
## Two things per pickup, and both are needed:
##
##   * a **halo** on the object itself, camera-facing and distance-compensated,
##     pushed BEHIND the prop along the view axis so the prop's own opaque
##     geometry occludes the middle of it -- the item is drawn whole and the glow
##     escapes around its silhouette;
##   * a **ground aura** lying flat at the object's foot, which is what bleeds
##     into the base of the grass and says the find is on the ground here.
##
## Two owner directives on 2026-08-30 shaped both. *"Glow on the actual item, not
## floating in the air above it"* killed an earlier version that hung the mark
## above the grass canopy; *"don't make it take over the items actual geometry or
## design. just add the glow to them"* is why the halo is pushed behind the prop
## rather than drawn over it. See `prop_glow_height()` and the shader's `behind`
## uniform.
##
## ## Why one node and not a child of each pickup
##
## Perf, and it is not a marginal call. The world holds well over a hundred
## pickups (114 harvest nodes across the five bands, five TMs, the caches, the
## key, and however many death satchels the player has left behind). A glow
## built as two `MeshInstance3D` children each would be 250+ transparent draws;
## two `OmniLight3D`s each -- which is what the TM and cache props were already
## doing -- is worse still under an OPEN ROG performance defect (OP-0830-6) and
## is ruled out by name in this lane's order.
##
## So every pickup in the world shares **two MultiMeshes and two draw calls**,
## and `shaders/pickup_glow.gdshader` collapses an out-of-band instance to zero
## size in the vertex shader so distance costs no fill either. Per-pickup colour
## rides on the instance colour; per-pickup pulse phase on its custom data.
##
## ## Registering
##
##     PICKUP_GLOW.attach(self, Color("#c9a227"))      # in _build_visual()
##     PICKUP_GLOW.detach(self)                        # in _deactivate()
##
## `attach` is keyed on the node, so calling it twice re-places one instance
## rather than stacking two, and a freed pickup is swept even if it never got to
## call `detach`.

const CONFIG_PATH := "res://data/config/pickup_glow.json"
const SHADER_PATH := "res://shaders/pickup_glow.gdshader"
const FIELD_NAME := "PickupGlowField"

static var _config: Dictionary = {}

var _entries: Array[Dictionary] = []
var _motes: MultiMeshInstance3D = null
var _auras: MultiMeshInstance3D = null
var _dirty: bool = false


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("pickup_glow.json missing at %s" % CONFIG_PATH)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		# LOUD, because silence here cost a render round. A malformed config
		# used to fall through to `{}`, every `get(key, default)` below then
		# quietly returned the code default, and the world rendered a glow at
		# the pre-tuning size and brightness -- so the capture looked exactly
		# like the BEFORE frame and the obvious conclusion ("the shader is not
		# drawing") was wrong. A config this file cannot read is a bug in the
		# config, and it should say so rather than pretending it was never
		# edited.
		push_error("pickup_glow.json is malformed at line %d: %s -- the highlight is running on code defaults" % [
			json.get_error_line(), json.get_error_message()])
		return _config
	if json.data is Dictionary:
		_config = json.data
	return _config


static func is_enabled() -> bool:
	return bool(config().get("enabled", true))


## Give `owner_node` the shared highlight. `colour` is the object's own tint --
## the key's gold, a TM's type colour, a berry bush's fruit -- so the glow says
## something about what is there rather than painting the whole world one
## colour. `height_override` places the halo by hand on a prop whose measurable
## crown is not where its body reads (the TM's plinth-and-orb assembly);
## everything else is measured by `prop_glow_height()`.
static func attach(
	owner_node: Node3D, colour: Color, height_override: float = -1.0,
	scale_multiplier: float = 1.0
) -> void:
	if owner_node == null or not is_enabled():
		return
	var field := _field_for(owner_node)
	if field == null:
		return
	field.call("_register", owner_node, colour, height_override, scale_multiplier)


static func detach(owner_node: Node3D) -> void:
	if owner_node == null:
		return
	var field := _field_for(owner_node, false)
	if field == null:
		return
	field.call("_unregister", owner_node)


## The field lives once per world, found by name under whatever node the pickups
## were placed beneath. `current_scene` is the ordinary answer; the walk-up
## fallback is for the capture tools and smoke tests, which add the world scene
## to `root` by hand and leave `current_scene` null.
static func _field_for(near: Node3D, create: bool = true) -> Node3D:
	var tree := near.get_tree()
	if tree == null:
		return null
	var host: Node = tree.current_scene
	if host == null:
		host = near
		while host.get_parent() != null and host.get_parent() != tree.root:
			host = host.get_parent()
	var existing := host.get_node_or_null(NodePath(FIELD_NAME))
	if existing != null:
		return existing as Node3D
	if not create:
		return null
	var field: Node3D = (load("res://scripts/world/pickup_glow.gd") as GDScript).new()
	field.name = FIELD_NAME
	host.add_child(field)
	return field


func _ready() -> void:
	var cfg := config()
	var shader: Shader = load(SHADER_PATH) as Shader
	if shader == null:
		push_warning("pickup_glow: %s did not load; pickups will not be highlighted" % SHADER_PATH)
		return
	_motes = _build_layer(shader, cfg.get("mote", {}), true)
	_auras = _build_layer(shader, cfg.get("aura", {}), false)
	set_process(true)


func _build_layer(shader: Shader, look: Dictionary, billboard: bool) -> MultiMeshInstance3D:
	var quad := QuadMesh.new()
	# 2x2, so its corners sit at +/-1 and the `radius` the config authors is a
	# RADIUS. At the default 1x1 the corners are at +/-0.5, so every authored
	# radius silently rendered at half size -- which is most of why an early
	# tuning round kept concluding "the glow is too faint" and reaching for
	# `strength` when the real answer was that the quad was half the size the
	# config said.
	quad.size = Vector2(2.0, 2.0)

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("billboard", 1.0 if billboard else 0.0)
	# Explicit, because the config blocks also carry numbers the shader has no
	# uniform for (`radius`, `height`, `body_fraction`, `max_height` are all
	# consumed on the CPU side in `_rebuild`), and a silently-ignored parameter
	# name is the kind of thing that costs a render round to notice.
	var shared: Dictionary = config().get("distance", {})
	for key: String in [
		"reference_distance", "screen_min_scale", "screen_max_scale",
		"far_fade_start", "far_fade_end", "near_fade_start", "near_fade_end",
		"near_floor",
	]:
		if shared.has(key):
			material.set_shader_parameter(key, float(shared[key]))
	for key: String in [
		"core_power", "core_inner", "rim_gain", "strength", "behind",
		"pulse_hz", "pulse_depth",
	]:
		if look.has(key):
			material.set_shader_parameter(key, float(look[key]))

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	multimesh.instance_count = 0

	var instance := MultiMeshInstance3D.new()
	instance.name = "Motes" if billboard else "Auras"
	instance.multimesh = multimesh
	instance.material_override = material
	# Transparent, additive and unsorted against each other on purpose: additive
	# blending is order-independent, which is the reason this can be one
	# MultiMesh at all.
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _register(
	owner_node: Node3D, colour: Color, height_override: float, scale_multiplier: float
) -> void:
	var tint := glow_tint(colour)
	for entry: Dictionary in _entries:
		if entry.get("node") == owner_node:
			entry["colour"] = tint
			entry["height"] = height_override
			entry["scale"] = scale_multiplier
			_dirty = true
			return
	_entries.append({
		"node": owner_node,
		"colour": tint,
		"height": height_override,
		"scale": scale_multiplier,
		"phase": randf(),
	})
	_dirty = true


## The object's own colour, made into something that can actually glow.
##
## The tint comes from `data/items/items.json`, which is authoring an object's
## ALBEDO -- `wood` is #7a5a35, `stone` is #8e8d86. Those are correct for a
## surface and useless for an additive light: a dark brown added to a frame is
## almost nothing, so a deadwood pile would have been given a highlight that
## does not highlight while a berry bush blazed, purely because of what the
## items happen to be made of.
##
## So the HUE is the object's (a fiber node still reads green, a key still reads
## gold) and the BRIGHTNESS is this system's. Saturation is capped rather than
## floored: a genuinely grey item stays a warm neutral instead of being assigned
## an arbitrary hue by `Color.from_hsv` off a hue channel that means nothing at
## zero saturation.
static func glow_tint(colour: Color) -> Color:
	var cfg: Dictionary = config().get("tint", {})
	var out := Color.from_hsv(
		colour.h,
		minf(colour.s, float(cfg.get("saturation_max", 0.55))),
		float(cfg.get("value", 0.95)))
	out.a = 1.0
	return out


## Where on the prop the glow sits.
##
## OWNER DIRECTIVE, 2026-08-30: **"glow on the actual item, not floating in the
## air above it."**
##
## The first version put the mote a fixed 1.15m up, above the grass canopy, on
## the reasoning that brightness cannot beat opaque geometry but clearance can.
## The reasoning about grass is still true and the answer was still wrong: a
## light hanging in the air over an object is a waypoint marker, not an object
## that glows, and it is the exact loot-beam register this treatment is supposed
## to avoid.
##
## So the glow is centred **on the prop's own body** -- the middle of its
## measured crown, so a 20cm TM orb glows at 12cm and a two-metre deadwood pile
## glows through its middle rather than over its head.
##
## Grass is then beaten by RADIUS instead of altitude. The glow is a soft disc
## roughly as wide as `mote.radius`, so a mark centred at 0.12m still reaches
## well above the 0.86m canopy `grass_field.json`'s own numbers produce -- but it
## reaches up out of the object, which is what makes it read as the object
## glowing rather than as something hovering near it.
## `tests/test_pickup_glow.gd` asserts that reach against the grass config
## directly, so the ground lane raising blade height still fails loudly.
static func prop_glow_height(node: Node3D, floor_height: float) -> float:
	var top := 0.0
	for child: Node in node.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		if visual == null or not visual.visible:
			continue
		var aabb := visual.get_aabb()
		# Composed up the parent chain rather than through `global_transform`:
		# a pickup's `_build_visual()` runs BEFORE the prop is in the tree in
		# some paths, and `global_transform` on a detached node is an engine
		# error and an identity matrix -- which would silently report every
		# prop as flat.
		var local := Transform3D.IDENTITY
		var walk: Node3D = visual
		while walk != null and walk != node:
			local = walk.transform * local
			walk = walk.get_parent() as Node3D
		for corner in 8:
			top = maxf(top, (local * aabb.get_endpoint(corner)).y)
	var cfg: Dictionary = config().get("mote", {})
	if top <= 0.0:
		return floor_height
	var ceiling := float(cfg.get("max_height", 1.4))
	return clampf(top * float(cfg.get("body_fraction", 0.55)), floor_height, ceiling)


func _unregister(owner_node: Node3D) -> void:
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i].get("node") == owner_node:
			_entries.remove_at(i)
			_dirty = true


## Rebuilt rather than incrementally patched: pickups are placed at world build
## and removed when taken, so this runs a handful of times in a session and the
## cost of a rebuild is a few hundred `set_instance_transform` calls.
##
## A pickup that is invisible (a harvest node between respawns, a prop a band
## has streamed out) keeps its entry and gets a zero-scale instance, so the
## glow tracks what the player can actually see without the pickup scripts
## having to know this class exists beyond attach/detach.
func _process(_delta: float) -> void:
	if not _dirty and not _any_visibility_changed():
		return
	_dirty = false
	_rebuild()


func _any_visibility_changed() -> bool:
	for entry: Dictionary in _entries:
		var node: Node3D = entry.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			return true
		if bool(entry.get("shown", true)) != node.is_visible_in_tree():
			return true
	return false


func _rebuild() -> void:
	for i in range(_entries.size() - 1, -1, -1):
		var node: Node3D = _entries[i].get("node") as Node3D
		if node == null or not is_instance_valid(node):
			_entries.remove_at(i)
	if _motes == null or _auras == null:
		return

	var cfg := config()
	var mote_look: Dictionary = cfg.get("mote", {})
	var aura_look: Dictionary = cfg.get("aura", {})
	var mote_height := float(mote_look.get("height", 1.15))
	var mote_radius := float(mote_look.get("radius", 0.42))
	var aura_height := float(aura_look.get("height", 0.06))
	var aura_radius := float(aura_look.get("radius", 0.85))

	var count := _entries.size()
	_motes.multimesh.instance_count = count
	_auras.multimesh.instance_count = count
	for i in count:
		var entry: Dictionary = _entries[i]
		var node: Node3D = entry["node"] as Node3D
		var shown := node.is_visible_in_tree()
		entry["shown"] = shown
		var at := node.global_position
		var scale_multiplier := float(entry.get("scale", 1.0))
		var height := float(entry.get("height", -1.0))
		if height < 0.0:
			height = prop_glow_height(node, mote_height)

		var colour: Color = entry["colour"]
		colour.a = 1.0 if shown else 0.0
		# .x is the pulse phase; .y is half the prop's own crown, which the
		# shader uses to push the halo just far enough behind THIS object for
		# the object to occlude its middle. See the `behind` push in
		# `shaders/pickup_glow.gdshader`.
		var custom := Color(
			float(entry.get("phase", 0.0)),
			minf(height, float(mote_look.get("max_height", 1.3))),
			0.0, 0.0)

		var mote := Transform3D(
			Basis.IDENTITY.scaled(Vector3.ONE * (mote_radius * scale_multiplier)),
			at + Vector3.UP * height)
		_motes.multimesh.set_instance_transform(i, mote)
		_motes.multimesh.set_instance_color(i, colour)
		_motes.multimesh.set_instance_custom_data(i, custom)

		# Laid flat. A QuadMesh faces +Z, so the aura is the same quad rotated
		# onto the ground plane, lifted a few centimetres so the terrain's own
		# depth does not eat it on a slope.
		var aura_basis := Basis(Vector3.RIGHT, -PI * 0.5).scaled(
			Vector3.ONE * (aura_radius * scale_multiplier))
		var aura := Transform3D(aura_basis, at + Vector3.UP * aura_height)
		_auras.multimesh.set_instance_transform(i, aura)
		_auras.multimesh.set_instance_color(i, colour)
		_auras.multimesh.set_instance_custom_data(i, custom)


## Read-only, for the regression that asserts every pickup path registered.
func highlight_count() -> int:
	return _entries.size()


func highlight_positions() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for entry: Dictionary in _entries:
		var node: Node3D = entry.get("node") as Node3D
		if node != null and is_instance_valid(node):
			out.append(node.global_position)
	return out

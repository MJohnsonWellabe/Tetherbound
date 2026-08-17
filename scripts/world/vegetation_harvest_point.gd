extends Node3D

## R2.3: a gather point bolted onto one of `vegetation.gd`'s OWN scattered
## trees or rocks, instead of one of `harvest_node.gd`'s ~10 authored tutorial
## props. The tree/rock itself is the MultiMesh instance already rendered by
## `vegetation.gd` — this only adds a small marker so the owner's reported
## "gathering seems to randomly pop up" (nothing distinguishes a harvestable
## prop from a decorative one until the prompt appears at close range) has an
## answer at a real approach distance.
##
## The marker is a small standalone glint, not a tint on the tree/rock's own
## material. A per-instance MultiMesh colour multiply was tried first (the
## same mechanism R7.1-remainder uses for grass jitter) and reached two
## independent blind critics reading it as "diseased/scorched foliage... a
## texture-atlas glitch" rather than a marker, on both a red-dominant and a
## gold-balanced attempt — the leaf mesh's own baked per-vertex shading
## variation survives any multiply, so the failure was structural, not a
## colour-tuning miss. A small unshaded sphere sidesteps it entirely: it
## reads as UI-adjacent (a resource glint, the genre's own convention) rather
## than as part of the tree.
##
## R2.3-remainder: the plain sphere shipped but a fresh blind critic called it
## "a flat, unshaded, arbitrarily-positioned sticker... reads as a debug/
## placeholder, not a designed interact-here affordance" — no gradient, no
## glow falloff. The glint is now a small bright core wrapped in a soft
## radial-gradient halo (a billboard quad sampling a procedural
## GradientTexture2D, additive-blended so it actually falls off to nothing
## rather than hard-cutting at a mesh edge) plus a handful of slow-drifting
## GPUParticles3D motes — the two untried levers this item's own remainder
## named ("real light falloff or a GPUParticles3D sparkle rather than a flat
## unshaded mesh"). No new asset files: the gradient and the particle's
## colour ramp are both built procedurally in code.
##
## OW7: the glint was still the ONLY thing at a wood point, and the owner
## played it and said so — "wood to pick up doesn't look like wood, it's just
## random yellow glowing spots." Rendering the frame shows exactly that: two
## gold blobs hanging in open air over grass. Every round above tuned how the
## MARKER looked, and none of them noticed that a "wood" point is bolted onto
## one of the scatter's own LIVING trees, so there was no wood-shaped object
## anywhere for the marker to mark. No amount of gradient fixes that. A pile of
## cut logs now stands at the point and the glint sits on top of it, so the
## thing a player recognises is the resource and the glow only says which one.
##
## HARVEST-ALL/D60, owner directive: "once it's chopped it should disappear
## and not regrow." This used to be a prompt-and-glint cooldown rather than a
## hide/show — a living tree vanishing read as a bug where a pile vanishing
## reads as "spent, come back later". That reasoning no longer applies: every
## tree and stone in the meadow is now harvestable, so what actually
## disappears is the WHOLE placement (the tree/rock's own render instance and
## collider, via `vegetation.gd::harvest_permanently`) alongside this node —
## not a dim-and-wait marker on a tree that stays standing. See that
## function's own header for the removal mechanism and D60 for why
## permanent, unbounded removal is the owner's explicit call.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")

## Warm gold, unshaded and emissive so it reads the same at any time of day
## and against any material behind it -- a rock's own grey or a tree's own
## green. One colour for every resource rather than per-item, so "glinting"
## itself is the convention a player learns, not a colour per material.
## TUNABLE.
const GLINT_COLOUR := Color(1.0, 0.78, 0.25, 1.0)
const GLINT_RADIUS := 0.11
const HALO_TEXTURE_SIZE := 64
const SPARKLE_COUNT := 5
const SPARKLE_ORBIT_RADIUS := 0.22

## OW7. The halo was 0.85m across with the core's own emission on top of it,
## and it was the ONLY thing at a gather point — so a frame of the meadow
## showed two gold blobs hanging over grass and nothing else, which is the
## owner's report word for word: "just random yellow glowing spots." It is
## smaller now because it no longer has to be the whole affordance. The pile
## below says what the resource is; the glint only has to say "this one".
const HALO_SIZE := 0.55

## OW7. The woodpile: three Kenney logs, already in the build and already
## ledgered for their log shapes (`water.gd` stands the same mesh on end for
## the jetty's pilings), so this adds no asset and joins no new family (D24).
##
## `log.glb` measures 0.234 x 0.173 x 0.710m and sits on its own y=0, lying
## along local Z. Two on the ground and one in the groove between them is the
## universally readable firewood stack, and at ~0.35m tall it is knee-high
## next to a 4-7m tree — present without competing with it.
const LOG_MODEL := "res://assets/environment/nature/log.glb"
const LOG_LENGTH := 0.710
const LOG_RISE := 0.173

## The pack's logs ship untextured, as a pale cream on both surfaces — the
## same flat near-white that made `water.gd`'s pilings read as concrete posts
## until it tinted them. Bark and cut face are separate surfaces here, so they
## get separate colours rather than one override over both: the pale END
## GRAIN against dark bark is the cue that says sawn wood rather than branch
## litter, and it is the whole reason this reads as a resource. TUNABLE.
const BARK_COLOUR := Color("#5d452e")
const CUT_COLOUR := Color("#c2a172")

var _item_id: String = ""
var _amount: int = 0
var _prompt: Node3D = null
var _glint: Node3D = null
var _prop: Node3D = null
## HARVEST-ALL. Which placement this node belongs to, so `_on_gathered()` can
## tell `vegetation.gd::harvest_permanently()` exactly which render instance
## and collider to remove. "" / -1 (the defaults) for a caller that predates
## HARVEST-ALL or a standalone test — `_on_gathered()` falls back to freeing
## just this node in that case, see its own comment.
var _harvest_layer: String = ""
var _harvest_index: int = -1


func setup(spec: Dictionary) -> void:
	_item_id = str(spec.get("item", "wood"))
	_amount = int(spec.get("amount", 2))
	_harvest_layer = str(spec.get("harvest_layer", ""))
	_harvest_index = int(spec.get("harvest_index", -1))
	var prompt_height := float(spec.get("prompt_height", 1.4))

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * prompt_height
	_prompt.call("configure", str(spec.get("label", "Gather")), 2.6, true)
	_prompt.connect("activated", _on_gathered)
	add_child(_prompt)

	# Offset out to one side rather than straight up from the base -- a real
	# tree/rock's own trunk or bulk sits exactly on this node's local origin,
	# so anything placed directly above it renders INSIDE that geometry from
	# most angles instead of beside it. `vegetation.gd` hashes the placement's
	# own world position for the bearing and samples the ground at the far end
	# of it, so the offset arrives here already standing on the terrain.
	var bearing := float(spec.get("prop_yaw", 0.0))
	var offset: Vector3 = spec.get("prop_offset", Vector3.ZERO)
	if offset == Vector3.ZERO:
		# No offset supplied (a caller that predates OW7, or a test): fall back
		# to the bearing alone at the old height, which is at least beside the
		# trunk rather than inside it.
		bearing = float(hash(position) & 0xFFFFFF) / float(0xFFFFFF) * TAU
		offset = Vector3(sin(bearing) * 1.3, prompt_height * 0.75, cos(bearing) * 1.3)

	# OW7. A resource prop, where there is one for this item. Wood was the
	# item with nothing to look at: a "wood" gather point is bolted onto one of
	# the scatter's own LIVING trees, so before this there was no wood-shaped
	# object anywhere near it and the glint was marking a spot rather than a
	# thing. Stone already has its object -- the point is on the rock itself --
	# so it keeps the marker it had.
	_prop = _build_resource_prop(bearing)
	if _prop != null:
		_prop.position = offset
		add_child(_prop)

	_glint = Node3D.new()
	_glint.name = "Glint"
	_glint.add_child(_build_core())
	_glint.add_child(_build_halo())
	_glint.add_child(_build_sparkles())
	# Sit the glint just clear of the pile's own crown, so the glow and the
	# thing it marks read as one object rather than as a light near some logs.
	_glint.position = offset + Vector3.UP * (LOG_RISE * 2.0 + 0.24) if _prop != null else offset
	add_child(_glint)


## The pile of cut logs a "wood" gather point stands on, or null for an item
## whose own object is already there.
##
## Built from the PackedScene the glTF actually imports as, never assigned
## straight to a `mesh` property: that is the OF20 trap, where every authored
## harvest node silently rendered nothing for weeks because a PackedScene
## assigned to a Mesh-typed property fails without raising anything.
func _build_resource_prop(bearing: float) -> Node3D:
	if _item_id != "wood":
		return null
	if not ResourceLoader.exists(LOG_MODEL):
		push_warning("log model %s missing; the wood point keeps its glint alone" % LOG_MODEL)
		return null
	var packed: PackedScene = load(LOG_MODEL) as PackedScene
	if packed == null:
		push_warning("log model %s did not load as a PackedScene; the wood point keeps its glint alone" % LOG_MODEL)
		return null

	var pile := Node3D.new()
	pile.name = "Woodpile"
	# Two logs on the ground either side of the centreline, one resting in the
	# groove between them. The small yaw offsets stop the stack reading as a
	# manufactured object -- these are logs somebody dropped, not a woodshed.
	for spec: Array in [
		[Vector3(-0.14, 0.0, 0.0), 0.0],
		[Vector3(0.15, 0.0, 0.03), 0.06],
		[Vector3(0.005, LOG_RISE, -0.02), -0.11],
	]:
		var log_node := packed.instantiate() as Node3D
		if log_node == null:
			continue
		log_node.transform = Transform3D(
			Basis(Vector3.UP, bearing + float(spec[1])),
			(spec[0] as Vector3).rotated(Vector3.UP, bearing)
		)
		_paint_wood(log_node)
		pile.add_child(log_node)
	# A woodpile's own shadow is what sets it on the ground rather than over
	# it -- the same rule vegetation.gd applies to its solid layers, and the
	# opposite of the one it applies to grass.
	for child: Node in _mesh_nodes(pile):
		(child as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return pile


## Bark on one surface, sawn end grain on the other, per surface rather than
## with a `material_override` -- an override replaces the material on EVERY
## surface at once, which would flatten the cut faces back into the bark and
## throw away the only cue that says this wood was worked.
func _paint_wood(root: Node) -> void:
	for node: Node in _mesh_nodes(root):
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var material := StandardMaterial3D.new()
			var source := mesh.surface_get_material(surface) as StandardMaterial3D
			# The pack marks bark and cut face only by albedo, and the bark is
			# the darker of the two. Reading the source rather than assuming an
			# index keeps this correct if the kit reorders its surfaces.
			var is_cut := source != null and source.albedo_color.get_luminance() > 0.9
			material.albedo_color = CUT_COLOUR if is_cut else BARK_COLOUR
			material.roughness = 0.92
			material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			instance.set_surface_override_material(surface, material)


func _mesh_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			out.append(node)
		for child in node.get_children():
			stack.append(child)
	return out


## A tight billboard gradient, same soft-falloff language as the halo but
## smaller and held opaque closer to its centre -- a bright pinpoint, not a
## faceted 3D shape. Round 1's blind critic called the old geometric
## SphereMesh core "blocky, hard-edged rectangles... an unantialiased sprite"
## up close: at GLINT_RADIUS (0.11m) and 12 segments/6 rings, its polygon
## facets were resolving as visible edges rather than a smooth ball under
## software rendering. A billboard has no silhouette geometry to facet.
func _build_core() -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(GLINT_RADIUS * 2.4, GLINT_RADIUS * 2.4)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = GLINT_COLOUR
	material.albedo_texture = _build_radial_gradient_texture(0.35)
	material.emission_enabled = true
	material.emission = GLINT_COLOUR
	material.emission_energy_multiplier = 2.2

	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## A billboard quad sampling a procedural radial gradient, additive-blended so
## it fades smoothly to nothing instead of hard-cutting at a mesh silhouette --
## the "no gradient, no glow falloff" half of the remainder's own critique.
func _build_halo() -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(HALO_SIZE, HALO_SIZE)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = GLINT_COLOUR
	material.albedo_texture = _build_radial_gradient_texture(0.0)
	material.emission_enabled = true
	material.emission = GLINT_COLOUR
	material.emission_energy_multiplier = 0.9

	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## `inner_hold`: fraction of the radius (from centre) that stays fully opaque
## before the fade to transparent begins -- 0.0 is a pure linear falloff from
## the very centre (the halo's soft glow), a higher value gives a solid,
## faceted-free bright core before it too fades at the edge.
func _build_radial_gradient_texture(inner_hold: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	if inner_hold > 0.0:
		gradient.offsets = PackedFloat32Array([0.0, inner_hold, 1.0])
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.0),
		])
	else:
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.0),
		])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = HALO_TEXTURE_SIZE
	texture.height = HALO_TEXTURE_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


## A handful of slow, orbiting motes -- the "GPUParticles3D sparkle" lever the
## remainder named as the other untried option. Continuous (not one-shot) so
## it reads as a standing convention, not a burst effect for a specific event.
func _build_sparkles() -> Node3D:
	var particles := GPUParticles3D.new()
	particles.amount = SPARKLE_COUNT
	particles.lifetime = 2.2
	particles.preprocess = 2.2
	particles.randomness = 0.5
	particles.local_coords = false

	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = SPARKLE_ORBIT_RADIUS
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 100.0
	process_material.gravity = Vector3(0.0, 0.06, 0.0)
	process_material.initial_velocity_min = 0.03
	process_material.initial_velocity_max = 0.09
	process_material.scale_min = 0.5
	process_material.scale_max = 1.0

	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	ramp.colors = PackedColorArray([
		Color(GLINT_COLOUR.r, GLINT_COLOUR.g, GLINT_COLOUR.b, 0.0),
		Color(GLINT_COLOUR.r, GLINT_COLOUR.g, GLINT_COLOUR.b, 1.0),
		Color(GLINT_COLOUR.r, GLINT_COLOUR.g, GLINT_COLOUR.b, 1.0),
		Color(GLINT_COLOUR.r, GLINT_COLOUR.g, GLINT_COLOUR.b, 0.0),
	])
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	process_material.color_ramp = ramp_texture
	particles.process_material = process_material

	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = GLINT_COLOUR
	# Round 2's blind critic named this specifically: an untextured quad with
	# a flat colour IS a hard-edged square, not a soft mote -- the same
	# gradient texture the halo/core use gives each spark real falloff
	# instead of a visible geometric edge.
	material.albedo_texture = _build_radial_gradient_texture(0.0)
	material.emission_enabled = true
	material.emission = GLINT_COLOUR
	material.emission_energy_multiplier = 2.0
	quad.material = material
	particles.draw_pass_1 = quad
	particles.emitting = true

	var node := Node3D.new()
	node.add_child(particles)
	return node


func _on_gathered() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; gathered %s into nothing" % _item_id)
		return
	var inventory: RefCounted = game.get("inventory")
	var items: RefCounted = game.get("items")
	if items == null or inventory == null:
		return
	var gathered: Dictionary = HARVEST_LOGIC.gather(_item_id, _amount, inventory, items)
	var actual_amount: int = int(gathered["amount"])
	if actual_amount <= 0:
		# The wrong tool for this resource: refused, and the tree stays put for
		# whenever the player comes back with the right one.
		return
	if not bool(inventory.call("has_room_for", _item_id, actual_amount)):
		# Refused, visibly: the prompt keeps offering, the honest version of
		# "your satchel is full".
		return
	inventory.call("add", _item_id, actual_amount)
	var required_slot: int = int(gathered["required_slot"])
	if required_slot >= 0:
		inventory.call("damage_tool", required_slot)

	# HARVEST-ALL/D60: chopped stays chopped. The tree/rock's own render
	# instance and collider go with it (vegetation.gd::harvest_permanently),
	# not just this marker -- there is no respawn any more. The parent IS
	# the Vegetation node (vegetation.gd::_spawn_harvest_point add_child()s
	# this directly), so no separate reference has to be threaded in.
	var vegetation := get_parent()
	if vegetation != null and vegetation.has_method("harvest_permanently") and not _harvest_layer.is_empty():
		vegetation.call("harvest_permanently", _harvest_layer, _harvest_index)
	else:
		# A standalone test, or a caller that predates HARVEST-ALL: nothing
		# to tell the world about, so just remove this node's own marker.
		queue_free()


func _ready() -> void:
	# So a tool swing can find this without knowing which of the two gather
	# scripts drew it (`harvest_logic.gd::GROUP`).
	add_to_group(HARVEST_LOGIC.GROUP)

## Gather this spot, the same as pressing the interact prompt on it.
##
## Public so a tool swing (`scripts/player/tool_hold.gd`) can drive the exact
## same path the prompt drives -- one gather implementation, two ways to reach
## it, so a swing and a press can never disagree about yield, tool gating,
## durability or respawn.
func gather() -> void:
	_on_gathered()


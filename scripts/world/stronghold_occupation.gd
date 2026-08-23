extends Node3D

## GATE-E-STRONGHOLD-ART (2026-08-23) — Team Tether's occupation of the castle
## on the ridge, as visible dressing.
##
## ## Why this exists
##
## Two independent blind critics, reading the same `shots/wayfinding` frames,
## described the endgame landmark in almost the same words: an untextured
## toy-scale blockout, bannerless, unlit-looking, with no Team Tether presence
## on it at all — against `docs/reference/tetherbound-meadows-keyart.png`,
## whose fortress is a sprawling, plainly OCCUPIED complex. Three separate
## things produce that reading and only one of them is stone colour:
##
##   1. the albedo, which is `building_prefabs.json`'s `castle` retint and is
##      fixed there, in the one place every module already reads from;
##   2. the light, which is this file — see below, it is the real defect;
##   3. the absence of anything human-sized anywhere near the walls, which is
##      also this file, and is most of why a 36x40m fortress with a 29m keep
##      reads as a toy in the first place.
##
## ## The light is the actual bug, and it is not a bug in a material
##
## `data/config/art.json` authors the sun at pitch -44, yaw -40 — the north
## sky. `landmark.gd` puts the ramp, the gate and the whole approach on the
## SOUTH side, because that is where the road and the Legendary Chamber are.
## So the hero face of the endgame landmark is backlit at every hour the
## chapter is ever played, and everything the player looks at on the way in is
## lit by ambient fill alone. Measured on `main` with `tools/frame_stats.py`:
## near-field luma 0.012 on `gate-close`, 0.053 on `silhouette-approach`,
## against the 0.49–0.60 `art.json`'s own comments quote from the project's
## reference frames. Ten to forty times under. No albedo survives that; a
## surface lit by nothing renders as nothing.
##
## Turning the sun around is not this lane's to do (it is one global value
## every biome, every frame and every combat readability decision in the game
## is tuned against, and it lives in the environment config another lane
## owns). The honest fix is the one the fiction was already asking for: a
## fortress held by an army, facing away from the sun, is lit by its garrison.
## So the gate has fire in it, the parapet has fire on it, and the machinery
## bolted to the stone glows in Team Tether's reserved teal.
##
## ## What is reused rather than made
##
## Nothing here is generated and no asset is new. The flames are
## `torch_prop.gd`'s existing stick-and-billboard-flame geometry, scaled up
## and stood in an iron basket built from two primitives (the kit ships no
## brazier; `torch_prop.gd`'s own header records that nothing in `assets/**`
## ships a brand or lantern either, and CLAUDE.md forbids generating one
## without owner reference art). The camp is `assets/props/generated_camp`'s
## tent/firewood/stone-ring, `kenney_survival`'s bedroll and
## `quaternius_fantasy`'s crates, barrels and rope — every one of them already
## installed and already placed elsewhere in the Meadows by `props.gd`. The
## banners are the castle kit's own `Banner.obj`, added as ordinary modules in
## `building_prefabs.json` where the two that already existed live.
##
## The flicker formula is the same two-summed-sines recipe
## `campfire_glow.gd`, `scripts/player/torch.gd` and `build_piece.gd` each
## carry — copied, as they copied it from each other, because it is four lines
## and none of them is a library.
##
## ## Reserved colours
##
## `palette.json` reserves `tether_teal` (#3fe8c4) for Team Tether machinery
## that is LIVE and `tether_oxblood` for Team Tether alone. Every teal light
## in `stronghold_occupation.json` is on hardware; every warm light is fire;
## the two never mix, and nothing neutral in this file is either colour.
##
## ## What this file does NOT own
##
## No collider, no interaction, no spawn, no progression flag, no navigation.
## It is presentation hung off `landmark.gd` after the castle is standing, and
## the five-space route inside `stronghold.gd` — which is a different building
## entirely, sited south of this one — is untouched by it. `plinth: true`
## entries sit on the courtyard slab that already has `landmark.gd`'s own
## `PlinthBody` under it, so nothing here can drop a prop through the floor or
## put one in the ramp's 6m width.

const CONFIG_PATH := "res://data/config/stronghold_occupation.json"
const TORCH_PROP := preload("res://scripts/world/torch_prop.gd")
const CAMPFIRE_GLOW := preload("res://scripts/world/campfire_glow.gd")
const PROPS_DIR := "res://assets/props/quaternius_fantasy"

## palette.json, `accent`. Read as constants rather than loaded, the same way
## every other consumer of the two reserved colours in this project does.
const TETHER_TEAL := Color("#3fe8c4")
const FIRE_COLOUR := Color(1.0, 0.55, 0.16)

## The iron the baskets are made of. Below the castle's darkest stone retint
## (`DarkRock` #6b5f52) so a basket reads as a black shape against the wall
## with a fire in it, rather than as another piece of masonry.
const IRON_COLOUR := Color("#2a2622")

## The local z the ramp meets the plinth at -- landmark.gd's own PLINTH_CENTRE.z
## minus PLINTH_HALF_Z, i.e. the plinth's south edge.
const RAMP_TOP_Z := -10.0

const FLICKER_AMOUNT := 0.26
const FLICKER_SPEED := 7.0

var _config: Dictionary = {}
var _lights: Array[OmniLight3D] = []
var _base_energy: Array[float] = []
var _time: float = 0.0
var _plinth_top: float = 4.2
var _ramp_run: float = 11.0


## `plinth_top` is landmark.gd's own PLINTH_TOP — the courtyard floor's local
## y, and the height every `plinth: true` entry is snapped to. `site_origin`
## is the landmark's own world position, passed in rather than read off the
## parent's transform so this builds identically whether or not the tree it is
## being assembled into is live yet. `world` is only needed for `ground: true`
## entries (the camp below the ramp), which sample the real terrain; passing
## null simply skips them, which is what a harness with no terrain wants.
##
## `ramp_run` is landmark.gd's RAMP_RUN, and with `plinth_top` it is enough to
## reconstruct the ramp's own slope for `ramp: true` placements — see
## `_ramp_y`. Both are passed rather than duplicated as constants here so a
## retune of the ramp cannot leave the fires standing in the air above it.
func build(world: Node, plinth_top: float, site_origin: Vector3,
		ramp_run: float = 11.0) -> void:
	name = "TetherOccupation"
	_config = _load_json(CONFIG_PATH)
	if _config.is_empty():
		push_warning("stronghold_occupation.json missing; the stronghold reads unheld")
		return
	_plinth_top = plinth_top
	_ramp_run = ramp_run
	_build_sky_fill()
	_build_braziers(world, site_origin)
	_build_tether_lamps()
	_build_camp(world, plinth_top, site_origin)
	set_process(not _lights.is_empty())


func _process(delta: float) -> void:
	_time += delta
	# Two summed sines rather than one, so the fire reads as fire and not as a
	# mechanical strobe. Each light is offset by its own index so a row of
	# braziers does not pulse in unison, which is the tell that gives away a
	# scripted flicker faster than the flicker itself does.
	for i in _lights.size():
		var light := _lights[i]
		if light == null or not is_instance_valid(light):
			continue
		var phase := _time * FLICKER_SPEED + float(i) * 1.7
		var wave := (sin(phase) + sin(phase * 0.37)) * 0.5
		light.light_energy = _base_energy[i] * (1.0 + FLICKER_AMOUNT * wave)


## --- sky ----------------------------------------------------------------------

## STRONGHOLD-R2. The cool half of the gate's light. See
## `stronghold_occupation.json`'s `_comment_sky_fill` for why this is here and
## not in `art.json`; the short version is that the Compatibility renderer
## gives a shadowed surface a colourless ambient constant, so the one thing a
## backlit face never receives is the sky's own blue, and round 1's fires left
## `gate-close` reading as two hue families with no blue in it at all.
##
## NOT tracked by `_track`: these are not fire and must not flicker. A
## flickering sky is worse than no sky.
const SKY_FILL_COLOUR := Color("#6f93c4")


func _build_sky_fill() -> void:
	var entries: Array = _config.get("sky_fill", []) as Array
	if entries.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "SkyFill"
	add_child(holder)
	var index := 0
	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var light := OmniLight3D.new()
		light.name = "SkyFill_%d" % index
		light.light_color = SKY_FILL_COLOUR
		light.light_energy = float(spec.get("energy", 0.7))
		light.omni_range = float(spec.get("range", 30.0))
		# Shadowless on purpose. A wide fill that casts shadows would draw a
		# second, contradictory set of shadow directions across the same wall
		# the sun already shadows, and it costs a shadow map per light on a
		# platform (ROG Ally) where the whole point of this being four omnis
		# rather than a second directional light is that it stays cheap.
		light.shadow_enabled = false
		light.position = _vec3(spec.get("at", [0.0, 0.0, 0.0]))
		holder.add_child(light)
		index += 1


## --- fire ---------------------------------------------------------------------

## An iron fire-basket with `torch_prop.gd`'s flame standing in it. The prop
## is 0.78m of stick and is authored to be CARRIED, so it is scaled up here
## and sunk into the basket rather than left standing on a wall like a
## dropped torch.
func _build_braziers(world: Node = null, site_origin: Vector3 = Vector3.ZERO) -> void:
	var holder := Node3D.new()
	holder.name = "Braziers"
	add_child(holder)
	var index := 0
	for entry: Variant in (_config.get("braziers", []) as Array):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var at := _vec3(spec.get("at", [0.0, 0.0, 0.0]))
		var scale_factor := float(spec.get("scale", 2.0))
		# `ground: true` ignores the authored y and sits the basket on the real
		# terrain, the same way a camp prop does -- ROUND 3 (this task) needed
		# it for the pair standing on the grass beside the ramp, which is what
		# finally puts light on the ramp itself rather than only on the wall
		# above it.
		if bool(spec.get("ground", false)):
			var y := _terrain_y(world, site_origin, at.x, at.z)
			if is_nan(y):
				continue
			at.y = y
		elif bool(spec.get("ramp", false)):
			at.y = _ramp_y(at.z)

		var brazier := Node3D.new()
		brazier.name = "Brazier_%d" % index
		brazier.position = at
		holder.add_child(brazier)

		_add_basket(brazier, scale_factor)

		# ROUND 2 (this task, after reading the round-1 frames): the flame is
		# taken from `torch_prop.gd` WITHOUT its stick. Round 1 kept the whole
		# prop, and a 0.78m handheld brand scaled 2.6x stands 2.8m of bare pole
		# out of a 1.1m bowl -- `gate-close` came back with a pair of black
		# mushrooms on sticks flanking the arch, which is not a brazier, it is
		# a torch somebody planted in a bucket. Freeing `Stick` leaves exactly
		# the parts a fire-basket wants (the two billboard flame quads and the
		# ember emitter) and lets the flame be seated on the bowl's own rim.
		var torch: Node3D = TORCH_PROP.new()
		var flame_scale := scale_factor * FLAME_SCALE
		torch.scale = Vector3.ONE * flame_scale
		var stick := torch.get_node_or_null(^"Stick")
		if stick != null:
			stick.queue_free()
		var flame_y := _bowl_rim(scale_factor) \
			- float(torch.call("flame_local_position").y) * flame_scale \
			+ FLAME_LIFT * scale_factor
		torch.position = Vector3(0.0, flame_y, 0.0)
		brazier.add_child(torch)

		var light := OmniLight3D.new()
		light.name = "Fire"
		light.light_color = FIRE_COLOUR
		light.omni_range = float(spec.get("range", 12.0))
		light.shadow_enabled = false
		light.position = Vector3(0.0, _bowl_rim(scale_factor) + FLAME_LIFT * scale_factor, 0.0)
		brazier.add_child(light)
		_track(light, float(spec.get("energy", 3.0)))
		index += 1


## The basket itself: a shallow bowl on a short post. Two primitives, because
## the castle kit ships no brazier and `torch_prop.gd`'s header already
## established that generating one is not available to this lane without owner
## reference art.
##
## The proportions are round 2's. Round 1's bowl was a deep, wide cone under a
## tall pole and read as a mushroom; this one is squatter than it is wide and
## sits low, so what stands out against the sky is the fire in it rather than
## the ironwork under it.
const POST_HEIGHT := 0.30
const BOWL_HEIGHT := 0.16
const BOWL_RADIUS := 0.26
## How far the flame's own centre floats above the bowl rim.
const FLAME_LIFT := 0.13
## The flame, relative to the basket. `torch_prop.gd`'s quads are sized for a
## brand held at arm's length (a 0.22m halo), so at the basket's own scale a
## factor below 1 makes the fire vanish -- round 2 used 0.62 and the frames
## came back with rows of empty black bowls. A basket of coals is WIDER than
## the pole a torch is, not narrower.
const FLAME_SCALE := 0.95


## The top of the bowl, in the brazier's own local space, at a given scale.
## One function so the mesh, the flame and the light cannot disagree about
## where the fire is.
func _bowl_rim(scale_factor: float) -> float:
	return (POST_HEIGHT + BOWL_HEIGHT) * scale_factor


func _add_basket(into: Node3D, scale_factor: float) -> void:
	var iron := StandardMaterial3D.new()
	iron.albedo_color = IRON_COLOUR
	iron.roughness = 0.8
	iron.metallic = 0.4

	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.05 * scale_factor
	post_mesh.bottom_radius = 0.10 * scale_factor
	post_mesh.height = POST_HEIGHT * scale_factor
	post_mesh.radial_segments = 8
	post_mesh.material = iron
	post.mesh = post_mesh
	post.position = Vector3(0.0, POST_HEIGHT * 0.5 * scale_factor, 0.0)
	into.add_child(post)

	var bowl := MeshInstance3D.new()
	bowl.name = "Bowl"
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = BOWL_RADIUS * scale_factor
	bowl_mesh.bottom_radius = BOWL_RADIUS * 0.55 * scale_factor
	bowl_mesh.height = BOWL_HEIGHT * scale_factor
	bowl_mesh.radial_segments = 10
	bowl_mesh.material = iron
	bowl.mesh = bowl_mesh
	bowl.position = Vector3(0.0, (POST_HEIGHT + BOWL_HEIGHT * 0.5) * scale_factor, 0.0)
	into.add_child(bowl)


## --- Team Tether hardware ------------------------------------------------------

## A work lamp: an emissive teal lens with a light behind it. The reserved
## colour, on machinery only — `palette.json`'s `_reserved_teal` is what makes
## a teal point at distance mean Team Tether and nothing else.
func _build_tether_lamps() -> void:
	var holder := Node3D.new()
	holder.name = "TetherLamps"
	add_child(holder)
	var index := 0
	for entry: Variant in (_config.get("tether_lamps", []) as Array):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var lamp := Node3D.new()
		lamp.name = "TetherLamp_%d" % index
		lamp.position = _vec3(spec.get("at", [0.0, 0.0, 0.0]))
		holder.add_child(lamp)

		var lens := MeshInstance3D.new()
		lens.name = "Lens"
		var sphere := SphereMesh.new()
		var radius := float(spec.get("lens", 0.3))
		sphere.radius = radius
		sphere.height = radius * 2.0
		var glass := StandardMaterial3D.new()
		glass.albedo_color = TETHER_TEAL
		glass.emission_enabled = true
		glass.emission = TETHER_TEAL
		# STRONGHOLD-R2: 2.4 -> 1.15. At 2.4 the lens clipped past white in
		# every frame it appears in, so the one object on this site whose whole
		# job is to be RECOGNISABLY TEAL rendered as a flat pale disc with a
		# dark ring round it -- a coin stuck on the tower, not a lamp, and not
		# the reserved colour either. Emission that blows out loses its hue
		# first; keeping it just under the clip is what makes the colour read.
		glass.emission_energy_multiplier = 1.15
		sphere.material = glass
		lens.mesh = sphere
		lamp.add_child(lens)

		# The housing, so a lamp reads as bolted to the stone rather than as a
		# glowing ball floating off the wall.
		var housing := MeshInstance3D.new()
		housing.name = "Housing"
		var can := CylinderMesh.new()
		can.top_radius = radius * 1.25
		can.bottom_radius = radius * 1.25
		can.height = radius * 0.9
		var iron := StandardMaterial3D.new()
		iron.albedo_color = IRON_COLOUR
		iron.roughness = 0.8
		iron.metallic = 0.4
		can.material = iron
		housing.mesh = can
		housing.rotation.x = PI * 0.5
		housing.position = Vector3(0.0, 0.0, radius * 0.8)
		lamp.add_child(housing)

		var light := OmniLight3D.new()
		light.name = "Glow"
		light.light_color = TETHER_TEAL
		light.omni_range = float(spec.get("range", 10.0))
		light.light_energy = float(spec.get("energy", 2.4))
		light.shadow_enabled = false
		lamp.add_child(light)
		index += 1


## --- the checkpoint camp -------------------------------------------------------

## The garrison's camp at the foot of the ramp, plus the working clutter on
## the courtyard slab. Every entry is either `ground: true` (sampled off the
## real terrain, for the grass below the plinth) or `plinth: true` (sat on the
## courtyard floor). Nothing is placed inside the ramp's own 6m width; see the
## config's own `_comment_camp`.
func _build_camp(world: Node, plinth_top: float, site_origin: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "Checkpoint"
	add_child(holder)
	for entry: Variant in (_config.get("camp", []) as Array):
		if not entry is Dictionary:
			continue
		_place(holder, entry, world, plinth_top, site_origin)


func _place(into: Node3D, spec: Dictionary, world: Node, plinth_top: float,
		site_origin: Vector3) -> void:
	var model := str(spec.get("model", ""))
	if model.is_empty():
		return
	var dir := str(spec.get("dir", PROPS_DIR))
	var node := _load_model(dir, model)
	if node == null:
		return
	node.name = model

	var at: Array = spec.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var y := 0.0
	if bool(spec.get("plinth", false)):
		y = plinth_top
	elif bool(spec.get("ground", false)):
		y = _terrain_y(world, site_origin, x, z)
		if is_nan(y):
			node.queue_free()
			return
	y += float(spec.get("lift", 0.0))

	node.position = Vector3(x, y, z)
	node.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	node.scale = Vector3.ONE * float(spec.get("scale", 1.0))
	into.add_child(node)

	var tint: String = str(spec.get("tint", ""))
	if not tint.is_empty():
		_tint(node, Color(tint))

	if bool(spec.get("fire", false)):
		_light_the_camp_fire(node)


## The one fire on the grass. `campfire_glow.gd` owns the flame, embers, light
## and smoke column and is already used by `props.gd` for every other camp in
## the Meadows -- reused whole rather than reimplemented, so this camp cannot
## drift away from how the rest of them look.
##
## With one subtraction. ROUND 2 (this task): the smoke column is dropped
## here. It is a stack of large, pale, alpha-blended discs, and this fire sits
## ~25m from the `silhouette-approach` camera at the bottom of a frame whose
## whole subject is a fortress -- round 1 came back with a translucent grey
## plume standing up the right third of the hero shot, which is the same
## reading ("a pale translucent rectangle in the sky") this task is elsewhere
## removing from the Band 4 horizons. A checkpoint brazier does not need a
## signal column; the camps that do keep theirs, since this only touches the
## instance built here.
##
## `campfire_glow.gd::_process` drives its own light energy off its own
## constant, so only the RANGE is worth setting from config -- overriding the
## energy here would be silently undone on the next frame.
func _light_the_camp_fire(ring: Node3D) -> void:
	var cfg: Dictionary = _config.get("camp_fire_light", {})
	var glow: Node3D = CAMPFIRE_GLOW.new()
	glow.name = "CampFire"
	ring.add_child(glow)
	for child in glow.get_children():
		if child is OmniLight3D:
			(child as OmniLight3D).omni_range = float(cfg.get("range", 12.0))
		elif child.name.begins_with("Smoke"):
			child.queue_free()


## The height of `landmark.gd`'s entry ramp at a local z. The ramp is a single
## rotated box running from the gate sill (the plinth's own south edge, local
## z -PLINTH_HALF_Z relative to its centre, which is z -10 at y `plinth_top`)
## down `ramp_run` metres to the grass, so its surface is a straight line
## between those two points and this is that line. Clamped at both ends so a
## number authored slightly off the ramp does not extrapolate into the sky.
##
## ROUND 5 (this task): `gate-close` is shot from ON this ramp looking up it,
## and after four rounds its lower two thirds was still the darkest thing in
## the frame -- a 6m-wide slab of stone that faces the sky but not the sun,
## with every fire in the file mounted at plinth height above it or standing
## on the grass off to one side, out of frame. Lights that sit ON the surface
## the camera is standing on are the only ones that reach it.
func _ramp_y(z: float) -> float:
	var foot := RAMP_TOP_Z - _ramp_run
	var t := clampf((z - foot) / maxf(_ramp_run, 0.01), 0.0, 1.0)
	return _plinth_top * t


## The terrain's height under a LOCAL (x, z), expressed back in this node's own
## local frame. `landmark.gd` sits AT the site's ground height, so a raw
## `ground_height_at` result has to have that origin subtracted out of it or
## every ground-snapped thing lands a full site-elevation above the grass it is
## meant to be standing on. Returns NAN when there is no terrain to ask.
func _terrain_y(world: Node, site_origin: Vector3, x: float, z: float) -> float:
	if world == null or not world.has_method("ground_height_at"):
		return NAN
	var ground := float(world.call("ground_height_at", site_origin.x + x, site_origin.z + z))
	if is_nan(ground):
		return NAN
	return ground - site_origin.y


## --- plumbing ------------------------------------------------------------------

func _load_model(dir: String, model: String) -> Node3D:
	# The same three-format fallback `props.gd::place` already walks: .gltf and
	# .glb arrive as scenes, .obj as a bare Mesh that has to be wrapped.
	for extension in [".gltf", ".glb"]:
		var path := "%s/%s%s" % [dir, model, extension]
		if not ResourceLoader.exists(path):
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			push_error("occupation prop failed to load: %s" % path)
			return null
		return packed.instantiate() as Node3D
	var obj_path := "%s/%s.obj" % [dir, model]
	if ResourceLoader.exists(obj_path):
		var mesh: Mesh = load(obj_path) as Mesh
		if mesh == null:
			push_error("occupation prop failed to load as a mesh: %s" % obj_path)
			return null
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		return instance
	push_error("occupation prop missing: %s (looked for .gltf/.glb/.obj under %s)" % [model, dir])
	return null


## Per-placement albedo override, applied through a UNIQUE material so tinting
## one crate cannot repaint every other instance sharing the imported
## resource -- the same trap `building_prefabs.gd::_apply_retint` documents.
func _tint(node: Node, colour: Color) -> void:
	for instance in _mesh_instances(node):
		var mesh := instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var source := instance.get_active_material(surface)
			var material: StandardMaterial3D = null
			if source is StandardMaterial3D:
				material = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				material = StandardMaterial3D.new()
				material.roughness = 0.9
			material.albedo_color = colour
			instance.set_surface_override_material(surface, material)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D:
			found.append(current as MeshInstance3D)
		stack.append_array(current.get_children())
	return found


func _track(light: OmniLight3D, energy: float) -> void:
	light.light_energy = energy
	_lights.append(light)
	_base_energy.append(energy)


## What a probe or a smoke test can count without walking the tree by hand.
func stats() -> Dictionary:
	return {
		"braziers": (_config.get("braziers", []) as Array).size(),
		"tether_lamps": (_config.get("tether_lamps", []) as Array).size(),
		"camp_props": _mesh_instances(get_node_or_null(^"Checkpoint")).size()
			if get_node_or_null(^"Checkpoint") != null else 0,
		"flickering_lights": _lights.size(),
	}


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		var list: Array = raw
		return Vector3(float(list[0]), float(list[1]), float(list[2]))
	return Vector3.ZERO


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

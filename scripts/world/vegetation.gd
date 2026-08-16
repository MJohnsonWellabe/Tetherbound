extends Node3D

## Renders the scatter.
##
## Where things go is decided by scripts/world/scatter_rules.gd, which is pure
## and tested. This file knows about meshes and nothing about ecology.
##
## OW5A/STREAM-SCATTER: renders through `Terrain3DInstancer` rather than a
## MultiMeshInstance3D per model. `scatter_rules.gd` is unchanged: it still
## returns plain placement dictionaries and knows nothing about how they are
## rendered. `build()` now needs a live Terrain3D node (for `get_instancer()`/
## `get_assets()`/`get_data()`), not just a world size.
##
## WHY, MEASURED, NOT JUST ARGUED: on today's 512m/4-region world (23,707
## instances) the OLD MultiMesh-build loop was already cheap — ~113ms,
## measured in isolation from the placement compute. The scatter's ~36s boot
## cost, before and after this swap, is ~99.6% `scatter_rules.all_placements()`
## itself (measured: 36.1s of a 36.3s total build), which this file does not
## touch and is not this task's scope — see `docs/MEADOWS_MACRO_LAYOUT.md`
## §1.1 on `road_polylines()`'s uncached per-pixel rebuild, owned by a
## different lane. So this swap is NOT a boot-time win today, and does not
## claim to be. What it buys is architectural: MultiMesh has no per-region
## storage and no streaming at all, so at the corridor's 64x/~1.5M-instance
## scale the whole scatter would have to live permanently resident in one
## place with a second, hand-rolled residency mechanism next to the terrain's
## own. `Terrain3DInstancer.add_transforms()` stores instance data on
## `Terrain3DRegion` — the object the terrain's own height/control/colour maps
## already live on and already stream — so scatter gets the terrain's
## residency mechanism instead of needing its own. §8.3 names this the hard
## prerequisite for exactly that reason, not for today's wall-clock.
##
## Collision is NOT part of what the instancer streams — MultiMesh never
## collided either, and neither does `Terrain3DInstancer`; both are pure
## rendering. `_add_collision()` below is UNCHANGED from before this swap:
## still one `StaticBody3D` per model, built eagerly for the whole world at
## `build()` time. A per-`Terrain3DRegion` grouping was tried and reverted —
## see `_add_collision()`'s own comment for why — so collision residency
## streaming with the corridor is explicit unfinished work, not solved here.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const HARVEST_POINT := preload("res://scripts/world/vegetation_harvest_point.gd")

## Props are sunk very slightly so their bases never float over a slope. The
## terrain under a prop is sampled at a single point, but the prop has width.
const SINK := 0.06

## OW7. How far off a marked tree its woodpile stands. Clear of the widest
## trunk this scatter places (CommonTree at 1.35 scale) so the pile never
## intersects the tree it belongs to, and close enough to read as ITS pile
## rather than as unrelated dressing. TUNABLE.
const PROP_OFFSET := 1.3

var _placed: int = 0
## SG46: layer name -> the placements `scatter_rules._thin_by_drain` took out
## around Team Tether's stations, held from the build so the healing can put
## back the very same instances rather than roll a second scatter that would
## not match the meadow the player walked through.
##
## Still keyed by layer and holding the same plain placement dictionaries
## `scatter_rules.gd` always returned — no per-region key was added here.
## `Terrain3DInstancer.add_transforms()` computes which `Terrain3DRegion` a
## transform belongs to from its own world position and files the instance
## there itself, so the region bookkeeping `Terrain3DInstancer` needs already
## lives in the transform's position — nothing here has to track region
## locations by hand to put a drained instance back in the right one.
var _drained: Dictionary = {}
var _regrown: int = 0
var _draw_calls: int = 0
var _solid: int = 0
var _harvest_points: int = 0
## OW7. Kept from `build` for `_spawn_harvest_point`, which stands a woodpile on
## the ground a metre or so off the tree it belongs to — and the ground there is
## not the ground under the tree.
var _field: RefCounted = null

## The live Terrain3D node passed to `build()`, and the three sub-objects the
## instancer swap needs from it.
var _terrain: Node = null
var _instancer: Object = null
var _assets: Object = null
var _data: Object = null
## model path -> the integer id it was registered under in `_assets`'
## mesh_list. Rebuilt every `build()`; `restore_drained()` extends it in place
## for any model that did not survive into the kept set at all (rare — every
## instance of that model was drained).
var _mesh_ids: Dictionary = {}
var _next_mesh_id: int = 0


## Build the whole scatter. `world_size` should match the terrain's.
## `terrain` is the live Terrain3D node — its instancer, assets and data are
## where every placement below actually ends up.
func build(world_size: float, terrain: Node) -> void:
	for child in get_children():
		child.queue_free()
	_placed = 0
	_draw_calls = 0
	_solid = 0
	_harvest_points = 0
	_tints.clear()
	_mesh_ids.clear()
	_next_mesh_id = 0

	_terrain = terrain
	if _terrain == null or not _terrain.has_method("get_instancer"):
		push_error("vegetation.build() needs a live Terrain3D node; scatter will not render")
		return
	_instancer = _terrain.call("get_instancer")
	_assets = _terrain.call("get_assets")
	_data = _terrain.call("get_data")
	if _instancer == null or _assets == null:
		push_error("Terrain3D produced no instancer/assets object; scatter will not render")
		return

	var cfg: Dictionary = RULES.config()
	if cfg.is_empty():
		return
	var field: RefCounted = HEIGHTFIELD.new()
	_field = field
	# SG46/D41: what the drain removed, kept aside instead of dropped. Nothing
	# is built from it here -- these instances are exactly the ones that are
	# meant to be missing while Team Tether's stations are running. See
	# `restore_drained()` for what puts them back and when.
	_drained.clear()
	_regrown = 0
	var by_layer: Dictionary = RULES.all_placements(field, world_size, int(cfg.get("seed", 1)), _drained)
	_mark_harvestable(by_layer)

	# Grouped by MODEL rather than by layer: two layers sharing a mesh should
	# share one instancer mesh id, or the draw-call saving is thrown away by
	# the bookkeeping.
	var by_model: Dictionary = {}
	for layer_name: String in by_layer.keys():
		for entry: Variant in (by_layer[layer_name] as Array):
			var placement: Dictionary = entry
			var model := str(placement["model"])
			if not by_model.has(model):
				by_model[model] = []
			(by_model[model] as Array).append(placement)

	# Every model registered as a Terrain3DMeshAsset in ONE set_mesh_list()
	# call before any transforms are added -- registering lazily per model
	# would call set_mesh_list() once per unique model (42 today), and this
	# is exactly the boot-time loop being fixed, not a place to add a second
	# one.
	_register_mesh_assets(by_model.keys())

	for model: String in by_model.keys():
		_build_batch(model, by_model[model])
	# One rebuild of the instancer's live MultiMeshInstance3Ds after every
	# batch is queued, not one per model -- `add_transforms()` below is
	# called with `update=false` for exactly this reason.
	_instancer.call("update_mmis", true)
	_warn_about_shared_models(by_layer)


## R2.3: makes a deterministic slice of a layer's OWN placements into real
## gather points, instead of scattering a second, separate set of authored
## nodes on top of the vegetation -- "walking up to any ordinary tree" only
## means something if the tree IS the gather point. Marks the placement
## Dictionary in place (a Dictionary is a reference type in GDScript, so this
## is still visible to `_build_batch` after the by-model regroup above,
## without threading a second data structure through it) rather than
## building a separate list, because `_build_batch` needs to know per
## INSTANCE, at the exact index it assigns in its own MultiMesh -- that index
## is what both the collider placement and the interact point have to agree
## on.
func _mark_harvestable(by_layer: Dictionary) -> void:
	for layer_name: String in by_layer.keys():
		var layer: Dictionary = RULES.config().get("layers", {}).get(layer_name, {})
		var item_id := str(layer.get("harvest_item", ""))
		if item_id == "":
			continue
		var fraction := clampf(float(layer.get("harvest_fraction", 0.0)), 0.0, 1.0)
		if fraction <= 0.0:
			continue
		var amount := int(layer.get("harvest_amount", 2))
		var respawn := float(layer.get("harvest_respawn_seconds", 90.0))
		var placements: Array = by_layer[layer_name]
		# A stride through the layer's own draw order, not an independent
		# per-instance coin flip -- spreads harvest points evenly across the
		# whole layer instead of letting chance cluster (or skip) them.
		var stride := maxi(1, roundi(1.0 / fraction))
		for i in placements.size():
			if i % stride != 0:
				continue
			var placement: Dictionary = placements[i]
			placement["harvest_item"] = item_id
			placement["harvest_amount"] = amount
			placement["harvest_respawn_seconds"] = respawn


## A model used by two layers cannot carry two different tints.
##
## Batches are grouped by MESH, and the per-layer tint override is looked up from
## the model. Sharing a model across layers is therefore silently
## last-writer-wins — which is exactly the kind of thing that shows up as one
## odd-coloured patch in a survey frame and takes an afternoon to trace.
func _warn_about_shared_models(by_layer: Dictionary) -> void:
	var owner_of: Dictionary = {}
	for layer_name: String in RULES.config().get("layers", {}).keys():
		if layer_name.begins_with("_"):
			continue
		var layer: Dictionary = RULES.config()["layers"][layer_name]
		for entry: Variant in (layer.get("models", []) as Array):
			var model := str(entry)
			if owner_of.has(model) and owner_of[model] != layer_name:
				push_warning("%s is in both '%s' and '%s'; only one layer's retint can apply" % [
					model.get_file(), owner_of[model], layer_name
				])
			owner_of[model] = layer_name


## Materials, cached by source name so every tree in the meadow shares one.
var _tints: Dictionary = {}


## Recolour a source mesh into the project's palette.
##
## Kenney's Nature Kit is authored in a bright teal green — #73ecdc grass,
## #6fe5d5 leaves. Internally consistent, and wrong here: against our terrain it
## reads as cyan plastic, and the key art board is warm olive and leaf. The
## silhouettes are good, so the models stay and the colours are remapped by
## material NAME, which survives a model being swapped for another from the same
## pack.
## A layer may override any entry in the global map — see `_tint_for`. That is
## what lets one mesh family carry two palettes: the same Kenney tufts read as
## green grass in one layer and dry gold straw in another, which is most of the
## hue breadth the meadow has. The critic counted 2 hue families against the key
## art board's 6, and the ground cannot supply the difference on its own.
func _retint(mesh: Mesh, overrides: Dictionary, swaps: Dictionary = {}, needs_instance_colour: bool = false) -> Mesh:
	var map: Dictionary = RULES.config().get("retint", {})
	# needs_instance_colour still requires a fresh material even with nothing
	# else to change: per-instance MultiMesh colour only multiplies through
	# when the material's own vertex_color_use_as_albedo is true, and the
	# source pack's default for an untouched model cannot be assumed to be.
	if not needs_instance_colour and map.is_empty() and overrides.is_empty() and swaps.is_empty():
		return mesh

	# `duplicate(false)` copies the mesh's surfaces (geometry, LOD chain and
	# all) through ArrayMesh's own storage properties rather than us
	# reconstructing them by hand. The old code rebuilt via
	# surface_get_arrays()/add_surface_from_arrays(), which only round-trips
	# the base LOD0 arrays -- the importer's generated LOD levels and shadow
	# mesh (meshes/generate_lods, meshes/create_shadow_meshes, both true on
	# every .glb/.gltf import here) have no public getter and were silently
	# dropped, so every retinted instance drew at LOD0 at every distance.
	# `false` (no subresource duplication) is deliberate: the shadow mesh
	# carries no material and is never touched below, so sharing the one
	# original instance across every retint variant is correct and free.
	var out: ArrayMesh = mesh.duplicate(false)
	for surface in mesh.get_surface_count():
		var source: Material = mesh.surface_get_material(surface)
		var key := "" if source == null else source.resource_name
		out.surface_set_material(surface, _tint_for(key, source, overrides, swaps, needs_instance_colour))
	return out


func _tint_for(name: String, source: Material, overrides: Dictionary, swaps: Dictionary = {}, needs_instance_colour: bool = false) -> Material:
	var map: Dictionary = RULES.config().get("retint", {})
	var colour := ""
	if overrides.has(name):
		colour = str(overrides[name])
	elif map.has(name):
		colour = str(map[name])

	# A layer may also swap the TEXTURE, not just tint it.
	#
	# Colour alone cannot fix a texture that is the wrong colour, because
	# `albedo_color` multiplies: the Quaternius pack ships `Leaves_TwistedTree_C`
	# as a crimson autumn leaf, and `Bush_Common` uses that same material — so
	# eight hundred bushes came out blood red, and no multiply turns red green.
	# Swapping the texture for the pack's own green leaf does.
	var swap := str(swaps.get(name, ""))

	# Keyed by everything that can change the result, so two layers overriding
	# the same source material get two materials while everything else still
	# shares one. needs_instance_colour is part of the key too — a jittered
	# layer and an unjittered one must not share a material even when their
	# colour/swap are otherwise identical.
	var cache_key := "%s|%s|%s|%s" % [name, colour, swap, needs_instance_colour]
	if _tints.has(cache_key):
		return _tints[cache_key]

	var material := StandardMaterial3D.new()
	var standard := source as StandardMaterial3D

	# A TEXTURED source keeps its texture, and the colour modulates it.
	#
	# This function was written when every prop was one flat colour, so it built
	# a fresh material and threw the source away. Pointed at a textured pack that
	# would discard the bark, leaf and rock textures entirely and repaint the
	# whole meadow in flat blocks — deleting the exact thing worth having, in the
	# name of palette consistency.
	#
	# In Godot `albedo_color` MULTIPLIES the albedo texture, so an unmapped
	# material passing through white is the texture exactly as authored, and a
	# mapped one is a tint over it. That means a strong colour from the old flat
	# palette would come out near-black over a texture — which is why mapped
	# colours for textured packs belong near white. See vegetation.json.
	if standard != null and standard.albedo_texture != null:
		material.albedo_texture = standard.albedo_texture
		if swap != "" and ResourceLoader.exists(swap):
			material.albedo_texture = load(swap) as Texture2D
		elif swap != "":
			push_warning("layer asks to swap material '%s' to '%s', which does not exist" % [name, swap])
		material.normal_texture = standard.normal_texture
		# Foliage packs carry per-vertex tint; dropping it flattens the canopy
		# variation the pack authored. A jittered layer forces it on regardless
		# of the source's own default — MultiMesh per-instance colour multiplies
		# through this same channel, and an untouched model cannot be assumed to
		# already have it enabled.
		material.vertex_color_use_as_albedo = standard.vertex_color_use_as_albedo or needs_instance_colour
		material.normal_enabled = standard.normal_enabled
		material.albedo_color = Color(colour) if colour != "" else Color.WHITE
		# Foliage is alpha-cut, not blended: leaves are cards with holes in them,
		# and alpha blending would sort them against each other every frame for
		# thousands of instances.
		material.transparency = standard.transparency
		material.alpha_scissor_threshold = standard.alpha_scissor_threshold
		material.cull_mode = standard.cull_mode
		# R9.4: two independent blind critics, looking at different frame sets
		# and told nothing, both named foliage as the most bug-like thing in the
		# build — "blue/green/white confetti speckle", "digital confetti", "reads
		# as compression noise, not foliage". A hard alpha scissor has no partial
		# coverage: every texel is fully in or fully out, so a tree that is ten
		# pixels wide resolves to a scatter of unrelated leaf texels with the
		# background between them. The project already runs 4x MSAA
		# (project.godot anti_aliasing/quality/msaa_3d=2) and it was doing
		# nothing here, because MSAA only cleans alpha edges when the material
		# opts in to alpha-to-coverage. This is that opt-in.
		#
		# NOT VERIFIED IN THIS HARNESS. llvmpipe's MSAA support is not something
		# these survey frames can honestly test, so the frames may look
		# unchanged while real hardware improves. Judge this one on the Ally.
		# What it cannot fix either way is that a ten-pixel tree carries almost
		# no information — that is an LOD/impostor problem, recorded separately.
		if standard.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			material.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
	elif colour != "":
		material.albedo_color = Color(colour)
		material.vertex_color_use_as_albedo = needs_instance_colour
	elif standard != null:
		# Unmapped, untextured materials keep their original colour rather than
		# turning white, so adding a model from the pack degrades to "slightly
		# off" instead of "glowing".
		material.albedo_color = standard.albedo_color
		material.vertex_color_use_as_albedo = needs_instance_colour
	elif needs_instance_colour:
		material.vertex_color_use_as_albedo = true

	material.roughness = 0.94
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_tints[cache_key] = material
	return material


## Register every unique model in `models` as a `Terrain3DMeshAsset` in one
## `set_mesh_list()` call. Models already registered (an id already held in
## `_mesh_ids`, which only happens when `restore_drained()` ran before a
## second `build()` — not the normal boot path) are skipped.
func _register_mesh_assets(models: Array) -> void:
	var list: Array = []
	for model_path: String in models:
		if _mesh_ids.has(model_path):
			continue
		var asset := _make_mesh_asset(str(model_path))
		if asset == null:
			continue
		var id := _next_mesh_id
		_next_mesh_id += 1
		asset.set("id", id)
		_mesh_ids[model_path] = id
		list.append(asset)
	if not list.is_empty():
		_assets.call("set_mesh_list", list)


## `restore_drained()`'s path: a model that was drained in its entirety never
## got a mesh id from `_register_mesh_assets()` above, so register it here,
## lazily, one `set_mesh_list()` call at a time. Not the boot path — never
## called from `build()` — so the extra calls this makes when several models
## are new at once cost nothing that matters.
func _mesh_id_for(model_path: String) -> int:
	if _mesh_ids.has(model_path):
		return _mesh_ids[model_path]
	var asset := _make_mesh_asset(model_path)
	if asset == null:
		return -1
	var id := _next_mesh_id
	_next_mesh_id += 1
	asset.set("id", id)
	var list: Array = _assets.call("get_mesh_list")
	list.append(asset)
	_assets.call("set_mesh_list", list)
	_mesh_ids[model_path] = id
	return id


## Build one `Terrain3DMeshAsset` for a model, retinted exactly the way the
## old MultiMesh path retinted it.
##
## `Terrain3DMeshAsset` takes a `scene_file` (a `PackedScene`), not a bare
## `Mesh` — it has no per-surface material slot of its own, only a single
## whole-mesh `material_override`, which would collapse `_retint()`'s
## per-SURFACE colour map (bark one colour, leaves another, both on one
## model) down to one flat tint. Packing the already-retinted mesh into a
## throwaway one-node `PackedScene` in memory — never written to disk —
## keeps `_retint()`/`_tint_for()` untouched and reuses them exactly as
## `_build_batch()` always did.
func _make_mesh_asset(model_path: String) -> Object:
	if not ClassDB.class_exists("Terrain3DMeshAsset"):
		push_error("Terrain3DMeshAsset is not available on this build; scatter cannot render")
		return null
	var mesh := _mesh_for(model_path)
	if mesh == null:
		push_error("scatter model %s could not be loaded; that layer will be missing" % model_path)
		return null

	var layer_cfg := _layer_for(model_path)
	var jitter := float(layer_cfg.get("colour_jitter", 0.0))
	# EV2: a layer may assign one of a few controlled material variants per
	# MODEL (spring/deep/yellow-green) instead of one flat colour for every
	# tree in the layer -- keyed by model path since several models share one
	# material name and the layer-wide `retint` cannot tell them apart. Falls
	# back to the layer's own retint when a model has no variant entry.
	var tint_overrides: Dictionary = layer_cfg.get("retint", {})
	var variants: Dictionary = layer_cfg.get("variant_retint", {})
	if variants.has(model_path):
		tint_overrides = variants[model_path]
	var retinted := _retint(mesh, tint_overrides, layer_cfg.get("retexture", {}), jitter > 0.0)

	var holder := MeshInstance3D.new()
	holder.mesh = retinted
	var packed := PackedScene.new()
	packed.pack(holder)
	holder.free()

	var asset: Object = ClassDB.instantiate("Terrain3DMeshAsset")
	asset.set("name", model_path.get_file().get_basename())
	asset.set("scene_file", packed)
	# Shadow casting is per layer, and the small layers must not.
	#
	# Everything cast until now. At the densities this scatter runs at — several
	# thousand tufts, most of them within thirty metres of the camera — every
	# blade drops its own hard shadow onto terrain that does receive, and they
	# overlap into a black carpet. Measured: the near-field ground read at
	# luminance 0.068 against 0.27-0.60 across the references, and three of five
	# survey frames had a foreground that was simply dark.
	#
	# A tuft's shadow is not information at this scale; a tree's is. Trees,
	# bushes, rocks and deadfall place themselves on the ground with theirs,
	# which is the thing shadows are actually for here.
	asset.set("cast_shadows", bool(layer_cfg.get("casts_shadow", true)))
	return asset


## Colour jitter needs its own RNG stream per model, seeded the same way the
## old MultiMesh path seeded it, so a jittered layer's palette spread is
## unchanged by this swap.
func _build_batch(model_path: String, placements: Array) -> void:
	var mesh_id := _mesh_id_for(model_path)
	if mesh_id < 0:
		return

	var layer_cfg := _layer_for(model_path)
	var jitter := float(layer_cfg.get("colour_jitter", 0.0))
	var use_colour := jitter > 0.0
	var jitter_rng := RandomNumberGenerator.new()
	if use_colour:
		jitter_rng.seed = hash(model_path)

	var transforms: Array[Transform3D] = []
	transforms.resize(placements.size())
	var colours := PackedColorArray()
	if use_colour:
		colours.resize(placements.size())

	for i in placements.size():
		var placement: Dictionary = placements[i]
		var basis := Basis(Vector3.UP, float(placement["yaw"]))
		# scatter_rules.gd only sets "normal" for layers that opted into
		# align_to_slope (rocks) — everything else stays world-up.
		if placement.has("normal"):
			var normal: Vector3 = placement["normal"]
			basis = Basis(Quaternion(Vector3.UP, normal)) * basis
		basis = basis.scaled(Vector3.ONE * float(placement["scale"]))
		var spot: Vector3 = placement["position"]
		transforms[i] = Transform3D(basis, spot - Vector3.UP * SINK)
		if use_colour:
			var v := 1.0 + jitter_rng.randf_range(-jitter, jitter)
			colours[i] = Color(v, v, v, 1.0)
		if placement.has("harvest_item"):
			_spawn_harvest_point(placement)

	# `update=false`: one bulk native call per model instead of one per
	# placement (the MultiMesh path's `set_instance_transform` loop, ~23.7k
	# individual calls today and the measured cause of the boot-time cost
	# this swap exists to remove), and `update_mmis(true)` runs once after
	# every model in `build()`'s loop rather than once per model here.
	_instancer.call("add_transforms", mesh_id, transforms, colours, false)

	_placed += placements.size()
	_draw_calls += 1
	_add_collision(model_path, placements)


## One real gather point on the world's own scattered vegetation (R2.3) --
## see `_mark_harvestable` for how a placement earns the `harvest_item` key
## this reads. The tree/rock itself is the MultiMesh instance built alongside
## it in `_build_batch`; `vegetation_harvest_point.gd` adds its own small
## glint marker rather than this file tinting the MultiMesh instance -- an
## earlier attempt at a per-instance colour multiply (the same mechanism
## R7.1-remainder uses for grass jitter) read as diseased/scorched foliage to
## two independent blind critics once applied to a tree canopy, because the
## leaf mesh's own baked per-vertex shading survives the multiply. A small
## separate marker sidesteps that entirely.
##
## OW7 adds the `prop_offset` the gather point stands its resource prop on. The
## bearing is hashed from the placement's own world position — deterministic,
## varied per instance, and identical to the bearing the glint already used —
## but the DROP is sampled from the heightfield here, because this is the file
## that holds one. A pile placed at the tree's own Y would hang in the air or
## sink into the bank wherever the ground falls away over that metre and a
## third, which on a meadow of rolling hills is most of them.
func _spawn_harvest_point(placement: Dictionary) -> void:
	var point := HARVEST_POINT.new()
	var spot: Vector3 = placement["position"]
	point.position = spot
	add_child(point)
	var bearing := float(hash(spot) & 0xFFFFFF) / float(0xFFFFFF) * TAU
	var away := Vector2(sin(bearing), cos(bearing)) * PROP_OFFSET
	var drop := 0.0
	if _field != null:
		drop = float(_field.call("height_at", spot.x + away.x, spot.z + away.y)) - spot.y
	point.call("setup", {
		"item": placement["harvest_item"],
		"amount": placement["harvest_amount"],
		"respawn_seconds": placement["harvest_respawn_seconds"],
		"prompt_height": 1.0 + float(placement["scale"]),
		"label": "Gather",
		"prop_offset": Vector3(away.x, drop - SINK, away.y),
		"prop_yaw": bearing,
	})
	_harvest_points += 1


## Give the solid layers real collision.
##
## MultiMesh draws but does not collide, and two things depend on collision that
## are easy to miss. A tree you walk through reads as a hologram. And the
## camera's SpringArm3D only stops at colliders — with none, the camera walks
## straight into a bush and the entire fight disappears behind two green
## polygons, which is exactly what happened to two survey frames.
##
## One StaticBody3D holding many shapes rather than a body per prop: the physics
## server handles that far better, and none of these ever move.
##
## STREAM-SCATTER: still one body per MODEL, unchanged from before this swap
## — NOT grouped per `Terrain3DRegion`, despite the file header raising that
## as the thing to plan for. Tried it (one `StaticBody3D` per region location)
## and reverted: `tests/smoke_traversal.gd::_check_rock_collision_alignment`
## finds rock colliders by walking `Vegetation`'s direct children for a
## `StaticBody3D` named `Rock_*`/`Pebble_*` — a real, working OF14 regression
## check, not incidental — and a region-keyed name broke it outright ("no
## sloped rock colliders found to check"). Since collision streaming is not
## actually wired to region residency yet either way (no
## region-activated/-deactivated signal exists on this Terrain3D build — see
## the file header), regrouping today traded a real check for a
## not-yet-useful structure. Left as the honest, explicitly named remainder:
## whoever wires collision residency to the corridor's region streaming needs
## a way to find "every collider in region R" that doesn't depend on name
## prefixes, and should change this function and
## `_check_rock_collision_alignment` together, in the same change.
func _add_collision(model_path: String, placements: Array) -> void:
	var layer := _layer_for(model_path)
	if layer.is_empty() or not bool(layer.get("collides", false)):
		return
	var radius := float(layer.get("collision_radius", 0.5))

	var body := StaticBody3D.new()
	body.name = "%s_Collision" % model_path.get_file().get_basename()
	add_child(body)
	for entry: Variant in placements:
		var placement: Dictionary = entry
		var scale := float(placement["scale"])
		var shape := CylinderShape3D.new()
		shape.radius = radius * scale
		# Tall enough to stop a camera at head height, short enough that it is a
		# trunk rather than an invisible wall.
		shape.height = 4.0 * scale
		var node := CollisionShape3D.new()
		node.shape = shape
		# OF14: the render path (above, `_build_batch`) tilts a rock's VISUAL
		# mesh to the slope normal when its layer opts into `align_to_slope`
		# (rocks only), but this collider stayed world-up regardless — on a
		# steep anchor site (up to 52 degrees) a scaled-up boulder leans its
		# silhouette out past a vertical cylinder's footprint, letting the
		# player walk into visible rock before touching collision. Give the
		# shape the same tilt the mesh gets, so the collider bounds what is
		# actually on screen instead of an upright approximation of it.
		var up := Vector3.UP
		if placement.has("normal"):
			up = placement["normal"]
			node.basis = Basis(Quaternion(Vector3.UP, up))
		node.position = (placement["position"] as Vector3) + up * (shape.height * 0.5)
		body.add_child(node)
	_solid += placements.size()


## Which layer a model belongs to. Models are grouped by mesh for drawing, so the
## layer has to be recovered to know whether it is solid.
func _layer_for(model_path: String) -> Dictionary:
	var layers: Dictionary = RULES.config().get("layers", {})
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		if model_path in (layers[name] as Dictionary).get("models", []):
			return layers[name]
	return {}


## Flatten an imported .glb down to a single Mesh.
##
## Kenney's nature models are one mesh under a couple of transform nodes, so the
## first mesh found, baked with its local transform, is the whole prop. A model
## with several parts would lose them here — which is why this reports rather
## than guesses.
func _mesh_for(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var scene: Node = packed.instantiate()
	var meshes: Array[MeshInstance3D] = []
	_collect(scene, meshes)
	scene.queue_free()

	if meshes.is_empty():
		return null
	if meshes.size() > 1:
		push_warning("%s has %d meshes; only the first is scattered" % [path.get_file(), meshes.size()])
	return meshes[0].mesh


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)


## SG46 / D41's third clause: the meadow is freed, and what the stations killed
## comes back.
##
## The drain took real instances out of this scatter at build time
## (`scatter_rules._thin_by_drain`), and this puts back exactly those — the
## same models, at the same positions, at the same scales and yaws — through
## the same `_build_batch` every other prop in the meadow goes through. So the
## regrowth gets the same retint, the same per-instance colour jitter, the same
## collision and the same harvest wiring, because it IS the same code path;
## there is no second vegetation system and no "healed" variant asset.
##
## Why the placements were kept rather than re-rolled: a fresh scatter with the
## drain switched off would return a DIFFERENT meadow — every clump and stray
## after the first re-draw shifts — and the player would walk home past ground
## that changed everywhere instead of ground that healed where the machines
## were. Keeping the removed list is the only version of this that is honest
## about which trees these are.
##
## What this CANNOT do is repaint the ground: the drained colour and control
## maps for the quarry stations are baked into the terrain textures, and D45
## priced that out loud ("the grammar chosen for the damage is baked, so the
## grammar for the repair is a separate piece of work"). Vegetation is the half
## that lives in the live scene; `tether_relay.gd::heal()` is the runtime skin.
## `docs/decisions/D45-the-drained-ground-grammar.md` records what stays baked.
##
## Returns how many instances came back, so the caller can log a real number
## rather than an intention. Safe to call twice: the second call is a no-op.
func restore_drained() -> int:
	if _drained.is_empty():
		return 0
	var by_model: Dictionary = {}
	for layer_name: String in _drained.keys():
		for entry: Variant in (_drained[layer_name] as Array):
			var placement: Dictionary = entry
			var model := str(placement["model"])
			if not by_model.has(model):
				by_model[model] = []
			(by_model[model] as Array).append(placement)
	var before := _placed
	for model: String in by_model.keys():
		_build_batch(model, by_model[model])
	# `_build_batch` adds with `update=false` (see its own comment); the
	# instancer's live MultiMeshInstance3Ds need exactly one rebuild after
	# all of this healing's models are queued, same as `build()`'s own loop.
	if _instancer != null:
		_instancer.call("update_mmis", true)
	_regrown = _placed - before
	_drained.clear()
	return _regrown


## How many instances the drain is currently holding out of the world — the
## size of the regrowth still owed. Zero once it has been paid.
func drained_count() -> int:
	var total := 0
	for layer_name: String in _drained.keys():
		total += (_drained[layer_name] as Array).size()
	return total


func regrown_count() -> int:
	return _regrown


## For the survey's cost readout. Not a budget and not a gate — software
## rendering cannot measure frame time honestly (D06) — but "how much did we
## just put in the world" is worth being able to say out loud.
func stats() -> Dictionary:
	return {
		"instances": _placed,
		"batches": _draw_calls,
		"solid": _solid,
		"harvest_points": _harvest_points,
		"drained_out": drained_count(),
		"regrown": _regrown,
	}

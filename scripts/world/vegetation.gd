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
const BAKE := preload("res://scripts/world/scatter_bake.gd")

## SCAT1: which bake this world's placements load from, in `data/scatter/<name>/`.
## The playground is the only world with a bake; anything else falls back to
## computing, same as a missing or stale bake does.
const BAKE_WORLD_NAME := "playground"

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

## HARVEST-ALL / D60. Chopped stays chopped, forever, including across a
## save/load — this is the record of it. layer name -> a real BITSET
## (`PackedByteArray`, one BIT not one byte per placement, `_bitset_bytes()`
## sized), one bit per placement in that layer's OWN placement order
## (`RULES.all_placements()`'s per-layer array, the same order
## `_mark_harvestable()` already walks with a stride). A bit set means that
## placement was permanently harvested. Sized once in `_mark_harvestable()`
## from the layer's own placement COUNT, which is fixed by the deterministic
## scatter (seed + config) — only which bits are SET grows as the player
## chops things, never the bitset itself, which is the bound the owner asked
## for explicitly rather than an ever-growing id list.
var _harvested: Dictionary = {}
## layer name -> that layer's total placement count, for `restore_from_game`'s
## loop bound (a save's own bitset size already gives this too, but a layer
## can be ABSENT from `_harvested` entirely on this build, e.g. a config edit
## that dropped it — this dict answers "how many, if at all" in one lookup).
var _harvest_layer_counts: Dictionary = {}
## "<layer>#<index>" -> {"mesh_id": int, "position": Vector3}. Built once per
## harvestable placement in `_spawn_harvest_point()`. `harvest_permanently()`
## uses this to find the exact render instance to remove and is the only
## consumer; entries are erased as their instance is chopped, so this shrinks
## back down rather than accumulating dead entries for the session.
var _harvest_lookup: Dictionary = {}
## Same key -> the live `vegetation_harvest_point.gd` node, so
## `harvest_permanently()` can free it. Erased alongside `_harvest_lookup`.
var _harvest_nodes: Dictionary = {}
## Same key -> the `_collision_batches` entry (a direct Dictionary reference,
## not a copy — mutating `placements`/`resident` here is the same array
## `update_collision_streaming()` iterates) holding that placement's
## collider, for the collidable layers (rocks). Trees are not collidable at
## the harvest-point-bearing instance today (`collides: true` on the layer,
## in fact they are — see `_add_collision`), so this applies to both.
var _harvest_collision_lookup: Dictionary = {}
## The `world_size` `build()` was last called with — `restore_from_game()`
## never needs to re-run the whole build, but this is kept for symmetry with
## the rest of the boot path and as a cheap sanity anchor if that ever
## changes.
var _last_world_size: float = 512.0
## HARVEST_REMOVE_RADIUS: the `size` passed to `Terrain3DInstancer.
## remove_instances()`. Verified empirically (not assumed) against this
## vendored Terrain3D build with `tools/_probe_terrain_streaming.gd`-style
## scratch probes: a `size` this small combined with `strength` 100 removes
## EXACTLY the instance nearest the given position and none other, even at
## 0.3m instance spacing (tighter than any real clump this scatter draws) —
## the two ~1.0m/~0.3m grid tests that established this are recorded in
## D60. `remove_instances()` is a probabilistic BRUSH tool built for the
## editor's erase-instances tool (its params dict — asset_id, modifier_
## shift/alt, size, strength, slope, on_collision, raycast_height — are the
## brush's own, undocumented on this build and recovered by reading Terrain3D
## upstream source), not a designed "remove exactly one instance" API — this
## is deliberately called at the EXACT stored position of the placement being
## harvested (never a player-aimed point) so the near-zero-distance case,
## which strength 100 removes reliably, is the only case ever exercised.
const HARVEST_REMOVE_RADIUS := 0.05
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

## COLL1 / §8.3: how close a collidable placement must be to the last point
## passed to `update_collision_streaming()` to keep a real `CollisionShape3D`.
## MultiMesh keeps drawing every instance in the world regardless -- this
## file's own header already argues that is cheap enough unstreamed -- only
## the physics body is gated. TUNABLE: chosen well inside the ~45m the
## player can already see coming (SpringArm3D camera collision, sprint stops
## being a surprise-corner problem long before this), not derived from a
## measurement.
const COLLISION_STREAM_RADIUS := 100.0

## One entry per `_add_collision()` call: `body` (the StaticBody3D that holds
## whatever is currently resident), `radius` (the layer's shape radius,
## config-driven, unrelated to COLLISION_STREAM_RADIUS), `placements` (every
## collidable instance in this batch, streamed or not) and `resident` (a
## parallel Array, one `CollisionShape3D` or `null` per placement) --
## `update_collision_streaming()` reads and writes this without ever
## scanning `get_children()`.
var _collision_batches: Array[Dictionary] = []


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
	_harvested.clear()
	_harvest_layer_counts.clear()
	_harvest_lookup.clear()
	_harvest_nodes.clear()
	_harvest_collision_lookup.clear()
	_last_world_size = world_size
	# HARVEST-ALL: `restore_from_game()` needs to find this node to apply a
	# save's permanently-chopped state on top of the fresh scatter build()
	# always draws — the same "build fresh, then reconcile against the save"
	# split `build_placer.gd`/`player_death.gd` already use for their own
	# groups. Safe to call every build(): `add_to_group` on an id already
	# held is a no-op.
	add_to_group("harvest_state")

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

	_collision_batches.clear()

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
	# SCAT1: the placement pass is pure and offline-bakeable. A fresh bake turns
	# load into a file read; a missing or stale one (older config, different
	# seed) falls back to computing exactly as `all_placements` always has, so
	# nothing depends on the bake existing. `is_fresh` compares a fingerprint of
	# the live config, which is why the corridor re-bake (OW5B-E) does not need
	# a matching scatter bake landed alongside it — an out-of-date bake is
	# ignored, never used.
	var base_seed := int(cfg.get("seed", 1))
	var by_layer: Dictionary
	if BAKE.is_fresh(BAKE_WORLD_NAME, base_seed):
		by_layer = BAKE.load_all(BAKE_WORLD_NAME, _drained)
	else:
		by_layer = RULES.all_placements(field, world_size, base_seed, _drained)
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
		var placements: Array = by_layer[layer_name]
		_harvest_layer_counts[layer_name] = placements.size()
		_harvested[layer_name] = _new_bitset(placements.size())
		# A stride through the layer's own draw order, not an independent
		# per-instance coin flip -- spreads harvest points evenly across the
		# whole layer instead of letting chance cluster (or skip) them.
		# HARVEST-ALL: fraction is 1.0 for every harvestable layer today, so
		# stride is 1 and every placement is marked -- the stride mechanism
		# stays rather than being ripped out because a future layer could
		# still ship with a fraction below 1.0 (a rare-resource species, say)
		# and this is exactly the lever for that.
		var stride := maxi(1, roundi(1.0 / fraction))
		for i in placements.size():
			if i % stride != 0:
				continue
			var placement: Dictionary = placements[i]
			placement["harvest_item"] = item_id
			placement["harvest_amount"] = amount
			# HARVEST-ALL/D60: no more respawn. `harvest_respawn_seconds` (the
			# old JSON key) is gone -- a chopped placement is removed for
			# good, never dimmed-and-timed-out. See harvest_permanently().
			placement["harvest_layer"] = layer_name
			placement["harvest_index"] = i


## HARVEST-ALL/D60. A real bitset, not one byte per flag: at this density
## (thousands of harvestable placements per layer) a `PackedByteArray` of one
## BYTE per instance would be 8x the save-file cost of one BIT per instance
## for no benefit -- the record only ever answers "chopped or not", nothing
## graded. Sized once per layer from that layer's own placement count and
## never resized after -- see `_harvested`'s own comment for why that bound
## matters.
func _bitset_bytes(count: int) -> int:
	return (count + 7) / 8


func _new_bitset(count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(_bitset_bytes(count))
	bytes.fill(0)
	return bytes


func _bit_get(bytes: PackedByteArray, index: int) -> bool:
	var byte_i := index / 8
	if byte_i < 0 or byte_i >= bytes.size():
		return false
	return (bytes[byte_i] & (1 << (index % 8))) != 0


func _bit_set(bytes: PackedByteArray, index: int) -> void:
	var byte_i := index / 8
	if byte_i < 0 or byte_i >= bytes.size():
		return
	bytes[byte_i] = bytes[byte_i] | (1 << (index % 8))


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
	var layer_name := str(placement.get("harvest_layer", ""))
	var index := int(placement.get("harvest_index", -1))
	point.call("setup", {
		"item": placement["harvest_item"],
		"amount": placement["harvest_amount"],
		"prompt_height": 1.0 + float(placement["scale"]),
		"label": "Gather",
		"prop_offset": Vector3(away.x, drop - SINK, away.y),
		"prop_yaw": bearing,
		"harvest_layer": layer_name,
		"harvest_index": index,
	})
	# HARVEST-ALL: `harvest_permanently()`'s only way to find this instance's
	# render mesh id/position and this node again, without scanning every
	# child every time a resource is chopped.
	var key := "%s#%d" % [layer_name, index]
	_harvest_lookup[key] = {"mesh_id": _mesh_id_for(str(placement["model"])), "position": spot}
	_harvest_nodes[key] = point
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

## COLL1 / §8.3: registers the batch and streams in whatever is already
## within COLLISION_STREAM_RADIUS of the world origin, rather than building
## every shape immediately. `update_collision_streaming()` is what actually
## keeps this current as the player moves; the caller (playground_world.gd)
## re-centres it on the real spawn point right after `build()` returns, so
## the origin-based pass here just avoids a single frame with zero collision
## on batches near (0,0,0).
func _add_collision(model_path: String, placements: Array) -> void:
	var layer := _layer_for(model_path)
	if layer.is_empty() or not bool(layer.get("collides", false)):
		return
	var radius := float(layer.get("collision_radius", 0.5))

	var body := StaticBody3D.new()
	body.name = "%s_Collision" % model_path.get_file().get_basename()
	add_child(body)

	var resident: Array = []
	resident.resize(placements.size())
	var batch := {
		"body": body,
		"radius": radius,
		"placements": placements,
		"resident": resident,
	}
	_collision_batches.append(batch)
	_solid += placements.size()
	_stream_batch(_collision_batches[-1], Vector3.ZERO)

	# HARVEST-ALL: index this batch (a Dictionary — a reference, so mutating
	# `placements`/`resident` through this lookup later is the exact same
	# arrays `_stream_batch`/`update_collision_streaming` already iterate) by
	# every harvestable placement it holds, so `harvest_permanently()` can
	# find and remove one collider without scanning every batch in the world.
	for placement: Dictionary in placements:
		if not placement.has("harvest_item"):
			continue
		var key := "%s#%d" % [str(placement.get("harvest_layer", "")), int(placement.get("harvest_index", -1))]
		_harvest_collision_lookup[key] = batch


## Ensures every collidable placement within `COLLISION_STREAM_RADIUS` of
## `center` has a real `CollisionShape3D`, and every one outside does not.
##
## No Terrain3DRegion involved on purpose: `tools/_probe_terrain_streaming.gd`
## dumped this build's full `Terrain3DRegion`/`Terrain3DInstancer` method
## surface and there is no activate/deactivate signal for hand-placed nodes
## to hook -- an earlier attempt at grouping these bodies per region hit
## exactly that wall and was reverted. This drives its own distance bubble
## from the camera/player position instead, the same mechanism Terrain3D's
## own `collision_mode` 1 / `collision_radius` already uses, rather than
## inventing a second, region-shaped residency system that could disagree
## with the first about which patch of the world is "loaded".
##
## Called once (from `_add_collision`, centred on the origin) so a batch is
## never built with zero collision, then again with the real spawn point
## right after `build()` returns, then periodically as the player moves
## (`playground_world.gd`, throttled -- cheap at today's few-thousand-
## instance scale, but there is no reason to pay for it every physics tick
## when the bubble only has to be right within a fraction of a second of the
## player actually approaching).
func update_collision_streaming(center: Vector3) -> void:
	for batch: Dictionary in _collision_batches:
		_stream_batch(batch, center)


func _stream_batch(batch: Dictionary, center: Vector3) -> void:
	var body: StaticBody3D = batch["body"]
	var placements: Array = batch["placements"]
	var resident: Array = batch["resident"]
	var shape_radius: float = batch["radius"]
	var radius_sq := COLLISION_STREAM_RADIUS * COLLISION_STREAM_RADIUS
	for i in placements.size():
		var placement: Dictionary = placements[i]
		var spot: Vector3 = placement["position"]
		var within := spot.distance_squared_to(center) <= radius_sq
		var has_shape: bool = resident[i] != null
		if within and not has_shape:
			var node := _make_collision_shape(placement, shape_radius)
			resident[i] = node
			body.add_child(node)
		elif not within and has_shape:
			(resident[i] as CollisionShape3D).queue_free()
			resident[i] = null


## One prop's collider, split out of `_add_collision` unchanged -- COLL1 did
## not touch the shape itself, only when it exists.
func _make_collision_shape(placement: Dictionary, radius: float) -> CollisionShape3D:
	var scale := float(placement["scale"])
	var shape := CylinderShape3D.new()
	shape.radius = radius * scale
	# Tall enough to stop a camera at head height, short enough that it is a
	# trunk rather than an invisible wall.
	shape.height = 4.0 * scale
	var node := CollisionShape3D.new()
	node.shape = shape
	# OF14: the render path (`_build_batch`) tilts a rock's VISUAL mesh to the
	# slope normal when its layer opts into `align_to_slope` (rocks only), but
	# this collider stayed world-up regardless — on a steep anchor site (up to
	# 52 degrees) a scaled-up boulder leans its silhouette out past a vertical
	# cylinder's footprint, letting the player walk into visible rock before
	# touching collision. Give the shape the same tilt the mesh gets, so the
	# collider bounds what is actually on screen instead of an upright
	# approximation of it.
	var up := Vector3.UP
	if placement.has("normal"):
		up = placement["normal"]
		node.basis = Basis(Quaternion(Vector3.UP, up))
	node.position = (placement["position"] as Vector3) + up * (shape.height * 0.5)
	return node


## Every collidable placement currently holding a real `CollisionShape3D`,
## across every batch -- what `_solid` counts is the world total; this is
## what is actually resident right now. For tests and for the survey's cost
## readout, not gameplay.
func collision_resident_count() -> int:
	var n := 0
	for batch: Dictionary in _collision_batches:
		for shape: Variant in (batch["resident"] as Array):
			if shape != null:
				n += 1
	return n


## How many collidable placements exist in total, world-wide, in every batch
## whose StaticBody3D name starts with `prefix` -- e.g. "Rock_" or "Pebble_".
## Independent of streaming state; see `force_collision_resident()` below.
func collidable_count(prefix: String = "") -> int:
	var n := 0
	for batch: Dictionary in _collision_batches:
		var body: StaticBody3D = batch["body"]
		if prefix != "" and not body.name.begins_with(prefix):
			continue
		n += (batch["placements"] as Array).size()
	return n


## Forces every placement in every batch whose StaticBody3D name starts with
## `prefix` to have a real `CollisionShape3D`, ignoring
## `COLLISION_STREAM_RADIUS` entirely -- for tests that need to check every
## instance of one specific layer (e.g. every sloped rock's collider
## alignment, OF14/`tests/smoke_traversal.gd`) regardless of where the
## player's own path happened to go, instead of trusting that incidental
## foot traffic streamed all of them in already.
##
## Gameplay code never calls this. It exists so a test can assert the
## property it actually cares about ("every rock's collider is aligned")
## without either disabling streaming or silently checking a subset and
## calling it complete.
func force_collision_resident(prefix: String) -> void:
	for batch: Dictionary in _collision_batches:
		var body: StaticBody3D = batch["body"]
		if not body.name.begins_with(prefix):
			continue
		var placements: Array = batch["placements"]
		var resident: Array = batch["resident"]
		for i in placements.size():
			if resident[i] == null:
				var node := _make_collision_shape(placements[i], batch["radius"])
				resident[i] = node
				body.add_child(node)


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


# --- HARVEST-ALL / D60: chopped stays chopped, forever -----------------------


## Permanently remove one harvestable placement — the render instance, its
## collider (if the layer has one) and this gather point's own node — and
## mark it in `_harvested` so it never comes back, including on the next
## boot. Called by `vegetation_harvest_point.gd::_on_gathered()` once the
## resource has actually been granted (never speculatively — a refused
## gather, wrong tool or a full satchel, must leave the tree standing).
##
## Idempotent by construction: the bit-already-set guard below means calling
## this twice for the same placement (a double interact-press race, or
## `restore_from_game()` re-applying a bit that a live chop already set)
## does nothing the second time, rather than double-freeing a node or
## double-decrementing a counter.
func harvest_permanently(layer_name: String, index: int) -> void:
	var key := "%s#%d" % [layer_name, index]
	if not _harvest_lookup.has(key):
		return
	var bytes: PackedByteArray = _harvested.get(layer_name, PackedByteArray())
	if bytes.is_empty() or _bit_get(bytes, index):
		return
	_bit_set(bytes, index)
	_harvested[layer_name] = bytes

	var info: Dictionary = _harvest_lookup[key]
	_harvest_lookup.erase(key)
	_remove_render_instance(int(info.get("mesh_id", -1)), info.get("position", Vector3.ZERO))
	_remove_collision_instance(key)

	if _harvest_nodes.has(key):
		(_harvest_nodes[key] as Node).queue_free()
		_harvest_nodes.erase(key)

	_placed = maxi(0, _placed - 1)
	_harvest_points = maxi(0, _harvest_points - 1)


## See `HARVEST_REMOVE_RADIUS`'s own comment for why this is safe: called only
## at the placement's own exact stored position, never a player-aimed point.
func _remove_render_instance(mesh_id: int, position: Vector3) -> void:
	if mesh_id < 0 or _instancer == null:
		return
	_instancer.call("remove_instances", position, {
		"asset_id": mesh_id,
		"modifier_shift": false,
		"modifier_alt": false,
		"size": HARVEST_REMOVE_RADIUS,
		"strength": 100.0,
		"slope": Vector2(0.0, 90.0),
		"on_collision": false,
		"raycast_height": 10.0,
	})
	_instancer.call("update_mmis", true)


## Drops this placement's `CollisionShape3D` (if one was resident) and
## removes it from its batch's `placements`/`resident` arrays entirely, so
## `update_collision_streaming()` never tries to stream it back in.
func _remove_collision_instance(key: String) -> void:
	if not _harvest_collision_lookup.has(key):
		return
	var batch: Dictionary = _harvest_collision_lookup[key]
	_harvest_collision_lookup.erase(key)
	var placements: Array = batch["placements"]
	var resident: Array = batch["resident"]
	for i in placements.size():
		var p: Dictionary = placements[i]
		if "%s#%d" % [str(p.get("harvest_layer", "")), int(p.get("harvest_index", -1))] != key:
			continue
		if resident[i] != null:
			(resident[i] as CollisionShape3D).queue_free()
		placements.remove_at(i)
		resident.remove_at(i)
		_solid = maxi(0, _solid - 1)
		return


## Applies whatever a save remembers as permanently chopped, on top of the
## fresh scatter `build()` always draws — mirrors `build_placer.gd`'s own
## `restore_from_game()`, called once after boot and again by
## `GameState.load_game` for a mid-session load (see that file's own group
## registration).
##
## Deliberately never "un-chops" anything: a bit set locally (this session's
## own chopping) that is ABSENT from the loaded save is left exactly as it
## is — chopped stays chopped is the owner's rule regardless of which save
## is loaded, not merely across a normal boot. Only bits the save has that
## this session does not yet reflect are applied.
func restore_from_game(game: Object) -> void:
	if game == null:
		return
	var saved: Variant = game.get("harvested_vegetation")
	if typeof(saved) != TYPE_DICTIONARY:
		return
	for layer_name: String in (saved as Dictionary).keys():
		if not _harvested.has(layer_name):
			continue  # this build's config has no such harvestable layer
		var raw := Marshalls.base64_to_raw(str((saved as Dictionary)[layer_name]))
		var current: PackedByteArray = _harvested[layer_name]
		if raw.size() != current.size():
			# The layer's placement count changed under this save (a config
			# edit, a seed bump) -- a bitset that no longer lines up index-
			# for-index with today's scatter cannot be trusted, the same
			# "discard rather than guess" rule map_state.gd's own grid
			# descriptor check uses for its fog-of-war bytes.
			continue
		var total: int = _harvest_layer_counts.get(layer_name, 0)
		for i in total:
			if _bit_get(raw, i):
				harvest_permanently(layer_name, i)


## The reverse of `restore_from_game()` — called by `GameState.save_game`
## right before it writes, mirroring `build_placer.gd::sync_state_to_game`.
func sync_state_to_game(game: Object) -> void:
	if game == null:
		return
	var out: Dictionary = {}
	for layer_name: String in _harvested.keys():
		out[layer_name] = Marshalls.raw_to_base64(_harvested[layer_name])
	game.set("harvested_vegetation", out)


## For tests and NOTES.md-style reporting: how many placements, across every
## harvestable layer, are permanently gone right now.
func harvested_count() -> int:
	var total := 0
	for layer_name: String in _harvested.keys():
		var bytes: PackedByteArray = _harvested[layer_name]
		var layer_total: int = _harvest_layer_counts.get(layer_name, 0)
		for i in layer_total:
			if _bit_get(bytes, i):
				total += 1
	return total


## For the survey's cost readout. Not a budget and not a gate — software
## rendering cannot measure frame time honestly (D06) — but "how much did we
## just put in the world" is worth being able to say out loud.
func stats() -> Dictionary:
	return {
		"instances": _placed,
		"batches": _draw_calls,
		"solid": _solid,
		"solid_resident": collision_resident_count(),
		"harvest_points": _harvest_points,
		"drained_out": drained_count(),
		"regrown": _regrown,
		"harvested_permanently": harvested_count(),
	}

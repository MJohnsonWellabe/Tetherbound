extends Node3D

## Authored prop clusters, placed from data/config/props.json.
##
## Same shape as village.gd's structures: data describes, code places, and
## nothing is saved into a scene. Unlike the farm buildings (raw .obj meshes),
## the Fantasy Props MegaKit imports as glTF scenes, so each entry is
## instantiated as a scene rather than loaded as a bare Mesh -- this also
## means a multi-part model keeps its parts, instead of vegetation.gd's
## flatten-to-first-mesh shortcut (fine for scattered grass, wrong for an
## authored prop someone is meant to look at). A collider is still built from
## the combined mesh AABB, the same reasoning village.gd gives: a crate you
## can walk through is a hologram.

const PROPS_DIR := "res://assets/props/quaternius_fantasy"
const CONFIG_PATH := "res://data/config/props.json"

## BAND-SPLIT. The `clusters` array is cut per corridor band under
## `data/config/bands/<band>/props.json` and merged back here.
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const CAMPFIRE_GLOW := preload("res://scripts/world/campfire_glow.gd")
## SITE-DRESSING: `apply_retint` is a general-purpose material-name ->
## colour recolour, already shipped for village.gd's building prefabs
## (`retint` in village.json — see building_prefabs.gd's own header). It
## needs no recipe/template state, only its own `_tinted` cache, so one
## shared instance here gives props.json entries the same lever for the one
## case a loose prop needs it: an oxblood Team Tether banner at an occupied
## site, without sourcing or generating a second banner mesh.
const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
## T5-CADENCE. A cluster MAY carry a `rest` block, which turns an authored camp
## from a mesh arrangement into a place the player can actually sleep and
## craft. See `rest_point.gd`'s own header for what that offers and for the
## audit finding it closes; this file's only job is to notice the key.
const REST_POINT := preload("res://scripts/world/rest_point.gd")

var _placed := 0
var _rest_points := 0
var _prefabs: RefCounted = null


func build() -> void:
	var parsed: Dictionary = BAND_CONTENT.load_config(CONFIG_PATH, "clusters")
	if parsed.is_empty():
		push_error("props.json missing; the settlement has no prop clusters")
		return

	for cluster: Variant in parsed.get("clusters", []):
		if not cluster is Dictionary:
			continue
		var cluster_name := str((cluster as Dictionary).get("name", "cluster"))
		var group := Node3D.new()
		group.name = cluster_name
		add_child(group)
		for entry: Variant in (cluster as Dictionary).get("props", []):
			if entry is Dictionary:
				place(group, entry as Dictionary)
		# After the props, not before: the rest point samples ground the same
		# way they do, and building it last keeps the camp's own meshes ahead
		# of it in the tree so a probe or a remote tree reads the site in the
		# order it was authored.
		var rest: Variant = (cluster as Dictionary).get("rest", {})
		if rest is Dictionary and not (rest as Dictionary).is_empty():
			var point: Node3D = REST_POINT.new()
			point.name = "%s_Rest" % cluster_name
			group.add_child(point)
			point.call("build", rest as Dictionary)
			_rest_points += 1
	print("[props] placed %d props in %d clusters (%d usable rest points)"
		% [_placed, parsed.get("clusters", []).size(), _rest_points])


## How many authored camps stood up a working rest offer this run. Read by
## `tests/smoke_authored_camps.gd`, which is the difference between "the data
## says these camps are rest points" and "the world built them".
func rest_points() -> int:
	return _rest_points


func placed() -> int:
	return _placed


## One prop from one spec: `model`, `at` (WORLD metres [x, z]), and the
## optional `yaw_deg`/`pitch_deg`/`roll_deg`/`scale`/`sink_m` documented
## inline below.
##
## Public, and called from outside this file by exactly one other place:
## `burrow_warrens.gd::_build_dressing()`, which stands its own instance of
## this script up as a `top_level` child of the cave so that `_ground_height()`
## below walks up into the WARRENS' `ground_height_at()` -- the cave floor --
## instead of the hillside now several metres overhead. Reused rather than
## re-implemented because the collider-from-combined-AABB and the `sink_m`
## reasoning below are the two things a second copy would get subtly wrong,
## and a crate you can walk through is a hologram underground too.
func place(into: Node3D, spec: Dictionary) -> void:
	var model := str(spec.get("model", ""))
	# `dir` (optional, default PROPS_DIR): BAND1-D1. Every prop cluster before
	# this pass only ever named a bare quaternius_fantasy filename, so that
	# stays the default and every existing entry is untouched. A cluster that
	# needs an asset from a different installed pack (quaternius_survival's
	# Bonfire, quaternius_furniture's Stool, stylized_nature's RockPath/scatter
	# props, quaternius_castle's Banner) names its own `dir` instead of forcing
	# every band onto one folder or duplicating assets into quaternius_fantasy.
	# This is CLAUDE.md's "one prop family" read as one INSTALLED prop family
	# (nothing new is generated or sourced), not one folder.
	var dir := str(spec.get("dir", PROPS_DIR))
	var gltf_path := "%s/%s.gltf" % [dir, model]
	var glb_path := "%s/%s.glb" % [dir, model]
	var obj_path := "%s/%s.obj" % [dir, model]

	var root: Node3D = null
	if ResourceLoader.exists(gltf_path):
		var packed: PackedScene = load(gltf_path) as PackedScene
		if packed == null:
			push_error("prop failed to load as a scene: %s" % gltf_path)
			return
		root = packed.instantiate()
	elif ResourceLoader.exists(glb_path):
		# .glb is the same glTF format as .gltf, just binary -- the corridor's
		# own environment/nature kit (log.glb, grass_*.glb) ships this way.
		var packed: PackedScene = load(glb_path) as PackedScene
		if packed == null:
			push_error("prop failed to load as a scene: %s" % glb_path)
			return
		root = packed.instantiate()
	elif ResourceLoader.exists(obj_path):
		# OBJ ships as a bare Mesh, not a scene -- the same fallback
		# building_prefabs.gd::_build_template already uses for the castle
		# kit (its own comment: "the castle kit ships OBJ+MTL, not glTF").
		# Wrapped in a MeshInstance3D so the rest of this function (the
		# combined-AABB collider build below) sees the same node shape a
		# glTF scene's root would give it.
		var mesh: Mesh = load(obj_path) as Mesh
		if mesh == null:
			push_error("prop failed to load as a mesh: %s" % obj_path)
			return
		var mi := MeshInstance3D.new()
		mi.name = model
		mi.mesh = mesh
		root = mi
	else:
		push_error("prop missing: %s (looked for .gltf/.glb/.obj under %s)" % [model, dir])
		return

	# GF-B-010's rule, applied to props: a surface that imports as metal with
	# no metallic texture to modulate it is a glTF export omission, and renders
	# as a black silhouette in daylight. See `imported_materials.gd`'s header --
	# it is also, on the evidence, why `ralph/BLOCKED.md` records the
	# `environment/nature` pack as not rendering correctly through this
	# function. A no-op for every pack that ships an ORM map, which is most of
	# them.
	IMPORTED_MATERIALS.make_dielectric(root)

	var at: Array = spec.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var ground := _ground_height(x, z)
	if is_nan(ground):
		push_error("no ground under prop '%s' at %.0f, %.0f" % [model, x, z])
		return

	var scale_factor := float(spec.get("scale", 1.0))
	# `scale_xyz` (optional, [sx, sy, sz]): a non-uniform override for
	# `scale`. Round 4's firewood pile needed to go "half as tall, twice as
	# wide" against its own generated proportions -- a shape correction no
	# single uniform number can express -- and every other placement math
	# below (collider box, sink) already worked in a full Vector3, so this
	# is the one line that needed to stop assuming uniform scale rather than
	# a new mechanism.
	var scale_xyz_raw: Variant = spec.get("scale_xyz", null)
	var scale_vec: Vector3 = (Vector3(float(scale_xyz_raw[0]), float(scale_xyz_raw[1]), float(scale_xyz_raw[2]))
		if scale_xyz_raw is Array and (scale_xyz_raw as Array).size() == 3
		else Vector3.ONE * scale_factor)
	# `name` (optional, default the model name): Godot silently auto-renames
	# same-named siblings to `@Node3D@25876`-style ids, which is invisible in
	# the world and useless in a probe or a remote tree the moment one cluster
	# uses the same model twice. A caller that places several of one model in
	# one parent -- burrow_warrens.gd's cave dressing does -- passes its own.
	#
	# GATE-D: both halves of this block landed in different lanes (D1's
	# scale_xyz, D2's name) and neither replaces the other.
	root.name = str(spec.get("name", model))
	# `sink_m` (optional, default 0): extra downward offset below the sampled
	# ground height. Most of the pack's models embed only a few centimetres at
	# their own authored origin (EV7-clusters-fix probe:
	# tools/_probe_ev7fix.gd -- Crate_Wooden embeds just 0.052m), which is
	# shallower than this meadow's grass card height, so a shallow-buried
	# crate reads as floating with grass lit up under its own skirt rather
	# than resting on the ground. Sinking it a little further (like
	# village.gd's own -0.05 "never hovers on a residual slope" sink for
	# buildings) buries that gap without touching grass density itself.
	var sink := float(spec.get("sink_m", 0.0))
	root.position = Vector3(x, ground - sink, z)
	# `pitch_deg`/`roll_deg` (optional, default 0): most props in this pack
	# are authored to stand or lie flat on their own, so yaw-only placement
	# has been enough -- but a couple (Axe_Bronze) are authored vertical with
	# no way to rest them at an angle using yaw alone. Full Euler rotation
	# (Godot's default order) lets one lean against another prop instead of
	# always standing bolt upright.
	root.rotation = Vector3(
		deg_to_rad(float(spec.get("pitch_deg", 0.0))),
		deg_to_rad(float(spec.get("yaw_deg", 0.0))),
		deg_to_rad(float(spec.get("roll_deg", 0.0))))
	root.scale = scale_vec
	into.add_child(root)

	# `retint` (optional): a material-name -> colour map, applied the same
	# way village.gd's own building prefabs use it (building_prefabs.gd::
	# apply_retint). Every prop here shares one prop family (D24); this is
	# for the rare site that needs one PIECE of that shared family to read
	# as a different faction's without sourcing or generating a second mesh
	# -- SITE-DRESSING's oxblood Team Tether banner at the picket-hess
	# checkpoint is the first user. Values are colour strings ("#7a2430")
	# keyed by the mesh's own material resource_name, exactly like
	# village.json's `retint` blocks.
	var retint: Variant = spec.get("retint", {})
	if retint is Dictionary and not (retint as Dictionary).is_empty():
		if _prefabs == null:
			_prefabs = PREFABS.new()
		_prefabs.call("apply_retint", root, retint)

	# `glow` (optional): BAND1-D1. A log mesh with no emissive material
	# (assets/props/quaternius_survival/Bonfire*.mtl carries Ke 0 0 0 on every
	# surface) reads as unlit cargo, not a fire, and is invisible as a landmark
	# from any distance. `"campfire"` is the only value read today: it lights
	# the mesh's own `Fire` surface if it has one, and attaches the light,
	# ember and smoke overlay `campfire_glow.gd` owns.
	#
	# The overlay is counter-scaled out of `root`'s own scale on purpose.
	# BAND1-D1 round 2 shipped the opposite rule ("entries using this should
	# keep scale_factor at 1.0") and it was wrong twice over: the Bonfire is
	# authored at 2.2m across, so a believable campfire MUST be scaled down,
	# and shrinking a 4.6m smoke column by the same factor is exactly what
	# made the camp unfindable from the trail. The glow's sizes are absolute
	# metres; the prop's scale is the prop's business.
	# `"flame_mesh"` (round 5 follow-up): the prop IS a whole generated flame
	# sculpt (camp_flame.glb), not a log pile with one small Fire surface --
	# `ignite_mesh` lights every surface from its own baked texture instead
	# of one named one, and the light/embers/smoke overlay is built without
	# its billboard halo, since a real flame mesh under it made the halo
	# redundant rather than additive (see campfire_glow.gd's own comment on
	# `include_halo`).
	var glow := str(spec.get("glow", ""))
	if glow == "campfire":
		var lit := CAMPFIRE_GLOW.ignite(root)
		if lit == 0:
			push_warning("prop '%s' has glow:\"campfire\" but no `Fire` surface to light" % model)
		CAMPFIRE_GLOW.texture_logs(root)
		# `glow_scale` (optional, default 1.0): E4-CAMP-CLUSTERING. Grows the
		# light range/energy and the ember particles without touching the log
		# mesh's own `scale` -- see campfire_glow.gd's own `_glow_scale` note.
		# 1.0 keeps every existing campfire in the chapter pixel-identical;
		# `ridge_patrol_camp` is the one site that passes anything else.
		var glow_scale := float(spec.get("glow_scale", 1.0))
		var overlay: Node3D = CAMPFIRE_GLOW.new(true, 1.0, glow_scale)
		if not is_zero_approx(scale_factor):
			overlay.scale = Vector3.ONE / scale_factor
		root.add_child(overlay)
	elif glow == "flame_mesh":
		CAMPFIRE_GLOW.ignite_mesh(root, 0.5, true)
		var overlay: Node3D = CAMPFIRE_GLOW.new(false)
		if not is_zero_approx(scale_factor):
			overlay.scale = Vector3.ONE / scale_factor
		root.add_child(overlay)

	var meshes: Array[MeshInstance3D] = []
	_collect(root, meshes)
	if meshes.is_empty():
		push_warning("prop '%s' has no mesh; placed with no collider" % model)
		_placed += 1
		return

	# Meshes may sit under intermediate transform nodes the glTF importer adds,
	# so this reads each one's GLOBAL transform (valid immediately -- `root`
	# is already parented into the tree above) and un-does root's own
	# transform, leaving the combined bounds in root's local, unscaled,
	# unrotated space -- the same space village.gd's OBJ meshes get for free.
	var to_root_local: Transform3D = root.global_transform.affine_inverse()
	var aabb: AABB = to_root_local * (meshes[0].global_transform * meshes[0].get_aabb())
	for i in range(1, meshes.size()):
		aabb = aabb.merge(to_root_local * (meshes[i].global_transform * meshes[i].get_aabb()))

	var body := StaticBody3D.new()
	body.name = "%s_Collision" % root.name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * scale_vec
	shape.shape = box
	body.add_child(shape)
	body.position = root.global_transform * (aabb.position + aabb.size * 0.5)
	body.rotation = root.rotation
	into.add_child(body)
	_placed += 1


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)


func _ground_height(x: float, z: float) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", x, z))
		node = node.get_parent()
	return NAN

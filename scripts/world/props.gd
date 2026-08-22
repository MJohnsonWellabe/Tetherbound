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

var _placed := 0


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
				_place(group, entry as Dictionary)
	print("[props] placed %d props in %d clusters" % [_placed, parsed.get("clusters", []).size()])


func placed() -> int:
	return _placed


func _place(into: Node3D, spec: Dictionary) -> void:
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

	var at: Array = spec.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var ground := _ground_height(x, z)
	if is_nan(ground):
		push_error("no ground under prop '%s' at %.0f, %.0f" % [model, x, z])
		return

	var scale_factor := float(spec.get("scale", 1.0))
	root.name = model
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
	root.scale = Vector3.ONE * scale_factor
	into.add_child(root)

	# `glow` (optional): BAND1-D1 coordinator directive -- a static log mesh
	# with no baked emissive material (checked: assets/props/quaternius_survival/
	# Bonfire*.mtl carries Ke 0 0 0 on every surface) reads as unlit cargo, not
	# a fire, and is invisible as a landmark from any distance. `"campfire"` is
	# the only value read today; CAMPFIRE_GLOW attaches under `root` so it
	# inherits the prop's own ground position (and rotation/scale -- entries
	# using this should keep scale_factor at 1.0, since the glow's own sizes
	# are tuned for that).
	var glow := str(spec.get("glow", ""))
	if glow == "campfire":
		root.add_child(CAMPFIRE_GLOW.new())

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
	body.name = "%s_Collision" % model
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * scale_factor
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

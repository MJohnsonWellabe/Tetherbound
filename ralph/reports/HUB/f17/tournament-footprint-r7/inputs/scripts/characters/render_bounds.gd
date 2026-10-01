extends RefCounted

## Measure a model the way the RENDERER will draw it, in the space of a chosen
## root node.
##
## This class exists because the project shipped a 180-metre trainer while
## every test said 1.80m, and the reason is worth stating once, here, where the
## fix lives:
##
## A SKINNED mesh is not drawn where its MeshInstance3D's transform chain says.
## The renderer computes each vertex as
##
##     skeleton_global × bone_pose × inverse_bind × vertex
##
## so the MeshInstance's own chain — the thing `get_aabb()` compositions walk —
## is simply not part of the picture. The three human models (trainer, Grandpa,
## the Warden) carry two compensations that cancel at scale 1.0: vertices in
## metres, inverse-bind matrices ×100 into a centimetre skeleton, and a 0.01
## Armature node. Measuring the mesh AABB through the node chain crosses the
## 0.01 but never sees the skin's ×100, reads 0.018m, and "corrects" a model
## that was already the right size — blowing the skinned render up by exactly
## the factor the measurement missed. The 17 creature models are authored with
## both factors at 1.0, which is why only the humans ever rendered wrong.
##
## At rest pose, bone_pose × inverse_bind collapses to one uniform transform
## (rest == bind for every rig this project produces), so the render-space box
## of a skinned mesh is the bind AABB pushed through the SKELETON's chain and
## that collapsed skin transform. That is what this measures. Unskinned meshes
## keep the plain node-chain measurement, which is correct for them.
##
## Everything here reads LOCAL transforms only, never `global_transform`:
## global is only valid once the node is in the tree and propagation has run,
## and callers measure on the line after `add_child()`. That race is how the
## first giant-trainer fix (1ebd434) picked the wrong branch to trust.


## The composite render-space AABB of every visible mesh under `root`,
## expressed in `root`'s own space (root's transform excluded, matching what a
## caller needs to scale/offset `root` itself). A zero-size AABB means nothing
## measurable was found.
static func measure(root: Node3D) -> AABB:
	var box := AABB()
	var started := false
	for mesh in _mesh_instances(root):
		var local: AABB = _render_transform(mesh, root) * mesh.mesh.get_aabb()
		if started:
			box = box.merge(local)
		else:
			box = local
			started = true
	return box


## The transform that carries this mesh's RESOURCE-space AABB into `root`'s
## space as the renderer will draw it.
static func _render_transform(mesh: MeshInstance3D, root: Node3D) -> Transform3D:
	var skeleton := _skeleton_for(mesh)
	if skeleton == null or mesh.skin == null:
		return _chain(mesh, root)
	var collapsed := _collapsed_skin(mesh.skin, skeleton)
	return _chain(skeleton, root) * collapsed


## bone_rest × inverse_bind for the skin's first resolvable bind — the uniform
## mesh-space → skeleton-space transform at rest pose. Identity when nothing
## resolves, which degrades to "trust the skeleton chain alone".
static func _collapsed_skin(skin: Skin, skeleton: Skeleton3D) -> Transform3D:
	for i in skin.get_bind_count():
		var bone := skin.get_bind_bone(i)
		if bone < 0:
			bone = skeleton.find_bone(skin.get_bind_name(i))
		if bone < 0 or bone >= skeleton.get_bone_count():
			continue
		return skeleton.get_bone_global_rest(bone) * skin.get_bind_pose(i)
	return Transform3D()


static func _skeleton_for(mesh: MeshInstance3D) -> Skeleton3D:
	# The instance names its own skeleton (the `skeleton` NodePath); trust that
	# first.
	var named := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
	if named != null:
		return named
	# Otherwise the nearest ancestor, which is where every importer puts it.
	var node: Node = mesh.get_parent()
	while node != null:
		if node is Skeleton3D:
			return node as Skeleton3D
		node = node.get_parent()
	return null


## Local-transforms-only chain from `from` up to, and excluding, `root`.
static func _chain(from: Node3D, root: Node3D) -> Transform3D:
	var chain := Transform3D()
	var node: Node3D = from
	while node != null and node != root:
		chain = node.transform * chain
		node = node.get_parent() as Node3D
	return chain


static func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null and (node as MeshInstance3D).visible:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found

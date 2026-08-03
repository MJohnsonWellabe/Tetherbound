extends Node3D

## Renders the scatter.
##
## One MultiMeshInstance3D per source model, so several thousand props cost a
## handful of draw calls rather than several thousand. This is what makes the
## meadow survivable on a handheld; instancing is not an optimisation to add
## later, it is the only way this layer can exist at all.
##
## Where things go is decided by scripts/world/scatter_rules.gd, which is pure
## and tested. This file knows about meshes and nothing about ecology.
##
## Terrain3D ships its own instancer (`Terrain3DInstancer`) which additionally
## streams per region. Deliberately not used yet: MultiMesh is engine-standard,
## has no extension-version risk, and a 512m playground does not need streaming.
## The upgrade path is real and is a swap of this file alone.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

## Props are sunk very slightly so their bases never float over a slope. The
## terrain under a prop is sampled at a single point, but the prop has width.
const SINK := 0.06

var _placed: int = 0
var _draw_calls: int = 0


## Build the whole scatter. `world_size` should match the terrain's.
func build(world_size: float) -> void:
	for child in get_children():
		child.queue_free()
	_placed = 0
	_draw_calls = 0
	_tints.clear()

	var cfg: Dictionary = RULES.config()
	if cfg.is_empty():
		return
	var field: RefCounted = HEIGHTFIELD.new()
	var by_layer: Dictionary = RULES.all_placements(field, world_size, int(cfg.get("seed", 1)))

	# Grouped by MODEL rather than by layer: two layers sharing a mesh should
	# share one MultiMesh, or the draw-call saving is thrown away by the
	# bookkeeping.
	var by_model: Dictionary = {}
	for layer_name: String in by_layer.keys():
		for entry: Variant in (by_layer[layer_name] as Array):
			var placement: Dictionary = entry
			var model := str(placement["model"])
			if not by_model.has(model):
				by_model[model] = []
			(by_model[model] as Array).append(placement)

	for model: String in by_model.keys():
		_build_batch(model, by_model[model])


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
func _retint(mesh: Mesh) -> Mesh:
	var map: Dictionary = RULES.config().get("retint", {})
	if map.is_empty():
		return mesh

	var out := ArrayMesh.new()
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var source: Material = mesh.surface_get_material(surface)
		var key := "" if source == null else source.resource_name
		out.surface_set_material(surface, _tint_for(key, source))
	return out


func _tint_for(name: String, source: Material) -> Material:
	if _tints.has(name):
		return _tints[name]
	var map: Dictionary = RULES.config().get("retint", {})
	var material := StandardMaterial3D.new()
	if map.has(name):
		material.albedo_color = Color(str(map[name]))
	elif source is StandardMaterial3D:
		# Unmapped materials keep their original colour rather than turning
		# white, so adding a model from the pack degrades to "slightly off"
		# instead of "glowing".
		material.albedo_color = (source as StandardMaterial3D).albedo_color
	material.roughness = 0.94
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_tints[name] = material
	return material


func _build_batch(model_path: String, placements: Array) -> void:
	var mesh := _mesh_for(model_path)
	if mesh == null:
		push_error("scatter model %s could not be loaded; that layer will be missing" % model_path)
		return

	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _retint(mesh)
	multi.instance_count = placements.size()

	for i in placements.size():
		var placement: Dictionary = placements[i]
		var basis := Basis(Vector3.UP, float(placement["yaw"])).scaled(
			Vector3.ONE * float(placement["scale"])
		)
		var spot: Vector3 = placement["position"]
		multi.set_instance_transform(i, Transform3D(basis, spot - Vector3.UP * SINK))

	var node := MultiMeshInstance3D.new()
	node.name = model_path.get_file().get_basename()
	node.multimesh = multi
	# Props cast but do not receive: a grass tuft receiving a shadow from its
	# neighbour costs real time and reads as dirt at this scale.
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(node)

	_placed += placements.size()
	_draw_calls += 1


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


## For the survey's cost readout. Not a budget and not a gate — software
## rendering cannot measure frame time honestly (D06) — but "how much did we
## just put in the world" is worth being able to say out loud.
func stats() -> Dictionary:
	return {"instances": _placed, "batches": _draw_calls}

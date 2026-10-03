extends SceneTree

## Main-required F48 owner diagnosis, not paid-building acceptance. Production
## Altar uses BuildPiece/BookStand, not StationPiece's procedural Altar. Camera,
## placer startup and direct construction are disclosed component fixtures;
## no inventory, authority, transaction, flags or save state is injected.
const PLACER := preload("res://scripts/build/build_placer.gd")
const PIECE := preload("res://scripts/build/build_piece.gd")
var _failures: Array[String] = []
var _held: Array[Resource] = []

class ComponentPlacer extends PLACER:
	func _ready() -> void:
		set_physics_process(false)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		quit(2)
		return
	for treatment: String in ["baseline", "retain-active-resources"]:
		print("F19 ACTUAL ALTAR BEGIN " + JSON.stringify({"treatment": treatment,
			"acceptance": false, "paid_build": false}))
		var world := Node3D.new()
		root.add_child(world)
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.position = Vector3(0, 4, 8)
		camera.look_at(Vector3.ZERO)
		camera.current = true
		var placer := ComponentPlacer.new()
		world.add_child(placer)
		var path: String = placer.call("_piece_mesh", game, "altar")
		var scale_for_model: Vector3 = placer.call("_piece_scale", game, "altar")
		print("F19 ACTUAL ALTAR BOUNDS START " + treatment)
		var cfg := PLACER._altar_config(game)
		if path != "res://assets/props/quaternius_fantasy/BookStand.gltf" or cfg.is_empty():
			_failures.append("Production Altar catalogue/bounds config unavailable")
		print("F19 ACTUAL ALTAR BOUNDS " + JSON.stringify({"treatment": treatment,
			"path": path, "scale": str(scale_for_model), "config_present": not cfg.is_empty()}))
		placer.call("_ensure_overlay")
		placer.call("_set_overlay_visible", true)
		var ghost := PIECE.new()
		ghost.name = "ActualAltarGhost"
		ghost.build_ghost(path, scale_for_model)
		world.add_child(ghost)
		placer.set("_ghost", ghost)
		ghost.tint_ghost_state(PIECE.STATE_VALID)
		for frame in 3: await process_frame
		var placed := PIECE.new()
		placed.name = "ActualAltarPlaced"
		world.add_child(placed)
		placed.build_real(path, {}, scale_for_model)
		placed.position.x = 3
		for frame in 3: await process_frame
		# Actual placement keeps selection; its occupied footprint makes the
		# preview invalid before an explicit cancel drops that actual ghost.
		ghost.tint_ghost_state(PIECE.STATE_INVALID)
		_observe(world, treatment == "retain-active-resources")
		print("F19 ACTUAL ALTAR DROP GHOST " + treatment)
		placer.call("_drop_ghost")
		for frame in 3: await process_frame
		print("F19 ACTUAL ALTAR DELETE PLACED " + treatment)
		placed.queue_free()
		for frame in 3: await process_frame
		var overlay: Node = placer.get("_overlay")
		print("F19 ACTUAL ALTAR DELETE COMPONENT " + treatment)
		world.queue_free()
		if is_instance_valid(overlay): overlay.queue_free()
		for frame in 4: await process_frame
		_held.clear()
		for frame in 3: await process_frame
		print("F19 ACTUAL ALTAR END " + treatment)
	print("F19 ACTUAL ALTAR DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures}))
	quit(0 if _failures.is_empty() else 1)

func _observe(node: Node, retain: bool) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var materials: Array[String] = []
		if mesh_node.mesh != null:
			if retain: _held.append(mesh_node.mesh)
			for surface in mesh_node.mesh.get_surface_count():
				var material := mesh_node.get_active_material(surface)
				if material != null:
					materials.append(str(material.get_instance_id()))
					if retain: _held.append(material)
		for material: Material in [mesh_node.material_override, mesh_node.material_overlay]:
			if retain and material != null: _held.append(material)
		print("F19 ACTUAL ALTAR MESH " + JSON.stringify({"path": str(node.get_path()),
			"active_material_ids": materials, "retained": retain}))
	for child: Node in node.get_children(): _observe(child, retain)

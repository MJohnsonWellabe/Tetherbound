extends SceneTree

## Actual imported Altar/BuildMaterialFinish and generic BuildPiece teardown.
## Direct construction is a component fixture, not paid-placement acceptance.
## Snapshots contain string IDs only: no observer retains Material resources.
const PIECE := preload("res://scripts/build/build_piece.gd")
const MODEL := "res://assets/props/quaternius_fantasy/BookStand.gltf"
var _failures: Array[String] = []
var _checks := 0

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value: _failures.append(message)

func _snapshot(piece: Node3D) -> Array:
	var result: Array = []
	for mesh_instance: MeshInstance3D in piece.mesh_instances():
		var surfaces: Array = []
		for surface in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.get_surface_override_material(surface)
			surfaces.append(str(material.get_instance_id()) if material != null else "")
		result.append({"surfaces": surfaces,
			"tint": str(mesh_instance.material_override.get_instance_id())
				if mesh_instance.material_override != null else ""})
	return result

func _run() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	for mode: String in ["placed", "valid", "invalid", "unsupported"]:
		var piece := PIECE.new()
		holder.add_child(piece)
		if mode == "placed": piece.build_real(MODEL)
		else:
			piece.build_ghost(MODEL)
			piece.tint_ghost_state(StringName(mode))
		var original := _snapshot(piece)
		_check(original.size() == 1, mode + ": actual BookStand mesh")
		if not original.is_empty():
			_check(original[0].surfaces.size() == 1 and original[0].surfaces[0] != "",
				mode + ": private furniture finish present")
			_check((original[0].tint == "") == (mode == "placed"), mode + ": correct tint")
		for frame in 2: await process_frame
		# Ordinary exit/re-entry must keep the live finish and ghost state.
		holder.remove_child(piece)
		_check(_snapshot(piece) == original, mode + ": tree exit preserves materials")
		holder.add_child(piece)
		_check(_snapshot(piece) == original, mode + ": re-entry preserves materials")
		if mode != "placed": piece.tint_ghost_state(PIECE.STATE_INVALID)
		print("BUILD PIECE LIFETIME DELETE " + mode)
		piece.queue_free()
		for frame in 3: await process_frame
		_check(not is_instance_valid(piece), mode + ": piece freed")
	# Teardown is also safe before a model has been constructed.
	var empty := PIECE.new()
	holder.add_child(empty)
	empty.free()
	_check(not is_instance_valid(empty), "unbuilt piece freed")
	holder.queue_free()
	for frame in 3: await process_frame
	print("BUILD PIECE LIFETIME RESULT " + JSON.stringify({"checks": _checks, "failures": _failures,
		"paid_placement": false, "materials_retained_by_observer": false}))
	quit(0 if _failures.is_empty() else 1)

extends SceneTree

## Does the Sigil Gate have collision, and is it where the gap is?
##
##   godot --headless --path . --script tools/_probe_sigil_gate_body.gd
##
## Headless is correct here: this reads the scene tree and shape extents, and
## renders nothing.
##
## WHY THIS EXISTS. `tools/_probe_crossings.gd` proved the two Sigil gorges seal
## everything except a ~14m causeway at x=57..70 -- correctly, because that
## causeway is uncarved ground and what stops a player there is a PROP, which no
## heightfield can measure. `tests/smoke_traversal.gd` then reported "the Sigil
## Gate has no box collider; nothing would ever stop a player at it".
##
## That claim needs checking before it is believed, because the code says the
## opposite: `playground_world.gd::_build_sigil_gate` builds a `road_gate.gd`,
## and `road_gate.gd::build` makes a StaticBody3D with a CollisionShape3D
## holding a BoxShape3D. `SIGIL_GATE_AT` is (63.6, 7400) -- dead centre of the
## measured gap, so the SITING is right too.
##
## So either the gate fails to build (a real and serious defect: the chapter's
## finale gate would stop nobody), or the test's lookup misses a body that is
## there (this sweep's eighth harness defect). This sweep has already produced
## seven harness defects and one overturned "needs art" verdict, so the
## difference is worth one minute of headless world boot rather than a guess.
##
## It reports the shape's world extent as well as its existence, because a
## collider narrower than the 13m gap gates nothing -- `south_bridge.gd`'s own
## history records exactly that failure: "any deck the rails do not cover can be
## stepped onto from the side, and a gate inboard of that gap gates nothing."

const SCENE := "res://scenes/world/meadows_playground.tscn"
const GATE_AT := Vector2(63.6, 7400.0)
const GAP := Vector2(57.0, 70.0)   # the open causeway _probe_crossings measured


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 120:
		await physics_frame

	var found: Array = []
	for node in _all(world):
		if node is CollisionShape3D:
			var cs := node as CollisionShape3D
			if cs.shape == null:
				continue
			var at := cs.global_position
			if Vector2(at.x, at.z).distance_to(GATE_AT) <= 40.0:
				found.append(cs)

	print("=== collision shapes within 40m of the Sigil Gate at (%.1f, %.1f) ===" % [GATE_AT.x, GATE_AT.y])
	if found.is_empty():
		print("NONE. Nothing with collision stands anywhere near the gate.")
	for entry: Variant in found:
		var cs: CollisionShape3D = entry
		var at := cs.global_position
		var kind := cs.shape.get_class()
		var span := "?"
		if cs.shape is BoxShape3D:
			var size: Vector3 = (cs.shape as BoxShape3D).size * cs.global_transform.basis.get_scale()
			# The leaf is yawed, so its extent along world x is what decides
			# whether it covers the gap -- not its own local width.
			var half_x: float = absf(size.x * cos(cs.global_rotation.y)) * 0.5 \
				+ absf(size.z * sin(cs.global_rotation.y)) * 0.5
			span = "world-x %.1f .. %.1f (%.1f m wide)" % [at.x - half_x, at.x + half_x, half_x * 2.0]
		print("  %-26s %-14s disabled=%s at (%.1f, %.1f, %.1f)  %s" % [
			cs.get_parent().name, kind, str(cs.disabled), at.x, at.y, at.z, span])

	print("")
	print("The causeway _probe_crossings measured open: world-x %.1f .. %.1f" % [GAP.x, GAP.y])
	print("A collider must span that whole width, enabled, to gate anything.")
	quit(0)


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out

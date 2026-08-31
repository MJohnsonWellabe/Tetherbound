extends SceneTree

## Scratch probe, BACKLOG-E1-VILLAGE-DAYTIME. Finds whatever is standing near
## the tournament-ground stand ("01-village-tournament") that renders as an
## unexplained floating orange spark/flare in `_capture_locations.gd`'s day and
## night frames -- see ralph/reports/audit/E-2026-08-31.md §E1. The stand's own
## eye is (14,5) looking at (20,15) in world XZ (tools/_capture_locations.gd's
## "tournament" entry), so this dumps every Node3D within a generous radius of
## that sightline, headless (no renderer needed, this only reads the tree).
##
##   godot --headless --path . --script tools/_probe_tournament_spark.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BOOT_FRAMES := 90

var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[probe] world up, boot settled")

	var centre := Vector3(17.0, 0.0, 10.0)  # midpoint of eye(14,5) and look(20,15)
	var radius := 14.0
	var hits: Array = []
	_scan(_world, centre, radius, hits)
	hits.sort_custom(func(a, b): return a["dist"] < b["dist"])
	print("[probe] %d Node3D within %.1fm of (%.1f,%.1f)" % [hits.size(), radius, centre.x, centre.z])
	for h: Dictionary in hits:
		print("  %.2fm  %s  class=%s  pos=%s  visible=%s" % [
			h["dist"], h["path"], h["class"], h["pos"], h["visible"]])

	# Specifically call out anything particle- or sprite-shaped anywhere in the
	# whole world, regardless of distance, in case the emitter's own transform
	# sits far away but a billboard/particle draws toward the camera.
	print("[probe] --- all GPUParticles3D / CPUParticles3D / Sprite3D / GPUParticles3DAttractor in the tree ---")
	var special: Array = []
	_scan_classes(_world, special)
	for h: Dictionary in special:
		print("  %s  class=%s  pos=%s  visible=%s  emitting=%s" % [
			h["path"], h["class"], h["pos"], h["visible"], h["emitting"]])

	quit(0)


func _scan(node: Node, centre: Vector3, radius: float, hits: Array) -> void:
	if node is Node3D:
		var n3 := node as Node3D
		var pos := n3.global_position
		var flat_dist := Vector2(pos.x - centre.x, pos.z - centre.z).length()
		if flat_dist <= radius:
			hits.append({
				"dist": flat_dist,
				"path": str(node.get_path()),
				"class": node.get_class(),
				"pos": "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z],
				"visible": n3.visible,
			})
	for child in node.get_children():
		_scan(child, centre, radius, hits)


func _scan_classes(node: Node, out: Array) -> void:
	if node is GPUParticles3D or node is CPUParticles3D or node is Sprite3D:
		var n3 := node as Node3D
		var pos := n3.global_position
		var emitting: Variant = node.get("emitting") if node.has_method("get") else null
		out.append({
			"path": str(node.get_path()),
			"class": node.get_class(),
			"pos": "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z],
			"visible": n3.visible,
			"emitting": str(emitting),
		})
	for child in node.get_children():
		_scan_classes(child, out)

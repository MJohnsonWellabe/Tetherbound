extends SceneTree

## T1-PERF (2026-08-30). One-shot lookup of the Burrow Warrens' own world-space
## chamber markers, used to derive `tools/perf_site_survey.gd::ABSOLUTE_VIEWS`'
## `warrens_den` eye/look-at pair. The Warrens complex is sited+rotated
## (`data/config/burrow_warrens.json` `site.at`/`site.yaw_deg`) and hand-deriving
## a chamber's world position from that site transform is exactly the kind of
## yaw arithmetic this repo's own history (`stronghold.gd`'s re-derivation
## notes) warns is easy to get backwards -- `burrow_warrens.gd::marker()`
## already does it correctly, so this just asks the live built node for the
## answer instead of re-deriving it.
##
## Correct headless: reads no RENDER_* monitor.
##
##   godot --headless --path . --script tools/_probe_warrens_markers.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const MARKERS := ["entrance", "mouth", "warren", "hall", "den", "vault", "guardian"]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var warrens: Node = world.get_node_or_null(^"BurrowWarrens")
	if warrens == null:
		print("FAIL: no BurrowWarrens node")
		quit(1)
		return
	if not warrens.has_method("marker"):
		print("FAIL: BurrowWarrens has no marker() method")
		quit(1)
		return

	for key in MARKERS:
		if warrens.has_method("has_marker") and not bool(warrens.call("has_marker", key)):
			print("%-10s (no marker)" % key)
			continue
		var pos: Vector3 = warrens.call("marker", key)
		print("%-10s -> (%.3f, %.4f, %.3f)" % [key, pos.x, pos.y, pos.z])

	quit(0)

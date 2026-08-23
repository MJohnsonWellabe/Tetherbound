extends SceneTree

## GATE-E-STRONGHOLD-ART diagnostic (scratch): name the grey translucent
## rectangles on band4's `far-panels-*` horizons before touching anything.
## Builds rift_collapse.gd against the real configs with no scene load, prints
## each slab's world transform, and tests it against the exact cameras the
## band4 capture tool uses. Delete once the finding is recorded.

const RIFT := preload("res://scripts/world/rift_collapse.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const SHOTS := {
	"far-panels-east": [Vector3(-244.0, 6.5, 6462.0), Vector3(-100.0, 18.0, 6520.0), 22.0],
	"far-panels-north": [Vector3(415.0, 3.0, 6000.0), Vector3(300.0, 30.0, 6900.0), 22.0],
	"watchtower-spur": [Vector3(-205.0, 12.0, 6430.0), Vector3(-262.0, 4.0, 6482.0), 62.0],
	"ridge-patrol-camp": [Vector3(-244.0, 6.5, 6462.0), Vector3(-235.5, 3.5, 6472.0), 62.0],
	"field-camp-clearing": [Vector3(415.0, 3.0, 6000.0), Vector3(400.0, 0.0, 6040.0), 62.0],
	"ironwood-grove": [Vector3(-316.0, 4.5, 5046.0), Vector3(-343.0, 1.5, 5078.0), 62.0],
	"ironwood-camp-pad": [Vector3(-310.0, 5.0, 5115.0), Vector3(-334.0, 1.0, 5085.0), 62.0],
	# The seam itself -- the one viewpoint this effect was authored for.
	"storm-road-seam": [Vector3(-33.99, 8.0, 7513.46), Vector3(-37.06, 30.0, 7618.89), 62.0],
}


class FakeWorld:
	extends Node3D
	var field: RefCounted = null
	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


func _init() -> void:
	_run()


func _run() -> void:
	var world := FakeWorld.new()
	world.field = HEIGHTFIELD.new()
	root.add_child(world)

	var rift: Node3D = RIFT.new()
	rift.name = "RiftCollapse"
	world.add_child(rift)
	rift.call("build", world)

	# Global transforms are only real once the nodes are actually inside the
	# tree -- reading them straight out of build() returns Transform3D() and
	# every distance below comes out measured from the origin.
	await process_frame
	await process_frame

	var meshes: Array = rift.call("meshes")
	print("slabs built: %d" % meshes.size())
	for instance: MeshInstance3D in meshes:
		var mesh := instance.mesh as QuadMesh
		var mat := instance.material_override as StandardMaterial3D
		print("  %-14s at (%.1f, %.1f, %.1f)  size %.0fx%.0f  alpha %.2f  vis=%s  fog_off=%s  range_end=%.0f" % [
			instance.name, instance.global_position.x, instance.global_position.y,
			instance.global_position.z, mesh.size.x, mesh.size.y,
			mat.albedo_color.a, instance.visible, mat.disable_fog,
			instance.visibility_range_end,
		])

	print("")
	print("visibility from each capture viewpoint (camera.far = 2000):")
	for name: String in SHOTS.keys():
		var spec: Array = SHOTS[name]
		var eye: Vector3 = spec[0]
		var target: Vector3 = spec[1]
		var fov: float = float(spec[2])
		var forward := (target - eye).normalized()
		print("  %s:" % name)
		for instance: MeshInstance3D in meshes:
			if not instance.visible:
				continue
			var to := instance.global_position - eye
			var distance := to.length()
			var angle := rad_to_deg(forward.angle_to(to.normalized()))
			var mesh := instance.mesh as QuadMesh
			var radius := rad_to_deg(atan2(maxf(mesh.size.x, mesh.size.y) * 0.5, distance))
			var half_fov := fov * 0.5 * 1.4
			var culled_by_range := (instance.visibility_range_end > 0.0
				and distance > instance.visibility_range_end)
			var on_screen := (distance < 2000.0 and angle - radius < half_fov
				and not culled_by_range)
			print("    %-14s d=%6.0fm  off-axis %5.1f deg (radius %4.1f)  ON SCREEN: %s" % [
				instance.name, distance, angle, radius, on_screen,
			])
	quit(0)

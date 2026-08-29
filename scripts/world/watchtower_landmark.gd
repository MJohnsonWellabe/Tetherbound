extends Node3D

## T3-BAND4: a ruined watchtower on the Upper Meadows' own wind ridge --
## spec's Band 4 area list already names "ruined watchtower" as part of this
## region's identity (docs/MEADOWS_PROGRESSION_SPEC.md section 3) and nothing
## had ever built it. Sited at the band4->band5 seam, the chapter's second
## worst authored-content gap (852m, ralph/reports/
## finding-post-tournament-cadence-2026-08-29.md): after Captain Vess the
## route runs empty until the Stronghold Approach picks up again, and a
## broken tower on the skyline is the "anticipate something clearly visible
## ahead" beat the owner's cadence rule (docs/owner-direction/
## TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md section 12) asks for -- seen
## from well past the corridor probe's own 30m notice radius, same as the
## Stronghold silhouette itself.
##
## Placeholder geometry, same house rule `signpost.gd` and the old
## `landmark.gd` history both document: primitives are fine to prove a beat
## exists, and CLAUDE.md reserves a real Meshy generation for Team Tether
## hero objects with owner-supplied reference, which this is not. Ownership
## split for this pass (the finding's own brief): this lane places the
## landmark and its reward, the visual lane (T1-REGIONS) owns presentation --
## so the shape below is deliberately plain and easy to replace wholesale
## without touching siting, collision or the reward pickup beside it.
##
## Ground-snaps at `at` the same way every other world structure does
## (`world.call("ground_height_at", ...)`, never a raycast -- D09's rule).

const RING_SEGMENTS := 10
const DRUM_HEIGHT := 4.2
const DRUM_RADII := [3.4, 3.0, 2.6]
const BROKEN_TOP_HEIGHT := 2.6
const STONE_COLOUR := Color("#6b6258")
const RUBBLE_COLOUR := Color("#54493f")


func build(world: Node, at: Vector2, facing_deg: float) -> void:
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the watchtower at %.0f, %.0f" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)
	rotation.y = deg_to_rad(facing_deg)

	var stone := StandardMaterial3D.new()
	stone.albedo_color = STONE_COLOUR
	stone.roughness = 0.95

	var body := StaticBody3D.new()
	body.name = "TowerBody"
	add_child(body)

	var y := 0.0
	for i in DRUM_RADII.size():
		var radius: float = DRUM_RADII[i]
		var drum := MeshInstance3D.new()
		drum.name = "Drum%d" % i
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius * 0.94
		mesh.bottom_radius = radius
		mesh.height = DRUM_HEIGHT
		mesh.radial_segments = RING_SEGMENTS
		mesh.material = stone
		drum.mesh = mesh
		drum.position = Vector3(0.0, y + DRUM_HEIGHT * 0.5, 0.0)
		add_child(drum)

		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = DRUM_HEIGHT
		shape.shape = cyl
		shape.position = drum.position
		body.add_child(shape)

		y += DRUM_HEIGHT

	# The broken top: one more short drum, off-axis and truncated, so the
	# silhouette reads as collapsed rather than merely short. Not collidable
	# -- it overhangs the walkable footprint below and nothing needs to climb
	# it.
	var broken := MeshInstance3D.new()
	broken.name = "BrokenTop"
	var broken_mesh := CylinderMesh.new()
	broken_mesh.top_radius = DRUM_RADII[-1] * 0.55
	broken_mesh.bottom_radius = DRUM_RADII[-1] * 0.9
	broken_mesh.height = BROKEN_TOP_HEIGHT
	broken_mesh.radial_segments = RING_SEGMENTS
	broken_mesh.material = stone
	broken.mesh = broken_mesh
	broken.position = Vector3(0.6, y + BROKEN_TOP_HEIGHT * 0.5 - 0.3, 0.3)
	broken.rotation = Vector3(deg_to_rad(9.0), 0.0, deg_to_rad(-6.0))
	add_child(broken)

	_build_rubble(body)


## A scatter of fallen blocks at the base -- the same "a place shows what
## happened to it" logic `landmark.gd`'s occupation dressing and the band
## camp-prop clusters use, cheap enough to be a handful of boxes rather than
## a new prop family.
func _build_rubble(body: StaticBody3D) -> void:
	var rubble_mat := StandardMaterial3D.new()
	rubble_mat.albedo_color = RUBBLE_COLOUR
	rubble_mat.roughness = 0.95

	var blocks := [
		{"at": Vector3(3.9, 0.0, 1.4), "size": Vector3(1.1, 0.9, 1.0), "yaw": 18.0},
		{"at": Vector3(-3.6, 0.0, -1.8), "size": Vector3(1.4, 0.7, 1.2), "yaw": -32.0},
		{"at": Vector3(2.1, 0.0, -3.6), "size": Vector3(0.9, 0.6, 0.9), "yaw": 55.0},
	]
	for entry: Dictionary in blocks:
		var at: Vector3 = entry["at"]
		var size: Vector3 = entry["size"]
		var block := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = rubble_mat
		block.mesh = mesh
		block.position = at + Vector3(0.0, size.y * 0.5, 0.0)
		block.rotation.y = deg_to_rad(float(entry["yaw"]))
		add_child(block)

		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		shape.position = block.position
		shape.rotation.y = block.rotation.y
		body.add_child(shape)

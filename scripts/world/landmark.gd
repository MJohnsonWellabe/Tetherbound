extends Node3D

## The stronghold silhouette on the ridge.
##
## R7.1: M7 asks for a distant landmark so the far edge of the map reads as a
## destination instead of a fence — the site-frames critique's "world ends
## 40m out" complaint named the horizon specifically. This is that landmark,
## not the stronghold itself: R8.2 authors the real approach and interior
## once Meadows is further along. Placeholder geometry is deliberate — a
## silhouette only has to read as a shape against the sky at ~170m, and
## CLAUDE.md is explicit that placeholder is fine to prove composition; the
## stronghold's own presentation still needs real art before it is judged.
##
## Built from primitives rather than a model: nothing in either vendored
## asset pack (quaternius_farm, stylized_nature) is a ruin or tower, and a
## silhouette's whole job is a dark, angular shape on the skyline, which a
## handful of tall cylinders already do at this distance.

const RISE_CENTRE := Vector2(140.0, -90.0)
## A few metres off the true peak so the towers do not have to fight the
## rise's own steepest ground for footing.
const OFFSET := Vector2(-6.0, 8.0)

const TOWER_COLOUR := Color("#2a2630")

## R7.1-visual: the blind critic (docs/decisions — see this task's ralph
## record) found the towers read correctly dark up close (~40m) but faded to
## a pale grey nearly matching the horizon haze at ~60m and ~157m — measured
## by re-rendering the same viewpoint with WorldEnvironment.fog_enabled
## forced false, which restored the dark silhouette. That is the world's
## shared fog (`data/config/art.json` `environment.aerial_perspective`),
## already tuned once against a documented "fog eating the world" complaint
## — retuning it globally for one landmark risks undoing that fix and needs
## the kind of whole-survey re-verification R9.4 exists for, not a change
## buried in this task. A silhouette is supposed to be a flat dark shape
## against the sky regardless of distance or sun angle, so instead of fighting
## the shared atmosphere, the towers opt out of it: `fog_disabled` is a real
## Godot 4 spatial shader render mode, and `unshaded` means the silhouette no
## longer picks up a lit highlight streak on the sunward face either (the
## other defect the critic named on the near frame).
const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

uniform vec4 albedo : source_color;

void fragment() {
	ALBEDO = albedo.rgb;
}
"""


func build(world: Node) -> void:
	var at := RISE_CENTRE + OFFSET
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the stronghold silhouette at %.0f, %.0f" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)

	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("albedo", TOWER_COLOUR)

	# A low, wide base connecting the towers' feet: four bare cylinders read
	# as standing stones or smokestacks (named directly by the critic), not a
	# fortified structure. One squat drum under them, wide enough to touch
	# every tower's footprint, gives the cluster a shared mass to stand on.
	var base := MeshInstance3D.new()
	base.name = "Base"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 10.0
	base_mesh.bottom_radius = 11.0
	base_mesh.height = 3.0
	base_mesh.radial_segments = 10
	base_mesh.material = mat
	base.mesh = base_mesh
	base.position = Vector3(1.25, 1.5, 3.25)
	add_child(base)

	# One tall keep and three shorter towers around it — an irregular skyline
	# reads as a ruin far more than one uniform silhouette does.
	_tower(Vector3(0.0, 0.0, 0.0), 5.5, 34.0, 5, mat)
	_tower(Vector3(9.0, 0.0, -4.0), 3.2, 22.0, 6, mat)
	_tower(Vector3(-7.0, 0.0, 6.0), 2.6, 18.0, 5, mat)
	_tower(Vector3(3.0, 0.0, 11.0), 3.6, 25.0, 6, mat)


func _tower(at: Vector3, radius: float, height: float, sides: int, mat: ShaderMaterial) -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 0.7
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = sides
	cyl.material = mat
	mesh.mesh = cyl
	mesh.position = at + Vector3(0.0, height * 0.5, 0.0)
	add_child(mesh)

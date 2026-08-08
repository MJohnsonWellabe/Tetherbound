extends Node3D

## The bounded space a fight happens in.
##
## Two jobs: hold both fighters inside a radius, and draw where that radius is.
##
## The boundary is a SOFT wall — you slide along it rather than stopping dead —
## and crossing it is not how you flee. Run is. A player backing away from a
## charged attack must never accidentally end the fight, and an arena that
## doubles as a flee trigger guarantees they eventually will.
##
## Created and destroyed by CombatManager around each fight, so nothing about
## the world scene has to know arenas exist.

const MATH := preload("res://scripts/combat/combat_math.gd")

var radius: float = 11.0

var _boundary_height: float = 3.5
var _boundary_alpha: float = 0.16


func configure(centre: Vector3, cfg: Dictionary) -> void:
	global_position = centre
	radius = float(cfg.get("radius", radius))
	_boundary_height = float(cfg.get("boundary_height", _boundary_height))
	_boundary_alpha = float(cfg.get("boundary_alpha", _boundary_alpha))
	_build_boundary()


## Pull a body back inside the circle and kill the outward part of its velocity.
##
## Killing only the OUTWARD component is what makes the wall slide rather than
## stick: movement along the boundary survives untouched, so holding the stick
## into the edge carries you around it instead of pinning you against it.
func hold_inside(body: CharacterBody3D) -> void:
	var offset := body.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= radius or distance < 0.001:
		return

	var outward := offset / distance
	body.global_position = global_position + outward * radius + Vector3.UP * (body.global_position.y - global_position.y)

	var flat := Vector3(body.velocity.x, 0.0, body.velocity.z)
	var outward_speed := flat.dot(outward)
	if outward_speed > 0.0:
		flat -= outward * outward_speed
		body.velocity.x = flat.x
		body.velocity.z = flat.z


## Is this point inside the arena? Used by the AI, which should never choose to
## reposition somewhere it cannot go.
func contains(point: Vector3) -> bool:
	var offset := point - global_position
	offset.y = 0.0
	return offset.length() <= radius


## Nearest point inside the arena, pulled in by a margin so the AI does not pick
## destinations that sit exactly on the wall.
func clamp_point(point: Vector3, margin: float = 1.0) -> Vector3:
	var offset := point - global_position
	offset.y = 0.0
	var usable := maxf(radius - margin, 0.5)
	if offset.length() <= usable:
		return point
	var pulled := global_position + offset.normalized() * usable
	return Vector3(pulled.x, point.y, pulled.z)


## An open cylinder, unshaded and translucent.
##
## Deliberately cheap and deliberately faint. It has to be visible enough to be
## read as a boundary and faint enough not to obscure the fight inside it, and
## it is a placeholder for a real effect. Over uneven ground it clips into
## slopes; that is accepted for M2 and is a reason the arena is centred on where
## the player chose to engage, which is somewhere they were standing.
func _build_boundary() -> void:
	for child in get_children():
		child.queue_free()

	var wall := CylinderMesh.new()
	wall.top_radius = radius
	wall.bottom_radius = radius
	wall.height = _boundary_height
	wall.cap_top = false
	wall.cap_bottom = false
	wall.radial_segments = 64
	# Segmented vertically so the gradient below has vertices to interpolate
	# across. One ring of quads fades linearly over its whole height and reads as
	# a solid band; sixteen give it a falloff.
	wall.rings = 16

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Warm gold, and NOT the teal it was for one round.
	#
	# Teal was chosen to sit outside the biome palette, which was right in
	# principle and wrong in fact: additive cyan over green terrain produced "a
	# blue-cyan haze band lying on the terrain and cutting across objects...
	# the same trunk is pale blue above the band and brown below, with a hard
	# boundary", and on a hillside it read as water in a biome whose art board
	# promises streams. A fix that ships a new artefact is not a fix.
	#
	# Gold is close enough to the sunlit grass that additive blending brightens
	# rather than recolours, so where it crosses a trunk the trunk stays brown.
	# The falloff below does the separating instead of the hue.
	material.albedo_color = Color(0.98, 0.86, 0.52, _boundary_alpha)
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED

	# Only the FAR wall is ever drawn.
	#
	# The trainer stands near the edge and the aim camera sits several metres
	# behind them, which puts it outside the circle — and with both faces drawn
	# the near wall then hung across the entire view as a translucent sheet with
	# the fight behind it. Culling front faces means the boundary is always
	# something you see across the arena, never something you look through.
	material.cull_mode = BaseMaterial3D.CULL_FRONT
	# It marks a line on the ground; it should never occlude a creature standing
	# behind it, and it has no business writing depth for anything else.
	material.no_depth_test = false
	material.disable_receive_shadows = true

	var mesh := MeshInstance3D.new()
	mesh.name = "Boundary"
	mesh.mesh = _faded(wall)
	mesh.material_override = material
	mesh.position = Vector3(0.0, _boundary_height * 0.5, 0.0)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


## Bake a vertical alpha gradient into the wall's vertex colours.
##
## Brightest where it meets the ground and fading out upward, so the boundary
## reads as a line on the ground with a glow above it rather than as a wall of
## flat colour. The critic's complaint was "no falloff" and this is the falloff:
## it is what makes a boundary read as an effect instead of as geometry.
##
## Vertex colours rather than a shader, because the whole arena is placeholder
## and a one-off shader here would outlive the thing it was written for.
func _faded(source: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays: Array = source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var colours := PackedColorArray()
		colours.resize(points.size())
		for i in points.size():
			# `height * 0.5` above and below the mesh origin.
			var up: float = clampf(points[i].y / maxf(0.001, _boundary_height) + 0.5, 0.0, 1.0)
			# Steeper than the square it was, so the band hugs the ground and has
			# essentially nothing left by the height of a tree trunk — which is
			# where it was being seen crossing things it should never touch.
			var alpha: float = pow(1.0 - up, 3.5)
			colours[i] = Color(1.0, 1.0, 1.0, alpha)
		arrays[Mesh.ARRAY_COLOR] = colours
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out

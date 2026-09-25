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
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")

var radius: float = 11.0

var _boundary_height: float = 3.5
var _boundary_alpha: float = 0.16

## The scatter that stood aside for this fight, and the node that holds it.
## See `vegetation.gd::hide_fight_occluders()`.
var _vegetation: Node = null
var _hidden_occluders := PackedInt32Array()
## Authored nodes built from the same models (`harvest_node.gd`'s group).
var _hidden_nodes: Array = []


func configure(centre: Vector3, cfg: Dictionary) -> void:
	global_position = centre
	radius = float(cfg.get("radius", radius))
	_boundary_height = float(cfg.get("boundary_height", _boundary_height))
	_boundary_alpha = float(cfg.get("boundary_alpha", _boundary_alpha))
	_build_boundary()
	if bool(cfg.get("clear_soft_occluders", false)):
		_clear_soft_occluders(radius + maxf(float(cfg.get("occluder_clear_margin", 0.0)), 0.0))


## Bushes and standing dead trees inside the ring stand aside for the fight
## and come back when the arena closes. Presentation only: neither layer
## collides, and nothing here is saved or sent to another peer.
func _clear_soft_occluders(reach: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	for node: Node in get_tree().get_nodes_in_group(HARVEST_NODE.FIGHT_RING_OCCLUDER_GROUP):
		var spot := node as Node3D
		if spot == null or not spot.is_inside_tree():
			continue
		var offset := spot.global_position - global_position
		if Vector2(offset.x, offset.z).length() <= reach:
			spot.call("set_fight_hidden", true)
			_hidden_nodes.append(spot)
	_vegetation = parent.get_node_or_null(^"Vegetation")
	if _vegetation == null or not _vegetation.has_method("hide_fight_occluders"):
		_vegetation = null
		return
	_hidden_occluders = _vegetation.call("hide_fight_occluders", global_position, reach)


func _exit_tree() -> void:
	for node: Variant in _hidden_nodes:
		if is_instance_valid(node):
			(node as Node).call("set_fight_hidden", false)
	_hidden_nodes.clear()
	if _vegetation != null and is_instance_valid(_vegetation) and not _hidden_occluders.is_empty() \
			and _vegetation.is_inside_tree() and not _vegetation.is_queued_for_deletion():
		_vegetation.call("restore_fight_occluders", _hidden_occluders)
	_hidden_occluders = PackedInt32Array()
	_vegetation = null


## Pull a body back inside the circle and kill the outward part of its velocity.
##
## Killing only the OUTWARD component is what makes the wall slide rather than
## stick: movement along the boundary survives untouched, so holding the stick
## into the edge carries you around it instead of pinning you against it.
func hold_inside(body: CharacterBody3D) -> Vector3:
	var offset := body.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= radius or distance < 0.001:
		return Vector3.ZERO

	var outward := offset / distance
	body.global_position = global_position + outward * radius + Vector3.UP * (body.global_position.y - global_position.y)

	var flat := Vector3(body.velocity.x, 0.0, body.velocity.z)
	var outward_speed := flat.dot(outward)
	if outward_speed > 0.0:
		flat -= outward * outward_speed
		body.velocity.x = flat.x
		body.velocity.z = flat.z
		return -outward
	return Vector3.ZERO


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
	# Teal, not gold.
	#
	# It was #d9b340, which is the same yellow-ochre family as the sunlit hills
	# behind it, so the blind critic read it as "a hard-edged flat khaki band
	# splatted onto the terrain with no falloff" — the second-largest colour mass
	# in the combat frames, fighting the depth read as well as the composition.
	# A boundary is UI drawn in the world: it should sit outside the biome's
	# palette so it never reads as ground.
	material.albedo_color = Color(0.35, 0.82, 0.86, _boundary_alpha)
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
			var alpha: float = pow(1.0 - up, 2.0)
			colours[i] = Color(1.0, 1.0, 1.0, alpha)
		arrays[Mesh.ARRAY_COLOR] = colours
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out

extends Node3D

## Marks which creature on screen is the one actually being fought.
##
## `R9.4-remainder-9-combat`: a blind critic found two visually identical wild
## pals on screen at once — the one engaged and an ambient, decorative one
## from the same spawn cluster (`data/config/spawns.json`'s `count` > 1) —
## with nothing telling them apart. This floats a marker over the real
## opponent's head for the length of the fight.
##
## `top_level = true`, the same technique `orb.gd`'s trail already uses: the
## opponent walks, roots and turns during a fight, and a marker that inherited
## its rotation would swing with every turn to face the player instead of
## staying camera-facing.

const BOB_SPEED := 2.6
const BOB_HEIGHT := 0.12

var _target: Node3D = null
var _height: float = 1.6
var _colour: Color = Color("#f4f7ff")
var _size: float = 0.42
var _life: float = 0.0

var _mesh: ImmediateMesh = null
var _billboard: MeshInstance3D = null


static func begin(parent: Node, target: Node3D, cfg: Dictionary) -> Node3D:
	var marker := new()
	marker._target = target
	marker._height = float(cfg.get("height", 1.6))
	marker._colour = Color(str(cfg.get("colour", "#f4f7ff")))
	marker._size = float(cfg.get("size", 0.42))
	marker.top_level = true
	parent.add_child(marker)
	return marker


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_billboard = MeshInstance3D.new()
	_billboard.mesh = _mesh
	_billboard.material_override = _material()
	_billboard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var reach := _size * 3.0
	_billboard.custom_aabb = AABB(Vector3.ONE * -reach, Vector3.ONE * reach * 2.0)
	add_child(_billboard)


func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = false
	return material


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	# Hidden, not freed, while the target itself is hidden — an orb resolving
	# a catch hides the creature for the length of the wobble, and a chevron
	# left floating over nothing would be a worse bug than the one this fixes.
	_billboard.visible = _target.visible
	if not _target.visible:
		return
	_life += delta
	var bob: float = sin(_life * BOB_SPEED) * BOB_HEIGHT
	var head: Vector3 = _target.call("centre") if _target.has_method("centre") \
		else _target.global_position
	global_position = head + Vector3.UP * (_height + bob)
	_draw()


## A small chevron pointing straight down at the creature's head — legible at
## the distance a combat frame actually shows it, and it does not compete with
## the impact flash's warm gold or the telegraph glow's warning red.
func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right: Vector3 = basis.x * _size
	var down: Vector3 = -basis.y * _size

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(Color(_colour.r, _colour.g, _colour.b, 0.95))
	_mesh.surface_add_vertex(down * 1.2)
	_mesh.surface_set_color(Color(_colour.r, _colour.g, _colour.b, 0.0))
	_mesh.surface_add_vertex(-right)
	_mesh.surface_set_color(Color(_colour.r, _colour.g, _colour.b, 0.0))
	_mesh.surface_add_vertex(right)
	_mesh.surface_end()


func stop() -> void:
	queue_free()

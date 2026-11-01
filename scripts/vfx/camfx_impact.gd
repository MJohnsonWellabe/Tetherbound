extends Node3D

## camfx.json `impact_fx` (cameras-and-effects lane, owner 1 Nov; judges:
## "flat magenta telegraph rings and slabs", "bright impact effects obscure
## creatures"). A landed blow leaves physical things at the struck creature's
## feet instead of only a flat disc over its body: lit stone chips that are
## thrown up, tumble, bounce once and settle; on a heavy blow a jagged ground
## crack (glowing briefly for electric and fire blows); and on an electric blow
## a few jagged lightning arcs from the body to the ground. Meshes and one
## shader, advanced on the physics clock (impact_flash.gd's lesson), so both
## renderers and the capture tools see it. Presentation only; the hit was
## decided before this is called.

const CAMFX := preload("res://scripts/vfx/camfx.gd")
const CRACK_SHADER := preload("res://shaders/camfx_crack.gdshader")
const VFX_CONFIG := "res://data/config/vfx.json"

var _cfg: Dictionary = {}
var _element := ""
var _charged := false
var _height := 1.0
var _life := 0.0
var _duration := 1.4
var _rng := RandomNumberGenerator.new()
var _chips: Array[Dictionary] = []
var _crack: MeshInstance3D = null
var _crack_material: ShaderMaterial = null
var _arcs: MeshInstance3D = null
var _arc_mesh: ImmediateMesh = null
var _arc_top := Vector3.ZERO
var _arc_ends: Array[Vector3] = []
var _arc_next := 0.0

static var _type_colours: Dictionary = {}


## The element a move tint names (vfx.json `type_colours`), or "".
static func element_for_tint(tint: Variant) -> String:
	if not (tint is Color):
		return ""
	if _type_colours.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VFX_CONFIG))
		var colours: Variant = parsed.get("type_colours", {}) if parsed is Dictionary else {}
		_type_colours = colours if colours is Dictionary else {}
	var best := ""
	var best_d := 0.02
	for type: String in _type_colours:
		var c := Color(str(_type_colours[type]))
		var d := absf(c.r - (tint as Color).r) + absf(c.g - (tint as Color).g) + absf(c.b - (tint as Color).b)
		if d < best_d:
			best_d = d
			best = type
	return best


## Spawns the effect under `host` at `struck`'s feet. Null when the flag is off.
static func spawn(host: Node, struck: Node3D, tint: Variant, charged: bool) -> Node3D:
	var cfg := CAMFX.block("impact_fx")
	if cfg.is_empty() or host == null or not host.is_inside_tree() \
			or struck == null or not is_instance_valid(struck) or not struck.is_inside_tree():
		return null
	var node := (load("res://scripts/vfx/camfx_impact.gd") as Script).new() as Node3D
	node.name = "CamfxImpact"
	node.set("_cfg", cfg)
	node.set("_element", element_for_tint(tint))
	node.set("_charged", charged)
	var height := 1.0
	if struck.has_method("height"):
		height = maxf(0.4, float(struck.call("height")))
	node.set("_height", height)
	node.top_level = true
	host.add_child(node)
	node.global_position = struck.global_position
	return node


## Elements whose blows crack the ground (not water or air).
func _cracks() -> bool:
	return _element not in ["water", "air", "ice"]


func _ready() -> void:
	_rng.seed = int(absf(position.x * 131.0 + position.z * 71.0)) + Time.get_ticks_msec()
	var size := clampf(_height / 2.0, 0.6, 2.2)
	var chips := int(_cfg.get("chips_charged" if _charged else "chips_quick", 6))
	if _element in ["water", "air"]:
		chips = 0
	var rock := Color(str(_cfg.get("chip_colour", "#7c6c58")))
	var material := StandardMaterial3D.new()
	material.albedo_color = rock
	material.roughness = 1.0
	for i in chips:
		var box := BoxMesh.new()
		var s := float(_cfg.get("chip_size_m", 0.11)) * size * _rng.randf_range(0.6, 1.4)
		box.size = Vector3(s, s * _rng.randf_range(0.5, 0.9), s * _rng.randf_range(0.7, 1.2))
		var chip := MeshInstance3D.new()
		chip.mesh = box
		var own := material.duplicate() as StandardMaterial3D
		own.albedo_color = rock.darkened(_rng.randf_range(0.0, 0.35))
		chip.material_override = own
		chip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(chip)
		var angle := _rng.randf() * TAU
		var out := Vector3(cos(angle), 0.0, sin(angle))
		chip.position = out * 0.25 * size + Vector3.UP * 0.05
		var speed := float(_cfg.get("chip_speed", 3.2)) * _rng.randf_range(0.6, 1.2) * sqrt(size)
		_chips.append({"node": chip, "v": out * speed * 0.6 + Vector3.UP * speed,
			"spin": Vector3(_rng.randf_range(-12, 12), _rng.randf_range(-12, 12), _rng.randf_range(-12, 12)),
			"bounced": false, "resting": false})
	if _charged and _cracks():
		var quad := QuadMesh.new()
		var radius := float(_cfg.get("crack_radius_m", 1.0)) * size
		quad.size = Vector2(radius * 2.0, radius * 2.0)
		quad.orientation = PlaneMesh.FACE_Y
		_crack = MeshInstance3D.new()
		_crack.mesh = quad
		_crack_material = ShaderMaterial.new()
		_crack_material.shader = CRACK_SHADER
		_crack_material.set_shader_parameter("seed", _rng.randf() * 10.0)
		_crack_material.set_shader_parameter("rays", float(_rng.randi_range(5, 8)))
		var glow := 0.0
		if _element in ["electric", "fire"]:
			glow = 1.0
			var tint: Variant = Color(str(_cfg.get("electric_glow", "#fff1b8"))) if _element == "electric" \
				else Color(str(_cfg.get("fire_glow", "#ffb05a")))
			_crack_material.set_shader_parameter("glow_colour", tint)
		_crack_material.set_shader_parameter("glow", glow)
		_crack.material_override = _crack_material
		_crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_crack.position = Vector3.UP * 0.03
		_crack.rotation.y = _rng.randf() * TAU
		add_child(_crack)
	if _element == "electric":
		_arc_mesh = ImmediateMesh.new()
		_arcs = MeshInstance3D.new()
		_arcs.mesh = _arc_mesh
		var arc_material := StandardMaterial3D.new()
		arc_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		arc_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		arc_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		arc_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		arc_material.vertex_color_use_as_albedo = true
		_arcs.material_override = arc_material
		_arcs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_arcs)
		_arc_top = Vector3.UP * _height * 0.6
		for i in int(_cfg.get("arcs", 3)):
			var a := _rng.randf() * TAU
			_arc_ends.append(Vector3(cos(a), 0.02, sin(a)) * _rng.randf_range(0.6, 1.2) * size)
	_duration = float(_cfg.get("seconds", 1.4))


func _physics_process(delta: float) -> void:
	_life += delta
	var gravity := 14.0
	for chip: Dictionary in _chips:
		var node: MeshInstance3D = chip["node"]
		if not chip["resting"]:
			var v: Vector3 = chip["v"]
			v.y -= gravity * delta
			node.position += v * delta
			node.rotation += (chip["spin"] as Vector3) * delta
			if node.position.y <= 0.03 and v.y < 0.0:
				node.position.y = 0.03
				if not chip["bounced"]:
					chip["bounced"] = true
					v = Vector3(v.x * 0.4, -v.y * 0.3, v.z * 0.4)
					chip["spin"] = (chip["spin"] as Vector3) * 0.3
				else:
					chip["resting"] = true
					v = Vector3.ZERO
			chip["v"] = v
		# Settle into the ground over the last third.
		var sink := clampf((_life - _duration * 0.66) / (_duration * 0.34), 0.0, 1.0)
		node.scale = Vector3.ONE * (1.0 - sink)
	if _crack_material != null:
		_crack_material.set_shader_parameter("fade", 1.0 - smoothstep(_duration * 0.5, _duration, _life))
		_crack_material.set_shader_parameter("glow", maxf(0.0, 1.0 - _life / 0.45) \
			if _element in ["electric", "fire"] else 0.0)
	if _arc_mesh != null:
		_draw_arcs(delta)
	if _life >= _duration:
		queue_free()


## Jagged camera-facing ribbons from the body down to the ground, re-jagged
## every few hundredths of a second so they crackle, gone after `arc_seconds`.
func _draw_arcs(delta: float) -> void:
	var seconds := float(_cfg.get("arc_seconds", 0.32))
	if _life > seconds:
		_arc_mesh.clear_surfaces()
		return
	_arc_next -= delta
	if _arc_next > 0.0:
		return
	_arc_next = 0.04
	_arc_mesh.clear_surfaces()
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	var view := Vector3.FORWARD if camera == null else (camera.global_position - global_position).normalized()
	var width := float(_cfg.get("arc_width_m", 0.05)) * clampf(_height / 2.0, 0.6, 2.0)
	var alpha := 1.0 - _life / seconds
	var core := Color(str(_cfg.get("arc_colour", "#fff6d0")))
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for end: Vector3 in _arc_ends:
		var steps := 7
		var prev := _arc_top
		for s in range(1, steps + 1):
			var t := float(s) / float(steps)
			var point := _arc_top.lerp(end, t)
			if s < steps:
				point += Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.5, 0.5), _rng.randf_range(-1, 1)) \
					* 0.18 * clampf(_height / 2.0, 0.6, 2.0)
			var side := (point - prev).cross(view).normalized() * width
			var c := Color(core.r, core.g, core.b, alpha)
			for v: Vector3 in [prev - side, prev + side, point + side, prev - side, point + side, point - side]:
				_arc_mesh.surface_set_color(c)
				_arc_mesh.surface_add_vertex(v)
			prev = point
	_arc_mesh.surface_end()

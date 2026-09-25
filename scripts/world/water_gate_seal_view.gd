extends Node3D

## Visible side of the closed-gate tide races (water_gate_seals.gd). Each sealed
## landform wears a white-water ring from its waterline out to the race's edge,
## streaming outward like the physics beneath it. A swimmer thrown back by a
## race is told which dock opens it. Presentation only: the current field and
## Fly restriction own the physical gate, so this node never decides access.

const SEALS := preload("res://scripts/world/water_gate_seals.gd")
const STATE := preload("res://scripts/player/swim_state.gd")
const TILE_M := 8.0
const SURFACE_LIFT_M := 0.08

var _world: Node3D
var _game: Node
var _seals: Array[Dictionary] = []
var _rules: Dictionary = {}
var _rings: Dictionary = {}
var _material: StandardMaterial3D
var _dock_names: Dictionary = {}
var _last_revision := -1
var _message_cooldown := 0.0
## Last explanation shown to this peer's swimmer; read by the runtime smoke.
var last_message := ""


func build(world: Node3D, config: Dictionary, seals: Array[Dictionary], rules: Dictionary) -> void:
	_world = world
	_game = get_node("/root/Game")
	_seals = seals
	_rules = rules
	var island_names: Dictionary = {}
	for island: Dictionary in config.get("islands", []):
		island_names[str(island.id)] = str(island.get("name", island.id))
	for dock: Dictionary in config.get("docks", []):
		_dock_names[str(dock.id)] = str(island_names.get(str(dock.island_id), dock.island_id))
	_material = _foam_material()
	var sea := float(config.get("terrain", {}).get("sea_level_m", 0.0))
	for seal: Dictionary in _seals:
		var ring := MeshInstance3D.new()
		ring.name = "TideRace_" + str(seal.id)
		ring.mesh = _annulus(float(seal.shore_radius_m), SEALS.outer_radius(seal, _rules),
				float(_rules.get("edge_blend_m", 0.0)))
		ring.material_override = _material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var centre: Vector2 = seal.centre
		ring.position = Vector3(centre.x, sea + SURFACE_LIFT_M, centre.y)
		add_child(ring)
		_rings[str(seal.id)] = ring
	_refresh()


func is_race_visible(seal_id: String) -> bool:
	var ring: Node3D = _rings.get(seal_id)
	return ring != null and ring.visible


func _refresh() -> void:
	_last_revision = int(_game.world.flags.revision)
	for seal: Dictionary in _seals:
		_rings[str(seal.id)].visible = SEALS.is_sealed(seal, _game.world.flags)


func _process(delta: float) -> void:
	if _game == null:
		return
	if int(_game.world.flags.revision) != _last_revision:
		_refresh()
	# Offset decreasing moves the pattern toward larger radius: outward flow.
	_material.uv1_offset.y = wrapf(_material.uv1_offset.y - float(_rules.get("foam_flow_m_s", 3.0)) * delta / TILE_M, 0.0, 1.0)
	_message_cooldown = maxf(0.0, _message_cooldown - delta)
	if _message_cooldown > 0.0:
		return
	var player := _world.local_rig() as CharacterBody3D
	if player == null:
		return
	var swim: Node = player.get("swim_controller")
	if swim == null or int(swim.state.mode) == STATE.Mode.LAND:
		return
	var sample: Dictionary = _world.currents.sample(player.global_position)
	var seal_id := str(sample.get("seal", ""))
	if seal_id.is_empty():
		return
	for seal: Dictionary in _seals:
		if str(seal.id) != seal_id:
			continue
		var dock := SEALS.first_closed_dock(seal, _game.world.flags)
		var label := str(seal.label)
		last_message = str(_rules.get("message", "%s throws you back. Clear the %s dock first.")) % [
			label.substr(0, 1).to_upper() + label.substr(1), str(_dock_names.get(dock, dock))]
		_game.push_world_message(last_message)
		_message_cooldown = float(_rules.get("message_interval_s", 12.0))
		return


func _annulus(inner: float, outer: float, blend: float) -> ArrayMesh:
	# Three radii: waterline, start of the outer blend, and the race's edge
	# where the foam fades to open water with the same smooth falloff as flow.
	var radii := [inner, maxf(inner, outer - blend), outer]
	var alphas := [1.0, 1.0, 0.0]
	var segments := maxi(48, ceili(TAU * outer / 4.0))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var circumference_tiles := maxf(1.0, roundf(TAU * inner / TILE_M))
	for index in segments:
		for band in 2:
			var a0 := TAU * float(index) / float(segments)
			var a1 := TAU * float(index + 1) / float(segments)
			var quad := [
				[a0, band], [a1, band], [a1, band + 1],
				[a0, band], [a1, band + 1], [a0, band + 1],
			]
			for corner: Array in quad:
				var angle: float = corner[0]
				var ring: int = corner[1]
				var radius: float = radii[ring]
				tool.set_color(Color(1, 1, 1, alphas[ring]))
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(angle / TAU * circumference_tiles, (radius - inner) / TILE_M))
				tool.add_vertex(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
	return tool.commit()


func _foam_material() -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.seed = 31
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.seamless = true
	texture.width = 256
	texture.height = 256
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(0.93, 0.97, 1.0, float(_rules.get("foam_alpha", 0.62)))
	material.albedo_texture = texture
	material.roughness = 0.35
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

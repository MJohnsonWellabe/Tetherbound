extends Node3D

## The Pond mill's readable working silhouette.
##
## The shared prefab carries a small wheel assembled from fence modules, but
## from the ordinary west-bank view those pieces disappear into the timbered
## wall.  This second, heavier timber ring sits in the exact same local frame
## and water race.  It belongs only to the village's Pond mill; the separately
## authored Old Mill Crossing keeps its already accepted channel wheel.

const WHEEL_RADIUS := 2.35
const SPOKE_COUNT := 10
const TIMBER := Color("#704a27")
const DARK_TIMBER := Color("#3b2818")
const FOAM := Color(0.64, 0.88, 0.92, 0.72)
const WOOD_ALBEDO := preload(
	"res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png")
const WOOD_NORMAL := preload(
	"res://assets/buildings/quaternius_medieval/T_WoodTrim_Normal.png")
const WOOD_ROUGHNESS := preload(
	"res://assets/buildings/quaternius_medieval/T_WoodTrim_Roughness.png")
const IRON := Color("#283235")
const WHEEL_PHASE := deg_to_rad(8.0)


func build() -> void:
	name = "PondMillIdentity"
	position = Vector3(-4.3, 2.15, 0.0)

	var timber := _timber_material(TIMBER, 0.72)
	var dark := _timber_material(DARK_TIMBER, 0.95)
	var iron := _iron_material()

	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var torus := TorusMesh.new()
	torus.inner_radius = WHEEL_RADIUS - 0.24
	torus.outer_radius = WHEEL_RADIUS
	torus.rings = 20
	torus.ring_segments = 8
	rim.mesh = torus
	# TorusMesh's axle is local Y.  The mill wheel turns around local X so its
	# full face reads from the west bank.
	rim.rotation.z = PI * 0.5
	rim.material_override = timber
	add_child(rim)

	# A restrained iron tyre and ten fastening straps keep the large hero wheel
	# from reading as one smooth brown torus. The timber remains the dominant
	# material; metal only articulates how the working assembly is held together.
	var tyre := MeshInstance3D.new()
	tyre.name = "IronTyre"
	var tyre_mesh := TorusMesh.new()
	tyre_mesh.inner_radius = WHEEL_RADIUS - 0.035
	tyre_mesh.outer_radius = WHEEL_RADIUS + 0.045
	tyre_mesh.rings = 20
	tyre_mesh.ring_segments = 8
	tyre.mesh = tyre_mesh
	tyre.rotation.z = PI * 0.5
	tyre.material_override = iron
	add_child(tyre)

	for i in SPOKE_COUNT:
		var angle := WHEEL_PHASE + float(i) * TAU / float(SPOKE_COUNT)
		var spoke := MeshInstance3D.new()
		spoke.name = "Spoke%02d" % i
		var spoke_mesh := BoxMesh.new()
		spoke_mesh.size = Vector3(0.18, WHEEL_RADIUS * 1.72, 0.16)
		spoke.mesh = spoke_mesh
		spoke.rotation.x = angle
		spoke.material_override = dark
		add_child(spoke)

		var paddle := MeshInstance3D.new()
		paddle.name = "Paddle%02d" % i
		var paddle_mesh := BoxMesh.new()
		paddle_mesh.size = Vector3(0.42, 0.82, 0.34)
		paddle.mesh = paddle_mesh
		paddle.position = Vector3(0.0, cos(angle), sin(angle)) * WHEEL_RADIUS
		paddle.rotation.x = angle
		paddle.material_override = timber
		add_child(paddle)

		var strap := MeshInstance3D.new()
		strap.name = "RimStrap%02d" % i
		var strap_mesh := BoxMesh.new()
		strap_mesh.size = Vector3(0.48, 0.16, 0.34)
		strap.mesh = strap_mesh
		strap.position = Vector3(0.0, cos(angle), sin(angle)) * WHEEL_RADIUS
		strap.rotation.x = angle
		strap.material_override = iron
		add_child(strap)

	var axle := MeshInstance3D.new()
	axle.name = "Axle"
	var axle_mesh := CylinderMesh.new()
	axle_mesh.top_radius = 0.36
	axle_mesh.bottom_radius = 0.36
	axle_mesh.height = 1.55
	axle_mesh.radial_segments = 10
	axle.mesh = axle_mesh
	axle.rotation.z = PI * 0.5
	axle.material_override = dark
	add_child(axle)

	for side in [-1.0, 1.0]:
		var hub := MeshInstance3D.new()
		hub.name = "IronHub%s" % ("Outer" if side < 0.0 else "Inner")
		var hub_mesh := CylinderMesh.new()
		hub_mesh.top_radius = 0.49
		hub_mesh.bottom_radius = 0.49
		hub_mesh.height = 0.16
		hub_mesh.radial_segments = 12
		hub.mesh = hub_mesh
		hub.rotation.z = PI * 0.5
		hub.position.x = side * 0.46
		hub.material_override = iron
		add_child(hub)

	# A restrained patch of pale broken water at the lowest paddles makes the
	# wheel-water contact legible without pretending the whole pond is foam.
	var wash := MeshInstance3D.new()
	wash.name = "WheelWash"
	var wash_mesh := PlaneMesh.new()
	wash_mesh.size = Vector2(2.5, 1.4)
	wash.mesh = wash_mesh
	wash.position = Vector3(-0.03, -2.16, 0.35)
	wash.material_override = _foam_material()
	add_child(wash)


func _timber_material(colour: Color, tile: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.albedo_texture = WOOD_ALBEDO
	material.normal_enabled = true
	material.normal_texture = WOOD_NORMAL
	material.roughness_texture = WOOD_ROUGHNESS
	material.roughness = 0.94
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * tile
	return material


func _iron_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = IRON
	material.metallic = 0.72
	material.roughness = 0.48
	return material


func _foam_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = FOAM
	material.roughness = 0.35
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

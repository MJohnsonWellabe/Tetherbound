extends "res://scripts/world/gated_crossing.gd"

## SE22 — the Old Mill Crossing, spec §3 Band 3's main gate.
##
## The one place SE21's river can be crossed. Team Tether has disabled the
## crossing and taken the person who knows the mechanism; freeing them (`SE27`)
## yields the Mill Bridge Gear, and the crossing opens for good. Everything
## about "shut, then permanently open, with no menu in between" is
## `gated_crossing.gd`'s and `item_gate.gd`'s (`SB10`) — this file adds the one
## thing this crossing has that the South Bridge does not: the mill.
##
## The mill is `building_prefabs.json`'s existing `mill`, the same recipe the
## village's own mill on the stream is built from (`village.json`,
## EV6-remainder) — D24's one village family, no new architecture for a second
## mill, and the wheel hangs over moving water here for the same reason it
## hangs over the stream there. Its position is authored in the crossing's own
## `mill` block, in the crossing's local frame, so it moves with the bridge if
## the narrows are ever re-sited.

const MILL_KEY_ITEM := "mill_bridge_gear"
const MILL_FLAG := "mill_crossing_restored"
const SIGNPOST := preload("res://scripts/world/signpost.gd")
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const MILL_RACE_WATER := preload("res://shaders/mill_race_water.gdshader")
const WORK_YARD_PROPS := {
	"Barrel": preload("res://assets/props/quaternius_fantasy/Barrel.gltf"),
	"BarrelHolder": preload("res://assets/props/quaternius_fantasy/Barrel_Holder.gltf"),
	"Bucket": preload("res://assets/props/quaternius_fantasy/Bucket_Wooden_1.gltf"),
	"Cart": preload("res://assets/props/quaternius_fantasy/Stall_Cart_Empty.gltf"),
	"Crate": preload("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"),
	"Bag": preload("res://assets/props/quaternius_fantasy/Bag.gltf"),
}

## The catalogue stand is thirty-three metres down the ordinary south-bank
## road. The crossing used to reveal a tall house through a tree and nothing
## that said whether it belonged to the river, the road, or the bridge. A
## normal fingerpost at the work-yard entrance makes the authored name a
## physical part of that approach. It uses the same sign object and lettering
## as every Meadows route marker; this is not a floating label or new lore.
const APPROACH_SIGN_BACK_M := 13.5
const APPROACH_SIGN_SIDE_M := 6.8


func _init() -> void:
	super("old_mill_crossing", MILL_KEY_ITEM, MILL_FLAG)


func prompt_label() -> String:
	# Still about the object, never the condition (spec §19). The gear goes
	# into the mill's gearing, so this is what a player would try.
	return "Try the mill bridge gate"


## The mill on the village-side bank. Placed in this node's own frame — local
## +X is the bridge's run toward the far bank, so the authored offset's x is
## negative to stand it back on the near side — and seated on the ground it
## actually finds there rather than on the deck's level, because the abutment
## pad and the mill yard are the same `flats` pad but the yard falls away from
## it (`terrain_playground.json`).
func _build_extras(world: Node3D, prefabs: RefCounted, deck_ground: float) -> void:
	var spec: Dictionary = _crossing.get("mill", {})
	if spec.is_empty():
		return
	var offset: Array = spec.get("offset", [])
	if offset.size() < 2:
		push_warning("the Old Mill Crossing's mill has no offset; not placed")
		return
	_clear_arrival_scatter(world)
	var local := Vector3(float(offset[0]), 0.0, float(offset[1]))
	# The inherited OW5C anchor predates final production pixels and places the
	# rotated footprint on the river feather. Recess the building to the centre
	# of its existing yard pad; attached wheel and millrace remain outboard.
	local.z += MILL_BANK_RECESS
	var mill: Node3D = prefabs.call("instantiate", str(spec.get("prefab", "mill")))
	if mill == null:
		push_error("mill prefab missing: %s" % spec.get("prefab", "mill"))
		return
	mill.name = "Mill"
	# The prefab's wheel hangs off its own local -x (building_prefabs.json), so
	# a yaw is what points the wheel at the water rather than at the meadow.
	mill.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	# Where that local point lands in the world, so the ground under it can be
	# sampled with the same duck-typed `ground_height_at` everything else in
	# this file uses — never a raycast (D09).
	var here := global_transform * local if is_inside_tree() else transform * local
	var ground: float = float(world.call("ground_height_at", here.x, here.z))
	# `village.gd` grounds this prefab "highest" because the wheel's own AABB
	# corner is the streambed; the same reasoning applies over a 7m-deep race,
	# only more so — so the mill sits on the higher of its own ground sample
	# and the levelled deck, and can never end up hung over the channel.
	# Embed the prefab's thin exterior-border skirt into the worked bank. The
	# stone ground course remains fully visible, while no daylight can appear
	# beneath the rotated footprint at the feathered edge of the yard flat.
	local.y = maxf(ground, deck_ground) - position.y - MILL_BANK_SEAT_DEPTH
	mill.position = local
	add_child(mill)
	_hide_river_border_skirt(mill)
	_add_prefab_colliders(prefabs, mill, str(spec.get("prefab", "mill")))
	_build_approach_sign(world)
	_build_visible_mill_wheel(mill)
	_build_millrace(mill)
	_build_mill_bank_seat(mill)
	_build_loading_activity(mill)
	_build_practical_lights(world, mill)


func _hide_river_border_skirt(mill: Node3D) -> void:
	# The kit's exterior-border strips are ornamental gray plates. At this steep
	# river-bank placement every side exposes a hard unsupported lip; the masonry
	# and the irregular footing below already supply the finished toe.
	for child: Node in mill.get_children():
		var part := child as Node3D
		if part != null and (part.name.begins_with("Prop_ExteriorBorder_") \
				or (absf(part.position.y) < 0.02 \
					and (absf(absf(part.position.x) - 3.15) < 0.03 \
						or absf(absf(part.position.z) - 3.15) < 0.03))):
			part.visible = false


func _build_mill_bank_seat(mill: Node3D) -> void:
	# One continuous battered plinth carries the full mill footprint into the
	# steep bank and below the waterline. Chamfered corners and a wider toe make
	# the load path explicit without stacked/interpenetrating boxes.
	var top_ring: Array[Vector2] = [
		Vector2(-2.62, -3.06), Vector2(2.62, -3.06),
		Vector2(3.06, -2.62), Vector2(3.06, 2.62),
		Vector2(2.62, 3.06), Vector2(-2.62, 3.06),
		Vector2(-3.06, 2.62), Vector2(-3.06, -2.62),
	]
	var toe_scale := [1.18, 1.20, 1.22, 1.19, 1.21, 1.17, 1.20, 1.22]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(
		"res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
	material.normal_enabled = true
	material.normal_texture = load(
		"res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
	material.roughness = 0.92
	material.roughness_texture = load(
		"res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in top_ring.size():
		var next := (i + 1) % top_ring.size()
		var top_a := top_ring[i]
		var top_b := top_ring[next]
		var toe_a := top_a * float(toe_scale[i])
		var toe_b := top_b * float(toe_scale[next])
		var face_width := top_a.distance_to(top_b)
		var base := i * 4
		surface.set_uv(Vector2(0.0, 0.0))
		surface.add_vertex(Vector3(top_a.x, 0.30, top_a.y))
		surface.set_uv(Vector2(face_width * 0.52, 0.0))
		surface.add_vertex(Vector3(top_b.x, 0.30, top_b.y))
		surface.set_uv(Vector2(0.0, 2.85))
		surface.add_vertex(Vector3(toe_a.x, -5.35, toe_a.y))
		surface.set_uv(Vector2(face_width * 0.52, 2.85))
		surface.add_vertex(Vector3(toe_b.x, -5.35, toe_b.y))
		surface.add_index(base); surface.add_index(base + 2); surface.add_index(base + 1)
		surface.add_index(base + 1); surface.add_index(base + 2); surface.add_index(base + 3)
	surface.generate_normals()
	var foundation := MeshInstance3D.new()
	foundation.name = "BatteredStoneFoundation"
	foundation.mesh = surface.commit()
	foundation.material_override = material
	mill.add_child(foundation)


func _clear_arrival_scatter(world: Node3D) -> void:
	var vegetation := world.get_node_or_null(^"Vegetation")
	if vegetation == null or not vegetation.has_method("clear_area"):
		return
	# The authored clearing owns the eventual bake. These overlapping production
	# lenses remove only stale imported scatter that still fills the south-road
	# camera-to-wheel axis before that bake is regenerated.
	vegetation.call("clear_area", Vector3(-150.2, 0.0, 4182.0), 12.5)
	vegetation.call("clear_area", Vector3(-157.0, 0.0, 4199.0), 10.0)
	vegetation.call("clear_area", Vector3(-152.0, 0.0, 4168.0), 6.5)


func _build_approach_sign(world: Node3D) -> void:
	# `near_point()` is resolved from the crossing's own road, so the sign stays
	# on the arriving bank if the narrows is re-sited. The perpendicular offset
	# leaves the bridge's walking line and the existing repair-yard props clear.
	var approach := near_point(APPROACH_SIGN_BACK_M)
	var road_right := Vector2(_across.y, -_across.x)
	var at := approach - road_right * APPROACH_SIGN_SIDE_M
	var sign: Node3D = SIGNPOST.new()
	sign.name = "OldMillCrossingSign"
	world.add_child(sign)
	sign.call("build", world, at, [{
		"label": str(_crossing.get("label", "Old Mill Crossing")),
		"points": [[at.x, at.y], [_centre.x, _centre.y]],
	}])


## The installed mill already carries a small fence-section wheel on its west
## wall. This larger wheel shares that authored axle instead of standing as a
## disconnected roadside sculpture across the bridge: the mill, wheel and water
## now make one readable machine from every bank. It is visual dressing only;
## the prefab's existing wheel collider remains authoritative.
const HERO_WHEEL_RADIUS := 2.65
const HERO_WHEEL_SPOKES := 10
const HERO_WHEEL_COLOUR := Color("#6e4a28")
const HERO_WHEEL_DARK := Color("#3f2a18")
# R7 moves the visible wheel fully outboard of the prefab's smooth lower wall while
# retaining the prefab axle's height and centre line. The longer drive shaft
# below visibly returns to the wall, so this reads as one machine rather than a
# second decorative wheel hidden behind the foundation plane.
const HYDRAULIC_AXIS_X := -7.25
const HERO_WHEEL_AXLE := Vector3(HYDRAULIC_AXIS_X, 2.15, 0.0)
const MILL_BANK_RECESS := 3.39
const MILL_BANK_SEAT_DEPTH := 2.35


func _build_visible_mill_wheel(mill: Node3D) -> void:
	var wheel := Node3D.new()
	wheel.name = "OldMillWaterWheel"
	wheel.position = HERO_WHEEL_AXLE
	# The generated circle lies in local XY. A quarter-turn puts it in the
	# prefab's YZ wheel plane, normal to the west wall and around the existing
	# axle/collider rather than in the bridge's walking line.
	wheel.rotation.y = -PI * 0.5
	mill.add_child(wheel)

	var timber := _wheel_material(HERO_WHEEL_COLOUR)
	var dark := _wheel_material(HERO_WHEEL_DARK)
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var torus := TorusMesh.new()
	torus.inner_radius = HERO_WHEEL_RADIUS - 0.22
	torus.outer_radius = HERO_WHEEL_RADIUS
	rim.mesh = torus
	rim.rotation.x = PI * 0.5
	rim.material_override = timber
	wheel.add_child(rim)

	for i in HERO_WHEEL_SPOKES:
		var angle := float(i) * TAU / float(HERO_WHEEL_SPOKES)
		var spoke := MeshInstance3D.new()
		spoke.name = "Spoke%02d" % i
		var spoke_mesh := BoxMesh.new()
		spoke_mesh.size = Vector3(HERO_WHEEL_RADIUS * 1.72, 0.14, 0.16)
		spoke.mesh = spoke_mesh
		spoke.rotation.z = angle
		spoke.material_override = dark
		wheel.add_child(spoke)

		var paddle := MeshInstance3D.new()
		paddle.name = "Paddle%02d" % i
		var paddle_mesh := BoxMesh.new()
		paddle_mesh.size = Vector3(0.86, 0.34, 0.32)
		paddle.mesh = paddle_mesh
		paddle.position = Vector3(cos(angle), sin(angle), 0.0) * HERO_WHEEL_RADIUS
		paddle.rotation.z = angle
		paddle.material_override = timber
		wheel.add_child(paddle)

	var axle := MeshInstance3D.new()
	axle.name = "Axle"
	var axle_mesh := CylinderMesh.new()
	axle_mesh.top_radius = 0.34
	axle_mesh.bottom_radius = 0.34
	axle_mesh.height = 1.2
	axle.mesh = axle_mesh
	axle.rotation.x = PI * 0.5
	axle.material_override = dark
	wheel.add_child(axle)

	# A longer shaft visibly enters the mill wall. The short hub above holds the
	# wheel together; this member explains where the wheel's rotation goes.
	var drive_shaft := MeshInstance3D.new()
	drive_shaft.name = "DriveShaft"
	var drive_mesh := CylinderMesh.new()
	drive_mesh.top_radius = 0.22
	drive_mesh.bottom_radius = 0.22
	drive_mesh.height = 3.8
	drive_shaft.mesh = drive_mesh
	drive_shaft.rotation.x = PI * 0.5
	# Wheel-local -Z becomes mill-local +X after the wheel's quarter-turn,
	# carrying the shaft from the wheel centre back into the west wall.
	drive_shaft.position = Vector3(0.0, 0.0, -1.42)
	drive_shaft.material_override = dark
	wheel.add_child(drive_shaft)


## The attached wheel only became credible machinery once the water had an
## authored route into it. This compact timber headrace leaves the mill wall,
## carries a narrow visible ribbon, and drops that ribbon directly onto the
## wheel's upper paddles. It is dressing under the mill root: no collision,
## terrain carve, river edit, or crossing-state change.
func _build_millrace(mill: Node3D) -> void:
	var race := Node3D.new()
	race.name = "OldMillHeadrace"
	mill.add_child(race)
	# R14 keeps the accepted broadside wheel but makes the entire hydraulic chain
	# one authored object: a timber headrace feeds the upper paddles, then a compact
	# stream tumbles through an irregular stone bank into the river. Overlapping
	# water runs hide their joints; rounded bank stones hide the hard underside that
	# made R13 read as an enormous segmented grey ramp.
	var timber := _wheel_material(Color("#765437"))
	var stone := _wheel_material(Color("#625d52"))
	var water := StandardMaterial3D.new()
	# Segment boxes remain the live measurable hydraulic contract, but are a
	# restrained underlay; one continuous surface below carries the visible flow.
	water.albedo_color = Color("#4f899500")
	water.metallic = 0.0
	water.roughness = 0.48
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	var foam := StandardMaterial3D.new()
	foam.albedo_color = Color("#b7cfcbc4")
	foam.roughness = 0.3
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var flow_water := ShaderMaterial.new()
	flow_water.shader = MILL_RACE_WATER
	var visual_mask := water.duplicate() as StandardMaterial3D
	visual_mask.albedo_color = Color(0.0, 0.0, 0.0, 0.0)

	_add_box(race, "HeadpondWater", Vector3(2.82, 0.42, 2.42),
		Vector3(HYDRAULIC_AXIS_X, 4.50, -5.58), water)
	for i in 4:
		_add_box(race, "HeadpondPlank%02d" % i, Vector3(2.10, 0.24, 0.34),
			Vector3(HYDRAULIC_AXIS_X, 4.20, -6.20 + float(i) * 0.42), timber)
	_add_box(race, "HeadpondOuterRail", Vector3(0.22, 0.58, 1.88),
		Vector3(HYDRAULIC_AXIS_X - 0.98, 4.48, -5.58), timber)
	_add_box(race, "HeadpondInnerRail", Vector3(0.22, 0.58, 1.88),
		Vector3(HYDRAULIC_AXIS_X + 0.98, 4.48, -5.58), timber)
	_add_box(race, "HeadpondSill", Vector3(2.18, 0.40, 0.34),
		Vector3(HYDRAULIC_AXIS_X, 4.18, -4.78), timber)
	# The visible hillside supply is longer than the compact mechanism proof
	# nodes below: players can follow water in a timber flume from the upstream
	# bank into the headpond instead of seeing it begin at the mill eave.
	_add_sloped_box_at_x(race, "SupplyFlumeBed", HYDRAULIC_AXIS_X, 1.54, 0.26,
		Vector2(-14.5, 4.34), Vector2(-5.74, 4.12), timber)
	_add_channel_banks_at_x(race, "SupplyFlumeBank", HYDRAULIC_AXIS_X, 1.26, 0.18,
		Vector2(-14.5, 4.54), Vector2(-5.74, 4.38), timber)
	_add_sloped_box_at_x(race, "SupplyFlumeWater", HYDRAULIC_AXIS_X - 0.42, 1.20, 0.10,
		Vector2(-14.5, 4.62), Vector2(-5.74, 4.48), flow_water)
	_add_box(race, "SupplyIntakeBasin", Vector3(2.18, 0.56, 1.72),
		Vector3(HYDRAULIC_AXIS_X, 4.28, -14.02), timber)
	_add_box(race, "SupplyIntakeWater", Vector3(1.84, 0.12, 1.40),
		Vector3(HYDRAULIC_AXIS_X - 0.42, 4.62, -14.02), flow_water)
	_add_box(race, "SupplyIntakeWeir", Vector3(2.22, 0.84, 0.22),
		Vector3(HYDRAULIC_AXIS_X, 4.54, -14.88), timber)
	for supply_z in [-8.1, -11.0, -13.5]:
		var trestle_id := int(absf(supply_z) * 10.0)
		_add_beam_between(race, "SupplyTrestle%02dLeft" % int(absf(supply_z) * 10.0),
			Vector3(HYDRAULIC_AXIS_X - 0.72, 0.1, supply_z),
			Vector3(HYDRAULIC_AXIS_X - 0.72, 4.26, supply_z), 0.28, timber)
		_add_beam_between(race, "SupplyTrestle%02dRight" % int(absf(supply_z) * 10.0),
			Vector3(HYDRAULIC_AXIS_X + 0.72, 0.1, supply_z),
			Vector3(HYDRAULIC_AXIS_X + 0.72, 4.26, supply_z), 0.28, timber)
		_add_beam_between(race, "SupplyTrestle%02dBraceA" % trestle_id,
			Vector3(HYDRAULIC_AXIS_X - 0.72, 0.28, supply_z),
			Vector3(HYDRAULIC_AXIS_X + 0.72, 3.72, supply_z), 0.16, timber)
		_add_beam_between(race, "SupplyTrestle%02dBraceB" % trestle_id,
			Vector3(HYDRAULIC_AXIS_X + 0.72, 0.28, supply_z),
			Vector3(HYDRAULIC_AXIS_X - 0.72, 3.72, supply_z), 0.16, timber)
		_add_box(race, "SupplyTrestle%02dFootTie" % trestle_id,
			Vector3(1.72, 0.20, 0.34),
			Vector3(HYDRAULIC_AXIS_X, 0.22, supply_z), timber)
	_add_sloped_box(race, "SourceIntakeWater", 1.46, 0.36,
		Vector2(-4.86, 4.45), Vector2(-4.10, 4.30), water)

	var headrace_beats := [
		{"name": "RunningWater", "from": Vector2(-4.10, 4.30), "to": Vector2(-3.14, 4.12)},
		{"name": "HeadraceWaterMid", "from": Vector2(-3.14, 4.12), "to": Vector2(-2.35, 3.94)},
		{"name": "HeadraceWaterLower", "from": Vector2(-2.35, 3.94), "to": Vector2(-1.58, 3.76)},
	]
	for i in headrace_beats.size():
		var beat: Dictionary = headrace_beats[i]
		var from_point: Vector2 = beat["from"]
		var to_point: Vector2 = beat["to"]
		_add_sloped_box(race, str(beat["name"]), 1.46, 0.36, from_point, to_point, water)
		_add_sloped_box(race, "TroughBed%02d" % i, 1.86, 0.36,
			from_point + Vector2(0.0, -0.30), to_point + Vector2(0.0, -0.30), timber)
		_add_channel_banks(race, "HeadraceBank%02d" % i, 1.46, 0.22,
			from_point, to_point, timber)
	var first_bed := race.get_node_or_null("TroughBed00") as Node3D
	if first_bed != null:
		first_bed.name = "TroughBed"
	_add_box(race, "SourceIntakeCrossbeam", Vector3(1.94, 0.30, 0.34),
		Vector3(HYDRAULIC_AXIS_X, 4.02, -4.10), timber)
	_add_box(race, "SluiceGate", Vector3(1.78, 0.70, 0.20),
		Vector3(HYDRAULIC_AXIS_X, 3.64, -1.58), timber)
	_add_sloped_box(race, "FeedDrop", 1.42, 0.38,
		Vector2(-1.58, 3.76), Vector2(-1.12, 3.56), water)
	_add_sloped_box(race, "PaddleContact", 1.38, 0.40,
		Vector2(-1.12, 3.56), Vector2(-0.68, 3.04), water)
	_add_box(race, "WheelSplash", Vector3(1.46, 0.24, 0.70),
		Vector3(HYDRAULIC_AXIS_X, 3.02, -0.64), water)
	_add_box(race, "FeedFoam", Vector3(1.30, 0.14, 0.30),
		Vector3(HYDRAULIC_AXIS_X, 3.44, -1.08), foam)
	# Broken spray at the bucket strike and basin landing interrupts the water
	# silhouette exactly where its energy changes, rather than drawing one ruler-
	# straight luminous ribbon through the mechanism.
	var contact_spray := [
		Vector3(-8.02, 4.40, -1.70), Vector3(-7.74, 4.30, -1.54),
		Vector3(-7.45, 4.18, -1.38), Vector3(-7.16, 4.05, -1.20),
	]
	for spray_index in contact_spray.size():
		_add_boulder(race, "PaddleSpray%02d" % spray_index, contact_spray[spray_index],
			Vector3(0.48, 0.26, 0.34) * (1.0 + float(spray_index % 2) * 0.25),
			foam, float(spray_index) * 23.0)
	_add_water_spray(race, "PaddleImpactSpray",
		Vector3(HYDRAULIC_AXIS_X - 0.18, 4.28, -1.48), 0.68, 4.6, 72)
	_add_continuous_headrace(race, flow_water)
	_add_box(race, "VisibleHeadpondSurface", Vector3(2.56, 0.12, 2.20),
		Vector3(HYDRAULIC_AXIS_X, 4.72, -5.58), flow_water)
	_add_sloped_box_at_x(race, "PaddleWaterfall", HYDRAULIC_AXIS_X - 0.62, 1.62, 0.16,
		Vector2(-2.10, 4.72), Vector2(-1.52, 4.22), flow_water)
	for jet_index in 3:
		var jet_x := HYDRAULIC_AXIS_X - 0.82 + float(jet_index) * 0.20
		_add_sloped_box_at_x(race, "PaddleLoadingJet%02d" % jet_index, jet_x,
			0.24, 0.10, Vector2(-2.06 + float(jet_index) * 0.08, 4.70),
			Vector2(-1.50 + float(jet_index) * 0.08, 4.18), flow_water)
	# These transparent measured segment nodes preserve the hydraulic layout and
	# evidence contract without drawing overlapping box faces as a staircase. The
	# continuous ribbon above is the authored visible water surface.

	# Water leaves the lower downstream quadrant in a stone/timber-lined race
	# that reaches back to the river axis. Keeping this under the mill root makes
	# the entire source -> wheel -> outfall relationship survive a future crossing
	# relocation without changing terrain, river collision, or gate mechanics.
	_add_sloped_box(race, "WheelDischarge", 1.34, 0.44,
		Vector2(0.84, 0.48), Vector2(1.18, -0.18), water)
	var tailrace_beats := [
		{"name": "TailraceWater", "from": Vector2(1.10, -0.14), "to": Vector2(1.88, -0.82), "width": 1.36, "x": -7.25},
		{"name": "TailraceMid", "from": Vector2(1.82, -0.78), "to": Vector2(2.62, -1.72), "width": 1.46, "x": -7.12},
		{"name": "TailraceMouth", "from": Vector2(2.56, -1.68), "to": Vector2(3.35, -2.72), "width": 1.58, "x": -7.34},
		{"name": "TailraceLower", "from": Vector2(3.29, -2.68), "to": Vector2(4.12, -3.30), "width": 1.68, "x": -7.18},
		{"name": "TailraceCascade", "from": Vector2(4.06, -3.26), "to": Vector2(4.92, -3.52), "width": 1.78, "x": -7.38},
	]
	for i in tailrace_beats.size():
		var beat: Dictionary = tailrace_beats[i]
		var from_point: Vector2 = beat["from"]
		var to_point: Vector2 = beat["to"]
		var width := float(beat["width"])
		var axis_x := float(beat["x"])
		_add_sloped_box_at_x(race, str(beat["name"]), axis_x, width, 0.44,
			from_point, to_point, water)
		# Low continuous cheeks expose the water itself as the causal path. The R14
		# paired boulders projected across the centre and made this read as a chain
		# of stepping stones, even though a valid water ribbon existed behind them.
		_add_channel_banks_at_x(race, "TailraceBank%02d" % i, axis_x,
			width, 0.20, from_point, to_point, visual_mask)
		_add_box(race, "TailraceBed%02d" % i, Vector3(width + 0.28, 0.30, 0.72),
			Vector3(axis_x, to_point.y - 0.30, to_point.x - 0.12), visual_mask)
	var first_tailrace_bed := race.get_node_or_null("TailraceBed00") as Node3D
	if first_tailrace_bed != null:
		first_tailrace_bed.name = "TailraceBed"
	_add_sloped_box_at_x(race, "TailraceOutfall", HYDRAULIC_AXIS_X, 1.92, 0.46,
		Vector2(4.86, -3.48), Vector2(5.70, -3.64), water)
	# The visible return is a free water curtain beside the wheel, not a built
	# diagonal chute: a full-length backing reads as concrete from the river.
	_add_continuous_tailrace(race, flow_water)
	_add_pool_ellipse(race, "TailraceSplashPool", Vector3(HYDRAULIC_AXIS_X + 0.62, -3.40, 4.10),
		Vector3(4.20, 0.12, 3.05), flow_water)
	for splash_index in 5:
		var splash_angle := float(splash_index) * TAU / 5.0
		_add_boulder(race, "BasinFoam%02d" % splash_index,
			Vector3(HYDRAULIC_AXIS_X + 0.62 + cos(splash_angle) * 1.10, -3.24,
				4.10 + sin(splash_angle) * 0.72),
			Vector3(0.34, 0.12, 0.24), foam, float(splash_index) * 17.0)
	_add_stone_basin_rim(race, Vector3(HYDRAULIC_AXIS_X + 0.62, -3.32, 4.10), stone)
	for basin_index in 10:
		var basin_angle := float(basin_index) * TAU / 10.0
		_add_boulder(race, "BasinStone%02d" % basin_index,
			Vector3(HYDRAULIC_AXIS_X + 0.62 + cos(basin_angle) * 2.12, -3.38,
				4.10 + sin(basin_angle) * 1.56),
			Vector3(0.72 + float(basin_index % 3) * 0.10, 0.42,
				0.64 + float((basin_index + 1) % 3) * 0.09), stone,
			float(basin_index * 29))
	_add_water_spray(race, "PlungeBasinSpray",
		Vector3(HYDRAULIC_AXIS_X + 0.42, -3.02, 3.22), 1.12, 3.8, 110)
	_add_box(race, "TailraceFoam", Vector3(1.86, 0.14, 0.54),
		Vector3(HYDRAULIC_AXIS_X, -3.48, 5.62), foam)
	_add_boulder(race, "TailraceRiverToe", Vector3(HYDRAULIC_AXIS_X, -3.62, 5.72),
		Vector3(2.55, 0.72, 1.52), stone, -7.0)
	_add_boulder(race, "OutfallBankLeft", Vector3(-8.62, -3.54, 5.18),
		Vector3(1.34, 0.92, 1.50), stone, 12.0)
	_add_boulder(race, "OutfallBankRight", Vector3(-5.98, -3.58, 5.28),
		Vector3(1.46, 0.86, 1.42), stone, -18.0)

	# A single splayed timber trestle replaces R11's dark monolithic pier. Two
	# stone feet visibly carry crossed legs into a short cap directly below the
	# channel; the open centre preserves the broadside wheel silhouette.
	_add_box(race, "HeadracePierFoot", Vector3(0.46, 1.52, 0.46),
		Vector3(HYDRAULIC_AXIS_X, -0.34, -4.62), timber)
	_add_box(race, "HeadracePierFootInner", Vector3(0.46, 1.46, 0.46),
		Vector3(HYDRAULIC_AXIS_X, -0.31, -3.42), timber)
	_add_beam_between(race, "HeadracePierShaft",
		Vector3(HYDRAULIC_AXIS_X, 0.42, -4.62),
		Vector3(HYDRAULIC_AXIS_X, 3.92, -3.72), 0.42, timber)
	_add_beam_between(race, "HeadracePierBrace",
		Vector3(HYDRAULIC_AXIS_X, 0.42, -3.42),
		Vector3(HYDRAULIC_AXIS_X, 3.92, -4.16), 0.42, timber)
	_add_box(race, "HeadracePierCap", Vector3(1.52, 0.24, 1.42),
		Vector3(HYDRAULIC_AXIS_X, 4.00, -3.94), timber)
	# The earlier long wall bearer projected as an unsupported gray slab from
	# the river view. The crossed trestle already carries the channel; retain a
	# named load-path marker for diagnostics without drawing a duplicate member.
	var wall_bearer_marker := Node3D.new()
	wall_bearer_marker.name = "HeadraceWallBearer"
	race.add_child(wall_bearer_marker)


func _add_continuous_headrace(race: Node3D, material: Material) -> void:
	var points: Array[Vector2] = [
		Vector2(-14.5, 4.62), Vector2(-12.0, 4.58), Vector2(-9.7, 4.54),
		Vector2(-8.9, 4.52), Vector2(-7.2, 4.50),
		Vector2(-5.92, 4.48), Vector2(-4.86, 4.45), Vector2(-4.10, 4.42),
		Vector2(-3.14, 4.38), Vector2(-2.35, 4.32), Vector2(-1.52, 4.22),
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const ACROSS := 5
	for point_index in points.size():
		var point := points[point_index]
		var width := lerpf(1.58, 1.38, float(point_index) / float(points.size() - 1))
		for column in ACROSS:
			var t := float(column) / float(ACROSS - 1)
			var edge_alpha := smoothstep(0.0, 0.28, minf(t, 1.0 - t))
			surface.set_color(Color(1.0, 1.0, 1.0, edge_alpha))
			surface.set_uv(Vector2(t, float(point_index) * 0.42))
			surface.add_vertex(Vector3(HYDRAULIC_AXIS_X - 0.58 + lerpf(-width * 0.5,
				width * 0.5, t), point.y + 0.205, point.x))
	for point_index in points.size() - 1:
		for column in ACROSS - 1:
			var a := point_index * ACROSS + column
			var b := a + 1
			var c := (point_index + 1) * ACROSS + column
			var d := c + 1
			surface.add_index(a); surface.add_index(c); surface.add_index(b)
			surface.add_index(b); surface.add_index(c); surface.add_index(d)
	surface.generate_normals()
	var ribbon := MeshInstance3D.new()
	ribbon.name = "ContinuousHeadraceWater"
	ribbon.mesh = surface.commit()
	ribbon.material_override = material
	race.add_child(ribbon)


func _add_continuous_tailrace(race: Node3D, material: Material,
		ribbon_name: String = "ContinuousTailraceWater", y_offset: float = 0.0,
		width_scale: float = 1.0) -> void:
	# x offset, z run, y height. Small alternating offsets and width pulses break
	# the waterfall edges while keeping one watertight surface.
	var points: Array[Vector3] = [
		# The discharge first falls almost vertically beside the wheel into a basin,
		# then the low race runs out to the river. This silhouette reads as waterwork
		# instead of a diagonal prop leaning unsupported across open air.
		Vector3(-0.58, 0.42, 0.82), Vector3(-0.48, 0.68, 0.10),
		Vector3(-0.34, 0.88, -0.90), Vector3(-0.22, 1.16, -2.10),
		Vector3(0.12, 1.72, -3.22), Vector3(0.02, 2.62, -3.36),
		Vector3(0.42, 3.34, -3.42), Vector3(0.72, 4.08, -3.48),
		Vector3(0.92, 4.72, -3.52), Vector3(0.42, 5.70, -3.64),
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const ACROSS := 7
	for point_index in points.size():
		var point := points[point_index]
		var width_pulse := 1.0 + sin(float(point_index) * 2.17) * 0.12
		var width := lerpf(2.05, 3.10, float(point_index) / float(points.size() - 1)) \
			* width_scale * width_pulse
		for column in ACROSS:
			var t := float(column) / float(ACROSS - 1)
			var edge_alpha := smoothstep(0.0, 0.22, minf(t, 1.0 - t))
			surface.set_color(Color(1.0, 1.0, 1.0, edge_alpha))
			surface.set_uv(Vector2(t, float(point_index) * 0.5))
			surface.add_vertex(Vector3(HYDRAULIC_AXIS_X + point.x + lerpf(-width * 0.5,
				width * 0.5, t), point.z + 0.25 + y_offset, point.y))
	for point_index in points.size() - 1:
		for column in ACROSS - 1:
			var a := point_index * ACROSS + column
			var b := a + 1
			var c := (point_index + 1) * ACROSS + column
			var d := c + 1
			surface.add_index(a); surface.add_index(c); surface.add_index(b)
			surface.add_index(b); surface.add_index(c); surface.add_index(d)
	surface.generate_normals()
	var ribbon := MeshInstance3D.new()
	ribbon.name = ribbon_name
	ribbon.mesh = surface.commit()
	ribbon.material_override = material
	race.add_child(ribbon)


func _add_pool_ellipse(parent: Node3D, node_name: String, at: Vector3,
		size: Vector3, material: Material) -> MeshInstance3D:
	var pool := MeshInstance3D.new()
	pool.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 32
	pool.mesh = mesh
	pool.position = at
	pool.scale = size
	pool.material_override = material
	parent.add_child(pool)
	return pool


func _add_stone_basin_rim(parent: Node3D, at: Vector3, material: Material) -> void:
	var rim := MeshInstance3D.new()
	rim.name = "TailraceStoneBasinRim"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.72
	mesh.outer_radius = 1.0
	mesh.rings = 24
	mesh.ring_segments = 12
	rim.mesh = mesh
	rim.position = at
	rim.scale = Vector3(1.38, 0.34, 1.92)
	rim.material_override = material
	parent.add_child(rim)


func _add_water_spray(parent: Node3D, node_name: String, at: Vector3,
		radius: float, speed: float, count: int) -> void:
	var spray := GPUParticles3D.new()
	spray.name = node_name
	spray.amount = count
	spray.lifetime = 1.15
	spray.randomness = 0.82
	spray.fixed_fps = 30
	spray.position = at
	spray.visibility_aabb = AABB(Vector3(-3.0, -3.0, -3.0), Vector3(6.0, 7.0, 6.0))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = radius
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 72.0
	process.initial_velocity_min = speed * 0.55
	process.initial_velocity_max = speed
	process.gravity = Vector3(0.0, -8.4, 0.0)
	process.scale_min = 0.45
	process.scale_max = 1.25
	spray.process_material = process
	var droplet := SphereMesh.new()
	droplet.radius = 0.055
	droplet.height = 0.11
	droplet.radial_segments = 6
	droplet.rings = 4
	var droplet_material := StandardMaterial3D.new()
	droplet_material.albedo_color = Color("#d5eee6cc")
	droplet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	droplet.material = droplet_material
	spray.draw_pass_1 = droplet
	parent.add_child(spray)


func _add_boulder(parent: Node3D, node_name: String, at: Vector3, size: Vector3,
		material: Material, yaw_deg: float) -> MeshInstance3D:
	var stone := MeshInstance3D.new()
	stone.name = node_name
	var boulder := SphereMesh.new()
	boulder.radius = 0.5
	boulder.height = 1.0
	boulder.radial_segments = 8
	boulder.rings = 5
	stone.mesh = boulder
	stone.position = at
	stone.scale = size
	stone.rotation.y = deg_to_rad(yaw_deg)
	stone.material_override = material
	parent.add_child(stone)
	return stone


func _add_box(parent: Node3D, node_name: String, size: Vector3,
		at: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = at
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_beam_between(parent: Node3D, node_name: String, start: Vector3,
		finish: Vector3, thickness: float, material: Material) -> MeshInstance3D:
	var delta := finish - start
	var beam := _add_box(parent, node_name,
		Vector3(thickness, delta.length(), thickness), (start + finish) * 0.5, material)
	beam.quaternion = Quaternion(Vector3.UP, delta.normalized())
	return beam


## Builds one continuous downhill ribbon between two Z/Y endpoints. The box's
## long axis follows the actual grade instead of presenting a level underside.
func _add_sloped_box(parent: Node3D, node_name: String, width: float, thickness: float,
		from_zy: Vector2, to_zy: Vector2, material: Material) -> MeshInstance3D:
	return _add_sloped_box_at_x(parent, node_name, HYDRAULIC_AXIS_X, width,
		thickness, from_zy, to_zy, material)


func _add_sloped_box_at_x(parent: Node3D, node_name: String, axis_x: float,
		width: float, thickness: float, from_zy: Vector2, to_zy: Vector2,
		material: Material) -> MeshInstance3D:
	var delta := to_zy - from_zy
	var length := delta.length()
	var centre := (from_zy + to_zy) * 0.5
	var ribbon := _add_box(parent, node_name, Vector3(width, thickness, length),
		Vector3(axis_x, centre.y, centre.x), material)
	ribbon.rotation.x = atan2(-delta.y, delta.x)
	return ribbon


## Low continuous cheeks contain each water run without recreating R11's tall
## rail forest. Their top edge sits just above the water and their underside
## follows the same grade, so the channel reads thick and supported in profile.
func _add_channel_banks(parent: Node3D, name_prefix: String, water_width: float,
		bank_width: float, from_zy: Vector2, to_zy: Vector2,
		material: Material) -> void:
	_add_channel_banks_at_x(parent, name_prefix, HYDRAULIC_AXIS_X, water_width,
		bank_width, from_zy, to_zy, material)


func _add_channel_banks_at_x(parent: Node3D, name_prefix: String, axis_x: float,
		water_width: float, bank_width: float, from_zy: Vector2, to_zy: Vector2,
		material: Material) -> void:
	var offset := water_width * 0.5 + bank_width * 0.5
	var raised_from := from_zy + Vector2(0.0, 0.10)
	var raised_to := to_zy + Vector2(0.0, 0.10)
	_add_sloped_box_at_x(parent, name_prefix + "Left", axis_x - offset,
		bank_width, 0.54, raised_from, raised_to, material)
	_add_sloped_box_at_x(parent, name_prefix + "Right", axis_x + offset,
		bank_width, 0.54, raised_from, raised_to, material)


## R5 polish: the R4 wheel finally belongs to the building, but the retained
## production review still reads the site as an inert mill beside a crossing.
## A compact load at the mill's established +Z door gives the practical light
## an actual job and ties the building to the bridge economy. These are
## visual-only installed props parented to the mill; the prefab and crossing
## remain the only collision owners.
func _build_loading_activity(mill: Node3D) -> void:
	var yard := Node3D.new()
	yard.name = "OldMillLoadingActivity"
	mill.add_child(yard)
	var placements := [
		{"id": "FlourBagA", "kind": "Bag", "at": Vector3(1.55, 0.05, 3.7), "yaw": -18.0, "scale": 1.05},
		{"id": "FlourBagB", "kind": "Bag", "at": Vector3(2.25, 0.05, 3.58), "yaw": 31.0, "scale": 0.94},
		{"id": "FlourBagC", "kind": "Bag", "at": Vector3(1.9, 0.6, 3.64), "yaw": 8.0, "scale": 0.88},
		{"id": "FlourBagD", "kind": "Bag", "at": Vector3(2.85, 0.05, 3.38), "yaw": -27.0, "scale": 0.82},
		{"id": "LoadingCrateA", "kind": "Crate", "at": Vector3(3.28, 0.06, 2.82), "yaw": 12.0, "scale": 0.9},
		{"id": "LoadingCrateB", "kind": "Crate", "at": Vector3(3.3, 0.84, 2.82), "yaw": -7.0, "scale": 0.72},
		{"id": "MealBarrel", "kind": "Barrel", "at": Vector3(3.78, 0.04, 3.62), "yaw": 0.0, "scale": 0.92},
		{"id": "HandCart", "kind": "Cart", "at": Vector3(4.6, 0.03, 1.62), "yaw": -72.0, "scale": 0.84},
		{"id": "BarrelRack", "kind": "BarrelHolder", "at": Vector3(0.95, 0.03, 4.18), "yaw": 88.0, "scale": 0.88},
		{"id": "MillBucket", "kind": "Bucket", "at": Vector3(2.72, 0.04, 4.3), "yaw": 12.0, "scale": 0.82},
	]
	for spec: Dictionary in placements:
		var packed := WORK_YARD_PROPS.get(str(spec["kind"])) as PackedScene
		if packed == null:
			push_error("Old Mill loading prop is unavailable: %s" % str(spec["kind"]))
			continue
		var prop := packed.instantiate() as Node3D
		if prop == null:
			continue
		prop.name = str(spec["id"])
		prop.position = spec["at"] as Vector3
		prop.rotation.y = deg_to_rad(float(spec["yaw"]))
		prop.scale = Vector3.ONE * float(spec["scale"])
		yard.add_child(prop)


func _process(delta: float) -> void:
	var wheel := get_node_or_null("Mill/OldMillWaterWheel") as Node3D
	if wheel != null:
		# Slow enough that the paddles remain legible, persistent enough that a
		# player immediately reads working water machinery rather than sculpture.
		wheel.rotation.z = fposmod(wheel.rotation.z + delta * 0.22, TAU)


func _wheel_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	return material


## Two small, visible working lights make the mill and its mechanism legible
## without lifting Meadows night globally. R13 keeps exactly the two existing
## sources, retaining the door lantern and centring the race practical just
## above the axle so its bounded pool separates the headrace, wheel contact and
## first two tailwater steps. Neither receives collision.
const PRACTICAL_COLOUR := Color("#ffad68")
const PRACTICAL_RANGE_M := 13.5


func _build_practical_lights(world: Node3D, mill: Node3D) -> void:
	var lights := Node3D.new()
	lights.name = "OldMillPracticalLights"
	world.add_child(lights)

	# The mill prefab's ground-floor door is local +Z. Mounting this holder on
	# that authored face makes the source part of the building, not a floating
	# point light in the yard.
	var door_holder := Node3D.new()
	door_holder.name = "MillDoorPractical"
	var mill_world := mill.global_transform if mill.is_inside_tree() else mill.transform
	door_holder.transform = mill_world * Transform3D(
		Basis(Vector3.UP, PI), Vector3(1.55, 2.15, 3.18))
	lights.add_child(door_holder)
	_install_lantern(door_holder, Vector3.ZERO, 0.40)

	var race_holder := Node3D.new()
	race_holder.name = "WheelRacePractical"
	race_holder.transform = mill_world * Transform3D(Basis.IDENTITY,
		Vector3(HYDRAULIC_AXIS_X, 2.92, 0.12))
	lights.add_child(race_holder)
	_install_lantern(race_holder, Vector3.ZERO, 0.42)

	# A third ordinary post lantern belongs to the crossing approach, giving the
	# player a credible warm route source instead of leaving the path black while
	# the mechanism is inexplicably washed from off camera.
	var route_holder := Node3D.new()
	route_holder.name = "SouthApproachPractical"
	var route_xz := near_point(18.0)
	var route_right := Vector2(_across.y, -_across.x)
	route_xz += route_right * 3.4
	var route_ground := float(world.call("ground_height_at", route_xz.x, route_xz.y))
	route_holder.position = Vector3(route_xz.x, route_ground + 2.15, route_xz.y)
	lights.add_child(route_holder)
	var post_material := _wheel_material(Color("#513823"))
	_add_box(route_holder, "LanternPost", Vector3(0.18, 2.15, 0.18),
		Vector3(0.0, -1.05, 0.0), post_material)
	_install_lantern(route_holder, Vector3.ZERO, 0.28)


func _install_lantern(holder: Node3D, at: Vector3, fixture_scale: float) -> void:
	var fixture := WALL_LANTERN.instantiate() as Node3D
	fixture.name = "LanternFixture"
	fixture.position = at
	fixture.scale = Vector3.ONE * fixture_scale
	holder.add_child(fixture)
	var ember := MeshInstance3D.new()
	ember.name = "VisibleEmber"
	var ember_mesh := SphereMesh.new()
	ember_mesh.radius = 0.06
	ember_mesh.height = 0.12
	ember.mesh = ember_mesh
	var ember_material := StandardMaterial3D.new()
	ember_material.albedo_color = PRACTICAL_COLOUR
	ember_material.emission_enabled = true
	ember_material.emission = PRACTICAL_COLOUR
	# Keep the visible source amber under tonemapping. The R2 multiplier of 4
	# clipped this tiny sphere to white even though its authored colour was warm.
	ember_material.emission_energy_multiplier = 1.35
	ember.material_override = ember_material
	ember.position = at + Vector3(0.0, 0.02, 0.08)
	holder.add_child(ember)
	var pool := OmniLight3D.new()
	pool.name = "WarmPool"
	pool.light_color = PRACTICAL_COLOUR
	pool.light_energy = 4.0
	pool.omni_range = PRACTICAL_RANGE_M
	pool.shadow_enabled = false
	pool.position = at + Vector3(0.0, 0.0, 0.28)
	holder.add_child(pool)

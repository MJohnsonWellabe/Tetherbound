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
	var local := Vector3(float(offset[0]), 0.0, float(offset[1]))
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
	local.y = maxf(ground, deck_ground) - position.y
	mill.position = local
	add_child(mill)
	_add_prefab_colliders(prefabs, mill, str(spec.get("prefab", "mill")))
	_build_approach_sign(world)
	_build_visible_mill_wheel(mill)
	_build_grounded_mill_foundation(mill)
	_build_millrace(mill)
	_build_loading_activity(mill)
	_build_practical_lights(world, mill)


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
	# R13 keeps the accepted broadside wheel while replacing R12's exposed shelves
	# and long blunt ramp with one contained, touching downhill channel. Short runs,
	# raised banks and a compact cascade make the water read as water carried by a
	# structure rather than cyan plates hung beside the mill. Its final local height
	# is still the crossing river surface, not the mill-yard grade.
	var timber := _wheel_material(Color("#765437"))
	var stone := _wheel_material(Color("#625d52"))
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("#3d7180b8")
	water.metallic = 0.0
	water.roughness = 0.34
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	var foam := StandardMaterial3D.new()
	foam.albedo_color = Color("#b8cec8b8")
	foam.roughness = 0.3
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_add_box(race, "HeadpondWater", Vector3(1.82, 0.36, 1.60),
		Vector3(HYDRAULIC_AXIS_X, 4.56, -5.75), water)
	for i in 4:
		_add_box(race, "HeadpondPlank%02d" % i, Vector3(2.16, 0.20, 0.28),
			Vector3(HYDRAULIC_AXIS_X, 4.30, -6.34 + float(i) * 0.40), timber)
	_add_box(race, "HeadpondOuterRail", Vector3(0.22, 0.58, 1.88),
		Vector3(HYDRAULIC_AXIS_X - 1.02, 4.55, -5.75), timber)
	_add_box(race, "HeadpondInnerRail", Vector3(0.22, 0.58, 1.88),
		Vector3(HYDRAULIC_AXIS_X + 1.02, 4.55, -5.75), timber)
	_add_box(race, "HeadpondSill", Vector3(2.18, 0.40, 0.34),
		Vector3(HYDRAULIC_AXIS_X, 4.28, -4.95), timber)
	_add_sloped_box(race, "SourceIntakeWater", 1.46, 0.36,
		Vector2(-4.95, 4.48), Vector2(-4.35, 4.38), water)

	var headrace_beats := [
		{"name": "RunningWater", "from": Vector2(-4.35, 4.38), "to": Vector2(-3.35, 4.20)},
		{"name": "HeadraceWaterMid", "from": Vector2(-3.35, 4.20), "to": Vector2(-2.45, 4.00)},
		{"name": "HeadraceWaterLower", "from": Vector2(-2.45, 4.00), "to": Vector2(-1.65, 3.82)},
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
	_add_box(race, "SourceIntakeCrossbeam", Vector3(1.94, 0.26, 0.30),
		Vector3(HYDRAULIC_AXIS_X, 4.10, -4.28), timber)
	_add_box(race, "SluiceGate", Vector3(1.78, 0.70, 0.20),
		Vector3(HYDRAULIC_AXIS_X, 3.70, -1.65), timber)
	_add_sloped_box(race, "FeedDrop", 1.42, 0.38,
		Vector2(-1.65, 3.82), Vector2(-1.25, 3.54), water)
	_add_sloped_box(race, "PaddleContact", 1.38, 0.40,
		Vector2(-1.25, 3.54), Vector2(-0.78, 3.14), water)
	_add_box(race, "WheelSplash", Vector3(1.46, 0.24, 0.70),
		Vector3(HYDRAULIC_AXIS_X, 3.08, -0.68), water)
	_add_box(race, "FeedFoam", Vector3(1.30, 0.14, 0.30),
		Vector3(HYDRAULIC_AXIS_X, 3.52, -1.22), foam)

	# Water leaves the lower downstream quadrant in a stone/timber-lined race
	# that reaches back to the river axis. Keeping this under the mill root makes
	# the entire source -> wheel -> outfall relationship survive a future crossing
	# relocation without changing terrain, river collision, or gate mechanics.
	_add_sloped_box(race, "WheelDischarge", 1.44, 0.40,
		Vector2(0.72, 0.58), Vector2(1.30, -0.10), water)
	var tailrace_beats := [
		{"name": "TailraceWater", "from": Vector2(1.30, -0.10), "to": Vector2(2.10, -1.00), "width": 1.48},
		{"name": "TailraceMid", "from": Vector2(2.10, -1.00), "to": Vector2(3.00, -2.00), "width": 1.56},
		{"name": "TailraceMouth", "from": Vector2(3.00, -2.00), "to": Vector2(4.00, -3.10), "width": 1.66},
		{"name": "TailraceLower", "from": Vector2(4.00, -3.10), "to": Vector2(5.00, -4.25), "width": 1.78},
		{"name": "TailraceCascade", "from": Vector2(5.00, -4.25), "to": Vector2(6.10, -5.35), "width": 1.90},
	]
	for i in tailrace_beats.size():
		var beat: Dictionary = tailrace_beats[i]
		var from_point: Vector2 = beat["from"]
		var to_point: Vector2 = beat["to"]
		var width := float(beat["width"])
		_add_sloped_box(race, str(beat["name"]), width, 0.40, from_point, to_point, water)
		_add_sloped_box(race, "TailraceBed%02d" % i, width + 0.54, 0.42,
			from_point + Vector2(0.0, -0.38), to_point + Vector2(0.0, -0.38), stone)
		_add_channel_banks(race, "TailraceBank%02d" % i, width, 0.30,
			from_point, to_point, stone)
	var first_tailrace_bed := race.get_node_or_null("TailraceBed00") as Node3D
	if first_tailrace_bed != null:
		first_tailrace_bed.name = "TailraceBed"
	_add_sloped_box(race, "TailraceOutfall", 2.04, 0.44,
		Vector2(6.10, -5.35), Vector2(7.40, -6.60), water)
	_add_channel_banks(race, "OutfallBank", 2.04, 0.34,
		Vector2(6.10, -5.35), Vector2(7.40, -6.60), stone)
	_add_box(race, "TailraceFoam", Vector3(1.86, 0.14, 0.54),
		Vector3(HYDRAULIC_AXIS_X, -5.76, 7.36), foam)
	_add_box(race, "TailraceRiverToe", Vector3(2.36, 0.30, 1.34),
		Vector3(HYDRAULIC_AXIS_X, -6.04, 7.10), stone)

	# A single splayed timber trestle replaces R11's dark monolithic pier. Two
	# stone feet visibly carry crossed legs into a short cap directly below the
	# channel; the open centre preserves the broadside wheel silhouette.
	_add_box(race, "HeadracePierFoot", Vector3(1.18, 0.34, 0.66),
		Vector3(HYDRAULIC_AXIS_X, 0.17, -4.62), stone)
	_add_box(race, "HeadracePierFootInner", Vector3(1.18, 0.34, 0.66),
		Vector3(HYDRAULIC_AXIS_X, 0.17, -3.52), stone)
	_add_beam_between(race, "HeadracePierShaft",
		Vector3(HYDRAULIC_AXIS_X, 0.34, -4.62),
		Vector3(HYDRAULIC_AXIS_X, 3.92, -3.72), 0.24, timber)
	_add_beam_between(race, "HeadracePierBrace",
		Vector3(HYDRAULIC_AXIS_X, 0.34, -3.52),
		Vector3(HYDRAULIC_AXIS_X, 3.92, -4.16), 0.24, timber)
	_add_box(race, "HeadracePierCap", Vector3(1.52, 0.24, 1.42),
		Vector3(HYDRAULIC_AXIS_X, 4.00, -3.94), timber)
	_add_beam_between(race, "HeadraceWallBearer",
		Vector3(-6.98, 3.86, -2.65), Vector3(-5.05, 3.30, -2.18), 0.24, timber)


## The prefab is correctly seated at the crossing deck, but its water-side half
## overhangs the river cut. A mill in that position needs masonry carried down
## into the bank, not a thin bright floor hovering over the gorge. This compact
## stepped foundation remains visual-only so the already accepted prefab and
## bridge collision stay authoritative.
func _build_grounded_mill_foundation(mill: Node3D) -> void:
	var foundation := Node3D.new()
	foundation.name = "OldMillGroundedFoundation"
	mill.add_child(foundation)
	# R13 removes R12's ten stacked masonry boxes. Two open timber bents now carry
	# the water-side building corners down to four compact stone feet at the river
	# cut. Angled legs and braces show load transfer while leaving the wheel and
	# water readable; every piece remains visual-only.
	var stone_low := _wheel_material(Color("#665d50"))
	var timber := _wheel_material(Color("#62452f"))
	for side in 2:
		var side_name := "Upstream" if side == 0 else "Downstream"
		var z := -2.15 if side == 0 else 2.15
		_add_box(foundation, "GroundedToe%s" % side_name, Vector3(1.28, 0.50, 1.18),
			Vector3(-5.72, -6.50, z), stone_low)
		_add_box(foundation, "GroundedToeInner%s" % side_name, Vector3(1.18, 0.46, 1.10),
			Vector3(-3.72, -6.48, z), stone_low)
		_add_beam_between(foundation, "BentOuterLeg%s" % side_name,
			Vector3(-5.72, -6.24, z), Vector3(-5.10, -0.34, z), 0.34, timber)
		_add_beam_between(foundation, "BentInnerLeg%s" % side_name,
			Vector3(-3.72, -6.24, z), Vector3(-4.38, -0.34, z), 0.34, timber)
		_add_beam_between(foundation, "BentCrossBrace%s" % side_name,
			Vector3(-5.55, -5.70, z - 0.04), Vector3(-4.05, -0.78, z - 0.04), 0.22, timber)
		_add_box(foundation, "BentCap%s" % side_name, Vector3(2.60, 0.34, 0.58),
			Vector3(-4.72, -0.20, z), timber)


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
	var offset := water_width * 0.5 + bank_width * 0.5
	var raised_from := from_zy + Vector2(0.0, 0.10)
	var raised_to := to_zy + Vector2(0.0, 0.10)
	_add_sloped_box_at_x(parent, name_prefix + "Left", HYDRAULIC_AXIS_X - offset,
		bank_width, 0.54, raised_from, raised_to, material)
	_add_sloped_box_at_x(parent, name_prefix + "Right", HYDRAULIC_AXIS_X + offset,
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
const PRACTICAL_COLOUR := Color("#ff8f32")
const PRACTICAL_RANGE_M := 6.8


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
	_install_lantern(door_holder, Vector3.ZERO, 0.32)

	var race_holder := Node3D.new()
	race_holder.name = "WheelRacePractical"
	race_holder.transform = mill_world * Transform3D(Basis.IDENTITY,
		Vector3(HYDRAULIC_AXIS_X, 2.92, 0.12))
	lights.add_child(race_holder)
	_install_lantern(race_holder, Vector3.ZERO, 0.34)


func _install_lantern(holder: Node3D, at: Vector3, fixture_scale: float) -> void:
	var fixture := WALL_LANTERN.instantiate() as Node3D
	fixture.name = "LanternFixture"
	fixture.position = at
	fixture.scale = Vector3.ONE * fixture_scale
	holder.add_child(fixture)
	var ember := MeshInstance3D.new()
	ember.name = "VisibleEmber"
	var ember_mesh := SphereMesh.new()
	ember_mesh.radius = 0.07
	ember_mesh.height = 0.14
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
	pool.light_energy = 2.45
	pool.omni_range = PRACTICAL_RANGE_M
	pool.shadow_enabled = false
	pool.position = at + Vector3(0.0, 0.0, 0.28)
	holder.add_child(pool)

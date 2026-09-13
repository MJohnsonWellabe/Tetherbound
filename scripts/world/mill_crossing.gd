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
const FOUNDATION_WALL := preload("res://assets/buildings/quaternius_medieval/Wall_UnevenBrick_Straight.gltf")
const FOUNDATION_FLOOR := preload("res://assets/buildings/quaternius_medieval/Floor_UnevenBrick.gltf")
const TIMBER_SUPPORT := preload("res://assets/buildings/quaternius_medieval/Prop_Support.gltf")
const FOUNDATION_ROCKS := [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
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
# R6 moves the visible wheel outboard of the prefab's smooth lower wall while
# retaining the prefab axle's height and centre line. The longer drive shaft
# below visibly returns to the wall, so this reads as one machine rather than a
# second decorative wheel hidden behind the foundation plane.
const HERO_WHEEL_AXLE := Vector3(-6.05, 2.15, 0.0)


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
	# The race is exposed from below at ordinary river-bank height. Near-black
	# timber turned the entire flume into one opaque placeholder slab, so use the
	# same warm mill timber family at a readable mid-value and support it as an
	# actual elevated waterwork.
	var timber := _wheel_material(Color("#795536"))
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("#5b8992a8")
	water.metallic = 0.0
	water.roughness = 0.16
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	var foam := StandardMaterial3D.new()
	foam.albedo_color = Color("#bfd7d2c0")
	foam.roughness = 0.3
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# R6 is a whole hydraulic composition, not another flume refinement. A broad
	# elevated headpond is the unmistakable source, a supported narrow headrace
	# carries it in open air, and the outboard wheel remains fully visible beside
	# the masonry. The sequence lies in the wheel's YZ plane from source to river.
	_add_box(race, "HeadpondWater", Vector3(3.70, 0.10, 3.10),
		Vector3(-6.05, 5.18, -10.55), water)
	for i in 5:
		_add_box(race, "HeadpondPlank%02d" % i, Vector3(3.92, 0.12, 0.58),
			Vector3(-6.05, 5.02, -11.72 + float(i) * 0.58), timber)
	_add_box(race, "HeadpondOuterRail", Vector3(0.18, 0.52, 3.30),
		Vector3(-8.02, 5.25, -10.55), timber)
	_add_box(race, "HeadpondInnerRail", Vector3(0.18, 0.52, 3.30),
		Vector3(-4.08, 5.25, -10.55), timber)
	_add_box(race, "HeadpondSill", Vector3(4.20, 0.28, 0.34),
		Vector3(-6.05, 4.88, -9.05), timber)
	for side in 2:
		var shoulder_x := -8.05 if side == 0 else -4.05
		var shoulder_suffix := "Outer" if side == 0 else "Inner"
		_add_foundation_module(race, "IntakeShoulder%s" % ("Outer" if side == 0 else "Inner"),
			FOUNDATION_WALL, Vector3(shoulder_x, 3.54, -10.55), 0.0)
		_add_foundation_module(race, "IntakeFoot%s" % shoulder_suffix,
			FOUNDATION_ROCKS[side] as PackedScene, Vector3(shoulder_x, 0.02, -10.55),
			22.0 + float(side) * 37.0)

	_add_box(race, "TroughBed", Vector3(0.18, 0.18, 7.75),
		Vector3(-6.58, 5.03, -5.18), timber)
	_add_box(race, "TroughOuterStringer", Vector3(0.18, 0.18, 7.75),
		Vector3(-5.52, 5.03, -5.18), timber)
	for i in 10:
		_add_box(race, "TroughPlank%02d" % i, Vector3(1.28, 0.10, 0.60),
			Vector3(-6.05, 5.08, -8.55 + float(i) * 0.76), timber)
	_add_box(race, "TroughNearRail", Vector3(0.14, 0.46, 7.75),
		Vector3(-6.72, 5.25, -5.18), timber)
	_add_box(race, "TroughFarRail", Vector3(0.14, 0.46, 7.75),
		Vector3(-5.38, 5.25, -5.18), timber)
	_add_box(race, "RunningWater", Vector3(1.08, 0.08, 7.62),
		Vector3(-6.05, 5.17, -5.22), water)
	_add_box(race, "SourceIntakeWater", Vector3(2.45, 0.09, 1.75),
		Vector3(-6.05, 5.17, -9.02), water)
	_add_box(race, "SourceIntakeCrossbeam", Vector3(1.92, 0.24, 0.28),
		Vector3(-6.05, 4.82, -8.72), timber)
	# A crosswise sluice and its two posts make the control point legible before
	# the visible ribbon falls onto the upper, upstream paddle quadrant.
	_add_box(race, "SluiceGate", Vector3(1.70, 0.76, 0.18),
		Vector3(-6.05, 5.05, -1.54), timber)
	for x in [-6.72, -5.38]:
		_add_box(race, "SluicePost%s" % ("Outer" if x < -6.05 else "Inner"),
			Vector3(0.16, 1.55, 0.18), Vector3(x, 4.74, -1.54), timber)
	# The short overshot cascade contacts only the upper upstream paddles. R4's
	# full-height sheet veiled the wheel face; this leaves its hub, lower rim and
	# discharge quadrant exposed in the same ordinary three-quarter view.
	_add_box(race, "FeedDrop", Vector3(0.92, 1.32, 0.14),
		Vector3(-6.05, 4.38, -1.47), water)
	_add_box(race, "WheelSplash", Vector3(1.12, 0.14, 0.66),
		Vector3(-6.05, 3.73, -1.28), water)
	_add_box(race, "FeedFoam", Vector3(1.12, 0.12, 0.3),
		Vector3(-6.05, 5.12, -1.47), foam)

	# Water leaves the lower downstream quadrant in a stone/timber-lined race
	# that reaches back to the river axis. Keeping this under the mill root makes
	# the entire source -> wheel -> outfall relationship survive a future crossing
	# relocation without changing terrain, river collision, or gate mechanics.
	_add_box(race, "TailraceBed", Vector3(2.05, 0.16, 7.70),
		Vector3(-6.05, -0.54, 5.20), timber)
	_add_box(race, "TailraceWater", Vector3(1.62, 0.08, 7.55),
		Vector3(-6.05, -0.38, 5.16), water)
	_add_box(race, "WheelDischarge", Vector3(1.26, 1.18, 0.14),
		Vector3(-6.05, 0.18, 1.62), water)
	for x in [-7.08, -5.02]:
		_add_box(race, "TailraceBank%s" % ("Outer" if x < -6.05 else "Inner"),
			Vector3(0.20, 0.52, 7.70), Vector3(x, -0.28, 5.20), timber)
	_add_box(race, "TailraceOutfall", Vector3(1.62, 0.44, 0.16),
		Vector3(-6.05, -0.58, 8.98), water)
	_add_box(race, "TailraceFoam", Vector3(1.38, 0.08, 0.42),
		Vector3(-6.05, -0.28, 1.62), foam)

	# Four paired timber bents carry the raised headrace. They sit wholly on the
	# mill/water side and have no collision, preserving the accepted road and
	# crossing while eliminating the suspended-slab silhouette.
	for i in 4:
		var z := -8.10 + float(i) * 2.05
		for x in [-6.62, -5.48]:
			var suffix := "Outer" if x < -6.05 else "Inner"
			_add_box(race, "HeadraceBent%d%s" % [i, suffix],
				Vector3(0.24, 5.00, 0.24), Vector3(x, 2.50, z), timber)
			_add_foundation_module(race, "HeadraceFoot%d%s" % [i, suffix],
				FOUNDATION_ROCKS[i % FOUNDATION_ROCKS.size()] as PackedScene, Vector3(x, 0.02, z),
				25.0 + float(i * 19 + (0 if suffix == "Outer" else 11)))
		_add_box(race, "HeadraceCrossbeam%d" % i, Vector3(1.72, 0.26, 0.34),
			Vector3(-6.05, 4.86, z), timber)
		# Installed diagonal brackets visibly transfer the trough load into each
		# post pair. They supplement rather than replace the full-height posts.
		for side in 2:
			var support := TIMBER_SUPPORT.instantiate() as Node3D
			if support == null:
				continue
			support.name = "InstalledHeadraceBrace%d%s" % [i,
				"Outer" if side == 0 else "Inner"]
			support.position = Vector3(-6.72 if side == 0 else -5.38, 1.42, z)
			support.rotation.y = -PI * 0.5 if side == 0 else PI * 0.5
			race.add_child(support)


## The prefab is correctly seated at the crossing deck, but its water-side half
## overhangs the river cut. A mill in that position needs masonry carried down
## into the bank, not a thin bright floor hovering over the gorge. This compact
## stepped foundation remains visual-only so the already accepted prefab and
## bridge collision stay authoritative.
func _build_grounded_mill_foundation(mill: Node3D) -> void:
	var foundation := Node3D.new()
	foundation.name = "OldMillGroundedFoundation"
	mill.add_child(foundation)
	# R5 left the prefab's six-metre smooth lower box as the largest shape in the
	# hydraulic view. R6 brings two installed uneven-brick courses out in front of
	# that plane, reverses them so their worked face addresses the water, and
	# batters the lower course outward. Unequal returns and a rubble toe break the
	# rectangle into a plausible bank abutment while leaving the wheel outboard.
	for level in 2:
		var level_y := -5.18 + float(level) * 3.02
		var face_x := -4.72 + float(level) * 0.42
		for segment in 3:
			_add_foundation_module(foundation, "WaterFaceL%dS%d" % [level, segment],
				FOUNDATION_WALL, Vector3(face_x, level_y, -2.0 + float(segment) * 2.0), 90.0)
		for side in 2:
			var side_name := "Upstream" if side == 0 else "Downstream"
			var side_z := -3.16 if side == 0 else 3.32
			var return_count := 3 if side == 0 else 2
			for segment in return_count:
				_add_foundation_module(foundation,
					"%sReturnL%dS%d" % [side_name, level, segment], FOUNDATION_WALL,
					Vector3(-4.70 + float(segment) * 2.0, level_y, side_z),
					0.0 if side == 0 else 180.0)

	# Horizontal installed-brick floor cells cap each setback. They replace the
	# razor-straight gray ledges with a textured stepped plinth.
	for x_segment in 2:
		for z_segment in 3:
			_add_foundation_module(foundation, "LowerCourseCap%d_%d" % [x_segment, z_segment],
				FOUNDATION_FLOOR, Vector3(-4.55 + float(x_segment) * 2.0, -2.18,
					-2.0 + float(z_segment) * 2.0), 0.0)
			_add_foundation_module(foundation, "BankSeat%d_%d" % [x_segment, z_segment],
				FOUNDATION_FLOOR, Vector3(-4.92 + float(x_segment) * 2.0, -5.20,
					-2.0 + float(z_segment) * 2.0), 0.0)

	# Narrow brick piers frame an open wheel bay. Their separated silhouettes
	# preserve the wheel and tailwater view while visibly carrying the mill wall.
	for z in [-2.42, 2.42]:
		var pier_name := "Upstream" if z < 0.0 else "Downstream"
		for level in 2:
			_add_foundation_module(foundation, "WheelSideButtress%sL%d" % [pier_name, level],
				FOUNDATION_WALL, Vector3(-5.05, -5.18 + float(level) * 3.02, z), 90.0)

	for i in 7:
		var toe_z := -3.55 + float(i) * 1.12
		var rock := _add_foundation_module(foundation, "RubbleToe%02d" % i,
			FOUNDATION_ROCKS[i % FOUNDATION_ROCKS.size()] as PackedScene,
			Vector3(-5.30 - 0.18 * float(i % 2), -6.48 + 0.10 * float(i % 3), toe_z),
			float(17 + i * 29))
		if rock != null:
			rock.scale = Vector3(0.72 + 0.08 * float(i % 3), 0.48 + 0.06 * float(i % 2),
				0.76 + 0.05 * float((i + 1) % 3))


func _add_foundation_module(parent: Node3D, node_name: String, scene: PackedScene,
		at: Vector3, yaw_deg: float) -> Node3D:
	var module := scene.instantiate() as Node3D
	if module == null:
		push_error("Old Mill foundation module is unavailable: %s" % node_name)
		return null
	module.name = node_name
	module.position = at
	module.rotation.y = deg_to_rad(yaw_deg)
	parent.add_child(module)
	return module


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


## Two small, visible working lights make the mill's two human thresholds legible
## without lifting Meadows night globally: one is bolted to the loading door and
## one stands beside the south-bank workbench. Neither receives collision, and
## the work lamp stays 5.5m off the road centreline, outside the bridge approach.
const PRACTICAL_COLOUR := Color("#ff8f32")
const PRACTICAL_RANGE_M := 6.0
const SOUTH_WORK_LAMP := Vector2(-146.5, 4192.0)


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

	# A short timber post supports the second wall-lantern asset beside the
	# existing workbench. It is visual-only and never changes gate collision.
	var work_holder := Node3D.new()
	work_holder.name = "SouthWorkbenchPractical"
	var ground := float(world.call("ground_height_at", SOUTH_WORK_LAMP.x, SOUTH_WORK_LAMP.y))
	work_holder.position = Vector3(SOUTH_WORK_LAMP.x, ground, SOUTH_WORK_LAMP.y)
	lights.add_child(work_holder)
	var post := MeshInstance3D.new()
	post.name = "TimberPost"
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.14, 1.9, 0.14)
	post.mesh = post_mesh
	post.material_override = _wheel_material(HERO_WHEEL_DARK)
	post.position = Vector3(0.0, 0.95, 0.0)
	work_holder.add_child(post)
	var arm := MeshInstance3D.new()
	arm.name = "SupportArm"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.65, 0.12, 0.12)
	arm.mesh = arm_mesh
	arm.material_override = _wheel_material(HERO_WHEEL_DARK)
	arm.position = Vector3(-0.25, 1.83, 0.0)
	work_holder.add_child(arm)
	_install_lantern(work_holder, Vector3(-0.52, 1.54, 0.0), 0.36)


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
	pool.light_energy = 2.35
	pool.omni_range = PRACTICAL_RANGE_M
	pool.shadow_enabled = false
	pool.position = at + Vector3(0.0, 0.0, 0.28)
	holder.add_child(pool)

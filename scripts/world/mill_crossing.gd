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
	_build_visible_mill_wheel(world, deck_ground)


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
## wall, but the south-bank player camera sees that wall through the retained
## riverside tree. This larger channel wheel is the crossing's readable hero
## shape: front-on to the approach, touching the same water and bridge, and
## built from the same rough timber palette as the bridge rail. It is visual
## dressing only; the existing mill and bridge colliders remain authoritative.
const HERO_WHEEL_RADIUS := 2.45
const HERO_WHEEL_SPOKES := 10
const HERO_WHEEL_COLOUR := Color("#6e4a28")
const HERO_WHEEL_DARK := Color("#3f2a18")


func _build_visible_mill_wheel(world: Node3D, deck_ground: float) -> void:
	var wheel := Node3D.new()
	wheel.name = "OldMillWaterWheel"
	wheel.position = Vector3(_centre.x + 7.2, deck_ground + 3.0, _centre.y - 1.5)
	world.add_child(wheel)

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


func _wheel_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	return material

extends Node3D

## SA4 — the seven old roads out of the Meadows, and what severed each of them.
##
## Spec §1E asks for seven outward routes so the Meadows does not read as an
## island. §29 is what stops that being seven dead ends: "Team Tether did not
## build seven random dead-end roads. They severed existing connections." So
## every spoke here is a ROAD FIRST — a real polyline in
## `terrain_playground.json`'s new `spokes` section, unioned into the path
## network by `playground_heightfield.road_polylines()`, which means the bake
## paints the same trodden soil along it that the village's own four routes
## get, the scatter keeps grass and trees off it, and path-anchored stone
## follows it out. Only then does something stand at the end of it.
##
## HARD RULE, from the backlog item and §19: none of this may ever explain
## itself with UI text. There is no prompt, no "Biome Locked", no interactable
## anywhere in this file. The only words on a spoke are on a fingerpost, and
## they name the place the road used to go, never its condition.
##
## What each kind is made of, and why nothing here is new vocabulary (D24):
##
##   `gorge` / `collapsed_bridge`  The blocker is the TERRAIN. Both carry a
##     `carve` block that `playground_heightfield._spoke_carve` cuts into the
##     heightfield at bake time, 11-16m deep with 57-66 degree walls — well
##     past the player's 45-degree `floor_max_angle`, so the ground itself
##     refuses. This file only dresses the lip: tumbled kerbstones off the
##     broken roadbed, and for the bridge two masonry abutments facing each
##     other across the channel with nothing between them.
##
##   `rockslide`  Props and collision, no terrain change and therefore no
##     re-bake. `Rock_Medium_*` from the one nature family, scaled far past
##     the meadow scatter's own ceiling so they read as slide debris rather
##     than as meadow stones, each with its own collider, over a buried
##     continuous barrier that closes the gaps between them. §1E allows
##     invisible collision "as support for visible boundaries, not as the only
##     boundary" — the barrier's top sits below the pile's own silhouette, so
##     it is never what the player sees, only what they cannot walk through.
##
## Masonry is the Quaternius medieval kit's `T_UnevenBrick` sheet, the same
## one `world_perimeter.gd`, `grandpa_house.gd` and every buildable already
## use. Rocks are the same three `Rock_Medium_*` meshes the vegetation scatter
## and the boundary's rock-formation style already place. No new asset, no
## generation.

const SPOKE_CONFIG := "res://data/config/terrain_playground.json"
const SIGNPOST := preload("res://scripts/world/signpost.gd")

const ROCK_MESHES := [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
## The `Rock_Medium_*` meshes stand about this tall at scale 1, measured the
## same way `world_perimeter.gd` measures them. Used to seat a block so it sits
## IN the ground rather than tangent to it.
const ROCK_MODEL_HEIGHT := 2.2

const STONE_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
const STONE_TILE := 3.2

## A tumbled kerbstone off the broken roadbed. Small, and small on purpose:
## these are the edge of a road, not boulders.
const KERB_SIZE := Vector3(0.9, 0.42, 0.62)

var _built: Array[String] = []
var _stone_material_cache: StandardMaterial3D = null


## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb `village.gd` and `road_gate.gd` use, and never a raycast (D09).
func build(world: Node3D) -> void:
	var config := _load_config()
	var routes: Array = config.get("routes", [])
	if routes.is_empty():
		push_warning("no `spokes.routes` in %s; the Meadows has no outward roads" % SPOKE_CONFIG)
		return
	var seed_value := int(config.get("seed", 0))

	for entry: Variant in routes:
		if not entry is Dictionary:
			continue
		var spoke: Dictionary = entry as Dictionary
		var id := str(spoke.get("id", ""))
		if id.is_empty():
			push_warning("a spoke entry has no `id` — skipped")
			continue
		if not bool(spoke.get("built", false)):
			continue
		var holder := Node3D.new()
		holder.name = "Spoke_%s" % id
		add_child(holder)
		_build_blocker(world, holder, spoke, seed_value)
		_build_sign(world, spoke, id)
		_built.append(id)


## Which spokes actually stood, for the boot log and for tests.
func built() -> Array[String]:
	return _built


func _build_blocker(world: Node3D, holder: Node3D, spoke: Dictionary, seed_value: int) -> void:
	var blocker: Dictionary = spoke.get("blocker", {})
	var kind := str(blocker.get("kind", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + hash(str(spoke.get("id", "")))
	match kind:
		"gorge":
			_build_gorge_lip(world, holder, blocker, rng)
		"collapsed_bridge":
			_build_collapsed_bridge(world, holder, blocker, rng)
		"rockslide":
			_build_rockslide(world, holder, blocker, rng)
		_:
			push_warning("spoke blocker kind '%s' is authored but has no builder yet" % kind)


## The carve is the blocker; this is the broken roadbed at its edge. Stones
## tipped along the near lip, and (for the gorge) the same again on the far
## lip so the road visibly RESUMES across the gap — §29's "distant land",
## close enough to read.
func _build_gorge_lip(world: Node3D, holder: Node3D, blocker: Dictionary, rng: RandomNumberGenerator) -> void:
	var carve: Dictionary = blocker.get("carve", {})
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var lip: float = float(carve.get("half_width", 9.0)) + float(carve.get("rim", 7.0)) * 0.85
	var span := float(blocker.get("lip_span", 11.0))
	var count := int(blocker.get("lip_stones", 9))
	var sides: Array = [1.0, -1.0] if bool(blocker.get("far_lip", false)) else [1.0]
	var transforms: Array = []
	for side: float in sides:
		for i in count:
			var along := (rng.randf() - 0.5) * 2.0 * span
			var out := lip + rng.randf_range(-0.9, 1.4)
			var at := centre + axis * along + across * (out * side)
			var ground := float(world.call("ground_height_at", at.x, at.y))
			if is_nan(ground):
				continue
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			basis = basis.rotated(axis3(axis), rng.randf_range(-0.55, 0.55))
			basis = basis.scaled(Vector3.ONE * rng.randf_range(0.85, 1.35))
			transforms.append(Transform3D(basis, Vector3(at.x, ground - 0.12, at.y)))
	if transforms.is_empty():
		return
	_batch_boxes(holder, "LipStones", KERB_SIZE, transforms)


## Two abutments and no deck. The gap between them is the carve; nothing this
## function places is walkable, and nothing bridges.
func _build_collapsed_bridge(world: Node3D, holder: Node3D, blocker: Dictionary, rng: RandomNumberGenerator) -> void:
	var carve: Dictionary = blocker.get("carve", {})
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var size: Dictionary = blocker.get("abutment", {})
	var width := float(size.get("width", 5.4))
	var depth := float(size.get("depth", 3.2))
	var height := float(size.get("height", 3.1))
	var stand: float = float(carve.get("half_width", 6.0)) + float(carve.get("rim", 5.0)) * 0.55

	var yaw := atan2(axis.x, axis.y)
	for side: float in [1.0, -1.0]:
		var at := centre + across * (stand * side)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var block := _stone_box(Vector3(width, height, depth))
		block.name = "Abutment_%s" % ("near" if side > 0.0 else "far")
		block.position = Vector3(at.x, ground - 0.9 + height * 0.5, at.y)
		block.rotation.y = yaw
		holder.add_child(block)
		_add_box_collider(holder, block.position, Vector3(width, height, depth), yaw)

	if bool(blocker.get("fallen_beam", true)):
		var at := centre + across * (stand * 0.55)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if not is_nan(ground):
			var beam := _stone_box(Vector3(0.55, 0.42, 6.2))
			beam.name = "FallenDeck"
			beam.position = Vector3(at.x, ground + 0.9, at.y)
			beam.rotation.y = yaw
			beam.rotate_object_local(Vector3.RIGHT, deg_to_rad(38.0))
			holder.add_child(beam)

	_build_gorge_lip(world, holder, blocker, rng)


## The one blocker that needs no terrain change: a slide of mountain rock
## lying across the trail, over a buried barrier that closes the gaps.
func _build_rockslide(world: Node3D, holder: Node3D, blocker: Dictionary, rng: RandomNumberGenerator) -> void:
	var centre := _vec2(blocker.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(blocker.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var span := float(blocker.get("span", 24.0))
	var half := span * 0.5

	var blocks := int(blocker.get("blocks", 13))
	var scale_min := float(blocker.get("block_scale_min", 1.8))
	var scale_max := float(blocker.get("block_scale_max", 3.6))
	for i in blocks:
		# Spread the big stones evenly across the trail rather than randomly:
		# a random draw leaves holes, and a hole in a rockslide is a route.
		var t := (float(i) + rng.randf_range(0.25, 0.75)) / float(blocks)
		var along := lerpf(-half, half, t)
		var at := centre + axis * along + across * rng.randf_range(-2.2, 2.2)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var scale := rng.randf_range(scale_min, scale_max)
		var rock := MeshInstance3D.new()
		rock.name = "Slide_%d" % i
		rock.mesh = _rock_mesh(rng.randi() % ROCK_MESHES.size())
		rock.scale = Vector3.ONE * scale
		rock.rotation.y = rng.randf_range(0.0, TAU)
		rock.rotate_object_local(Vector3.RIGHT, rng.randf_range(-0.35, 0.35))
		# Bury a fifth of each block, the way the mound anchors do, so the
		# slide sits in the hillside instead of resting on it.
		rock.position = Vector3(at.x, ground - ROCK_MODEL_HEIGHT * scale * 0.2, at.y)
		holder.add_child(rock)

	var rubble := int(blocker.get("rubble", 18))
	var rubble_min := float(blocker.get("rubble_scale_min", 0.3))
	var rubble_max := float(blocker.get("rubble_scale_max", 0.9))
	for i in rubble:
		var at := centre + axis * rng.randf_range(-half * 1.25, half * 1.25) \
			+ across * rng.randf_range(-6.5, 6.5)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var scale := rng.randf_range(rubble_min, rubble_max)
		var stone := MeshInstance3D.new()
		stone.name = "Rubble_%d" % i
		stone.mesh = _rock_mesh(rng.randi() % ROCK_MESHES.size())
		stone.scale = Vector3.ONE * scale
		stone.rotation.y = rng.randf_range(0.0, TAU)
		stone.position = Vector3(at.x, ground - ROCK_MODEL_HEIGHT * scale * 0.25, at.y)
		holder.add_child(stone)

	# The buried barrier. Segmented so it follows the ground the pile lies on
	# rather than hanging over a dip at one end, exactly the failure OF7 fixed
	# in the boundary ring.
	var barrier_height := float(blocker.get("barrier_height", 4.2))
	var thickness := float(blocker.get("barrier_thickness", 3.6))
	var segments := 8
	var yaw := atan2(axis.x, axis.y) + PI * 0.5
	for i in segments:
		var t := (float(i) + 0.5) / float(segments)
		var at := centre + axis * lerpf(-half, half, t)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var length := span / float(segments) + 1.2
		var mid := Vector3(at.x, ground - 1.0 + barrier_height * 0.5, at.y)
		_add_box_collider(holder, mid, Vector3(length, barrier_height, thickness), yaw)


## Old signage, §29's own word for it. One arm, one destination, through
## `signpost.gd`'s `routes_override` — the same object `paths.trailheads`
## already plants at the Rise road's end. It names where the road WENT. It
## says nothing about why you cannot follow it; the gorge says that.
func _build_sign(world: Node3D, spoke: Dictionary, id: String) -> void:
	var sign_data: Dictionary = spoke.get("sign", {})
	if sign_data.is_empty():
		return
	var at := _vec2(sign_data.get("at", []))
	var label := str(sign_data.get("label", ""))
	var points: Array = sign_data.get("points", [])
	if at == Vector2.INF or label.is_empty() or points.size() < 2:
		push_warning("spoke %s has a malformed `sign` — skipped" % id)
		return
	var post: Node3D = SIGNPOST.new()
	post.name = "SpokeSign_%s" % id
	add_child(post)
	post.call("build", world, at, [{"label": label, "points": points}])


func _rock_mesh(index: int) -> Mesh:
	var scene: PackedScene = ROCK_MESHES[index]
	var root: Node = scene.instantiate()
	var found: Mesh = null
	for child: Node in _all_children(root):
		if child is MeshInstance3D:
			found = (child as MeshInstance3D).mesh
			break
	root.queue_free()
	return found


func _all_children(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child: Node in node.get_children():
		out.append_array(_all_children(child))
	return out


func _stone_box(size: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _stone_material()
	instance.mesh = mesh
	return instance


## One MultiMesh for every kerbstone on a lip: they are identical boxes and
## there can be twenty of them, which is one draw call's worth of work, not
## twenty nodes'. Same reasoning `vegetation.gd` and `world_perimeter.gd` use.
func _batch_boxes(parent: Node3D, node_name: String, size: Vector3, transforms: Array) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _stone_material()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	parent.add_child(instance)


func _add_box_collider(parent: Node3D, mid: Vector3, size: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision"
	body.position = mid
	body.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)


func _stone_material() -> StandardMaterial3D:
	if _stone_material_cache != null:
		return _stone_material_cache
	var material := StandardMaterial3D.new()
	material.albedo_texture = STONE_ALBEDO
	material.normal_enabled = true
	material.normal_texture = STONE_NORMAL
	material.roughness_texture = STONE_ROUGHNESS
	material.uv1_scale = Vector3(STONE_TILE, STONE_TILE, STONE_TILE)
	material.uv1_triplanar = true
	_stone_material_cache = material
	return material


func _vec2(raw: Variant) -> Vector2:
	var array: Array = raw as Array if raw is Array else []
	if array.size() < 2:
		return Vector2.INF
	return Vector2(float(array[0]), float(array[1]))


## The world-space axis a lip stone is tipped about: the carve's own direction,
## flattened into the XZ plane.
func axis3(axis: Vector2) -> Vector3:
	return Vector3(axis.x, 0.0, axis.y).normalized()


func _load_config() -> Dictionary:
	var file := FileAccess.open(SPOKE_CONFIG, FileAccess.READ)
	if file == null:
		push_error("cannot read %s" % SPOKE_CONFIG)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("spokes", {})

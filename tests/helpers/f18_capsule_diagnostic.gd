extends RefCounted

## Read-only physics observations for isolated probes and the actual entry. This
## never moves a body, changes a predicate or turns a failing check into PASS.
static func vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func collider(value: Object, rid: RID) -> Dictionary:
	var out := {"rid": str(rid)}
	if is_instance_valid(value):
		out["class"] = value.get_class()
		out["instance_id"] = value.get_instance_id()
		if value is Node: out["path"] = str(value.get_path()) if value.is_inside_tree() else str(value.name)
	return out

static func overlaps(actor: CharacterBody3D, query: PhysicsShapeQueryParameters3D) -> Dictionary:
	var hits: Array[Dictionary] = actor.get_world_3d().direct_space_state.intersect_shape(query, 32)
	var rows: Array[Dictionary] = []
	for hit: Dictionary in hits:
		rows.append({"collider": collider(hit.get("collider"), hit.get("rid", RID())), "shape": hit.get("shape", -1)})
	return {"origin": vector(query.transform.origin), "margin": query.margin, "hits": rows, "saturated": hits.size() == 32}

static func terrain_seam_report(arrival: Node, world: Node3D, actor: CharacterBody3D, target: Vector3, radius: float) -> void:
	# R4 Water entry has one missing support witness at x=-radius. The baked
	# neighboring tiles are present, finite and hole-free. Observe both the
	# original ray neighborhood and wider raw rays before choosing a repair.
	var terrain := world.get_node_or_null(^"Terrain") as Node3D
	if terrain == null or not terrain.is_class("Terrain3D"): return
	var data: Object = terrain.get("data")
	if data == null: return
	var before := actor.global_transform
	var rows: Array[Dictionary] = []
	var shapes := {}
	var tiles: Array[Dictionary] = []
	var native_collision: Object = terrain.call("get_collision")
	var terrain_rid: RID = native_collision.call("get_rid") if native_collision != null else RID()
	if terrain_rid.is_valid():
		var body_transform: Transform3D = PhysicsServer3D.body_get_state(terrain_rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
		for index in PhysicsServer3D.body_get_shape_count(terrain_rid):
			var shape := PhysicsServer3D.body_get_shape(terrain_rid, index)
			var transform := body_transform * PhysicsServer3D.body_get_shape_transform(terrain_rid, index)
			var tile := {"shape": index, "world_origin": vector(transform.origin),
				"shape_type": PhysicsServer3D.shape_get_type(shape)}
			if absf(transform.origin.x - target.x) < float(terrain.get("region_size")) * 0.75 \
				and absf(transform.origin.z - target.z) < float(terrain.get("region_size")) * 0.75 \
				and PhysicsServer3D.shape_get_type(shape) == PhysicsServer3D.SHAPE_HEIGHTMAP:
				var shape_data: Dictionary = PhysicsServer3D.shape_get_data(shape)
				var heights: PackedFloat32Array = shape_data.get("heights", PackedFloat32Array())
				tile["heightmap"] = {"width": shape_data.get("width"), "depth": shape_data.get("depth"), "height_count": heights.size()}
			tiles.append(tile)
	for dz: float in [-0.5, 0.0, 0.5]:
		for dx: float in [-1.0, -radius, -0.01, 0.0, 0.01, radius, 1.0]:
			var at := target + Vector3(dx, 0.0, dz)
			var height: float = world.call("ground_height_at", at.x, at.z)
			var raw_height: float = data.call("get_height", Vector3(at.x, 0.0, at.z))
			var row := {"at": vector(at), "sampled_height": height, "raw_data_height": raw_height,
				"accepted_support": not (arrival.call("_landing_hit", world, actor, at, radius) as Dictionary).is_empty()}
			for band: String in ["original", "wide"]:
				if band == "original" and not is_finite(height): continue
				var from := Vector3(at.x, height + radius, at.z) if band == "original" else Vector3(at.x, actor.global_position.y + 4.0, at.z)
				var to := Vector3(at.x, height - radius, at.z) if band == "original" else Vector3(at.x, actor.global_position.y - 4.0, at.z)
				var ray := PhysicsRayQueryParameters3D.create(from, to, actor.collision_mask, [actor.get_rid()])
				var hit := actor.get_world_3d().direct_space_state.intersect_ray(ray)
				var witness := {"from": vector(from), "to": vector(to), "hit": not hit.is_empty()}
				if not hit.is_empty():
					var rid: RID = hit.get("rid", RID())
					var index := int(hit.get("shape", -1))
					witness.merge({"point": vector(hit.position), "normal": vector(hit.normal),
						"shape": index, "collider": collider(hit.get("collider"), rid)})
					var key := str(rid) + ":" + str(index)
					if not shapes.has(key) and rid.is_valid():
						var count := PhysicsServer3D.body_get_shape_count(rid)
						if index >= 0 and index < count:
							var transform := PhysicsServer3D.body_get_shape_transform(rid, index)
							var body_transform: Transform3D = PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
							var shape := PhysicsServer3D.body_get_shape(rid, index)
							shapes[key] = {"body_shape_count": count, "local_origin": vector(transform.origin),
								"world_origin": vector((body_transform * transform).origin),
								"local_basis": [vector(transform.basis.x), vector(transform.basis.y), vector(transform.basis.z)],
								"shape_type": PhysicsServer3D.shape_get_type(shape)}
							if PhysicsServer3D.shape_get_type(shape) == PhysicsServer3D.SHAPE_HEIGHTMAP:
								var shape_data: Dictionary = PhysicsServer3D.shape_get_data(shape)
								var heights: PackedFloat32Array = shape_data.get("heights", PackedFloat32Array())
								shapes[key]["heightmap"] = {"keys": shape_data.keys(), "width": shape_data.get("width"),
									"depth": shape_data.get("depth"), "height_count": heights.size()}
				row[band] = witness
			rows.append(row)
	print("F18_TERRAIN_SEAM_DIAGNOSTIC " + JSON.stringify({"target": vector(target), "radius": radius,
		"vertex_spacing": terrain.get("vertex_spacing"), "region_size": terrain.get("region_size"),
		"collision_mode": terrain.get("collision_mode"), "actor_transform_unchanged": actor.global_transform == before,
		"rows": rows, "native_shapes": shapes, "terrain_collision_rid": str(terrain_rid), "native_tiles": tiles}))

static func report(arrival: Node, world: Node3D, actor: CharacterBody3D, target: Vector3, radius: float, label: String) -> void:
	var before := actor.global_transform
	var collision := actor.get_node_or_null(^"Collision") as CollisionShape3D
	var out := {"case": label, "actor_position": vector(actor.global_position), "target": vector(target),
		"safe_margin": actor.safe_margin, "radius": radius, "collision_mask": actor.collision_mask}
	var registered_shapes: Array[Dictionary] = []
	for i in PhysicsServer3D.body_get_shape_count(actor.get_rid()):
		var shape_rid := PhysicsServer3D.body_get_shape(actor.get_rid(), i)
		var shape_transform := PhysicsServer3D.body_get_shape_transform(actor.get_rid(), i)
		registered_shapes.append({"index": i, "rid": str(shape_rid), "type": PhysicsServer3D.shape_get_type(shape_rid),
			"local_origin": vector(shape_transform.origin)})
	out["registered_body"] = {"shapes": registered_shapes,
		"layer": PhysicsServer3D.body_get_collision_layer(actor.get_rid()), "mask": PhysicsServer3D.body_get_collision_mask(actor.get_rid()),
		"floor_stop_on_slope": actor.floor_stop_on_slope, "floor_snap_length": actor.floor_snap_length,
		"motion_mode": actor.motion_mode, "max_slides": actor.max_slides, "velocity": vector(actor.velocity)}
	out["guards"] = {"world_ancestor": world != null and world.is_ancestor_of(actor),
		"target_finite": target.is_finite(), "radius_finite_positive": is_finite(radius) and radius > 0.0,
		"margin_finite_positive_within_radius": is_finite(actor.safe_margin) and actor.safe_margin > 0.0 and actor.safe_margin <= radius,
		"collision_exists": collision != null, "shape_enabled": collision != null and not collision.disabled,
		"shape_is_capsule": collision != null and collision.shape is CapsuleShape3D}
	if collision != null and collision.shape is CapsuleShape3D:
		var shape_radius: float = (collision.shape as CapsuleShape3D).radius
		out.guards["shape_radius"] = shape_radius
		out.guards["radius_exact_match"] = shape_radius == radius
		out.guards["literal_point_four_exact_match"] = shape_radius == .4
	var surfaces: Array[Dictionary] = []
	var surface_rows: Array[Dictionary] = []
	var height := NAN
	var highest := -INF
	for offset: Vector2 in [Vector2.ZERO, Vector2(-radius, 0), Vector2(radius, 0), Vector2(0, -radius), Vector2(0, radius)]:
		var at := target + Vector3(offset.x, 0, offset.y)
		var hit: Dictionary = arrival.call("_landing_hit", world, actor, at, radius)
		var row := {"at": vector(at), "hit": not hit.is_empty()}
		if not hit.is_empty():
			if surfaces.is_empty(): height = float(hit.position.y)
			highest = maxf(highest, float(hit.position.y))
			surfaces.append(hit)
			row["point"] = vector(hit.position)
			row["normal"] = vector(hit.normal)
			row["collider"] = collider(hit.get("collider"), hit.get("rid", RID()))
			row["shape"] = hit.get("shape", -1)
			row["height_delta"] = float(hit.position.y) - height
			row["within_walkable_height_delta"] = absf(float(hit.position.y) - height) <= tan(actor.floor_max_angle) * radius
		surface_rows.append(row)
	out["surfaces"] = surface_rows
	if surfaces.size() == 5 and collision != null and collision.shape is CapsuleShape3D:
		var start := Vector3(target.x, height + radius, target.z)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collision.shape
		var proposed_pose := actor.global_transform
		proposed_pose.origin = start
		query.transform = proposed_pose * collision.transform
		query.collision_mask = actor.collision_mask
		query.exclude = [actor.get_rid()]
		out["start_actor_origin"] = vector(start)
		out["start_overlaps"] = overlaps(actor, query)
		query.motion = Vector3(0, -2.0 * radius, 0)
		var fractions: PackedFloat32Array = actor.get_world_3d().direct_space_state.cast_motion(query)
		out["motion"] = vector(query.motion)
		out["fractions"] = Array(fractions)
		if fractions.size() == 2 and is_finite(fractions[0]) and is_finite(fractions[1]) \
			and fractions[0] >= 0.0 and fractions[0] <= fractions[1] and fractions[1] <= 1.0:
			var unsafe_pose := actor.global_transform
			unsafe_pose.origin = start + query.motion * fractions[1]
			var motion := PhysicsTestMotionParameters3D.new()
			motion.from = unsafe_pose
			motion.motion = Vector3.ZERO
			motion.margin = actor.safe_margin
			motion.recovery_as_collision = true
			motion.max_collisions = 32
			var result := PhysicsTestMotionResult3D.new()
			var collided := PhysicsServer3D.body_test_motion(actor.get_rid(), motion, result)
			var contact_rows: Array[Dictionary] = []
			for i in result.get_collision_count():
				var normal := result.get_collision_normal(i)
				var point := result.get_collision_point(i)
				var comparisons: Array[Dictionary] = []
				for surface: Dictionary in surfaces:
					comparisons.append({"same_rid_shape": result.get_collider_rid(i) == surface.rid and result.get_collider_shape(i) == surface.shape,
						"normal_equal_approx": normal.is_equal_approx(surface.normal),
						"signed_plane_distance": surface.normal.dot(point - surface.position)})
				contact_rows.append({"normal": vector(normal), "point": vector(point), "depth": result.get_collision_depth(i),
					"collider": collider(result.get_collider(i), result.get_collider_rid(i)), "shape": result.get_collider_shape(i),
					"walkable": normal.is_finite() and normal.length_squared() > 0.0 and normal.angle_to(Vector3.UP) <= actor.floor_max_angle,
					"support_comparisons": comparisons})
			var accepted_contacts: Array[Dictionary] = arrival.call("_walkable_contacts", actor, unsafe_pose)
			out["unsafe_zero_motion"] = {"actor_origin": vector(unsafe_pose.origin), "collided": collided,
				"count": result.get_collision_count(), "saturated": result.get_collision_count() == motion.max_collisions,
				"travel": vector(result.get_travel()), "contacts": contact_rows,
				"production_walkable_contact_count": accepted_contacts.size(),
				"production_contacts_on_support": arrival.call("_contacts_on_support", world, accepted_contacts, surfaces, actor.safe_margin)}
			var bracket := absf(query.motion.y) * (fractions[1] - fractions[0])
			var candidate_y: float = arrival.call("_cast_landing_y", float(start.y), float(query.motion.y),
				float(fractions[0]), float(actor.safe_margin), highest, bracket)
			var maximum_y: float = highest + actor.safe_margin + bracket
			var bounded_alternative := Vector3(target.x, maximum_y, target.z)
			proposed_pose.origin = bounded_alternative
			query.transform = proposed_pose * collision.transform
			query.motion = Vector3.ZERO
			out["bounded_alternative"] = {"origin": vector(bounded_alternative), "scalar_y": maximum_y,
				"within_radius": bounded_alternative.distance_to(Vector3(target.x, height, target.z)) <= radius,
				"overlaps": overlaps(actor, query)}
			if not is_finite(candidate_y):
				out["candidate"] = {"scalar_bound_refused": true, "maximum_y": highest + actor.safe_margin + bracket}
				out["actor_transform_unchanged"] = actor.global_transform == before
				print("F18_INITIAL_CAPSULE_DIAGNOSTIC " + JSON.stringify(out))
				return
			var landing := Vector3(target.x, candidate_y, target.z)
			out["candidate"] = {"origin": vector(landing), "center_floor": height, "highest_sample": highest,
				"cast_bracket_width": bracket, "maximum_y": highest + actor.safe_margin + bracket,
				"scalar_y": candidate_y, "within_maximum_y": candidate_y <= highest + actor.safe_margin + bracket,
				"within_encoded_maximum_y": landing.y <= Vector3(0, highest + actor.safe_margin + bracket, 0).y,
				"distance_to_physical_center": landing.distance_to(Vector3(target.x, height, target.z)),
				"within_radius": landing.distance_to(Vector3(target.x, height, target.z)) <= radius}
			proposed_pose.origin = landing
			query.transform = proposed_pose * collision.transform
			query.motion = Vector3.ZERO
			out["end_overlaps"] = overlaps(actor, query)
	out["actor_transform_unchanged"] = actor.global_transform == before
	print("F18_INITIAL_CAPSULE_DIAGNOSTIC " + JSON.stringify(out))

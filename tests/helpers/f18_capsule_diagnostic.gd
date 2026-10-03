extends RefCounted

## Failure-only physics observations for the isolated arrival probes. This
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

static func report(arrival: Node, world: Node3D, actor: CharacterBody3D, target: Vector3, radius: float, label: String) -> void:
	var before := actor.global_transform
	var collision := actor.get_node_or_null(^"Collision") as CollisionShape3D
	var out := {"case": label, "actor_position": vector(actor.global_position), "target": vector(target),
		"safe_margin": actor.safe_margin, "radius": radius, "collision_mask": actor.collision_mask}
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

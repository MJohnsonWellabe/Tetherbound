extends SceneTree

## VP8 sentries restart (2026-09-02). Headless proof-of-primitive for the Hall
## gate sentries: boots the real playground scene exactly the way
## `tools/_capture_locations.gd::_run` does, then answers, from the live tree,
## every question five render rounds guessed at:
##   * does `Stronghold/GateSentries` exist, and how many children survived
##     `_build_gate_sentries()` (a failed `build_from_config` frees the body);
##   * for every node under the Stronghold whose name suggests sentry/grunt/
##     guard: path, global_position, visible / is_visible_in_tree, scale, and
##     whether a MeshInstance3D WITH a mesh lives under it (an empty Node3D is
##     "placed but not visible" by construction);
##   * the `10-stronghold` `gate-face` camera eye/look the tool computes --
##     replicated step for step from `_resolve` / `_shoot` / `_frame` with the
##     same RIG numbers, and the live `Stronghold.marker()` answers;
##   * each sentry's projected screen position at 1280x720, vfov 70, plus the
##     jambs' own, and whether anything solid stands on the camera->sentry ray.
##
##   godot --headless --path . --script tools/_probe_gate_sentries.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const BOOT_FRAMES := 90
const SETTLE_FRAMES := 40
const FOV := 70.0
const WIDTH := 1280.0
const HEIGHT := 720.0
## `_capture_locations.gd` RIG["standing"] and the gate-face shot's own keys.
const RIG_BACK := 3.2
const RIG_UP := 1.70
const LOOK_UP := 1.6
const PULL_BACK := -33.1

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[probe] world up, boot settled")
	_player = _world.get_node_or_null(^"Player") as Node3D

	var stronghold: Node = _world.get_node_or_null(^"Stronghold")
	if stronghold == null:
		print("FAIL no Stronghold node in the tree")
		quit(1)
		return
	var sh := stronghold as Node3D
	print("[probe] Stronghold at global %s  (yaw %.1f deg)" % [
		_v(sh.global_position), rad_to_deg(sh.rotation.y)])
	print("[probe] markers known: %s" % str(stronghold.call("marker_names")))
	var entrance: Vector3 = stronghold.call("marker", "entrance")
	var outer_works: Vector3 = stronghold.call("marker", "outer_works")
	print("[probe] marker entrance    %s" % _v(entrance))
	print("[probe] marker outer_works %s" % _v(outer_works))

	# --- 1. the sentry nodes themselves ------------------------------------
	var holder: Node = stronghold.get_node_or_null(^"GateSentries")
	if holder == null:
		print("[sentries] NO `GateSentries` holder under Stronghold -- _build_gate_sentries() never ran or bailed before add_child")
	else:
		print("[sentries] GateSentries holder: %d child(ren), visible=%s in_tree=%s" % [
			holder.get_child_count(), str((holder as Node3D).visible),
			str((holder as Node3D).is_visible_in_tree())])
	var found := 0
	for node in _all(stronghold):
		var lname := node.name.to_lower()
		var sname := ""
		if node.get_script() != null:
			sname = str((node.get_script() as Script).resource_path).to_lower()
		if not ("sentr" in lname or "grunt" in lname or "guard" in lname
				or "sentr" in sname or "grunt" in sname or "guard" in sname):
			continue
		found += 1
		var n3: Node3D = node as Node3D
		if n3 == null:
			print("[sentries] %s  (not a Node3D)" % _path(stronghold, node))
			continue
		var meshes := 0
		var meshes_with_mesh := 0
		var skeletons := 0
		var aabb_min := Vector3(INF, INF, INF)
		var aabb_max := Vector3(-INF, -INF, -INF)
		for sub in _all(node):
			if sub is Skeleton3D:
				skeletons += 1
			if sub is MeshInstance3D:
				meshes += 1
				var mi := sub as MeshInstance3D
				if mi.mesh != null:
					meshes_with_mesh += 1
					var box := mi.get_aabb()
					var gt := mi.global_transform
					for cx in 2:
						for cy in 2:
							for cz in 2:
								var corner := box.position + Vector3(
									box.size.x * cx, box.size.y * cy, box.size.z * cz)
								var g := gt * corner
								aabb_min = aabb_min.min(g)
								aabb_max = aabb_max.max(g)
		print("[sentries] %s" % _path(stronghold, node))
		print("           global_pos %s  local_pos %s  scale %s  yaw %.1f" % [
			_v(n3.global_position), _v(n3.position), _v(n3.scale), rad_to_deg(n3.global_rotation.y)])
		print("           visible=%s  visible_in_tree=%s  script=%s" % [
			str(n3.visible), str(n3.is_visible_in_tree()), sname])
		print("           MeshInstance3D: %d (with mesh: %d)  Skeleton3D: %d" % [
			meshes, meshes_with_mesh, skeletons])
		if meshes_with_mesh > 0:
			print("           render-ish AABB (global, via get_aabb*global_transform): min %s max %s  => height %.2fm" % [
				_v(aabb_min), _v(aabb_max), aabb_max.y - aabb_min.y])
			if node.has_method("body_material"):
				var mat: Material = node.call("body_material")
				print("           body_material: %s" % (str(mat) if mat != null else "null"))
		if node.has_method("has_model"):
			print("           has_model()=%s  height()=%.2f" % [
				str(node.call("has_model")), float(node.call("height"))])
		for sub in _all(node):
			if sub is AnimationPlayer:
				var ap := sub as AnimationPlayer
				print("           AnimationPlayer '%s': current='%s' playing=%s clips=%s" % [
					ap.name, ap.current_animation, str(ap.is_playing()), str(ap.get_animation_list())])
	if found == 0:
		print("[sentries] NOTHING under Stronghold matches sentr/grunt/guard by name or script")

	# --- 2. the gate-face camera, replicated from _capture_locations.gd ------
	# _resolve: marker -> eye (floor = marker y), look_marker -> look, pull_back
	var eye := Vector2(entrance.x, entrance.z)
	var look := Vector2(outer_works.x, outer_works.z)
	var look_floor := outer_works.y
	var away := (eye - look).normalized()
	eye += away * PULL_BACK
	var floor_hint := NAN
	# _shoot: the tool first seats the PLAYER on the eye (analytic, then ray)
	# so Terrain3D streams there; replicate so the raycast sees real ground.
	var seat: float = float(_field.height_at(eye.x, eye.y))
	if _player != null:
		_player.global_position = Vector3(eye.x, seat + 0.4, eye.y)
	for i in SETTLE_FRAMES:
		await physics_frame
	var toward := (look - eye).normalized()
	var ground_raw := _surface(eye)
	var eye_cleared := _clear_of_bodies(eye, toward, ground_raw)
	var ground := _surface(eye_cleared)
	var back := eye_cleared - toward * RIG_BACK
	var back_ground := _ground_at(back, floor_hint)
	var cam_pos := Vector3(back.x, back_ground + RIG_UP, back.y)
	var cam_target := Vector3(look.x, look_floor + LOOK_UP, look.y)
	print("")
	print("[camera] gate-face: resolved eye (%.2f, %.2f) ground %.2f -> cleared (%.2f, %.2f) ground %.2f" % [
		eye.x, eye.y, ground_raw, eye_cleared.x, eye_cleared.y, ground])
	print("[camera] back point (%.2f, %.2f) ground %.2f  => CAMERA POS %s  LOOK AT %s" % [
		back.x, back.y, back_ground, _v(cam_pos), _v(cam_target)])
	var forward := (cam_target - cam_pos).normalized()
	print("[camera] forward %s  pitch %.1f deg" % [_v(forward), rad_to_deg(asin(forward.y))])
	if _player != null:
		print("[camera] player ruler at %s" % _v(_player.global_position))

	# --- 3. projections ------------------------------------------------------
	print("")
	var jamb_l: Vector3 = sh.to_global(Vector3(-2.45, _floor_y_of(sh, outer_works) , -13.1))
	var jamb_r: Vector3 = sh.to_global(Vector3(2.45, _floor_y_of(sh, outer_works), -13.1))
	_project("jamb west (base)", jamb_l, cam_pos, forward)
	_project("jamb east (base)", jamb_r, cam_pos, forward)
	if holder != null:
		for child in holder.get_children():
			var body: Node3D = child as Node3D
			if body == null:
				continue
			var feet := body.global_position
			var head := feet + Vector3(0.0, 1.8, 0.0)
			var f := _project("%s feet" % body.name, feet, cam_pos, forward)
			var h := _project("%s head" % body.name, head, cam_pos, forward)
			if f.size() == 2 and h.size() == 2:
				print("           => on-screen height %.0f px, distance %.1f m" % [
					absf(f[1] - h[1]), cam_pos.distance_to(feet)])
			_ray_check(cam_pos, feet + Vector3(0.0, 0.9, 0.0), body)
			_seat_check(feet, body)
	# lights near the posts
	print("")
	var post_mid := sh.to_global(Vector3(0.0, _floor_y_of(sh, outer_works), -13.1))
	for node in _all(stronghold):
		if node is OmniLight3D or node is SpotLight3D:
			var l := node as Light3D
			var d := l.global_position.distance_to(post_mid)
			if d <= 14.0:
				print("[light] %s at %s  d=%.1f m  energy %.2f  range %.1f  visible=%s" % [
					_path(stronghold, node), _v(l.global_position), d, l.light_energy,
					float(l.get("omni_range")) if l is OmniLight3D else float(l.get("spot_range")),
					str(l.is_visible_in_tree())])
	quit(0)


func _floor_y_of(sh: Node3D, outer_works: Vector3) -> float:
	# outer_works' marker is to_global(centre.x, _floor_y, centre.z).
	return sh.to_local(outer_works).y


## Returns [sx, sy] or [] when behind the camera.
func _project(label: String, p: Vector3, cam: Vector3, forward: Vector3) -> Array:
	var right := forward.cross(Vector3.UP).normalized()
	var up := right.cross(forward).normalized()
	var d := p - cam
	var z := d.dot(forward)
	var scale := (HEIGHT * 0.5) / tan(deg_to_rad(FOV * 0.5))
	if z <= 0.01:
		print("[project] %-24s %s  BEHIND CAMERA (z %.2f)" % [label, _v(p), z])
		return []
	var sx := WIDTH * 0.5 + d.dot(right) / z * scale
	var sy := HEIGHT * 0.5 - d.dot(up) / z * scale
	var on := sx >= 0.0 and sx <= WIDTH and sy >= 0.0 and sy <= HEIGHT
	print("[project] %-24s %s  -> px (%.0f, %.0f)  %s" % [
		label, _v(p), sx, sy, "on-screen" if on else "OFF-SCREEN"])
	return [sx, sy]


## Is there a walkable surface directly under the feet, and how far off it are they?
func _seat_check(feet: Vector3, body: Node) -> void:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return
	var query := PhysicsRayQueryParameters3D.create(feet + Vector3(0.0, 1.0, 0.0), feet - Vector3(0.0, 3.0, 0.0))
	query.collide_with_areas = false
	if _player != null:
		query.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("           seat under %s: NOTHING within 3m below the feet" % body.name)
	else:
		var y := float((hit["position"] as Vector3).y)
		print("           seat under %s: %s at y %.2f -> feet are %.2f m %s it" % [
			body.name, _path(_world, hit.get("collider") as Node), y, absf(feet.y - y),
			"above" if feet.y >= y else "BELOW"])


func _ray_check(from: Vector3, to: Vector3, body: Node) -> void:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	if _player != null:
		query.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("           ray camera->%s chest: clear (no collider between)" % body.name)
	else:
		var col: Node = hit.get("collider") as Node
		print("           ray camera->%s chest: BLOCKED by %s at %s (%.1f m from camera; body is %.1f m)" % [
			body.name, _path(_world, col), _v(hit["position"]),
			from.distance_to(hit["position"]), from.distance_to(to)])


## --- verbatim-equivalent helpers from _capture_locations.gd ---------------
func _is_interior(floor_hint: float) -> bool:
	return not is_nan(floor_hint)


func _ground_at(at: Vector2, floor_hint: float) -> float:
	if _is_interior(floor_hint):
		return floor_hint
	return _surface(at)


func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("  WARN no collision under (%.0f, %.0f); analytic %.2f may be under the surface" % [
			at.x, at.y, analytic])
		return analytic
	var col: Node = hit.get("collider") as Node
	print("  [surface] (%.1f, %.1f): analytic %.2f, ray hit %.2f on %s" % [
		at.x, at.y, analytic, float((hit["position"] as Vector3).y),
		_path(_world, col) if col != null else "?"])
	return float((hit["position"] as Vector3).y)


func _clear_of_bodies(eye: Vector2, toward: Vector2, ground: float) -> Vector2:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return eye
	var aside := Vector2(-toward.y, toward.x).normalized()
	var occupant := ""
	for attempt in 4:
		var candidate := eye if attempt == 0 else eye + aside * 2.0 * float(attempt)
		var query := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.6
		capsule.height = 2.6
		query.shape = capsule
		query.transform = Transform3D(Basis(), Vector3(candidate.x, ground + 1.45, candidate.y))
		query.collide_with_bodies = true
		query.collide_with_areas = false
		if _player != null:
			query.exclude = [_player.get_rid()]
		var blocker := ""
		for hit: Dictionary in space.intersect_shape(query, 4):
			var body: Node = hit.get("collider") as Node
			if body == null or _under_terrain(body):
				continue
			blocker = body.name
			if occupant == "":
				occupant = body.name
			break
		if blocker == "":
			if attempt > 0:
				print("  NOTE (%.0f,%.0f) was occupied by %s; landing moved %.1fm aside" % [
					eye.x, eye.y, occupant, (candidate - eye).length()])
			return candidate
	print("  WARN (%.0f,%.0f) is occupied by %s and four steps aside did not clear it" % [
		eye.x, eye.y, occupant])
	return eye


func _under_terrain(body: Node) -> bool:
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain == null:
		return false
	var node: Node = body
	while node != null:
		if node == terrain:
			return true
		node = node.get_parent()
	return false


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out


func _path(from: Node, node: Node) -> String:
	if node == null:
		return "(null)"
	return str(from.get_path_to(node))


func _v(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]

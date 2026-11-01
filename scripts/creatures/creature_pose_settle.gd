extends RefCounted

## Roster-wide hurt/faint settle (CAUSE-POSES lane, 1 Nov 2026; owner: fix
## shared causes, not item by item). Today's GPU judges named the same pose
## faults across the roster, whatever the clip's source:
##   "faint mid floats above its detached shadow", "faint end collapses into a
##   front-facing blob", "fainted bodies read as a rug or pelt with no head",
##   "hurt and moving frames keep the idle silhouette", "hit react goes
##   airborne".
## The F36 recipe roster (creature_pose_candidates.gd, optionally
## roster_pose_r1) and every species that plays its own clips (the Meadows
## roster and all 49 remake_owner1101_* candidates) share one rig convention
## (root, pelvis, spine, neck, head, ...), so one clip-level pass covers both.
##
## data/config/creature_pose_settle.json (master `enabled`, OFF; each section
## also has its own switch so a GPU arm can drop one)
## rewrites the resolved faint and hit clips once per body, in a per-body copy
## of their library, under the clip's own name (stages that play a clip by name
## see the same result as the game):
##   faint.grounded  - dense pivot keys: every sample's posed vertices touch
##                     the standing ground line (a small bed-in sink) and the
##                     posed body is re-centred over its contact shadow.
##   faint.side_lie  - a faint whose final frame still stands (posed height
##                     above `collapse_ratio` of standing) rolls onto its side
##                     about the body's own forward axis; collapsed clips keep
##                     their authored fall.
##   faint.head_lift - the neck lifts a head that ends buried or pointing down,
##                     so the face stays visible at faint end.
##   hit.recoil      - a hit whose posed vertices barely move from its first
##                     frame gains a pivot recoil (nose up, lean, shove back),
##                     held through the clip's middle.
##   hit.grounded    - every hit sample is planted on the ground line (no hop).
## Materials, meshes, collision and durable state are untouched: the pass only
## re-keys the model pivot and one neck track. Presentation only.
const PATH := "res://data/config/creature_pose_settle.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const META := "pose_settle_installed"
const ORIGINALS := &"pose_settle_original"

static var _config: Dictionary = {}
static var _config_loaded := false


static func config() -> Dictionary:
	if not _config_loaded:
		_config_loaded = true
		if FileAccess.file_exists(PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
			_config = parsed if parsed is Dictionary else {}
	return _config


## Tests swap the configuration in and out.
static func set_config_for_test(value: Variant) -> void:
	_config_loaded = value != null
	_config = value if value is Dictionary else {}


static func _section(cfg: Dictionary, role: String, part: String) -> Dictionary:
	if not bool(cfg.get("enabled", false)):
		return {}
	var block: Variant = (cfg.get(role, {}) as Dictionary).get(part, {}) if cfg.get(role, {}) is Dictionary else {}
	return block if block is Dictionary and bool((block as Dictionary).get("enabled", false)) else {}


static func any_enabled(cfg: Dictionary) -> bool:
	if not bool(cfg.get("enabled", false)):
		return false
	for pair: Array in [["faint", "grounded"], ["faint", "side_lie"], ["faint", "head_lift"], ["faint", "face_camera"],
			["hit", "recoil"], ["hit", "grounded"]]:
		if not _section(cfg, pair[0], pair[1]).is_empty():
			return true
	return false


static func excluded(cfg: Dictionary, species_id: String) -> bool:
	return _listed(cfg.get("exclude_species", []), species_id)


static func _listed(list: Variant, species_id: String) -> bool:
	return list is Array and (species_id in list or species_id.trim_prefix("water_") in list)


## Rewrite the clips this body resolves for faint and hit. Returns the role ->
## clip map, unchanged unless a section is enabled and the rig can be sampled.
static func apply(body: Node3D, model: Node3D, player: AnimationPlayer, clips: Dictionary,
		species_id: String, cfg: Dictionary = {}) -> Dictionary:
	var settings := cfg if not cfg.is_empty() else config()
	if not any_enabled(settings) or excluded(settings, species_id):
		return clips
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1:
		return clips
	var skeleton := skeletons[0] as Skeleton3D
	var animation_root := player.get_node_or_null(player.root_node)
	if animation_root == null:
		return clips
	var rig := Rig.new(model, skeleton, animation_root, int(settings.get("sample_vertices", 2400)))
	rig.species_id = species_id
	if rig.empty():
		return clips
	var idle := _animation(player, str(clips.get("idle", "")))
	rig.measure_standing(idle)
	if rig.standing_height <= 0.01:
		return clips
	var changed := false
	for role: String in ["faint", "hit"]:
		var name := str(clips.get(role, ""))
		var source := _animation(player, name)
		if source == null:
			continue
		var edited: Animation = null
		if role == "faint":
			edited = settle_faint(rig, source, settings)
		else:
			edited = settle_hit(rig, source, settings)
		if edited == null:
			continue
		if role == "faint" and str(clips.get("rest_faint", "")) == name:
			# Bed rests finish the installed faint; keep them on the original.
			_keep_original(player, source)
			clips["rest_faint"] = "%s/faint" % ORIGINALS
		_replace(player, name, edited)
		changed = true
	if changed:
		body.set_meta(META, true)
		var settled: Array = clips.get("pivot_clips", [])
		for role: String in ["faint", "hit"]:
			if str(clips.get(role, "")) not in settled:
				settled.append(str(clips.get(role, "")))
		clips["pivot_clips"] = settled
	return clips


static func _animation(player: AnimationPlayer, name: String) -> Animation:
	if name.is_empty() or not player.has_animation(StringName(name)):
		return null
	return player.get_animation(StringName(name))


static func _keep_original(player: AnimationPlayer, source: Animation) -> void:
	var library := AnimationLibrary.new()
	library.add_animation(&"faint", source)
	if player.has_animation_library(ORIGINALS):
		player.remove_animation_library(ORIGINALS)
	player.add_animation_library(ORIGINALS, library)


## Replace one clip in a per-body copy of its library; the shared imported
## resource is never edited.
static func _replace(player: AnimationPlayer, name: String, animation: Animation) -> void:
	var library_name := StringName(name.get_slice("/", 0)) if name.contains("/") else &""
	var clip_name := StringName(name.get_slice("/", 1)) if name.contains("/") else StringName(name)
	var library := player.get_animation_library(library_name).duplicate() as AnimationLibrary
	library.remove_animation(clip_name)
	library.add_animation(clip_name, animation)
	player.remove_animation_library(library_name)
	player.add_animation_library(library_name, library)


static func _smooth(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func _times(animation: Animation, rig: Rig, count: int) -> PackedFloat64Array:
	var times := PackedFloat64Array()
	var n := maxi(count, 2)
	for i in n:
		times.append(animation.length * float(i) / float(n - 1))
	for track: int in [rig.pivot_track(animation, Animation.TYPE_ROTATION_3D), rig.pivot_track(animation, Animation.TYPE_POSITION_3D)]:
		if track < 0:
			continue
		for key in animation.track_get_key_count(track):
			var t := animation.track_get_key_time(track, key)
			var near := false
			for existing: float in times:
				if absf(existing - t) < 0.004:
					near = true
					break
			if not near:
				times.append(t)
	times.sort()
	return times


## Faint: optional side-lie, optional head lift, then grounded dense pivot keys.
static func settle_faint(rig: Rig, source: Animation, cfg: Dictionary) -> Animation:
	var grounded := _section(cfg, "faint", "grounded")
	var side := _section(cfg, "faint", "side_lie")
	var lift := _section(cfg, "faint", "head_lift")
	if grounded.is_empty() and side.is_empty() and lift.is_empty():
		return null
	var animation := source.duplicate(true) as Animation
	var times := _times(animation, rig, int(cfg.get("samples", 11)))
	var rotations: Array[Quaternion] = []
	var positions: Array[Vector3] = []
	for t: float in times:
		rotations.append(rig.pivot_rotation(animation, t))
		positions.append(rig.pivot_position(animation, t))
	var end := animation.length
	var final := rig.posed(animation, end, rotations[-1], positions[-1])
	var final_height := Rig.height(final)
	var roll := 0.0
	if not side.is_empty():
		var legs: Variant = rig.limb_direction(animation, end, rotations[-1], positions[-1])
		var target := deg_to_rad(float(side.get("roll_deg", 78.0)) * signf(float(side.get("roll_sign", 1.0))))
		# Shelled and many-legged bodies collapse flat on their own legs: their
		# target is legs-down, which also rights a belly-up turtle.
		var upright := _listed(side.get("upright_species", []), rig.species_id)
		if upright:
			target = 0.0
		if legs is Vector3:
			# Roll about the forward axis until the legs lie out to the side:
			# a standing or crouched faint (legs down) and a legs-up faint both
			# end side-lying; a faint already on its side is left alone.
			roll = rig.roll_to_side(legs as Vector3, target)
		elif not upright and final_height > rig.standing_height * float(side.get("collapse_ratio", 0.62)):
			roll = target
		if absf(roll) < deg_to_rad(float(side.get("min_roll_deg", 10.0))):
			roll = 0.0
	if roll != 0.0:
		var start := float(side.get("roll_start", 0.2))
		var finish := maxf(start + 0.05, float(side.get("roll_end", 0.85)))
		for i in times.size():
			var r := _smooth((times[i] / end - start) / (finish - start))
			rotations[i] = (Quaternion(rig.forward, roll * r) * rotations[i]).normalized()
	if not lift.is_empty():
		rig.lift_head(animation, end, rotations[-1], positions[-1], lift)
	if not grounded.is_empty() or not side.is_empty():
		var sink := rig.standing_height * float(grounded.get("sink_frac", 0.015)) if not grounded.is_empty() else 0.0
		var centre := grounded.is_empty() or bool(grounded.get("recentre", true))
		var limit := rig.standing_height * float(grounded.get("max_shift_frac", 0.6))
		for i in times.size():
			var points := rig.posed(animation, times[i], rotations[i], positions[i])
			if points.is_empty():
				continue
			positions[i].y += rig.ground_y - sink - Rig.min_y(points)
			if centre:
				var offset := rig.standing_centre - Rig.centre_xz(points)
				offset = offset.limit_length(limit)
				positions[i].x += offset.x
				positions[i].z += offset.y
	rig.write_pivot(animation, times, rotations, positions)
	animation.set_meta("settle_faint", {"forward": rig.forward,
		"centre": Vector3(rig.standing_centre.x, 0.0, rig.standing_centre.y),
		"rotations": rotations.duplicate(), "positions": positions.duplicate(), "times": times,
		"roll_deg": rad_to_deg(roll)})
	return animation


## faint.face_camera: at the moment of fainting, turn the settled collapse
## (about the standing centre, ramped in) so the body lies across the camera's
## view with its back toward the camera: no end-on blob, and the belly (where
## generated textures are weakest) faces away. Recomputed from the baked keys
## each faint, so a revive and second faint never compounds the turn.
static func face_camera(model: Node3D, player: AnimationPlayer, clip: String, camera_position: Vector3,
		cfg: Dictionary = {}) -> float:
	var settings := cfg if not cfg.is_empty() else config()
	var section := _section(settings, "faint", "face_camera")
	if section.is_empty() or clip.is_empty() or not player.has_animation(StringName(clip)):
		return 0.0
	var animation := player.get_animation(StringName(clip))
	if not animation.has_meta("settle_faint"):
		return 0.0
	var baked: Dictionary = animation.get_meta("settle_faint")
	var parent := model.get_parent() as Node3D
	if parent == null:
		return 0.0
	var to_camera := parent.global_transform.affine_inverse() * camera_position
	var centre: Vector3 = baked.centre
	to_camera -= centre
	to_camera.y = 0.0
	if to_camera.length() < 0.01:
		return 0.0
	# side_lie rolls the back toward the body's right (forward x up), so that
	# right should point at the camera: forward = up x right.
	var target := Vector3.UP.cross(to_camera.normalized())
	var forward: Vector3 = baked.forward
	var yaw := atan2(forward.cross(target).y, forward.dot(target))
	var limit := deg_to_rad(float(section.get("max_turn_deg", 110.0)))
	yaw = clampf(yaw, -limit, limit)
	var finish := clampf(float(section.get("turn_end", 0.7)), 0.05, 1.0)
	var times: PackedFloat64Array = baked.times
	var rotations: Array = baked.rotations
	var positions: Array = baked.positions
	var rotation_track := -1
	var position_track := -1
	var root_node := player.get_node_or_null(player.root_node)
	for track in animation.get_track_count():
		if root_node != null and root_node.get_node_or_null(animation.track_get_path(track)) == model:
			if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				rotation_track = track
			elif animation.track_get_type(track) == Animation.TYPE_POSITION_3D:
				position_track = track
	if rotation_track < 0 or position_track < 0 or animation.track_get_key_count(rotation_track) != times.size():
		return 0.0
	for i in times.size():
		var turn := Quaternion(Vector3.UP, yaw * _smooth(times[i] / animation.length / finish))
		animation.track_set_key_value(rotation_track, i, (turn * (rotations[i] as Quaternion)).normalized())
		animation.track_set_key_value(position_track, i, centre + turn * ((positions[i] as Vector3) - centre))
	return rad_to_deg(yaw)


## Hit: a recoil when the authored hit barely moves, then planted samples.
static func settle_hit(rig: Rig, source: Animation, cfg: Dictionary) -> Animation:
	var recoil := _section(cfg, "hit", "recoil")
	var grounded := _section(cfg, "hit", "grounded")
	if recoil.is_empty() and grounded.is_empty():
		return null
	var animation := source.duplicate(true) as Animation
	var times := _times(animation, rig, int(cfg.get("samples", 11)))
	var rotations: Array[Quaternion] = []
	var positions: Array[Vector3] = []
	for t: float in times:
		rotations.append(rig.pivot_rotation(animation, t))
		positions.append(rig.pivot_position(animation, t))
	if not recoil.is_empty():
		var first := rig.posed(animation, 0.0, rotations[0], positions[0])
		var motion := 0.0
		for i in times.size():
			motion = maxf(motion, Rig.mean_shift(first, rig.posed(animation, times[i], rotations[i], positions[i])))
		if motion / rig.standing_height < float(recoil.get("min_motion_frac", 0.04)):
			var pitch := deg_to_rad(float(recoil.get("pitch_deg", 7.0)))
			var lean := deg_to_rad(float(recoil.get("lean_deg", 6.0)))
			var shove := rig.standing_height * float(recoil.get("shove_frac", 0.08))
			var rise := clampf(float(recoil.get("peak", 0.22)), 0.02, 0.9)
			var hold := clampf(float(recoil.get("hold_until", 0.6)), rise, 0.98)
			var lateral := rig.forward.cross(Vector3.UP).normalized()
			for i in times.size():
				var t := times[i] / animation.length
				var e := _smooth(t / rise) if t < rise else (1.0 if t <= hold else 1.0 - _smooth((t - hold) / (1.0 - hold)))
				var turn := Quaternion(lateral, pitch * e) * Quaternion(rig.forward, lean * e)
				rotations[i] = (turn * rotations[i]).normalized()
				positions[i] -= rig.forward * shove * e
	for i in times.size():
		var points := rig.posed(animation, times[i], rotations[i], positions[i])
		if not points.is_empty():
			positions[i].y += rig.ground_y - Rig.min_y(points)
	rig.write_pivot(animation, times, rotations, positions)
	return animation


## Samples a rig's skinned vertices (a bounded subset) under any clip and any
## pivot transform, in the model pivot's parent (body) space.
class Rig:
	var model: Node3D
	var skeleton: Skeleton3D
	var pivot_path: NodePath
	var to_model: Transform3D
	var base: Transform3D
	var surfaces: Array[Dictionary] = []
	var bone_tracks: Dictionary = {}
	var forward := Vector3.BACK
	var standing_height := 0.0
	var ground_y := 0.0
	var standing_centre := Vector2.ZERO
	var species_id := ""
	var _animation_root: Node

	func _init(pivot: Node3D, skel: Skeleton3D, animation_root: Node, budget: int) -> void:
		model = pivot
		skeleton = skel
		_animation_root = animation_root
		pivot_path = animation_root.get_path_to(pivot)
		to_model = BOUNDS._chain(skel, pivot)
		base = pivot.transform
		_prepare(maxi(budget, 64))

	func empty() -> bool:
		return surfaces.is_empty()

	func _prepare(budget: int) -> void:
		var meshes: Array[MeshInstance3D] = []
		var total := 0
		for mesh: MeshInstance3D in BOUNDS._mesh_instances(model):
			if mesh.skin != null and BOUNDS._skeleton_for(mesh) == skeleton:
				meshes.append(mesh)
				for surface in mesh.mesh.get_surface_count():
					total += (mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var stride := maxi(1, ceili(float(total) / float(budget)))
		for mesh: MeshInstance3D in meshes:
			var skin := mesh.skin
			var bind_bones := PackedInt32Array()
			var bind_poses: Array[Transform3D] = []
			for bind in skin.get_bind_count():
				var bone := skin.get_bind_bone(bind)
				if bone < 0:
					bone = skeleton.find_bone(skin.get_bind_name(bind))
				var valid := bone >= 0 and bone < skeleton.get_bone_count()
				bind_bones.append(bone if valid else -1)
				bind_poses.append(skin.get_bind_pose(bind) if valid else Transform3D.IDENTITY)
			for surface in mesh.mesh.get_surface_count():
				var arrays := mesh.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var bones: Variant = arrays[Mesh.ARRAY_BONES]
				var weights: Variant = arrays[Mesh.ARRAY_WEIGHTS]
				if vertices.is_empty() or bones == null or weights == null \
						or bones.size() != weights.size() or bones.size() % vertices.size() != 0:
					continue
				var per := int(bones.size() / vertices.size())
				var kept := PackedVector3Array()
				var influences := PackedInt32Array()
				var influence_weights := PackedFloat32Array()
				var vertex := 0
				while vertex < vertices.size():
					kept.append(vertices[vertex])
					var total_weight := 0.0
					for k in per:
						total_weight += maxf(float(weights[vertex * per + k]), 0.0)
					for k in per:
						var offset := vertex * per + k
						var bind := int(bones[offset])
						var weight := float(weights[offset])
						var ok := weight > 0.0 and bind >= 0 and bind < bind_bones.size() and bind_bones[bind] >= 0 and total_weight > 0.0
						influences.append(bind if ok else -1)
						influence_weights.append(weight / total_weight if ok else 0.0)
					vertex += stride
				surfaces.append({"vertices": kept, "per": per, "bind_bones": bind_bones,
					"bind_poses": bind_poses, "influences": influences, "weights": influence_weights})

	func _bone_tracks(animation: Animation) -> Dictionary:
		var id := animation.get_instance_id()
		if bone_tracks.has(id):
			return bone_tracks[id]
		var map := {}
		for track in animation.get_track_count():
			var kind := animation.track_get_type(track)
			if kind not in [Animation.TYPE_ROTATION_3D, Animation.TYPE_POSITION_3D, Animation.TYPE_SCALE_3D]:
				continue
			var path := animation.track_get_path(track)
			if path.get_subname_count() == 0:
				continue
			if _animation_root.get_node_or_null(NodePath(path.get_concatenated_names())) != skeleton:
				continue
			var bone := skeleton.find_bone(path.get_concatenated_subnames())
			if bone < 0:
				continue
			var entry: Dictionary = map.get(bone, {})
			entry[kind] = track
			map[bone] = entry
		bone_tracks[id] = map
		return map

	func pivot_track(animation: Animation, kind: int) -> int:
		for track in animation.get_track_count():
			if animation.track_get_type(track) == kind \
					and _animation_root.get_node_or_null(animation.track_get_path(track)) == model:
				return track
		return -1

	func pivot_rotation(animation: Animation, t: float) -> Quaternion:
		var track := pivot_track(animation, Animation.TYPE_ROTATION_3D)
		return animation.rotation_track_interpolate(track, t) if track >= 0 and animation.track_get_key_count(track) > 0 \
			else base.basis.get_rotation_quaternion()

	func pivot_position(animation: Animation, t: float) -> Vector3:
		var track := pivot_track(animation, Animation.TYPE_POSITION_3D)
		return animation.position_track_interpolate(track, t) if track >= 0 and animation.track_get_key_count(track) > 0 \
			else base.origin

	func global_poses(animation: Animation, t: float) -> Array[Transform3D]:
		var tracks := _bone_tracks(animation) if animation != null else {}
		var count := skeleton.get_bone_count()
		var local: Array[Transform3D] = []
		for bone in count:
			var rest := skeleton.get_bone_rest(bone)
			var position := rest.origin
			var rotation := rest.basis.get_rotation_quaternion()
			var scale := rest.basis.get_scale()
			var entry: Dictionary = tracks.get(bone, {})
			if entry.has(Animation.TYPE_POSITION_3D) and animation.track_get_key_count(entry[Animation.TYPE_POSITION_3D]) > 0:
				position = animation.position_track_interpolate(entry[Animation.TYPE_POSITION_3D], t)
			if entry.has(Animation.TYPE_ROTATION_3D) and animation.track_get_key_count(entry[Animation.TYPE_ROTATION_3D]) > 0:
				rotation = animation.rotation_track_interpolate(entry[Animation.TYPE_ROTATION_3D], t)
			if entry.has(Animation.TYPE_SCALE_3D) and animation.track_get_key_count(entry[Animation.TYPE_SCALE_3D]) > 0:
				scale = animation.scale_track_interpolate(entry[Animation.TYPE_SCALE_3D], t)
			local.append(Transform3D(Basis(rotation) * Basis.from_scale(scale), position))
		var globals: Array[Transform3D] = []
		for bone in count:
			var pose := local[bone]
			var parent := skeleton.get_bone_parent(bone)
			while parent >= 0:
				pose = local[parent] * pose
				parent = skeleton.get_bone_parent(parent)
			globals.append(pose)
		return globals

	func _pivot(rotation: Quaternion, position: Vector3) -> Transform3D:
		return Transform3D(Basis(rotation) * Basis.from_scale(base.basis.get_scale()), position)

	## Posed sample vertices in body space.
	func posed(animation: Animation, t: float, rotation: Quaternion, position: Vector3) -> PackedVector3Array:
		var globals := global_poses(animation, t)
		var to_body := _pivot(rotation, position) * to_model
		var out := PackedVector3Array()
		for surface: Dictionary in surfaces:
			var bind_bones: PackedInt32Array = surface.bind_bones
			var bind_poses: Array[Transform3D] = surface.bind_poses
			var binds: Array[Transform3D] = []
			for bind in bind_bones.size():
				var bone := bind_bones[bind]
				binds.append(to_body * globals[bone] * bind_poses[bind] if bone >= 0 else Transform3D.IDENTITY)
			var vertices: PackedVector3Array = surface.vertices
			var influences: PackedInt32Array = surface.influences
			var weights: PackedFloat32Array = surface.weights
			var per: int = surface.per
			for v in vertices.size():
				var point := Vector3.ZERO
				var weighted := 0.0
				for k in per:
					var bind := influences[v * per + k]
					if bind < 0:
						continue
					var w := weights[v * per + k]
					point += (binds[bind] * vertices[v]) * w
					weighted += w
				if weighted > 0.0:
					out.append(point / weighted)
		return out

	func bone_point(animation: Animation, t: float, bone_name: String, rotation: Quaternion, position: Vector3) -> Variant:
		var bone := skeleton.find_bone(bone_name)
		if bone < 0:
			return null
		return (_pivot(rotation, position) * to_model * global_poses(animation, t)[bone]).origin

	## Standing ground line, centre and height from the idle clip's first frame
	## (the rest pose if the rig has no idle).
	func measure_standing(idle: Animation) -> void:
		var points := posed(idle, 0.0, base.basis.get_rotation_quaternion(), base.origin)
		if points.is_empty():
			return
		standing_height = Rig.height(points)
		ground_y = Rig.min_y(points)
		standing_centre = Rig.centre_xz(points)
		var head: Variant = bone_point(idle, 0.0, "head", base.basis.get_rotation_quaternion(), base.origin)
		var pelvis: Variant = bone_point(idle, 0.0, "pelvis", base.basis.get_rotation_quaternion(), base.origin)
		var axis := Vector3.BACK
		if head is Vector3 and pelvis is Vector3:
			axis = (head as Vector3) - (pelvis as Vector3)
			axis.y = 0.0
		if axis.length() < 0.001:
			axis = base.basis.z
			axis.y = 0.0
		forward = axis.normalized() if axis.length() > 0.001 else Vector3.BACK

	## Mean direction from the trunk (pelvis, spine) to the lower limbs (legs,
	## not wings), in body space; null when the rig names no lower limbs.
	func limb_direction(animation: Animation, t: float, rotation: Quaternion, position: Vector3) -> Variant:
		var to_body := _pivot(rotation, position) * to_model
		var globals := global_poses(animation, t)
		var trunk := Vector3.ZERO
		var trunk_count := 0
		for name: String in ["pelvis", "spine"]:
			var bone := skeleton.find_bone(name)
			if bone >= 0:
				trunk += (to_body * globals[bone]).origin
				trunk_count += 1
		if trunk_count == 0:
			return null
		trunk /= float(trunk_count)
		var sum := Vector3.ZERO
		var count := 0
		for bone in skeleton.get_bone_count():
			var name := str(skeleton.get_bone_name(bone)).to_lower()
			if name.contains("wing") or not (name.contains("lower") or name.contains("foot") or name.contains("paw")):
				continue
			sum += (to_body * globals[bone]).origin - trunk
			count += 1
		if count == 0 or sum.length() < 0.001:
			return null
		return sum / float(count)

	## Signed roll about `forward` that turns the legs' direction (projected
	## across the body) onto `target` radians from straight down.
	func roll_to_side(legs: Vector3, target: float) -> float:
		var across := legs - forward * legs.dot(forward)
		if across.length() < 0.001:
			return 0.0
		var goal := Quaternion(forward, target) * Vector3.DOWN
		return atan2(forward.dot(across.cross(goal)), across.dot(goal))

	## Lift the neck so the head at the clip's end sits at least
	## `min_elevation_deg` above level, ramped in over the clip's end.
	func lift_head(animation: Animation, t_end: float, rotation: Quaternion, position: Vector3, cfg: Dictionary) -> void:
		var neck := skeleton.find_bone("neck")
		var head := skeleton.find_bone("head")
		if neck < 0 or head < 0:
			return
		var track: int = (_bone_tracks(animation).get(neck, {}) as Dictionary).get(Animation.TYPE_ROTATION_3D, -1)
		if track < 0 or animation.track_get_key_count(track) == 0:
			return
		var to_body := _pivot(rotation, position) * to_model
		var globals := global_poses(animation, t_end)
		var d := (to_body * globals[head]).origin - (to_body * globals[neck]).origin
		if d.length() < 0.001:
			return
		var elevation := rad_to_deg(asin(clampf(d.normalized().y, -1.0, 1.0)))
		var angle := clampf(float(cfg.get("min_elevation_deg", 10.0)) - elevation, 0.0, float(cfg.get("max_lift_deg", 35.0)))
		if angle < 1.0:
			return
		var axis_body := d.cross(Vector3.UP)
		if axis_body.length() < 0.001:
			return
		var axis_skeleton := (to_body.basis.inverse() * axis_body.normalized()).normalized()
		var lift := Quaternion(axis_skeleton, deg_to_rad(angle))
		var parent := skeleton.get_bone_parent(neck)
		var parent_rotation := globals[parent].basis.get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY
		var local_lift := (parent_rotation.inverse() * lift * parent_rotation).normalized()
		var start := float(cfg.get("ramp_start", 0.5))
		var end_time := animation.length
		# Make sure the ramp has keys to ride on, then lift each key.
		for phase: float in [start, (start + 1.0) * 0.5, 1.0]:
			var t := phase * end_time
			if animation.track_find_key(track, t, Animation.FIND_MODE_APPROX) < 0:
				animation.rotation_track_insert_key(track, t, animation.rotation_track_interpolate(track, t))
		for key in animation.track_get_key_count(track):
			var r := _smooth((animation.track_get_key_time(track, key) / end_time - start) / maxf(1.0 - start, 0.05))
			if r <= 0.0:
				continue
			var value: Quaternion = animation.track_get_key_value(track, key)
			animation.track_set_key_value(track, key, (Quaternion.IDENTITY.slerp(local_lift, r) * value).normalized())
		bone_tracks.erase(animation.get_instance_id())

	func write_pivot(animation: Animation, times: PackedFloat64Array, rotations: Array[Quaternion], positions: Array[Vector3]) -> void:
		var rotation_track := pivot_track(animation, Animation.TYPE_ROTATION_3D)
		if rotation_track < 0:
			rotation_track = animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(rotation_track, pivot_path)
		var position_track := pivot_track(animation, Animation.TYPE_POSITION_3D)
		if position_track < 0:
			position_track = animation.add_track(Animation.TYPE_POSITION_3D)
			animation.track_set_path(position_track, pivot_path)
		for track: int in [rotation_track, position_track]:
			while animation.track_get_key_count(track) > 0:
				animation.track_remove_key(track, 0)
		for i in times.size():
			animation.rotation_track_insert_key(rotation_track, times[i], rotations[i])
			animation.position_track_insert_key(position_track, times[i], positions[i])

	static func _smooth(t: float) -> float:
		var x := clampf(t, 0.0, 1.0)
		return x * x * (3.0 - 2.0 * x)

	static func min_y(points: PackedVector3Array) -> float:
		var low := INF
		for p in points:
			low = minf(low, p.y)
		return low

	static func height(points: PackedVector3Array) -> float:
		var low := INF
		var high := -INF
		for p in points:
			low = minf(low, p.y)
			high = maxf(high, p.y)
		return high - low if points.size() > 0 else 0.0

	static func centre_xz(points: PackedVector3Array) -> Vector2:
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for p in points:
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
		return (lo + hi) * 0.5 if points.size() > 0 else Vector2.ZERO

	static func mean_shift(a: PackedVector3Array, b: PackedVector3Array) -> float:
		var n := mini(a.size(), b.size())
		if n == 0:
			return 0.0
		var total := 0.0
		for i in n:
			total += a[i].distance_to(b[i])
		return total / float(n)

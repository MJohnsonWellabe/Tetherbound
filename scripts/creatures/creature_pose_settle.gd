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
##   faint.grounded  - dense pivot keys: every sample's trunk rests on the
##                     standing ground line (a small bed-in sink; limbs may
##                     sink a little) and the posed body is re-centred over
##                     its contact shadow.
##   faint.side_lie  - rolls about the body's forward axis until the legs lie
##                     out to the side, keeping the side a faint already fell
##                     to; legless rigs never roll by height.
##   faint.level_trunk - a trunk that ends sitting or standing up (pelvis to
##                     head steeper than 25 deg) pitches down first.
##   faint.crumple   - bodies that look odd on their side (owner, 1 Nov: winged,
##                     legless, shelled, many-legged, seal/ray/serpent/amphibian
##                     shapes) collapse onto the ground instead: legs back
##                     under the body with a slight slump, legs folding out so
##                     the belly drops, head sinking to the ground.
##   faint.head_lift - the neck lifts a head that ends buried or pointing down,
##                     so the face stays visible at faint end (limbed rigs).
##   faint.face_camera - at play_faint the collapse turns across the camera.
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

const CACHE_LIMIT := 96
static var _cache: Dictionary = {}
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
	_cache.clear()
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
	for pair: Array in [["faint", "grounded"], ["faint", "side_lie"], ["faint", "head_lift"], ["faint", "face_camera"], ["faint", "crumple"], ["faint", "level_trunk"], ["faint", "legless_head_drop"],
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
	# One bake per species, model, clips and fit per session; later bodies
	# take duplicates (play_faint re-keys a body's own faint copy).
	var sources := {}
	for role: String in ["faint", "hit"]:
		sources[role] = _animation(player, str(clips.get(role, "")))
	var key := _cache_key(model, skeleton, clips, sources, species_id, settings)
	var baked: Dictionary = _cache.get(key, {})
	if baked.is_empty():
		var rig := Rig.new(model, skeleton, animation_root, int(settings.get("sample_vertices", 1500)))
		rig.species_id = species_id
		if rig.empty():
			return clips
		rig.measure_standing(_animation(player, str(clips.get("idle", ""))))
		if rig.standing_height <= 0.01:
			return clips
		for role: String in ["faint", "hit"]:
			var source: Animation = sources[role]
			if source == null:
				continue
			var edited: Animation = settle_faint(rig, source, settings) if role == "faint" else settle_hit(rig, source, settings)
			if edited != null:
				baked[role] = edited
		if _cache.size() >= CACHE_LIMIT:
			_cache.clear()
		_cache[key] = baked
	var changed := false
	for role: String in ["faint", "hit"]:
		if not baked.has(role):
			continue
		var name := str(clips.get(role, ""))
		var edited := (baked[role] as Animation).duplicate(true) as Animation
		if role == "faint" and str(clips.get("rest_faint", "")) == name:
			# Bed rests finish the installed faint; keep them on the original.
			_keep_original(player, sources[role])
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


static func _cache_key(model: Node3D, skeleton: Skeleton3D, clips: Dictionary, sources: Dictionary,
		species_id: String, settings: Dictionary) -> String:
	var parts: Array = [species_id, model.transform, BOUNDS._chain(skeleton, model), hash(settings)]
	for role: String in ["idle", "faint", "hit"]:
		var name := str(clips.get(role, ""))
		parts.append(name)
		var source: Variant = sources.get(role, null)
		# Imported clips are shared resources; recipe clips are rebuilt per
		# body from the same static recipe data, so their name identifies them.
		if source is Animation and not name.contains("/"):
			parts.append((source as Animation).resource_path if not (source as Animation).resource_path.is_empty() \
				else str((source as Animation).get_instance_id()))
	for child in model.get_children():
		parts.append(child.scene_file_path)
	return str(parts)


static func clear_cache() -> void:
	_cache.clear()


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
	if grounded.is_empty() and side.is_empty() and lift.is_empty() and _section(cfg, "faint", "crumple").is_empty():
		return null
	var animation := source.duplicate(true) as Animation
	var times := _times(animation, rig, int(cfg.get("samples", 11)))
	var rotations: Array[Quaternion] = []
	var positions: Array[Vector3] = []
	for t: float in times:
		rotations.append(rig.pivot_rotation(animation, t))
		positions.append(rig.pivot_position(animation, t))
	var end := animation.length
	# Level a trunk that ends sitting or standing up (a seal begging, a ray on
	# its tail): pitch the body down until pelvis-to-head is no steeper than
	# `max_trunk_deg`, before rolling it onto its side.
	var level := _section(cfg, "faint", "level_trunk")
	if not level.is_empty():
		var pitch: Variant = rig.trunk_pitch(animation, end, rotations[-1], positions[-1],
			deg_to_rad(float(level.get("max_trunk_deg", 25.0))))
		if pitch is Quaternion:
			var start := float(level.get("ramp_start", 0.2))
			var finish := maxf(start + 0.05, float(level.get("ramp_end", 0.85)))
			for i in times.size():
				var r := _smooth((times[i] / end - start) / (finish - start))
				rotations[i] = (Quaternion.IDENTITY.slerp(pitch, r) * rotations[i]).normalized()
	var crumple := _section(cfg, "faint", "crumple")
	var crumples := not crumple.is_empty() and crumples_species(rig, crumple)
	var keep := _listed(side.get("exclude_species", []), rig.species_id) if not side.is_empty() else false
	var legs: Variant = rig.limb_direction(animation, end, rotations[-1], positions[-1])
	var roll := 0.0
	var side_sign := signf(float(side.get("roll_sign", 1.0))) if not side.is_empty() else 1.0
	if legs is Vector3 and not keep and (crumples or not side.is_empty()):
		# Roll about the forward axis. Side-lying bodies: until the legs lie
		# out to the side; a standing or crouched faint takes `roll_sign`, a
		# faint already on a side (or legs-up) keeps the side it fell to.
		# Crumpling bodies: legs back down under the body (a belly-up fall is
		# righted), with only a slight natural slump to one side.
		var angle := rig.leg_angle(legs as Vector3)
		if absf(angle) > deg_to_rad(float(side.get("keep_side_deg", 25.0))):
			side_sign = signf(angle)
		var target := side_sign * deg_to_rad(float(side.get("roll_deg", 78.0)))
		if crumples:
			target = side_sign * deg_to_rad(float(crumple.get("slump_deg", 12.0)))
		roll = wrapf(target - angle, -PI, PI)
		# Tiny corrections are noise. A side-lying body never spins past
		# `max_roll_deg`; a crumple may right a full belly-up fall, because its
		# correction ramps in against the clip's own roll.
		var limit := 180.0 if crumples else float(side.get("max_roll_deg", 120.0))
		if absf(roll) < deg_to_rad(float(side.get("min_roll_deg", 10.0))) or absf(roll) > deg_to_rad(limit) + 0.001:
			roll = 0.0
	# Legless rigs (snakes, rays, moths) never roll by height alone: that stood
	# Fulgocobra's coil up on its side.
	if roll != 0.0:
		var start := float(side.get("roll_start", 0.2))
		var finish := maxf(start + 0.05, float(side.get("roll_end", 0.85)))
		for i in times.size():
			var r := _smooth((times[i] / end - start) / (finish - start))
			rotations[i] = (Quaternion(rig.forward, roll * r) * rotations[i]).normalized()
	var limbed := legs is Vector3
	if crumples:
		# Collapse onto the ground: the legs fold out from under the body (it
		# drops onto its belly once grounded) and the head sinks to the ground.
		if limbed:
			var fold := crumple.duplicate()
			var after: Variant = rig.limb_direction(animation, end, rotations[-1], positions[-1])
			fold["_inverted"] = after is Vector3 and (after as Vector3).y > 0.0 and not keep
			rig.splay_limbs(animation, end, rotations[-1], positions[-1], fold)
		_drop_head(rig, animation, end, rotations[-1], positions[-1], crumple, limbed)
	else:
		if not lift.is_empty() and limbed:
			# The face stays visible on a side-lying body.
			rig.lift_head(animation, end, rotations[-1], positions[-1], lift)
		var drop := _section(cfg, "faint", "legless_head_drop")
		if not drop.is_empty() and not limbed:
			# A raised hood does not read as a faint.
			_drop_head(rig, animation, end, rotations[-1], positions[-1], drop, false)
	if not grounded.is_empty() or not side.is_empty():
		var sink := rig.standing_height * float(grounded.get("sink_frac", 0.015)) if not grounded.is_empty() else 0.0
		var centre := grounded.is_empty() or bool(grounded.get("recentre", true))
		var limit := rig.standing_height * float(grounded.get("max_shift_frac", 0.6))
		for i in times.size():
			var points := rig.posed(animation, times[i], rotations[i], positions[i])
			if points.is_empty():
				continue
			# Rest the trunk on the ground; limbs may sink up to `limb_sink_frac`
			# of standing height (a flipper or leg pointing down must not prop
			# the whole body up off the ground).
			var raise := rig.ground_y - sink - Rig.min_y(points)
			var trunk := rig.trunk_min_y(points)
			if is_finite(trunk):
				# A crumpling body's legs give way under it, so they may sink
				# further and the belly reaches the ground.
				var limb_sink := float(crumple.get("limb_sink_frac", 0.6)) if crumples else float(grounded.get("limb_sink_frac", 0.2))
				raise = maxf(rig.ground_y - sink - trunk,
					rig.ground_y - rig.standing_height * limb_sink - Rig.min_y(points))
			if crumples and not rig.torso_heights.is_empty():
				# The legs give way: the torso (spine) sinks toward
				# `torso_drop_ratio` of its standing height over the clip's
				# second half; folded legs pass into the ground. Auto-rigged
				# remakes skin most leg mesh to the trunk, so grounding alone
				# would leave them standing.
				# Each torso joint (pelvis, spine...) sinks toward the ratio of
				# its own standing height; the most-raised joint (an arched
				# hip) sets the drop.
				var dropped := raise
				var any := false
				for bone_name: String in rig.torso_heights:
					var joint: Variant = rig.bone_point(animation, times[i], bone_name, rotations[i], positions[i])
					if joint is Vector3:
						var target_y := rig.ground_y + (float(rig.torso_heights[bone_name]) - rig.ground_y) * float(crumple.get("torso_drop_ratio", 0.45))
						dropped = minf(dropped, target_y - (joint as Vector3).y)
						any = true
				if any:
					# Never bury the body: its top stays at least this high.
					var top := -INF
					for p in points:
						top = maxf(top, p.y)
					dropped = maxf(dropped, rig.ground_y + rig.standing_height * float(crumple.get("min_top_frac", 0.3)) - top)
					var r := _smooth((times[i] / end - float(crumple.get("drop_start", 0.35))) / maxf(1.0 - float(crumple.get("drop_start", 0.35)), 0.05))
					raise = lerpf(raise, dropped, r)
			positions[i].y += raise
			if centre:
				var offset := rig.standing_centre - Rig.centre_xz(points)
				offset = offset.limit_length(limit)
				positions[i].x += offset.x
				positions[i].z += offset.y
	rig.write_pivot(animation, times, rotations, positions)
	animation.set_meta("settle_faint", {"forward": rig.forward,
		"centre": Vector3(rig.standing_centre.x, 0.0, rig.standing_centre.y),
		"rotations": rotations.duplicate(), "positions": positions.duplicate(), "times": times,
		"roll_deg": rad_to_deg(roll), "side": side_sign, "crumple": crumples})
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
	# The baked side says where the back ended: +1 toward the body's right
	# (forward x up), -1 toward its left. That side should face the camera:
	# forward = up x right, with right = side * to_camera.
	var target := Vector3.UP.cross(to_camera.normalized()) * float(baked.get("side", 1.0))
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


## Crumpling bodies: the listed species, plus winged and legless rigs when
## `winged_rigs` / `legless_rigs` are set, minus `keep_authored`.
static func crumples_species(rig: Rig, crumple: Dictionary) -> bool:
	if _listed(crumple.get("keep_authored", []), rig.species_id):
		return false
	if _listed(crumple.get("species", []), rig.species_id):
		return true
	var winged := false
	var limbed := false
	for bone in rig.skeleton.get_bone_count():
		var name := str(rig.skeleton.get_bone_name(bone)).to_lower()
		winged = winged or name.contains("wing")
		limbed = limbed or (not name.contains("wing") and (name.contains("lower") or name.contains("foot") \
			or name.contains("paw") or (name.begins_with("leg_") and name.ends_with("_3"))))
	return (winged and bool(crumple.get("winged_rigs", true))) or (not limbed and bool(crumple.get("legless_rigs", true)))


## Lower the head through the joints below it (limbed: neck then head's
## parent chain of two; legless: three), the lowest joint first, so the neck
## curves down rather than kinking at the head.
static func _drop_head(rig: Rig, animation: Animation, end: float, rotation: Quaternion, position: Vector3,
		cfg: Dictionary, limbed: bool) -> void:
	var head := rig.skeleton.find_bone("head")
	if head < 0:
		return
	var chain: Array[int] = []
	var bone := rig.skeleton.get_bone_parent(head)
	for n in (2 if limbed else 3):
		if bone < 0:
			break
		chain.push_front(bone)
		bone = rig.skeleton.get_bone_parent(bone)
	if chain.is_empty():
		return
	var share := cfg.duplicate()
	share["max_drop_deg"] = float(cfg.get("max_drop_deg", 90.0)) / float(chain.size())
	share["max_elevation_deg"] = float(cfg.get("head_max_elevation_deg", cfg.get("max_elevation_deg", -15.0)))
	for joint: int in chain:
		rig.lift_head(animation, end, rotation, position, share, str(rig.skeleton.get_bone_name(joint)), true)


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
	var limb_mask := PackedByteArray()
	var bone_tracks: Dictionary = {}
	var forward := Vector3.BACK
	var standing_height := 0.0
	var ground_y := 0.0
	var standing_centre := Vector2.ZERO
	var torso_heights := {}
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
		var arrays_by_mesh: Array = []
		var total := 0
		for mesh: MeshInstance3D in BOUNDS._mesh_instances(model):
			if mesh.skin != null and BOUNDS._skeleton_for(mesh) == skeleton:
				meshes.append(mesh)
				var per_surface: Array = []
				for surface in mesh.mesh.get_surface_count():
					var arrays := mesh.mesh.surface_get_arrays(surface)
					per_surface.append(arrays)
					total += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				arrays_by_mesh.append(per_surface)
		var stride := maxi(1, ceili(float(total) / float(budget)))
		for mesh_index in meshes.size():
			var mesh := meshes[mesh_index]
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
			for arrays: Array in arrays_by_mesh[mesh_index]:
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
					var total_weight := 0.0
					var valid := 0.0
					var dominant := -1
					var dominant_weight := 0.0
					for k in per:
						var weight := float(weights[vertex * per + k])
						var bind := int(bones[vertex * per + k])
						total_weight += maxf(weight, 0.0)
						if weight > 0.0 and bind >= 0 and bind < bind_bones.size() and bind_bones[bind] >= 0:
							valid += weight
							if weight > dominant_weight:
								dominant_weight = weight
								dominant = bind_bones[bind]
					if valid > 0.0:
						kept.append(vertices[vertex])
						limb_mask.append(1 if _is_limb(dominant) else (2 if _is_head(dominant) else 0))
						for k in per:
							var offset := vertex * per + k
							var bind := int(bones[offset])
							var weight := float(weights[offset])
							var ok := weight > 0.0 and bind >= 0 and bind < bind_bones.size() and bind_bones[bind] >= 0
							influences.append(bind if ok else -1)
							influence_weights.append(weight / total_weight if ok else 0.0)
					vertex += stride
				surfaces.append({"vertices": kept, "per": per, "bind_bones": bind_bones,
					"bind_poses": bind_poses, "influences": influences, "weights": influence_weights})

	## Limbs (legs, arms, wings, fins) may sink into the ground at a faint's
	## end; the trunk (root, spine, tail, neck, head) is what rests on it.
	func _is_limb(bone: int) -> bool:
		if bone < 0:
			return false
		var name := str(skeleton.get_bone_name(bone)).to_lower()
		for part: String in ["upper", "lower", "foot", "wing", "leg", "paw", "hand", "arm", "fin", "flipper"]:
			if name.contains(part):
				return true
		return false

	## The head and neck: a sinking head must not count as the body resting.
	func _is_head(bone: int) -> bool:
		if bone < 0:
			return false
		var name := str(skeleton.get_bone_name(bone)).to_lower()
		return name.contains("head") or name.contains("neck") or name.contains("jaw")

	## Lowest posed point of the body core (root, pelvis, spine, tail: not
	## limbs, head or neck); INF when the rig names none.
	func trunk_min_y(points: PackedVector3Array) -> float:
		var low := INF
		for i in mini(points.size(), limb_mask.size()):
			if limb_mask[i] == 0:
				low = minf(low, points[i].y)
		return low

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
		for name: String in ["pelvis", "spine", "thorax", "abdomen", "spine_2"]:
			var joint: Variant = bone_point(idle, 0.0, name, base.basis.get_rotation_quaternion(), base.origin)
			if joint is Vector3:
				torso_heights[name] = (joint as Vector3).y
		# Combat faces every creature along +Z in the pivot's parent space
		# (creature_body.gd applies the per-species model_yaw so the art does);
		# a head-to-pelvis axis misreads curled necks (Galecrest).
		forward = Vector3.BACK

	## Mean direction from the trunk (pelvis, spine) to the lower limbs (legs,
	## not wings), in body space; null when the rig names no lower limbs.
	func limb_direction(animation: Animation, t: float, rotation: Quaternion, position: Vector3) -> Variant:
		var to_body := _pivot(rotation, position) * to_model
		var globals := global_poses(animation, t)
		var trunk := Vector3.ZERO
		var trunk_count := 0
		for name: String in ["pelvis", "spine", "thorax", "abdomen"]:
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
			if name.contains("wing") or not (name.contains("lower") or name.contains("foot") or name.contains("paw") \
					or (name.begins_with("leg_") and name.ends_with("_3"))):
				continue
			sum += (to_body * globals[bone]).origin - trunk
			count += 1
		if count == 0 or sum.length() < 0.001:
			return null
		return sum / float(count)

	## The body-space rotation that pitches a too-steep pelvis-to-head axis
	## down to `max_elevation` radians; null when level enough or unnamed.
	func trunk_pitch(animation: Animation, t: float, rotation: Quaternion, position: Vector3, max_elevation: float) -> Variant:
		var pelvis: Variant = bone_point(animation, t, "pelvis", rotation, position)
		var head: Variant = bone_point(animation, t, "head", rotation, position)
		if not (pelvis is Vector3 and head is Vector3):
			return null
		var d: Vector3 = (head as Vector3) - (pelvis as Vector3)
		if d.length() < 0.001:
			return null
		var elevation := asin(clampf(d.normalized().y, -1.0, 1.0))
		if elevation <= max_elevation:
			return null
		var axis := Vector3(d.x, 0.0, d.z).cross(Vector3.UP)
		if axis.length() < 0.001:
			axis = forward.cross(Vector3.UP)
		# A +angle about (flat x up) raises the axis; lower it instead.
		return Quaternion(axis.normalized(), -(elevation - max_elevation))

	## Signed angle about `forward` from straight down to the legs' direction
	## (projected across the body). A +roll about forward swings down toward
	## the body's left, the back toward its right.
	func leg_angle(legs: Vector3) -> float:
		var across := legs - forward * legs.dot(forward)
		if across.length() < 0.001:
			return 0.0
		return atan2(forward.dot(Vector3.DOWN.cross(across)), Vector3.DOWN.dot(across))

	## Upright collapse for shelled and many-legged bodies: each upper limb
	## (a lower-limb bone's parent chain below the trunk) swings outward about
	## the body's forward axis, away from the trunk's side it sits on, so the
	## body settles flat onto splayed legs once grounded.
	func splay_limbs(animation: Animation, t_end: float, rotation: Quaternion, position: Vector3, cfg: Dictionary) -> void:
		var to_body := _pivot(rotation, position) * to_model
		var globals := global_poses(animation, t_end)
		var trunk_bone := skeleton.find_bone("pelvis")
		if trunk_bone < 0:
			trunk_bone = skeleton.find_bone("thorax")
		if trunk_bone < 0:
			return
		var trunk := (to_body * globals[trunk_bone]).origin
		var right := forward.cross(Vector3.UP).normalized()
		var inverted := bool(cfg.get("_inverted", false))
		var angle := deg_to_rad(float(cfg.get("splay_deg", 32.0)))
		var start := float(cfg.get("ramp_start", 0.3))
		var tracks := _bone_tracks(animation)
		var done := {}
		for bone in skeleton.get_bone_count():
			var name := str(skeleton.get_bone_name(bone)).to_lower()
			if name.contains("wing") or not (name.contains("upper") or (name.begins_with("leg_") and name.ends_with("_1"))):
				continue
			var parent := skeleton.get_bone_parent(bone)
			var side := ((to_body * globals[bone]).origin - trunk).dot(right)
			if absf(side) < 0.001 or done.has(bone):
				continue
			done[bone] = true
			var track: int = (tracks.get(bone, {}) as Dictionary).get(Animation.TYPE_ROTATION_3D, -1)
			if track < 0 or animation.track_get_key_count(track) == 0:
				continue
			# +angle about forward swings "down" toward the body's left, so a
			# left limb (side < 0) splays with +angle on an upright body; an
			# inverted body (legs above the trunk, a belly-up turtle) flips it.
			var outward := (angle if side < 0.0 else -angle) * (-1.0 if inverted else 1.0)
			var axis_skeleton := (to_body.basis.inverse() * forward).normalized()
			var swing := Quaternion(axis_skeleton, outward)
			var parent_rotation := globals[parent].basis.get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY
			var local_swing := (parent_rotation.inverse() * swing * parent_rotation).normalized()
			for phase: float in [start, (start + 1.0) * 0.5, 1.0]:
				var t := phase * animation.length
				if animation.track_find_key(track, t, Animation.FIND_MODE_APPROX) < 0:
					animation.rotation_track_insert_key(track, t, animation.rotation_track_interpolate(track, t))
			for key in animation.track_get_key_count(track):
				var r := _smooth((animation.track_get_key_time(track, key) / animation.length - start) / maxf(1.0 - start, 0.05))
				if r <= 0.0:
					continue
				var value: Quaternion = animation.track_get_key_value(track, key)
				animation.track_set_key_value(track, key, (Quaternion.IDENTITY.slerp(local_swing, r) * value).normalized())
		bone_tracks.erase(animation.get_instance_id())

	## Lift the neck so the head at the clip's end sits at least
	## `min_elevation_deg` above level, ramped in over the clip's end.
	func lift_head(animation: Animation, t_end: float, rotation: Quaternion, position: Vector3, cfg: Dictionary,
			joint := "neck", drop := false) -> void:
		var head := skeleton.find_bone("head")
		var neck := skeleton.find_bone(joint) if not joint.is_empty() else (skeleton.get_bone_parent(head) if head >= 0 else -1)
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
		if drop:
			# Lower a raised head (a snake's hood) to `max_elevation_deg`.
			angle = -clampf(elevation - float(cfg.get("max_elevation_deg", -15.0)), 0.0, float(cfg.get("max_drop_deg", 60.0)))
		if absf(angle) < 1.0:
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

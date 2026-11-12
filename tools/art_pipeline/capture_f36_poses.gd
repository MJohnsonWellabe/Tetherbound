extends "res://tools/_capture_creature_roster.gd"

## Existing pose/scale stage. Explicit --candidate previews flag-off recipes on one
## stage body. Capture the same command without it for the matched baseline.
## This stage is deformation evidence, not an ordinary-input traversal proof.
const ROLES := ["hit", "faint", "swim", "fly_grip", "ride"]
const PHASES := [0.0, 0.25, 0.5, 0.75, 1.0]
var _pose_failures: Array[String] = []
var _scale_only := false
## Opt-in role staging (--context): fly_grip raised off the stage as in flight,
## swim behind a water plane, ride with the trainer ruler mounted on the back.
## Without the flag every frame reproduces the original stand-only capture.
var _context := false
var _water: MeshInstance3D = null
## Round 4 (r3 judges: a T-posed ruler floating over necks and heads): with
## --context the ride row is staged the way riding_controller.gd seats a
## rider -- the production trainer_model.gd in its seated pose (set_riding),
## its origin on the species' `rideable.mount_offset` in the body's frame.
## Only species with a `rideable` block can be ridden in game, so the ride row
## is captured for those alone; the receipt records the rest as not rideable.
const TRAINER_MODEL := preload("res://scripts/player/trainer_model.gd")
var _rider: Node3D = null
const FLY_VIEW_TURN_DEG := 35.0
const FLY := preload("res://scripts/player/fly_controller.gd")
## The stage floor under the carried row, and how far the hanging trainer's
## feet stay above it.
var _fly_floor_y := 0.0
const FLY_FEET_CLEAR_M := 1.2
## Close-1020 batch 4: the stage camera looks almost level (~1.6 deg), so a
## creature downed on its side reads as belly-up; fights are watched from
## combat.json's starting pitch. Opt-in so earlier rounds stay reproducible.
var _combat_pitch := false
## --roles=a,b overrides ROLES (e.g. hit,faint,rest for the rest-pose items).
var _roles: Array = []
## Game clips (LANE-THINGS, 12 Nov; the default since the THINGS-FAINT
## landing): each row plays the clip the game's own animator resolved for that
## role, not the species' raw clip of that name. Recipe species (every water
## form on an installed mesh) play `f36_candidate/<role>` in a fight, and
## creature_pose_settle.gd re-keys the resolved clip, so the raw clip showed a
## faint no fight plays (water mirejaw belly-up and floating, water abyssal
## guardian sitting up) and no settle change could reach it. `--raw-clips`
## restores the old rows for reproducing earlier rounds; `--game-clips` is
## still accepted.
var _game_clips := true
## --clear-ruler (LANE-THINGS, 12 Nov; T2 "trainer inside the tail coil",
## mangrove monitor 3/3 every frame): the ruler was placed from the body's
## rest-mesh bounds, which a posed tail, neck or collapsed body leaves. With
## this the ruler stands clear of the skinned mesh as posed across the row's
## own phases (creature_pose_settle.gd Rig samples), never nearer than before.
var _clear_ruler := false
const POSE_RIG := preload("res://scripts/creatures/creature_pose_settle.gd")
const RULER_GAP_M := 0.9


func _run() -> void:
	var ids: Array[String] = ["terrapup"]
	var candidate := false
	var whole_body := false
	var out := "res://ralph/reports/R2-F36/frames"
	var source := ""
	var all_roster := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			ids.assign(arg.trim_prefix("--species=").split(",", false))
		elif arg == "--candidate":
			candidate = true
		elif arg == "--whole-body":
			whole_body = true
		elif arg == "--scale-only":
			_scale_only = true
			whole_body = true
		elif arg == "--context":
			_context = true
		elif arg == "--combat-pitch":
			_combat_pitch = true
		elif arg == "--game-clips":
			_game_clips = true
		elif arg == "--raw-clips":
			_game_clips = false
		elif arg == "--clear-ruler":
			_clear_ruler = true
		elif arg == "--all":
			all_roster = true
		elif arg.begins_with("--roles="):
			_roles.assign(arg.trim_prefix("--roles=").split(",", false))
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--source-commit="):
			source = arg.trim_prefix("--source-commit=")
	if all_roster:
		ids.assign(SPECIES.table().keys())
		ids.sort()
	if _scale_only and candidate:
		push_error("Installed scale audit cannot preview pose candidates")
		quit(1)
		return
	var seen := {}
	for id: String in ids:
		if not SPECIES.has(id) or seen.has(id):
			push_error("F36 needs unique current species ids")
			quit(1)
			return
		seen[id] = true
	var sha_pattern := RegEx.new()
	sha_pattern.compile("^[0-9a-f]{40}$")
	if DisplayServer.get_name() == "headless" or ids.is_empty() \
			or (not source.is_empty() and sha_pattern.search(source) == null):
		push_error("F36 needs a native renderer and a current species id")
		quit(1)
		return
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(out)):
		push_error("F36 needs a fresh output folder; existing frames preserved")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out)) != OK:
		quit(1)
		return
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()
	for frame in BOOT_FRAMES:
		await physics_frame
	for id: String in ids:
		await _capture_species_poses(id, candidate, whole_body, out, source)
	for failure: String in _pose_failures:
		push_error(failure)
	quit(0 if _pose_failures.is_empty() else 1)


func _capture_species_poses(id: String, candidate: bool, whole_body: bool, out: String, source: String) -> void:
	var body := _spawn_creature(id, false, PAIR_CREATURE_POS, 90.0)
	body.set_physics_process(false)
	var measured_height := _measured_height(body)
	var measured_trainer := RENDER_BOUNDS.measure(_trainer).size.y
	var resting_bounds := RENDER_BOUNDS.measure(body)
	# F29#3 r6 (r5 judges: the ruler hid behind long bodies): with --context
	# the trainer stands clear of the resting body, never overlapping it.
	if _context:
		_trainer.global_position = Vector3(minf(PAIR_TRAINER_POS.x, resting_bounds.position.x - 1.4),
			PAIR_TRAINER_POS.y, PAIR_TRAINER_POS.z)
	if whole_body:
		# One conservative standing-envelope camera per species, shared by both
		# variants and every sampled pose. Never rescale the creature or change
		# FOV to fit; this is a full-body diagnostic stage, not gameplay framing.
		var radius := resting_bounds.size.length() * 0.8 + measured_trainer
		var target := Vector3(CAM_LOOK.x, measured_height * 0.75, CAM_LOOK.z)
		var distance := radius / tan(deg_to_rad(FOV * 0.5))
		var view_dir := (CAM_POS - CAM_LOOK).normalized()
		if _combat_pitch:
			var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
			var down := deg_to_rad(-float(combat.get("camera", {}).get("pitch_start_deg", -25.0)))
			var flat := Vector3(view_dir.x, 0.0, view_dir.z).normalized()
			view_dir = flat * cos(down) + Vector3.UP * sin(down)
		_camera.global_position = target + view_dir * distance
		_camera.look_at(target, Vector3.UP)
	if measured_height <= TRAINER_HEIGHT:
		_pose_failures.append("%s: rendered height %.3fm does not clear trainer %.2fm" %
			[id, measured_height, TRAINER_HEIGHT])
	if _scale_only and not bool(body.call("has_model")):
		_pose_failures.append("%s: installed model missing; capsule cannot establish visual scale" % id)
	if _scale_only and absf(measured_trainer - TRAINER_HEIGHT) > 0.02:
		_pose_failures.append("%s: trainer ruler renders %.3fm rather than %.2fm" % [id, measured_trainer, TRAINER_HEIGHT])
	if candidate:
		body.set_meta("f36_pose_preview", true)
		body.call("_build_placeholder")
	if candidate and not bool(body.get_meta("f36_pose_candidate_installed", false)):
		_pose_failures.append("%s: F36 candidate did not install" % id)
		body.queue_free()
		await process_frame
		return
	var players := body.find_children("*", "AnimationPlayer", true, false)
	if not _scale_only and players.size() != 1:
		_pose_failures.append("%s: expected one AnimationPlayer, found %d" % [id, players.size()])
		body.queue_free()
		await process_frame
		return
	var player := players[0] as AnimationPlayer if players.size() == 1 else null
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	var look: Dictionary = SPECIES.placeholder(id)
	var map: Dictionary = look.get("animations", {})
	var receipt: Array = []
	var roles: Array = ["standing"] if _scale_only else (_roles if not _roles.is_empty() else ROLES)
	var phases: Array = [0.0, 1.0] if _scale_only else PHASES
	for role: String in roles:
		if _context and role == "ride" and _mount_offset(id) == null:
			receipt.append({"role": role, "status": "not_rideable"})
			continue
		# GPU F36#0 judges (24 Oct) read a land species' swim row as walking on the
		# stage's water slab; only water forms and swim mounts ever swim in play.
		if _context and role == "swim" and not _swims(id):
			receipt.append({"role": role, "status": "not_a_swimmer"})
			continue
		# GPU A+C (24 Oct): a land species' carried row hung it in mid-air over a
		# detached shadow. Only a fly carrier (fly_traversal can_carry) takes the
		# fly_grip pose in play; everyone else is shown on the ground or not at all.
		if _context and role == "fly_grip" and not _carries(id):
			receipt.append({"role": role, "status": "not_a_carrier"})
			continue
		var clip := "f36_candidate/%s" % role if candidate else str(map.get(role, ""))
		if _game_clips and not candidate and player != null:
			var animator: Variant = body.get("_animator")
			var resolved: Variant = animator.get("_clips") if animator is Object else null
			var game_clip := str((resolved as Dictionary).get(role, "")) if resolved is Dictionary else ""
			if not game_clip.is_empty() and player.has_animation(game_clip):
				clip = game_clip
		if not _scale_only and (clip.is_empty() or not player.has_animation(clip)):
			receipt.append({"role": role, "status": "missing_baseline_clip"})
			_pose_failures.append("%s: missing %s clip" % [id, role])
			continue
		# GPU re-score, 11 Nov (water mosshell, 3/3): after the faint row the
		# ride and swim rows showed the turtle belly-up. Recipe clips move the
		# model pivot and leave unkeyed bones; the game leaves them through
		# creature_animator.gd (revive stops the player and restores the
		# pivot). This stage plays clips directly, so it does the same here.
		_reset_between_roles(body, player)
		var staged := _stage_role(role, body, measured_height, resting_bounds) if _context else {}
		var ruler_home := _trainer.global_position
		if _clear_ruler and _context and _trainer.visible and player != null:
			_stand_ruler_clear(body, player, clip, phases)
		# The game puts a fainted creature's aspect flame out (creature_body.gd
		# play_faint); this row plays the clip directly, so do the same here.
		body.call("set_aspect_vfx_suspended", role == "faint")
		for phase: float in phases:
			if _scale_only:
				body.rotation.y = deg_to_rad(phase * 180.0)
			else:
				player.play(clip)
				player.seek(player.get_animation(clip).length * phase, true)
				player.pause()
			for frame in 3:
				await process_frame
			if _context and role == "fly_grip":
				# The talons move with the clip, so the hang is re-seated per phase.
				_hang_rider_from_grip(body)
				await process_frame
			var path := "%s/%s-%s-%03d.png" % [out, id, role, int(phase * 100)]
			var captured := await _capture(path)
			receipt.append({"role": role, "phase": phase, "path": path, "captured": captured})
			if not captured:
				_pose_failures.append("%s: PNG capture failed" % path)
		if _clear_ruler and _context:
			_trainer.global_position = ruler_home
		if _context:
			_unstage_role(staged, body)
	var file := FileAccess.open("%s/%s-receipt.json" % [out, id], FileAccess.WRITE)
	if file == null:
		_pose_failures.append("%s: receipt could not be opened" % id)
	else:
		file.store_string(JSON.stringify({"species": id, "candidate": candidate, "stage_only": true,
			"scale_only": _scale_only, "installed_model": bool(body.call("has_model")),
			"source_commit": source, "renderer": RenderingServer.get_current_rendering_method(),
			"standing_height_m": measured_height, "trainer_reference_height_m": TRAINER_HEIGHT,
			"trainer_measured_height_m": measured_trainer, "scale_scope": "Installed standing stage; no fight-scale claim",
			"whole_body_camera": whole_body, "role_context_staging": _context, "combat_pitch": _combat_pitch, "camera_position": [_camera.global_position.x, _camera.global_position.y, _camera.global_position.z],
			"camera_fov": _camera.fov, "resting_size_m": [resting_bounds.size.x, resting_bounds.size.y, resting_bounds.size.z],
			"resolution": [root.size.x, root.size.y], "planned_frames": roles.size() * phases.size(),
			"frames": receipt}, "\t"))
		file.flush()
		if file.get_error() != OK:
			_pose_failures.append("%s: receipt flush failed" % id)
		file.close()
	_trainer.global_position = PAIR_TRAINER_POS
	body.queue_free()
	await process_frame


func _stage_role(role: String, body: Node3D, height: float, resting: AABB) -> Dictionary:
	var staged := {"body_position": body.global_position, "body_yaw": body.rotation.y,
		"trainer_transform": _trainer.global_transform}
	match role:
		"fly_grip":
			body.global_position += Vector3.UP * height * 0.45
			# r5: wings spread to the sides foreshorten to a vertical sliver in
			# the side-on stage camera and read as folded (r4 judges); the
			# flight row is shot with the body turned to a three-quarter view.
			body.rotation.y += deg_to_rad(FLY_VIEW_TURN_DEG)
			# GPU re-score, 11 Nov (galewisp, 3/3): "carries nothing, the trainer
			# stands apart". In play the trainer hangs from the carrier's grip
			# bones in fly_traversal.json's hang pose (fly_controller.gd). The
			# row is staged the same way: the production trainer model in that
			# pose, its hands on the stage body's grip bones.
			_fly_floor_y = float((staged.body_position as Vector3).y)
			_rider = Node3D.new()
			_rider.set_script(TRAINER_MODEL)
			_world.add_child(_rider)
			_rider.global_transform = Transform3D(body.global_basis.orthonormalized(), body.global_position)
			_rider.call("set_fly_hang", true, FLY.hang_pose())
			_trainer.visible = false
		"swim":
			# GPU A+C (24 Oct): the glossy slab ended in a blown white specular edge
			# and stood the ruler in the water. A rough, nearly specular-free
			# surface over the whole stage instead, and the ruler stands on the
			# waterline beside the swimmer, out of the water.
			if _water == null:
				_water = MeshInstance3D.new()
				var plane := PlaneMesh.new()
				plane.size = Vector2(60, 60)
				_water.mesh = plane
				var material := StandardMaterial3D.new()
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.albedo_color = Color(0.14, 0.38, 0.5, 0.8)
				material.roughness = 0.7
				material.metallic_specular = 0.1
				_water.material_override = material
				_world.add_child(_water)
			_water.visible = true
			var waterline := body.global_position.y + height * 0.38
			_water.global_position = Vector3(body.global_position.x, waterline, body.global_position.z)
			_trainer.global_position = Vector3(_trainer.global_position.x, waterline, _trainer.global_position.z)
			# GPU re-score, 11 Nov (water mosshell, 2/3): the ruler read as a
			# trainer standing on the water. A swimmer that can be ridden carries
			# its rider when it swims in play, so that row seats the rider on
			# its back, as the ride row does, in place of the standing ruler.
			var seat: Variant = _mount_offset(str(body.get("species_id")))
			if seat != null:
				_rider = Node3D.new()
				_rider.set_script(TRAINER_MODEL)
				_world.add_child(_rider)
				_rider.call("set_riding", true)
				_rider.global_transform = Transform3D(body.global_basis.orthonormalized(),
					body.global_transform * (seat as Vector3))
				_trainer.visible = false
		"ride":
			var offset: Variant = _mount_offset(str(body.get("species_id")))
			# A fresh rider per species: a rider reused after set_riding(false)
			# rendered nowhere in the full-roster run (r4 sheets).
			_rider = Node3D.new()
			_rider.set_script(TRAINER_MODEL)
			_world.add_child(_rider)
			_rider.call("set_riding", true)
			_rider.global_transform = Transform3D(body.global_basis.orthonormalized(),
				body.global_transform * (offset as Vector3))
			_trainer.visible = false
	return staged


## Lowest world x of the skinned mesh over the row's phases; the ruler steps
## left until it is RULER_GAP_M clear of it.
func _stand_ruler_clear(body: Node3D, player: AnimationPlayer, clip: String, phases: Array) -> void:
	var model := body.get_node_or_null(^"Model") as Node3D
	var skeletons := model.find_children("*", "Skeleton3D", true, false) if model != null else []
	var animation_root := player.get_node_or_null(player.root_node)
	if skeletons.size() != 1 or animation_root == null or not player.has_animation(clip):
		return
	var rig = POSE_RIG.Rig.new(model, skeletons[0] as Skeleton3D, animation_root, 1500)
	if rig.empty():
		return
	var animation := player.get_animation(clip)
	var low := INF
	for phase: float in phases:
		var t := animation.length * phase
		for point: Vector3 in rig.posed(animation, t, rig.pivot_rotation(animation, t), rig.pivot_position(animation, t)):
			low = minf(low, (body.global_transform * point).x)
	if is_finite(low):
		_trainer.global_position.x = minf(_trainer.global_position.x, low - RULER_GAP_M)


## What creature_animator.gd does when the game leaves a terminal or recipe
## clip: stop the player, put the bones back on their rest and restore the
## model pivot the clip moved.
func _reset_between_roles(body: Node3D, player: AnimationPlayer) -> void:
	if player == null:
		return
	player.stop()
	for skeleton: Node in body.find_children("*", "Skeleton3D", true, false):
		(skeleton as Skeleton3D).reset_bone_poses()
	var animator: Variant = body.get("_animator")
	if animator is Object and (animator as Object).has_method("_restore_candidate_pivot"):
		(animator as Object).call("_restore_candidate_pivot")


## Move the hanging rider so the midpoint of its hands is on the midpoint of
## the stage body's grip bones (fly_controller.gd align_carrier_grip, with the
## trainer moved instead of the carrier), then lift both clear of the floor.
func _hang_rider_from_grip(body: Node3D) -> void:
	if _rider == null or not _rider.has_method("skeleton"):
		return
	var grip: Array = SPECIES.fly_capability(str(body.get("species_id"))).get("grip_bones", [])
	var rigs := body.find_children("*", "Skeleton3D", true, false)
	var trainer: Skeleton3D = _rider.call("skeleton")
	if grip.size() != 2 or rigs.is_empty() or trainer == null:
		return
	var rig := rigs[0] as Skeleton3D
	var hands := Vector3.ZERO
	var feet := Vector3.ZERO
	for i in 2:
		var hand := trainer.find_bone("LeftHand" if i == 0 else "RightHand")
		var foot := rig.find_bone(str(grip[i]))
		if hand < 0 or foot < 0:
			return
		hands += trainer.to_global(trainer.get_bone_global_pose(hand).origin) * 0.5
		feet += rig.to_global(rig.get_bone_global_pose(foot).origin) * 0.5
	_rider.global_position += feet - hands
	var short := _fly_floor_y + FLY_FEET_CLEAR_M - _rider.global_position.y
	if short > 0.0:
		body.global_position += Vector3.UP * short
		_rider.global_position += Vector3.UP * short


func _swims(id: String) -> bool:
	if id.begins_with("water_"):
		return true
	var mount: Variant = SPECIES.definition(id).get("swim_mount", null)
	return mount is Dictionary and bool((mount as Dictionary).get("compatible", false))


func _carries(id: String) -> bool:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/fly_traversal.json"))
	var row: Variant = (data as Dictionary).get("capabilities", {}).get(id, null) if data is Dictionary else null
	return row is Dictionary and bool((row as Dictionary).get("can_carry", false))


func _mount_offset(id: String) -> Variant:
	var ride: Variant = SPECIES.definition(id).get("rideable", null)
	if not ride is Dictionary or not (ride as Dictionary).get("mount_offset") is Array:
		return null
	var o: Array = (ride as Dictionary)["mount_offset"]
	return Vector3(float(o[0]), float(o[1]), float(o[2])) if o.size() == 3 else null


func _unstage_role(staged: Dictionary, body: Node3D) -> void:
	if staged.is_empty():
		return
	body.global_position = staged.body_position
	body.rotation.y = staged.body_yaw
	_trainer.global_transform = staged.trainer_transform
	_trainer.visible = true
	if _rider != null:
		_rider.queue_free()
		_rider = null
	if _water != null:
		_water.visible = false

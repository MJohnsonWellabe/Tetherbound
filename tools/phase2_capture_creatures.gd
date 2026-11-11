extends SceneTree

## Phase 2 creature pose inventory in the production biome, with the trainer
## as a scale ruler and the production camera. This is a visual fixture: pose
## calls do not claim that a combat or traversal path was played.
## Optional --poses=idle,shiny_idle narrows a paired material review while
## retaining the same stage, camera and pose timings as the full inventory.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const SPECIES_DATA := preload("res://scripts/creatures/creature_species.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const SCENES := {
	"meadows": "res://scenes/world/meadows_playground.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn",
}
const STAGES := {
	"meadows": Vector2(-430.0, 470.0),
	"water": Vector2(35.0, 110.0),
	# A verified walkable shelf beside Realm Gate Crag. The earlier Gatefoot
	# position had no finite ground in front of the trainer.
	"cloudreach": Vector2(-14.5, -207.0),
	"stormwood": Vector2(-350.0, 450.0),
}
const SPECIES := {
	"meadows": ["terrapup", "bramblebun", "mudsnout", "trailpup", "burrowback",
		"meadowhart", "paddlenewt", "mosshell", "brooktail", "galecrest", "duskhush",
		"pipwing", "reedwing", "nightburrow", "stormtrail", "riftfrill", "veridian"],
	"water": ["ripplet", "cannonback", "riptusk", "mirejaw", "aquaryn", "torrentoad", "mosshell",
		"cragclaw", "riverdrake", "sirenseal", "mangrove_monitor", "tidecoil", "abyssal_guardian"],
	"cloudreach": ["galewisp", "glimmermoth", "stormcapra", "skyrill", "aeriex",
		"ribbonray", "breezetail", "cloudfang", "cliffspike", "tempestwing", "solmane",
		"craghorn", "pebbik", "galecrest"],
	"stormwood": ["stormtrail", "voltwig", "mosshock", "staticub", "voltarach",
		"fulgocobra", "stormraven", "pebbik", "craghorn", "stormbrush",
		"tanglevolt", "thundertunnel", "sparkit", "glimmermoth"],
}
const POSES := ["idle", "moving", "attacking", "hurt", "resting", "fainted"]

var _biome := ""
var _output := ""
var _seed := 2042
var _only := ""
var _poses: PackedStringArray = []
var _live_transitions := false
var _paired_transitions := false
var _graphics_capture: Dictionary = {}
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _records: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			_graphics_capture = preload("res://tools/lookdev_capture_bootstrap.gd").prepare(self)
			if _graphics_capture.is_empty():
				quit(1)
				return
			break
	if DisplayServer.get_name() == "headless":
		push_error("Phase 2 creature capture needs a rendering display")
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome = arg.trim_prefix("--biome=")
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--poses="):
			_poses = arg.trim_prefix("--poses=").split(",", false)
		elif arg == "--live-transitions":
			_live_transitions = true
		elif arg == "--paired-transitions":
			_paired_transitions = true
	if not SCENES.has(_biome) or not (_output.begins_with("res://ralph/reports/VISUAL/phase2/") or _output.begins_with("res://.artifacts/phase2/")):
		push_error("Use --biome and a Phase 2 evidence output")
		quit(1)
		return
	for pose: String in _poses:
		if pose not in POSES and pose not in ["shiny_idle", "alpha_idle"]:
			push_error("Unknown creature pose filter: " + pose)
			quit(1)
			return
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output)):
		push_error("Choose a fresh creature capture output: " + _output)
		quit(1)
		return
	for _frame in 3:
		await process_frame
	if root.size != Vector2i(1920, 1080):
		push_error("Capture viewport is %s, expected 1920x1080; on Windows use --fullscreen" % str(root.size))
		quit(1)
		return
	seed(_seed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload missing")
		quit(1)
		return
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	game.set("current_realm", _biome)
	_world = (load(str(SCENES[_biome])) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 900000
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			push_error("Production world build timed out")
			quit(1)
			return
		await process_frame
	for frame in 24:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	if _player == null or _rig == null or _camera == null:
		push_error("Production trainer or camera missing")
		quit(1)
		return
	var stage: Vector2 = STAGES[_biome]
	if not bool(game.call("debug_teleport_to", stage.x, stage.y, _biome, "")):
		push_error("Stage teleport refused")
		quit(1)
		return
	var ground := float(_world.call("ground_height_at", stage.x, stage.y))
	if not is_finite(ground):
		push_error("Creature stage has no finite ground")
		quit(1)
		return
	_player.global_position = Vector3(stage.x, ground + 0.3, stage.y)
	_player.velocity = Vector3.ZERO
	_rig.call("set_target", _player)
	_rig.set("yaw", PI)
	_rig.rotation.y = PI
	_rig.global_position = _player.global_position
	_camera.make_current()
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	var look := _world.get_node_or_null(^"WorldLook")
	if look != null and look.has_method("apply_time"):
		look.call("apply_time", "day")
		look.set_process(false)
	for node: Node in _world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	for frame in 45:
		await physics_frame
	for species: String in SPECIES[_biome]:
		if not _only.is_empty() and species not in _only.split(",", false):
			continue
		for pose: String in POSES:
			if _poses.is_empty() or pose in _poses:
				await _capture_pose(species, pose, false, 1.0)
		if _paired_transitions and not _live_transitions:
			_live_transitions = true
			for pose: String in POSES:
				if _poses.is_empty() or pose in _poses:
					await _capture_pose(species, pose, false, 1.0)
			_live_transitions = false
		if _live_transitions:
			continue
		if _poses.is_empty() or "shiny_idle" in _poses:
			await _capture_pose(species, "shiny_idle", true, 1.0)
		var alpha_scale := _alpha_scale(species)
		if alpha_scale > 1.0 and (_poses.is_empty() or "alpha_idle" in _poses):
			await _capture_pose(species, "alpha_idle", false, alpha_scale)
	if _records.is_empty():
		_failures.append("No creature frames matched the species/pose selection")
	var manifest := {"biome": _biome, "scene": SCENES[_biome], "seed": _seed,
		"species_filter": _only, "pose_filter": _poses,
		"stage_xz": [stage.x, stage.y], "display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "Production scene, trainer and camera; direct visual pose fixture, not combat or traversal proof",
		"live_transitions": _live_transitions,
		"paired_transitions": _paired_transitions,
		"creature_ruler_depth": bool(ruler_depth_config().get("enabled", false)),
		"frames": _records, "failures": _failures, "complete": _failures.is_empty()}
	if not _graphics_capture.is_empty():
		manifest["graphics_capture"] = _graphics_capture
	var file := FileAccess.open("%s/manifest.json" % _output, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	quit(0 if _failures.is_empty() else 1)


## Where the subject stands relative to the trainer: x is the side offset and
## y the distance ahead along the camera axis, both in metres.
##
## The shipped stage puts the subject max(7, height * 1.8) m beyond the trainer.
## The production camera sits about 5 m behind the trainer, so a 2.9 m hare
## ends 12 m from the lens against a 1.80 m trainer at 5 m and draws at about
## the trainer's height on screen: the "ruler" is at a different depth from the
## thing it measures. With `creature_ruler_depth` on (capture_stands.json) the
## subject stands beside the trainer on the trainer's own depth plane
## (`_plane_spot`), so their on-screen heights compare as their real heights
## do; `_fit_in_frame` then keeps it in frame and clear of the trainer.
static func stage_offsets(height: float, cfg: Dictionary) -> Vector2:
	if not bool(cfg.get("enabled", false)):
		return Vector2(clampf(height * 0.7, 2.0, 5.0), maxf(7.0, height * 1.8))
	var ahead := clampf(height * float(cfg.get("ahead_per_height", 1.1)) - float(cfg.get("ahead_less_m", 3.0)),
		float(cfg.get("ahead_min_m", 0.0)), float(cfg.get("ahead_max_m", 12.0)))
	var side := clampf(height * float(cfg.get("side_per_height", 0.7)),
		float(cfg.get("side_min_m", 2.0)), float(cfg.get("side_max_m", 5.0)))
	return Vector2(side, ahead)


static func ruler_depth_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/capture_stands.json"))
	if parsed is Dictionary and (parsed as Dictionary).get("creature_ruler_depth") is Dictionary:
		return (parsed as Dictionary)["creature_ruler_depth"]
	return {}


func _capture_pose(species: String, pose: String, shiny: bool, scale_factor: float) -> void:
	var stage: Vector2 = STAGES[_biome]
	var placeholder: Dictionary = SPECIES_DATA.placeholder(species)
	var height := float(placeholder.get("height", 2.0)) * scale_factor
	var offsets := stage_offsets(height, ruler_depth_config())
	var distance := offsets.y
	var side := offsets.x
	var subject_x := NAN
	var subject_z := NAN
	var ground := NAN
	var on_plane := bool(ruler_depth_config().get("enabled", false))
	# Cliff shelves and narrow bridges can leave the first forward point over a
	# void. Search nearby walkable presentation ground before placing a body;
	# a NaN transform produces a plausible-looking image with no creature.
	for candidate_distance: float in [distance, distance + 3.0, distance + 6.0, 5.0]:
		for candidate_side: float in [side, -side, 0.0, side + 3.0, -side - 3.0]:
			var x := stage.x + candidate_side
			var z := stage.y + candidate_distance
			if on_plane:
				var spot := _plane_spot(candidate_side, candidate_distance)
				x = spot.x
				z = spot.y
			var y := float(_world.call("ground_height_at", x, z))
			if is_finite(y):
				subject_x = x
				subject_z = z
				ground = y
				side = candidate_side
				distance = candidate_distance
				break
		if is_finite(ground):
			break
	if not is_finite(ground):
		_failures.append("%s %s: no finite forward ground near trainer" % [species, pose])
		return
	var body := CREATURE_SCENE.instantiate() as Node3D
	body.name = "Phase2_%s_%s" % [species, pose]
	body.set_script(BODY)
	_world.add_child(body)
	body.call("setup", species, shiny)
	# Creatures-ralph 4 Nov (reproduced): the art model and its animator are
	# built on the body's first frame, not inside setup(). Seating and posing
	# before then were no-ops: play_hit/play_faint/play_rest found no animator,
	# so "hurt", "fainted" and "resting" stills showed idle, and _seat measured
	# no model. Wait for the model (bounded) before seating and posing.
	for _wait in 30:
		if body.get("_animator") != null or bool(body.get("_has_model")):
			break
		await process_frame
	if scale_factor > 1.0 and body.has_method("apply_size_multiplier"):
		body.call("apply_size_multiplier", scale_factor)
	# F38#31 capture fix (7 Nov, NEAR6-MS ask): play marks every wild alpha with
	# set_alpha(true) (encounter_director.gd), which adds its aura and rim. The
	# stand only scaled the body, so "alpha_idle" showed a bigger animal with
	# none of the alpha presentation.
	if pose == "alpha_idle":
		body.call("set_alpha", true)
	body.global_position = Vector3(subject_x, ground, subject_z)
	body.rotation.y = PI
	body.set_process(false)
	body.set_physics_process(false)
	_seat(body, ground)
	_join_grass_clearing(body)
	var animator: Variant = body.get("_animator")
	if pose == "idle":
		print("PHASE2 POSE RIG %s model=%s animator=%s" % [species,
			str(body.get("_has_model")), str(animator != null)])
	if pose == "moving" and animator is Object:
		(animator as Object).call("tick", 0.0, 4.0, 8.0)
	elif pose == "attacking":
		body.call("play_attack")
	elif pose == "hurt":
		body.call("play_hit")
	elif pose == "resting":
		body.call("play_rest")
	elif pose == "fainted":
		body.call("play_faint")
	elif animator is Object:
		(animator as Object).call("tick", 0.0, 0.0, 8.0)
	if _live_transitions:
		await _capture_transition(body, species, pose)
		body.queue_free()
		await process_frame
		return
	for frame in 5:
		await process_frame
	var player: AnimationPlayer = (animator as Object).get("_player") as AnimationPlayer if animator is Object else null
	# Creatures-ralph 4 Nov (reproduced): a "fainted" still is the end state the
	# player sees, but five CPU frames land mid-collapse in a 1.5 s faint clip
	# (Veridian read as "splayed" mid-fall). Wait, in game time, for the faint
	# clip to finish (bounded by wall time).
	if pose == "fainted" and player != null and not str(player.current_animation).is_empty():
		var faint_left := player.current_animation_length - player.current_animation_position
		var waited := 0.0
		var wall_cap := Time.get_ticks_msec() + 60000
		while player.is_playing() and waited < faint_left + 0.1 and Time.get_ticks_msec() < wall_cap:
			await process_frame
			waited += root.get_process_delta_time()
	if pose == "idle":
		print("PHASE2 POSE PLAYER %s player=%s active=%s" % [species,
			str(player != null), str(player.current_animation) if player != null else ""])
	var rest_receipt: Dictionary = body.call("rest_pose_receipt") if pose == "resting" else {}
	var authored_rest := str((rest_receipt.get("config", {}) as Dictionary).get("mode", "")) == "authored"
	# Live transition capture has already returned above: only endpoint stills wait.
	if authored_rest:
		# The recipe is applied by animation_finished. Seeking to 45% and
		# pausing would strand it pending and photograph an unfinished pose.
		var wait_seconds := 5.0
		if player != null and not str(player.current_animation).is_empty():
			wait_seconds = clampf(player.current_animation_length / maxf(absf(player.speed_scale), 0.01) + 2.0, 5.0, 30.0)
		# Game time, not wall time: on CPU (llvmpipe) a frame takes far longer than
		# its delta, so a wall-clock deadline expired before the clip could finish.
		var waited := 0.0
		var wall_cap := Time.get_ticks_msec() + 300000
		while bool(body.call("rest_pose_pending")) and waited < wait_seconds and Time.get_ticks_msec() < wall_cap:
			await process_frame
			waited += get_root().get_process_delta_time()
		rest_receipt = body.call("rest_pose_receipt")
		if bool(rest_receipt.get("pending", false)) or not bool(rest_receipt.get("active", false)):
			_failures.append("%s resting: authored rest did not complete before capture" % species)
			body.queue_free()
			await process_frame
			return
		if player != null:
			player.pause()
	elif player != null and not str(player.current_animation).is_empty():
		# Preserve the inventory's original sampling for every legacy pose.
		var length := player.get_animation(player.current_animation).length
		player.seek(length * (0.9 if pose == "fainted" else 0.45), true)
		player.pause()
	var fit := {}
	if bool(ruler_depth_config().get("enabled", false)):
		fit = await _fit_in_frame(body, Vector2(side, distance), pose)
		side = float(fit.get("lateral_m", side))
		distance = float(fit.get("behind_plane_m", distance))
		subject_x = body.global_position.x
		subject_z = body.global_position.z
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_id := "%s__%s__%s" % [_biome, species, pose]
	var path := "%s/%s.jpg" % [_output, frame_id]
	if image == null or image.is_empty() or image.get_width() != 1920 or image.get_height() != 1080:
		_failures.append("%s: wrong-sized or empty image" % frame_id)
	elif image.save_jpg(path, 0.87) != OK:
		_failures.append("%s: save failed" % frame_id)
	else:
		_records.append({"id": frame_id, "species": species, "pose": pose,
			"shiny": shiny, "alpha_scale": scale_factor, "path": path,
			"rest_pose": rest_receipt,
			"model_loaded": bool(body.get("_has_model")),
			"animator_present": animator != null,
			"animation_player_present": player != null,
			"trainer_to_subject_xz_m": sqrt(side * side + distance * distance),
			"subject_stand_xz": [subject_x, subject_z],
			"ruler_depth_fit": fit,
			"animation": str(player.current_animation) if player != null else "",
			"trainer_visible_intent": true, "camera": "production CameraRig/Camera3D"})
		print("PHASE2 CREATURE %s -> %s" % [frame_id, path])
	body.queue_free()
	await process_frame


## Where a subject stands on the trainer's depth plane: `lateral` metres to
## the trainer's side along the camera's right axis (toward the side the old
## stage used) and `behind` metres further from the camera along its view axis
## (0 = exactly the trainer's depth; never negative, so never nearer the lens).
func _plane_spot(lateral: float, behind: float) -> Vector2:
	var basis := _camera.global_transform.basis
	var right := Vector2(basis.x.x, basis.x.z).normalized()
	var away := Vector2(-basis.z.x, -basis.z.z).normalized()
	if right.x < 0.0:
		right = -right
	var at := Vector2(_player.global_position.x, _player.global_position.z)
	return at + right * lateral + away * maxf(behind, 0.0)


## Ruler-depth fit rule (coordinator, 11 Nov). The first GPU capture cut
## Aquaryn's crest and tail and a fainted otter's hindquarters, let the alpha
## Mosshell cover the trainer's legs, and its judges noted that subjects
## standing nearer the lens than the trainer were flattered by perspective.
## Round 2 put the body ORIGIN on the plane, which left a camera-facing
## animal's front feet up to half its length nearer the lens, so round 3 puts
## its nearest ground contact (posed mesh) at or behind the trainer's feet.
## So the subject stands on the trainer's own depth plane and this only ever
## moves it SIDEWAYS along that plane while it overlaps the trainer. A subject
## too big for the frame at the trainer's depth (cut top or bottom, or cut at
## the side once clear of the trainer) steps AWAY from the lens, which can only
## understate it, and the manifest records how far (`behind_plane_m`). It never
## moves toward the camera; camera and trainer never move.
func _fit_in_frame(body: Node3D, offsets: Vector2, pose: String) -> Dictionary:
	var cfg := ruler_depth_config()
	var lateral := offsets.x
	var behind := maxf(offsets.y, 0.0)
	var steps := 0
	var went_out := false
	var max_steps := int(cfg.get("fit_max_steps", 16))
	var step_side := float(cfg.get("fit_step_side_m", 0.4))
	var step_behind := float(cfg.get("fit_step_behind_m", 1.0))
	var margin := float(cfg.get("fit_margin", 0.03))
	var view := Vector2(root.size)
	var report := {}
	while true:
		for _settle in 2:
			await process_frame
		var points := _subject_corners(body)
		var subject := _screen_rect(points)
		var contact := _contact_depth(points, float(cfg.get("fit_contact_band_m", 0.25)))
		# No part of the subject's ground contact may be nearer the lens than
		# the trainer's feet (a body facing the camera has its front feet half
		# its length ahead of its origin). Step back by exactly the shortfall.
		var contact_short := -float(contact.get("nearest_m", 0.0))
		var trainer := _screen_rect(_trainer_corners())
		var cut_side := subject.size == Vector2.ZERO \
			or subject.position.x < view.x * margin or subject.end.x > view.x * (1.0 - margin)
		var cut_height := subject.size == Vector2.ZERO \
			or subject.position.y < view.y * margin or subject.end.y > view.y * (1.0 - margin)
		var overlaps := subject.grow(view.x * 0.005).intersects(trainer)
		var ratio := subject.size.y / maxf(trainer.size.y, 1.0)
		var away := Vector3(-_camera.global_transform.basis.z.x, 0.0, -_camera.global_transform.basis.z.z).normalized()
		report = {"lateral_m": snappedf(lateral, 0.01), "behind_plane_m": snappedf(behind, 0.01),
			"depth_vs_trainer_m": snappedf(away.dot(body.global_position - _player.global_position), 0.01),
			"contact_depth_vs_trainer_feet_m": snappedf(float(contact.get("nearest_m", NAN)), 0.01),
			"body_nearest_depth_vs_trainer_feet_m": snappedf(float(contact.get("body_nearest_m", NAN)), 0.01),
			"lens_to_trainer_feet_m": snappedf(float(contact.get("lens_to_trainer_m", NAN)), 0.01),
			"lens_to_contact_m": snappedf(float(contact.get("lens_to_contact_m", NAN)), 0.01),
			"contact_ground_y": snappedf(float(contact.get("contact_ground_y", NAN)), 0.01),
			"trainer_ground_y": snappedf(float(contact.get("trainer_ground_y", NAN)), 0.01),
			"feet_screen_y": snappedf(subject.end.y / view.y, 0.001),
			"trainer_feet_screen_y": snappedf(trainer.end.y / view.y, 0.001),
			"steps": steps, "in_frame": not (cut_side or cut_height),
			"overlaps_trainer": overlaps, "screen_height_vs_trainer": snappedf(ratio, 0.01)}
		print("PHASE2 FIT %s step=%d subject=%s trainer=%s view=%s cut_side=%s cut_height=%s overlaps=%s contact=%s" % [
			body.name, steps, str(subject), str(trainer), str(view), str(cut_side), str(cut_height), str(overlaps), str(contact)])
		var contact_ok := contact_short <= 0.01
		if (contact_ok and not (cut_side or cut_height or overlaps)) or steps >= max_steps:
			break
		var next_lateral := lateral
		var next_behind := behind
		if not contact_ok:
			next_behind += contact_short + 0.02
			var spot_back := _plane_spot(next_lateral, next_behind)
			var ground_back := float(_world.call("ground_height_at", spot_back.x, spot_back.y))
			if not is_finite(ground_back):
				report["stopped"] = "no finite ground at the contact-rule spot"
				break
			behind = next_behind
			steps += 1
			body.global_position = Vector3(spot_back.x, ground_back, spot_back.y)
			_seat(body, ground_back)
			GRASS_FIELD.clearings_dirty = true
			continue
		var gap := trainer.position.x - subject.end.x
		if overlaps and not cut_side:
			next_lateral += step_side
			went_out = true
		elif cut_side and not cut_height and not overlaps and not went_out \
				and gap > view.x * 0.06 and lateral - step_side >= 1.2:
			# Cut at the outer edge with room beside the trainer: come inward.
			next_lateral -= step_side
		else:
			next_behind += step_behind
			# A body lying down is not a height read; only upright poses hold the ratio.
			if pose not in ["fainted", "resting"] \
					and ratio * (1.0 - step_behind / maxf(_camera.global_position.distance_to(body.global_position), 1.0)) \
					< float(cfg.get("fit_min_ratio", 1.15)):
				report["stopped"] = "would stop drawing taller than the trainer"
				break
		var spot := _plane_spot(next_lateral, next_behind)
		var ground := float(_world.call("ground_height_at", spot.x, spot.y))
		if not is_finite(ground):
			report["stopped"] = "no finite ground at the next spot"
			break
		lateral = next_lateral
		behind = next_behind
		steps += 1
		body.global_position = Vector3(spot.x, ground, spot.y)
		_seat(body, ground)
		GRASS_FIELD.clearings_dirty = true
	return report


## World-space sample of the subject's own mesh vertices AS POSED (every
## `stride`th vertex, capped). A skinned mesh is run through its skeleton's
## current bone poses, so a faint, rest or hit clip is measured where it is
## drawn. The bounding box's corners are empty air: projected raw they report
## cuts the animal does not have, and flattened they miss the perspective
## growth of a head that points at the lens. The vertices are where it is.
func _subject_corners(body: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var pivot := body.get_node_or_null(^"Model") as Node3D
	if pivot == null:
		return out
	for mesh: MeshInstance3D in RENDER_BOUNDS._mesh_instances(pivot):
		var skeleton: Skeleton3D = RENDER_BOUNDS._skeleton_for(mesh)
		var skinned := skeleton != null and mesh.skin != null
		var bone_world: Array[Transform3D] = []
		if skinned:
			for bind in mesh.skin.get_bind_count():
				var bone := mesh.skin.get_bind_bone(bind)
				if bone < 0:
					bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
				bone_world.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind)
					if bone >= 0 else Transform3D.IDENTITY)
		var rest_world: Transform3D = pivot.global_transform * RENDER_BOUNDS._render_transform(mesh, pivot)
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			if arrays.is_empty() or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
				continue
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: Variant = arrays[Mesh.ARRAY_BONES]
			var weights: Variant = arrays[Mesh.ARRAY_WEIGHTS]
			var per := 0
			if skinned and bones is PackedInt32Array and weights is PackedFloat32Array and not vertices.is_empty():
				per = (bones as PackedInt32Array).size() / vertices.size()
			var stride := maxi(1, vertices.size() / 1500)
			for index in range(0, vertices.size(), stride):
				if per <= 0:
					out.append(rest_world * vertices[index])
					continue
				var posed := Vector3.ZERO
				var total := 0.0
				for slot in per:
					var weight: float = weights[index * per + slot]
					var bind: int = bones[index * per + slot]
					if weight <= 0.0 or bind >= bone_world.size():
						continue
					posed += (bone_world[bind] * vertices[index]) * weight
					total += weight
				out.append(posed / total if total > 0.0 else rest_world * vertices[index])
	if out.is_empty():
		var bounds: AABB = RENDER_BOUNDS.measure(pivot)
		for index in 8:
			out.append(pivot.global_transform * bounds.get_endpoint(index))
	return out


## Where the subject touches the ground, relative to the trainer's feet, along
## the lens axis (horizontal). Ground contact = the sampled vertices within
## `band` of the subject's lowest point. Negative `nearest_m` means part of its
## ground contact is NEARER the lens than the trainer's feet.
func _contact_depth(points: PackedVector3Array, band: float) -> Dictionary:
	if points.is_empty():
		return {}
	var away := Vector3(-_camera.global_transform.basis.z.x, 0.0, -_camera.global_transform.basis.z.z).normalized()
	var feet := _player.global_position
	var lowest := INF
	for point: Vector3 in points:
		lowest = minf(lowest, point.y)
	var nearest := INF
	var nearest_at := Vector3.ZERO
	var body_nearest := INF
	for point: Vector3 in points:
		var depth := away.dot(point - feet)
		body_nearest = minf(body_nearest, depth)
		if point.y <= lowest + band and depth < nearest:
			nearest = depth
			nearest_at = point
	return {"nearest_m": nearest, "body_nearest_m": body_nearest, "lowest_y": lowest,
		"contact_ground_y": float(_world.call("ground_height_at", nearest_at.x, nearest_at.z)),
		"trainer_ground_y": float(_world.call("ground_height_at", feet.x, feet.z)),
		"lens_to_trainer_m": away.dot(feet - _camera.global_position),
		"lens_to_contact_m": away.dot(nearest_at - _camera.global_position)}


func _trainer_corners() -> PackedVector3Array:
	var out := PackedVector3Array()
	var at := _player.global_position
	# The trainer's feet are on the ground under them; the body's origin is not
	# necessarily at its feet, so the silhouette is built up from the ground.
	var ground := float(_world.call("ground_height_at", at.x, at.z))
	if is_finite(ground):
		at.y = ground
	var right := _camera.global_transform.basis.x
	right = Vector3(right.x, 0.0, right.z).normalized()
	for side: float in [-0.45, 0.45]:
		for dy: float in [0.0, 1.8]:
			out.append(at + right * side + Vector3(0.0, dy, 0.0))
	return out


## Screen-space bounds of world points; zero-size when any point is behind the lens.
func _screen_rect(points: PackedVector3Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var rect := Rect2()
	var started := false
	for point: Vector3 in points:
		if _camera.is_position_behind(point):
			return Rect2()
		var screen := _camera.unproject_position(point)
		if started:
			rect = rect.expand(screen)
		else:
			rect = Rect2(screen, Vector2.ZERO)
			started = true
	return rect


## F38#26 capture fix (7 Nov, NEAR6-MS ask): in play a creature that stands
## still on the floor for `settle_s` joins the grass clearing
## (creature_body.gd `_update_grass_clear`, run from `_physics_process`). The
## stand turns the body's physics off to hold its pose, so the clearing never
## engaged and the frames showed grass a standing creature would have cleared.
## Join it exactly as the settled body would, and release it when the body goes.
func _join_grass_clearing(body: Node3D) -> void:
	var cfg: Dictionary = BODY.grass_clear_config()
	if not bool(cfg.get("enabled", false)):
		return
	body.set_meta(BODY.GRASS_CLEAR_RADIUS_META, float(body.get("_radius")) * float(cfg.get("radius_scale", 1.6)))
	body.add_to_group(BODY.GRASS_CLEAR_GROUP)
	body.set("_grass_clearing", true)
	GRASS_FIELD.clearings_dirty = true
	body.tree_exiting.connect(func() -> void: GRASS_FIELD.clearings_dirty = true)


## Let the production AnimationPlayer and animation_finished callbacks run.
## The body remains parked at the manifest stand: this witnesses a visual
## transition, not an earned fight, walking trajectory or bed interaction.
func _capture_transition(body: Node3D, species: String, pose: String) -> void:
	var animator: Variant = body.get("_animator")
	var player: AnimationPlayer = (animator as Object).get("_player") as AnimationPlayer if animator is Object else null
	var elapsed := 0.0
	for sample_time: float in [0.1, 0.35, 1.0, 3.0]:
		while elapsed < sample_time:
			await process_frame
			var delta := root.get_process_delta_time()
			elapsed += delta
			if animator is Object:
				(animator as Object).call("tick", delta, 4.0 if pose == "moving" else 0.0, 8.0)
		await RenderingServer.frame_post_draw
		var frame_id := "%s__%s__%s__t%04d" % [_biome, species, pose, int(sample_time * 1000.0)]
		var path := "%s/%s.jpg" % [_output, frame_id]
		var image := root.get_texture().get_image()
		if image == null or image.is_empty() or image.get_width() != 1920 or image.get_height() != 1080:
			_failures.append("%s: wrong-sized or empty image" % frame_id)
		elif image.save_jpg(path, 0.87) != OK:
			_failures.append("%s: save failed" % frame_id)
		else:
			_records.append({"id": frame_id, "species": species, "pose": pose, "path": path,
				"sample_seconds": sample_time, "elapsed_seconds": elapsed,
				"animation": str(player.assigned_animation) if player != null else "",
				"animation_playing": player.is_playing() if player != null else false,
				"rest_receipt": body.call("rest_pose_receipt"),
				"camera": "production CameraRig/Camera3D", "body_parked": true})
			print("PHASE2 LIVE POSE %s -> %s" % [frame_id, path])


func _seat(body: Node3D, ground: float) -> void:
	var pivot := body.get_node_or_null(^"Model") as Node3D
	if pivot == null:
		return
	var bounds: AABB = RENDER_BOUNDS.measure(pivot)
	if bounds.size == Vector3.ZERO:
		return
	var foot := bounds.position.y * pivot.global_transform.basis.get_scale().y
	body.global_position.y = ground - foot


func _alpha_scale(species: String) -> float:
	if _biome != "meadows":
		return 1.0
	for band: String in ["band1_lower_meadows", "band2_stone_and_root",
		"band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"]:
		var path := "res://data/config/bands/%s/spawns.json" % band
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			continue
		for raw: Variant in (parsed as Dictionary).get("spawns", []):
			if raw is Dictionary and str((raw as Dictionary).get("species", "")) == species:
				var alpha: Variant = (raw as Dictionary).get("alpha", {})
				if alpha is Dictionary:
					var factor := float((alpha as Dictionary).get("scale", 1.0))
					if factor > 1.0:
						return factor
	return 1.0

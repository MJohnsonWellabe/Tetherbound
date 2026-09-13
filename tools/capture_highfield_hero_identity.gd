extends SceneTree

## Dedicated production-scene evidence for The Highfield's herd -> drove gate
## -> visual stock-camp composition. This does not share or modify
## tools/_capture_locations.gd.
##
## Run with a real Compatibility renderer:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_highfield_hero_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/MEADOWS-0912/HIGHFIELD-HERO-IDENTITY-R13"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const READY_TIMEOUT_MS := 420_000
const CAMERA_BACK_M := 5.2
const CAMERA_UP_M := 2.75
const FOV := 65.0

const VIEWS := [
	# R12 proved the whole Highfield read from here, but the alpha and ordinary
	# bodies sat near opposite edges. Keep that useful location-scale receipt as
	# context rather than asking it to carry the strict comparison by itself.
	{"name": "01-herd-gate-camp-day", "stand": Vector2(400.0, 5832.0), "target": Vector2(408.0, 5870.0), "time": "day", "aim_up": 5.0, "fov": 75.0, "pair_contract": "context"},
	{"name": "02-herd-gate-camp-night", "stand": Vector2(400.0, 5832.0), "target": Vector2(408.0, 5870.0), "time": "night", "aim_up": 5.0, "fov": 75.0, "pair_contract": "context"},
	# R13 replaces the cropped east-side close-up. From this fixed player-height
	# south stand, the two production encounter anchors are almost symmetrical
	# around the lens: the alpha is east, the ordinary Meadowhart is west, and
	# the open drove gate plus stock camp remain on the middle plane behind them.
	# The narrower lens gives both complete silhouettes useful pixel height while
	# leaving substantial daylight between their projected body boxes.
	{"name": "03-alpha-ordinary-threshold-day", "stand": Vector2(402.0, 5810.0), "target": Vector2(402.0, 5855.0), "time": "day", "aim_up": 3.8, "fov": 65.0, "pair_contract": "strict"},
	{"name": "04-alpha-ordinary-threshold-night", "stand": Vector2(402.0, 5810.0), "target": Vector2(402.0, 5855.0), "time": "night", "aim_up": 3.8, "fov": 65.0, "pair_contract": "strict"},
	{"name": "05-compressed-hero-day", "stand": Vector2(414.0, 5852.0), "target": Vector2(405.0, 5891.0), "time": "day", "aim_up": 4.6},
	{"name": "06-compressed-hero-night", "stand": Vector2(414.0, 5852.0), "target": Vector2(405.0, 5891.0), "time": "night", "aim_up": 4.6},
]


func _init() -> void:
	# Autoloads are attached after a SceneTree script's constructor returns.
	# Defer the production reset so Game is present before we select seed 0.
	call_deferred("_run")


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(OUT_DIR, "Highfield hero identity capture"):
		quit(1)
		return
	if not _prepare_authored_world():
		quit(1)
		return
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load production Meadows scene")
		quit(1)
		return
	var world := packed.instantiate() as Node3D
	root.add_child(world)
	if not await _wait_for_world(world):
		push_error("production Meadows scene did not finish building")
		quit(1)
		return

	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	var director := world.get_node_or_null(^"EncounterDirector")
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if player == null or look == null or director == null:
		push_error("capture requires the production Player, WorldLook and EncounterDirector")
		quit(1)
		return
	if not director.has_method("world_seed") or int(director.call("world_seed")) != 0:
		push_error("capture requires EncounterDirector's authored world seed 0")
		quit(1)
		return
	# The world shell becomes ready before EncounterDirector's awaited, terrain-
	# grounded population pass necessarily reaches late Band 4. Stand the real
	# player in Highfield first so Terrain3D streams the same collision the
	# production spawn path needs, then wait for that path to create both bodies.
	# R8 looked once at shell-ready and could fail before either body existed.
	var highfield_stand := Vector2(400.0, 5832.0)
	var highfield_ground := float(world.call("ground_height_at",
		highfield_stand.x, highfield_stand.y))
	# Disable the whole local rig before the long observation wait. Unlike only
	# disabling `_physics_process`, this also closes deferred/input-owned motion
	# paths while leaving the production trainer visible for the photographs.
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(highfield_stand.x, highfield_ground + 0.35,
		highfield_stand.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	# Terrain streaming follows the still-live gameplay rig/camera, not the
	# player's physics tick. Freeze the body now so it cannot fall through a
	# collision tile that is still arriving during the awaited population pass.
	player.set_process(false)
	player.set_physics_process(false)
	var pair := await _wait_for_highfield_pair(director)
	var bull := pair.get("bull", null) as Node3D
	var ordinary := pair.get("ordinary", null) as Node3D
	if bull == null or ordinary == null:
		push_error("capture requires the real Highfield alpha and ordinary Meadowhart bodies")
		quit(1)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	# Evidence moves the ordinary production player between fixed art-review
	# stands. Hold locomotion after each live ground sample so streamed collision
	# or a nearby creature cannot push the trainer away while the fixed camera
	# remains behind. R2 exposed exactly that in frame 01 (31.76m camera-to-player
	# instead of the intended ~6m).
	player.set_process(false)
	player.set_physics_process(false)
	if hud != null:
		hud.visible = false
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	look.set_process(false)
	look.set_physics_process(false)

	var camera := Camera3D.new()
	camera.name = "HighfieldHeroEvidenceCamera"
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	# The full 1920-wide desktop viewport exhausted the Compatibility renderer
	# while allocating the sixth readback in R4. The project-standard 1280x720
	# evidence size preserves the same FOV/composition with a bounded footprint.
	root.size = Vector2i(1280, 720)

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		camera.fov = float(view.get("fov", FOV))
		look.call("apply_time", str(view.time))
		var stand: Vector2 = view.stand
		var target: Vector2 = view.target
		var stand_ground := float(world.call("ground_height_at", stand.x, stand.y))
		if is_nan(stand_ground) or is_inf(stand_ground):
			failures.append("%s: production ground sample is not finite" % str(view.name))
			continue
		player.global_position = Vector3(stand.x, stand_ground + 0.35, stand.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		var toward := (target - stand).normalized()
		player.rotation.y = atan2(toward.x, toward.y)
		var eye_xz := stand - toward * CAMERA_BACK_M
		var eye_ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		camera.global_position = Vector3(eye_xz.x, eye_ground + CAMERA_UP_M, eye_xz.y)
		var target_ground := float(world.call("ground_height_at", target.x, target.y))
		camera.look_at(Vector3(target.x, target_ground + float(view.aim_up), target.y), Vector3.UP)
		for i in 60:
			await physics_frame
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var pair_contract := str(view.get("pair_contract", ""))
		if pair_contract != "":
			var subjects := [
				_live_body_subject(bull, "production Highfield alpha Meadowhart"),
				_live_body_subject(ordinary, "production ordinary Meadowhart"),
			]
			var comparison_limits := {
				"min_height_frac": 0.045,
				"min_inside_frac": 0.65,
				"max_height_frac": 0.55,
				"max_overlap_frac": 0.25,
				"min_gap_frac": 0.01,
			}
			if pair_contract == "strict":
				# The R12 judge found a telemetry-valid but visually cropped pair.
				# This contract requires practically the entire projected bodies,
				# little overlap, and an unmistakable band of clear frame between.
				comparison_limits["min_inside_frac"] = 0.96
				comparison_limits["max_height_frac"] = 0.30
				comparison_limits["max_overlap_frac"] = 0.02
				comparison_limits["min_gap_frac"] = 0.04
			var subject_problems := CAPTURE_CHECK.readable_problems_for_camera(
				camera, subjects, comparison_limits)
			if not subject_problems.is_empty():
				failures.append("%s: real bull/ordinary comparison is not visually judgeable: %s" % [
					str(view.name), " / ".join(subject_problems)])
				continue
		var actual_xz := Vector2(player.global_position.x, player.global_position.z)
		var stand_displacement := actual_xz.distance_to(stand)
		var ground_clearance := player.global_position.y - stand_ground
		if stand_displacement > 0.25:
			failures.append("%s: player left evidence stand by %.2fm" % [str(view.name), stand_displacement])
			continue
		if absf(ground_clearance - 0.35) > 0.1:
			failures.append("%s: player grounding drifted to %.2fm clearance" % [str(view.name), ground_clearance])
			continue
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			failures.append("%s: viewport returned no image" % str(view.name))
			continue
		var path := "%s/%s.png" % [OUT_DIR, str(view.name)]
		if image.save_png(path) != OK:
			failures.append("%s: save_png failed" % str(view.name))
			continue
		records.append({
			"frame": str(view.name),
			"time": str(view.time),
			"player_xz": [stand.x, stand.y],
			"player_actual_xz": [actual_xz.x, actual_xz.y],
			"player_stand_displacement_m": stand_displacement,
			"player_ground_clearance_m": ground_clearance,
			"camera_to_player_m": camera.global_position.distance_to(player.global_position),
			"gate_distance_m": stand.distance_to(Vector2(400.0, 5885.5)),
			"ordinary_herd_distance_m": stand.distance_to(Vector2(377.5, 5855.3)),
			"bull_distance_m": stand.distance_to(Vector2(bull.global_position.x, bull.global_position.z)),
			"bull_actual_xyz": [bull.global_position.x, bull.global_position.y, bull.global_position.z],
			"ordinary_actual_xyz": [ordinary.global_position.x, ordinary.global_position.y, ordinary.global_position.z],
			"bull_alpha": bool(bull.get_meta("alpha", false)),
			"bull_body_height_m": float(bull.call("body_height")),
			"ordinary_body_height_m": float(ordinary.call("body_height")),
			"bull_to_ordinary_height_ratio": float(bull.call("body_height")) /
				maxf(float(ordinary.call("body_height")), 0.001),
			"pair_contract": pair_contract,
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s" % path)
		image = null

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Highfield",
		"fixture_disclosure": "Fresh production Meadows scene pinned to authored world seed 0 before scene construction, so the production rolled table deterministically retains its authored ordinary Highfield Meadowhart herd and no prior save can clear the one-shot bull. Ordinary player, Terrain3D, scatter, props and EncounterDirector population remain production. The player is moved to Highfield and fully process-disabled before the observation wait so it cannot fall while collision streams. The harness waits for and resolves the real EncounterDirector alpha and ordinary bodies; neither creature is injected, moved or frozen. HUD hidden for unobstructed art review; clear weather/time pin; serialized 65-degree third-person camera at 5.2m stand-off for the strict south-side alpha/ordinary/threshold pair, with the retained contextual pair widened to 75 degrees. The strict pair requires 96% of each projected body box inside frame, no more than 2% overlap and at least 4% frame-width clear separation; no progress or encounter injection.",
		"complete": failures.is_empty() and records.size() == VIEWS.size(),
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if file == null:
		failures.append("manifest could not be written")
	else:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	quit(0 if failures.is_empty() else 1)


## Evidence must not inherit a player's rolled ecology or cleared one-shot
## encounters. Seed 0 is the production-authored population (spawn_tables.gd's
## public contract), and reset_for_new_game clears only this capture process's
## in-memory save state before the production scene constructs its population.
## This selects a real supported world configuration; it does not add a body.
func _prepare_authored_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null or not game.has_method("reset_for_new_game"):
		push_error("capture requires the production Game autoload")
		return false
	# The environment override intentionally outranks saved state in production.
	# Pin it as well as Game.world_seed so an operator's shell cannot silently
	# turn this identity receipt into a different rolled ecology.
	OS.set_environment("TB_WORLD_SEED", "0")
	game.call("reset_for_new_game")
	game.set("world_seed", 0)
	game.set("current_realm", "meadows")
	return true


func _find_meadowhart(director: Node, anchor: Vector2, want_alpha: bool) -> Node3D:
	if not director.has_method("wild_creatures"):
		return null
	var best: Node3D = null
	var best_distance := INF
	for raw: Variant in (director.call("wild_creatures") as Array):
		if not raw is Node3D:
			continue
		var body := raw as Node3D
		if str(body.get("species_id")) != "meadowhart" \
				or bool(body.get_meta("alpha", false)) != want_alpha:
			continue
		var distance := Vector2(body.global_position.x, body.global_position.z).distance_to(anchor)
		if distance < best_distance:
			best = body
			best_distance = distance
	return best if best_distance <= 30.0 else null


func _wait_for_highfield_pair(director: Node) -> Dictionary:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		var bull := _find_meadowhart(director, Vector2(425.0, 5844.0), true)
		var ordinary := _find_meadowhart(director, Vector2(377.5, 5855.3), false)
		if bull != null and ordinary != null:
			return {"bull": bull, "ordinary": ordinary}
		await physics_frame
	return {}


func _live_body_subject(body: Node3D, label: String) -> Dictionary:
	return {
		"name": label,
		"aabb": CAPTURE_CHECK.body_box(body.global_position,
			float(body.call("body_height")), float(body.call("body_radius"))),
		"body": body,
		"fighter": true,
	}


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false

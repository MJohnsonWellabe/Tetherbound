extends SceneTree

## RG8. The production orbit rig across exploration -> real encounter ->
## active-creature movement/switch -> throw aim/cancel -> combat exit, driven
## with physical joypad events for every camera/control assertion.
##
##   godot --headless --path . --script tests/smoke_combat_camera.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const FIT := preload("res://scripts/combat/fight_camera.gd")
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")

const SETTLE_FRAMES := 300
const RIGHT_X := JOY_AXIS_RIGHT_X
const RIGHT_Y := JOY_AXIS_RIGHT_Y
const LEFT_Y := JOY_AXIS_LEFT_Y
## Consecutive frames the relocated opponent must stay framed (neutral check).
const HOLD_IN_FRAME := 10
## Seconds of the rig's own grace countdown that must be observed inside the live manual-look grace
## for the "not recentred while held" check to prove anything (the grace
## itself is combat.json camera.tracking.manual_grace_seconds, 0.4).
const MIN_GRACE_SECONDS_OBSERVED := 0.15

var _failures: Array[String] = []
var _world: Node3D = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: SpringArm3D = null
var _camera: Camera3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	create_timer(900.0).timeout.connect(func() -> void: _fail("bounded camera witness exceeded 900s"); _report())
	if not _matrix_renderer_preflight():
		_report()
		return
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	# Raw B/LB events also reach the autoload menu. A manually-instanced world
	# is not current_scene unless the harness says so; without this, the menu's
	# production combat guard cannot find CombatManager and the test—not the
	# game—turns B into Pause instead of flee/cancel.
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	if not await _collect_and_stage():
		_report()
		return

	await _prove_exploration_baseline()
	await _enter_real_encounter()
	if not bool(_manager.call("is_fighting")):
		_fail("the physical interact button never entered the production encounter")
		_report()
		return
	await _capture_combat_entry()
	await _capture_size_matrix()
	await _prove_combat_entry_follow_and_orbit()
	await _prove_camera_fits_both_separations()
	await _prove_neutral_camera_keeps_the_opponent_in_frame()
	await _prove_creature_switch_keeps_the_camera()
	await _prove_aim_cancel_returns_combat_orbit()
	await _prove_combat_exit_restores_exploration()
	await _prove_a_second_entry_exit_cycle()
	_report()


func _capture_combat_entry() -> void:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--capture-dir="):
			continue
		var directory := argument.trim_prefix("--capture-dir=")
		DirAccess.make_dir_recursive_absolute(directory)
		for i in 90:
			await physics_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(directory.path_join("combat-entry.png"))
		if error != OK:
			_fail("could not save the ordinary combat camera frame: %s" % error)
		return


## Fail before the expensive world boot if the requested matrix would only
## capture a fallback preset or the wrong viewport. Source identity is checked
## by the external clean-HEAD launcher; runtime checks its receipt syntax.
func _matrix_renderer_preflight() -> bool:
	var requested := false
	var preset := "Low"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--matrix-dir="): requested = true
		elif argument.begins_with("--matrix-preset="): preset = argument.trim_prefix("--matrix-preset=")
	if not requested: return true
	if DisplayServer.get_name() == "headless" or GRAPHICS.choose(preset) != OK \
			or GRAPHICS.restart_required() or RenderingServer.get_current_rendering_method() != GRAPHICS.requested_renderer() \
			or root.get_visible_rect().size != Vector2(1920,1080):
		_fail("matrix refused before world boot: actual renderer/preset and1920x1080 required")
		return false
	return true

## Optional F21#4 pixels from the normal production rig. All original input,
## aim/exit and render-corner checks continue after restoring this scoped fixture.
## Only the three actual authored species are swapped, never their scales.
func _capture_size_matrix() -> void:
	var directory := ""
	var source := ""
	var preset := "Low"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--matrix-dir="): directory = argument.trim_prefix("--matrix-dir=")
		elif argument.begins_with("--source-commit="): source = argument.trim_prefix("--source-commit=")
		elif argument.begins_with("--matrix-preset="): preset = argument.trim_prefix("--matrix-preset=")
	if directory.is_empty(): return
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-f]{40}$")
	if DisplayServer.get_name() == "headless" or pattern.search(source) == null \
			or DirAccess.dir_exists_absolute(directory) or GRAPHICS.choose(preset) != OK \
			or GRAPHICS.restart_required() or RenderingServer.get_current_rendering_method() != GRAPHICS.requested_renderer() \
			or root.get_visible_rect().size != Vector2(1920,1080):
		_fail("matrix needs matching actual renderer/preset,1920x1080,exact source SHA and fresh output directory")
		return
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		_fail("could not create fresh matrix output")
		return
	for look: Node in get_nodes_in_group("day_cycle"):
		if look.has_method("refresh_graphics"): look.call("refresh_graphics")
	GRAPHICS.apply_viewport(root)
	GRAPHICS.apply_camera(_camera)
	var saved_party: Array = (_manager.get("_party") as Array).duplicate()
	var active_index := int(_manager.get("_active_index"))
	var saved_enemy: RefCounted = _manager.get("_enemy")
	var saved_ally_species := str(_ally.get("species_id"))
	var saved_enemy_species := str(_wild.get("species_id"))
	var saved_ally_at := _ally.global_transform
	var saved_foe_at := _wild.global_transform
	var manager_physics := _manager.is_physics_processing()
	var ally_physics := _ally.is_physics_processing()
	var foe_physics := _wild.is_physics_processing()
	_manager.set_physics_process(false)
	_ally.set_physics_process(false)
	_wild.set_physics_process(false)
	var kinds := {"small":"mudsnout", "normal":"terrapup", "giant":"veridian"}
	var cfg := FIT.config()
	var cases: Array[Dictionary] = []
	var case_index := 0
	print("MATRIX SCOPE: direct species/roster and position fixture in physically entered real encounter; only actor/manager simulation held during captures, live normal rig/world/weather/UI; no rescale, earned campaign, combat difficulty or fight-FPS claim")
	for ally_class: String in kinds:
		for foe_class: String in kinds:
			var ally_instance := SPECIES.spawn(str(kinds[ally_class]))
			var foe_instance := SPECIES.spawn(str(kinds[foe_class]))
			var staged_party := saved_party.duplicate()
			staged_party[active_index] = ally_instance
			_manager.set("_party", staged_party)
			_manager.set("_enemy", foe_instance)
			_wild.set("instance", foe_instance)
			_ally.call("setup", str(kinds[ally_class]))
			_wild.call("setup", str(kinds[foe_class]))
			_ally.global_transform = saved_ally_at
			_wild.global_transform = saved_foe_at
			var ally_bounds: AABB = _manager.call("_body_world_bounds", _ally)
			var foe_bounds: AABB = _manager.call("_body_world_bounds", _wild)
			var gap := (ally_bounds.size.x + foe_bounds.size.x) * 0.5 + 0.6
			var foe_at := _ally.global_position + Vector3(gap,0,0)
			foe_at.y = float(_world.call("ground_height_at",foe_at.x,foe_at.z))
			_wild.global_position = foe_at
			_ally.call("face_towards", _wild.global_position)
			_wild.call("face_towards", _ally.global_position)
			_manager.call("_take_camera")
			_manager.emit_signal("state_changed")
			var last_frame := Time.get_ticks_usec()
			var samples: Array[float] = []
			for frame: int in 180:
				await physics_frame
				_manager.call("_update_combat_camera_framing",1.0/60.0)
				var now := Time.get_ticks_usec()
				samples.append(float(now-last_frame)/1000.0)
				last_frame = now
			await RenderingServer.frame_post_draw
			ally_bounds = _manager.call("_body_world_bounds",_ally)
			foe_bounds = _manager.call("_body_world_bounds",_wild)
			var viewport := _camera.get_viewport().get_visible_rect().size
			var aspect := viewport.x/maxf(viewport.y,1.0)
			var a := FIT.project_box(ally_bounds,_camera.get_camera_transform(),_camera.fov,aspect,_camera.near)
			var b := FIT.project_box(foe_bounds,_camera.get_camera_transform(),_camera.fov,aspect,_camera.near)
			var measured_pair := FIT.size_class(ally_bounds.size.y,cfg)+"/"+FIT.size_class(foe_bounds.size.y,cfg)
			var pair := ally_class+"/"+foe_class
			var framed := bool(a.get("in_frame",false)) and bool(b.get("in_frame",false))
			var overlap := FIT.overlap_ratio(a.rect,b.rect) if bool(a.get("valid",false)) and bool(b.get("valid",false)) else 1.0
			var image := root.get_texture().get_image()
			var pixels := _pixel_summary(image)
			var pixels_present := bool(pixels.get("nonblank",false))
			var filename := "%02d.png" % case_index
			var wrote := pixels_present and image.save_png(directory.path_join(filename)) == OK
			var passed := measured_pair == pair and framed and overlap <= float(cfg.max_actor_overlap) and wrote
			if not passed: _fail("actual matrix "+pair+" failed: measured="+measured_pair+" framed="+str(framed)+" overlap="+str(overlap)+" png="+str(wrote))
			cases.append({"pair":pair,"measured_pair":measured_pair,"ally_species":kinds[ally_class],"foe_species":kinds[foe_class],
				"ally_bounds":_bounds_record(ally_bounds),"foe_bounds":_bounds_record(foe_bounds),"ally_rect":_rect_record(a),"foe_rect":_rect_record(b),
				"framed":framed,"overlap":overlap,"pass":passed,"png":filename,"pixels":pixels,"physics_interval_ms":samples,"spring_length":_rig.spring_length,
				"resolution":[image.get_width(),image.get_height()] if image != null else [],"actual_camera_position":_point_record(_camera.global_position)})
			case_index += 1
	_manager.set("_party",saved_party)
	_manager.set("_enemy",saved_enemy)
	_wild.set("instance",saved_enemy)
	_ally.call("setup",saved_ally_species)
	_wild.call("setup",saved_enemy_species)
	_ally.global_transform = saved_ally_at
	_wild.global_transform = saved_foe_at
	_manager.call("_take_camera")
	_manager.set_physics_process(manager_physics)
	_ally.set_physics_process(ally_physics)
	_wild.set_physics_process(foe_physics)
	var output := FileAccess.open(directory.path_join("matrix.json"),FileAccess.WRITE)
	if output == null:
		_fail("could not write matrix receipt")
	else:
		output.store_string(JSON.stringify({"source_commit":source,"camera_config_sha256":FileAccess.get_sha256("res://data/config/camera.json"),
			"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"preset":GRAPHICS.selected(),"requested_preset":preset,
			"scope":"Staged actual authored bodies and roster/positions; actor/manager simulation held temporarily. Normal production rig, live world/weather/UI. No species rescale, earned campaign, code-blind result or fight-FPS claim.","cases":cases,
			"all_nine_complete":cases.size()==9,"failures":_failures.duplicate()},"  "))
		output.close()
	for frame: int in 30: await physics_frame

## Refuse uniform opaque or transparent frames as evidence. This is only a
## bounded capture-validity guard; it does not judge art or actor readability.
func _pixel_summary(image: Image) -> Dictionary:
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return {"nonblank":false}
	var low := 1.0
	var high := 0.0
	var visible := 0
	for y: int in 9:
		for x: int in 16:
			var px := mini(image.get_width()-1, int((float(x)+0.5)*float(image.get_width())/16.0))
			var py := mini(image.get_height()-1, int((float(y)+0.5)*float(image.get_height())/9.0))
			var colour := image.get_pixel(px,py)
			if colour.a <= 0.01: continue
			var luma := colour.r*0.2126+colour.g*0.7152+colour.b*0.0722
			low = minf(low,luma)
			high = maxf(high,luma)
			visible += 1
	return {"nonblank":visible > 0 and high > 0.02 and high-low > 0.03,
		"sample_count":144,"visible":visible,"minimum_luminance":low,"maximum_luminance":high}

func _point_record(point: Vector3) -> Array:
	return [point.x,point.y,point.z]

func _bounds_record(bounds: AABB) -> Dictionary:
	return {"position":_point_record(bounds.position),"size":_point_record(bounds.size)}

func _rect_record(projection: Dictionary) -> Dictionary:
	if not bool(projection.get("valid",false)): return {"valid":false}
	var rect: Rect2 = projection.rect
	return {"valid":true,"position":[rect.position.x,rect.position.y],"size":[rect.size.x,rect.size.y]}


func _collect_and_stage() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _rig.get_node_or_null(^"Camera3D") as Camera3D if _rig != null else null
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _game == null or _player == null or _rig == null or _camera == null \
			or _manager == null or _director == null:
		_fail("the real world is missing Game, Player, CameraRig/Camera3D, CombatManager, or EncounterDirector")
		return false
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup", "Orbit")
	_wild = _director.call("wild_creature") as Node3D
	if _director.call("ally_instance") == null or _wild == null:
		_fail("the production encounter could not stage an ally and wild creature")
		return false

	# A real second party member makes the existing combat-switch input reachable.
	var second := CREATURE.from_species("ripplet", SPECIES.definition("ripplet"))
	(_game.get("party") as RefCounted).call("add", second)
	(_game.get("inventory") as RefCounted).call("add", "orb_basic", 3)

	# Move beside the authored wild spawn, but enter through the production
	# arbiter and physical X button. Walking there is smoke_combat.gd's concern.
	var offset := Vector3(3.0, 0.0, 0.0)
	var near := _wild.global_position + offset
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	return true


func _prove_exploration_baseline() -> void:
	if _rig.get("_target") != _player:
		_fail("exploration camera target is not the trainer before combat")
	if not _camera.current:
		_fail("CameraRig/Camera3D is not the active exploration camera")
	if not _rig.is_processing():
		_fail("the exploration orbit rig is not processing")
	await _assert_raw_orbit_changes("exploration baseline")


func _enter_real_encounter() -> void:
	# The wild keeps wandering while the baseline camera is exercised. Stage the
	# trainer beside its CURRENT authored body immediately before pressing X so
	# this remains a camera test rather than a race against wandering distance.
	# A scatter harvest prompt can legitimately be closer at any one side of the
	# wild (camera03-smoke-first caught exactly that intermittent fixture clash).
	# Try a fixed ring of nearby, grounded approach points and require the real
	# arbiter to publish EncounterDirector before physical X. This is equivalent
	# to the player taking a few steps around the creature; it neither bypasses
	# the arbiter nor changes production prompt priority.
	if not await _stage_at_published_engage():
		_print_entry_diagnostics("no clear production engage approach")
		return
	_print_entry_diagnostics("before physical engage")
	await _press_button(JOY_BUTTON_X)
	for i in 120:
		if bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_ally = _director.call("ally_body") as Node3D


func _stage_at_published_engage() -> bool:
	var arbiter := get_first_node_in_group("interaction_arbiter")
	if arbiter == null or not arbiter.has_method("winning_provider"):
		return false
	# Cardinal points first keep the common case quick and make failures
	# reproducible. The second radius covers a prompt whose 2.6m reach overlaps
	# one side of the wild while remaining inside the encounter's 4m reach.
	var radii: Array[float] = [1.5, 2.2]
	var bearings: Array[float] = [0.0, PI, PI * 0.5, -PI * 0.5,
		PI * 0.25, -PI * 0.25, PI * 0.75, -PI * 0.75]
	for radius: float in radii:
		for bearing: float in bearings:
			if _wild == null or not is_instance_valid(_wild):
				return false
			var anchor := _wild.global_position
			var near := anchor + Vector3(cos(bearing), 0.0, sin(bearing)) * radius
			near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
			_player.global_position = near
			_player.velocity = Vector3.ZERO
			for i in 3:
				await physics_frame
			for i in 2:
				await process_frame
			var candidate := _director.call("_engageable") as Node3D
			var winner := arbiter.call("winning_provider") as Node
			if candidate == _wild and winner == _director:
				return true
	return false


func _prove_combat_entry_follow_and_orbit() -> void:
	print("camera target on entry: %s" % _node_label(_rig.get("_target")))
	print("active camera: %s current=%s processing=%s" % [
		_camera.get_path(), _camera.current, _rig.is_processing()])
	if _ally == null or _rig.get("_target") != _ally:
		_fail("combat camera target is not the deployed active creature body")
	if not _camera.current:
		_fail("another camera became active when combat began")
	if not _rig.is_processing():
		_fail("the camera rig stopped processing when combat began")

	var ally_before := _ally.global_position
	var rig_before := _rig.global_position
	_send_axis(LEFT_Y, -0.85)
	for i in 50:
		await physics_frame
	_send_axis(LEFT_Y, 0.0)
	for i in 20:
		await physics_frame
	var ally_travel := _ally.global_position.distance_to(ally_before)
	var rig_travel := _rig.global_position.distance_to(rig_before)
	print("combat follow: ally moved %.2fm, rig moved %.2fm" % [ally_travel, rig_travel])
	if ally_travel < 0.5:
		_fail("physical left-stick input did not move the active creature")
	if rig_travel < 0.3:
		_fail("the rig did not follow the moving active creature")
	await _assert_raw_orbit_changes("combat")


## OP-0905-17 (owner playtest 2026-09-05): "the fighting camera sucks. I think
## it is too zoomed in." `combat_manager.gd::_update_combat_camera_framing()`
## is meant to keep the whole shot fitted as fighter spacing and live shoulder
## clearance change, on top of the already-raised base distance. The real wild AI does not hold still at an
## arbitrary gap, so this drives the real framing function directly against
## the real ally/wild bodies -- the same private-method access the production
## smokes already use on this world (`_director.call("_engageable")` above) --
## rather than fighting the AI for a stable measurement.
func _prove_camera_fits_both_separations() -> void:
	var cfg: Dictionary = MATH.config().get("camera", {}) as Dictionary
	var base_distance := float(cfg.get("distance", 6.0))
	var max_extra := float((cfg.get("framing", {}) as Dictionary).get("max_extra_distance", 4.0))
	var ceiling := base_distance + max_extra

	var near_distance := _measure_requested_framing(3.0)
	var far_distance := _measure_requested_framing(9.0)
	print("camera framing: near(3m)=%.2f far(9m)=%.2f base=%.2f ceiling=%.2f" % [
		near_distance, far_distance, base_distance, ceiling])
	if near_distance < base_distance - 0.05:
		_fail("the near frame narrowed below the authored base distance")
	if far_distance < base_distance - 0.05:
		_fail("the far frame narrowed below the authored base distance")
	if near_distance > ceiling + 0.05:
		_fail("camera distance at a 3m gap exceeded base distance + max_extra_distance (near=%.2f ceiling=%.2f)" % [
			near_distance, ceiling])
	if far_distance > ceiling + 0.05:
		_fail("camera distance at a 9m gap exceeded base distance + max_extra_distance (far=%.2f ceiling=%.2f)" % [
			far_distance, ceiling])

	# Leave the fighters at a normal gap, and give the real per-tick framing a
	# few physics frames to settle back before the remaining proofs run —
	# otherwise the switch/aim/exit checks below inherit this test's synthetic
	# 9m separation.
	var centre := _player.global_position + Vector3(3.5, 0.0, 0.0)
	_ally.global_position = centre
	_wild.global_position = centre + Vector3(2.0, 0.0, 0.0)
	for i in 30:
		await physics_frame


## Places the wild `gap` metres from the ally along X and drives the real
## `_update_combat_camera_framing()` in a tight synchronous loop -- no
## `await physics_frame` between calls, so nothing else (the wild's own AI
## included) gets a tick to move either body between one call and the next --
## enough times for `camera.framing.lag`'s exponential smoothing to settle.
## Shoulder clearance legitimately changes with fighter spacing, so requested
## distance need not be monotonic. Instead, place a noncurrent camera at the
## exact requested pivot/shoulder/depth pose and require both measured render
## bounds to fit the lens at each gap. Returns the rig's own `_distance`: the value
## `camera_rig.gd::_follow()` chases every real frame with
## `move_toward(spring_length, _distance, _recover_speed * delta)`.
func _measure_requested_framing(gap: float) -> float:
	var centre := _ally.global_position
	for i in 180:
		_ally.global_position = centre
		_wild.global_position = centre + Vector3(gap, 0.0, 0.0)
		_manager.call("_update_combat_camera_framing", 1.0 / 60.0)
	var requested := float(_rig.get("_distance"))
	var basis := _rig.global_basis.orthonormalized()
	var pivot := _ally.global_position + Vector3.UP * float(_rig.get("_height"))
	if _rig.has_method("framing_pivot_offset"):
		pivot += _rig.call("framing_pivot_offset") as Vector3
	pivot += Basis(Vector3.UP, float(_rig.get("yaw"))).x * float(_rig.get("_shoulder"))
	var probe := Camera3D.new()
	probe.current = false
	probe.projection = _camera.projection
	probe.fov = _camera.fov
	probe.keep_aspect = _camera.keep_aspect
	probe.near = _camera.near
	probe.far = _camera.far
	_world.add_child(probe)
	probe.global_transform = Transform3D(basis, pivot + basis.z * requested)
	var viewport_size := probe.get_viewport().get_visible_rect().size
	# horizontal_fill=.82 reserves about 9% per edge. Five percent permits
	# ordinary projection rounding while still requiring useful breathing room.
	var safe := Rect2(viewport_size * 0.05, viewport_size * 0.90)
	for body: Node3D in [_ally, _wild]:
		var bounds: AABB = _manager.call("_body_render_bounds", body)
		var model := body.call("model_pivot") as Node3D if body.has_method("model_pivot") else null
		if model == null or bounds.size.is_zero_approx():
			_fail("the %.0fm framing fixture could not measure %s's live render bounds" % [
				gap, _node_label(body)])
			continue
		for x in [0.0, 1.0]:
			for y in [0.0, 1.0]:
				for z in [0.0, 1.0]:
					var local := bounds.position + bounds.size * Vector3(x, y, z)
					var corner: Vector3 = model.global_transform * local
					if probe.is_position_behind(corner):
						_fail("the %.0fm requested frame leaves a %s render corner behind the lens" % [
							gap, _node_label(body)])
						continue
					var screen := probe.unproject_position(corner)
					if not safe.has_point(screen):
						_fail("the %.0fm requested frame crops a %s render corner at %s outside %s" % [
							gap, _node_label(body), screen, safe])
	probe.free()
	return requested


## OWNER_PLAYTEST_2026-09-12: distance widening alone cannot make a combat
## camera usable if the opponent can circle behind the lens while the player is
## moving with the left stick. With the look stick neutral, give production a
## fair settling beat at four substantially different bearings and require the
## opponent's actual body centre to remain in the safe screen area. This keeps
## manual orbit covered by `_assert_raw_orbit_changes()` while proving that
## doing nothing with the right stick cannot lose the thing being fought.
func _prove_neutral_camera_keeps_the_opponent_in_frame() -> void:
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	# A NEUTRAL camera: stick at rest and the combat profile's own pitch. The
	# tracker corrects yaw only, so without this the check inherited whatever
	# pitch the previous orbit check left -- a run whose stick-down release
	# landed late started pinned at the pitch clamp and failed every bearing
	# with identical screen positions (opponent ~25% below the frame).
	for i in 120:
		await physics_frame
		if Input.get_vector("look_left", "look_right", "look_up", "look_down").is_zero_approx():
			break
	var cam_cfg: Dictionary = MATH.config().get("camera", {}) as Dictionary
	var inherited_pitch := float(_rig.get("pitch"))
	var neutral_pitch := deg_to_rad(float(cam_cfg.get("pitch_start_deg", -25.0)))
	print("neutral check: inherited pitch %.1f deg, reset to profile %.1f deg" % [
		rad_to_deg(inherited_pitch), rad_to_deg(neutral_pitch)])
	_rig.set("pitch", neutral_pitch)
	_rig.rotation = Vector3(neutral_pitch, float(_rig.get("yaw")), 0.0)
	var ally_at := _ally.global_position
	var wild_was_processing := _wild.is_physics_processing()
	_wild.set_physics_process(false)
	for bearing_deg: float in [0.0, 95.0, 190.0, 285.0]:
		var bearing := deg_to_rad(bearing_deg)
		_ally.global_position = ally_at
		_wild.global_position = ally_at + Vector3(sin(bearing), 0.0, cos(bearing)) * 6.0
		# Poll up to the budget the tunables themselves allow, rather than a
		# fixed 90 frames. A bearing jump near 190 degrees at the tracker's
		# max_speed_deg, plus a clear-orbit ease back, needed more than 1.5 s,
		# so the old fixed wait passed or failed on the starting angle alone
		# (runner: FAIL then PASS on one head). Converging early ends the wait.
		# The opponent must then STAY framed for HOLD_IN_FRAME consecutive
		# frames: a camera that only sweeps through the safe rect (spinning or
		# oscillating) must not pass on the one frame it crosses it.
		var budget := _neutral_convergence_frames()
		var centre := Vector3.ZERO
		var screen := Vector2.ZERO
		var viewport := Vector2.ZERO
		var safe := Rect2()
		var behind := true
		var streak := 0
		var frames := 0
		for i in budget + HOLD_IN_FRAME:
			await physics_frame
			frames += 1
			centre = _wild.call("centre") if _wild.has_method("centre") \
				else _wild.global_position + Vector3.UP
			viewport = _camera.get_viewport().get_visible_rect().size
			safe = Rect2(viewport * 0.06, viewport * 0.88)
			behind = _camera.is_position_behind(centre)
			screen = _camera.unproject_position(centre)
			streak = streak + 1 if not behind and safe.has_point(screen) else 0
			if streak >= HOLD_IN_FRAME:
				break
		if streak >= HOLD_IN_FRAME:
			continue
		if behind:
			_fail("neutral combat camera left the opponent behind the lens at %.0f degrees (budget %d + hold %d frames)" % [
				bearing_deg, budget, HOLD_IN_FRAME])
		else:
			_fail("neutral combat camera did not keep the opponent framed at %.0f degrees for %d frames within %d (screen=%s viewport=%s, final streak %d)" % [
				bearing_deg, HOLD_IN_FRAME, frames, screen, viewport, streak])
	_wild.set_physics_process(wild_was_processing)
	_wild.global_position = ally_at + Vector3(2.0, 0.0, 0.0)
	for i in 30:
		await physics_frame


func _prove_creature_switch_keeps_the_camera() -> void:
	await _press_button(JOY_BUTTON_DPAD_RIGHT)
	for i in 20:
		await physics_frame
	var active: RefCounted = _manager.call("active_creature")
	if active == null or str(active.get("species_id")) != "ripplet":
		_fail("physical D-pad switch did not make the second creature active")
	if _rig.get("_target") != _ally:
		_fail("switching left the camera on a stale/non-deployed target")
	if not _rig.is_processing():
		_fail("switching disabled the camera rig")
	await _assert_raw_orbit_changes("after creature switch")


func _prove_aim_cancel_returns_combat_orbit() -> void:
	# CONTROLLER-MAP: the orb is a hotbar item thrown with X, so `interact`
	# (raw button 2) is what opens throw aim on a pad now -- `combat_throw`
	# kept only its keyboard F. RB, which used to carry it, is
	# `creature_recall`, which combat_manager.gd::_flee_pressed() reads as
	# DISENGAGE: pressing it here ended the fight instead of opening the aim.
	await _press_button(JOY_BUTTON_X)
	for i in 30:
		if bool(_manager.call("is_aiming")):
			break
		await physics_frame
	if not bool(_manager.call("is_aiming")):
		_fail("physical X did not enter throw aim despite available orbs")
		return
	print("camera target in aim: %s" % _node_label(_rig.get("_target")))
	if _rig.get("_target") != _player:
		_fail("throw aim did not temporarily target the trainer")
	# throw_aim deliberately guards the same press that opened the mode for
	# 0.15s. Wait beyond that production debounce before testing B/cancel.
	for i in 15:
		await physics_frame
	await _press_button(JOY_BUTTON_B)
	for i in 30:
		if not bool(_manager.call("is_aiming")):
			break
		await physics_frame
	if bool(_manager.call("is_aiming")):
		_fail("physical B did not cancel throw aim")
	if _rig.get("_target") != _ally:
		_fail("cancelled aim did not return camera follow to the active creature")
	if bool(_player.call("locomotion_enabled")):
		_fail("cancelled aim left trainer locomotion active during creature combat")
	await _assert_raw_orbit_changes("after aim cancel")


## CONTROLLER-MAP: "Fleeing is RB. Putting the creature away IS disengaging."
## `combat_run` kept its keyboard Escape and lost its pad button;
## `combat_manager.gd::_flee_pressed()` reads `creature_recall` (RB) instead. B
## is `hotbar_1`/`build_cancel` now and does not end a fight.
func _prove_combat_exit_restores_exploration() -> void:
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_fail("physical RB did not disengage from combat")
		return
	print("camera target on exit: %s" % _node_label(_rig.get("_target")))
	if _rig.get("_target") != _player:
		_fail("combat exit did not return camera target to the trainer")
	if not _rig.is_processing() or not _camera.current:
		_fail("combat exit left the exploration camera inactive")
	if absf(_camera.fov - 70.0) > 0.01 or absf(float(_rig.get("_shoulder"))) > 0.001 \
			or absf(float(_rig.get("_sensitivity_scale")) - 1.0) > 0.001:
		_fail("combat exit did not restore the exploration camera profile")
	if not bool(_player.call("locomotion_enabled")):
		_fail("combat exit did not restore trainer locomotion")
	var deployed: RefCounted = _director.call("ally_instance") as RefCounted
	var party_active: RefCounted = (_game.get("party") as RefCounted).call("active") as RefCounted
	if deployed == null or str(deployed.get("species_id")) != "ripplet" or party_active != deployed:
		_fail("combat exit did not preserve the creature selected by the player")
	if not _ally.visible or str(_ally.get("species_id")) != "ripplet":
		_fail("combat exit did not restore the selected creature as the visible follower")
	await _assert_raw_orbit_changes("exploration after combat")


func _prove_a_second_entry_exit_cycle() -> void:
	# Flee leaves the same wild encounter available. Re-enter through X and exit
	# through B once more to catch state that degrades only after the first cycle.
	var near := _wild.global_position + Vector3(3.0, 0.0, 0.0)
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	await _enter_real_encounter()
	if not bool(_manager.call("is_fighting")):
		_print_entry_diagnostics("second entry refused")
		_fail("the second production encounter would not start")
		return
	_ally = _director.call("ally_body") as Node3D
	if _rig.get("_target") != _ally or not _rig.is_processing():
		_fail("second combat cycle did not retarget a live, processing camera")
	# Let the same production input guard that separates the engage X press from
	# the first charged attack elapse before moving another physical control.
	for i in 20:
		await physics_frame
	await _assert_raw_orbit_changes("second combat cycle")
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")) or _rig.get("_target") != _player:
		_fail("second combat exit did not restore trainer camera follow")


## A failed second entry previously reported only the final inactive state. Keep
## the production physical-button path unchanged, but retain enough state to
## distinguish a stale/wrong interaction winner from CombatManager::begin()
## refusing the selected creature after the first cycle.
func _print_entry_diagnostics(context: String) -> void:
	var engageable := _director.call("_engageable") as Node3D
	var arbiter := get_first_node_in_group("interaction_arbiter")
	var winner: Node = null
	if arbiter != null and arbiter.has_method("winning_provider"):
		winner = arbiter.call("winning_provider") as Node
	var active: RefCounted = (_game.get("party") as RefCounted).call("active") as RefCounted
	var hp := -1.0
	var fainted := true
	var resting := true
	var species := "<null>"
	if active != null:
		hp = float(active.get("hp"))
		fainted = bool(active.get("fainted"))
		resting = bool(active.get("resting"))
		species = str(active.get("species_id"))
	var distance := -1.0
	if engageable != null:
		distance = _player.global_position.distance_to(engageable.global_position)
	var winner_detail := "<none>"
	if winner != null and is_instance_valid(winner):
		var winner_script := winner.get_script() as Script
		var owner := winner.get_parent()
		var owner_script: Script = null
		if owner != null:
			owner_script = owner.get_script() as Script
		var offer: Dictionary = {}
		if winner.has_method("interaction_offer"):
			offer = winner.call("interaction_offer", _player.global_position) as Dictionary
		var winner_position := Vector3.ZERO
		if winner is Node3D:
			winner_position = (winner as Node3D).global_position
		winner_detail = "label=%s offer=%s position=%s distance=%.3f script=%s parent=%s parent_script=%s parent_groups=%s parent_meta=%s" % [
			str(winner.get("label")), str(offer), winner_position,
			_player.global_position.distance_to(winner_position) if winner is Node3D else -1.0,
			winner_script.resource_path if winner_script != null else "<none>",
			_node_label(owner), owner_script.resource_path if owner_script != null else "<none>",
			str(owner.get_groups()) if owner != null else "[]",
			str(_metadata(owner))]
	print("%s: manager=%s active=%s hp=%.2f fainted=%s resting=%s wild=%s visible=%s engageable=%s distance=%.3f arbiter=%s winner=%s" % [
		context, bool(_manager.call("is_fighting")), species, hp, fainted, resting,
		_node_label(_wild), _wild.visible if _wild != null and is_instance_valid(_wild) else false,
		_node_label(engageable), distance, _node_label(arbiter), _node_label(winner)])
	print("%s winner detail: %s" % [context, winner_detail])


func _metadata(node: Node) -> Dictionary:
	var out := {}
	if node == null:
		return out
	for key: StringName in node.get_meta_list():
		var value: Variant = node.get_meta(key)
		# Runtime objects such as Tweens are noisy and cannot identify the owner;
		# retain only scalar/vector metadata useful in a preserved smoke log.
		if value is String or value is StringName or value is bool or value is int \
				or value is float or value is Vector2 or value is Vector3:
			out[str(key)] = value
	return out


func _assert_raw_orbit_changes(context: String) -> void:
	# Keep away from either pitch clamp so both axes have room to move.
	_rig.set("yaw", 0.15)
	_rig.set("pitch", -0.15)
	_rig.rotation = Vector3(-0.15, 0.15, 0.0)
	var yaw_before := float(_rig.get("yaw"))
	var pitch_before := float(_rig.get("pitch"))
	_send_axis(RIGHT_X, 0.72)
	_send_axis(RIGHT_Y, -0.58)
	await physics_frame
	var live := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	print("%s look vector: %s (paused=%s, processing=%s, target=%s)" % [
		context, live, paused, _rig.is_processing(), _node_label(_rig.get("_target"))])
	for i in 18:
		await physics_frame
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	# Everything below must happen inside the rig's manual-look grace: once
	# it expires the neutral tracker is SUPPOSED to recentre. The old
	# 10 + 15 frames (0.417 s) ran past the 0.4 s grace, so "continuously
	# recentred" failed whenever tracking resumed inside the window.
	# Sync on the RIG, not on a frame count: the grace starts counting down
	# only once the rig's own _process has seen the stick at rest, so wait for
	# `_tracking_manual_left` to drop below its full value. Fixed physics or
	# process waits either measured residual stick motion (0.31 rad under
	# load) or ran long enough to pitch the view off the opponent.
	var grace_s := _manual_grace_seconds()
	for i in 240:
		await physics_frame
		if float(_rig.get("_tracking_manual_left")) < grace_s - 0.0001:
			break
	var yaw_after := float(_rig.get("yaw"))
	var pitch_after := float(_rig.get("pitch"))
	# Synthetic joy-motion state may be cleared by the engine after the camera's
	# physics read and before this coroutine resumes. The resulting yaw/pitch
	# deltas below are the durable proof that these raw events reached the rig.
	if absf(angle_difference(yaw_after, yaw_before)) < 0.08:
		_fail("%s: right-stick horizontal input did not orbit the camera" % context)
	if absf(pitch_after - pitch_before) < 0.05:
		_fail("%s: right-stick vertical input did not pitch the camera" % context)
	var held_yaw := yaw_after
	var inside := 0
	var drifted := 0.0
	var observed_s := 0.0
	for i in 240:
		if float(_rig.get("_tracking_manual_left")) <= 0.0:
			break
		await physics_frame
		if float(_rig.get("_tracking_manual_left")) <= 0.0:
			break
		inside += 1
		# On the rig's own clock (its _process delta), not wall time.
		observed_s = maxf(observed_s, grace_s - float(_rig.get("_tracking_manual_left")))
		drifted = maxf(drifted, absf(angle_difference(float(_rig.get("yaw")), held_yaw)))
	if observed_s < MIN_GRACE_SECONDS_OBSERVED:
		_fail("%s: only %.2fs (%d frames) observed inside the manual-look grace (need %.2fs); cannot prove the hold" % [
			context, observed_s, inside, MIN_GRACE_SECONDS_OBSERVED])
	elif drifted > 0.01:
		_fail("%s: camera yaw was continuously recentered after the stick returned to neutral (drift %.3f rad over %.2fs of grace)" % [
			context, drifted, observed_s])


## The grace the rig itself applies right now: combat.json's
## camera.tracking.manual_grace_seconds in combat, the rig default outside it.
func _manual_grace_seconds() -> float:
	var tracking: Dictionary = _rig.get("_tracking_config") as Dictionary
	return float(tracking.get("manual_grace_seconds", 0.4))


## Worst case for the neutral tracker to bring a relocated opponent back into
## frame: a half-turn at max_speed_deg, plus the clear-orbit swing easing back
## over its widest sample, plus one solver interval and a half-second margin.
func _neutral_convergence_frames() -> int:
	var camera: Dictionary = MATH.config().get("camera", {}) as Dictionary
	var tracking: Dictionary = camera.get("tracking", {}) as Dictionary
	var orbit: Dictionary = ((camera.get("framing", {}) as Dictionary) \
		.get("clear_orbit", {}) as Dictionary)
	var turn_s := 180.0 / maxf(float(tracking.get("max_speed_deg", 120.0)), 1.0)
	var widest := 0.0
	for raw: Variant in orbit.get("samples_deg", []):
		widest = maxf(widest, absf(float(raw)))
	var ease_s := widest / maxf(float(orbit.get("ease_deg_per_s", 90.0)), 1.0)
	var seconds := turn_s + ease_s + float(orbit.get("interval_s", 0.2)) + 0.5
	return int(ceil(seconds * float(Engine.physics_ticks_per_second)))


func _press_button(index: JoyButton) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	# Match the project's controller smokes: hold across two rendered frames so
	# both idle UI readers and physics-world readers see the physical press.
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3:
		await process_frame


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _node_label(value: Variant) -> String:
	var node := value as Node
	return str(node.get_path()) if node != null and is_instance_valid(node) else "<null/stale>"


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	_send_axis(LEFT_Y, 0.0)
	print("")
	if _failures.is_empty():
		print("PASS: combat camera follows the active creature, keeps free controller orbit, survives switch/aim, and restores exploration repeatedly")
		quit(0)
		return
	for message: String in _failures:
		print("FAIL: %s" % message)
	quit(1)

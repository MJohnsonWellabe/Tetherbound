extends Node

## Optional read-only companion to the earned-input/net smoke, never its driver.
## Native pixels + runtime observations are evidence for review, not a visual or
## audible acceptance verdict. Headless cannot produce presentation screenshots.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const FRESH := preload("res://tools/fresh_capture_output.gd")
const HOME_SOURCE := "res://scripts/world/home_key.gd"
const TARGET_SECONDS := [0.0, 0.5, 1.5, 2.0]
const MAX_EPISODES := 4
const MAX_SAMPLES := 1200
const MAX_SECONDS := 600.0

var _game: Node
var _output: String
var _native: bool
var _started_msec: int
var _next_sample_msec: int = 0
var _next_flush_msec: int = 0
var _draws: int = 0
var _last_phase: String = "unobserved"
var _episode: Dictionary = {}
var _manifest: Dictionary = {}
var _stopped: bool = false


## Call once in each already-running process, with a distinct fresh directory:
## CAPTURE.attach(tree, game, "res://ralph/reports/F18/native-host-round1")
## Keep the returned node and call finish() at smoke completion before quitting.
static func attach(tree: SceneTree, game: Node, output_path: String) -> Node:
	if tree == null or not is_instance_valid(game) or game.get_tree() != tree:
		push_error("F18 capture requires the actual retained tree and Game.")
		return null
	if not FRESH.create_fresh(output_path, "F18 read-only presentation capture"): return null
	var observer: Node = load("res://tests/helpers/f18_presentation_capture.gd").new()
	observer.name = "F18PresentationCapture"
	observer._game = game
	observer._output = output_path
	observer._native = DisplayServer.get_name() != "headless"
	observer._started_msec = Time.get_ticks_msec()
	observer._manifest = {"schema_version": 1, "pid": OS.get_process_id(),
		"display_server": DisplayServer.get_name(), "native_framebuffer_available": observer._native,
		"capture_source": "actual root viewport texture after frame_post_draw",
		"headless_reason": "" if observer._native else "Headless has no native presentation framebuffer.",
		"acceptance_verdict": "not assessed; pixels require visual review, audio requires listening",
		"started_monotonic_msec": observer._started_msec, "episodes": [], "samples": [], "errors": []}
	observer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(observer)
	if observer._native: RenderingServer.frame_post_draw.connect(observer._after_draw)
	observer._flush()
	return observer


func _process(_delta: float) -> void:
	if _stopped: return
	if not is_instance_valid(_game): finish("actual Game was freed"); return
	if Time.get_ticks_msec() - _started_msec > int(MAX_SECONDS * 1000.0):
		finish("bounded observation deadline reached")
		return
	if not _native: _observe(false)


func _after_draw() -> void:
	if _stopped or not is_instance_valid(_game): return
	_draws += 1
	_observe(true)


func _observe(drawn: bool) -> void:
	var now: int = Time.get_ticks_msec()
	var key: Node = _game.get_node_or_null(^"HomeKey")
	if key != null and (key.get_script() == null or key.get_script().resource_path != HOME_SOURCE): key = null
	var phase: String = str(key.get("_phase")) if key != null else "not_mounted"
	var started: int = int(key.get("_raise_started_msec")) if key != null else 0
	if phase == "raising" and started > 0 and started != int(_episode.get("raise_started_msec", 0)):
		if (_manifest.episodes as Array).size() >= MAX_EPISODES:
			finish("bounded episode limit reached")
			return
		_episode = {"index": (_manifest.episodes as Array).size() + 1, "raise_started_msec": started,
			"use_id": str(key.get("_use_id")), "targets_seen": [], "captures": [],
			"transition_observed": false, "production_fade_observed": false,
			"home_key_black_observed": false,
			"previous_transition_active": false, "before_transition_candidate": false,
			"phase_events": [], "idle_after_raise_observed": false}
		_manifest.episodes.append(_episode)
	var sample: Dictionary = _snapshot(key, now, drawn)
	var changed: bool = phase != _last_phase
	if changed or now >= _next_sample_msec:
		if (_manifest.samples as Array).size() >= MAX_SAMPLES:
			finish("bounded sample limit reached")
			return
		_manifest.samples.append(sample)
		_next_sample_msec = now + (50 if phase == "raising" else 1000)
	if not _episode.is_empty():
		if changed: _episode.phase_events.append({"phase": phase, "monotonic_msec": now})
		var elapsed: float = float(now - int(_episode.raise_started_msec)) / 1000.0
		# Late/blocked frames keep their actual times and phase; no invented frames.
		for target: float in TARGET_SECONDS:
			if elapsed >= target and not (_episode.targets_seen as Array).has(target):
				_episode.targets_seen.append(target)
				_capture("raise_%.1fs" % target, sample, target)
		var transitioning: bool = bool(sample.transition.active)
		if sample.transition.fading: _episode.production_fade_observed = true
		if not transitioning and phase == "raising" and elapsed >= 1.5 and not _episode.before_transition_candidate:
			_episode.before_transition_candidate = true
			_capture("before_transition_candidate", sample)
		if transitioning and not _episode.previous_transition_active:
			_episode.transition_observed = true
			_capture("observed_transition_visible", sample)
		if sample.transition.home_key_is_fading and float(sample.transition.home_key_fade_alpha) >= 0.999 \
			and not _episode.home_key_black_observed:
			_episode.home_key_black_observed = true
			_capture("observed_home_key_black", sample)
		if not transitioning and _episode.previous_transition_active: _capture("after_observed_transition", sample)
		_episode.previous_transition_active = transitioning
		if changed and phase in ["finishing", "travelling"]: _capture(phase, sample)
		if phase == "idle" and not transitioning and not _episode.idle_after_raise_observed:
			_episode.idle_after_raise_observed = true
			_capture("idle_after_raise", sample) # A refusal can also reach idle; see phase/result metadata.
	_last_phase = phase
	if changed or now >= _next_flush_msec:
		_flush()
		_next_flush_msec = now + 1000


func _snapshot(key: Node, now: int, drawn: bool) -> Dictionary:
	var owner: Node = INPUT_OWNER.current(get_tree())
	# Scene/visual cleanup can leave freed references in the retained presenter.
	# Keep raw Variants until validity is checked; casting first itself errors.
	var actor: Variant = key.get("_actor") if key != null else null
	var live_actor: Node = get_tree().current_scene.get_node_or_null(^"Player") if get_tree().current_scene != null else null
	var rig: Variant = key.get("_rig") if key != null else null
	var prop: Variant = key.get("_prop") if key != null else null
	var glow: Variant = key.get("_glow") if key != null else null
	var audio: Variant = key.get("_audio") if key != null else null
	var progress: Variant = null
	var settings: Dictionary = key.get("_settings") if key != null else {}
	if key != null and float(settings.get("raise_seconds", 0.0)) > 0.0:
		progress = clampf(float(key.get("_elapsed")) / float(settings.raise_seconds), 0.0, 1.0)
	var bones: Dictionary = {}
	if is_instance_valid(rig):
		for bone: String in ["RightArm", "RightForeArm", "RightHand"]:
			var index: int = rig.find_bone(bone)
			if index >= 0:
				var pose: Quaternion = rig.get_bone_pose_rotation(index)
				bones[bone] = [pose.x, pose.y, pose.z, pose.w]
	return {"monotonic_msec": now, "process_seconds": float(now - _started_msec) / 1000.0,
		"native_draw": drawn, "draw_index": _draws, "engine_process_frame": Engine.get_process_frames(),
		"phase": str(key.get("_phase")) if key != null else "not_mounted",
		"actual_elapsed_seconds": float(key.get("_elapsed")) if key != null else null, "actual_progress": progress,
		"raise_clock_elapsed_seconds": float(now - int(_episode.raise_started_msec)) / 1000.0 if not _episode.is_empty() else null,
		"realm": str(_game.get("current_realm")), "pending_realm_entry": str(_game.get("pending_realm_entry")),
		"current_scene": _node_info(get_tree().current_scene), "input_owner": _node_info(owner),
		"raise_actor": _node_info(actor), "current_player": _node_info(live_actor), "rig": _node_info(rig),
		"bone_pose_rotations": bones, "key_prop": _node_info(prop),
		"key_prop_bone": prop.bone_name if is_instance_valid(prop) else "",
		"glow": _node_info(glow), "glow_energy": glow.light_energy if is_instance_valid(glow) else null,
		"audio": _audio_info(audio), "remote_raises": _remote_info(key), "transition": _transition_info()}


func _node_info(node: Variant) -> Dictionary:
	if not is_instance_valid(node): return {"present": false}
	var result: Dictionary = {"present": true, "instance_id": node.get_instance_id(),
		"path": str(node.get_path()) if node.is_inside_tree() else "", "class": node.get_class(),
		"script": node.get_script().resource_path if node.get_script() != null else ""}
	if node is Node3D:
		result.visible_in_tree = node.is_visible_in_tree()
		if node.is_inside_tree(): result.position = [node.global_position.x, node.global_position.y, node.global_position.z]
	return result


func _audio_info(audio: Variant) -> Dictionary:
	if not is_instance_valid(audio): return {"present": false, "listened": false}
	var stream: AudioStream = audio.stream
	var bus_index: int = AudioServer.get_bus_index(audio.bus)
	return {"present": true, "playing": audio.playing, "bus": str(audio.bus), "volume_db": audio.volume_db,
		"playback_seconds": audio.get_playback_position(), "stream_class": stream.get_class() if stream != null else "",
		"stream_path": stream.resource_path if stream != null else "", "stream_seconds": stream.get_length() if stream != null else null,
		"bus_muted": AudioServer.is_bus_mute(bus_index) if bus_index >= 0 else null,
		"bus_volume_db": AudioServer.get_bus_volume_db(bus_index) if bus_index >= 0 else null, "listened": false}


func _remote_info(key: Node) -> Array:
	var out: Array = []
	if key == null: return out
	for child: Node in key.get_children():
		if child.get_script() == null or child.get_script().resource_path != HOME_SOURCE: continue
		out.append({"visual": _node_info(child), "elapsed_seconds": child.get("_elapsed"),
			"actor": _node_info(child.get("_actor")), "rig": _node_info(child.get("_rig")),
			"prop": _node_info(child.get("_prop")), "glow": _node_info(child.get("_glow")),
			"audio": _audio_info(child.get("_audio"))})
	return out


func _transition_info() -> Dictionary:
	var key: Node = _game.get_node_or_null(^"HomeKey")
	var key_fading: bool = key != null and key.has_method("is_fading") and key.call("is_fading") == true
	var key_rect: ColorRect = key.get_node_or_null(^"HomeKeyFade/Black") as ColorRect if key != null else null
	var overlay: Node = get_tree().root.get_node_or_null(^"LoadingOverlay")
	var backdrop: ColorRect = overlay.get_node_or_null(^"Backdrop") as ColorRect if overlay != null else null
	var fading_sources: Array = []
	for node: Node in get_tree().get_nodes_in_group("progression_restore"):
		if node.has_method("is_fading") and node.call("is_fading") == true: fading_sources.append(_node_info(node))
	var overlay_visible: bool = is_instance_valid(backdrop) and backdrop.is_visible_in_tree() and backdrop.color.a > 0.0
	return {"active": key_fading or overlay_visible or not fading_sources.is_empty(),
		"fading": key_fading or not fading_sources.is_empty(), "home_key_is_fading": key_fading,
		"home_key_fade": _node_info(key_rect), "home_key_fade_alpha": key_rect.color.a if is_instance_valid(key_rect) else null,
		"loading_overlay": _node_info(overlay),
		"overlay_visible": overlay_visible, "overlay_alpha": backdrop.color.a if is_instance_valid(backdrop) else null,
		"reported_fading_sources": fading_sources,
		"interpretation": "overlay visibility/production is_fading observation; smooth fade has not been judged"}


func _capture(label: String, sample: Dictionary, target: float = -1.0) -> void:
	var capture: Dictionary = {"label": label, "observation": sample, "png": "", "status": "unavailable_headless"}
	if target >= 0.0:
		capture.target_seconds = target
		capture.target_error_seconds = float(sample.raise_clock_elapsed_seconds) - target
		capture.near_target = absf(float(capture.target_error_seconds)) <= 0.25
		capture.raise_visual_present = sample.phase in ["raising", "finishing"] \
			and sample.rig.present and sample.key_prop.present
	if _native and sample.native_draw:
		var texture: ViewportTexture = get_tree().root.get_texture()
		var image: Image = texture.get_image() if texture != null else null
		if image == null or image.is_empty(): capture.status = "unavailable_empty_native_framebuffer"
		else:
			var filename: String = "episode_%02d_%03d_%s.png" % [_episode.index, (_episode.captures as Array).size(), label]
			var error: Error = image.save_png(_output.path_join(filename))
			capture.status = "captured_native_frame" if error == OK else "png_write_failed"
			capture.png = filename if error == OK else ""
			capture.image_size = [image.get_width(), image.get_height()]
			if error != OK: _manifest.errors.append("PNG write failed: %s (%d)" % [filename, error])
	_episode.captures.append(capture)
	_flush()


func _flush() -> void:
	var file: FileAccess = FileAccess.open(_output.path_join("presentation.json"), FileAccess.WRITE)
	if file == null:
		push_error("F18 capture cannot write its requested observation manifest.")
		return
	file.store_string(JSON.stringify(_manifest, "\t"))


func finish(reason: String = "smoke completed") -> void:
	if _stopped: return
	_stopped = true
	set_process(false)
	if RenderingServer.frame_post_draw.is_connected(_after_draw): RenderingServer.frame_post_draw.disconnect(_after_draw)
	_manifest.finished_monotonic_msec = Time.get_ticks_msec()
	_manifest.stop_reason = reason
	_manifest.native_draws_observed = _draws
	_flush()

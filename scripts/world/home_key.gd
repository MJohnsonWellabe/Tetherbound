extends Node

## Game mounts this persistent presentation owner once, and routes Satchel Use
## and quick bindings to use(). Only the host authorizes begin and completion.
## Neither animation completion nor a client clock grants travel permission.
const DATA := preload("res://scripts/data/redesign_data.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")

var _settings: Dictionary = {}
var _game: Node
var _phase := "idle"
var _pending := ""
var _use_id := ""
var _elapsed := 0.0
var _wait := 0.0
var _raise_started_msec := 0
var _wait_started_msec := 0
var _refusal_at := -INF
var _rig: Skeleton3D
var _mixer: AnimationPlayer
var _mixer_active := true
var _before: Dictionary = {}
var _prop: BoneAttachment3D
var _glow: OmniLight3D
var _audio: AudioStreamPlayer
var _actor: Node3D
var _closing_edge := false
var _remote_only := false
var _remote_raises: Dictionary = {}
var _abandoned_begins: Dictionary = {}
var _travel_identity: Dictionary = {}
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _fade_generation: int = 0
var _fade_locked: bool = false


func _ready() -> void:
	_settings = (DATA.json("res://data/config/portals.json") as Dictionary).get("home_key", {}).duplicate(true)
	_game = get_node_or_null(^"/root/Game")
	if _remote_only:
		return
	add_to_group(INPUT_OWNER.GROUP)
	if _game != null and _game.has_signal("portal_action_result"):
		_game.connect("portal_action_result", _result)
	if _game != null and _game.get("session") != null:
		_game.get("session").connect("session_ended", func(_reason: String) -> void: _reset())


func owns_input() -> bool:
	return _fade_locked or _closing_edge or _phase in ["confirming", "raising", "finishing", "travelling", "cancelling"]


func use() -> bool:
	if _fade_locked: return false
	if _phase == "settling": _refuse("Your previous arrival is still waiting to save.")
	if _phase != "idle":
		return false
	if _game == null or not _game.has_method("request_portal_action") \
			or not _game.has_method("home_key_refusal"):
		_refuse("The Home Key is not ready yet.")
		return false
	var reason := str(_game.call("home_key_refusal"))
	if not reason.is_empty():
		_refuse(reason)
		return false
	# The inventory UI must close before this call; another input owner must
	# never be stolen by the key. The host independently checks dialogue etc.
	if INPUT_OWNER.current(get_tree()) != null:
		_refuse("Close the current screen first.")
		return false
	var queued: Dictionary = _game.call("request_portal_action", {"kind": "home_key_begin"})
	if not bool(queued.get("ok", false)):
		_refuse(str(queued.get("reason", "The Home Key could not confirm.")))
		return false
	_pending = str(queued.get("request_id", ""))
	if _pending.is_empty():
		_refuse("The Home Key could not confirm.")
		return false
	_phase = "confirming"
	_wait = 0.0
	_wait_started_msec = _now_msec()
	return true


func _now_msec() -> int:
	return Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if _closing_edge and not Input.is_action_pressed("menu_cancel") and not Input.is_action_pressed("hotbar_1"):
		_closing_edge = false
	if _remote_only:
		if not is_instance_valid(_actor) or not is_instance_valid(_rig):
			queue_free()
			return
		_elapsed = maxf(0.0, float(_now_msec() - _raise_started_msec) / 1000.0)
		_animate(clampf(_elapsed / float(_settings.raise_seconds), 0.0, 1.0))
		if _elapsed >= float(_settings.response_timeout_seconds):
			queue_free()
		return
	if _phase == "idle":
		return
	if _phase in ["travelling", "settling"]:
		# The exact consumed permit has handed off to the bounded realm/arrival
		# owner. Its final saved reply, refusal or session end releases input.
		if not _travel_binding_current(): _reset()
		return
	# The host's ready/expiry bounds use monotonic milliseconds. Frame delta
	# is capped during slow frames and can otherwise stretch a two-second
	# presentation past the host's deadline in an expensive live world.
	_wait = maxf(0.0, float(_now_msec() - _wait_started_msec) / 1000.0)
	if _wait >= float(_settings.response_timeout_seconds):
		cancel("The Home Key lost its connection. Check your position before trying again.")
		return
	if _phase == "confirming" and Input.is_action_just_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		cancel("")
		_closing_edge = true
		return
	if _phase != "raising":
		return
	if Input.is_action_just_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		cancel("")
		_closing_edge = true
		return
	var reason := str(_game.call("home_key_refusal"))
	if not reason.is_empty():
		cancel(reason)
		return
	if not is_instance_valid(_actor) or not is_instance_valid(_rig):
		cancel("The Home Key could not finish its raise.")
		return
	_elapsed = maxf(0.0, float(_now_msec() - _raise_started_msec) / 1000.0)
	var progress := clampf(_elapsed / float(_settings.raise_seconds), 0.0, 1.0)
	_animate(progress)
	if progress >= 1.0:
		var queued: Dictionary = _game.call("request_portal_action", {
			"kind": "home_key_finish", "use_id": _use_id})
		if not bool(queued.get("ok", false)) or str(queued.get("request_id", "")).is_empty():
			cancel(str(queued.get("reason", "The Home Key could not finish.")))
			return
		_pending = str(queued.request_id)
		_phase = "finishing"
		_wait = 0.0
		_wait_started_msec = _now_msec()


func _result(result: Dictionary) -> void:
	var kind := str(result.get("kind", ""))
	if not kind.begins_with("home_key_"):
		return
	var request_id := str(result.get("request_id", ""))
	if kind == "home_key_begin" and _abandoned_begins.has(request_id):
		_abandoned_begins.erase(request_id)
		# B or timeout can race a delayed host-approved begin. Lower that exact
		# approved channel without reviving a cancelled local animation.
		var approved_id := str(result.get("use_id", ""))
		if bool(result.get("ok", false)) and not approved_id.is_empty():
			_game.call("request_portal_action", {"kind": "home_key_cancel", "use_id": approved_id})
		return
	var approved_cancel := kind == "home_key_cancel" and not _use_id.is_empty() \
		and str(result.get("use_id", "")) == _use_id
	if not approved_cancel and (_pending.is_empty() or request_id != _pending):
		return
	if not bool(result.get("ok", false)):
		_refuse(str(result.get("reason", "The Home Key could not confirm. You stay where you are.")))
		_reset()
		return
	if kind == "home_key_begin" and _phase == "confirming":
		_use_id = str(result.get("use_id", _pending))
		var owner := INPUT_OWNER.current(get_tree())
		if owner != null and owner != self:
			cancel("Close the current screen before raising the Home Key.")
			return
		var reason := str(_game.call("home_key_refusal"))
		if not reason.is_empty():
			cancel(reason)
			return
		_actor = _game.call("find_player") as Node3D
		if not _start_visual(_actor):
			cancel("The Home Key could not begin its raise.")
			return
		_phase = "raising"
		_elapsed = 0.0
		_wait = 0.0
		_raise_started_msec = _now_msec()
		_wait_started_msec = _raise_started_msec
	elif kind in ["home_key_finish", "home_key_cancel"]:
		_reset()


func cancel(reason: String = "") -> void:
	if _phase == "idle":
		return
	if _phase == "confirming" and not _pending.is_empty():
		_abandoned_begins[_pending] = true
		while _abandoned_begins.size() > int(_settings.max_abandoned_begins):
			_abandoned_begins.erase(_abandoned_begins.keys()[0])
	# Cancel uses the immutable approved begin identity. ROOT's host expiry also
	# clears raises when a disconnect prevents this message reaching the host.
	if _game != null and _game.has_method("request_portal_action"):
		_game.call("request_portal_action", {"kind": "home_key_cancel", "use_id": _use_id if not _use_id.is_empty() else _pending})
	if not reason.is_empty():
		_refuse(reason)
	_reset()
	# Consume the closing B press so it cannot use hotbar slot one on this frame.
	INPUT_OWNER.suppress_pause_reopen(get_tree())

func travel_started(request_id: String) -> bool:
	if _phase != "finishing" or _pending.is_empty() or request_id != _pending: return false
	var session: Node = _game.get("session")
	if session == null or _game.get("local") == null or _game.get("world") == null: return false
	_travel_identity = {"owner": weakref(_game.get("local")), "world": weakref(_game.get("world")),
		"session": weakref(session), "epoch": str(session.call("_altar_current_epoch")),
		"character_id": str(_game.get("local").get("character_id")),
		"world_namespace": str(_game.get("world").get("reward_delivery_namespace"))}
	_stop_visual()
	_phase = "travelling"
	# Only the already-consumed permit's caller awaits this presentation seam.
	# The fade has no save/ACK/permit side effects and cannot authorize travel.
	if not is_inside_tree() or get_viewport() == null: return true
	_build_fade()
	_fade_generation += 1
	var generation: int = _fade_generation
	_fade_locked = true
	var black: bool = await _fade_to(1.0, float(_settings.get("fade_out_seconds", 0.18)), generation)
	return black and generation == _fade_generation and _phase == "travelling" \
		and _pending == request_id and _travel_binding_current()

func _travel_binding_current() -> bool:
	if _travel_identity.is_empty() or _game == null: return false
	var owner: RefCounted = _travel_identity.owner.get_ref()
	var world: RefCounted = _travel_identity.world.get_ref()
	var session: Node = _travel_identity.session.get_ref()
	return owner != null and world != null and session != null \
		and _game.get("local") == owner and _game.get("world") == world and _game.get("session") == session \
		and owner.get("character_id") == _travel_identity.character_id \
		and world.get("reward_delivery_namespace") == _travel_identity.world_namespace \
		and session.call("_altar_current_epoch") == _travel_identity.epoch

func save_waiting(request_id: String) -> void:
	if _phase != "travelling" or _pending.is_empty() or request_id != _pending: return
	_phase = "settling"
	_clear_fade()
	_refuse("Your arrival is waiting to save. You can move while it retries.")


## Read-only presentation seam used by the optional native evidence observer.
func is_fading() -> bool:
	return is_instance_valid(_fade_rect) and _fade_rect.is_visible_in_tree() and _fade_rect.color.a > 0.0


func _build_fade() -> void:
	if is_instance_valid(_fade_layer): return
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "HomeKeyFade"
	_fade_layer.layer = UI_TOKENS.LAYER_MENU + 20
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_rect = ColorRect.new()
	_fade_rect.name = "Black"
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)
	add_child(_fade_layer) # Game's persistent child survives the ordinary realm swap.


func _fade_to(alpha: float, seconds: float, generation: int) -> bool:
	if not is_inside_tree() or not is_instance_valid(_fade_rect): return false
	var tree: SceneTree = get_tree()
	var before: float = _fade_rect.color.a
	var began: int = Time.get_ticks_msec()
	var duration: float = maxf(0.0, seconds) if is_finite(seconds) else 0.0
	while true:
		if generation != _fade_generation or not is_inside_tree() or not is_instance_valid(_fade_rect): return false
		var progress: float = clampf(float(Time.get_ticks_msec() - began) / (duration * 1000.0), 0.0, 1.0) if duration > 0.0 else 1.0
		_fade_rect.color.a = lerpf(before, alpha, progress)
		if progress >= 1.0: break
		await tree.process_frame
	# Give the real viewport its black frame before the awaited caller moves.
	# Headless still exercises the fade state; detached fixtures skip it above.
	if alpha > 0.0:
		await tree.process_frame
		await tree.process_frame
	return generation == _fade_generation and is_inside_tree() and is_instance_valid(_fade_rect)


func _clear_fade() -> void:
	_fade_generation += 1 # Retire every earlier black/clear callback first.
	var generation: int = _fade_generation
	if not is_inside_tree() or not is_instance_valid(_fade_rect):
		_remove_fade_now()
		return
	_fade_locked = true
	var clear: bool = await _fade_to(0.0, float(_settings.get("fade_in_seconds", 0.20)), generation)
	if clear and generation == _fade_generation: _remove_fade_now()


func _remove_fade_now() -> void:
	_fade_generation += 1
	_fade_locked = false
	if is_instance_valid(_fade_layer): _fade_layer.queue_free()
	_fade_layer = null
	_fade_rect = null


func _start_visual(actor: Node3D) -> bool:
	if actor == null:
		return false
	var model := actor.get_node_or_null(^"Model")
	if model == null or not model.has_method("skeleton") or not model.has_method("animation_player"):
		return false
	_rig = model.call("skeleton") as Skeleton3D
	_mixer = model.call("animation_player") as AnimationPlayer
	if _rig == null or _rig.find_bone("RightHand") < 0:
		return false
	for bone: String in ["RightArm", "RightForeArm"]:
		var index := _rig.find_bone(bone)
		if index < 0:
			return false
		_before[index] = _rig.get_bone_pose_rotation(index)
	if _mixer != null:
		_mixer_active = _mixer.active
		_mixer.active = false
	_prop = BoneAttachment3D.new()
	_prop.name = "RaisedHomeKey"
	_prop.bone_name = "RightHand"
	_rig.add_child(_prop)
	_build_key(_prop)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(str(_settings.glow_color))
	_glow.omni_range = float(_settings.glow_range_m)
	_glow.light_energy = 0.0
	_prop.add_child(_glow)
	_play_chime()
	return true


## ROOT routes trusted host presentation events here. Remotes animate without
## taking this peer's input, touching inventory or issuing a travel intent.
func show_remote_raise(actor: Node3D, use_id: String) -> bool:
	if use_id.is_empty() or _remote_raises.has(use_id):
		return false
	var visual: Node = get_script().new()
	visual.set("_remote_only", true)
	visual.set("_actor", actor)
	visual.set("_raise_started_msec", _now_msec())
	add_child(visual)
	if not bool(visual.call("_start_visual", actor)):
		visual.queue_free()
		return false
	_remote_raises[use_id] = visual
	visual.tree_exited.connect(_remote_raise_exited.bind(use_id, visual.get_instance_id()))
	return true


func _remote_raise_exited(use_id: String, instance_id: int) -> void:
	var current: Variant = _remote_raises.get(use_id)
	if is_instance_valid(current) and current.get_instance_id() != instance_id:
		return
	_remote_raises.erase(use_id)


func end_remote_raise(use_id: String) -> void:
	var visual: Variant = _remote_raises.get(use_id)
	if is_instance_valid(visual):
		visual.queue_free()
	_remote_raises.erase(use_id)


func clear_remote_raises() -> void:
	for use_id: String in _remote_raises.keys():
		end_remote_raise(use_id)


func _build_key(parent: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("dcc78d")
	material.metallic = 0.75
	material.roughness = 0.3
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(float(_settings.key_width_m), float(_settings.key_shaft_m), float(_settings.key_width_m))
	shaft.mesh = box
	shaft.material_override = material
	shaft.position.y = float(_settings.key_shaft_m) * 0.5
	parent.add_child(shaft)
	var bow := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = float(_settings.key_bow_radius_m) * 0.66
	ring.outer_radius = float(_settings.key_bow_radius_m)
	bow.mesh = ring
	bow.material_override = material
	bow.rotation.x = PI * 0.5
	bow.position.y = float(_settings.key_shaft_m)
	parent.add_child(bow)
	var tooth := MeshInstance3D.new()
	var tooth_box := BoxMesh.new()
	tooth_box.size = Vector3(float(_settings.key_width_m) * 3.0, float(_settings.key_width_m), float(_settings.key_width_m))
	tooth.mesh = tooth_box
	tooth.material_override = material
	tooth.position.x = float(_settings.key_width_m)
	parent.add_child(tooth)


func _animate(progress: float) -> void:
	var ramp := smoothstep(0.0, float(_settings.pose_ramp_fraction), progress)
	for bone: String in ["RightArm", "RightForeArm"]:
		var index := _rig.find_bone(bone)
		var degrees := float(_settings.shoulder_degrees if bone == "RightArm" else _settings.elbow_degrees)
		var original: Quaternion = _before[index]
		_rig.set_bone_pose_rotation(index, original * Quaternion(Vector3.RIGHT, deg_to_rad(degrees) * ramp))
	if is_instance_valid(_glow):
		_glow.light_energy = float(_settings.glow_energy) * progress


func _play_chime() -> void:
	# Original transient synthesis: no new audio asset, external purchase or
	# dependence on the missing Stormwood sound bank. A gentle rising key tone.
	var rate := 22050
	var samples := int(float(_settings.raise_seconds) * rate)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var phase := 0.0
	for index: int in samples:
		var t := float(index) / float(samples)
		var hz := lerpf(float(_settings.sound_hz_start), float(_settings.sound_hz_end), t)
		phase += TAU * hz / float(rate)
		var envelope := sin(PI * t) * float(_settings.sound_gain)
		bytes.encode_s16(index * 2, int(sin(phase) * envelope * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	_audio = AudioStreamPlayer.new()
	_audio.stream = stream
	_audio.bus = "SFX"
	_audio.volume_db = float(_settings.sound_volume_db)
	add_child(_audio)
	_audio.play()


func _stop_visual() -> void:
	if is_instance_valid(_rig):
		for index: Variant in _before:
			_rig.set_bone_pose_rotation(int(index), _before[index])
	if is_instance_valid(_mixer):
		_mixer.active = _mixer_active
	if is_instance_valid(_prop):
		_prop.queue_free()
	if is_instance_valid(_audio):
		_audio.stop()
		_audio.queue_free()
	_before.clear()
	_rig = null
	_mixer = null
	_prop = null
	_audio = null
	_actor = null

func _reset() -> void:
	_stop_visual()
	_clear_fade()
	_travel_identity.clear()
	_phase = "idle"
	_pending = ""
	_use_id = ""


func _exit_tree() -> void:
	# An exiting presentation must never start an asynchronous clear on a tree
	# it is leaving, or retain black pixels above a replacement Game instance.
	_stop_visual()
	_remove_fade_now()
	_travel_identity.clear()
	_phase = "idle"
	_pending = ""
	_use_id = ""


func _refuse(reason: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _refusal_at < float(_settings.get("refusal_interval_seconds", 2.0)):
		return
	_refusal_at = now
	if _game != null and _game.has_method("push_world_message"):
		_game.call("push_world_message", reason)

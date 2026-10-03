extends Node3D

## Mounted under F17's authored slot by the shared world owner. This component
## offers ordinary X input; it cannot debit an item, write an unlock or travel.
const DATA := preload("res://scripts/data/redesign_data.gd")
const ORDER := preload("res://scripts/data/biome_order.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")

var arch_id := ""
var _row: Dictionary = {}
var _settings: Dictionary = {}
var _prompt: Node3D
var _game: Node
var _pending := ""
var _wait := 0.0
var _refresh_elapsed := 0.0
var _stir_settings: Dictionary = {}
var _stir_light: OmniLight3D
var _stir_elapsed := -1.0
var _stir_seen := false
var _stir_audio: AudioStreamPlayer3D


func setup(id: String) -> bool:
	var config: Dictionary = DATA.json("res://data/config/portals.json")
	for value: Dictionary in config.get("arches", []):
		if str(value.get("id", "")) == id:
			arch_id = id
			_row = value.duplicate(true)
			_settings = config.get("arch", {}).duplicate(true)
			_stir_settings = config.get("fifth_stir", {}).duplicate(true)
			return true
	return false


func _ready() -> void:
	if _row.is_empty():
		push_error("PortalArch requires a configured authored slot")
		set_process(false)
		return
	add_to_group("portal_arches")
	_game = get_node_or_null(^"/root/Game")
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.call("configure", "", float(_settings.interaction_radius_m), true)
	_prompt.activated.connect(_activate)
	add_child(_prompt)
	if _game != null and _game.has_signal("portal_action_result"):
		_game.connect("portal_action_result", _result)
	refresh()
	# Restoring saved presentation is silent. A durable use result alone starts
	# the moment; loading a stirred world never repeats its sound or line.
	_stir_seen = bool(_view().get("character_stirred", false))


func _process(delta: float) -> void:
	if _stir_elapsed >= 0.0:
		_stir_elapsed += delta
		var fraction := clampf(_stir_elapsed / float(_stir_settings.glow_seconds), 0.0, 1.0)
		_stir_light.light_energy = lerpf(float(_stir_settings.glow_energy),
			float(_stir_settings.resting_energy), fraction)
		if fraction >= 1.0:
			_stir_elapsed = -1.0
	_refresh_elapsed += delta
	if not _pending.is_empty():
		_wait += delta
		if _wait >= float(_settings.response_timeout_seconds):
			_pending = ""
			_message("The portal is still confirming. Check the arch before trying again.")
	if _refresh_elapsed >= float(_settings.refresh_seconds):
		_refresh_elapsed = 0.0
		refresh()


func refresh() -> void:
	if _prompt == null:
		return
	var view := _view()
	var label := prompt_text(_row, view)
	_prompt.set("label", "Confirming the portal…" if not _pending.is_empty() else label)
	_prompt.set("actionable", _pending.is_empty() and bool(view.get("ready", false)) \
		and ((str(_row.kind) == "live" and (bool(view.get("open", false)) or bool(view.get("has_key", false)))) \
		or (arch_id == "biome5" and bool(view.get("has_key", false)) and not bool(view.get("character_stirred", false)))))
	if arch_id == "biome5" and bool(view.get("fifth_arch_stirred", false)):
		_restore_stir_glow()
	# Preserve the shared Hall's world display. The offer is per traveler, so an
	# ahead guest's own unlock does not falsely open the world for other peers.


static func prompt_text(row: Dictionary, view: Dictionary) -> String:
	if str(row.get("id", "")) == "biome5":
		if bool(view.get("ready", false)) and bool(view.get("has_key", false)) \
				and not bool(view.get("character_stirred", false)):
			return "Use the fifth key"
		return "The arch is quiet." if bool(view.get("fifth_arch_stirred", false)) else "Sealed"
	if str(row.get("kind", "sealed")) == "sealed":
		return "Sealed"
	var name := ORDER.display_name(str(row.get("biome", "")))
	var level := int(view.get("recommended_level", row.get("recommended_level", 0)))
	var sign := "%s · Recommended Lv %d" % [name, level]
	if not bool(view.get("ready", false)):
		return sign + " · Travel is not ready yet"
	var key_name := "%s Portal Key" % name
	if bool(view.get("has_key", false)) and not bool(view.get("character_open", false)):
		return "Use %s · Recommended Lv %d · open permanently for your character" % [key_name, level]
	if bool(view.get("open", false)):
		return "Enter %s · to %s" % [sign, str(view.get("destination_label", "biome entry"))]
	if bool(view.get("has_key", false)):
		return "Use %s · %s" % [key_name, sign]
	return sign + " · Needs the " + key_name


func _view() -> Dictionary:
	if _game == null or not _game.has_method("portal_view"):
		return {}
	var raw: Variant = _game.call("portal_view", arch_id)
	return raw if raw is Dictionary else {}


func _activate() -> void:
	if not _pending.is_empty() or (str(_row.kind) != "live" and arch_id != "biome5"):
		return
	var view := _view()
	if not bool(view.get("ready", false)):
		_message("Travel is not ready yet.")
		return
	if arch_id == "biome5":
		if bool(view.get("has_key", false)) and not bool(view.get("character_stirred", false)):
			_queue("portal_unlock")
		return
	if not bool(view.get("open", false)) and not bool(view.get("has_key", false)):
		_message(prompt_text(_row, view))
		return
	if _game == null or not _game.has_method("request_portal_action"):
		return
	var needs_personal_unlock := bool(view.get("has_key", false)) and not bool(view.get("character_open", false))
	var kind := "portal_enter" if bool(view.get("open", false)) and not needs_personal_unlock else "portal_unlock"
	_queue(kind)


## Backpack Use at the matching arch permits spending a newly earned key in
## another host world even when the portable character unlock already exists.
## Ordinary X remains Enter for an open arch. ROOT routes item Use here only.
func use_key() -> bool:
	var view := _view()
	if not _pending.is_empty() or (str(_row.kind) != "live" and arch_id != "biome5") \
			or not bool(view.get("ready", false)) or not bool(view.get("has_key", false)):
		return false
	if arch_id == "biome5" and bool(view.get("character_stirred", false)):
		return false
	return _queue("portal_unlock")


func _queue(kind: String) -> bool:
	if _game == null or not _game.has_method("request_portal_action"):
		return false
	var queued: Dictionary = _game.call("request_portal_action", {"kind": kind, "arch_id": arch_id})
	if not bool(queued.get("ok", false)):
		_message(str(queued.get("reason", "The portal could not confirm. Your key is safe.")))
		return false
	_pending = str(queued.get("request_id", ""))
	if _pending.is_empty():
		_message("The portal could not confirm. Your key is safe.")
		return false
	_wait = 0.0
	refresh()
	return true


func _result(result: Dictionary) -> void:
	if _pending.is_empty() or str(result.get("request_id", "")) != _pending:
		return
	if not str(result.get("kind", "")).begins_with("portal_"):
		return
	_pending = ""
	if not bool(result.get("ok", false)):
		_message(str(result.get("reason", "The portal did not open. Your key is safe.")))
	elif str(result.get("kind")) == "portal_unlock":
		if arch_id == "biome5":
			show_committed_stir(result)
		else:
			_message("The portal is open.")
	refresh()


## Shared authority may forward the durable world presentation to other peers.
## This method presents only; it cannot set a stir flag, debit a key or open.
func show_committed_stir(receipt: Dictionary) -> bool:
	if arch_id != "biome5" or _stir_seen or receipt.get("kind") != "portal_unlock" \
			or receipt.get("arch_id") != arch_id or not bool(receipt.get("ok", false)) \
			or receipt.get("durable") != true:
		return false
	for field: String in ["request_id", "character_id", "world_instance_id"]:
		if not receipt.get(field) is String or str(receipt[field]).is_empty():
			return false
	_stir_seen = true
	_restore_stir_glow()
	_stir_elapsed = 0.0
	_stir_light.light_energy = float(_stir_settings.glow_energy)
	_play_stir_hum()
	var dust := CPUParticles3D.new()
	dust.one_shot = true
	dust.amount = int(_stir_settings.dust_count)
	dust.lifetime = float(_stir_settings.dust_seconds)
	dust.explosiveness = 1.0
	dust.position.y = float(_stir_settings.dust_height_m)
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(float(_stir_settings.dust_width_m), 0.05, 0.1)
	dust.direction = Vector3.UP
	dust.gravity = Vector3.ZERO
	dust.initial_velocity_min = float(_stir_settings.dust_speed_mps) * 0.5
	dust.initial_velocity_max = float(_stir_settings.dust_speed_mps)
	dust.color = Color(str(_stir_settings.glow_color))
	var mesh := SphereMesh.new()
	mesh.radius = float(_stir_settings.dust_radius_m)
	mesh.height = mesh.radius * 2.0
	dust.mesh = mesh
	dust.finished.connect(dust.queue_free)
	add_child(dust)
	dust.emitting = true
	_message(str(_stir_settings.line))
	return true


func _restore_stir_glow() -> void:
	if _stir_light != null:
		return
	_stir_light = OmniLight3D.new()
	_stir_light.position.y = float(_stir_settings.glow_height_m)
	_stir_light.light_color = Color(str(_stir_settings.glow_color))
	_stir_light.omni_range = float(_stir_settings.glow_range_m)
	_stir_light.light_energy = float(_stir_settings.resting_energy)
	add_child(_stir_light)


func _play_stir_hum() -> void:
	# Original short tone on SFX: no missing/placeholder cue can turn a receipt
	# into a claimed audible effect. Actual audibility still needs runtime proof.
	var rate := 22050
	var samples := int(float(_stir_settings.glow_seconds) * rate)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for index: int in samples:
		var seconds := float(index) / rate
		var envelope := sin(PI * float(index) / samples) * float(_stir_settings.hum_gain)
		var tone := sin(TAU * float(_stir_settings.hum_hz) * seconds)
		bytes.encode_s16(index * 2, int(tone * envelope * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	_stir_audio = AudioStreamPlayer3D.new()
	_stir_audio.stream = stream
	_stir_audio.bus = "SFX"
	_stir_audio.volume_db = float(_stir_settings.hum_volume_db)
	_stir_audio.finished.connect(_stir_audio.queue_free)
	add_child(_stir_audio)
	_stir_audio.play()


func _message(text: String) -> void:
	if _game != null and _game.has_method("push_world_message"):
		_game.call("push_world_message", text)

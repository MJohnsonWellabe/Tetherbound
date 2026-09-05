extends Node

## Read-only progression projection. Never dispatches story events or grants
## flags/rewards; world bindings and the production audio buses express state.
signal presentation_changed(state: Dictionary)

const AUDIO := preload("res://scripts/audio/audio_manager.gd")
const MAP := preload("res://scripts/world/cloudreach_map_state.gd")
const CONFIG_PATH := "res://data/config/cloudreach_atmosphere.json"
var config: Dictionary = {}
var chapter: Dictionary = {}
var world_data: Dictionary = {}
var progression: RefCounted
var navigation: RefCounted
var player: Node3D
var bindings: Dictionary = {}
var _layers: Dictionary = {}
var _gains: Dictionary = {}
var _targets: Dictionary = {}
var _light_energy: Dictionary = {}
var _presentation: Dictionary = {}
var _finale_active := false


static func read_json(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


func configure(flags: RefCounted, map_state: RefCounted, actor: Node3D,
		world_bindings: Dictionary = {}, data: Dictionary = {}) -> void:
	progression = flags
	navigation = map_state
	player = actor
	bindings = world_bindings
	_presentation = {} # New bindings must receive state even when flags match.
	config = read_json(CONFIG_PATH) if data.is_empty() else data
	chapter = read_json("res://data/config/cloudreach_chapter.json")
	world_data = read_json("res://data/config/cloudreach_world.json")
	if is_inside_tree():
		_build_audio()
		sync_progression()


func _ready() -> void:
	add_to_group("progression_restore")
	if not config.is_empty():
		_build_audio()
		sync_progression()


static func has_flag(flags: RefCounted, id: String) -> bool:
	return flags != null and bool(flags.call("has", id))


static func presentation_for(flags: RefCounted) -> Dictionary:
	var restored := has_flag(flags, "cloudreach_winds_restored")
	var network_off := has_flag(flags, "storm_anchor_network_disabled") or restored
	return {"fly_routes": has_flag(flags, "fly_traversal_unlocked"),
		"upper_routes": has_flag(flags, "cloudreach_upper_route_unlocked"),
		"returning_travelers": restored, "shrine_brightened": restored,
		"anchor_drone": not network_off, "natural_anchor_wind": restored,
		"waterward_overlook": restored and has_flag(flags, "captain_veyra_defeated") and has_flag(flags, "waterward_route_revealed"),
		"waterward_enterable": false}


static func mix_for(data: Dictionary, region: String, flags: RefCounted, finale: bool,
		near_settlement: bool) -> Dictionary:
	var mix: Dictionary = data.get("region_mix", {}).get(region, {"wind": 0.35, "exposed_cliff": 0.25}).duplicate(true)
	if not near_settlement:
		mix["settlement"] = 0.0
	var freed := has_flag(flags, "cloudreach_winds_restored")
	var network_off := freed or has_flag(flags, "storm_anchor_network_disabled")
	if network_off:
		mix["boss_zone_escalation"] = 0.0
	if freed:
		mix["distant_bird_calls"] = float(data.get("restored_bird_gain", 0.32))
		mix["wind"] = float(data.get("restored_wind_gain", 0.55))
		mix["exposed_cliff"] = float(data.get("restored_exposed_gain", 0.3))
	mix["boss_music"] = float(data.get("finale_music_gain", 0.65)) \
		if finale and not network_off and region == "summit_final_stronghold" else 0.0
	return mix


func set_finale_active(active: bool) -> void:
	_finale_active = active
	sync_progression()


func restore_progression_from_game(game: Node) -> void:
	progression = game.get("progression")
	_finale_active = false
	sync_progression()


func sync_progression() -> void:
	if progression == null or not is_instance_valid(player):
		return
	if navigation != null:
		navigation.call("sync_navigation", progression, player.global_position)
	var state := presentation_for(progression)
	if state != _presentation:
		_presentation = state
		_apply_bindings(state)
		presentation_changed.emit(state.duplicate(true))
	var nearby := false
	for p: Array in config.get("settlements", []):
		var offset := player.global_position - Vector3(float(p[0]), float(p[1]), float(p[2]))
		if Vector2(offset.x, offset.z).length() <= float(config.get("settlement_radius_m", 95)) \
				and absf(offset.y) <= float(config.get("settlement_height_tolerance_m", 25)):
			nearby = true
	_targets = mix_for(config, MAP.region_at(world_data, player.global_position), progression, _finale_active, nearby)


func _apply_bindings(state: Dictionary) -> void:
	for key: String in bindings:
		for node: Node in bindings[key]:
			if not is_instance_valid(node):
				continue
			if key == "shrine_lights" and node is Light3D:
				var id := node.get_instance_id()
				if not _light_energy.has(id):
					_light_energy[id] = node.light_energy
				node.light_energy = float(_light_energy[id]) * (float(config.get("shrine_restored_energy_multiplier", 1.35)) if state["shrine_brightened"] else 1.0)
			elif state.has(key) and node is Node3D:
				node.visible = bool(state[key])


func _build_audio() -> void:
	if not _layers.is_empty():
		return
	AUDIO.apply_all_volumes()
	for cue: Dictionary in chapter.get("audio_atmosphere", {}).get("cues", []):
		var source := str(cue.get("source", ""))
		if source.is_empty():
			continue # Bespoke bridge creak remains explicitly unavailable.
		var stream := AUDIO.stream(source)
		if stream == null:
			continue
		var role := str(cue["role"])
		var layer := AudioStreamPlayer.new()
		layer.name = str(cue["id"])
		layer.stream = stream
		layer.bus = "Music" if role == "boss_music" else "Ambience"
		layer.volume_db = -80.0
		layer.finished.connect(_replay_layer.bind(role))
		add_child(layer)
		_layers[role] = layer
		_gains[role] = 0.0


func _replay_layer(role: String) -> void:
	if float(_gains.get(role, 0.0)) > 0.001 and _layers.has(role):
		_layers[role].play()


func _process(delta: float) -> void:
	sync_progression()
	advance_mix(delta)


func advance_mix(delta: float) -> void:
	var speed := maxf(0.0, delta) / maxf(0.01, float(config.get("fade_seconds", 3.0)))
	for role: String in _layers:
		var gain := move_toward(float(_gains[role]), clampf(float(_targets.get(role, 0.0)), 0, 1), speed)
		_gains[role] = gain
		var layer: AudioStreamPlayer = _layers[role]
		if gain <= 0.001:
			layer.stop()
			layer.volume_db = -80.0
		else:
			layer.volume_db = linear_to_db(gain)
			if not layer.playing:
				layer.play()


func audio_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for role: String in _layers:
		result[role] = {"target": _targets.get(role, 0.0), "gain": _gains[role],
			"playing": _layers[role].playing, "bus": _layers[role].bus}
	return result


func _exit_tree() -> void:
	for layer: AudioStreamPlayer in _layers.values():
		layer.stop()
		layer.stream = null
	_layers.clear()

extends Node3D

## F18 waystone presentation and local touch intent. Persistence, actor binding,
## proximity/refusal checks, bool-save commit and acknowledgements belong to Game.
## There is no local unlock, save, inventory change or travel producer here.
## Mount with build(owner_world, runtime_realm). Host shells retain the positions
## for validation but never submit intents for the host's local player.

const CONFIG_PATH := "res://data/config/waystones.json"
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var waystone_id := ""
var biome := ""
var realm_id := ""
var display_name := ""
var _world: Node3D
var _config: Dictionary = {}
var _row: Dictionary = {}
var _prompt: Node3D
var _marker_material: StandardMaterial3D
var _light: OmniLight3D
var _poll_elapsed := 0.0
var _retry_elapsed := 0.0
var _pending_elapsed := 0.0
var _message_elapsed := 0.0
var _pending := false
var _pending_request_id := ""
var _touch_committed := false
var _activated := false
var _presentation_enabled := true


## One collection component mounts a child per configured stone. Before mount,
## every anchor is checked against its canonical source; changed content fails
## loudly instead of quietly keeping a stale guessed position.
func build(owner_world: Node3D, runtime_realm: String) -> void:
	if not get_children().is_empty():
		push_error("Waystones must be mounted once per world")
		return
	var config := load_config()
	if config.is_empty():
		return
	for raw: Variant in config.get("waystones", []):
		if not raw is Dictionary or str(raw.get("realm_id", "")) != runtime_realm:
			continue
		var row: Dictionary = raw
		var at := resolve_position(owner_world, row)
		if not at.is_finite():
			push_error("Waystone has no authored dry support: " + str(row.get("id", "")))
			continue
		var stone := (get_script() as Script).new() as Node3D
		stone.name = str(row.id)
		stone.set("_world", owner_world)
		stone.set("_config", config)
		stone.set("_row", row)
		stone.set("waystone_id", str(row.id))
		stone.set("biome", str(row.biome))
		stone.set("realm_id", runtime_realm)
		stone.set("display_name", str(row.display_name))
		stone.set("_presentation_enabled", owner_world.get("simulation_only") != true)
		stone.position = to_local(at)
		add_child(stone)


static func load_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1 \
			or parsed.get("scope", "") != "character" or parsed.get("authority", "") != "host" \
			or not parsed.get("waystones", null) is Array:
		push_error("Waystone configuration is malformed")
		return {}
	return parsed


## Host resolution uses this exact source-grounding path, never client positions.
## Cloudreach's preferred Y selects the correct stacked platform.
static func resolve_position(owner_world: Node3D, row: Dictionary,
		arrival: bool = false) -> Vector3:
	var invalid := Vector3(INF, INF, INF)
	if owner_world == null or not owner_world.has_method("ground_height_at"):
		return invalid
	var anchor := _source_anchor(row)
	if not anchor.is_finite():
		return invalid
	var offset: Array = row.get("offset_xz", [])
	if offset.size() != 2:
		return invalid
	var at := anchor + Vector2(float(offset[0]), float(offset[1]))
	if arrival:
		var arrive: Array = row.get("arrival_offset_xz", [])
		if arrive.size() != 2:
			return invalid
		at += Vector2(float(arrive[0]), float(arrive[1]))
	var preferred: Variant = row.get("preferred_y")
	var y := float(owner_world.call("ground_height_at", at.x, at.y, float(preferred))) \
		if preferred != null else float(owner_world.call("ground_height_at", at.x, at.y))
	if not is_finite(y):
		return invalid
	var config := load_config()
	if config.is_empty():
		return invalid
	var tuning: Dictionary = config.tuning
	if str(row.get("realm_id", "")) == "water" and y < float(tuning.water_min_height_m):
		return invalid
	# The complete shrine/arrival pad must sit on one support surface. Four
	# perimeter samples reject cliff lips and bridged gaps, without fabricated Y.
	var half_width := float(config.presentation.max_footprint_m) * 0.5
	for corner: Vector2 in [Vector2(-half_width, -half_width), Vector2(half_width, -half_width),
			Vector2(-half_width, half_width), Vector2(half_width, half_width)]:
		var p := at + corner
		var support := float(owner_world.call("ground_height_at", p.x, p.y, float(preferred))) \
			if preferred != null else float(owner_world.call("ground_height_at", p.x, p.y))
		if not is_finite(support) or absf(support - y) > float(tuning.max_support_delta_m):
			return invalid
	return Vector3(at.x, y, at.y)


static func _source_anchor(row: Dictionary) -> Vector2:
	var invalid := Vector2(INF, INF)
	var source: Dictionary = row.get("source", {})
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(source.get("path", ""))))
	if not raw is Dictionary:
		return invalid
	var collection: Variant = _nested(raw, str(source.get("collection", "")))
	if not collection is Array:
		return invalid
	for candidate: Variant in collection:
		if not candidate is Dictionary \
				or str(candidate.get(str(source.get("id_field", "id")), "")) != str(source.get("id", "")):
			continue
		var coordinates: Variant = _nested(candidate, str(source.get("coordinate_field", "")))
		if not coordinates is Array or not coordinates.size() in [2, 3]:
			return invalid
		var at := Vector2(float(coordinates[0]), float(coordinates[-1]))
		if coordinates.size() == 3 and (row.get("preferred_y") == null \
				or not is_equal_approx(float(row.preferred_y), float(coordinates[1]))):
			push_error("Waystone support height changed: " + str(row.get("id", "")))
			return invalid
		var frozen: Array = row.get("position_xz", [])
		if frozen.size() != 2 or not at.is_equal_approx(Vector2(float(frozen[0]), float(frozen[1]))):
			push_error("Waystone anchor changed: " + str(row.get("id", "")))
			return invalid
		return at
	return invalid


static func _nested(value: Dictionary, path: String) -> Variant:
	var current: Variant = value
	for field: String in path.split("."):
		if not current is Dictionary:
			return null
		current = current.get(field)
	return current


func _ready() -> void:
	if waystone_id.is_empty():
		set_process(false)
		return
	add_to_group("waystones")
	add_to_group("progression_restore")
	_retry_elapsed = float(_config.tuning.retry_interval_s)
	_message_elapsed = float(_config.tuning.message_interval_s)
	if _presentation_enabled:
		_build_visual()
	_build_prompt()
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_signal("portal_action_result"):
		game.connect("portal_action_result", _on_action_result)
	refresh_from_game()
	visible = _presentation_enabled
	set_process(_presentation_enabled)


func _build_visual() -> void:
	var spec: Dictionary = _config.presentation
	var scene := load(str(spec.model)) as PackedScene
	if scene == null:
		push_error("Waystone installed shrine model is missing: " + str(spec.model))
		return
	var model := scene.instantiate() as Node3D
	if model == null:
		push_error("Waystone shrine is not spatial")
		return
	add_child(model)
	var bounds := BOUNDS.measure(model)
	if bounds.size.y <= 0.0:
		push_error("Waystone shrine has no measurable mesh")
		model.queue_free()
		return
	var uniform := float(spec.height_m) / bounds.size.y
	if maxf(bounds.size.x, bounds.size.z) * uniform > float(spec.max_footprint_m):
		push_error("Waystone shrine exceeds authored support footprint")
		model.queue_free()
		return
	model.scale = Vector3.ONE * uniform
	model.position = Vector3(-bounds.get_center().x * uniform,
		-bounds.position.y * uniform - float(spec.sink_m), -bounds.get_center().z * uniform)
	var body := StaticBody3D.new()
	body.name = "ShrineCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = bounds.size * uniform
	collision.shape = shape
	collision.position = Vector3(0, shape.size.y * 0.5 - float(spec.sink_m), 0)
	body.add_child(collision)
	add_child(body)
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = float(spec.marker_radius_m)
	sphere.height = sphere.radius * 2.0
	marker.mesh = sphere
	marker.position.y = float(spec.marker_height_m)
	_marker_material = StandardMaterial3D.new()
	_marker_material.emission_enabled = true
	marker.material_override = _marker_material
	add_child(marker)
	_light = OmniLight3D.new()
	_light.position = marker.position
	_light.omni_range = float(spec.light_range_m)
	add_child(_light)


func _build_prompt() -> void:
	_prompt = INTERACTABLE.new()
	_prompt.name = "InspectWaystone"
	_prompt.set("label", "Inspect " + display_name)
	_prompt.set("radius", float(_config.tuning.inspect_radius_m))
	_prompt.set("enabled", _presentation_enabled)
	_prompt.position.y = float(_config.presentation.marker_height_m)
	_prompt.connect("activated", _inspect)
	add_child(_prompt)


func _process(delta: float) -> void:
	_poll_elapsed += delta
	_retry_elapsed += delta
	_message_elapsed += delta
	if _pending:
		_pending_elapsed += delta
		if _pending_elapsed >= float(_config.tuning.ack_timeout_s):
			_pending = false
			_pending_request_id = ""
	if _poll_elapsed < float(_config.tuning.poll_interval_s):
		return
	_poll_elapsed = 0.0
	var game := get_node_or_null(^"/root/Game")
	if game == null or not game.has_method("local_player") \
			or str(game.get("current_realm")) != realm_id:
		return
	var player := game.call("local_player") as Node3D
	if player == null or not is_instance_valid(player):
		return
	var touching := player.global_position.distance_to(global_position) <= float(_config.tuning.touch_radius_m)
	if not touching:
		_touch_committed = false
		return
	if _pending or _touch_committed or _retry_elapsed < float(_config.tuning.retry_interval_s):
		return
	if not game.has_method("request_portal_action"):
		return
	_pending = true
	_pending_request_id = ""
	_pending_elapsed = 0.0
	_retry_elapsed = 0.0
	var queued: Variant = game.call("request_portal_action", {"kind": "waystone_touch", "waystone_id": waystone_id})
	if not queued is Dictionary or not bool(queued.get("ok", false)):
		_pending = false
		_message(str(queued.get("reason", "Waystone could not be confirmed.")) if queued is Dictionary \
			else "Waystone could not be confirmed.")
	elif _pending:
		_pending_request_id = str(queued.get("request_id", ""))
		if _pending_request_id.is_empty():
			_pending = false
			_message("Waystone could not confirm its request identity.")


func _on_action_result(result: Dictionary) -> void:
	# The request id is this stone's own, unique per send. Host and guest
	# refusals do not echo the stone id, so it is checked only when present;
	# otherwise a refusal would hold the stone silent until ack_timeout_s.
	var echoed := str(result.get("waystone_id", result.get("id", "")))
	if not _pending or str(result.get("kind", "")) != "waystone_touch" \
			or (not echoed.is_empty() and echoed != waystone_id):
		return
	if _pending_request_id.is_empty() \
			or str(result.get("request_id", "")) != _pending_request_id:
		return
	# Game publishes only the bound requesting character's acknowledgement to
	# this peer. Never accept a remote character's visual state as our unlock.
	var state := _character_state()
	if str(result.get("character_id", "")).is_empty() \
			or str(result.character_id) != str(state.get("character_id", "")):
		return
	_pending = false
	_pending_request_id = ""
	if not bool(result.get("ok", false)):
		print("[waystone] %s touch refused: %s %s" % [waystone_id, str(result.get("reason", "")), str(result.get("code", ""))])
		_message(str(result.get("reason", "Waystone could not be saved. Touch it again.")))
		return
	_touch_committed = true
	refresh_from_game()
	_message("Waystone awakened: " + display_name if bool(result.get("first_activation", false)) \
		else "Return point: " + display_name)


func _character_state() -> Dictionary:
	var game := get_node_or_null(^"/root/Game")
	if game == null or not game.has_method("portal_character_state"):
		return {}
	var result: Variant = game.call("portal_character_state")
	return result if result is Dictionary else {}


func refresh_from_game() -> void:
	var state := _character_state()
	var activated: Dictionary = state.get("waystones_activated", {})
	var stones: Array = activated.get(biome, [])
	_activated = stones.has(waystone_id)
	if _marker_material == null:
		return
	var spec: Dictionary = _config.presentation
	var colour := Color(str(spec.active_colour if _activated else spec.inactive_colour))
	_marker_material.albedo_color = colour
	_marker_material.emission = colour
	_marker_material.emission_energy_multiplier = float(spec.active_energy if _activated else spec.inactive_energy)
	_light.light_color = colour
	_light.light_energy = float(spec.light_energy) if _activated else 0.0


func _inspect() -> void:
	_message(display_name + ": Portals from the Hall bring you here.", true)


func _message(text: String, force: bool = false) -> void:
	if text.is_empty() or (not force and _message_elapsed < float(_config.tuning.message_interval_s)):
		return
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", text)
		_message_elapsed = 0.0

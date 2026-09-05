extends Node3D

## Summit encounter environment. Canonical ProgressionState is the only durable
## store. Combat owns team/HP/win detection; the chapter adapter owns rewards.
## Call apply_hazards AFTER locomotion chooses velocity and BEFORE move_and_slide.
## No automatic body movement, human attack, roster or second save payload here.
signal phase_changed(phase: String)
signal captain_defeated()
signal relay_disabled(relay_id: String)
signal network_disabled()
signal aftermath_restored()
signal presentation_changed(state: Dictionary)
signal recovery_requested(body: CharacterBody3D, camp_id: String, safe_position: Vector3)

const CONFIG_PATH := "res://data/config/cloudreach_finale.json"
const INTERACTABLE := preload("res://scripts/world/interactable.gd")

var config: Dictionary = {}
var phase := "dormant"
var elapsed := 0.0
var _progression: RefCounted
var _chapter_event: Callable
var _controlled_body: Callable
var _creature_piloted: Callable
var _recovery_handoff: Callable
var _revision := -1
var _in_encounter := false
var _overload := false
var _presentation: Dictionary = {}
var _prompts: Dictionary = {}
var _pending_recoveries: Dictionary = {}
var _hazard_drift: Dictionary = {}


static func read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}


## body_source returns the currently piloted CharacterBody (it can switch).
## creature_source returns whether it is a creature, so a human cannot strike.
## recover(body, camp_id, world_position) owns combat exit/Fly exit/camp placement.
func setup(progression: RefCounted, event_adapter: Callable, body_source: Callable,
		creature_source: Callable, recover: Callable = Callable(), data: Dictionary = {}) -> void:
	_progression = progression
	_chapter_event = event_adapter
	_controlled_body = body_source
	_creature_piloted = creature_source
	_recovery_handoff = recover
	config = read_config() if data.is_empty() else data.duplicate(true)
	position = vec(config.get("arena_origin", []))
	_in_encounter = false
	_overload = false
	elapsed = 0.0
	_pending_recoveries.clear()
	_hazard_drift.clear()
	_revision = -1
	sync_progression()
	if is_inside_tree():
		build_interactions()


func _ready() -> void:
	add_to_group("progression_restore")
	if not config.is_empty():
		build_interactions()


func _process(delta: float) -> void:
	if _progression == null:
		return
	if int(_progression.get("revision")) != _revision:
		sync_progression()
	elapsed += delta
	_sync_prompt_access()


func restore_progression_from_game(game: Node) -> void:
	_progression = game.get("progression")
	_in_encounter = false
	_overload = false
	elapsed = 0.0
	_pending_recoveries.clear()
	_hazard_drift.clear()
	_revision = -1
	sync_progression()


func _has(flag: String) -> bool:
	return _progression != null and bool(_progression.call("has", flag))


func _prerequisites() -> bool:
	for flag: String in config.get("requires_flags", []):
		if not _has(flag):
			return false
	return not config.is_empty()


func _event(event: String) -> bool:
	if not _chapter_event.is_valid():
		return false
	var result: Variant = _chapter_event.call(event)
	return result is Dictionary and bool(result.get("accepted", false))


## Connect from the production encounter start; rejects wrong encounters/order.
func encounter_started(encounter_id: String) -> bool:
	if encounter_id != str(config.get("encounter_id", "")) or not _prerequisites() \
			or _has(str(config["captain_victory_flag"])):
		return false
	if _in_encounter:
		return false
	_in_encounter = true
	_overload = false
	elapsed = 0.0
	sync_progression()
	return true


## Combat reports the ACTUAL surviving opposition count; no HP multiplier.
func opposition_remaining(encounter_id: String, remaining: int, initial: int) -> void:
	if not _in_encounter or encounter_id != str(config.get("encounter_id", "")):
		return
	if initial > 0 and remaining > 0 and remaining <= initial / 2.0 and not _overload:
		_overload = true
		elapsed = 0.0
		sync_progression()


## Wire ONLY to the production captain-victory callback, never a dialogue effect.
## Zero opposition count alone deliberately cannot manufacture the win.
func encounter_won(encounter_id: String) -> bool:
	if not _in_encounter or encounter_id != str(config.get("encounter_id", "")) \
			or not _prerequisites() or _has(str(config["captain_victory_flag"])):
		return false
	if not _event(str(config["captain_victory_event"])) or not _has(str(config["captain_victory_flag"])):
		return false
	_in_encounter = false
	elapsed = 0.0
	sync_progression()
	captain_defeated.emit()
	return true


func encounter_lost(encounter_id: String, body: CharacterBody3D) -> bool:
	if not _in_encounter or encounter_id != str(config.get("encounter_id", "")):
		return false
	_in_encounter = false
	_overload = false
	sync_progression()
	_request_recovery(body)
	return true


func sync_progression() -> void:
	if _progression == null or config.is_empty():
		return
	# Safe repair after a save between the third relay write and aggregate event.
	if _has(str(config["captain_victory_flag"])) and _all_relays_disabled() \
			and not _has(str(config["network_flag"])):
		_event(str(config["network_event"]))
	var next := "dormant"
	if _has(str(config["aftermath_flag"])):
		next = "restored"
	elif _has(str(config["network_flag"])):
		next = "awaiting_restoration"
	elif _has(str(config["captain_victory_flag"])):
		next = "break_the_eye"
	elif _in_encounter:
		next = "anchor_overload" if _overload else "crosswind_command"
	if next != phase:
		phase = next
		phase_changed.emit(phase)
	_revision = int(_progression.get("revision"))
	_sync_prompt_access()
	var state := presentation_state()
	if state != _presentation:
		_presentation = state.duplicate(true)
		presentation_changed.emit(state)


func presentation_state() -> Dictionary:
	var relays: Dictionary = {}
	for relay: Dictionary in config.get("relays", []):
		relays[str(relay["id"])] = _has(str(relay["flag_id"])) or _has(str(config["network_flag"]))
	var freed := _has(str(config.get("aftermath_flag", "")))
	return {"phase": phase, "relays_disabled": relays,
		"hazards_active": phase in ["crosswind_command", "anchor_overload", "break_the_eye"],
		"anchor_drone_active": not _has(str(config.get("network_flag", ""))),
		"natural_wind_trails": freed, "travelers_reconnected": freed,
		"restored_route_currents": freed, "waterward_visible": _has("waterward_route_revealed")}


func build_interactions() -> void:
	if not _prompts.is_empty():
		return
	for relay: Dictionary in config.get("relays", []):
		var prompt := INTERACTABLE.new()
		prompt.name = "Relay_" + str(relay["id"])
		prompt.position = vec(relay["offset"]) + Vector3.UP
		prompt.configure("Strike the exposed %s relay" % relay["id"],
			float(config["relay_interaction_radius_m"]), false)
		prompt.activated.connect(_activate_relay.bind(str(relay["id"])))
		add_child(prompt)
		_prompts[str(relay["id"])] = prompt
	_sync_prompt_access()


func _sync_prompt_access() -> void:
	var piloted := _creature_piloted.is_valid() and bool(_creature_piloted.call())
	for relay: Dictionary in config.get("relays", []):
		var id := str(relay["id"])
		if _prompts.has(id):
			_prompts[id].set_enabled(phase == "break_the_eye" and piloted and not _has(str(relay["flag_id"])))


func _activate_relay(id: String) -> void:
	if not _controlled_body.is_valid():
		return
	strike_relay(id, _controlled_body.call() as CharacterBody3D)


## Public for a production creature hit adapter as well as the shared prompt.
## Validate actor, range, vertical access and sight AGAIN at action time.
func strike_relay(id: String, body: CharacterBody3D) -> bool:
	if not is_inside_tree() or phase != "break_the_eye" or not _has(str(config["captain_victory_flag"])) \
			or not _prerequisites() or not is_instance_valid(body) \
			or not _controlled_body.is_valid() or _controlled_body.call() != body \
			or not _creature_piloted.is_valid() or not bool(_creature_piloted.call()):
		return false
	for relay: Dictionary in config.get("relays", []):
		if str(relay["id"]) != id or _has(str(relay["flag_id"])):
			continue
		var target := _origin() + vec(relay["offset"]) + Vector3.UP
		if body.global_position.distance_to(target) > float(config["relay_interaction_radius_m"]):
			return false
		if _prompts.has(id) and _prompts[id].interaction_offer(body.global_position).is_empty():
			return false
		var network_was_disabled := _has(str(config["network_flag"]))
		_progression.call("set_flag", str(relay["flag_id"]))
		sync_progression()
		relay_disabled.emit(id)
		if not network_was_disabled and _has(str(config["network_flag"])):
			network_disabled.emit()
		return true
	return false


func _all_relays_disabled() -> bool:
	var relays: Array = config.get("relays", [])
	if relays.size() != 3:
		return false
	for relay: Dictionary in relays:
		if not _has(str(relay["flag_id"])):
			return false
	return true


## Call on physical arrival at the delegation's overlook. Reward dialogue is a
## separate chapter event: witnessing restoration never grants the Heart/key.
func witness_restoration(body: CharacterBody3D) -> bool:
	if not is_instance_valid(body) or not _controlled_body.is_valid() \
			or _controlled_body.call() != body or not _has(str(config["network_flag"])) \
			or _has(str(config["aftermath_flag"])):
		return false
	var witness: Dictionary = config["aftermath_witness"]
	var offset := body.global_position - vec(witness["position"])
	if Vector2(offset.x, offset.z).length() > float(witness["radius_m"]) \
			or absf(offset.y) > float(witness["height_tolerance_m"]):
		return false
	if not _event(str(config["aftermath_event"])) or not _has(str(config["aftermath_flag"])):
		return false
	sync_progression()
	aftermath_restored.emit()
	return true


func _origin() -> Vector3:
	return global_position if is_inside_tree() else position


static func vec(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2])) if raw.size() == 3 else Vector3.ZERO


static func cycle_stage(at: float, spec: Dictionary) -> String:
	var cycle := maxf(0.1, float(spec["cycle_seconds"]))
	var cursor := fposmod(at, cycle)
	if cursor < float(spec["telegraph_seconds"]):
		return "telegraph"
	return "recovery" if cursor >= cycle - float(spec["recovery_window_seconds"]) else "active"


## Renderer and movement consume the SAME field sample/timer. A lee pocket is
## safe at every rotation; arena height checks exclude stacked lower paths.
func hazard_at(world_position: Vector3, at: float = -1.0) -> Dictionary:
	var result := {"wind": Vector3.ZERO, "arc": Vector3.ZERO, "sheltered": false,
		"wind_stage": "idle", "arc_stage": "idle"}
	if phase not in ["crosswind_command", "anchor_overload", "break_the_eye"]:
		return result
	var local := world_position - _origin()
	var point := Vector2(local.x, local.z)
	if point.length() > float(config["arena_radius_m"]) \
			or absf(local.y) > float(config["arena_height_tolerance_m"]):
		return result
	for lee: Dictionary in config["lee_pockets"]:
		var centre := vec(lee["offset"])
		if point.distance_to(Vector2(centre.x, centre.z)) <= float(lee["radius_m"]):
			result["sheltered"] = true
			return result
	var t := elapsed if at < 0.0 else at
	var wind: Dictionary = config["wind"]
	var angle := deg_to_rad(t * float(wind["rotation_degrees_per_second"]))
	var normal := Vector2(cos(angle), sin(angle))
	var along := Vector2(-normal.y, normal.x)
	result["wind_stage"] = cycle_stage(t, wind)
	for offset: float in wind["lane_offsets_m"]:
		if absf(point.dot(normal) - offset) <= float(wind["lane_half_width_m"]) \
				and result["wind_stage"] == "active":
			result["wind"] = Vector3(along.x, 0, along.y) * float(wind["acceleration_mps2"])
	if phase == "crosswind_command":
		return result
	var arc: Dictionary = config["relay_arc"]
	result["arc_stage"] = cycle_stage(t, arc)
	if result["arc_stage"] != "active" or point.length() < float(arc["inner_radius_m"]) \
			or point.length() > float(arc["outer_radius_m"]):
		return result
	var rotation := deg_to_rad(t * float(arc["rotation_degrees_per_second"]))
	for sector in range(3):
		var difference := wrapf(point.angle() - rotation - sector * TAU / 3.0, -PI, PI)
		if absf(difference) <= deg_to_rad(float(arc["sector_half_angle_degrees"])):
			var inward := -point.normalized() * float(arc["repulsion_acceleration_mps2"])
			result["arc"] = Vector3(inward.x, 0, inward.y)
	return result


## CharacterBody remains collision owner. The caller supplies its chosen
## locomotion velocity each frame, BEFORE this function adds external drift.
## Drift is transient, bounded and decays promptly on entering a lee pocket.
## Never calls move_and_slide twice or reuses pre-collision airborne positions.
func apply_hazards(body: CharacterBody3D, delta: float) -> Dictionary:
	if not is_instance_valid(body) or delta <= 0.0 or config.is_empty():
		return {}
	var sample := hazard_at(body.global_position)
	var wind: Vector3 = sample["wind"]
	var arc: Vector3 = sample["arc"]
	var drift: Vector3 = _hazard_drift.get(body.get_instance_id(), Vector3.ZERO)
	var force := wind + arc
	if force.is_zero_approx():
		drift = drift.move_toward(Vector3.ZERO, 30.0 * delta)
	else:
		var limit := float(config["relay_arc"]["max_push_speed_mps"]) if not arc.is_zero_approx() \
			else float(config["wind"]["max_push_speed_mps"])
		drift = (drift + force * delta).limit_length(limit)
	_hazard_drift[body.get_instance_id()] = drift
	body.velocity += drift
	_apply_recovery_current(body)
	return sample


func _apply_recovery_current(body: CharacterBody3D) -> void:
	# Recovery remains usable after the engine is disabled, including restored play.
	if phase == "dormant":
		return
	var local := body.global_position - _origin()
	var recovery: Dictionary = config["recovery"]
	var id := body.get_instance_id()
	if local.y > -float(recovery["current_below_deck_m"]):
		_pending_recoveries.erase(id)
		return
	if Vector2(local.x, local.z).length() > float(recovery["current_radius_m"]):
		return
	if local.y < -float(recovery["handoff_below_deck_m"]):
		_request_recovery(body)
		return
	var inward := -Vector3(local.x, 0, local.z).normalized()
	body.velocity = inward * float(recovery["inward_speed_mps"]) \
		+ Vector3.UP * float(recovery["lift_speed_mps"])


func _request_recovery(body: CharacterBody3D) -> void:
	if not is_instance_valid(body) or _pending_recoveries.has(body.get_instance_id()):
		return
	_pending_recoveries[body.get_instance_id()] = true
	_hazard_drift.erase(body.get_instance_id())
	var recovery: Dictionary = config["recovery"]
	var camp_id := str(recovery["safe_camp_id"])
	var safe := vec(recovery["safe_position"])
	recovery_requested.emit(body, camp_id, safe)
	if _recovery_handoff.is_valid():
		_recovery_handoff.call(body, camp_id, safe)

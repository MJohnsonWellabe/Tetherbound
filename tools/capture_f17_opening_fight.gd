extends "res://tests/smoke_four_biome_continuous.gd"

## Native presentation witness of the genuine fresh title/starter/tutorial
## catch. The inherited ordinary-input driver owns gameplay; this observer
## only saves actual frames/state. No staged party, pose, HP, fight outcome,
## direct purchase, collision removal or artificial keep-alive.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const MOVE_LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
var _fight_output := ""
var _fight_source := ""
var _fight_preset := ""
var _observer: FightObserver
var _ending_fight_capture := false

class FightObserver extends Node:
	var output := ""
	var preset := ""
	# Frozen from the validated startup window; never resize a window or image.
	var expected_resolution := Vector2i.ZERO
	var rows: Array[Dictionary] = []
	var began_ms := -1
	var next_ms := 0
	var saving := false
	var failure := ""
	var live_frames := 0
	var retain_sample: Callable
	# Optional, process-local presentation preview. No gameplay or saved config
	# changes; the default observer and its inherited input driver stay intact.
	var prove_library_arrival := false
	var arrival_records: Dictionary = {}
	var arrival_errors: Array[String] = []
	var uncorrelated_impacts: Array[Dictionary] = []
	var pending_contacts := 0
	var _manager: Node
	var _hud: Node
	var _event_sequence := 0
	var _preview_active := false
	var _saved_enabled := false
	var _saved_enabled_present := false
	var _closed := false

	func begin_preview() -> void:
		if not prove_library_arrival: return
		_saved_enabled_present = MOVE_LIBRARY.config().has("enabled")
		_saved_enabled = bool(MOVE_LIBRARY.config().get("enabled", false))
		MOVE_LIBRARY.config()["enabled"] = true
		_preview_active = true

	func close_observation() -> void:
		_closed = true
		_disconnect_manager()
		if _preview_active:
			if _saved_enabled_present: MOVE_LIBRARY.config()["enabled"] = _saved_enabled
			else: MOVE_LIBRARY.config().erase("enabled")
			_preview_active = false

	func _exit_tree() -> void:
		close_observation()

	func _process(_delta: float) -> void:
		if _closed: return
		if prove_library_arrival: _observe_arrivals()
		if saving or not failure.is_empty(): return
		var world := get_tree().current_scene
		var manager: Node = world.get_node_or_null("CombatManager") if world != null else null
		var live := manager != null and int(manager.get("state")) == COMBAT.State.ACTIVE
		if began_ms < 0 and not live: return
		if began_ms >= 0 and Time.get_ticks_msec() - began_ms >= 30000: return
		if Time.get_ticks_msec() >= next_ms:
			saving = true
			await _save()
			saving = false

	func _save() -> void:
		await RenderingServer.frame_post_draw
		var at := Time.get_ticks_msec()
		var world := get_tree().current_scene
		var manager: Node = world.get_node_or_null("CombatManager") if world != null else null
		var director: Node = world.get_node_or_null("EncounterDirector") if world != null else null
		var state := int(manager.get("state")) if manager != null else COMBAT.State.INACTIVE
		var live := state == COMBAT.State.ACTIVE
		if began_ms < 0 and not live:
			# State may have changed between idle and draw; never relabel it.
			next_ms = at + 100
			return
		var actual_preset := GRAPHICS.selected()
		var renderer := RenderingServer.get_current_rendering_method()
		if actual_preset != preset or renderer != ("gl_compatibility" if preset == "Low" else "forward_plus"):
			failure = "actual graphics preset/renderer drifted during earned fight capture"
			return
		var active: RefCounted = manager.call("active_creature") if live else null
		var enemy: RefCounted = manager.call("enemy") if live else null
		if live and (active == null or enemy == null or float(active.get("hp")) <= 0.0 \
				or float(enemy.get("hp")) <= 0.0 or bool(active.get("fainted")) or bool(enemy.get("fainted"))):
			# An ACTIVE transition with a fainted actor is aftermath, not a live sample.
			next_ms = at + 100
			return
		var pixels := get_viewport().get_texture().get_image()
		if pixels == null or pixels.is_empty() or pixels.get_size() != expected_resolution \
				or DisplayServer.window_get_size() != expected_resolution:
			failure = "native fight image/window missing or changed from %dx%d" % [expected_resolution.x, expected_resolution.y]
			return
		var camera := get_viewport().get_camera_3d()
		var ally := director.call("ally_body") as Node3D if director != null else null
		var foe := manager.call("enemy_body") as Node3D if live else null
		if camera == null or (live and (not is_instance_valid(ally) or not is_instance_valid(foe))):
			failure = "actual live fight camera/creature bodies missing"
			return
		var image_name := "%04d-earned-opening-%s.jpg" % [rows.size(), preset.to_lower()]
		if pixels.save_jpg(output.path_join(image_name), .95) != OK:
			failure = "could not save native fight frame"
			return
		var still_name := ""
		if live and live_frames == 0:
			still_name = "first-actual-live-fight-" + preset.to_lower() + ".png"
			if pixels.save_png(output.path_join(still_name)) != OK:
				failure = "could not retain first actual live fight PNG"
				return
		if began_ms < 0: began_ms = at
		if live: live_frames += 1
		rows.append({"image": image_name, "still_png": still_name, "elapsed_ms": at, "motion_sample": true,
			"resolution": [pixels.get_width(), pixels.get_height()],
			"label": "earned opening fight and ordinary aftermath", "preset": actual_preset,
			"renderer": renderer, "graphics_values": GRAPHICS.values(), "combat_state": state,
			"time_of_day": _world_value(world, "WorldLook", "time_of_day"),
			"weather": _world_value(world, "WorldWeather", "weather"),
			"live_fight": live, "physics_frame": Engine.get_physics_frames(),
			"camera": _xyz(camera.global_position),
			"camera_basis": [_xyz(camera.global_basis.x), _xyz(camera.global_basis.y), _xyz(camera.global_basis.z)],
			"ally_body": _body(ally), "enemy_body": _body(foe),
			"ally": _creature(active), "enemy": _creature(enemy)})
		next_ms = at + 100
		if not retain_sample.call():
			failure = "could not retain incomplete earned fight manifest"

	func _observe_arrivals() -> void:
		var world := get_tree().current_scene
		var manager: Node = world.get_node_or_null("CombatManager") if world != null else null
		var hud: Node = world.get_node_or_null("CombatHUD") if world != null else null
		if is_instance_valid(manager) and manager.is_node_ready() and is_instance_valid(hud) and hud.is_node_ready() and manager != _manager:
			_disconnect_manager()
			_manager = manager
			_hud = hud
			_manager.connect("attack_launched", _on_launch)
			_manager.connect("impact_confirmed", _on_impact)
		for action_id: String in arrival_records:
			var row: Dictionary = arrival_records[action_id]
			if not row.has("contact") and row.errors.is_empty():
				_check_before_contact(action_id)

	func _disconnect_manager() -> void:
		if not is_instance_valid(_manager): return
		if _manager.is_connected("attack_launched", _on_launch): _manager.disconnect("attack_launched", _on_launch)
		if _manager.is_connected("impact_confirmed", _on_impact): _manager.disconnect("impact_confirmed", _on_impact)

	func _stamp() -> Dictionary:
		_event_sequence += 1
		return {"elapsed_ms": Time.get_ticks_msec(), "process_frame": Engine.get_process_frames(),
			"physics_frame": Engine.get_physics_frames(), "event_sequence": _event_sequence,
			"combat_state": int(_manager.get("state")) if is_instance_valid(_manager) else COMBAT.State.INACTIVE}

	func _arrival_error(action_id: String, reason: String) -> void:
		var message := action_id + ": " + reason
		if not arrival_errors.has(message): arrival_errors.append(message)
		if arrival_records.has(action_id) and not arrival_records[action_id].errors.has(reason):
			arrival_records[action_id].errors.append(reason)

	func _retain_arrivals() -> void:
		if not retain_sample.call(): failure = "could not retain incomplete arrival manifest"

	func _identity_matches(row: Dictionary, allow_terminal: bool = false) -> bool:
		var world := get_tree().current_scene
		if not is_instance_valid(_manager) or not is_instance_valid(_hud) or world == null \
				or _manager.is_queued_for_deletion() or _hud.is_queued_for_deletion() \
				or world.get_node_or_null("CombatManager") != _manager or world.get_node_or_null("CombatHUD") != _hud \
				or _manager.get_instance_id() != int(row.manager_instance_id) \
				or str(_manager.get("_encounter_id")) != str(row.encounter_id): return false
		var target: RefCounted = _manager.call("enemy")
		var actor: RefCounted = _manager.call("active_creature")
		var body: Node3D = _manager.call("enemy_body")
		if target == null or actor == null or not is_instance_valid(body) \
				or not body.is_inside_tree() or body.is_queued_for_deletion() \
				or target.get_instance_id() != int(row.target_instance_id) or body.get_instance_id() != int(row.target_body_instance_id) \
				or actor.get_instance_id() != int(row.actor_instance_id) \
				or str(target.get("uid")) != str(row.target_uid) or str(actor.get("uid")) != str(row.attacker_uid): return false
		var director: Node = world.get_node_or_null("EncounterDirector")
		if not is_instance_valid(director) or director.is_queued_for_deletion() \
				or director.get_instance_id() != int(row.director_instance_id): return false
		var actor_body := director.call("ally_body") as Node3D
		if not is_instance_valid(actor_body) or not actor_body.is_inside_tree() or actor_body.is_queued_for_deletion() \
				or actor_body.get_instance_id() != int(row.actor_body_instance_id) or _manager.get("_ally_body") != actor_body: return false
		# UID/body reuse after switching cannot revive an old launch. This read
		# consults Director's current authoritative deployment generation.
		var current: Dictionary = director.call("presentation_move_actor", row.admitted_launch, actor_body)
		row["latest_actor_binding"] = current.duplicate(true)
		if current.is_empty() or current != row.birth_actor_binding: return false
		for key: String in ["character_id", "creature_uid", "encounter_id", "generation", "action"]:
			if current.get(key) != row.accepted_actor_binding.get(key): return false
		var state := int(_manager.get("state"))
		if state == COMBAT.State.ACTIVE: return true
		# The normal victory beat retains both bodies. Admit its first draw only
		# for this observed lethal receipt, with every lifetime check above intact.
		return allow_terminal and state == COMBAT.State.RESOLVING and str(_manager.get("_outcome")) == "won" \
			and row.has("contact") and bool(row.get("receipt", {}).get("killed", false)) \
			and float(target.get("hp")) <= 0.0 and bool(target.get("fainted"))

	func _matching_numbers(action_id: String) -> Array[Dictionary]:
		var found: Array[Dictionary] = []
		if not is_instance_valid(_hud): return found
		for number: Label in _hud.get("_damage_numbers"):
			if not is_instance_valid(number) or number.is_queued_for_deletion(): continue
			var receipt: Dictionary = number.get_meta("receipt", {})
			if str(receipt.get("action_id", "")) == action_id:
				found.append({"receipt": receipt.duplicate(true), "text": number.text,
					"visible": number.is_visible_in_tree(), "born_ms": int(number.get_meta("born_ms", -1)),
					"position": [number.global_position.x, number.global_position.y]})
		return found

	func _on_launch(on_enemy: bool, launch: Dictionary, presentation: Node3D) -> void:
		if _closed or not on_enemy or str(launch.get("slot", "")) == "ultimate": return
		var action_id := str(launch.get("action_id", ""))
		if action_id.is_empty() or arrival_records.has(action_id):
			_arrival_error(action_id, "empty or duplicate admitted launch identity")
			_retain_arrivals()
			return
		var target: RefCounted = _manager.call("enemy")
		var body: Node3D = _manager.call("enemy_body")
		var actor: RefCounted = _manager.call("active_creature")
		var world := get_tree().current_scene
		var director: Node = world.get_node_or_null("EncounterDirector") if world != null else null
		var actor_body := director.call("ally_body") as Node3D if is_instance_valid(director) else null
		var birth: Dictionary = director.call("presentation_move_actor", launch, actor_body) if is_instance_valid(director) and is_instance_valid(actor_body) else {}
		var row := {"action_id": action_id, "encounter_id": str(launch.get("encounter_id", "")),
			"attacker_uid": str(launch.get("attacker_uid", "")), "target_uid": str(launch.get("target_uid", "")),
			"move_id": str(launch.get("move_id", "")), "slot": str(launch.get("slot", "")),
			"mastery_rank": int(launch.get("mastery_rank", 1)), "body_generation": int(launch.get("body_generation", -1)),
			"archetype": str(launch.get("move", {}).get("vfx", {}).get("archetype", "")),
			"travel_seconds": float(launch.get("travel_seconds", -1.0)), "launch": _stamp(),
			"manager_instance_id": _manager.get_instance_id(),
			"director_instance_id": director.get_instance_id() if is_instance_valid(director) else 0,
			"actor_instance_id": actor.get_instance_id() if actor != null else 0,
			"actor_body_instance_id": actor_body.get_instance_id() if is_instance_valid(actor_body) else 0,
			"target_instance_id": target.get_instance_id() if target != null else 0,
			"target_body_instance_id": body.get_instance_id() if is_instance_valid(body) else 0,
			"presentation_instance_id": presentation.get_instance_id() if is_instance_valid(presentation) else 0,
			"hp_at_launch": float(target.get("hp")) if target != null else -1.0,
			"accepted_actor_binding": launch.get("move", {}).get("actor_binding", {}).duplicate(true),
			"admitted_launch": launch.duplicate(true), "birth_actor_binding": birth.duplicate(true),
			"pre_arrival_checks": [], "errors": [], "visual_verdict": "unjudged"}
		arrival_records[action_id] = row
		if row.encounter_id.is_empty() or row.target_uid.is_empty() or row.attacker_uid.is_empty() \
				or not _identity_matches(row):
			_arrival_error(action_id, "launch does not identify the current admitted encounter, actor and target")
		if not is_instance_valid(presentation) or presentation.get_script() != MOVE_LIBRARY.EFFECT \
				or not presentation.is_in_group("move_effect_presentation") \
				or not presentation.has_method("action_id") or str(presentation.call("action_id")) != action_id \
				or not presentation.has_method("encounter_id") or str(presentation.call("encounter_id")) != str(row.encounter_id) \
				or not presentation.has_signal("arrived"):
			_arrival_error(action_id, "matching library presentation was not mounted")
		else:
			var context: Dictionary = presentation.get("_context")
			row["presentation_context"] = context.duplicate(true)
			for key: String in ["action_id", "encounter_id", "attacker_uid", "target_uid", "move_id", "mastery_rank", "body_generation"]:
				if context.get(key) != row.get(key): _arrival_error(action_id, "presentation identity mismatch: " + key)
			if row.accepted_actor_binding.is_empty() or context.get("actor_binding") != row.accepted_actor_binding:
				_arrival_error(action_id, "presentation lacks the same accepted actor binding")
			presentation.connect("arrived", _on_arrived.bind(action_id), CONNECT_ONE_SHOT)
		_check_before_contact(action_id)
		_retain_arrivals()

	func _check_before_contact(action_id: String) -> void:
		var row: Dictionary = arrival_records[action_id]
		if not _identity_matches(row):
			_arrival_error(action_id, "target or encounter became stale before contact")
			return
		var presentation := instance_from_id(int(row.presentation_instance_id)) as Node3D
		if not is_instance_valid(presentation) or presentation.is_queued_for_deletion():
			_arrival_error(action_id, "presentation disappeared before contact")
			return
		var target: RefCounted = _manager.call("enemy")
		var check := _stamp()
		check["hp"] = float(target.get("hp"))
		check["actor_binding"] = row.latest_actor_binding.duplicate(true)
		check["matching_hud_numbers"] = _matching_numbers(action_id)
		row.pre_arrival_checks.append(check)
		if not is_equal_approx(float(check.hp), float(row.hp_at_launch)):
			_arrival_error(action_id, "target HP changed before contact; intervening damage cannot prove this launch")
		if not check.matching_hud_numbers.is_empty():
			_arrival_error(action_id, "matching HUD number preceded effect contact")

	func _on_arrived(action_id: String) -> void:
		if _closed: return
		var row: Dictionary = arrival_records[action_id]
		_check_before_contact(action_id)
		row["contact"] = _stamp()
		var presentation := instance_from_id(int(row.presentation_instance_id)) as Node3D
		var impact: Node3D = presentation.get("_impact") if is_instance_valid(presentation) and presentation.get_script() == MOVE_LIBRARY.EFFECT else null
		row["contact_geometry_visible"] = is_instance_valid(impact) and impact.is_visible_in_tree()
		if not row.contact_geometry_visible: _arrival_error(action_id, "contact geometry absent at arrived signal")
		if _identity_matches(row):
			var target: RefCounted = _manager.call("enemy")
			row["hp_at_contact"] = float(target.get("hp"))
			row["contact_actor_binding"] = row.latest_actor_binding.duplicate(true)
		_retain_arrivals()
		_capture_contact(action_id)

	func _on_impact(on_enemy: bool, receipt: Dictionary, _where: Vector3) -> void:
		if _closed or not on_enemy or str(receipt.get("slot", "")) == "ultimate": return
		var action_id := str(receipt.get("action_id", ""))
		if not arrival_records.has(action_id):
			uncorrelated_impacts.append({"observed": _stamp(), "receipt": receipt.duplicate(true)})
			_arrival_error(action_id, "impact has no observed launch; prior/unrelated hits earn no credit")
			_retain_arrivals()
			return
		var row: Dictionary = arrival_records[action_id]
		if row.has("impact"): _arrival_error(action_id, "duplicate impact receipt")
		row["impact"] = _stamp()
		row["receipt"] = receipt.duplicate(true)
		if not row.has("contact"): _arrival_error(action_id, "impact receipt preceded matching effect contact")
		for key: String in ["action_id", "move_id", "target_uid", "slot", "mastery_rank"]:
			if receipt.get(key) != row.get(key): _arrival_error(action_id, "impact identity mismatch: " + key)
		if receipt.has("encounter_id") and receipt.encounter_id != row.encounter_id:
			_arrival_error(action_id, "impact encounter mismatch")
		if not _identity_matches(row, true):
			_arrival_error(action_id, "impact target or encounter is stale")
		else:
			var target: RefCounted = _manager.call("enemy")
			row["impact_actor_binding"] = row.latest_actor_binding.duplicate(true)
			row["hp_after_impact"] = float(target.get("hp"))
			var damage := float(receipt.get("damage", 0.0))
			row["hp_debit"] = float(row.get("hp_at_contact", -1.0)) - float(row.hp_after_impact)
			row["expected_hp_debit"] = minf(damage, float(row.get("hp_at_contact", -1.0)))
			if not row.has("hp_at_contact") or damage <= 0.0 \
					or float(row.hp_debit) <= 0.0 or not is_equal_approx(float(row.hp_debit), float(row.expected_hp_debit)):
				_arrival_error(action_id, "target HP debit does not match this positive impact receipt")
		_retain_arrivals()

	func _capture_contact(action_id: String) -> void:
		pending_contacts += 1
		await RenderingServer.frame_post_draw
		if _closed:
			pending_contacts -= 1
			return
		var row: Dictionary = arrival_records[action_id]
		row["contact_draw"] = _stamp()
		row["matching_hud_numbers"] = _matching_numbers(action_id)
		var numbers: Array = row.matching_hud_numbers
		if numbers.size() != 1 or not bool(numbers[0].visible):
			_arrival_error(action_id, "first contact draw lacks one visible matching HUD number")
		elif not row.has("receipt") or numbers[0].receipt.get("target_uid") != row.target_uid \
				or numbers[0].receipt.get("move_id") != row.move_id \
				or not is_equal_approx(float(numbers[0].receipt.get("applied_damage", -1.0)), float(row.receipt.get("damage", 0.0))):
			_arrival_error(action_id, "contact HUD receipt is merged, mismatched or uncorrelated")
		if not _identity_matches(row, true): _arrival_error(action_id, "contact draw no longer has the same actor deployment, target and encounter")
		else: row["contact_draw_actor_binding"] = row.latest_actor_binding.duplicate(true)
		var camera := get_viewport().get_camera_3d()
		var presentation := instance_from_id(int(row.presentation_instance_id)) as Node3D
		var impact: Node3D = presentation.get("_impact") if is_instance_valid(presentation) and presentation.get_script() == MOVE_LIBRARY.EFFECT else null
		row["contact_draw_geometry_visible"] = is_instance_valid(impact) and impact.is_visible_in_tree()
		if camera == null or not row.contact_draw_geometry_visible:
			_arrival_error(action_id, "contact geometry or ordinary camera missing at actual draw")
		else:
			row["contact_camera"] = _xyz(camera.global_position)
			row["contact_camera_basis"] = [_xyz(camera.global_basis.x), _xyz(camera.global_basis.y), _xyz(camera.global_basis.z)]
			row["contact_geometry_position"] = _xyz(impact.global_position)
			row["contact_in_camera_frustum"] = camera.is_position_in_frustum(impact.global_position)
			if not row.contact_in_camera_frustum: _arrival_error(action_id, "contact origin is outside the ordinary camera frustum")
			var world := get_tree().current_scene
			var director: Node = world.get_node_or_null("EncounterDirector") if world != null else null
			var ally := director.call("ally_body") as Node3D if director != null else null
			var enemy := _manager.call("enemy_body") as Node3D if is_instance_valid(_manager) else null
			row["contact_ally_body"] = _body(ally)
			row["contact_enemy_body"] = _body(enemy)
			if not is_instance_valid(ally) or not is_instance_valid(enemy): _arrival_error(action_id, "creature bodies missing at contact draw")
		var pixels := get_viewport().get_texture().get_image()
		var name := "contact-%04d-%s.png" % [int(row.launch.event_sequence), preset.to_lower()]
		if pixels == null or pixels.is_empty() or pixels.get_size() != expected_resolution \
				or DisplayServer.window_get_size() != expected_resolution \
				or GRAPHICS.selected() != preset \
				or RenderingServer.get_current_rendering_method() != ("gl_compatibility" if preset == "Low" else "forward_plus") \
				or pixels.save_png(output.path_join(name)) != OK:
			_arrival_error(action_id, "native %dx%d first contact draw could not be retained with matching window/renderer/preset" % [expected_resolution.x, expected_resolution.y])
		else:
			row["contact_png"] = name
			row["contact_resolution"] = [pixels.get_width(), pixels.get_height()]
		pending_contacts -= 1
		_retain_arrivals()

	func arrival_proof_complete() -> bool:
		if not prove_library_arrival: return false
		if arrival_records.is_empty() or not arrival_errors.is_empty() or pending_contacts > 0: return false
		for action_id: String in arrival_records:
			var row: Dictionary = arrival_records[action_id]
			if not row.errors.is_empty() or not row.has("contact") or not row.has("impact") or not row.has("contact_png"): return false
		return true

	func finish() -> bool:
		if began_ms < 0:
			failure = "no actual native live fight was captured"
			return false
		# Finish this disclosed motion observation after the real prefix, without
		# any further gameplay input or game-clock manipulation.
		while failure.is_empty() and Time.get_ticks_msec() - began_ms < 30000:
			await get_tree().process_frame
		while saving or pending_contacts > 0:
			await get_tree().process_frame
		if not failure.is_empty(): return false
		await _save() # actual terminal sample establishes >=30s timestamp span
		return failure.is_empty() and live_frames > 0 and rows.size() >= 2 \
			and int(rows[-1].elapsed_ms) - int(rows[0].elapsed_ms) >= 30000

	func _xyz(value: Vector3) -> Array[float]: return [value.x, value.y, value.z]
	func _world_value(world: Node, child: String, method: String) -> String:
		var node := world.get_node_or_null(child) if world != null else null
		return str(node.call(method)) if node != null else "unavailable"
	func _body(body: Node3D) -> Dictionary:
		return {"path": str(body.get_path()), "position": _xyz(body.global_position), "visible": body.is_visible_in_tree()} if is_instance_valid(body) else {}
	func _creature(creature: RefCounted) -> Dictionary:
		return {"uid": str(creature.get("uid")), "species": str(creature.get("species_id")), "level": int(creature.get("level")), "hp": float(creature.get("hp")), "fainted": bool(creature.get("fainted"))} if creature != null else {}

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	for argument: String in arguments:
		if argument == "--legacy-order-diagnostic" or argument.begins_with("--resume") \
				or argument.begins_with("--dry") or argument.begins_with("--stop-at"):
			failures.append("earned fight capture refuses legacy, resumed, fixture and boundary-stop paths")
			super._finish(false)
			return
		if argument.begins_with("--output="): _fight_output = argument.trim_prefix("--output=")
		elif argument.begins_with("--source-commit="): _fight_source = argument.trim_prefix("--source-commit=")
		elif argument.begins_with("--preset="): _fight_preset = argument.trim_prefix("--preset=")
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-f]{40}$")
	var renderer := "gl_compatibility" if _fight_preset == "Low" else "forward_plus"
	var requested_resolution := DisplayServer.window_get_size()
	if DisplayServer.get_name() == "headless" or requested_resolution not in [Vector2i(1280, 720), Vector2i(1920, 1080)] \
			or not GRAPHICS.PRESETS.has(_fight_preset) or RenderingServer.get_current_rendering_method() != renderer \
			or pattern.search(_fight_source) == null or not _fight_output.is_absolute_path() \
			or DirAccess.dir_exists_absolute(_fight_output) or not arguments.has("--through-opening") \
			or not arguments.has("--no-checkpoints"):
		failures.append("earned fight capture requires native 1280x720 or 1920x1080, matching preset/renderer, exact source, fresh output and through-opening/no-checkpoints")
		super._finish(false)
		return
	if DirAccess.make_dir_recursive_absolute(_fight_output) != OK or GRAPHICS.choose(_fight_preset) != OK:
		failures.append("could not create earned fight evidence or select preset")
		super._finish(false)
		return
	_observer = FightObserver.new()
	_observer.name = "F17EarnedOpeningFightObserver"
	_observer.output = _fight_output
	_observer.preset = _fight_preset
	_observer.expected_resolution = requested_resolution
	_observer.prove_library_arrival = arguments.has("--prove-library-arrival")
	_observer.retain_sample = _write_fight_manifest.bind(false, false)
	_observer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(_observer)
	_observer.begin_preview()
	if not _write_fight_manifest(false, false):
		failures.append("could not retain initial incomplete earned fight manifest")
		_finish(false)
		return
	await super._run()

func _finish(prefix_passed: bool) -> void:
	if _ending_fight_capture: return
	_ending_fight_capture = true
	var captured := _observer != null and prefix_passed and failures.is_empty()
	if captured: captured = await _observer.finish()
	if captured and _observer.prove_library_arrival and not _observer.arrival_proof_complete():
		captured = false
		failures.append("production library arrival proof incomplete: no launches or unmatched launch/contact/HP/HUD/native draw evidence")
	if not captured:
		failures.append(_observer.failure if _observer != null and not _observer.failure.is_empty() else "earned opening or native fight observation did not complete")
	if _observer != null and not _write_fight_manifest(captured and failures.is_empty(), prefix_passed):
		failures.append("could not retain earned fight manifest")
	if _observer != null: _observer.close_observation()
	super._finish(captured and failures.is_empty())

func _finalize() -> void:
	if is_instance_valid(_observer): _observer.close_observation()

func _write_fight_manifest(complete: bool, prefix_passed: bool) -> bool:
	var file := FileAccess.open(_fight_output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"complete": complete, "source": _fight_source,
		"presets": [_fight_preset], "renderer": RenderingServer.get_current_rendering_method(),
		"resolution": [_observer.expected_resolution.x, _observer.expected_resolution.y],
		"views": _observer.rows, "live_fight_frames": _observer.live_frames, "requested_prefix_passed": prefix_passed,
		"library_arrival": {"requested": _observer.prove_library_arrival,
			"complete": complete and prefix_passed and _observer.arrival_proof_complete(),
			"scope": "observed ordinary player launches only; signal/HP/HUD correlation, visual judge still required",
			"preview_scope": "process-local move_library.enabled only; restored on completion/observer exit",
			"records": _observer.arrival_records, "errors": _observer.arrival_errors,
			"uncorrelated_impacts": _observer.uncorrelated_impacts, "pending_contact_draws": _observer.pending_contacts},
		"failures": failures, "scope": ("actual fresh title/starter/catch presentation and >=30s native motion" if complete
			else "incomplete native earned-opening observation; opening/catch completion and >=30s motion remain unproved")
			+ "; no full M1, visual bar, multiplayer or device claim",
		"shortcuts": ["inherited ordinary-input fresh opening driver", "observational JPEG95 frames at actual timestamps", "motion may include ordinary post-catch aftermath", "no added gameplay inputs or gameplay state mutations by observer",
			"optional --prove-library-arrival previews library in this process; event-triggered native PNGs retain first draw after contact, not an assumed exact periodic frame"]}, "\t") + "\n")
	file.flush()
	var write_error := file.get_error()
	file.close()
	return write_error == OK

extends Node3D

## The Stormwood chapter's playable release and aftermath.
##
## Marrow's Dynamo remains the authority for combat. Once its fourth conduit
## commits the victory flag, this host-owned controller opens the prison,
## reserves the one freed Stormheart for the first nearby character who accepts
## its offer, and addresses that character's existing five-slot ceremony. The
## party choice stays personal; release, Spark placement, the quieted storm and
## the Waterward reveal are world facts committed through the chapter ledger.
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const CAPTURE_CODEC := preload("res://scripts/save/water_capture_codec.gd")
const SHRINE := preload("res://scripts/world/stormwood_heart_shrine.gd")
const WATER_GATE := preload("res://scripts/world/stormwood_water_gate.gd")

const MARROW_FLAG := "stormwood:marrow_defeated"
const FREED_FLAG := "stormwood:legendary_freed"
const OFFER_FLAG := "stormwood:legendary_offer_made"
const SPARK_PLACED_FLAG := "stormwood:spark_placed"
const HEART_PLACED_FLAG := "realm_heart_stormwood_placed"
const WATERWARD_FLAG := "stormwood:waterward_revealed"
const PERSONAL_RECEIPT_FLAG := "stormwood:legendary_ceremony_settled"
const LEGENDARY_SPECIES := "fulgocobra"
const LEGENDARY_NAME := "the Stormheart"
const LEGENDARY_LEVEL := 44
const CORE_POSITION := Vector3(-100.0, 262.21, 5470.0)
const OFFER_RADIUS_M := 14.0
const VIEW_RADIUS_M := 18.0
const WATER_GATE_RADIUS_M := 6.0
const RESEND_SECONDS := 1.0

var world: Node3D
var hub: Node
var session: Node
var _chapter: Node
var _legendary: Node3D
var _cage: Node3D
var _offer_prompt: Node3D
var _view_prompt: Node3D
var _water_gate: Node3D
var _waterward_sea: MeshInstance3D
var _local_claim: Dictionary = {}
var _local_creature: RefCounted
var _waiting_for_offer_dialogue := false
var _save_retry_left := 0.0
var _resend_left := 0.0
var _released_announced := false
var _aftermath_announced := false
var _progression_revision := -1


func mount(owner_world: Node3D) -> void:
	world = owner_world
	hub = world.get_node("StormwoodEncounterHub")
	session = get_node("/root/Game/Session")
	_chapter = world.get_node("StormwoodChapter")
	global_position = CORE_POSITION
	_build_captive()
	_build_offer_prompt()
	_build_spark_shrine()
	_build_waterward_view()
	_build_water_gate()
	var panel := world.get_node_or_null("DialoguePanel")
	if panel != null:
		panel.finished.connect(_dialogue_finished)
	add_to_group("progression_restore")
	_refresh_presentation()
	_released_announced = _has(FREED_FLAG)
	_aftermath_announced = _has(WATERWARD_FLAG)
	if not bool(world.get("simulation_only")):
		session.request_stormwood_encounter({"kind": "ending_snapshot"})


func dispatch(peer: int, intent: Dictionary) -> void:
	if not session.is_host():
		return
	match str(intent.get("kind", "")):
		"ending_claim":
			_claim_for(peer)
		"ending_settled":
			_settle_for(peer, intent)
		"ending_waterward_view":
			_reveal_for(peer)
		WATER_GATE.UNLOCK_INTENT:
			_unlock_water_gate_for(peer)
		"ending_snapshot":
			send_snapshot(peer)


func receive(event: Dictionary) -> void:
	match str(event.get("kind", "")):
		"ending_state":
			_released_announced = bool(event.get("released", false))
			_aftermath_announced = bool(event.get("waterward_revealed", false))
			_refresh_presentation()
		"ending_release":
			_released_announced = true
			_refresh_presentation()
			_animate_release()
			_start_dialogue_when_free("stormwood_stormheart_release")
		"ending_offer":
			var claim: Variant = event.get("claim", {})
			if claim is Dictionary and not (claim as Dictionary).is_empty():
				_receive_claim(claim as Dictionary)
		"ending_aftermath":
			_aftermath_announced = true
			_refresh_presentation()
			_start_dialogue_when_free("stormwood_waterward_aftermath")
		"ending_water_gate_opened":
			get_node("/root/Game").push_world_message("The Waterward gate is open.")
		"ending_refused":
			get_node("/root/Game").push_world_message(str(event.get("reason", "The Stormheart is not ready.")))


func send_snapshot(peer: int) -> void:
	if not session.is_host():
		return
	hub.call("send_to", peer, {
		"kind": "ending_state",
		"released": _has(FREED_FLAG),
		"offer_made": _has(OFFER_FLAG),
		"spark_placed": _has(SPARK_PLACED_FLAG),
		"waterward_revealed": _has(WATERWARD_FLAG),
	})
	var state := _saved_state()
	if not _has(OFFER_FLAG) and str(state.get("recipient_character_id", "")) == _character_for_peer(peer):
		_send_claim(peer, state)


func restore_progression_from_game(_game: Node) -> void:
	_progression_revision = -1
	_refresh_presentation()


func _process(delta: float) -> void:
	var progression: RefCounted = get_node("/root/Game").get("progression")
	if progression != null and int(progression.get("revision")) != _progression_revision:
		_refresh_presentation()
	_process_local_claim(delta)
	if not session.is_host():
		return
	# realm_chapter_events admits the matching host simulation shell, so the
	# authority that completed Marrow also owns every shared ending mutation.
	if _has(MARROW_FLAG) and not _has(FREED_FLAG):
		_chapter.call("emit_event", "dynamo:release")
	if _has(HEART_PLACED_FLAG) and not _has(SPARK_PLACED_FLAG):
		_chapter.call("emit_event", "shrine:stormwood_placed")
	if _has(FREED_FLAG) and not _released_announced:
		_released_announced = true
		_broadcast({"kind": "ending_release"})
	if _has(WATERWARD_FLAG) and not _aftermath_announced:
		_aftermath_announced = true
		_broadcast({"kind": "ending_aftermath"})
	_resend_left -= delta
	if _resend_left <= 0.0 and _has(FREED_FLAG) and not _has(OFFER_FLAG):
		_resend_left = RESEND_SECONDS
		var state := _saved_state()
		var recipient := str(state.get("recipient_character_id", ""))
		if not recipient.is_empty():
			for peer: int in session.peers_in_realm("stormwood"):
				if _character_for_peer(peer) == recipient:
					_send_claim(peer, state)


func _claim_for(peer: int) -> void:
	if not _has(FREED_FLAG) or _has(OFFER_FLAG):
		_refuse(peer, "The Stormheart's offer is no longer waiting.")
		return
	var actor: Node3D = hub.call("actor_for", peer)
	if not is_instance_valid(actor) or actor.global_position.distance_to(_offer_prompt.global_position) > OFFER_RADIUS_M:
		_refuse(peer, "Stand beside the freed Stormheart before answering it.")
		return
	var character := _character_for_peer(peer)
	if character.is_empty():
		_refuse(peer, "Your character record is not ready for this ceremony.")
		return
	var state := _saved_state()
	var reserved := str(state.get("recipient_character_id", ""))
	if not reserved.is_empty() and reserved != character:
		_refuse(peer, "The Stormheart has already offered its bond to another trainer.")
		return
	if reserved.is_empty():
		var creature := _make_legendary()
		var payload := CAPTURE_CODEC.encode(creature)
		if payload.is_empty():
			_refuse(peer, "The Stormheart could not begin the ceremony.")
			return
		state = {
			"recipient_character_id": character,
			"creature": payload,
			"settled": false,
			"kept": false,
		}
		var game := get_node("/root/Game")
		var before: Dictionary = (game.get("realm_environment") as Dictionary).duplicate(true)
		_store_state(state)
		if not _save_world_claim():
			game.set("realm_environment", before)
			_refuse(peer, "The world could not save the ceremony. Try again.")
			return
	_send_claim(peer, state)


func _settle_for(peer: int, intent: Dictionary) -> void:
	if _has(OFFER_FLAG):
		return
	var state := _saved_state()
	if str(state.get("recipient_character_id", "")) != _character_for_peer(peer):
		_refuse(peer, "Only the trainer receiving the offer can settle it.")
		return
	state["kept"] = bool(intent.get("kept", false))
	state["settled"] = true
	_store_state(state)
	var result: Dictionary = _chapter.call("emit_event", "legendary:offer_shown")
	if not bool(result.get("accepted", false)) and not _has(OFFER_FLAG):
		state["settled"] = false
		_store_state(state)
		_refuse(peer, "The world could not record the ceremony. Try again.")
		return
	_broadcast(_state_event())


func _reveal_for(peer: int) -> void:
	if _has(WATERWARD_FLAG):
		hub.call("send_to", peer, {"kind": "ending_aftermath"})
		return
	if not _has(SPARK_PLACED_FLAG):
		_refuse(peer, "Place the Spark at Lantern Hollow before reading the cleared sky.")
		return
	var actor: Node3D = hub.call("actor_for", peer)
	if not is_instance_valid(actor) or actor.global_position.distance_to(_view_prompt.global_position) > VIEW_RADIUS_M:
		_refuse(peer, "Climb onto the high platform to see beyond the broken storm.")
		return
	var result: Dictionary = _chapter.call("emit_event", "aftermath:waterward_view")
	if bool(result.get("accepted", false)) and _has(WATERWARD_FLAG):
		_broadcast({"kind": "ending_aftermath"})


func _unlock_water_gate_for(peer: int) -> void:
	if not is_instance_valid(_water_gate):
		_refuse(peer, "The Waterward gate is not ready yet.")
		return
	var actor: Node3D = hub.call("actor_for", peer)
	var game := get_node("/root/Game")
	var flags: RefCounted = game.get("progression") as RefCounted
	if not is_instance_valid(actor) or not WATER_GATE.request_allowed(flags,
			actor.global_position, _water_gate.global_position, WATER_GATE_RADIUS_M):
		_refuse(peer, "Stand at the Waterward gate after charting the cleared sky.")
		return
	var transport: Node = game.get("ledger") as Node
	var ledger: RefCounted = transport.get("ledger") as RefCounted if transport != null else null
	var result: Dictionary = WATER_GATE.host_commit(game, ledger)
	if not bool(result.get("ok", false)):
		_refuse(peer, str(result.get("reason", "The Waterward gate did not open.")))
		return
	var delta: Dictionary = result.get("delta", {}) as Dictionary
	if transport != null and not (delta.get("ops", []) as Array).is_empty():
		transport.call("publish_journaled_delta", delta)
	# The host's ordinary RealmGate interaction already reports synchronous
	# success. A remote requester needs the same feedback while its delta lands.
	if peer != int(session.call("local_peer_id")):
		hub.call("send_to", peer, {"kind": "ending_water_gate_opened"})


func _receive_claim(claim: Dictionary) -> void:
	var game := get_node("/root/Game")
	if str(claim.get("recipient_character_id", "")) != str(game.get("local").get("character_id")):
		return
	var player_flags: RefCounted = game.call("player_flags")
	if player_flags != null and bool(player_flags.call("has", PERSONAL_RECEIPT_FLAG)):
		_local_claim = claim.duplicate(true)
		_finish_local_claim(_has_party_legendary(game.get("party")))
		return
	if _has_party_legendary(game.get("party")):
		_local_claim = claim.duplicate(true)
		_save_retry_left = 0.0
		_finish_local_claim(true)
		return
	if not _local_claim.is_empty() or game.get("pending_catch") != null:
		return
	_local_claim = claim.duplicate(true)
	_waiting_for_offer_dialogue = true
	_start_dialogue_when_free("stormwood_stormheart_offer")


func _process_local_claim(delta: float) -> void:
	if _waiting_for_offer_dialogue:
		var panel := world.get_node_or_null("DialoguePanel")
		if panel == null or not bool(panel.call("is_open")):
			_start_dialogue_when_free("stormwood_stormheart_offer")
	if _local_claim.is_empty() or _local_creature == null:
		return
	var game := get_node("/root/Game")
	if game.get("pending_catch") != null:
		return
	_save_retry_left -= delta
	if _save_retry_left > 0.0:
		return
	_finish_local_claim((game.get("party").call("members") as Array).has(_local_creature))


func _dialogue_finished(id: String) -> void:
	if id != "stormwood_stormheart_offer" or not _waiting_for_offer_dialogue:
		return
	_waiting_for_offer_dialogue = false
	_begin_local_ceremony()


func _begin_local_ceremony() -> void:
	if _local_claim.is_empty():
		return
	var game := get_node("/root/Game")
	if game.get("pending_catch") != null:
		return
	_local_creature = CAPTURE_CODEC.decode(_local_claim.get("creature", {}))
	if _local_creature == null:
		game.push_world_message("The Stormheart's offer could not be restored yet.")
		return
	_local_creature.set("caught_on_day", maxi(1, int(game.get("day"))))
	var party: RefCounted = game.get("party")
	if not bool(party.call("is_full")):
		if bool(party.call("add", _local_creature)):
			_finish_local_claim(true)
		return
	game.set("pending_catch", _local_creature)


func _finish_local_claim(kept: bool) -> void:
	if _local_claim.is_empty():
		return
	var game := get_node("/root/Game")
	var saver: RefCounted = game.get("save_system")
	var character := str(game.get("local").get("character_id"))
	# The world keeps the unresolved claim; this player-owned receipt makes a
	# reconnect resume at the acknowledgement instead of replaying a farewell.
	var player_flags: RefCounted = game.call("player_flags")
	if player_flags != null:
		player_flags.call("set_flag", PERSONAL_RECEIPT_FLAG)
	if saver != null and not character.is_empty() and not bool(saver.call("save_character", game, character)):
		_save_retry_left = 1.0
		game.push_world_message("Could not save the roster choice. The Stormheart is still waiting.")
		return
	session.request_stormwood_encounter({"kind": "ending_settled", "kept": kept})
	_local_claim.clear()
	_local_creature = null


func _on_offer() -> void:
	session.request_stormwood_encounter({"kind": "ending_claim"})


func _on_waterward_view() -> void:
	session.request_stormwood_encounter({"kind": "ending_waterward_view"})


func _refresh_presentation() -> void:
	var game := get_node_or_null("/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	_progression_revision = int(progression.get("revision")) if progression != null else -1
	var freed := _has(FREED_FLAG) or _released_announced
	var offered := _has(OFFER_FLAG)
	if _legendary != null:
		_legendary.visible = not offered
		_legendary.position = Vector3(0.0, 0.0, 8.0) if freed else Vector3.ZERO
	if _cage != null:
		_cage.visible = not freed
	if _offer_prompt != null:
		_offer_prompt.set("enabled", freed and not offered and not bool(world.get("simulation_only")))
	if _view_prompt != null:
		var revealed := _has(WATERWARD_FLAG) or _aftermath_announced
		_view_prompt.set("enabled", _has(SPARK_PLACED_FLAG) and not bool(world.get("simulation_only")))
		_view_prompt.set("actionable", not revealed)
		_view_prompt.set("label", "Waterward route charted" if revealed else "Look beyond the broken storm")
	if _waterward_sea != null:
		_waterward_sea.visible = _has(SPARK_PLACED_FLAG)


func _animate_release() -> void:
	if bool(world.get("simulation_only")) or _legendary == null:
		return
	_legendary.position = Vector3.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_legendary, "position", Vector3(0.0, 0.0, 8.0), 2.4)


func _build_captive() -> void:
	if bool(world.get("simulation_only")):
		_legendary = Node3D.new()
		_legendary.name = "CaptiveStormheart"
		add_child(_legendary)
		_cage = Node3D.new()
		_cage.name = "StormheartContainment"
		add_child(_cage)
		_legendary.visible = false
		return
	_legendary = CREATURE_SCENE.instantiate() as Node3D
	_legendary.set_script(CREATURE_BODY)
	_legendary.name = "CaptiveStormheart"
	_legendary.set("body_scale", 1.8)
	_legendary.call("setup", LEGENDARY_SPECIES, false)
	add_child(_legendary)
	_legendary.call("set_alpha", true)
	_legendary.set("collision_layer", 0)
	_legendary.set("collision_mask", 0)
	_legendary.set_physics_process(false)
	_cage = Node3D.new()
	_cage.name = "StormheartContainment"
	add_child(_cage)
	var cage_material := _glow(Color("8d78e8"), 2.4, 0.62)
	for i in 8:
		var bar := MeshInstance3D.new()
		bar.name = "ContainmentArc%02d" % i
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.07
		mesh.bottom_radius = 0.07
		mesh.height = 7.0
		mesh.radial_segments = 6
		bar.mesh = mesh
		var angle := TAU * float(i) / 8.0
		bar.position = Vector3(cos(angle) * 3.6, 3.5, sin(angle) * 3.6)
		bar.material_override = cage_material
		_cage.add_child(bar)


func _build_offer_prompt() -> void:
	_offer_prompt = INTERACTABLE.new()
	_offer_prompt.name = "StormheartOffer"
	_offer_prompt.position = Vector3(0.0, 1.4, 10.5)
	_offer_prompt.call("configure", "Accept the Stormheart's offer", OFFER_RADIUS_M, false)
	_offer_prompt.connect("activated", _on_offer)
	add_child(_offer_prompt)


func _build_spark_shrine() -> void:
	var shrine := SHRINE.new()
	shrine.name = "SparkOfStormwoodShrine"
	shrine.set("presentation_enabled", not bool(world.get("simulation_only")))
	shrine.call("setup", "stormwood", "Spark of the Stormwood", "stormwood")
	world.add_child(shrine)
	var x := -450.0
	var z := 3960.0
	shrine.global_position = Vector3(x, world.call("ground_height_at", x, z), z)
	if bool(world.get("simulation_only")):
		shrine.visible = false


func _build_waterward_view() -> void:
	_view_prompt = INTERACTABLE.new()
	_view_prompt.name = "WaterwardView"
	_view_prompt.position = Vector3(0.0, 1.4, 17.0)
	_view_prompt.call("configure", "Look beyond the broken storm", VIEW_RADIUS_M, false)
	_view_prompt.connect("activated", _on_waterward_view)
	add_child(_view_prompt)
	if bool(world.get("simulation_only")):
		return
	# The view remains a horizon and has no collision. The deliberate gate on
	# this same platform is built separately and stays sealed until this view
	# grants the one-time key.
	_waterward_sea = MeshInstance3D.new()
	_waterward_sea.name = "DistantWaterwardSea"
	var plane := PlaneMesh.new()
	plane.size = Vector2(2600.0, 1700.0)
	_waterward_sea.mesh = plane
	_waterward_sea.material_override = _glow(Color("2d8fa6"), 0.35, 0.92)
	world.add_child(_waterward_sea)
	_waterward_sea.global_position = Vector3(-100.0, 35.0, 6900.0)


func _build_water_gate() -> void:
	_water_gate = WATER_GATE.new()
	_water_gate.name = "WaterwardRealmGate"
	_water_gate.origin_realm = "stormwood"
	_water_gate.call("setup", "water", "water_arrival_from_stormwood",
		"Tidewake", WATER_GATE.WATER_KEY_FLAG, WATER_GATE.WATER_GATE_FLAG)
	world.add_child(_water_gate)
	var anchor: Dictionary = world.call("entry_anchor", "stormwood_departure_to_water")
	var position: Array = anchor.get("position", []) as Array
	if position.size() >= 3:
		_water_gate.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))
	if bool(world.get("simulation_only")):
		_water_gate.visible = false


func _make_legendary() -> RefCounted:
	var creature: RefCounted = TRAINER_NPC.creature_for({
		"species": LEGENDARY_SPECIES,
		"level": LEGENDARY_LEVEL,
	})
	if creature != null:
		creature.set("nickname", LEGENDARY_NAME)
	return creature


func _has_party_legendary(party: RefCounted) -> bool:
	if party == null:
		return false
	for creature: RefCounted in party.call("members"):
		if str(creature.get("species_id")) == LEGENDARY_SPECIES \
				and str(creature.get("nickname")) == LEGENDARY_NAME \
				and int(creature.get("level")) == LEGENDARY_LEVEL:
			return true
	return false


func _start_dialogue_when_free(id: String) -> bool:
	if bool(world.get("simulation_only")):
		return false
	var panel := world.get_node_or_null("DialoguePanel")
	if panel == null or bool(panel.call("is_open")):
		return false
	return bool(panel.call("start", id))


func _character_for_peer(peer: int) -> String:
	var row: Dictionary = session.registry().row(peer)
	if row.is_empty() and peer == session.local_peer_id():
		return str(get_node("/root/Game").get("local").get("character_id"))
	return str(row.get("character_id", ""))


func _saved_state() -> Dictionary:
	var environment: Dictionary = get_node("/root/Game").get("realm_environment")
	var stormwood: Variant = environment.get("stormwood", {})
	if stormwood is Dictionary:
		var ending: Variant = (stormwood as Dictionary).get("ending", {})
		if ending is Dictionary:
			return (ending as Dictionary).duplicate(true)
	return {}


func _store_state(state: Dictionary) -> void:
	var game := get_node("/root/Game")
	var environment: Dictionary = game.get("realm_environment")
	var stormwood: Dictionary = (environment.get("stormwood", {}) as Dictionary).duplicate(true)
	stormwood["ending"] = state.duplicate(true)
	environment["stormwood"] = stormwood
	game.set("realm_environment", environment)


func _save_world_claim() -> bool:
	var game := get_node("/root/Game")
	var saver: RefCounted = game.get("save_system")
	var world_state: RefCounted = game.get("world")
	if saver == null or world_state == null or str(world_state.get("world_id")).is_empty():
		return true
	var saved := bool(saver.call("save_world", game, str(world_state.get("world_id"))))
	if not saved:
		push_error("Stormwood ending could not persist the reserved legendary ceremony")
	return saved


func _send_claim(peer: int, state: Dictionary) -> void:
	if bool(state.get("settled", false)):
		return
	hub.call("send_to", peer, {"kind": "ending_offer", "claim": state.duplicate(true)})


func _refuse(peer: int, reason: String) -> void:
	hub.call("send_to", peer, {"kind": "ending_refused", "reason": reason})


func _broadcast(event: Dictionary) -> void:
	for peer: int in session.peers_in_realm("stormwood"):
		hub.call("send_to", peer, event)
	if not session.is_active():
		hub.call("send_to", session.local_peer_id(), event)


func _state_event() -> Dictionary:
	return {
		"kind": "ending_state",
		"released": _has(FREED_FLAG),
		"offer_made": _has(OFFER_FLAG),
		"spark_placed": _has(SPARK_PLACED_FLAG),
		"waterward_revealed": _has(WATERWARD_FLAG),
	}


func _has(flag: String) -> bool:
	var game := get_node_or_null("/root/Game")
	return game != null and game.get("progression") != null and bool(game.get("progression").call("has", flag))


func _glow(colour: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(colour, alpha)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	material.roughness = 0.42
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


## Pure policy helpers: tests pin the unique-recipient and chapter-order rules
## without needing a network peer or loading the world scene.
static func claim_allowed(flags: Array, reserved_character: String, character: String) -> bool:
	return flags.has(FREED_FLAG) and not flags.has(OFFER_FLAG) and not character.is_empty() \
		and (reserved_character.is_empty() or reserved_character == character)


static func waterward_allowed(flags: Array) -> bool:
	return flags.has(SPARK_PLACED_FLAG) and not flags.has(WATERWARD_FLAG)

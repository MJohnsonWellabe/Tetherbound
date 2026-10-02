extends Node

## Session lifetime retains the original accepted resolution through failed
## world writes. No remote intent can provide a clock, census or generation.
const RULES := preload("res://scripts/repeatables/alpha_respawns.gd")
var _pending: Dictionary = {}
var _settled: Dictionary = {}
var _first_pending: Dictionary = {}
var _left := 0.0
var _service: Node

func _ready() -> void:
	_service = preload("res://scripts/repeatables/alpha_respawn_service.gd").new()
	_service.name = "AlphaRespawnService"
	add_child(_service)
	_service.call("bind_host", _host_context, _commit, _publish)

func session() -> Node:
	return get_parent().get_parent()

func first_spawn(director: Node, id: String) -> Dictionary:
	var owner := session()
	var site := RULES.site(id)
	if RULES.config().get("runtime_enabled") != true or owner.call("is_host") != true or site.is_empty() \
		or not is_instance_valid(director) or director.get("_session") != owner or director.get_script() == null \
		or not owner.FOUNDATION_DIRECTORS.has(director.get_script().resource_path): return {}
	var world: RefCounted = owner.call("_game").world
	var epoch := str(owner.call("_altar_current_epoch"))
	if not preload("res://scripts/data/redesign_state.gd").validate("world", world.redesign_world, [], world.reward_delivery_namespace).is_empty(): return {}
	var retained := RULES.retained_spawn(world.redesign_world, id)
	if not retained.is_empty(): return retained
	# A pristine admitted document carries alpha_cycles={} until the first
	# durable RULES.first_spawn plan creates sites. Never invent a live packet.
	if not world.redesign_world.get("alpha_cycles", {}).get("sites", {}).get(id, {}).is_empty(): return {}
	var key := JSON.stringify([world.reward_delivery_namespace, epoch, id]).sha256_text()
	if not _first_pending.has(key):
		_first_pending[key] = {"world": weakref(world), "director": weakref(director), "epoch": epoch,
			"world_namespace": world.reward_delivery_namespace, "site_id": id}
	var frozen: Dictionary = _first_pending[key]
	if frozen.world.get_ref() != world or frozen.director.get_ref() != director or frozen.epoch != epoch \
		or frozen.world_namespace != world.reward_delivery_namespace: return {}
	# Initial population is built before shell_build_complete. Retain its
	# request, then sample the owning look once the normal realm is ready.
	var realm_id := "water" if site.biome == "tidewake" else str(site.biome)
	var realm: Node = owner.call("_portal_world_node", realm_id)
	var look := _realm_look(site)
	if realm == null or not realm.is_ancestor_of(director) or look == null: return {}
	if not frozen.has("night"):
		frozen.night = bool(look.call("is_dark"))
		frozen.weather = unusual_weather(look.get("_weather"))
	var plan := RULES.first_spawn(world.redesign_world, id, frozen.world_namespace, frozen.night, frozen.weather)
	if plan.is_empty(): return {}
	var result: Dictionary = _commit(plan)
	if result.get("ok") != true or result.get("durable") != true: return {}
	_first_pending.erase(key)
	return RULES.retained_spawn(world.redesign_world, id)

func resolution(director: Node, encounter_id: String, outcome: String, capture: Dictionary = {}) -> Dictionary:
	var owner := session()
	if RULES.config().get("runtime_enabled") != true: return {"ok": true, "durable": true, "disabled": true}
	if owner.call("is_host") != true or not is_instance_valid(director) or director.get("_session") != owner \
		or director.get_script() == null or not owner.FOUNDATION_DIRECTORS.has(director.get_script().resource_path): return {"ok": false, "durable": false}
	var runtime: Node = director.call("_shared_host_fight", encounter_id)
	var body: Node3D = runtime.call("body") if runtime != null else null
	if body == null or not body.has_meta("foundation_alpha_site"): return {"ok": true, "durable": true, "ordinary": true}
	var id := str(body.get_meta("foundation_alpha_site"))
	var generation := int(body.get_meta("foundation_alpha_generation", 0))
	var site := RULES.site(id)
	if site.is_empty() or generation < 1: return {"ok": false, "durable": false}
	if outcome == "defeat":
		var accepted: Dictionary = director.call("host_wild_victory_source", encounter_id)
		if accepted.get("accepted", {}).get("delta", {}).get("killed") != true \
			or accepted.get("enemy_record", {}).get("fainted") != true: return {"ok": false, "durable": false}
	elif outcome == "catch":
		if runtime.get_meta("catch_decision", {}).get("caught") != true \
			or director.get("_encounter_host").call("phase", encounter_id) != "catching": return {"ok": false, "durable": false}
	else: return {"ok": false, "durable": false}
	var game: Node = owner.call("_game")
	var world: RefCounted = game.world
	if body.get_meta("foundation_alpha_world", null) == null \
		or body.get_meta("foundation_alpha_world").get_ref() != world \
		or body.get_meta("foundation_alpha_epoch", "") != owner.call("_altar_current_epoch"): return {"ok": false, "durable": false}
	var capture_row: Dictionary = {}
	if not capture.is_empty():
		if outcome != "catch" or not preload("res://scripts/net/foundation_capture_rules.gd").offer_valid(capture) \
			or capture.creature != preload("res://scripts/save/water_capture_codec.gd").encode(body.get("instance")) \
			or capture.capture_traits != body.get_meta("foundation_alpha_packet", {}) \
			or capture.participants[0] != owner.call("_authority_character", int(runtime.get("catch_claimant"))) \
			or capture.world_namespace != world.reward_delivery_namespace or capture.session_id != owner.call("_altar_current_epoch"): return {"ok": false, "durable": false}
		capture_row = preload("res://scripts/net/foundation_event.gd").make(world, capture.session_id, capture.source_key,
			[{"character_id": capture.participants[0], "action": "capture_offer", "intent": {}, "context": capture}])
		if capture_row.is_empty(): return {"ok": false, "durable": false}
	var key := JSON.stringify([world.reward_delivery_namespace, owner.call("_altar_current_epoch"), id, generation]).sha256_text()
	if _settled.has(key): return {"ok": true, "durable": true}
	if not _pending.has(key):
		var seconds := _seconds(site)
		var census := _census(site)
		if seconds < 0 or census.is_empty(): return {"ok": false, "durable": false, "code": "alpha_live_census_clock_required"}
		_pending[key] = {"world": weakref(world), "world_namespace": world.reward_delivery_namespace,
			"world_id": world.world_id, "epoch": owner.call("_altar_current_epoch"), "site_id": id,
			"generation": generation, "seconds": seconds, "characters": census, "outcome": outcome, "capture_offer": capture_row}
	return _retry(key)

func _realm_look(site: Dictionary) -> Node:
	var realm_id := "water" if site.get("biome") == "tidewake" else str(site.get("biome", ""))
	var realm: Node = session().call("_portal_world_node", realm_id)
	if realm == null: return null
	var found: Node = null
	for candidate: Node in get_tree().get_nodes_in_group(&"day_cycle"):
		if not realm.is_ancestor_of(candidate) or candidate.get_script() == null \
			or candidate.get_script().resource_path != "res://scripts/world/world_look.gd": continue
		if found != null: return null
		found = candidate
	return found if found != null and found.has_method("is_dark") \
		and found.has_method("elapsed_seconds") and found.get("_weather") is Dictionary else null

static func unusual_weather(delta: Dictionary) -> bool:
	# WorldWeather applies the whole preset, including clear's weight/comment
	# metadata. Only its effective atmosphere/rain overrides are weather.
	if delta.get("rain") == true: return true
	for field: String in ["sun", "sky", "environment"]:
		if delta.get(field) is Dictionary and not delta[field].is_empty(): return true
	return false

func _seconds(site: Dictionary) -> int:
	var clock := _realm_look(site)
	if clock == null: return -1
	var world: RefCounted = session().call("_game").world
	return day_seconds(int(world.day))

static func day_seconds(day: int) -> int:
	if day < 1: return -1
	# WorldLook's midnight and Game's advance_day use different phases, and
	# resume realigns the look. Only the existing durable day owns cooldown
	# progress; three configured days mean three actual advance_day events.
	return (day - 1) * int(RULES.config().day_seconds)

func _region(peer: Dictionary) -> String:
	var owner := session()
	var writer: Node = owner.get_node_or_null(^"LedgerRpc")
	if writer == null or owner.call("admitted_character_state", int(peer.peer_id)).is_empty(): return ""
	var actor: Dictionary = writer.call("_water_actor_context", int(peer.peer_id), {})
	if actor.get("character_id") != peer.character_id or actor.get("realm") != peer.realm or not actor.get("position") is Vector3: return ""
	var map: RefCounted = owner.call("_game").local.call("map_for", str(peer.realm))
	if map == null: return ""
	var here: Vector3 = actor.position
	return str(map.call("_region_at", Vector2(here.x, here.z)).get("id", ""))

func _census(site: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for peer: Dictionary in session().call("peers"):
		if preload("res://scripts/data/biome_order.gd").canonical_id(str(peer.realm)) != site.biome: continue
		if _region(peer) == site.region_id and not result.has(peer.character_id): result.append(peer.character_id)
	result.sort()
	return result

func _retry(key: String) -> Dictionary:
	var frozen: Dictionary = _pending[key]
	var owner := session()
	var game: Node = owner.call("_game")
	var world: RefCounted = frozen.world.get_ref()
	if world == null or game.world != world or world.reward_delivery_namespace != frozen.world_namespace \
		or world.world_id != frozen.world_id or owner.call("_altar_current_epoch") != frozen.epoch: return {"ok": false, "durable": false, "code": "alpha_original_owner_required"}
	var saved: Dictionary = world.redesign_world.get("alpha_cycles", {}).get("sites", {}).get(frozen.site_id, {})
	if saved.get("status") == "waiting" and saved.get("generation") == frozen.generation \
		and saved.get("resolved_at_seconds") == frozen.seconds and saved.get("required_departures") == frozen.characters \
		and (frozen.capture_offer.is_empty() or world.reward_deliveries.get(frozen.capture_offer.delivery_id) == frozen.capture_offer):
		_settled[key] = true
		_pending.erase(key)
		return {"ok": true, "durable": true}
	var result: Dictionary = _service.call("resolve", frozen.site_id, {"is_host": true, "validated_host_resolution": true,
		"redesign_world": world.redesign_world.duplicate(true), "generation": frozen.generation,
		"world_seconds": frozen.seconds, "region_characters": frozen.characters.duplicate(), "outcome": frozen.outcome})
	if result.get("durable") == true:
		_settled[key] = true
		_pending.erase(key)
	return result

func _commit(plan: Dictionary) -> Dictionary:
	var offer: Dictionary = {}
	if plan.get("operation") == "alpha_resolve":
		for frozen: Dictionary in _pending.values():
			if frozen.site_id == plan.site_id and frozen.generation == plan.source.generation \
				and frozen.world.get_ref() == session().call("_game").world and frozen.epoch == session().call("_altar_current_epoch"): offer = frozen.capture_offer
	return session().get_node(^"LedgerRpc").call("commit_alpha_plan", plan, offer)

func _host_context(id: String) -> Dictionary:
	var owner := session()
	if owner.call("is_host") != true: return {}
	var game: Node = owner.call("_game")
	var site := RULES.site(id)
	if site.is_empty(): return {}
	var host := {"is_host": true, "redesign_world": game.world.redesign_world.duplicate(true),
		"world_namespace": game.world.reward_delivery_namespace}
	if not RULES.retained_spawn(host.redesign_world, id).is_empty(): return host
	var clock := _realm_look(site)
	var seconds := _seconds(site)
	if not _census(site).is_empty() or seconds < 0 or clock == null: return {}
	host.world_seconds = seconds
	host.night = bool(clock.call("is_dark"))
	host.weather = unusual_weather(clock.get("_weather"))
	return host

func _publish(id: String, packet: Dictionary) -> bool:
	var owner := session()
	var site := RULES.site(id)
	var realm_id := "water" if site.get("biome") == "tidewake" else str(site.get("biome", ""))
	var realm: Node3D = owner.call("_portal_world_node", realm_id)
	if realm == null: return false
	for node: Node in realm.find_children("*", "Node", true, false):
		if node.get_script() == null or node.get_script().resource_path not in ["res://scripts/combat/encounter_director.gd", "res://scripts/combat/water_encounter_director.gd", "res://scripts/combat/stormwood_encounter_director.gd"]: continue
		for wild: Node3D in node.get("_wild_creatures"):
			if is_instance_valid(wild) and wild.get_meta("foundation_alpha_site", "") == id \
				and wild.get_meta("foundation_alpha_generation", 0) == packet.captured_from.spawn_generation: return true
		node.call("foundation_publish_alpha", id, packet)
		return false
	return false

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 1.0
	var owner := session()
	if RULES.config().get("runtime_enabled") != true or owner.call("is_host") != true: return
	for key: String in _first_pending.keys():
		var frozen: Dictionary = _first_pending[key]
		var director: Node = frozen.director.get_ref()
		if director == null or frozen.world.get_ref() != owner.call("_game").world \
			or frozen.epoch != owner.call("_altar_current_epoch") \
			or frozen.world_namespace != owner.call("_game").world.reward_delivery_namespace:
			_first_pending.erase(key)
			continue
		var packet := first_spawn(director, frozen.site_id)
		if not packet.is_empty(): _publish(frozen.site_id, packet)
	for key: String in _pending.keys(): _retry(key)
	var game: Node = owner.call("_game")
	var world: RefCounted = game.world
	var rows: Dictionary = world.redesign_world.get("alpha_cycles", {}).get("sites", {}).duplicate(true)
	for id: String in rows:
		var site := RULES.site(id)
		if site.is_empty(): continue
		var record: Dictionary = world.redesign_world.alpha_cycles.sites[id]
		if record.status == "waiting":
			for peer: Dictionary in owner.call("peers"):
				if not record.required_departures.has(peer.character_id) or record.departed.has(peer.character_id): continue
				var region := _region(peer)
				if region.is_empty(): continue
				# A live actor in another named region/realm is evidence of leaving;
				# absence, disconnect and an unlocated proxy never count.
				if preload("res://scripts/data/biome_order.gd").canonical_id(str(peer.realm)) != site.biome: region = str(peer.realm) + ":" + region
				_service.call("depart", id, {"is_host": true, "validated_region_transition": true,
					"redesign_world": world.redesign_world.duplicate(true), "generation": int(record.generation),
					"character_id": peer.character_id, "actual_region": region})
				record = world.redesign_world.alpha_cycles.sites[id]
		_service.call("advance", id)

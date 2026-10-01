extends Node

## Owner UI/hazard observations have their own authenticated lifecycle. They
## never carry a travel action, position, destination, inventory or candidate.
## Host travel still resolves the registered body and its traversal/contact.
var _serial: int = 0
var _left: float = 0.0
var _observations: Dictionary = {}

func _ready() -> void:
	session().connect("peer_left", func(peer: int) -> void: _observations.erase(peer))
	session().connect("session_ended", func(_reason: String) -> void: _observations.clear())

func session() -> Node:
	return get_parent().get_parent()

func reset() -> void:
	_observations.clear()
	_serial = 0

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.refresh_seconds)
	var owner: Node = session()
	if owner.call("portal_runtime_ready") != true: return
	if owner.call("is_host") == true:
		for peer: int in _observations.keys():
			var context := host_context(peer)
			if context.is_empty():
				context = {"character_id": _observations[peer].sample.character_id, "combat": true}
			owner.get("_portal_policy").call("cancel_invalid", context)
		return
	if owner.call("is_active") != true: return
	publish_now()

func publish_now() -> bool:
	var owner: Node = session()
	if owner.call("is_host") == true or owner.call("is_active") != true: return false
	var sample := local_sample()
	if sample.is_empty(): return false
	_serial += 1
	sample.sequence = _serial
	owner.call("publish_travel_lifecycle", self, sample)
	return true

func local_sample() -> Dictionary:
	var owner: Node = session()
	var game: Node = owner.call("_game")
	if game == null or game.get("local") == null or game.get("world") == null: return {}
	var realm: String = game.get("current_realm")
	var world_node: Node3D = owner.call("_portal_world_node", realm)
	var actor := game.call("find_player") as CharacterBody3D
	if actor == null or world_node == null or not world_node.is_ancestor_of(actor): return {}
	var swim: Node = actor.get("swim_controller")
	var fly: Node = actor.get("fly_controller")
	var downed: Node = game.get_node_or_null(^"DownedState")
	var vitals: RefCounted = actor.get("vitals")
	if swim == null or fly == null or downed == null or vitals == null: return {}
	var input_owner: Node = preload("res://scripts/ui/input_owner.gd").current(get_tree())
	var key: Node = game.get_node_or_null(^"HomeKey")
	var dialogue: bool = false
	var cutscene: bool = input_owner != null and input_owner != key
	for node: Node in get_tree().get_nodes_in_group("progression_restore"):
		if world_node.is_ancestor_of(node) and node.has_method("is_fading") and node.call("is_fading") == true: cutscene = true
	for node: Node in get_tree().get_nodes_in_group("story_modal"):
		if node.has_method("is_open") and node.call("is_open") == true: dialogue = true
	return {"character_id": game.get("local").character_id, "world_instance_id": game.get("world").reward_delivery_namespace,
		"session_epoch": owner.call("_altar_current_epoch"), "realm": realm,
		"damage_revision": vitals.get("damage_revision"), "dialogue": dialogue, "cutscene": cutscene,
		"swimming": bool(swim.call("is_swimming")), "flying": bool(fly.call("is_flying")), "downed": bool(downed.call("is_downed"))}

static func valid_sample(sample: Dictionary) -> bool:
	if sample.size() != 11: return false
	for field: String in ["character_id", "world_instance_id", "session_epoch", "realm"]:
		if not sample.get(field) is String or sample[field].is_empty() or sample[field].length() > 192: return false
	for field: String in ["dialogue", "cutscene", "swimming", "flying", "downed"]:
		if not sample.get(field) is bool: return false
	return sample.get("sequence") is int and sample.sequence > 0 \
		and sample.get("damage_revision") is int and sample.damage_revision >= 0

func accept(peer: int, sample: Dictionary) -> void:
	var owner: Node = session()
	if owner.call("is_host") != true or not valid_sample(sample) \
		or sample.character_id != owner.call("_authority_character", peer) \
		or sample.session_epoch != owner.call("_altar_current_epoch") \
		or sample.world_instance_id != owner.call("_game").get("world").reward_delivery_namespace \
		or owner.call("admitted_character_state", peer).is_empty(): return
	var prior: Dictionary = _observations.get(peer, {})
	if not prior.is_empty() and prior.sample.session_epoch == sample.session_epoch \
		and (sample.sequence <= prior.sample.sequence or sample.damage_revision < prior.sample.damage_revision): return
	_observations[peer] = {"sample": sample.duplicate(true), "seen_at": Time.get_ticks_msec()}

func remote_body(peer: int) -> CharacterBody3D:
	var owner: Node = session()
	var found: CharacterBody3D
	for proxy: Node in get_tree().get_nodes_in_group("remote_trainer"):
		if proxy.get_multiplayer_authority() != peer: continue
		if found != null or proxy.get_script() == null or proxy.get_script().resource_path != "res://scripts/net/remote_trainer.gd": return null
		found = proxy as CharacterBody3D
	if found == null or found.get("character_id") != owner.call("_authority_character", peer): return null
	return found

func host_context(peer: int) -> Dictionary:
	var owner: Node = session()
	if owner.call("is_host") != true or peer == owner.call("local_peer_id"): return {}
	var observation: Dictionary = _observations.get(peer, {})
	if observation.is_empty(): return {}
	var sample: Dictionary = observation.sample
	var timeout: float = float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.refresh_seconds) * 4.0
	var game: Node = owner.call("_game")
	if Time.get_ticks_msec() - int(observation.seen_at) > int(timeout * 1000.0) \
		or sample.character_id != owner.call("_authority_character", peer) \
		or sample.session_epoch != owner.call("_altar_current_epoch") \
		or sample.world_instance_id != game.get("world").reward_delivery_namespace: return {}
	var actor := remote_body(peer)
	var realm: String = sample.realm
	var world_node: Node3D = owner.call("_portal_world_node", realm)
	var downed: Node = game.get_node_or_null(^"DownedState")
	if actor == null or world_node == null or downed == null or not world_node.is_ancestor_of(actor) \
		or actor.get("net_realm") != realm or not actor.is_physics_processing(): return {}
	var aquatic: RefCounted = actor.get("aquatic")
	if aquatic == null: return {}
	var personal: Dictionary = owner.get("_character_authority").call("state", sample.character_id)
	if personal.is_empty(): return {}
	var key_count: int = 0
	for stack: Variant in personal.get("inventory", []):
		if stack is Dictionary and stack.get("id") == "home_key": key_count += int(stack.get("n", 0))
	var positions: Dictionary = {}
	var arches: Dictionary = {}
	for hall: Node in get_tree().get_nodes_in_group("crossing_halls"):
		if not world_node.is_ancestor_of(hall): continue
		for id: String in ["home", "tidewake", "cloudreach", "stormwood", "biome5", "biome6", "biome7", "biome8"]:
			var arch: Node3D = hall.call("arch", id)
			if arch != null:
				if arches.has(id): return {}
				arches[id] = arch.global_position
	for stone: Node in get_tree().get_nodes_in_group("waystones"):
		if world_node.is_ancestor_of(stone) and stone.get("realm_id") == realm:
			var id: String = stone.get("waystone_id")
			if positions.has(id): return {}
			positions[id] = (stone as Node3D).global_position
	return {"world_instance_id": sample.world_instance_id, "character_id": sample.character_id, "peer_id": peer,
		"realm": realm, "position": actor.global_position, "damage_revision": sample.damage_revision,
		"combat": owner.call("_altar_peer_in_combat", peer), "dialogue": sample.dialogue, "cutscene": sample.cutscene,
		"swimming": sample.swimming or aquatic.get("mode") != preload("res://scripts/player/swim_state.gd").Mode.LAND,
		"flying": sample.flying or actor.get("net_flying") == true or actor.get("net_carried") == true,
		"downed": sample.downed or (downed.get("_downed_peers") as Dictionary).has(peer), "home_key_owned": key_count == 1,
		"character_unlocks": personal.redesign_character.portal_unlocks.duplicate(),
		"world_unlocks": game.get("world").redesign_world.portal_unlocks.duplicate(),
		"character_stirred": owner.get("_character_authority").call("character_fifth_stirred", sample.character_id),
		"owned_portal_keys": owner.call("admitted_portal_keys", peer),
		"last_waystones": personal.redesign_character.last_waystones.duplicate(true),
		"waystones_activated": personal.redesign_character.waystones_activated.duplicate(true),
		"waystone_positions": positions, "arch_positions": arches}

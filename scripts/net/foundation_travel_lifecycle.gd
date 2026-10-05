extends Node

## Owner UI/hazard observations have their own authenticated lifecycle. They
## never carry a travel action, position, destination, inventory or candidate.
## Host travel still resolves the registered body and its traversal/contact.
var _serial: int = 0
var _left: float = 0.0
var _observations: Dictionary = {}
const SAMPLE_FIELDS := ["character_id", "world_instance_id", "session_epoch", "realm", "damage_revision", "dialogue", "cutscene", "swimming", "flying", "downed", "station_ack_only", "ending_owner", "party_revision", "party_signature", "sequence"]
const OPTIONAL_SAMPLE_FIELDS := ["equipped_tool", "passive_clock_active", "party_identity"]

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
	var portal_ready: bool = owner.call("portal_runtime_ready") == true
	var stations := preload("res://scripts/build/station_rules.gd").config()
	var forge_ready: bool = stations.get("runtime_enabled") == true and stations.get("forge", {}).get("runtime_enabled") == true
	if not portal_ready and not forge_ready: return
	if owner.call("is_host") == true:
		# HomeKeyChannels owns host cancellation and observer cleanup together.
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
	var swimming := swimming_observation(realm, actor.get("swim_controller"))
	var fly: Node = actor.get("fly_controller")
	var downed: Node = game.get_node_or_null(^"DownedState")
	var vitals: RefCounted = actor.get("vitals")
	if swimming.is_empty() or fly == null or downed == null or vitals == null: return {}
	var input_owner: Node = preload("res://scripts/ui/input_owner.gd").current(get_tree())
	var key: Node = game.get_node_or_null(^"HomeKey")
	var dialogue: bool = false
	var cutscene: bool = input_owner != null and input_owner != key
	var other_dialogue: bool = false
	var fading: bool = false
	for node: Node in get_tree().get_nodes_in_group("progression_restore"):
		if world_node.is_ancestor_of(node) and node.has_method("is_fading") and node.call("is_fading") == true:
			cutscene = true
			fading = true
	for node: Node in get_tree().get_nodes_in_group("story_modal"):
		if node.has_method("is_open") and node.call("is_open") == true:
			dialogue = true
			if node != owner: other_dialogue = true
	var ending_owner: bool = false
	if realm == "meadows" and input_owner != null:
		for source: Node in world_node.find_children("*", "Node", true, false):
			if source.get_script() != preload("res://scripts/story/sequence_director.gd"): continue
			var prompt: Node3D = source.get("_grandpa_prompt")
			if prompt == null or actor.global_position.distance_to(prompt.global_position) > float(prompt.get("radius")): continue
			var credits: Node = source.get("_regional_credits")
			if source.call("owns_regional_presentation", input_owner, game) == true: ending_owner = true
			if credits != null and input_owner == credits and credits.get("_expected_character_id") == game.get("local").character_id \
				and credits.get("_expected_world") == game.get("world"): ending_owner = true
	var party: RefCounted = game.get("party")
	if party == null or not preload("res://scripts/story/regional_homecoming.gd").valid_party(party): return {}
	return {"character_id": game.get("local").character_id, "world_instance_id": game.get("world").reward_delivery_namespace,
		"session_epoch": owner.call("_altar_current_epoch"), "realm": realm,
		"damage_revision": vitals.get("damage_revision"), "dialogue": dialogue, "cutscene": cutscene,
		"swimming": swimming.swimming, "flying": bool(fly.call("is_flying")), "downed": bool(downed.call("is_downed")),
		"station_ack_only": input_owner == owner and owner.call("owns_input") == true and not other_dialogue and not fading,
		"equipped_tool": str(game.get("equipped_tool")),
		"passive_clock_active": local_passive_clock_active(game, owner),
		"ending_owner": ending_owner, "party_revision": int(party.get("revision")),
		"party_signature": preload("res://scripts/story/regional_homecoming.gd").party_signature(party),
		"party_identity": preload("res://scripts/story/regional_homecoming.gd").party_identity_signature(party)}

## D102 multiplayer modals do not pause Game. Use actual processing and the
## existing transaction fence, never dialogue/cutscene/input ownership flags.
static func local_passive_clock_active(game: Node, owner: Node) -> bool:
	return game != null and owner != null and game.get("local") != null and game.can_process() and game.is_processing() \
		and owner.has_method("_owner_training_mutation_blocked") \
		and owner.call("_owner_training_mutation_blocked", game.get("local")) == false

## Water alone mounts SwimController. The other actual realm bodies have no
## swimming state; absence there is ordinary dry travel, not missing authority.
## Water still requires its installed observer, including on dry land.
static func swimming_observation(realm: String, controller: Node) -> Dictionary:
	if realm not in ["meadows", "water", "cloudreach", "stormwood"]: return {}
	if controller == null: return {} if realm == "water" else {"swimming": false}
	if not controller.has_method("is_swimming"): return {}
	var observed: Variant = controller.call("is_swimming")
	return {"swimming": observed} if observed is bool else {}

static func valid_sample(sample: Dictionary) -> bool:
	if sample.size() < SAMPLE_FIELDS.size() or sample.size() > SAMPLE_FIELDS.size() + OPTIONAL_SAMPLE_FIELDS.size(): return false
	for field: String in SAMPLE_FIELDS:
		if not sample.has(field): return false
	for field: Variant in sample:
		if field not in SAMPLE_FIELDS and field not in OPTIONAL_SAMPLE_FIELDS: return false
	if sample.has("equipped_tool") and (not sample.equipped_tool is String or sample.equipped_tool.length() > 96): return false
	if sample.has("passive_clock_active") and not sample.passive_clock_active is bool: return false
	if sample.has("party_identity") and (not sample.party_identity is String or sample.party_identity.length() != 64 \
		or not sample.party_identity.is_valid_hex_number(false)): return false
	for field: String in ["character_id", "world_instance_id", "session_epoch", "realm"]:
		if not sample.get(field) is String or sample[field].is_empty() or sample[field].length() > 192: return false
	for field: String in ["dialogue", "cutscene", "swimming", "flying", "downed", "ending_owner", "station_ack_only"]:
		if not sample.get(field) is bool: return false
	return sample.get("sequence") is int and sample.sequence > 0 \
		and sample.get("damage_revision") is int and sample.damage_revision >= 0 \
		and sample.get("party_revision") is int and sample.party_revision >= 0 \
		and sample.get("party_signature") is String and sample.party_signature.length() == 64 \
		and sample.party_signature.is_valid_hex_number(false)

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

## Cheap read of an already authenticated observation. This does not refresh
## admission, inspect geometry, or construct the portal host context. Legacy
## packets remain valid for travel but cannot authorize canonical elapsed time.
func host_passive_clock_active(peer: int) -> bool:
	var owner: Node = session()
	if owner == null or owner.call("is_host") != true or owner.call("is_active") != true: return false
	var observation: Dictionary = _observations.get(peer, {})
	if observation.is_empty(): return false
	var game: Node = owner.call("_game")
	if game == null or game.get("world") == null: return false
	var sample: Dictionary = observation.sample
	var age := Time.get_ticks_msec() - int(observation.seen_at)
	var timeout: float = float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.refresh_seconds) * 4.0
	return age >= 0 and age <= int(timeout * 1000.0) and sample.get("passive_clock_active") == true \
		and sample.character_id == owner.call("_authority_character", peer) \
		and sample.realm == owner.call("realm_of", peer) \
		and sample.session_epoch == owner.call("_altar_current_epoch") \
		and sample.world_instance_id == game.get("world").reward_delivery_namespace

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
		"station_ack_only": sample.station_ack_only,
		"equipped_tool": str(sample.get("equipped_tool", "")),
		"swimming": sample.swimming or aquatic.get("mode") != preload("res://scripts/player/swim_state.gd").Mode.LAND,
		"flying": sample.flying or actor.get("net_flying") == true or actor.get("net_carried") == true,
		"downed": sample.downed or (downed.get("_downed_peers") as Dictionary).has(peer), "home_key_owned": owner.call("_home_key_authoritative_owned", peer),
		"character_unlocks": personal.redesign_character.portal_unlocks.duplicate(),
		"world_unlocks": game.get("world").redesign_world.portal_unlocks.duplicate(),
		"character_stirred": owner.get("_character_authority").call("character_fifth_stirred", sample.character_id),
		"owned_portal_keys": owner.call("admitted_portal_keys", peer),
		"last_waystones": personal.redesign_character.last_waystones.duplicate(true),
		"waystones_activated": personal.redesign_character.waystones_activated.duplicate(true),
		"waystone_positions": positions, "arch_positions": arches}

## Diagnostic only: which gate the last host_ending_context refusal hit.
var ending_refusal := ""

func host_ending_context(peer: int) -> Dictionary:
	var owner: Node = session()
	var safety := host_context(peer)
	ending_refusal = "no_safe_sample" if safety.is_empty() else "realm_" + str(safety.realm)
	if safety.is_empty() or safety.realm != "meadows": return {}
	for hazard: String in ["combat", "swimming", "flying", "downed"]:
		ending_refusal = hazard
		if safety.get(hazard) != false: return {}
	var sample: Dictionary = _observations[peer].sample
	ending_refusal = "modal dialogue=%s cutscene=%s ending_owner=%s" % [str(safety.dialogue), str(safety.cutscene), str(sample.ending_owner)]
	if (safety.dialogue or safety.cutscene) and sample.ending_owner != true: return {}
	var world_node: Node3D = owner.call("_portal_world_node", "meadows")
	var nearby: bool = false
	for source: Node in world_node.find_children("*", "Node", true, false):
		if source.get_script() != preload("res://scripts/story/sequence_director.gd"): continue
		var prompt: Node3D = source.get("_grandpa_prompt")
		if prompt != null and safety.position.distance_to(prompt.global_position) <= float(prompt.get("radius")): nearby = true
	var world: RefCounted = owner.call("_game").get("world")
	ending_refusal = "not_at_farm" if not nearby else "world_flag"
	if not nearby or not world.flags.call("has", preload("res://scripts/story/regional_homecoming.gd").WORLD_FLAG): return {}
	var personal: Dictionary = owner.get("_character_authority").call("state", sample.character_id)
	var flags: Dictionary = owner.call("_foundation_flags", peer)
	ending_fields_refusal = ""
	var fields := ending_fields(personal, flags, sample)
	ending_refusal = "" if not fields.is_empty() else "ending_fields " + ending_fields_refusal
	return fields

static var ending_fields_refusal := ""

static func ending_fields(personal: Dictionary, flags: Dictionary, sample: Dictionary) -> Dictionary:
	ending_fields_refusal = "character_or_settled_flag"
	if personal.get("character_id") != sample.get("character_id") or flags.get("stormwood:legendary_ceremony_settled") != true: return {}
	var originals: Array[String] = []
	var answers: Array[String] = []
	for flag: String in flags:
		if flags[flag] != true: continue
		if flag.begins_with("stormwood:regional_outcome:"): originals.append(flag)
		if flag.begins_with("stormwood:legendary_answer:"): answers.append(flag)
	ending_fields_refusal = "outcome_flags"
	if originals.size() > 1 or (originals.is_empty() and answers.size() != 1): return {}
	var outcome: String = answers[0] if originals.is_empty() else originals[0].replace("stormwood:regional_outcome:", "stormwood:legendary_answer:")
	ending_fields_refusal = "outcome_answer"
	if not answers.has(outcome) or outcome.get_slice(":", outcome.get_slice_count(":") - 1) not in ["accepted", "refused"]: return {}
	var home: String = preload("res://scripts/story/regional_homecoming.gd").home_return_receipt(
		personal.get("redesign_character", {}).get("transaction_receipts", []),
		str(sample.world_instance_id), str(sample.character_id), outcome)
	var starter: String = ""
	for receipt: String in personal.get("redesign_character", {}).get("transaction_receipts", []):
		var prefix: String = "starter_choice:%s:" % sample.character_id
		if receipt.begins_with(prefix):
			var uid: String = receipt.trim_prefix(prefix)
			ending_fields_refusal = "starter_receipt"
			if uid.is_empty() or uid.contains(":") or (not starter.is_empty() and starter != uid): return {}
			starter = uid
	ending_fields_refusal = "home_return=" + str(not home.is_empty()) + " starter=" + str(not starter.is_empty())
	if home.is_empty() or starter.is_empty(): return {}
	var temporary: RefCounted = preload("res://autoload/party.gd").new()
	var mirrors: Dictionary = personal.redesign_character.get("creatures", {})
	for card: Dictionary in personal.get("party", []):
		var member: RefCounted = preload("res://scripts/save/water_capture_codec.gd").decode_owned(card, personal.redesign_character) \
			if mirrors.has(card.uid) else preload("res://scripts/save/water_capture_codec.gd").decode(card)
		ending_fields_refusal = "party_decode"
		if member == null or not temporary.call("add", member): return {}
	var homecoming := preload("res://scripts/story/regional_homecoming.gd")
	var signature: String = homecoming.party_signature(temporary)
	var identity: String = homecoming.party_identity_signature(temporary)
	while temporary.call("size") > 0: temporary.call("remove_at", 0)
	# The guest's live party keeps accruing passive care (landmarks walked
	# together) that this host copy only receives at owner-passive gates. The
	# same five with the same non-passive history is the same party: verify that
	# here and keep the guest's own full signature, which its intent carries.
	if sample.has("party_identity"):
		ending_fields_refusal = "party_identity"
		if identity.is_empty() or identity != sample.party_identity: return {}
		# Guest-attested: only its own presentation fence for this ack, never a
		# host-verified roster. Identity above is the host's check.
		signature = sample.party_signature
	else:
		ending_fields_refusal = "party_signature"
		if signature.is_empty() or signature != sample.get("party_signature"): return {}
	return {"world_instance_id": sample.world_instance_id, "session_epoch": sample.session_epoch,
		"character_id": sample.character_id, "outcome_id": outcome, "home_return_receipt": home,
		"party_revision": sample.party_revision, "party_signature": signature}

extends Node

## Explicit named-mechanics aid. This source exists only in PeerRunner;
## ordinary gameplay never installs it or exposes a request RPC.
const DISCLOSURE := {"scope": "named_mechanics_only", "self_hp_topups": true,
	"ally_placement": true, "enemy_hp_ceiling": 0, "earned_campaign_credit": false}
const EXACT := preload("res://scripts/creatures/essence.gd")
const ORIGINAL := preload("res://scripts/combat/accepted_action_host.gd")
const SCOPE := preload("res://scripts/net/combat_round_reward.gd")

var fixture_runner: WeakRef
var fixture_disclosure: Dictionary = {}
var _actor_vitals_proposals: Dictionary = {}
var _serial: int = 0
var _observations: Array = []

static func install(tree: SceneTree, disclosure: Dictionary) -> Node:
	if tree == null or tree.root == null or tree.get_script() == null \
		or tree.get_script().resource_path != "res://tools/net/peer_runner.gd" \
		or not EXACT._equivalent(disclosure, DISCLOSURE): return null
	var session: Node = tree.root.get_node_or_null(^"Game/Session")
	if session == null or session.call("is_host") != true: return null
	var provider_script: Script = load("res://tools/net/f48_actor_topup.gd")
	var existing: Node = tree.root.get_node_or_null(^"F48ActorTopup")
	if existing != null:
		var retained_runner: Variant = existing.get("fixture_runner")
		if existing.get_script() != provider_script \
			or not retained_runner is WeakRef or retained_runner.get_ref() != tree: return null
		return existing
	var provider: Node = provider_script.new()
	provider.name = "F48ActorTopup"
	provider.set("fixture_runner", weakref(tree))
	provider.set("fixture_disclosure", ORIGINAL._original(disclosure))
	tree.root.add_child(provider)
	return provider

func observations() -> Array:
	return _observations.duplicate(true)

func unresolved() -> bool:
	for original: Dictionary in _actor_vitals_proposals.values():
		if original.get("presented") != true: return true
	return false

func request_topup(director: Node, manager: Node) -> Dictionary:
	if not _installed() or not is_instance_valid(director) or not is_instance_valid(manager):
		return _refuse("fixture_source_required")
	var session: Node = get_node_or_null(^"/root/Game/Session")
	var id: String = str(manager.call("encounter_id"))
	var progress: Dictionary = get_tree().get("_trainer_fight_progress")
	if session == null or session.call("is_host") != true \
		or get_tree().get("_role") != "host" or progress.get("running") != true \
		or get_tree().get("_trainer_fight_director") != director \
		or get_tree().get("_trainer_fight_observed_encounter_id") != id \
		or director.get("_session") != session or director.get("_manager") != manager \
		or director.call("uses_durable_trainer_rewards", id) != true:
		return _refuse("actual_owned_host_warden_required")
	for original: Dictionary in _actor_vitals_proposals.values():
		if original.get("presented") != true:
			_retry(original)
			return original.get("result", {"ok": true, "pending": true, "code": "fixture_owner_save_pending"}).duplicate(true)
	if director.call("ordinary_actor_vitals_pending", id) != false:
		return {"ok": true, "pending": true, "code": "original_health_change_pending"}
	var host: RefCounted = director.get("_encounter_host")
	var record: Dictionary = host.call("record", id) if host != null else {}
	var scope: Dictionary = record.get("ordinary_combat_reward_owner", {})
	var game: Node = session.call("_game")
	var world: RefCounted = game.get("world") if game != null else null
	var peer: int = int(session.call("local_peer_id"))
	var character: String = str(session.call("_authority_character", peer))
	var registry: RefCounted = session.call("registry")
	if record.get("phase") != "active" or record.get("kind") != "boss" \
		or not SCOPE.scope_valid(scope) or scope.trainer_id != "warden_aldis" \
		or scope.encounter_id != id or world == null \
		or scope.world_namespace != world.get("reward_delivery_namespace") \
		or scope.session_id != session.call("_altar_current_epoch") \
		or scope.realm != preload("res://scripts/data/biome_order.gd").canonical_id(str(session.call("realm_of", peer))) \
		or character.is_empty() or registry.call("peer_for_character", character) != peer:
		return _refuse("actual_owned_host_warden_required")
	var body: Node3D = director.call("deployed_body_for", peer)
	var binding: Dictionary = director.call("_ordinary_actor_binding", id, peer, body)
	if binding.is_empty() or not is_instance_valid(body): return _refuse("actual_actor_required")
	var uid: String = str(binding.creature_uid)
	var actor: Dictionary = host.call("actor_vitals", id, peer, uid, int(binding.actor_generation))
	var mine: RefCounted = manager.call("active_creature")
	if actor.is_empty() or mine == null or mine.get("uid") != uid \
		or not EXACT._equivalent(mine.get("hp"), actor.hp) \
		or not EXACT._equivalent(mine.get("max_hp"), actor.max_hp) \
		or mine.get("fainted") != actor.fainted: return _refuse("fixture_live_vitals_conflict")
	if actor.fainted or float(actor.hp) <= 0.0: return _refuse("fixture_cannot_revive")
	if float(actor.hp) == float(actor.max_hp): return {"ok": true, "pending": false, "code": "already_full"}
	var limit: int = int(preload("res://scripts/combat/combat_math.gd").config().get("utility_limits", {}).get("receipt_limit_per_encounter", 0))
	if limit < 1 or int(director.call("_ordinary_actor_proposal_count", id)) >= limit:
		return _refuse("fixture_receipt_capacity")
	_serial += 1
	var action_id: String = "%s:f48-topup:%d" % [id, _serial]
	var proposal: Dictionary = host.call("stage_actor_vitals", id, peer, uid, int(binding.actor_generation),
		int(actor.revision), action_id, "heal", float(actor.max_hp) - float(actor.hp), limit)
	if proposal.get("ok") != true: return _refuse(str(proposal.get("code", "fixture_stage_refused")))
	var original: Dictionary = {"encounter_id": id, "peer_id": peer,
		"proposal": ORIGINAL._original(proposal), "character_revision": int(session.call("admitted_character_revision", peer)),
		"binding": ORIGINAL._original(binding), "host_record": ORIGINAL._original(host.call("record", id)),
		"fixture_provider": weakref(self), "fixture_source": ORIGINAL._original({"scope": scope,
			"world_id": world.get("world_id"), "character_id": character, "creature_uid": uid,
			"body_instance_id": body.get_instance_id(), "body_generation": binding.actor_generation}),
		"fixture_disclosure": fixture_disclosure, "director": weakref(director),
		"fixture_driver_source": ORIGINAL._original({"started_ms": progress.get("started_ms"),
			"started_physics_frame": progress.get("started_physics_frame"), "encounter_id": id}),
		"committed": false, "presented": false}
	_actor_vitals_proposals[action_id] = original
	var pending: Dictionary = director.get("_ordinary_actor_vitals_proposals")
	pending[action_id] = original # Same retained original fences combat BEFORE any writer.
	_observations.append({"action_id": action_id, "encounter_id": id, "peer_id": peer,
		"character_id": character, "uid": uid, "body_generation": binding.actor_generation,
		"before": proposal.hp_before, "after": proposal.hp_after,
		"receipt": proposal.settlement_receipt.duplicate(true), "resolved": false})
	original["observation_index"] = _observations.size() - 1
	director.call("_host_after_encounter_change", id)
	_retry(original)
	return original.get("result", {}).duplicate(true)

func _installed() -> bool:
	if not is_inside_tree() or is_queued_for_deletion() or fixture_runner == null: return false
	var runner: Object = fixture_runner.get_ref() if fixture_runner != null else null
	return is_instance_valid(runner) and runner == get_tree() and runner.get_script() != null \
		and runner.get_script().resource_path == "res://tools/net/peer_runner.gd" \
		and get_parent() == get_tree().root and name == &"F48ActorTopup" \
		and EXACT._equivalent(fixture_disclosure, DISCLOSURE)

func _process(_delta: float) -> void:
	if not _installed(): return
	for original: Dictionary in _actor_vitals_proposals.values():
		if original.get("presented") != true: _retry(original)

func _retry(original: Dictionary) -> void:
	var director: Node = original.director.get_ref()
	var session: Node = get_node_or_null(^"/root/Game/Session")
	if not is_instance_valid(director) or session == null \
		or not session.has_method("ordinary_fixture_actor_topup_commit"): return
	var result: Dictionary = session.call("ordinary_fixture_actor_topup_commit", self, director,
		str(original.encounter_id), int(original.peer_id), original.proposal)
	original["result"] = {"ok": true, "pending": result.get("resolved") != true,
		"code": str(result.get("code", "fixture_owner_save_pending")),
		"action_id": original.proposal.action_id, "receipt": original.proposal.settlement_receipt.duplicate(true)}
	var observed: Dictionary = _observations[int(original.observation_index)]
	observed["result"] = result.duplicate(true)
	if result.get("resolved") == true:
		original["presented"] = true
		observed["resolved"] = true
		director.call("_host_after_encounter_change", str(original.encounter_id))

static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "pending": false, "code": code}

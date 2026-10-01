extends RefCounted

## Owned Training adapter for the director's REAL accepted killing-hit hook.
## No RPC, fake ledger, local award fallback, new balance or save writer.
## Capture BEFORE done-record/verdict publication; Foundation owns settlement.
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const DIRECTOR_PATH := "res://scripts/combat/encounter_director.gd"
const LEDGER_PATH := "res://scripts/net/encounter_host.gd"
const RUNTIME_PATH := "res://scripts/combat/shared_wild_host_fight.gd"


static func _inherits(actual: Object, path: String) -> bool:
	if actual == null or not is_instance_valid(actual): return false
	var script: Script = actual.get_script()
	while script != null:
		if script.resource_path == path: return true
		script = script.get_base_script()
	return false


static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "resolved": false, "code": code}


## accepted is the director's own verdict after rolled damage was merged and
## EncounterHost.set_opponent_hp committed. The numeric contents never come
## from a remote reward claim or the debug latest_strike_receipt reader.
static func capture_accepted_defeat(director: Node, encounter_id: String,
		accepted: Dictionary) -> Dictionary:
	if not _inherits(director, DIRECTOR_PATH) or not director.is_inside_tree() \
			or not ESSENCE._opaque_id(encounter_id): return _refuse("actual_defeat_director_required")
	var host: Variant = director.call("is_encounter_host")
	if not host is bool or host != true: return _refuse("actual_defeat_host_required")
	var game := director.get_node_or_null(^"/root/Game")
	var session: Variant = director.get("_session")
	if game == null or not session is Node or not is_instance_valid(session) \
			or game.get("session") != session \
			or not session.has_method("_host_wild_training_context"):
		return _refuse("wild_training_authority_unavailable")
	var context: Variant = session.call("_host_wild_training_context")
	var world: Variant = game.get("world")
	if not context is Dictionary or not context.get("ready") is bool or context.ready != true \
			or not world is RefCounted or context.get("world_id") != world.get("world_id") \
			or context.get("world_namespace") != world.get("reward_delivery_namespace") \
			or not ESSENCE._opaque_id(context.get("world_id")) \
			or not ESSENCE._opaque_id(context.get("world_namespace")) \
			or not ESSENCE._opaque_id(context.get("session_id")):
		return _refuse("wild_training_authority_unavailable")
	var ledger: Variant = director.get("_encounter_host")
	var runtime: Variant = director.call("_shared_host_fight", encounter_id)
	if not ledger is RefCounted or not _inherits(ledger, LEDGER_PATH) \
			or not runtime is Node or not _inherits(runtime, RUNTIME_PATH) \
			or not runtime.is_inside_tree() or runtime.get("authority_link") != director:
		return _refuse("actual_defeat_ledger_body_required")
	var record: Variant = ledger.call("record", encounter_id)
	var body: Variant = runtime.call("body")
	if not record is Dictionary or record.get("encounter_id") != encounter_id \
			or record.get("kind") != "wild" or not record.get("phase") in ["active", "resolving", "done"] \
			or not body is Node3D or not is_instance_valid(body) or not body.is_inside_tree() \
			or runtime.get("authority_body") != body or not record.get("opponent") is Dictionary \
			or not ESSENCE._equivalent(runtime.get("body_generation"), record.opponent.get("body_generation")):
		return _refuse("actual_defeat_ledger_body_required")
	var enemy: Variant = body.get("instance")
	if not enemy is RefCounted: return _refuse("actual_dead_wild_required")
	var snapshot := CODEC.encode(enemy)
	if snapshot.is_empty() or not snapshot.get("fainted") is bool or snapshot.fainted != true \
			or not ESSENCE._integer(snapshot.get("hp"), 0, 0) \
			or not ESSENCE._integer(record.opponent.get("hp"), 0, 0) \
			or record.opponent.get("species_id") != snapshot.get("species_id") \
			or not record.opponent.get("card") is Dictionary \
			or record.opponent.card.get("uid") != snapshot.get("uid"):
		return _refuse("actual_dead_wild_required")
	if not accepted.get("ok") is bool or accepted.ok != true \
			or accepted.get("kind") != "strike_intent" or not accepted.get("delta") is Dictionary \
			or not ESSENCE._integer(accepted.get("peer"), 1, 2147483647) \
			or not record.get("participants") is Dictionary \
			or not record.participants.has(int(accepted.peer)):
		return _refuse("actual_accepted_killing_hit_required")
	var delta: Dictionary = accepted.delta
	var damage: Variant = delta.get("damage")
	if delta.get("encounter_id") != encounter_id or not delta.get("hit") is bool or delta.hit != true \
			or not delta.get("killed") is bool or delta.killed != true \
			or not (damage is int or damage is float) or not is_finite(float(damage)) or float(damage) <= 0.0 \
			or not ESSENCE._integer(delta.get("hp"), 0, 0) \
			or not ESSENCE._equivalent(delta.get("hp_max"), snapshot.get("max_hp")):
		return _refuse("actual_accepted_killing_hit_required")
	var cfg := ESSENCE.config()
	var mode: Variant = cfg.get("wild_victory_xp_mode")
	if not mode is String or not mode in ["ordinary", "hybrid"]:
		return _refuse("invalid_defeat_XP_policy")
	var identity := [context.world_namespace, context.session_id, record.get("realm"),
		encounter_id, int(record.opponent.get("body_generation")), snapshot.get("uid")]
	var peers: Array = record.participants.keys()
	for peer: Variant in peers:
		if not peer is int or peer < 1: return _refuse("invalid_defeat_participants")
	peers.sort()
	var deployments: Array[Dictionary] = []
	for peer: int in peers:
		var deployed: Variant = director.call("deployed_body_for", peer)
		var card: Variant = director.call("_creature_card_for", peer)
		if not deployed is Node3D or not is_instance_valid(deployed) or not deployed.is_inside_tree() \
				or not card is Dictionary or not ESSENCE._component(card.get("creature_uid")):
			return _refuse("actual_defeat_deployment_required")
		# Only the actual deployed UID is frozen here. Foundation derives the
		# stable character and full eight-field baseline from SAME registry;
		# neither the join packet's character nor the masked combat view is used.
		deployments.append({"peer_id": peer, "active_uid": card.creature_uid})
	return {"ok": true, "source_id": "wild_defeat:" + JSON.stringify(identity).sha256_text(),
		"xp_mode": mode, "world_id": context.world_id, "world_namespace": context.world_namespace,
		"session_id": context.session_id, "record": record.duplicate(true),
		"enemy_record": snapshot.duplicate(true), "accepted": accepted.duplicate(true),
		"deployments": deployments}


## Direct host-internal call only. Missing typed producer refuses. After the
## host retains/journals this frozen source, retries use the original event;
## never read a respawned body, new deployment, changed mode or new epoch.
static func submit_frozen_source(director: Node, frozen: Dictionary) -> Dictionary:
	# Caller must FIRST retain this immutable capture on the actual runtime;
	# even a failed/precommit/full-bag submission cannot erase an earned kill.
	if not _inherits(director, DIRECTOR_PATH) or not director.is_inside_tree():
		return _refuse("actual_defeat_director_required")
	var session: Variant = director.get("_session")
	if not session is Node or not is_instance_valid(session) \
			or not session.has_method("_commit_host_wild_victory"):
		return _refuse("wild_training_writer_unavailable")
	# Foundation validates actual authority/context/admission and reconciles
	# original durable rows before any new stage. No source rebuilding here.
	var result: Variant = session.call("_commit_host_wild_victory", frozen.duplicate(true))
	return result.duplicate(true) if result is Dictionary else _refuse("decision_unavailable")

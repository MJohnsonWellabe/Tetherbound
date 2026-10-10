extends Node

## Presents only an actual retained host catch offer. The full-character row
## remains the sole ownership decision and the existing owner BOOL/ACK ends it.
signal release_completed(release_id: String, result: Dictionary)
const EVENT := preload("res://scripts/net/foundation_event.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const RULES := preload("res://scripts/net/foundation_capture_rules.gd")
var _active := ""
var _quotes: Dictionary = {}
var _requests: Dictionary = {}
var _left := 0.0

func session() -> Node:
	return get_parent().get_parent()

func _ready() -> void:
	session().connect("foundation_reply_received", _reply)

func _offer(id: String = "", include_decided: bool = false) -> Dictionary:
	var game: Node = session().call("_game")
	if game == null or game.local == null or game.world == null: return {}
	for row: Variant in game.world.reward_deliveries.values():
		if not EVENT.valid(row, game.world.reward_delivery_namespace, game.world.world_id): continue
		for duty: Dictionary in row.duties:
			if duty.action != "capture_offer" or duty.character_id != game.local.character_id or duty.context.realm != game.current_realm: continue
			if not id.is_empty() and duty.context.offer_id != id: continue
			var receipt := RULES.receipt(duty.context.offer_id, duty.character_id)
			var latest: Variant = game.world.reward_deliveries.get(preload("res://scripts/creatures/essence.gd").training_delivery_id(game.world.reward_delivery_namespace, duty.character_id))
			if not include_decided and game.local.redesign_character.transaction_receipts.has(receipt) \
				and latest is Dictionary and load("res://autoload/world_state.gd").call("training_row_valid", latest, game.world.reward_delivery_namespace, game.world.world_id) == true:
				# A later v2/v3 mutation can replace the accepted capture row with
				# its own pending row. Its frozen BEFORE carries only the already
				# accepted prefix (make_record requires an accepted predecessor).
				# Pending AFTER alone still proves no owner save/ACK for a catch.
				var prior_capture: bool = latest.version in [2, 3] and int(latest.journal_revision) > 1 \
					and latest.before.redesign_character.transaction_receipts.has(receipt)
				if prior_capture or (latest.status == "accepted" and latest.after.redesign_character.transaction_receipts.has(receipt)): continue
			return duty.context.duplicate(true)
	return {}

func present_from_catch(creature: RefCounted) -> bool:
	var offer := _offer()
	if offer.is_empty() or creature == null or creature.get("uid") != offer.creature.uid: return false
	return _present(offer, creature)

## Synchronous local terminal-catch completion. Use the same journal, owner
## writer, accepted world writer and registry ACK as deferred reconciliation.
## A full belt still opens the existing ceremony; it never auto-adds a sixth.
func complete_local_catch(creature: RefCounted) -> bool:
	if creature == null or session().call("is_host") != true: return false
	var game: Node = session().call("_game")
	if game == null or game.local == null or game.world == null: return false
	var offer: Dictionary = {}
	for row: Variant in game.world.reward_deliveries.values():
		if not EVENT.valid(row, game.world.reward_delivery_namespace, game.world.world_id): continue
		for duty: Dictionary in row.duties:
			if duty.action == "capture_offer" and duty.character_id == game.local.character_id \
				and duty.context.realm == game.current_realm and duty.context.creature.uid == creature.get("uid"):
				offer = duty.context.duplicate(true)
	if offer.is_empty() or not RULES.offer_valid(offer): return false
	var receipt := RULES.receipt(offer.offer_id, game.local.character_id)
	var world_script := load("res://autoload/world_state.gd") as GDScript
	var owner_row: Dictionary = world_script.training_owner_row(game.world.reward_deliveries,
		game.world.reward_delivery_namespace, game.world.world_id, game.local.character_id)
	var same_row: bool = owner_row.get("action") == "wild_capture" \
		and owner_row.get("intent", {}).get("offer_id") == offer.offer_id \
		and owner_row.get("source_key") == offer.source_key and owner_row.get("receipt") == receipt
	if not same_row:
		if not _present(offer, creature): return false
		if game.local.party.is_full(): return true
		var view: Dictionary = session().call("homestead_personal_view")
		if view.is_empty() or not view.get("registry_revision") is int: return false
		_send({"offer_id": offer.offer_id, "keep": true, "released_uid": ""}, int(view.registry_revision), "")
		owner_row = world_script.training_owner_row(game.world.reward_deliveries,
			game.world.reward_delivery_namespace, game.world.world_id, game.local.character_id)
	if owner_row.get("action") != "wild_capture" or owner_row.get("character_id") != game.local.character_id \
		or owner_row.get("intent", {}).get("offer_id") != offer.offer_id \
		or owner_row.get("source_key") != offer.source_key or owner_row.get("receipt") != receipt: return false
	var ledger := session().get_node_or_null(^"LedgerRpc")
	if ledger == null or ledger.call("reconcile_creature_training_before_ready") != true: return false
	owner_row = game.world.reward_deliveries.get(owner_row.delivery_id, {})
	var decision: Dictionary = session().call("_foundation_decision", session().call("local_peer_id"), owner_row)
	if decision.get("resolved") != true or decision.get("saved") != true or decision.get("owner_acknowledged") != true: return false
	var matches := 0
	for member: RefCounted in game.local.party.members():
		if member.get("uid") == creature.get("uid"): matches += 1
	if matches != 1 or not game.local.redesign_character.transaction_receipts.has(receipt): return false
	# Reconciliation can finish after _send returned an unresolved decision.
	# Retire only this saved, acknowledged offer before exploration resumes.
	_complete(owner_row.intent, decision, "")
	return true

func owns_pending_capture(creature: RefCounted) -> bool:
	if creature == null or _active.is_empty() \
		or creature.get_meta("foundation_capture_offer", "") != _active: return false
	var offer := _offer(_active, true)
	return not offer.is_empty() and creature.get("uid") == offer.creature.uid

func _bind_release_service() -> bool:
	var mounted := false
	for node: Node in get_tree().root.find_children("*", "Control", true, false):
		if node.get_script() == null or node.get_script().resource_path != "res://scripts/ui/tab_creatures.gd": continue
		if node.call("configure_release_service", self) != true: return false
		mounted = true
	return mounted

func _present(offer: Dictionary, creature: RefCounted = null) -> bool:
	var game: Node = session().call("_game")
	if session().call("_altar_peer_in_combat", session().call("local_peer_id")) == true: return false
	# Game can open and poll the ceremony as soon as pending_catch is set.
	# Bind its typed authority first on both direct-catch and retained-offer paths.
	if not _bind_release_service(): return false
	if game.pending_catch != null:
		return game.pending_catch.get_meta("foundation_capture_offer", "") == offer.offer_id
	if creature == null: creature = CODEC.decode(offer.creature, offer.capture_traits)
	if creature == null: return false
	creature.set_meta("foundation_capture_offer", offer.offer_id)
	_active = offer.offer_id
	game.pending_catch = creature
	return true

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 0.5
	if preload("res://scripts/repeatables/alpha_respawns.gd").config().get("runtime_enabled") != true \
		and not preload("res://scripts/creatures/traits.gd").runtime_enabled(): return
	var game: Node = session().call("_game")
	if game == null or game.local == null or game.world == null: return
	for id: String in _requests.keys(): reconcile_release(id)
	if not _active.is_empty() and _offer(_active).is_empty():
		if game.pending_catch != null and game.pending_catch.get_meta("foundation_capture_offer", "") == _active: game.pending_catch = null
		_active = ""
	var offer := _offer(_active)
	if offer.is_empty(): return
	if not _present(offer): return
	_active = offer.offer_id
	if game.local.party.is_full(): return
	var view: Dictionary = session().call("homestead_personal_view")
	if view.is_empty() or not view.get("registry_revision") is int: return
	_send({"offer_id": _active, "keep": true, "released_uid": ""}, int(view.registry_revision), "")

func quote_release(pending_uid: String, released_uid: String) -> Dictionary:
	var offer := _offer(_active)
	if offer.is_empty() or offer.creature.uid != pending_uid: return {}
	var intent := {"offer_id": _active, "keep": not released_uid.is_empty(), "released_uid": released_uid}
	var key := JSON.stringify(intent)
	if _quotes.has(key): return _quotes[key].duplicate(true)
	var result: Dictionary = session().call("_foundation_send", "wild_capture_quote", offer.source_key, intent, -1)
	if session().call("is_host") == true: return result
	return _quotes.get(key, {}).duplicate(true)

func submit_release(request: Dictionary) -> void:
	var offer := _offer(_active)
	if offer.is_empty() or request.get("ceremony_id") != _active or request.get("pending_uid") != offer.creature.uid \
		or not request.get("released_uid") is String or not request.get("release_id") is String \
		or not request.get("expected_character_revision") is int: return
	var intent := {"offer_id": _active, "keep": not str(request.released_uid).is_empty(), "released_uid": request.released_uid}
	_requests[request.release_id] = {"intent": intent.duplicate(true), "revision": request.expected_character_revision}
	_send(intent, request.expected_character_revision, request.release_id)

func reconcile_release(id: String) -> void:
	if not _requests.has(id): return
	var request: Dictionary = _requests[id]
	_send(request.intent, request.revision, id)

func _send(intent: Dictionary, revision: int, release_id: String) -> void:
	var offer := _offer(intent.offer_id, true)
	if offer.is_empty(): return
	var result: Dictionary = session().call("_foundation_send", "wild_capture", offer.source_key, intent, revision)
	if session().call("is_host") == true: _complete(intent, result, release_id)

func _reply(envelope: Dictionary, result: Dictionary) -> void:
	if envelope.get("op") == "wild_capture_quote":
		_quotes[JSON.stringify(envelope.intent)] = result.duplicate(true)
	elif envelope.get("op") == "wild_capture":
		var id := ""
		for key: String in _requests:
			if _requests[key].intent == envelope.intent: id = key
		_complete(envelope.intent, result, id)

func _complete(intent: Dictionary, result: Dictionary, release_id: String) -> void:
	if result.get("ok") != true and result.get("resolved") == true: _quotes.clear()
	if result.get("ok") == true and result.get("resolved") == true:
		var game: Node = session().call("_game")
		if game.pending_catch != null and game.pending_catch.get_meta("foundation_capture_offer", "") == intent.offer_id: game.pending_catch = null
		_active = ""
		_quotes.clear()
	if not release_id.is_empty():
		if result.get("resolved") == true: _requests.erase(release_id)
		release_completed.emit(release_id, result.duplicate(true))

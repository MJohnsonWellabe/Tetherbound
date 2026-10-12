extends Node
## Scene/UI adapter over Foundation's authenticated action doorway. This owns
## no admission map or persistence. Bind only from the actual host/session
## composition; the callback performs identity/proximity/CAS/save/ACK checks.
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")
const PANEL := preload("res://scripts/masters/breakthrough_panel.gd")
const SITE := preload("res://scripts/masters/master_site.gd")
var _submit: Callable
var _view: Callable
var _panel: Control
var _producer: Object
var _duel_preparing := false
var _duel_preparing_director: WeakRef
var _duel_preparation_generation := 0
## A guest's chest press refused only for the moment (its own earlier owner
## checkpoint, such as the duel's win, is still settling, or its view of the
## admitted revision is a step behind) is held and sent again, so one press
## opens the chest. Bounded; anything else answers at once.
const CHEST_WAIT_CODES := ["awaiting_saved_decision", "owner_passive_checkpoint_pending"]
const CHEST_RETRY_CODES := ["owner_passive_original_pending", "owner_passive_prior_transaction_pending",
	"owner_passive_readmit_pending", "source_or_revision_changed"]
const CHEST_RETRY_SECONDS := 1.0
const CHEST_RETRIES := 60
var _chest_hold: Dictionary = {}

func bind_actions(submit_action: Callable, personal_view: Callable) -> bool:
	if not submit_action.is_valid() or not personal_view.is_valid(): return false
	if is_instance_valid(_producer) and _producer.has_signal("homestead_action_completed") and _producer.is_connected("homestead_action_completed", _action_completed):
		_producer.disconnect("homestead_action_completed", _action_completed)
	if is_instance_valid(_producer) and _producer.has_signal("foundation_reply_received") and _producer.is_connected("foundation_reply_received", _foundation_reply):
		_producer.disconnect("foundation_reply_received", _foundation_reply)
	if is_instance_valid(_producer) and _producer.has_signal("homestead_personal_view_completed") and _producer.is_connected("homestead_personal_view_completed", _view_completed):
		_producer.disconnect("homestead_personal_view_completed", _view_completed)
	_submit = submit_action
	_view = personal_view
	var producer: Object = _submit.get_object()
	_producer = producer
	if producer != null and producer.has_signal("homestead_action_completed") \
			and not producer.is_connected("homestead_action_completed", _action_completed):
		producer.connect("homestead_action_completed", _action_completed)
	if producer != null and producer.has_signal("foundation_reply_received") \
			and not producer.is_connected("foundation_reply_received", _foundation_reply):
		producer.connect("foundation_reply_received", _foundation_reply)
	if producer != null and producer.has_signal("homestead_personal_view_completed") \
			and not producer.is_connected("homestead_personal_view_completed", _view_completed):
		producer.connect("homestead_personal_view_completed", _view_completed)
	return true

## A guest's personal view answers asynchronously; an open panel built before
## it arrived re-reads it now.
func _view_completed() -> void:
	if is_instance_valid(_panel):
		_panel.call("view_arrived")

## Session already fenced this reply to the exact sent envelope. Admission
## failure has no saved reward; it releases the chooser for another attempt.
func _foundation_reply(envelope: Dictionary, result: Dictionary) -> void:
	if envelope.get("op") != "master_duel" or not envelope.get("intent") is Dictionary \
			or result.get("ok") != false or result.get("code") == "awaiting_saved_decision": return
	var refused := result.duplicate(true)
	refused.terminal_refusal = true
	_action_completed("master_duel", envelope.intent, refused)

func _action_completed(action: String, original: Dictionary, result: Dictionary) -> void:
	if action == "master_chest":
		if _chest_held(original, result): return
		if result.get("settled") == true or result.get("owner_saved") == true:
			_message("Ascension Feast recipe learned. Your Master rewards are saved. Cook your feast at home.")
			view()
		elif result.get("terminal_refusal") == true:
			_message(_chest_message(result))
	if is_instance_valid(_panel):
		_panel.call("accept_completion", action, original, result)

func submit(op: String, intent: Dictionary, source: Node) -> Dictionary:
	if not _submit.is_valid():
		return {"ok": false, "code": "breakthrough_producer_not_mounted", "reason": "Master and Kitchen integration is not ready."}
	# Source node stays local. It is not serialized as proof of reachability.
	var verdict: Variant = _submit.call(op, intent.duplicate(true), source)
	return verdict if verdict is Dictionary else {"ok": false, "code": "invalid_producer_verdict"}

## Choosing a challenger uses the same real party/deployment flow as entering
## a tournament. The host still admits the actual actor and owns the duel.
func prepare_duel(uid: String, site: Node3D) -> Dictionary:
	# Summoning owns a live body across its ground/nav awaits. Closing the
	# chooser cancels submission, but must not let another choice free that
	# body before the existing summon returns.
	if _duel_preparing and _duel_preparing_director != null and not is_instance_valid(_duel_preparing_director.get_ref()):
		_duel_preparing = false
	if _duel_preparing:
		return {"ok": false, "code": "deployment_pending", "reason": "Your companion is still taking the field. Try again when it is ready."}
	_duel_preparing = true
	_duel_preparation_generation += 1
	var generation := _duel_preparation_generation
	var result: Dictionary = await _prepare_duel(uid, site)
	if generation == _duel_preparation_generation:
		_duel_preparing = false
		_duel_preparing_director = null
	return result

func _prepare_duel(uid: String, site: Node3D) -> Dictionary:
	var producer: Object = _submit.get_object() if _submit.is_valid() else null
	if not is_instance_valid(producer) or not is_instance_valid(site) \
			or not producer.has_method("_game") or not producer.has_method("_foundation_master_director") \
			or not producer.has_method("personal_tm_scope"):
		return {"ok": false, "code": "breakthrough_producer_not_mounted"}
	var scope: Dictionary = producer.call("personal_tm_scope")
	var game: Node = producer.call("_game")
	var owner: RefCounted = game.get("local") if is_instance_valid(game) else null
	var party: RefCounted = owner.get("party") if owner != null else null
	var director: Node = producer.call("_foundation_master_director", site)
	if scope.is_empty() or party == null or not is_instance_valid(director):
		return {"ok": false, "code": "character_context_unavailable"}
	_duel_preparing_director = weakref(director)
	if director.call("trainer_battle_active") == true or not str(director.get("_shared_active_id")).is_empty() \
			or (is_instance_valid(director.get("_manager")) and director.get("_manager").call("is_fighting") == true):
		return {"ok": false, "code": "combat_active", "reason": "Finish your current fight before challenging a Master."}
	var members: Array = party.call("members")
	var chosen: RefCounted
	var index := -1
	for i: int in range(members.size()):
		if str(members[i].get("uid")) != uid: continue
		if chosen != null: return {"ok": false, "code": "ambiguous_owned_creature"}
		chosen = members[i]
		index = i
	if chosen == null or chosen.get("fainted") == true or chosen.get("resting") == true \
			or float(chosen.get("hp")) <= 0:
		return {"ok": false, "code": "conscious_owned_creature_required", "reason": "Choose an awake, conscious companion."}
	if party.call("set_active", index) != true:
		return {"ok": false, "code": "character_selection_refused"}
	if director.call("ally_instance") != chosen:
		director.call("dismiss_active_creature")
		if not bool(await director.call("summon_active_creature")):
			return {"ok": false, "code": "deployment_unavailable", "reason": "Your companion could not take the field. Try again."}
	if not is_instance_valid(producer) or not _submit.is_valid() or _submit.get_object() != producer or not is_instance_valid(site) \
			or not is_instance_valid(director) or producer.call("personal_tm_scope") != scope \
			or not is_instance_valid(game) or producer.call("_game") != game or game.get("local") != owner or owner.get("party") != party \
			or party.call("active") != chosen or director.call("ally_instance") != chosen:
		return {"ok": false, "code": "character_context_changed"}
	if director.call("ally_deployment_ready") != true:
		return {"ok": false, "code": "deployment_pending", "reason": "Your companion is still taking the field. Try again when it is ready."}
	return {"ok": true}

func view() -> Dictionary:
	if not _view.is_valid(): return {}
	var state: Variant = _view.call()
	return state if state is Dictionary else {}

func retained_transaction(actions: Array) -> Dictionary:
	var producer: Object = _submit.get_object() if _submit.is_valid() else null
	return producer.call("retained_training_transaction", actions) \
		if producer != null and producer.has_method("retained_training_transaction") else {}

func mount_biome(world: Node3D, player: Node3D, runtime_biome: String) -> void:
	if not is_instance_valid(world) or not is_instance_valid(player) or not world.is_inside_tree() \
		or not player.is_inside_tree() or not world.is_ancestor_of(player): return
	for row: Dictionary in BREAKTHROUGH.masters().get("masters", []):
		if BIOMES.runtime_id(str(row.biome)) != runtime_biome: continue
		var retained := retained_site(world, str(row.id))
		if retained.status != "absent":
			if retained.status == "owned":
				var npc: Node = retained.site.get_node_or_null(^"Master")
				if npc != null and npc.has_method("set_player"): npc.call("set_player", player)
			continue # Never duplicate or adopt a foreign/ambiguous authored site.
		var scene: Variant = load(str(row.scene))
		if not scene is PackedScene: continue
		var site: Node3D = scene.instantiate()
		world.add_child(site)
		site.set_meta("breakthrough_service", self)
		if not site.call("mount", world, player):
			site.queue_free()
			continue
		site.connect("challenge_requested", _challenge)
		site.connect("chest_requested", _chest)

## Read-only ownership lookup. It is also usable by detached source controls;
## mount_biome supplies the separate live world/occupant readiness fence.
func retained_site(world: Node3D, master_id: String) -> Dictionary:
	if not is_instance_valid(world): return {"status": "unavailable"}
	var found: Node3D
	var candidates: Array[Node] = []
	if world.is_inside_tree():
		for node: Node in world.get_tree().get_nodes_in_group(SITE.FOUNDATION_GROUP):
			if world.is_ancestor_of(node): candidates.append(node)
	else:
		candidates = world.find_children("*", "Node3D", true, false)
	for candidate: Node in candidates:
		if candidate.get_script() != SITE or candidate.get("master_id") != master_id: continue
		if found != null: return {"status": "ambiguous"}
		found = candidate as Node3D
	if found == null: return {"status": "absent"}
	if not found.has_meta("breakthrough_service") or found.get_meta("breakthrough_service") != self or found.get("_mounted") != true \
		or found.is_queued_for_deletion(): return {"status": "foreign_or_unready"}
	return {"status": "owned", "site": found}

func _challenge(site: Node3D) -> void:
	_open("duel", site, str(site.get("master_id")))

func _chest(site: Node3D) -> void:
	_chest_hold = {}
	_send_chest(site, CHEST_RETRIES)

func _send_chest(site: Node3D, retries: int) -> void:
	var intent := {"master_id": str(site.get("master_id"))}
	var verdict := submit("master_chest", intent, site)
	var code := str(verdict.get("code", ""))
	if verdict.get("ok") != true and (code in CHEST_WAIT_CODES or code in CHEST_RETRY_CODES):
		var first := _chest_hold.is_empty()
		_chest_hold = {"site": weakref(site), "intent": intent, "retries": retries, "wait": -1.0}
		if code in CHEST_RETRY_CODES: _hold_chest_retry(code)
		if first: _message("Opening the chest...")
		return
	_chest_hold = {}
	_message(_chest_message(verdict))

## The host's answer to the held press. A momentary refusal waits and sends the
## same press again; any other answer ends the hold and is shown as before.
func _chest_held(original: Dictionary, result: Dictionary) -> bool:
	if _chest_hold.is_empty() or original != _chest_hold.intent: return false
	var code := str(result.get("code", ""))
	# A stale-revision refusal changed nothing (the host marks it terminal for
	# this envelope); re-read the admitted revision and send again, as the
	# essence release service does.
	var retryable: bool = code in CHEST_RETRY_CODES and (result.get("terminal_refusal") != true or code == "source_or_revision_changed")
	if result.get("ok") != true and retryable and int(_chest_hold.retries) > 0:
		_hold_chest_retry(code)
		return true
	if result.get("ok") != true and result.get("terminal_refusal") != true and code in CHEST_WAIT_CODES:
		return true # Its own checkpoint is settling; the saved answer follows.
	_chest_hold = {}
	return false

func _hold_chest_retry(code: String) -> void:
	_chest_hold.retries = int(_chest_hold.retries) - 1
	_chest_hold.wait = CHEST_RETRY_SECONDS
	# A press judged on a stale admitted revision re-reads it before resending.
	if code == "source_or_revision_changed": view()

func _process(delta: float) -> void:
	if _chest_hold.is_empty() or float(_chest_hold.wait) < 0.0: return
	_chest_hold.wait = float(_chest_hold.wait) - delta
	if float(_chest_hold.wait) > 0.0: return
	var site: Node3D = _chest_hold.site.get_ref() as Node3D
	if not is_instance_valid(site) or site.get("_mounted") != true:
		_chest_hold = {}
		return
	_send_chest(site, int(_chest_hold.retries))

func _chest_message(result: Dictionary) -> String:
	if result.get("code") == "chest_pending_make_satchel_room":
		return "Your Master reward is waiting. Use your Home Key, store items at home, then return to this chest with room in your satchel."
	return str(result.get("reason", result.get("code", "")))

func open_kitchen(station: Node3D) -> void:
	_open("cook", station, "")

func open_feed() -> void:
	_open("feed", self, "")

## Only Session's fenced reply for this still-open ordinary chooser reaches
## this path. The selected actual local creature must still be the same UID.
func accept_duel_offer(intent: Dictionary, result: Dictionary) -> bool:
	if not is_instance_valid(_panel) or _panel.call("is_open") != true or _panel.get("_mode") != "duel" \
		or _panel.get("_service") != self or _panel.get("_master") != intent.get("master_id") \
		or _panel.get("_pending_action") != "master_duel" or _panel.get("_pending_intent") != intent:
		return false
	var site := _panel.get("_source") as Node3D
	var producer: Object = _submit.get_object() if _submit.is_valid() else null
	if not is_instance_valid(site) or producer == null or not producer.has_method("_foundation_master_director"): return false
	var director: Node = producer.call("_foundation_master_director", site)
	if director == null or director.call("accept_guest_master_offer", site, intent, result) != true: return false
	_panel.call("close")
	return true

func _open(mode: String, source: Node, master_id: String) -> void:
	if _panel == null:
		_panel = PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self, mode, source, master_id)

func _message(message: String) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game != null and not message.is_empty(): game.call("push_world_message", message)

func _exit_tree() -> void:
	if is_instance_valid(_producer) and _producer.has_signal("homestead_action_completed") and _producer.is_connected("homestead_action_completed", _action_completed):
		_producer.disconnect("homestead_action_completed", _action_completed)
	if is_instance_valid(_producer) and _producer.has_signal("foundation_reply_received") and _producer.is_connected("foundation_reply_received", _foundation_reply):
		_producer.disconnect("foundation_reply_received", _foundation_reply)
	if is_instance_valid(_producer) and _producer.has_signal("homestead_personal_view_completed") and _producer.is_connected("homestead_personal_view_completed", _view_completed):
		_producer.disconnect("homestead_personal_view_completed", _view_completed)
	if is_instance_valid(_panel): _panel.queue_free()

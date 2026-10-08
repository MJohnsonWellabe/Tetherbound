extends Node

## Mounted by Game; edits travel through Session's existing training journal.
signal loadout_completed(edit_id: String, result: Dictionary)
var _session: Node
var _pending: Dictionary = {}
var _quotes: Dictionary = {}

func configure(session: Node) -> void:
	_session = session
	session.connect("foundation_reply_received", _reply)

func quote_loadout(key: String, uid: String) -> Dictionary:
	if not is_instance_valid(_session): return {"ok": false}
	var quote: Dictionary = _session.call("_foundation_send", "loadout_quote", key, {"creature_uid": uid}, -1)
	if quote.get("ok") == true: _quotes[key + ":" + uid] = quote.duplicate(true)
	return quote if _session.call("is_host") == true else _quotes.get(key + ":" + uid, {"ok": false}).duplicate(true)

func submit_loadout(key: String, request: Dictionary) -> void:
	var id := str(request.get("edit_id", ""))
	if not is_instance_valid(_session) or not _pending.is_empty():
		loadout_completed.emit(id, {"ok": false, "resolved": true, "code": "quote_changed"})
		return
	# Freeze the first press before starting the guest's asynchronous quote.
	_pending = {"key": key, "intent": request.duplicate(true), "phase": "quote",
		"quote_intent": {"creature_uid": request.get("creature_uid", ""), "edit_id": id},
		"character_id": _session.call("_local_character_id"), "world_namespace": _session.call("_game").get("world").reward_delivery_namespace}
	_send()

func reconcile_loadout(edit_id: String) -> void:
	if _pending.is_empty() or _pending.intent.edit_id != edit_id: return
	_send()

func _send() -> void:
	if _pending.is_empty() or not is_instance_valid(_session): return
	if _session.call("_local_character_id") != _pending.character_id \
		or _session.call("_game").get("world").reward_delivery_namespace != _pending.world_namespace: return
	if _pending.phase == "quote":
		var quote: Dictionary = _session.call("_foundation_send", "loadout_quote", _pending.key, _pending.quote_intent, -1)
		_accept_quote(quote)
		return
	var result: Dictionary = _session.call("_foundation_send", "loadout", _pending.key, _pending.intent, _pending.revision)
	_settle(result)

func _accept_quote(quote: Dictionary) -> void:
	if _pending.is_empty() or _pending.phase != "quote": return
	if quote.get("resolved") == false: return
	if quote.get("ok") != true or quote.get("creature_uid") != _pending.intent.get("creature_uid") \
		or quote.get("loadout_revision") != _pending.intent.get("expected_revision"):
		_settle({"ok": false, "resolved": true, "durable": false, "code": "quote_changed"})
		return
	_pending.revision = quote.registry_revision
	_pending.phase = "submit"
	_send()

func _reply(envelope: Dictionary, result: Dictionary) -> void:
	if envelope.op == "loadout_quote" and result.get("ok") == true:
		_quotes[envelope.station_key + ":" + str(envelope.intent.get("creature_uid", ""))] = result.duplicate(true)
	if not _pending.is_empty() and envelope.op == "loadout_quote" and envelope.station_key == _pending.key \
		and envelope.intent == _pending.quote_intent: _accept_quote(result)
	elif envelope.op == "loadout" and not _pending.is_empty() and _pending.phase == "submit" and envelope.station_key == _pending.key \
		and envelope.intent == _pending.intent: _settle(result)

func _settle(result: Dictionary) -> void:
	if _pending.is_empty(): return
	var id: String = _pending.intent.edit_id
	if result.get("resolved") == true and (result.get("ok") == false and result.get("durable") == false \
		or result.get("ok") == true and result.get("saved") == true and result.get("durable") == true): _pending.clear()
	loadout_completed.emit(id, result.duplicate(true))

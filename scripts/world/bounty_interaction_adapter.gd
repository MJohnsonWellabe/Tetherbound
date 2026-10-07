extends Node

## F42 owns presentation and input_owner. This focused adapter supplies the
## board rows and instance-only claim intent, and never grants client rewards.
const BOARD := preload("res://scripts/world/bounty_board.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
signal open_requested(view: Dictionary, adapter: Node)
signal action_completed(result: Dictionary)
var _submit: Callable
var _view: Callable
var _reconcile: Callable
var _pending: Dictionary = {}
var _prompt: Node3D

func bind_actions(authenticated_submit: Callable, personal_view: Callable, original_decision_lookup: Callable) -> bool:
	if not authenticated_submit.is_valid() or not personal_view.is_valid() or not original_decision_lookup.is_valid(): return false
	_submit = authenticated_submit
	_view = personal_view
	_reconcile = original_decision_lookup
	return true

func mount(board: Node3D, prompt_position: Vector3) -> bool:
	if BOARD.config().get("runtime_enabled") != true or not is_instance_valid(board) or is_instance_valid(_prompt): return false
	_prompt = INTERACTABLE.new()
	_prompt.name = "BountyInteractable"
	_prompt.set("label", "Read Halda's bounties")
	_prompt.set("radius", float(BOARD.config().interaction_radius_m))
	_prompt.position = prompt_position
	board.add_child(_prompt)
	_prompt.connect("activated", _open)
	return true

func view() -> Dictionary:
	if not _view.is_valid(): return {"ready": false}
	var raw: Variant = _view.call()
	return raw.duplicate(true) if raw is Dictionary else {"ready": false}

func _open() -> void:
	open_requested.emit(view(), self)

func claim(instance: String) -> Dictionary:
	if not _pending.is_empty() or not _submit.is_valid(): return {"ok": false, "code": "board_busy_or_unavailable"}
	var current := view()
	if current.get("ready") != true or not current.get("character_id") is String \
		or not current.get("world_namespace") is String: return {"ok": false, "code": "character_not_ready"}
	_pending = {"instance": instance, "character_id": current.character_id,
		"world_namespace": current.world_namespace} # freeze before solo callback
	var raw: Variant = _submit.call({"instance": instance})
	var result: Dictionary = raw if raw is Dictionary else {"ok": false, "code": "invalid_verdict"}
	if result.get("ok") == false and result.get("durable") == false \
		and result.get("resolved") == false and result.get("code") not in ["reconcile_original_decision", "owner_passive_checkpoint_pending"]:
		_pending.clear()
	settled(result, _pending.duplicate(true))
	return result

func reconcile() -> void:
	if _pending.is_empty() or not _reconcile.is_valid(): return
	if not _same_owner():
		action_completed.emit({"ok": false, "code": "original_character_required", "recoverable": true})
		return
	var raw: Variant = _reconcile.call(_pending.duplicate(true))
	if raw is Dictionary: settled(raw, _pending.duplicate(true))

func settled(result: Dictionary, original: Dictionary = {}) -> void:
	var reply := result.duplicate(true)
	# Durable host acceptance is not a completed payment until exact owner's
	# bool-save and host ACK finish. Disconnect leaves the ORIGINAL instance.
	# The saved care checkpoint is also pending; a terminal no-effect releases
	# only this consumer, without paying or pretending a journal was accepted.
	if result.get("terminal_refusal") == true and result.get("resolved") == true and result.get("durable") == false \
		and not _pending.is_empty() and original == _pending and _same_owner():
		_pending.clear()
		reply["terminal"] = true # Existing panel's presentation-only waiting flag.
	if result.get("ok") == true and result.get("durable") == true \
		and result.get("owner_saved") == true and result.get("owner_acknowledged") == true:
		if not _pending.is_empty() and _same_owner() \
			and result.get("receipt") == "bounty:%s:%s" % [_pending.instance, _pending.character_id]: _pending.clear()
	action_completed.emit(reply)

func _same_owner() -> bool:
	var current := view()
	return current.get("character_id") == _pending.get("character_id") \
		and current.get("world_namespace") == _pending.get("world_namespace")

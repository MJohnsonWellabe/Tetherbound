extends Node

## F44 scene/board adapter. No RPC, identity registry, receipt store or save.
## Foundation supplies authenticated source/start/outcome closures. Incomplete
## composition refuses all actions; UI/F43 consume view() and settled only.
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
signal settled(trainer_id: String, tier: String, character_id: String, verdict: Dictionary)
var _director: Object
var _context: Callable
var _start: Callable
var _retain: Callable
var _submit: Callable
var _pending: Callable

func _ready() -> void:
	add_to_group("f44_rematch_services")

func bind_host(director: Object, host_context: Callable, start_encounter: Callable,
		retain_host_outcome: Callable, submit_character_action: Callable, pending_host_outcomes: Callable) -> bool:
	if director == null: return false
	for callback: Callable in [host_context, start_encounter, retain_host_outcome, submit_character_action, pending_host_outcomes]:
		if not callback.is_valid(): return false
	_director = director
	_context = host_context
	_start = start_encounter
	_retain = retain_host_outcome
	_submit = submit_character_action
	_pending = pending_host_outcomes
	return true

func view(character: String, source: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _context.is_valid(): return out
	for id: String in RULES.config().get("profiles", {}):
		var raw: Variant = _context.call(character, id, source)
		if not raw is Dictionary: continue
		for tier: String in ["r1", "endgame"]:
			if RULES.available(id, tier, raw.get("world_flags", []), raw.get("personal_flags", [])):
				out.append({"trainer_id": id, "tier": tier, "profile": RULES.profile(id)})
	return out

func challenge(character: String, trainer_id: String, tier: String, source: Node,
		creature_uid: String = "") -> Dictionary:
	if RULES.config().get("runtime_enabled") != true or not _context.is_valid() or not _start.is_valid():
		return RULES.deny("rematch_producer_not_mounted")
	var raw: Variant = _context.call(character, trainer_id, source)
	if not raw is Dictionary or raw.get("character_id") != character or raw.get("in_range") != true:
		return RULES.deny("registered_rematch_source_required")
	if not RULES.available(trainer_id, tier, raw.get("world_flags", []), raw.get("personal_flags", [])):
		return RULES.deny("tier_locked")
	var spec := RULES.encounter_spec(raw.get("canonical_spec", {}), tier)
	if spec.is_empty(): return RULES.deny("canonical_trainer_roster_required")
	if RULES.profile(trainer_id).kind == "master" and creature_uid.is_empty():
		return RULES.deny("choose_one_conscious_owned_creature")
	# Existing EncounterHost/director owns actual range, arena, party/vitals,
	# damage and frozen participants. Boss spec goes only to Halda's lawn.
	var result: Variant = _start.call(character, spec, source, creature_uid)
	return result if result is Dictionary else RULES.deny("invalid_encounter_verdict")

## Only the bound director may call this. The retain closure reads its own
## accepted encounter outcome and frozen stable-character census. It journals
## that outcome through the existing durable carrier BEFORE any character
## output: a full satchel or offline owner must keep an owed win after reload.
func finish(source: Object, encounter_id: String) -> Dictionary:
	if source != _director or not _retain.is_valid(): return RULES.deny("host_director_required")
	var outcome: Variant = _retain.call(_director, encounter_id)
	if not outcome is Dictionary or outcome.get("ok") != true or outcome.get("durable") != true:
		return outcome if outcome is Dictionary else RULES.deny("retain_host_outcome_failed")
	if outcome.get("outcome") != "win": return outcome # Loss changes no receipts/deadline.
	return retry(encounter_id)

## Reconnect/reload calls this with the SAME retained outcome. No re-roll or
## receipt synthesis here. The callback authenticates each frozen character,
## re-stages rematch_win inside Authority, then world-save/owner-save/ACK.
func retry(encounter_id: String) -> Dictionary:
	if not _pending.is_valid() or not _submit.is_valid(): return RULES.deny("rematch_delivery_not_mounted")
	var records: Variant = _pending.call(encounter_id)
	if not records is Array: return RULES.deny("invalid_host_outcome")
	var results: Array[Dictionary] = []
	for record: Variant in records:
		if not record is Dictionary or record.get("encounter_id") != encounter_id \
			or not record.get("character_id") is String: return RULES.deny("invalid_retained_participant")
		var intent := {"trainer_id": record.get("trainer_id"), "tier": record.get("tier"), "encounter_id": encounter_id}
		var verdict: Variant = _submit.call(record.character_id, "rematch_win", intent)
		if not verdict is Dictionary: return RULES.deny("invalid_rematch_delivery")
		results.append(verdict)
		# F43 only sees a settled owner result; durable/pending is insufficient.
		if verdict.get("resolved") == true and verdict.get("saved") == true:
			settled.emit(intent.trainer_id, intent.tier, record.character_id, verdict.duplicate(true))
	return {"ok": true, "results": results, "resolved": false}

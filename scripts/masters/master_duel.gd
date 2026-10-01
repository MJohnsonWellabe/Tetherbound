extends RefCounted
## Ephemeral host arena residency, not a durable win/receipt store. A departure
## voids an unfinished duel. A retained durable world delivery is reconciled by
## Foundation; this class never imports a reconnect packet as a victory.
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
var _active: Dictionary = {}
var _director: Object
var _commit: Callable
var _canonical_state: Callable

func bind_host(director: Object, canonical_state: Callable, commit: Callable) -> bool:
	if director == null or not director.has_method("start_master_duel") or not director.has_method("void_master_duel") \
			or not canonical_state.is_valid() or not commit.is_valid(): return false
	_director = director
	_canonical_state = canonical_state
	_commit = commit
	return true

func begin(site: Node3D, character_id: String, uid: String) -> Dictionary:
	if _director == null or not _canonical_state.is_valid(): return {"ok": false, "code": "master_integration_unavailable"}
	var definition := BREAKTHROUGH.master(str(site.get("master_id")))
	if definition.is_empty() or _active.has(definition.id): return {"ok": false, "code": "arena_busy"}
	var current: Variant = _canonical_state.call(character_id)
	if not current is Dictionary or current.get("character_id") != character_id: return {"ok": false, "code": "not_admitted"}
	var chosen: Dictionary = {}
	for card: Dictionary in current.get("party", []):
		if card.uid == uid: chosen = card
	if chosen.is_empty() or chosen.get("fainted", true) or float(chosen.get("hp", 0)) <= 0:
		return {"ok": false, "code": "choose_one_conscious_owned_creature"}
	# The registered director validates actual actor proximity, realm, current
	# character revision and encounter readiness again before engaging.
	var result: Variant = _director.call("start_master_duel", site, character_id, uid, definition)
	if not result is Dictionary or result.get("ok") != true: return result if result is Dictionary else {"ok": false, "code": "encounter_refused"}
	if str(result.get("encounter_id", "")).is_empty(): return {"ok": false, "code": "encounter_identity_required"}
	_active[definition.id] = {"encounter_id": str(result.encounter_id), "character_id": character_id,
		"uid": uid, "site": site, "master_id": definition.id}
	return result

## Only the bound live director can report completion. No RPC targets this.
## The director itself owns host damage/vitals, participant freeze and outcome.
func finish(source: Object, encounter_id: String, character_id: String, uid: String,
		master_id: String, outcome: String) -> Dictionary:
	if source != _director or not _active.has(master_id): return {"ok": false, "code": "unknown_host_duel"}
	var frozen: Dictionary = _active[master_id]
	if frozen.encounter_id != encounter_id or frozen.character_id != character_id or frozen.uid != uid:
		return {"ok": false, "code": "duel_binding_mismatch"}
	if outcome not in ["win", "loss", "void"]: return {"ok": false, "code": "invalid_outcome"}
	if outcome != "win":
		_active.erase(master_id)
		return {"ok": true, "code": "retry_with_any_conscious_creature", "recipe_granted": false}
	# The closure stages prepare_win in the existing registry/journal. A failed
	# bool world save retains this frozen result so the SAME win can be retried.
	var result: Variant = _commit.call(character_id, "master_win", {"master_id": master_id,
		"encounter_id": encounter_id, "creature_uid": uid})
	if not result is Dictionary: return {"ok": false, "code": "transaction_refused"}
	if result.get("ok") == true and result.get("durable") == true: _active.erase(master_id)
	return result

func depart(character_id: String) -> void:
	for id: String in _active.keys():
		if _active[id].character_id == character_id:
			_director.call("void_master_duel", str(_active[id].encounter_id), character_id)
			_active.erase(id)

func can_damage(master_id: String, character_id: String, uid: String) -> bool:
	var row: Dictionary = _active.get(master_id, {})
	return not row.is_empty() and row.character_id == character_id and row.uid == uid

func can_switch(master_id: String) -> bool:
	return not _active.has(master_id)

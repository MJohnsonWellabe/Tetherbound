extends "res://tests/test_case.gd"

## The Cloudreach director's defeat path on a joined CLIENT, and its host
## payout's honesty. The real `cloudreach_encounter_director.gd` and the real
## base `encounter_director.gd` session path run; only the session, ledger,
## satchel and store edges are stubbed (`--script` boots no autoload). The
## integrated path with the finale controller and the real `Game` sweep is
## `tests/smoke_cloudreach_finale.gd::_director_client_leg`.

const VEYRA := "captain_veyra_storm_anchor"
const VEYRA_FLAG := "captain_veyra_defeated"
const GUEST_PEER := 424242


## `Game.progression` stand-in with the merged view's routing surface.
class FlagStore extends RefCounted:
	var flags: Dictionary = {}

	func has(id: String) -> bool:
		return flags.has(id)

	func set_flag(id: String, value: bool = true) -> void:
		if value:
			flags[id] = true
		else:
			flags.erase(id)


class Director:
	extends "res://scripts/combat/cloudreach_encounter_director.gd"
	var multi := true
	var host := false
	var store := FlagStore.new()
	var intents: Array[Dictionary] = []
	var victories: Array = []
	var told: Array = []
	var self_pays := 0
	## When set, every `reward_grant` is refused with this code.
	var grant_refusal := ""
	var receipts: Dictionary = {}

	func _is_multi_peer() -> bool:
		return multi

	func _is_host() -> bool:
		return multi and host

	func _encounter_realm() -> String:
		return "cloudreach"

	## The store seam only: `_progression()` itself stays the director's.
	func _flag_store() -> RefCounted:
		return store

	func _pay_trainer_reward(_spec: Dictionary) -> void:
		self_pays += 1

	func _trainer_reward_line(_spec: Dictionary) -> String:
		return ""

	func _tell_participant_they_were_paid(peer_id: int, _payload: Dictionary) -> void:
		told.append(peer_id)

	func _submit_reward_intent(intent: Dictionary) -> Dictionary:
		intents.append(intent.duplicate(true))
		if str(intent.get("kind", "")) == "set_world_flag":
			if _is_host():
				store.set_flag(str(intent.get("id", "")))
				return {"ok": true, "pending": false, "code": "noop", "paid": []}
			return {"ok": false, "pending": true, "code": "", "paid": []}
		if not grant_refusal.is_empty():
			return {"ok": false, "pending": false, "code": grant_refusal, "paid": []}
		var source := str(intent.get("source", ""))
		var seen: Dictionary = receipts.get(source, {})
		var paid: Array = []
		for raw: Variant in (intent.get("peers", []) as Array):
			if not seen.has(int(raw)):
				seen[int(raw)] = true
				paid.append(int(raw))
		receipts[source] = seen
		if paid.is_empty():
			return {"ok": false, "pending": false, "code": "already_taken", "paid": []}
		return {"ok": true, "pending": false, "code": "", "paid": paid}

	## A client's finale adapter: its write is pending, nothing lands here.
	func adapter(id: String) -> void:
		victories.append(id)


func _director(host: bool) -> Director:
	var director := Director.new()
	if not director.has_method("_flag_store") or not director.has_method("_on_client_refusal"):
		assert_true(false, "Cloudreach director has no client-defeat seam")
		director.free()
		return null
	director.setup(null)
	director.host = host
	director.trainer_victory.connect(director.adapter)
	return director


func _sets(director: Director, flag: String) -> int:
	var count := 0
	for intent: Dictionary in director.intents:
		if str(intent.get("kind", "")) == "set_world_flag" and str(intent.get("id", "")) == flag:
			count += 1
	return count


func test_a_client_win_writes_no_world_flag_before_the_host_commits() -> void:
	var director := _director(false)
	if director == null:
		return
	var spec: Dictionary = director.trainer_specs[VEYRA]
	director._record_trainer_defeat(spec)
	assert_false(director.store.has(VEYRA_FLAG), "the defeat flag waits for the host's committed delta")
	assert_eq(_sets(director, VEYRA_FLAG), 1, "the defeat is submitted as an intent")
	assert_eq(director.victories, [VEYRA])
	assert_eq(director.self_pays, 1, "the base's client personal half runs once")
	director._record_trainer_defeat(spec)
	assert_eq(director.victories, [VEYRA], "a pending defeat is not announced twice")
	assert_eq(_sets(director, VEYRA_FLAG), 1, "nor submitted twice")
	assert_false(director.store.has(VEYRA_FLAG))
	director.free()


func test_a_refusal_allows_a_retry_that_still_writes_nothing_and_pays_nothing_again() -> void:
	var director := _director(false)
	if director == null:
		return
	var spec: Dictionary = director.trainer_specs[VEYRA]
	director._record_trainer_defeat(spec)
	director._on_client_refusal("set_world_flag", "refused", "", {})
	director._record_trainer_defeat(spec)
	assert_eq(director.victories, [VEYRA, VEYRA], "after a refusal the win is announced again")
	assert_eq(_sets(director, VEYRA_FLAG), 2, "and submitted again")
	assert_false(director.store.has(VEYRA_FLAG), "still no local world write")
	assert_eq(director.self_pays, 1, "the personal half does not run again")
	# The host's delta lands: the durable guard stops every later win.
	director.store.set_flag(VEYRA_FLAG)
	director._record_trainer_defeat(spec)
	assert_eq(director.victories.size(), 2)
	director.free()


func test_another_refusal_kind_keeps_the_pending_guard() -> void:
	var director := _director(false)
	if director == null:
		return
	var spec: Dictionary = director.trainer_specs[VEYRA]
	director._record_trainer_defeat(spec)
	director._on_client_refusal("claim_pickup", "already_taken", "", {})
	director._record_trainer_defeat(spec)
	assert_eq(director.victories, [VEYRA])
	director.free()


## The view the base writes through on a client drops only world-scope ids.
func test_the_client_view_drops_world_writes_and_passes_player_writes() -> void:
	var director := _director(false)
	if director == null:
		return
	director._client_view = true
	var view: RefCounted = director._progression()
	view.call("set_flag", VEYRA_FLAG)
	view.call("set_flag", "tam_tools_given")
	director._client_view = false
	assert_false(director.store.has(VEYRA_FLAG), "a world flag is never written locally")
	assert_true(director.store.has("tam_tools_given"), "this peer's own player flag is")
	assert_true(director._progression() == director.store, "outside a client defeat the store is untouched")
	director.free()


func test_solo_and_host_paths_are_unchanged() -> void:
	var solo := _director(false)
	if solo == null:
		return
	solo.multi = false
	solo._record_trainer_defeat(solo.trainer_specs[VEYRA])
	assert_true(solo.store.has(VEYRA_FLAG), "solo records the defeat locally, as before")
	assert_eq(solo.self_pays, 1)
	assert_true(solo.intents.is_empty(), "solo submits nothing")
	solo.free()
	var host := _director(true)
	host._encounter_host = RefCounted.new()
	host._trainer_battle_participants = {1: true, GUEST_PEER: true}
	host._record_trainer_defeat(host.trainer_specs[VEYRA])
	assert_true(host.store.has(VEYRA_FLAG), "the host's intent commits")
	assert_eq(host.self_pays, 0, "the host pays through the session path")
	var told := host.told.duplicate()
	told.sort()
	assert_eq(told, [1, GUEST_PEER])
	host.free()


func test_a_refused_host_payout_is_reported_not_swallowed() -> void:
	var director := _director(true)
	if director == null:
		return
	if not director.has_method("last_payout") or not director.has_signal("trainer_payout_refused"):
		assert_true(false, "Cloudreach director does not report payout refusals")
		director.free()
		return
	director._encounter_host = RefCounted.new()
	director._trainer_battle_participants = {1: true, GUEST_PEER: true}
	director.grant_refusal = "legacy_unresolved"
	var reported: Array = []
	director.trainer_payout_refused.connect(func(id: String, codes: Array) -> void: reported.append([id, codes]))
	director._record_trainer_defeat(director.trainer_specs[VEYRA])
	assert_eq(reported, [[VEYRA, ["legacy_unresolved", "legacy_unresolved"]]],
		"each refused component is reported once")
	var outcome: Dictionary = director.last_payout()
	assert_eq(outcome.get("paid"), [], "nobody is recorded as paid")
	assert_eq(outcome.get("refused"), ["legacy_unresolved", "legacy_unresolved"])
	assert_true(director.told.is_empty(), "nobody is told they were paid")
	assert_eq(director.self_pays, 0, "a refused session payout never falls back to a local one")
	director.free()


func test_already_paid_is_not_reported_as_a_refusal() -> void:
	var director := _director(true)
	if director == null:
		return
	if not director.has_method("last_payout"):
		assert_true(false, "Cloudreach director does not report payout outcomes")
		director.free()
		return
	var spec: Dictionary = director.trainer_specs[VEYRA]
	director._encounter_host = RefCounted.new()
	director._trainer_battle_participants = {1: true, GUEST_PEER: true}
	director._record_trainer_defeat(spec)
	assert_eq((director.last_payout().get("paid") as Array).size(), 2)
	var reported: Array = []
	director.trainer_payout_refused.connect(func(id: String, _codes: Array) -> void: reported.append(id))
	director.store.set_flag(VEYRA_FLAG, false)
	director._record_trainer_defeat(spec)
	assert_eq(reported, [], "already_taken is the receipt working, not a refusal")
	assert_eq(director.last_payout().get("refused"), [])
	director.free()

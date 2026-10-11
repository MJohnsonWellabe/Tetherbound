extends RefCounted

## F27: the host's ownership of a GUEST's creature vitals in one canonical
## wild fight. It reuses the trainer fights' durable actor-vitals carrier
## (encounter_host.stage_actor_vitals -> session.ordinary_actor_vitals_commit
## -> owner save/ACK), but it is a separate scope keyed by the encounter: it
## never names a trainer, never satisfies combat_round_reward.scope_valid and
## so never installs round rewards. The wild victory's own `wild_defeat`
## shares pay XP once.
const E := preload("res://scripts/creatures/essence.gd")
const FIELDS := ["kind", "world_namespace", "session_id", "realm", "encounter_id"]


## F28: kind "master" is the same host ownership of a guest's creature vitals
## in one host-arbitrated Master duel (a one-participant "trainer" record whose
## opponent is that Master). Its win settles through master_win, never rounds.
static func make(namespace_id: String, epoch: String, realm: String, encounter_id: String, kind: String = "wild") -> Dictionary:
	var scope := {"kind": kind, "world_namespace": namespace_id, "session_id": epoch,
		"realm": preload("res://scripts/data/biome_order.gd").canonical_id(realm), "encounter_id": encounter_id}
	return scope if scope_valid(scope) else {}


static func scope_valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != FIELDS.size(): return false
	for field: String in FIELDS:
		if not value.has(field): return false
	if value.kind not in ["wild", "master"]: return false
	for field: String in ["world_namespace", "session_id", "realm", "encounter_id"]:
		if not E._opaque_id(value[field]): return false
	return preload("res://scripts/data/biome_order.gd").ids(false).has(value.realm)


## The scope belongs to this exact live wild record.
static func owns(scope: Variant, record: Dictionary, encounter_id: String) -> bool:
	if not scope_valid(scope) or scope.encounter_id != encounter_id or record.get("encounter_id") != encounter_id \
		or scope.realm != preload("res://scripts/data/biome_order.gd").canonical_id(str(record.get("realm", ""))): return false
	if scope.kind == "master":
		var master_id := str(record.get("opponent", {}).get("owner_npc", ""))
		return record.get("kind") == "trainer" and not master_id.is_empty() \
			and not preload("res://scripts/creatures/breakthrough.gd").master(master_id).is_empty() \
			and record.get("participants", {}).size() == 1
	return record.get("kind") == "wild" and str(record.get("opponent", {}).get("owner_npc", "")) == ""


## One settled vitals row per owned card, from the host's live record of this
## guest after every original hit was owner-saved (actor_generation 0: the
## card was never bound, so its admitted values stand unchanged).
static func settled_vitals(state: Dictionary, member: Dictionary) -> Array:
	var actors: Dictionary = member.get("actor_vitals", {})
	var out: Array = []
	for card: Dictionary in state.get("party", []):
		var actual: Dictionary = actors.get(card.get("uid"), {})
		out.append({"uid": card.get("uid"), "hp": actual.get("hp", card.get("hp")),
			"max_hp": actual.get("max_hp", card.get("max_hp")), "fainted": actual.get("fainted", card.get("fainted")),
			"actor_generation": int(actual.get("body_generation", 0))})
	return out


## The owner-passive replay cursor with this fight's host-saved HP applied,
## as combat_round_reward.settled_before does for trainer rounds. A card that
## already holds the saved values (the authority record) is unchanged.
static func settled_before(current: Dictionary, context: Dictionary) -> Dictionary:
	var vitals: Variant = context.get("settled_vitals")
	if not vitals is Array or not current.get("party") is Array or current.party.size() != vitals.size(): return {}
	var next := current.duplicate(true)
	for index: int in next.party.size():
		var card: Dictionary = next.party[index]
		var found := false
		for vital: Variant in vitals:
			if not vital is Dictionary or vital.get("uid") != card.get("uid"): continue
			if not E._equivalent(vital.get("max_hp"), card.get("max_hp")) or not vital.get("fainted") is bool \
				or not (vital.get("hp") is int or vital.get("hp") is float): return {}
			if int(vital.get("actor_generation", 0)) == 0 and (not E._equivalent(vital.hp, card.get("hp")) \
				or vital.fainted != card.get("fainted")): return {}
			var settled := preload("res://scripts/net/actor_vitals_delivery.gd").settled_card(card, float(vital.hp), vital.fainted)
			if settled.is_empty(): return {}
			next.party[index] = settled
			found = true
			break
		if not found: return {}
	return next


## FoundationActions `wild_defeat_share`: a guest's share of a host wild
## victory. The event was frozen by the host from the actual accepted killing
## hit. It stages on the authority record exactly as it is now: every fight
## hit was already owner-saved into it, and a later heal or hit is never
## overwritten by the frozen end-of-fight values.
static func stage(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	if context.get("validated_host_outcome") != "win" or not E._equivalent(context.get("defeat_event"), intent) \
		or intent.get("world_namespace") != context.get("world_namespace"):
		return {"ok": false, "code": "actual_host_wild_defeat_required", "durable": false, "resolved": false}
	var proposal := E.stage_core_defeat(current, str(current.character_id), intent, int(context.get("expected_revision", 0)),
		E.config(), preload("res://scripts/creatures/progression.gd").config(),
		preload("res://scripts/creatures/teaching.gd").available_moves, preload("res://scripts/creatures/teaching.gd").character_loadout_mirror)
	if proposal.get("ok") != true: return proposal
	if proposal.get("duplicate") == true: return {"ok": false, "code": "reconcile_original_decision", "durable": false, "resolved": false}
	return {"ok": true, "state": proposal.state, "receipt": proposal.receipt}


## The owner already holds the saved fight vitals, as does row.before.
static func owner_plan(current: Dictionary, row: Dictionary) -> Dictionary:
	if E.owner_matches_after(current, row.after):
		return {"ok": true, "duplicate": true, "requires_owner_save": true, "state": current.duplicate(true), "receipt": row.receipt}
	if not E.owner_matches_after(current, row.before):
		return {"ok": false, "code": "owner_action_baseline_conflict", "durable": false, "resolved": false}
	if row.status != "pending": return {"ok": false, "code": "accepted_history_is_not_a_new_award", "durable": false, "resolved": false}
	return {"ok": true, "duplicate": false, "requires_owner_save": true,
		"before": current.duplicate(true), "state": row.after.duplicate(true), "receipt": row.receipt}

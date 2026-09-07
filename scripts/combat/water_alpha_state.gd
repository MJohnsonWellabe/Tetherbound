extends RefCounted

## Aquaryn's host simulation state, separate from local combat/camera ownership.
## Only the realm authority calls this with host-observed participant identities
## and its live enemy instance. Transport intents never contain HP or eligibility.
const HOST := preload("res://scripts/net/encounter_host.gd")
var host := HOST.new()
var config: Dictionary
var enemy: RefCounted
var encounter_id := ""
var phase_index := 0
var phase_elapsed := 0.0
var eligible_characters: Dictionary = {}
var resolution: Dictionary = {}

func _init(rules: Dictionary = {}) -> void:
	config = rules.duplicate(true) if not rules.is_empty() else JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/water_alpha.json"))

func engage(peer_id: int, character_id: String, creature_uid: String, opponent: RefCounted) -> Dictionary:
	if not resolution.is_empty() or character_id.is_empty() or peer_id <= 0 or opponent == null:
		return {}
	if str(opponent.species_id) != str(config.species_id) or opponent.fainted:
		return {}
	if enemy != null and enemy != opponent:
		return {}
	var existing: Dictionary = record().get("participants", {}).get(peer_id, {})
	if not existing.is_empty() and str(existing.get("character_id", "")) != character_id:
		return {}
	if encounter_id.is_empty() or str(record().get("phase", "")) == "done":
		enemy = opponent
		eligible_characters.clear()
		var opened := host.open(peer_id, "water", "wild", {
			"species_id": enemy.species_id, "level": enemy.level,
			"hp": enemy.hp, "hp_max": enemy.max_hp, "owner_npc": ""}, creature_uid, character_id)
		encounter_id = str(opened.encounter_id)
	else:
		if enemy != opponent:
			return {}
		var joined := host.join(encounter_id, peer_id, creature_uid, character_id)
		if not joined.ok:
			return {}
	eligible_characters[character_id] = true
	return record()

func record() -> Dictionary:
	return host.record(encounter_id)

func phase() -> Dictionary:
	return config.phases[phase_index]

func advance(delta: float) -> bool:
	if enemy == null or resolution.size() > 0 or str(record().get("phase", "")) != "active":
		return false
	var previous := phase_index
	var fraction := float(enemy.hp) / maxf(1.0, float(enemy.max_hp))
	for index in config.phases.size():
		if fraction <= float(config.phases[index].enter_below_hp_fraction):
			phase_index = maxi(phase_index, index)
	if previous != phase_index:
		phase_elapsed = 0.0
	else:
		phase_elapsed += maxf(0.0, delta)
	return previous != phase_index

## Called after host-validated damage has changed the existing enemy instance.
## No amount, HP value, winner or eligibility comes from the attacker's payload.
func synchronise_damage() -> Dictionary:
	if enemy == null or not resolution.is_empty() or str(record().get("phase", "")) != "active":
		return {}
	host.set_opponent_hp(encounter_id, enemy.hp, enemy.max_hp)
	if enemy.hp <= 0.0:
		return _resolve("defeated", 0)
	advance(0.0)
	return {}

## A wobble acknowledgement cannot turn a breakout into a catch. Read the
## stored host roll while its claim is still present, before releasing it.
func finish_catch(peer_id: int, arbiter: RefCounted, now_ms: int) -> Dictionary:
	if arbiter == null or not resolution.is_empty() \
			or not host.is_participant(encounter_id, peer_id) \
			or str(record().get("phase", "")) != "catching":
		return {}
	if arbiter.owner_of(encounter_id, now_ms) != peer_id:
		return {}
	var decision: Dictionary = arbiter.decision_for(encounter_id, peer_id)
	if decision.is_empty():
		return {}
	arbiter.release(encounter_id, peer_id)
	if bool(decision.get("caught", false)):
		return _resolve("caught", peer_id)
	host.set_phase(encounter_id, "active")
	return {"outcome": "escaped", "caught": false}

func _resolve(outcome: String, catcher: int) -> Dictionary:
	host.set_phase(encounter_id, "resolving")
	resolution = {"alpha_id": str(config.id), "outcome": outcome,
		"catcher_peer_id": catcher, "species_id": str(config.species_id),
		"eligible_character_ids": eligible_characters.keys()}
	return resolution.duplicate(true)

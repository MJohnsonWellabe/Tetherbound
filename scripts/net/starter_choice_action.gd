extends RefCounted

## F01#6a. The original starter, promoted through the existing full-character
## transaction so the host's admitted record and the owner's saved record agree
## on the same receipt at the same revision.
##
## The guest builds its starter locally (`encounter_director.adopt_starter`) and
## asks the host to admit it. The host never trusts the card: the species must
## be one of the opening's three starters, the card must decode, it must be a
## fresh creature at the configured starter level, the admitted party must be
## empty, and no `starter_choice:<character>:` receipt may already exist -- so a
## character can never be granted a second original starter, nor a conflicting
## one, through this or any other world. Pure and static: the host stages it
## through `foundation_actions.gd`, and every owner re-runs the same callback
## against the frozen pre-decision record (`character_action_delivery.valid`).

const ESSENCE := preload("res://scripts/creatures/essence.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const PREFIX := "starter_choice:"
const FLAG := "opening:starter_granted"


static func codec() -> Script:
	return load("res://scripts/save/water_capture_codec.gd")


static func receipt(character: String, uid: String) -> String:
	return "%s%s:%s" % [PREFIX, character, uid]


static func source_key(character: String) -> String:
	return "starter_choice:" + character


## The host-derived half of the decision. Every value comes from the host's own
## config and admitted registry, never from the request.
static func host_context(character: String, revision: int, starter_species: Array, starter_level: int) -> Dictionary:
	return {"character_id": character, "expected_revision": revision, "in_range": true, "in_combat": false,
		"source_key": source_key(character), "starter_species": starter_species.duplicate(),
		"starter_level": starter_level}


## The request the owner sends: its locally built starter card, nothing else.
static func intent(card: Dictionary) -> Dictionary:
	return {"creature": card.duplicate(true)}


static func stage(current: Dictionary, intent_value: Dictionary, context: Dictionary) -> Dictionary:
	var character: Variant = current.get("character_id")
	if not character is String or character.is_empty() or character.contains(":"):
		return ESSENCE._refuse("invalid_admitted_character")
	if context.get("source_key") != source_key(character) or not context.get("starter_species") is Array \
		or not ESSENCE._integer(context.get("starter_level"), 1, 100):
		return ESSENCE._refuse("starter_context_changed")
	if intent_value.size() != 1 or not intent_value.get("creature") is Dictionary:
		return ESSENCE._refuse("invalid_starter_choice")
	var card: Dictionary = intent_value.creature
	var receipts: Variant = current.get("redesign_character", {}).get("transaction_receipts", [])
	if not receipts is Array:
		return ESSENCE._refuse("invalid_admitted_character")
	for prior: Variant in receipts:
		if prior is String and (prior as String).begins_with(PREFIX + character + ":"):
			return ESSENCE._refuse("original_starter_already_chosen")
	if not current.get("party") is Array or not (current.party as Array).is_empty():
		return ESSENCE._refuse("starter_requires_empty_party")
	var uid: Variant = card.get("uid")
	if not uid is String or uid.is_empty() or uid.contains(":"):
		return ESSENCE._refuse("invalid_starter_card")
	var creature: RefCounted = codec().call("decode", card)
	if creature == null or str(creature.get("uid")) != uid:
		return ESSENCE._refuse("invalid_starter_card")
	if not (context.starter_species as Array).has(str(creature.get("species_id"))):
		return ESSENCE._refuse("not_a_starter_species")
	if int(creature.get("level")) != int(context.starter_level) or bool(creature.get("fainted")) \
		or float(creature.get("hp")) < float(creature.get("max_hp")):
		return ESSENCE._refuse("starter_not_fresh")
	# The decoded card must round-trip exactly: no extra or reinterpreted field
	# can ride into the admitted record.
	if not ESSENCE._equivalent(codec().call("encode", creature), card):
		return ESSENCE._refuse("invalid_starter_card")
	var next := current.duplicate(true)
	next.party = [card.duplicate(true)]
	next.redesign_character = TEACHING.character_loadout_mirror(next.party, next.redesign_character)
	if not next.redesign_character.get("creatures", {}).has(uid):
		return ESSENCE._refuse("starter_loadout_missing")
	if next.redesign_character.transaction_receipts.size() >= int(ESSENCE.config().maximum_transaction_receipts):
		return ESSENCE._refuse("receipt_budget")
	var token := receipt(character, uid)
	next.redesign_character.transaction_receipts.append(token)
	return {"ok": true, "state": next, "receipt": token}
